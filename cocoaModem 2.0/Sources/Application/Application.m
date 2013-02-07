//
//  Application.m
//  cocoaModem
//
//  Created by Kok Chen on Sun May 16 2004.
	#include "Copyright.h"
//

#import "Application.h"
#import "About.h"
#import "AppDelegate.h"
#import "AudioInterfaceTypes.h"
#import "AudioManager.h"
#import "AuralMonitor.h"
#import "Config.h"
#import "Contest.h"
#import "ContestInterface.h"
#import "DigitalInterfaces.h"
#import "FSKHub.h"
#import "LiteRTTY.h"
#import "MacroInterface.h"
#import "MacroScripts.h"
#import "Messages.h"
#import "modemTypes.h"
#import "ModemSleepManager.h"
#import "Plist.h"
#import "Preferences.h"
#import "QSO.h"
#import "splash.h"
#import "StdManager.h"
#import "TextEncoding.h"
#import "UserInfo.h"
#import "UTC.h"
#import <math.h>
#import <unistd.h>
#import "CoreModem.h"
#import "cocoaModemDebug.h"
#import "NetReceive.h"
#import "NetSend.h"
#import <netinet/in.h>
#import "audioutils.h"


@implementation Application

// global
Boolean gFinishedInitialization = NO ;
Boolean gSplashShowing = NO ;
NSThread *mainThread ;

- (int)appLevel
{
	return 0 ;
}

//  check if option/control/shift keys have changed
//  send to current active modem
- (void)modifierKeyCheck:(NSNotification*)notify
{
	unsigned int flags ;
	
	flags = [ [ notify object ] modifierFlags ] & ( NSAlternateKeyMask | NSShiftKeyMask | NSControlKeyMask ) ;
	
	if ( flags != lastModifierFlags ) {
		// notify others of control key change (for callsign capture, etc)
		lastModifierFlags = flags ;
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"ModifierFlagsChanged" object:self ] ;
	}
}

- (unsigned int)keyboardModifierFlags
{
	return lastModifierFlags ;
}

//  Note: for Tiger, ( floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_3 )
//  Tiger 10.4.8 appears to be 824.41.
- (float)OSVersion
{
	return NSAppKitVersionNumber ;
}

//  command key equivalents for macro keys 
//  send to current active modem
- (void)macroKeyCheck:(NSNotification*)notify
{
	NSEvent *event ;
	int key, index, sheet ;
	unsigned int flags ;
	Boolean option, shift ;
	ContestInterface *modem ;

	event = [ notify object ] ;
	if ( [ [ event characters ] length ] <= 0 ) return ;		// v0.35
	
	key = [ [ event charactersIgnoringModifiers ] characterAtIndex:0 ] ;
	
	if ( key >= '1' && key <= '9' ) index = key-'1' ;
	else if ( key == '0' ) index = 9 ;
	else if ( key == '-' ) index = 10 ;
	else if ( key == '=' ) index = 11 ;
	else return ;
	
	flags = [ event modifierFlags ] ;
	option = ( ( flags & NSAlternateKeyMask ) != 0 ) ;
	shift = ( ( flags & NSShiftKeyMask ) != 0 ) ;
	
	sheet = 0 ;
	if ( option ) {
		if ( shift ) sheet = 2 ; else sheet = 1 ;
	}
	
	modem = (ContestInterface*)[ stdManager currentModem ] ;		
	if ( modem ) {
		if ( contestMode ) {
			//  ask contestManager to execute (common) contest macro
			[ stdManager executeContestMacroFromShortcut:index sheet:sheet modem:modem ] ;
		}
		else {
			// ask modem to execute macro
			[ modem executeMacro:index sheetNumber:sheet ] ;
		}
	}
}

- (void)sysBeep:(NSNotification*)notify
{
}

- (UTC*)clock
{
	return utc ;
}

//  insternal UTC clock server
- (void)tick:(NSTimer*)timer
{
	struct tm *time ;
	
	time = [ utc setTime ] ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SecondTick" object:utc ] ;
	
	if ( minute != time->tm_min ) {
		minute = time->tm_min ;
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"MinuteTick" object:utc ] ;
	}
}

/* local */
- (void)getLocalHostIP
{
	NSEnumerator *addresses ; 
	NSString *address ;
	NSHost *currentHost ;
	const char *ipAddr, *s ;
	
	currentHost = [ NSHost currentHost ] ;

	addresses = [ [ currentHost addresses ] objectEnumerator ] ;
			
	strcpy( localHostIP, "127.0.0.1" ) ;
	while ( ( address = [ addresses nextObject ] ) != nil ) {
		ipAddr = [ address cStringUsingEncoding:kTextEncoding ] ;
		s = ipAddr ;
		while ( *s ) {
			if ( *s++ == '.' ) {
				strcpy( localHostIP, ipAddr ) ;
				return ;
			}
		}
	}
}

/* local */
- (NSArray*)createNetInputPorts:(Preferences*)pref
{
	NSArray *serviceArray, *ipArray, *portArray, *passwordArray ;
	NSMutableArray *array ;
	NetReceive *netAudio ;
	NSString *service, *ip, *portNum, *password ;
	const char *ipAddr ;
	int i, port ;
	
	array = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
	serviceArray = [ pref arrayForKey:kNetInputServices ] ;
	ipArray = [ pref arrayForKey:kNetInputAddresses ] ;
	portArray = [ pref arrayForKey:kNetInputPorts ] ;
	passwordArray = [ pref arrayForKey:kNetInputPasswords ] ;
	
	//  v0.64d use NetAudio only if in Preferences
	if ( [ pref hasKey:kEnableNetAudio ] == NO ) return array ;
	if ( [ pref intValueForKey:kEnableNetAudio ] == 0 ) return array ;
	
	//  sanity check
	if ( !serviceArray || [ serviceArray count ] < 4 ) return array ;
	if ( !ipArray || [ ipArray count ] <= 0 ) return array ;
	if ( !portArray || [ portArray count ] <= 0 ) return array ;

	for ( i = 0; i < 4; i++ ) {
		netAudio = nil ;
		service = [ serviceArray objectAtIndex:i ] ;
		
		//  check if service name, IP address or port number is specified
		if ( service && [ service length ] > 0 ) {
			netAudio = [ [ NetReceive alloc ] initWithService:service delegate:nil samplesPerBuffer:512 ] ;
		}
		else {
			ip = [ ipArray objectAtIndex:i ] ;
			portNum = [ portArray objectAtIndex:i ] ;
			if ( ( ip && [ ip length ] ) || ( portNum && [ portNum length ] ) ) {
			
				if ( ip && [ ip length ] > 0 ) {
					ipAddr = [ ip cStringUsingEncoding:kTextEncoding ] ;
				}
				else {
					if ( localHostIP[0] == 0 ) [ self getLocalHostIP ] ;
					ipAddr = localHostIP ;
				}
				port = ( portNum && [ portNum length ] ) ? [ portNum intValue ] : 52800 ;
				netAudio = [ [ NetReceive alloc ] initWithAddress:ipAddr port:port delegate:nil samplesPerBuffer:512 ] ;
			}
		}
		if ( netAudio ) {
			password = [ passwordArray objectAtIndex:i ] ;
			if ( password && [ password length ] > 0 ) [ netAudio setPassword:password ] ;
			[ array addObject:netAudio ] ;
		}
	}
	return array ;
}

- (NSArray*)createNetPorts:(Preferences*)pref isInput:(Boolean)isInput
{
	NSArray *prefArray ;
	NSMutableArray *array ;
	NetAudio *netAudio ;
	NSString *str ;
	char cstr[64] ;
	int count, i, j, ip1, ip2, ip3, ip4, port ;
	
	array = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
	prefArray = [ pref arrayForKey:( isInput ) ? kNetInputServices : kNetOutputServices ] ;
	
	if ( prefArray != nil ) {
	
		count = [ prefArray count ] ;
		for ( j = 0; j < count; j++ ) {

			netAudio = nil ;
			str = [ prefArray objectAtIndex:j ] ;
			
			if ( str && [ str length ] > 0 ) {
			
				ip1 = ip2 = ip3 = ip4 = port = -1 ;
				if ( isInput ) {
					//  NetReceive
					sscanf( [ str cString ], "%d.%d.%d.%d:%d", &ip1, &ip2, &ip3, &ip4, &port ) ;
					if ( ip1 < 0 || ip2 < 0 || ip3 < 0 || ip4 < 0 || port < 0 ) {
						//  get NetReceive using service name
						netAudio = [ [ NetReceive alloc ] initWithService:str delegate:nil samplesPerBuffer:512 ] ;
					}
					else {
						// get NetReceive with ip:port
						strcpy( cstr, [ str cString ] ) ;
						for ( i = 0; i < 64; i++ ) {
							if ( cstr[i] == ':' ) {
								cstr[i] = 0 ;
								break ;
							}
						}
						netAudio = [ [ NetReceive alloc ] initWithAddress:cstr port:port delegate:nil samplesPerBuffer:512 ] ;
					}
				}
				else {
					//  NetSend, either service name, or servicename:port
					strcpy( cstr, [ str cString ] ) ;
					for ( i = 0; i < 64; i++ ) {
						//  look for port number
						if ( cstr[i] == ':' || cstr[i] <= 0 ) break ;
					}
					if ( cstr[i] ) {
						//  terminate string before port number
						sscanf( &cstr[i+1], "%d", &port ) ;
						if ( port >= 0 ) cstr[i] = 0 ;
					}
					str = [ NSString stringWithCString:cstr encoding:kTextEncoding ] ; 
					netAudio = [ [ NetSend alloc ] initWithService:str delegate:nil samplesPerBuffer:512 ] ;
					if ( port >= 0 && netAudio != nil ) {
						//  try setting the port number
						if ( [ (NetSend*)netAudio setPortNumber:port ] == NO ) netAudio = nil ;
					}
				}
			}
			if ( netAudio ) [ array addObject:netAudio ] ;
		}
	}
	return array ;
}

- (const char*)localHostIP 
{
	if ( localHostIP[0] == 0 ) [ self getLocalHostIP ] ;			// v0.53b deferred getLocalIP (uses 2.2 seconds)
	return localHostIP ;
}

//  (Private API)
- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

//  v0.71
- (void)setAllowShiftJISForPSK:(Boolean)state
{
	int n ;
	
	allowShiftJIS = state ;
	if ( state == NO ) {
		//  if preference is not set, check if we are Japanese Mac OS X, if not, disable Command-j.
		n = [ NSLocalizedString( @"Use Shift-JIS", nil ) characterAtIndex:0 ] ;
		if ( n != '1' ) {
			[ psk31UnicodeInterfaceItem setKeyEquivalent:@"" ] ;
			return ;
		}
	}
	//  preference sets allow shift-JIS
	[ psk31UnicodeInterfaceItem setKeyEquivalent:@"j" ] ;
}

//	v1.02c
- (void)updateDirectAccessFrequency
{
	float freq ;
	
	freq = [ stdManager selectedFrequency ] ; 
	[ directFrequencyAccessField setFloatValue:freq ] ;
}

//  v1.02e
- (void)setSpeakAssistInfo:(NSString*)string
{
	if ( speakAssistInfo ) [ speakAssistInfo autorelease ] ;
	speakAssistInfo = [ [ NSString alloc ] initWithString:string ] ;
}

- (IBAction)speakAlertInfo:(id)sender
{
	if ( speakAssistInfo == nil ) {
		[ self speakAssist:@"No alert info." ] ;
		return ;
	}
	[ self speakAssist:speakAssistInfo ] ;
}
	
- (void)awakeFromNib
{
	NSWindow *window ;
	Preferences *tempPref ;
	Boolean isBrushedMetal ;
	Boolean isLite ;
	NSArray *netInputs, *netOutputs ;
	NSBundle *bundle ;
	NSData *jisdata ;
	NSString *path ;
	const char *str ;
	int i ;
	
	//	v1.01b
	voiceAssist = NO ;
	//	v1.02d
	assistVoice = [ [ Speech alloc ] initWithVoice:nil ] ;
	[ assistVoice setVerbatim:YES ] ;
	[ assistVoice setMute:NO ] ;
	[ assistVoice setSpell:NO ] ;
	//	v1.02e
	speakAssistInfo = nil ;
	
	//  v0.96d
	mainReceiverVoice = [ [ Speech alloc ] initWithVoice:nil ] ;
	subReceiverVoice = [ [ Speech alloc ] initWithVoice:nil ] ;
	transmitterVoice = [ [ Speech alloc ] initWithVoice:nil ] ;
	
	//  v0.78
	auralMonitor = nil ;
	audioManager = nil ;
	initAudioUtils() ;
		
	//  set up local IP defer until needed
	//  [ self getLocalHostIP ] ;
	localHostIP[0] = 0 ;
	
	mainThread = [ NSThread currentThread ] ;
	
	splashScreen = [ [ splash alloc ] init ] ;
	[ self showSplash:@"Welcome" ] ;
	
	//  v0.70 read Shift-JIS Tables from resource
	allowShiftJIS = NO ;
	for ( i = 0; i < 65536; i++ ) jisToUnicode[i] = unicodeToJis[i] = 0 ;
	bundle = [ NSBundle mainBundle ];
	path = [ [ bundle bundlePath ] stringByAppendingString:@"/Contents/Resources/jisToUni.dat" ] ;
	if ( path ) {
		jisdata = [ NSData dataWithContentsOfFile:path ] ;
		if ( jisdata ) memcpy( jisToUnicode, [ jisdata bytes ], 65536*2 ) ;
	}
	path = [ [ bundle bundlePath ] stringByAppendingString:@"/Contents/Resources/uniToJis.dat" ] ;
	if ( path ) {
		jisdata = [ NSData dataWithContentsOfFile:path ] ;
		if ( jisdata ) memcpy( unicodeToJis, [ jisdata bytes ], 65536*2 ) ;
		//  v0.81 Shift-JIS slashed zero
		unicodeToJis[216*2] = 0 ;
		unicodeToJis[216*2+1] = 216 ;
	}
	
	// initialize CoreModem framework
	[ [ CoreModem alloc ] init ] ;
	
	contestMode = NO ;
	
	//	v1.02b
	[ self setInterface:directFrequencyAccessField to:@selector(directFrequencyAccessed:) ] ;
	
	//  v0.70
	[ self setInterface:psk31UnicodeInterfaceItem to:@selector(useUnicodeForPSKChanged:) ] ;
	[ self setInterface:psk31RawInterfaceItem to:@selector(useRawForPSKChanged:) ] ;
	
	//  accepts SysBeep messages here
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(sysBeep:) name:@"SysBeep" object:nil ] ;
	//  create sleep manager
	sleepManager = [ [ ModemSleepManager alloc ] initWithApplication:self ] ;
	
	selectedString[0] = 0 ;
	selectedTextView = nil ;
	[ splashScreen positionWindow ] ;
	gSplashShowing = YES ;
	
	//  check Plist (temporary copy) to see if which UI and if we should search for NetAudio devices
	
	tempPref = [ [ Preferences alloc ] init ] ;
	[ tempPref fetchPlist:NO ] ;
	
	Boolean dontOpenRouter = [ tempPref intValueForKey:kNoOpenRouter ] ;
	
	//	v0.89  Digital Interfaces (cocoaPTT, MacLoggerDX, microHAM devices, etc
	if ( dontOpenRouter ) {
		digitalInterfaces = [ [ DigitalInterfaces alloc ] initWithoutRouter ] ;
	}
	else {
		digitalInterfaces = [ [ DigitalInterfaces alloc ] init ] ;
	}
	macroScripts = [ [ MacroScripts alloc ] init ] ;				//  v0.89
	
	isBrushedMetal = isLite = NO ;
	
	NSString *prefString = [ tempPref stringValueForKey:kAppearancePrefs ] ;
	if ( prefString != nil ) {												// v0.42 Leopard returning nil cString
		str = [ prefString cStringUsingEncoding:kTextEncoding ] ;
		if ( str != nil ) {
			if ( strlen( str ) >= 9 && str[8] == '1' ) isLite = YES ;
			else {
				isBrushedMetal = ( str == nil || strlen( str ) < 6 || str[5] == '1' ) ;	
			}
		}
	}
	//  v0.64d
	Boolean useNetAudio = NO ;
	if ( [ tempPref hasKey:kEnableNetAudio ] ) {
		if ( [ tempPref intValueForKey:kEnableNetAudio ] != 0 ) useNetAudio = YES ;
	}
	if ( useNetAudio ) {
		//  v0.47
		netInputs = [ self createNetInputPorts:tempPref ] ;
		netOutputs = [ self createNetPorts:tempPref isInput:NO ] ;	
	}
	else {
		netInputs = [ [ NSMutableArray alloc ] initWithCapacity:0 ] ;
		netOutputs = [ [ NSMutableArray alloc ] initWithCapacity:0 ] ;
	}
	
	//  v0.76s release thread for 60 ms to allow other things to run
	[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.06 ] ] ;

	//  v0.50 shared FSKHub
	fskHub = [ [ FSKHub alloc ] init ] ;
	//  create UserInfo (must be before StdManager setupWindow)
	userInfo = [ [ UserInfo alloc ] init ] ;
	
	//  v0.78 aural monitor and AudioManager
	audioManager = [ [ AudioManager alloc ] init ] ;
	auralMonitor = [ [ AuralMonitor alloc ] init ] ;

	//  select UI (must be set up before modems, see createModems futher down)
	[ stdManager setupWindow:isBrushedMetal lite:isLite ] ;	
	
	[ stdManager useSmoothPattern:YES ] ;
	[ stdManager updateQSOWindow ] ;
	
	//  don't allocate About panel until needed
	about = nil ; 
	[ self showSplash: @"Discover Audio Devices" ] ;

	//  configure from Preference
	[ self showSplash: @"Creating User Configuration" ] ;
	
	config = [ [ Config alloc ] initWithApp:self ] ;
	[ config awakeFromApplication ] ;
	
	//  create the modems based on what is asked for in the Preference panel
	
	// 0.54 use config as prefs
	[ stdManager createModems:config startModemsFromPlist:tempPref ] ;
	[ tempPref release ] ;
	
	//  v0.53b 
	//  updateDeviceWithActualSamplingRate in ExtendedAudioChannel is initially inhibited by finishedInitializing in the app delegate
	//  we set setFinishedInitializing from here and after all modems have finished initialized	
	gFinishedInitialization = YES ;
	
	//  AppleScript support
	appleScript = [ [ AppDelegate alloc ] initFromApplication:self ] ;
	
	[ [ NSApp delegate ] setIsLite:isLite ] ;

	//  set up default preferences in case Plist does not exist or is messed up  moved here 0.54
	[ self showSplash:@"Reading preferences" ] ;
	[ config setupDefaultPreferences ] ; 	
	
	//  now update preferences from the Plist file, if file exists
	[ config fetchPlist:YES ] ;
	
	//  then, update preferences from Plist file
	[ self showSplash:@"Updating preferences" ] ;
	[ config updatePreferences ] ;
	
	//  update sources for modems in the interfaces  v0.53d
	//  [ stdManager updateModemSources ] ;
	
	//  now make window visible and set us as delegate
	window = [ stdManager windowObject ] ;
	if ( isLite ) {
		//  check if we want to keep a Lite window hidden anyway
		if ( [ config intValueForKey:kHideWindow ] == 0 ) {
			[ window orderFront:self ] ;
			[ (LiteRTTY*)[ stdManager wfRTTYModem ] showControlWindow:YES ] ;
			[ [ NSApp delegate ] setWindowIsVisible:YES ] ;
		}
		else {
			[ (LiteRTTY*)[ stdManager wfRTTYModem ] showControlWindow:NO ] ;
			[ [ NSApp delegate ] setWindowIsVisible:NO ] ;
		}
	}
	else {
		[ window orderFront:self ] ;
		[ [ NSApp delegate ] setWindowIsVisible:YES ] ;
	}
	
	[ window makeFirstResponder:self ] ;
	
	//  add notification observer for option key
	lastModifierFlags = 0 ;
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(modifierKeyCheck:) name:@"OptionKey" object:nil ] ;
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(macroKeyCheck:) name:@"MacroKeyboardShortcut" object:nil ] ;

	//  set up cocoaModem timer
	utc = [ [ UTC alloc ] init ] ;
	minute = -1 ;
	[ NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tick:) userInfo:self repeats:YES ] ;
	
	//  start off by selecting the interfactive interface
	[ self switchInterfaceMode:0 ] ;
	
	//  close splashscreen from a timer - Leopard bug? v0.37
	//[ NSTimer scheduledTimerWithTimeInterval:0.25 target:splashScreen selector:@selector(close) userInfo:self repeats:NO ] ;
	[ splashScreen remove ] ;
	gSplashShowing = NO ;
	
	if ( [ config booleanValueForKey:kVoiceAssist ] ) {
		[ self toggleVoiceAssist:voiceAssistMenuItem ] ;			//  v1.01b
		[ stdManager speakModemSelection ] ;						//  v1.02c
		[ self speakAssist:@" , " ] ;
		[ self updateDirectAccessFrequency ] ;						//  v1.02c
	}
}

- (NSWindow*)mainWindow
{
	return [ stdManager windowObject ] ;
}

//  v0.50
- (FSKHub*)fskHub
{
	return fskHub ;
}

- (StdManager*)stdManagerObject
{
	return stdManager ;
}

- (UserInfo*)userInfoObject
{
	return userInfo ;
}

- (AuralMonitor*)auralMonitor
{
	return auralMonitor ;
}

- (AudioManager*)audioManager
{
	return audioManager ;
}

- (NSMenuItem*)qsoEnableItem
{
	return qsoInterfaceEnableItem ;
}

//  display message on splash screen
- (void)showSplash:(NSString*)msg
{
	[ splashScreen showMessage:NSLocalizedString( msg, nil ) ] ;		// v0.39, v0.70  translate localization here
}

- (Boolean)speakAssist:(NSString*)assist 
{
	if ( [ self voiceAssist ] ) {
		[ assistVoice queuedSpeak:assist ] ;
		return YES ;
	}
	return NO ;
}

- (void)flushSpeakAssist
{
	[ assistVoice clearVoice ] ;
}

- (IBAction)showPreferences:(id)sender
{
	[ config showPreferencePanel:self ] ;
}

- (IBAction)showQSO:(id)sender
{
	[ stdManager toggleQSOShowing ] ;
}

//  v1.01a
- (IBAction)selectQSOCall:(id)sender
{
	[ stdManager selectQSOCall ] ;
	[ self speakAssist:@"call sign" ] ;
}

//  v1.01a		
- (IBAction)selectQSOName:(id)sender
{
	[ stdManager selectQSOName ] ;
	[ self speakAssist:@"name" ] ;
}

//  v1.01b		
- (IBAction)toggleVoiceAssist:(id)sender
{
	voiceAssist = ( [ sender state ] == NSOffState ) ;
	[ sender setState:( voiceAssist ) ? NSOnState : NSOffState ] ;
	if ( voiceAssist ) {
		[ assistVoice setVoiceEnable:YES ] ;
		[ assistVoice speak:@"Voice Assist On." ] ;

	}
	else {
		[ assistVoice speak:@"Voice Assist Offff." ] ;
		[ assistVoice setVoiceEnable:NO ] ;
	}
}

//  update appearance from "General" preferences
- (void)setAppearancePrefs:(NSMatrix*)appearancePrefs
{
	int i, count, state ;
	NSButton *b ;
	
	count = [ appearancePrefs numberOfRows ] ;
	for ( i = 0; i < count; i++ ) {
		b = [ appearancePrefs cellAtRow:i column:0 ] ;
		state = [ b state ] ;
		if ( state == NSOnState ) {
			switch ( i ) {
			case 0:
				//  enable command Q
				[ quitMenu setKeyEquivalent:@"q" ] ;
				break ;
			}
		}
		else {
			switch ( i ) {
			case 0:
				//  disable command Q
				[ quitMenu setKeyEquivalent:@"" ] ;
				break ;
			}
		}
	}
}

/* local */
- (void)enableContestMenus:(Boolean)state
{
	[ resumeMenuItem setEnabled:state ] ;
	[ newMenuItem setEnabled:state ] ;
	[ recentMenuItem setEnabled:state ] ;
}

//  mode 0 - QSO mode, 1 = Contest mode
- (void)switchInterfaceMode:(int)mode
{
	[ contestInterfaceItem setState:(mode==1) ] ;
	[ qsoInterfaceItem setState:(mode==0) ] ;

	[ stdManager activateModems:YES ] ;
	[ self enableContestMenus:YES ] ;
	
	[ stdManager useContestMode:(mode==1) ] ;
			
	contestMode = (mode==1) ;
	[ stdManager updateQSOWindow ] ;

	//  close any open config if interface changed
	[ self closeConfigPanels ] ;
}

- (Boolean)contestModeState
{
	return contestMode ;
}

//  v0.70
- (void)saveSelectedString:(NSString*)string view:(NSTextView*)view
{
	int length, i ;
	unichar u ;
	char *s ;
	
	selectedTextView = view ;
	length = [ string length ] ;
	if ( length > 32 ) length = 32 ;
	s = selectedString ;
	for ( i = 0; i < length; i++ ) {
		u = [ string characterAtIndex:i ] ;
		*s++ = ( ( int )u ) & 0xff ;				//  only allow ASCII
	}
	*s = 0 ;
}

//  ask all interfaces to close their config panels
//  this is typically used when interface or modem changes
- (void)closeConfigPanels
{
	[ stdManager closeConfigPanels ] ;
}

//  show config window of current mode of current interface
- (IBAction)showConfig:(id)sender
{
	[ stdManager showConfigPanel ] ;
}

- (IBAction)showSoftRock:(id)sender
{
	[ stdManager showSoftRock ] ;
}

//  show About panel, allocate and load Nib file if needed
- (IBAction)showAboutPanel:(id)sender
{
	if ( !about ) about = [ [ About alloc ] initFromNib ] ;
	[ about showPanel ] ;
}

//	v1.02b
- (IBAction)showDirectFrequencyAccess:(id)sender
{
	[ [ directFrequencyAccessField window ] makeKeyAndOrderFront:self ] ;
}

//	v1.02b
- (IBAction)directFrequencyAccess:(id)sender
{
	[ self updateDirectAccessFrequency ] ;
	[ [ directFrequencyAccessField window ] makeKeyAndOrderFront:self ] ;
	[ directFrequencyAccessField selectText:self ] ;
	[ self speakAssist:@" Enter frequency - ending with a carriage return. " ] ;
}

- (void)speakContentsOfCurrentFrequency
{
	int ifreq ;
	float freq ;
	
	freq = [ directFrequencyAccessField floatValue ] ;
	
	if ( freq < 1 ) {
		[ self speakAssist:@" Modem turned off. " ] ;
		return ;
	}
	ifreq = freq ;
	if ( fabs( ifreq-freq ) < .05 ) {
		[ self flushSpeakAssist ] ;
		[ self speakAssist:[ NSString stringWithFormat:@"Tuned to %d Hertz ", ifreq ] ] ;
	}
	else {
		[ self flushSpeakAssist ] ;
		[ self speakAssist:[ NSString stringWithFormat:@"Tuned to %.1f Hertz ", freq ] ] ;
	}
}

- (IBAction)speakCurrentFrequency:(id)sender
{
	[ self speakContentsOfCurrentFrequency ] ;
}

//	v1.02c
- (IBAction)selectNextModem:(id)sender 
{
	[ stdManager selectNextModem ] ;
}

//	v1.02c
- (IBAction)selectPreviousModem:(id)sender 
{
	[ stdManager selectPreviousModem ] ;
}

- (IBAction)showRTTYScope:(id)sender
{
	[ stdManager displayRTTYScope ] ;
}

- (IBAction)showAuralMonitor:(id)sender
{
	[ auralMonitor showWindow ] ;
}

- (IBAction)showUserInfo:(id)sender
{
	[ userInfo showSheet:[ stdManager windowObject ] ] ;
}

//  open Cabrillo sheet in contest manager
- (IBAction)showContestInfo:(id)sender
{
	[ stdManager showCabrilloInfo ] ;
}

- (IBAction)switchToTransmit:(id)sender
{
	[ [ stdManager windowObject ] makeKeyWindow ] ;				// v0.33
	[ stdManager switchCurrentModemToTransmit:YES ] ;
}

- (IBAction)switchToReceive:(id)sender
{
	[ stdManager switchCurrentModemToTransmit:NO ] ;
}

- (IBAction)flushToReceive:(id)sender
{
	[ stdManager flushCurrentModem ] ;
}

//	v0.70  Added menu item to Interface Menu
- (void)useUnicodeForPSKChanged:(id)sender
{
	[ self setUseUnicodeForPSK:( [ psk31UnicodeInterfaceItem state ] == NSOffState ) ] ;
}

//  v0.70
- (Boolean)useUnicodeForPSK
{
	return ( [ psk31UnicodeInterfaceItem state ] == NSOnState ) ;
}

//  v0.70
- (void)setUseUnicodeForPSK:(Boolean)state
{
	Boolean useShiftJIS ;
	int n ;

	//  v0.71
	if ( allowShiftJIS == NO ) {
		//  if pref is not set, check if Japanese Mac OS X
		n = [ NSLocalizedString( @"Use Shift-JIS", nil ) characterAtIndex:0 ] ;
		if ( n != '1' ) {
			if ( state == YES ) {
				[ [ NSAlert alertWithMessageText:NSLocalizedString( @"Shift-JIS setting ignored.", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"Shift-JIS cannot be turned on", nil ) ] runModal ] ;
			}
			[ stdManager setUseShiftJIS:NO ] ;
			return ;
		}
	}
	[ psk31UnicodeInterfaceItem setState:( state == NO ) ? NSOffState : NSOnState ] ;
	useShiftJIS = ( [ psk31UnicodeInterfaceItem state ] == NSOnState ) ;
	[ stdManager setUseShiftJIS:useShiftJIS ] ;
}

//  v0.70
- (unsigned char*)jisToUnicodeTable
{
	return jisToUnicode ;
}

//  v0.70
- (unsigned char*)unicodeToJisTable ;
{
	return unicodeToJis ;
}

//	(Private API)
//  v0.70
- (void)setUseRawForPSK:(Boolean)state
{
	Boolean useRaw ;
	
	[ psk31RawInterfaceItem setState:( state == NO ) ? NSOffState : NSOnState ] ;
	useRaw = ( [ psk31RawInterfaceItem state ] == NSOnState ) ;
	[ stdManager setUseRawForPSK:useRaw ] ;
}

//	v0.70  Added menu item to Interface Menu
- (void)useRawForPSKChanged:(id)sender
{
	[ self setUseRawForPSK:( [ psk31RawInterfaceItem state ] == NSOffState ) ] ;
}

//	v1.02b
- (void)setDirectFrequencyFieldTo:(float)value
{
	int ivalue ;
	
	ivalue = value ;
	[ directFrequencyAccessField setStringValue:( fabs( ivalue-value ) < 0.05 ) ? [ NSString stringWithFormat:@"%d", ivalue ] : [ NSString stringWithFormat:@"%.1f", value ] ] ;
	[ NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(speakContentsOfCurrentFrequency) userInfo:nil repeats:NO ] ;
}

//	v1.02b  Direct frequency Access
- (void)directFrequencyAccessed:(id)sender
{
	float freq ;
	int ifreq ;
	
	freq = [ sender floatValue ] ;
	if ( freq > 0 ) {
		if ( freq < 400 || freq > 2400 ) {
			ifreq = [ stdManager selectedFrequency ] ;
			if ( ifreq > 0 ) {
				[ sender setStringValue:[ NSString stringWithFormat:@"%d", ifreq ] ] ;
				[ self speakAssist:[ NSString stringWithFormat:@"Frequency out of range, unchanged at %d Hertz.", ifreq ] ] ;
			}
			else [ self speakAssist:@"Frequency out of range " ] ;
		}
		else {
			if ( fabs( [ stdManager selectedFrequency ] - freq ) < 0.1 ) {
				ifreq = freq ;
				if ( fabs( ifreq-freq ) < 0.05 ) {
					[ self speakAssist:[ NSString stringWithFormat:@"Frequency unchanged. Already tuned to %d Hertz.", ifreq ] ] ;
				}
				else {
					[ self speakAssist:[ NSString stringWithFormat:@"Frequency unchanged. Already tuned to %.1f Hertz.", freq ] ] ;
				}
				return ;
			}
			[ stdManager directSetFrequency:freq ] ;
		}
	}
	else {
		[ stdManager directSetFrequency:0 ] ;
	}
}

- (IBAction)selectInterfaceMode:(id)sender
{
	int mode ;
	
	mode = [ sender tag ] ;
	
	//  check to see if any contest has been selected, if not, do nothing
	if ( mode == 1 && ![ stdManager currentContest ] ) return ;

	//  tag 0 - QSO mode, 1 = Contest mode
	[ self switchInterfaceMode:[ sender tag ] ] ;
}

- (IBAction)swapInterfaceMode:(id)sender
{
	//  check to see if any contest has been selected, if not, do nothing
	if ( ![ stdManager currentContest ] ) return ;

	[ self switchInterfaceMode:(contestMode)?0:1 ] ;
}

- (IBAction)qsoCommands:(id)sender
{
	NSString *string ;
	int t ;
	
	//  check if there is a selected string
	string = [ sender title ] ;	
	t = 0 ;
	if ( [ string isEqualToString:@"Copy Callsign" ] ) t = 'C' ;
	else if ( [ string isEqualToString:@"Copy Name" ] ) t = 'N' ;
	
	[ self transferToQSOField:t ] ;
}

- (void)transferToQSOField:(int)t
{
	NSRange range ;
	
	if ( selectedString[0] == 0 ) return ;
	if ( t != 0 ) {
		[ [ stdManager qsoObject ] copyString:selectedString into:t ] ;
		if ( selectedTextView ) {
			//  unselect the field
			[ selectedTextView lockFocus ] ;
			range = [ selectedTextView selectedRange ] ;
			range.length = 0 ;
			[ selectedTextView setSelectedRange:range ] ;
			[ selectedTextView unlockFocus ] ;
			selectedTextView = nil ;
		}
	}
}

- (void)enableContestMenuItems:(Boolean)state
{
	[ qsoInterfaceItem setEnabled:state ] ;
	[ contestInterfaceItem setEnabled:state ] ;
	[ resumeMenuItem setEnabled:state ] ;
	[ newMenuItem setEnabled:state ] ;
	[ recentMenuItem setEnabled:state ] ;
}

//  clean up and save Plist
- (NSApplicationTerminateReply)terminate
{
	int reply ;
	
	if ( ![ stdManager okToQuit ] ) {
		reply = [ [ NSAlert alertWithMessageText:NSLocalizedString( @"database not saved", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:NSLocalizedString( @"Quit anyway", nil ) informativeTextWithFormat:NSLocalizedString( @"save contest", nil ) ] runModal ] ;
		if ( reply != -1 ) return NSTerminateCancel ;
	}
	[ stdManager applicationTerminating ] ;
	
	// v0.50
	if ( fskHub ) {
		[ fskHub closeFSKConnections ] ;
		fskHub = nil ;
	}
	if ( digitalInterfaces ) [ digitalInterfaces terminate:config ] ;

	[ sleepManager release ] ;			// this should deallocate it
	
	[ config setBoolean:[ self voiceAssist ] forKey:kVoiceAssist ] ;
	[ config savePlist ] ;

	//  v0.78
	[ auralMonitor unconditionalStop ] ;
	[ audioManager release ] ;
	
	return NSTerminateNow ;
}

//  called from ModemSleepManager
- (void)putCodecsToSleep
{
	if ( audioManager != nil ) [ audioManager putCodecsToSleep ] ;
}

//  called from ModemSleepManager
- (void)wakeCodecsUp
{
	if ( audioManager != nil ) [ audioManager wakeCodecsUp ] ;
}

//   NSResponder - catches option and shift keys
- (void)flagsChanged:(NSEvent*)event
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"OptionKey" object:event ] ;
	[ super flagsChanged:event ] ;
}

//   NSResponder - catches command 1 through = keys
//   this usually is caught in the Exhange and Send text views, but is trapped here if they don't see it
- (BOOL)performKeyEquivalent:(NSEvent*)event
{
	int n ;
		
	if ( [ [ event characters ] length ] > 0 ) {		// v0.35
		n = [ [ event charactersIgnoringModifiers ] characterAtIndex:0 ] ;
		if ( ( n >= '0' && n <= '9' ) || n == '-' || n == '=' ) {
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"MacroKeyboardShortcut" object:event ] ;
			return YES ;
		}
	}
	return NO ;
}

//  AppleScript support

//  class references
- (ModemManager*)interface
{
	return stdManager ;
}

- (void)changeInterfaceTo:(ModemManager*)which alternate:(Boolean)state
{
	[ self switchInterfaceMode:(state)?1:0 ] ;
}

- (BOOL)windowShouldClose:(id)sender
{
	return NO ;	
}

//  v0.75
- (void)openURLDoc:(NSString*)url
{
	[ [ NSWorkspace sharedWorkspace ] openURL:[ NSURL URLWithString:url ] ] ;
}

//  v0.72
- (IBAction)checkForUpdate:(id)sender
{
	NSString *url, *version ;
	FILE *updateFile ;
	char line[129], *s, *app ;
	int i, len, alert ;
	float latest, current ;

	app = "cocoaModem 2.0" ;
	len = strlen( app ) ;
	url = @"curl -s -m10 -A \"Mozilla/4.0 (compatible; MSIE 5.5; Windows 98)\" " ;
	url = [ url stringByAppendingString:@"\"http://www.w7ay.net/site/Downloads/updates.txt\"" ] ;
	updateFile = popen( [ url cStringUsingEncoding:NSASCIIStringEncoding ], "r" ) ;

	if ( updateFile == nil ) {
		[ [ NSAlert alertWithMessageText:NSLocalizedString( @"Update information error", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"Update file not found", nil ) ] runModal ] ;
		return ;
	}
	for ( i = 0; i < 20; i++ ) {
		s = fgets( line, 128, updateFile ) ;
		if ( s == nil ) {
			[ [ NSAlert alertWithMessageText:NSLocalizedString( @"Update information error", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"No update info", nil ) ] runModal ] ;
			break ;
		}
		if ( strncmp( s, app, len ) == 0 ) {
			sscanf( s+len, "%f", &latest ) ;
			version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
			sscanf( [ version cStringUsingEncoding:kTextEncoding ], "%f", &current ) ;
			
			if ( ( latest - current ) > .0001 ) {
				alert = [ [ NSAlert alertWithMessageText:NSLocalizedString( @"New download available", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:NSLocalizedString( @"What's New", nil ) informativeTextWithFormat:[ NSString stringWithFormat:NSLocalizedString( @"Update available info", nil ), latest ] ] runModal ] ;
				if ( alert == -1 || alert == NSAlertThirdButtonReturn ) {
					// v0.75
					[ self openURLDoc:@"http://www.w7ay.net/site/Applications/cocoaModem/Whats%20New/index.html" ] ;
				}
			}
			else {
				[ [ NSAlert alertWithMessageText:NSLocalizedString( @"Up to date", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:[ NSString stringWithFormat:NSLocalizedString( @"Up to date info", nil ), latest ] ] runModal ] ;
			}
			break ;
		}
	}
	pclose( updateFile ) ;
}

//	v0.96c
- (IBAction)selectMainView:(id)sender 
{
	[ stdManager selectView:1 ] ;
}

//	v0.96c
- (IBAction)selectSubView:(id)sender
{
	[ stdManager selectView:2 ] ;
}

//	v0.96c
- (IBAction)selectTransmitView:(id)sender
{
	[ stdManager selectView:0 ] ;
}

//	v0.96d
- (IBAction)muteSpeech:(id)sender
{
	Boolean state ;
	
	if ( [ sender state ] == NSOffState ) {
		[ sender setState:NSOnState ] ;
		state = YES ;
	}
	else {
		[ sender setState:NSOffState ] ;
		state = NO ;
		[ mainReceiverVoice speak:@"Text To Speech On." ] ;
	}
	[ transmitterVoice setMute:state ] ;
	[ mainReceiverVoice setMute:state ] ;
	[ subReceiverVoice setMute:state ] ;
}

//	v1.00
- (IBAction)spellSpeech:(id)sender
{
	Boolean state ;
	
	if ( [ sender state ] == NSOffState ) {
		[ sender setState:NSOnState ] ;
		state = YES ;
	}
	else {
		[ sender setState:NSOffState ] ;
		state = NO ;
	}
	[ transmitterVoice setSpell:state ] ;
	[ mainReceiverVoice setSpell:state ] ;
	[ subReceiverVoice setSpell:state ] ;
}

- (DigitalInterfaces*)digitalInterfaces
{
	return digitalInterfaces ;
}

- (MacroScripts*)macroScripts
{
	return macroScripts ;
}

//	v0.96d TextToSpeech
//	channel 0	transmit
//			1	main receiver
//			2	sub receiver
- (void)addToVoice:(int)ascii channel:(int)channel
{
	switch ( channel ) {
	case 0:
		[ transmitterVoice addToVoice:ascii ] ;
		break ;
	case 1:
		[ mainReceiverVoice addToVoice:ascii ] ;
		break ;
	case 2:
		[ subReceiverVoice addToVoice:ascii ] ;
		break ;
	case 3:
		[ assistVoice addToVoice:ascii ] ;
		break ;
	}
}

- (void)setVoice:(NSString*)name channel:(int)channel
{
	switch ( channel ) {
	case 0:
		[ transmitterVoice setVoice:name ] ;
		break ;
	case 1:
		[ mainReceiverVoice setVoice:name ] ;
		break ;
	case 2:
		[ subReceiverVoice setVoice:name ] ;
		break ;
	case 3:
		[ assistVoice setVoice:name ] ;
		//[ assistVoice setRate:800.0 ] ;
		[ self speakAssist:@"Welcome to cocoaModem." ] ;
		break ;
	}
}

- (void)setVoiceEnable:(Boolean)state channel:(int)channel
{
	switch ( channel ) {
	case 0:
		[ transmitterVoice setVoiceEnable:state ] ;
		break ;
	case 1:
		[ mainReceiverVoice setVoiceEnable:state ] ;
		break ;
	case 2:
		[ subReceiverVoice setVoiceEnable:state ] ;
		break ;
	}
}

- (void)setVerbatimSpeech:(Boolean)state channel:(int)channel
{
	switch ( channel ) {
	case 0:
		[ transmitterVoice setVerbatim:state ] ;
		break ;
	case 1:
		[ mainReceiverVoice setVerbatim:state ] ;
		break ;
	case 2:
		[ subReceiverVoice setVerbatim:state ] ;
		break ;
	}
}

- (void)clearVoiceChannel:(int)channel
{
	switch ( channel ) {
	case 0:
		[ transmitterVoice clearVoice ] ;
		break ;
	case 1:
		[ mainReceiverVoice clearVoice ] ;
		break ;
	case 2:
		[ subReceiverVoice clearVoice ] ;
		break ;
	}
}

- (void)clearAllVoices
{
	[ transmitterVoice clearVoice ] ;
	[ mainReceiverVoice clearVoice ] ;
	[ subReceiverVoice clearVoice ] ;
}

//	v1.01b
- (Boolean)voiceAssist
{
	return voiceAssist ;
}

- (void)dealloc
{
	[ mainReceiverVoice release ] ;
	[ subReceiverVoice release ] ;
	[ transmitterVoice release ] ;
	if ( speakAssistInfo ) [ speakAssistInfo release ] ;
	[ super dealloc ] ;
}

@end
