//
//  Config.m
//  cocoaModem
//
//  Created by Kok Chen on Mon May 17 2004.
	#include "Copyright.h"
//

#import "Config.h"
#import "Application.h"
#import "cocoaModemDebug.h"
#import "ContestManager.h"
#import "Hellschreiber.h"
#import	"MacroScripts.h"
#import "ModemSource.h"
#import "Plist.h"
#import "PSK.h"
#import "PTTHub.h"
#import "QSO.h"
#import "RTTY.h"
#import "DualRTTY.h"
#import "StdManager.h"
#import "TextEncoding.h"
#import "UserInfo.h"

@implementation Config

//  Config includes Plist maintainer

//  initialize
- (id)initWithApp:(Application*)app
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		if ( [ NSBundle loadNibNamed:@"Config" owner:self ] ) {
			logScriptFileName = @"" ;
			pttScriptFolderName = @"" ;
			[ logScriptField setStringValue:logScriptFileName ] ;
			application = app ;
			for ( i = 0; i < 6; i++ ) macroScriptFileName[i] = @"" ;
			return self ;
		}
		[ self release ] ;
	}
	return nil ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)awakeFromNib
{
	NSArray *avail ;
	NSMutableArray *all, *simple ;
	int i, size ;
	
	//[ self setInterface:microKeyerSetupString to:@selector(setupMicroKeyer) ] ;			v0.89
	[ self setInterface:microKeyerQuitScriptField to:@selector(setupMicroKeyerQuit) ] ;
	
	//  v0.96d
	avail = [ NSSpeechSynthesizer availableVoices ] ;
	if ( avail ) {
		all = [ NSMutableArray arrayWithCapacity:64 ] ;
		[ all addObject:[ NSSpeechSynthesizer defaultVoice ] ] ;
		[ all addObjectsFromArray:avail ] ;
		voices = [ [ NSArray alloc ] initWithArray:all ] ;
		
		size = [ voices count ] ;
		simple = [ NSMutableArray arrayWithCapacity:size ] ;
		[ simple addObject:[ NSString stringWithFormat:@"Default Voice (%@)", [ [ voices objectAtIndex:0 ] pathExtension ] ] ] ;
		for ( i = 1; i < size; i++ ) {
			[ simple addObject:[ [ voices objectAtIndex:i ] pathExtension ] ] ;
		}
		[ mainReceiverSpeechMenu removeAllItems ] ;
		[ mainReceiverSpeechMenu addItemsWithTitles:simple ] ;
		[ self setInterface:mainReceiverSpeechMenu to:@selector(mainSpeechMenuChanged:) ] ;
		[ self setInterface:mainReceiverSpeechCheckbox to:@selector(mainSpeechCheckboxChanged:) ] ;
		[ self setInterface:mainReceiverVerbatimCheckbox to:@selector(mainSpeechVerbatimChanged:) ] ;
		
		[ subReceiverSpeechMenu removeAllItems ] ;
		[ subReceiverSpeechMenu addItemsWithTitles:simple ] ;
		[ self setInterface:subReceiverSpeechMenu to:@selector(subSpeechMenuChanged:) ] ;
		[ self setInterface:subReceiverSpeechCheckbox to:@selector(subSpeechCheckboxChanged:) ] ;
		[ self setInterface:subReceiverVerbatimCheckbox to:@selector(subSpeechVerbatimChanged:) ] ;

		[ transmitterSpeechMenu removeAllItems ] ;
		[ transmitterSpeechMenu addItemsWithTitles:simple ] ;
		[ self setInterface:transmitterSpeechMenu to:@selector(transmitSpeechMenuChanged:) ] ;
		[ self setInterface:transmitterSpeechCheckbox to:@selector(transmitSpeechCheckboxChanged:) ] ;
		[ self setInterface:transmitterVerbatimCheckbox to:@selector(transmitterVerbatimChanged:) ] ;
		
		// v1.02d
		[ voiceAssistSpeechMenu removeAllItems ] ;
		[ voiceAssistSpeechMenu addItemsWithTitles:simple ] ;
		[ self setInterface:voiceAssistSpeechMenu to:@selector(voiceAssistMenuChanged:) ] ;

	}
}

- (void)dealloc
{
	[ voices release ] ;
	[ super dealloc ] ;
}

- (void)awakeFromApplication
{
	//  delegate to trap pref panel closure
	[ prefPanel setDelegate:self ] ;
}

- (NSString*)logScriptFile
{
	return logScriptFileName ;
}

- (NSString*)pttScriptFolder
{
	return pttScriptFolderName ;
}

- (IBAction)prefPanelChanged:(id)sender
{
	prefChanged = YES ;
}

//  browse for AppleScript filename
- (Boolean)browseForField:(NSTextField*)textField into:(NSString**)filename isFolder:(Boolean)isFolder
{
	NSOpenPanel *panel ;
	int result ;
	
	panel = [ NSOpenPanel openPanel ] ;
	[ panel setCanChooseDirectories:isFolder ] ;
	[ panel setCanChooseFiles:!isFolder ] ;
	
	//  only allow scripts to be selected
	result = [ panel runModalForTypes:[ NSArray arrayWithObjects:@"scpt", nil ] ] ;
	if ( result == NSOKButton ) {
		[ *filename release ] ;
		*filename = [ [ NSString alloc ] initWithString:[ panel filename ] ] ;
		if ( isFolder ) {
			//  complete path
			[ textField setStringValue:[ panel filename ] ] ;
		}
		else {
			//  filename only
			[ textField setStringValue:[ *filename lastPathComponent ] ] ;
		}
		return YES ;
	}
	*filename = [ [ NSString alloc ] initWithString:[ textField stringValue ] ] ;
	return NO ;
}

- (IBAction)browseForLogScript:(id)sender
{
	if ( [ self browseForField:logScriptField into:&logScriptFileName isFolder:NO ] ) {
		[ [ [ application stdManagerObject ] qsoObject ] logScriptChanged:logScriptFileName ] ;
	}
}

//  v0.89
- (IBAction)browseForMacroScript:(id)sender
{
	int index ;
	NSTextField *field ;
	
	index = [ sender tag ] ;
	switch ( index ) {
	default:
	case 0:
		field = macroScript0 ;
		break ;
	case 1:
		field = macroScript1 ;
		break ;
	case 2:
		field = macroScript2 ;
		break ;
	case 3:
		field = macroScript3 ;
		break ;
	case 4:
		field = macroScript4 ;
		break ;
	case 5:
		field = macroScript5 ;
		break ;
	}
	if ( [ self browseForField:field into:&macroScriptFileName[index] isFolder:NO ] ) {
		[ [ application macroScripts ] setScriptFile:macroScriptFileName[index] index:index ] ;
	}
}

- (IBAction)macroScriptFieldChanged:(id)sender
{
	int index ;
	
	index = [ sender tag ] ;
	[ [ application macroScripts ] setScriptFile:[ sender stringValue ] index:index ] ;
}

- (IBAction)browseForMicroHamQuitScript:(id)sender
{
	[ self browseForField:microKeyerQuitScriptField into:&microKeyerQuitScriptFileName isFolder:NO ] ;
}

- (IBAction)scriptFieldChanged:(id)sender
{
	[ logScriptFileName release ] ;
	logScriptFileName = [ [ NSString alloc ] initWithString:[ logScriptField stringValue ] ] ;
	[ [ [ application stdManagerObject ] qsoObject ] logScriptChanged:logScriptFileName ] ;
}

- (IBAction)browseForPTTFolder:(id)sender
{
	if ( [ self browseForField:userPTTFolderField into:&pttScriptFolderName isFolder:YES ] ) {
		[ [ [ application stdManagerObject ] pttHub ] updateUserPTTScripts:pttScriptFolderName ] ;
	}
}

- (IBAction)pttFolderChanged:(id)sender
{
	[ pttScriptFolderName release ] ;
	pttScriptFolderName = [ [ NSString alloc ] initWithString:[ userPTTFolderField stringValue ] ] ;
	[ [ [ application stdManagerObject ] pttHub ] updateUserPTTScripts:pttScriptFolderName ] ;
}
	
- (void)defaultGeneralPref:(int)index to:(Boolean)state
{
	[ [ appearancePrefs cellAtRow:index column:0 ] setState:( state ) ? NSOnState : NSOffState ] ;
}

/* local */
- (NSMutableArray*)createEmptyArrayOfStrings:(int)size
{
	NSMutableArray *array ;
	int i ;
	
	array = [ [ NSMutableArray alloc ] initWithCapacity:size ] ;
	for ( i = 0; i < size; i++ )  [ array addObject:@"" ] ;
	return array ;
}

//  preferences maintainence
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences
{
	NSArray *empty ;

	if ( application == nil ) quitWithError( @"config has no pointer to application" )
	//  default application prefs (plist version, window position, tab item)
	[ self setString:[ [ application mainWindow ] stringWithSavedFrame ] forKey:kWindowPosition ] ;
	[ self setString:@"DefaultTabItem" forKey:kTabName ] ;
	
	//  Unicode preferences v0.70
	[ self setInt:0 forKey:kUseUnicodeForPSK ] ;
	
	//  General preferences
	[ self setInt:0 forKey:kAutoConnect ] ;
	[ self setInt:0 forKey:kEnableNetAudio ] ;		//  v0.64d
	[ self setInt:0 forKey:kHideWindow ] ;			//  Lite window v0.64e
	[ self setInt:0 forKey:kToolTips ] ;
	[ self setInt:0 forKey:kSlashZeros ] ;
	[ self setInt:0 forKey:kNoOpenRouter ] ;
	[ self setInt:0 forKey:kQuitWithAutoRouting ] ;	//  v0.93b
	
	[ self defaultGeneralPref:0 to:YES ] ;
	[ self defaultGeneralPref:1 to:YES ] ;
	[ self defaultGeneralPref:2 to:NO ] ;
	[ self defaultGeneralPref:3 to:YES ] ;
	[ self defaultGeneralPref:4 to:NO ] ;
	[ self defaultGeneralPref:5 to:YES ] ;
	[ self defaultGeneralPref:6 to:YES ] ;
	[ self defaultGeneralPref:7 to:YES ] ;
	[ self defaultGeneralPref:8 to:NO ] ;			// Lite interface
	
	empty = [ self createEmptyArrayOfStrings:6 ] ; 
	[ self setArray:empty forKey:kMacroScripts ] ;
	[ empty release ] ;
	
	//  Initialize default NetAudio dictionary items to be empty v0.47
	empty = [ self createEmptyArrayOfStrings:4 ] ; 
	[ self setArray:empty forKey:kNetInputServices ] ;
	[ self setArray:empty forKey:kNetInputAddresses ] ;
	[ self setArray:empty forKey:kNetInputPorts ] ;
	[ self setArray:empty forKey:kNetInputPasswords ] ;
	[ self setArray:empty forKey:kNetOutputServices ] ;
	[ self setArray:empty forKey:kNetOutputPorts ] ;
	[ self setArray:empty forKey:kNetOutputPasswords ] ;
	[ empty release ] ;
	
	//  QSO preferences
	[ self setInt:0 forKey:kQSOInterface ] ;
	[ self setString:@"" forKey:kQSOScript ] ;		// v0.34
	
	// PSK Preferences
	[ self setString:@"" forKey:kPSKPrefs ] ;
	
	//  Modem Prefs
	[ self setString:@"1111111111" forKey:kModemList ] ;		// enable all modems as default
	
	//  User Defined PTT 
	[ self setString:@"" forKey:kUserPTTFolder ] ;
	//[ self setString:@"09 85 00 40 00 00 20 01 60 89" forKey:kMicroKeyerSetup2 ] ;
	
	//  uH Router
	[ self setString:@"" forKey:kMicroKeyerSetup3 ] ;
	[ self setString:@"" forKey:kMicroKeyerQuitScript ] ;		// v0.66
	microKeyerQuitScriptFileName = @"" ;
	[ self setInt:0 forKey:kMicroKeyerInvert ] ;
	[ self setInt:0 forKey:kMicroKeyerMode ] ;					// v0.68
			
	if ( [ application userInfoObject ] == nil ) quitWithError( @"config has no pointer to UserInfo object" )
	[ [ application userInfoObject ] setupDefaultPreferences:self ] ;
	
	if ( [ application stdManagerObject ] == nil ) quitWithError( @"config has no pointer to stdManager" )
	[ [ application stdManagerObject ] setupDefaultPreferences:self ] ;
	
	[ [ application auralMonitor ] setupDefaultPreferences:self ] ;
}

/* v0.89
//  v0.50
- (NSTextField*)microKeyerSetupField
{
	return microKeyerSetupString ;
}
*/

//  v0.66
- (NSString*)microKeyerQuitScriptFileName
{
	return microKeyerQuitScriptFileName ;
}

- (void)setupMicroKeyer
{
	DigitalInterfaces *digitalInterfaces ;

	if ( application ) {
		digitalInterfaces = [ application digitalInterfaces ] ;
		[ digitalInterfaces useDigitalModeOnlyForFSK:( [ microKeyerModeCheckbox state ] == NSOnState ) ] ; 
	}
	return ;
	
	/*
	int *p, i, microHamSetupArray[10] ;
	NSString *str ;
	const char *cstr ;
	
	if ( application ) {
		pttHub = [ [ application stdManagerObject ] pttHub ] ;
		//  v0.77 sanity check (crashed due to bad strlen?)
		if ( microKeyerSetupString == nil ) return ;
		str = [ microKeyerSetupString stringValue ] ;
		if ( str == nil || [ str length ] < 20 ) return ;
		cstr = [ str cStringUsingEncoding:kTextEncoding ] ;
		if ( cstr == nil ) return ;
		if ( strlen( cstr ) < 20 ) return ;
		//  v0.77 finally perform sscanf and check if all fields are legit
		p = microHamSetupArray ;
		for ( i = 0; i < 10; i++ ) microHamSetupArray[i] = -1 ;
		sscanf( cstr, "%2x %2x %2x %2x %2x %2x %2x %2x %2x %2x", p, p+1, p+2, p+3, p+4, p+5, p+6, p+7, p+8, p+9 ) ;
		for ( i = 0; i < 10; i++ ) if ( microHamSetupArray[i] < 0 ) return ;
		//  sets up setup string and keyer mode
		[ pttHub microKeyerSetupArray:microHamSetupArray count:10 useDigitalModeOnlyForFSK:( [ microKeyerModeCheckbox state ] == NSOnState ) ] ;  // v0.68
	}
	*/
}

//  v0.66
- (void)setupMicroKeyerQuit
{
	if ( microKeyerQuitScriptFileName && [ microKeyerQuitScriptFileName length ] > 0 ) [ microKeyerQuitScriptFileName release ] ;
	microKeyerQuitScriptFileName = [ [ NSString alloc ] initWithString:[ microKeyerQuitScriptField stringValue ] ] ;
}


/* local */
- (void)setMatrix:(NSMatrix*)matrix fromKey:(NSString*)key
{
	NSArray *array ;
	int i, count ;
	
	array = [ self arrayForKey:key ] ;
	count = [ array count ] ;
	if ( count > 4 ) count = 4 ;
	for ( i = 0; i < count; i++ ) {
		[ [ matrix cellAtRow:i column:0 ] setStringValue:[ array objectAtIndex:i ] ] ;
	}
}

/* local */
- (void)setMatrix:(NSMatrix*)matrix fromString:(NSString*)string
{
	int i ;
	
	for ( i = 0; i < 4; i++ ) {
		[ [ matrix cellAtRow:i column:0 ] setStringValue:string ] ;
	}
}

- (void)setKey:(NSString*)key fromMatrix:(NSMatrix*)matrix
{
	NSMutableArray *array ;
	int i ;

	array = [ [ NSMutableArray alloc ] initWithCapacity:4 ] ;
	for ( i = 0; i < 4; i++ ) {
		[ array addObject:[ [ matrix cellAtRow:i column:0 ] stringValue ] ] ;
	}
	[ self setArray:array forKey:key ] ;
	[ array release ] ;
}

- (void)addMacroScript:(NSArray*)array index:(int)index 
{
	NSString *apath ;
	NSTextField *field ;
	MacroScripts *macroScripts ;
	
	macroScripts = [ application macroScripts ] ;
	if ( macroScripts == nil && index < 6 ) return ;
	
	apath = [ array objectAtIndex:index ] ;
	if ( apath && [ apath length ] > 0 ) {
		switch ( index ) {
		case 0:
			field = macroScript0 ;
			break ;
		case 1:
			field = macroScript1 ;
			break ;
		case 2:
			field = macroScript2 ;
			break ;
		case 3:
			field = macroScript3 ;
			break ;
		case 4:
			field = macroScript4 ;
			break ;
		case 5:
			field = macroScript5 ;
			break ;
		}
		if ( [ macroScripts setScriptFile:apath index:index ] ) {
			macroScriptFileName[index] = [ apath retain ] ;
			[ field setStringValue:[ apath lastPathComponent ] ] ;
		}
		else {
			macroScriptFileName[index] = @"" ;
			[ field setStringValue:@"" ] ;
		}
	}
}

//	v0.96d
- (void)speechMenuChanged:(id)sender channel:(int)channel
{
	int index ;
	
	index = [ sender indexOfSelectedItem ] ;
	if ( index <= 0 ) {
		[ application setVoice:nil channel:channel ] ;
		return ;
	}
	[ application setVoice:[ voices objectAtIndex:index ] channel:channel ] ;
}

//	v1.02d
- (void)voiceAssistMenuChanged:(id)sender
{
	[ self speechMenuChanged:sender channel:3 ] ;
}

//	v0.96d
- (void)mainSpeechMenuChanged:(id)sender
{
	[ self speechMenuChanged:sender channel:1 ] ;
}

//	v0.96d
- (void)subSpeechMenuChanged:(id)sender
{
	[ self speechMenuChanged:sender channel:2 ] ;
}

//	v0.96d
- (void)transmitSpeechMenuChanged:(id)sender
{
	[ self speechMenuChanged:sender channel:0 ] ;
}

//	v0.96d
- (void)speechCheckboxChanged:(id)sender channel:(int)channel
{
	[ application setVoiceEnable:[ sender state ] == NSOnState channel:channel ] ;
}

//	v0.96d
- (void)mainSpeechCheckboxChanged:(id)sender
{
	[ self speechCheckboxChanged:sender channel:1 ] ;
}

//	v0.96d
- (void)subSpeechCheckboxChanged:(id)sender
{
	[ self speechCheckboxChanged:sender channel:2 ] ;
}

//	v0.96d
- (void)transmitSpeechCheckboxChanged:(id)sender
{
	[ self speechCheckboxChanged:sender channel:0 ] ;
}

//	v0.96d
- (void)verbatimChanged:(id)sender channel:(int)channel
{
	[ application setVerbatimSpeech:[ sender state ] == NSOnState channel:channel ] ;
}

//  v0.96d
- (void)mainSpeechVerbatimChanged:(id)sender
{
	[ self verbatimChanged:sender channel:1 ] ;
}

//  v0.96d
- (void)subSpeechVerbatimChanged:(id)sender
{
	[ self verbatimChanged:sender channel:2 ] ;
}

//  v0.96d
- (void)transmitterVerbatimChanged:(id)sender
{
	[ self verbatimChanged:sender channel:1 ] ;
}


//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updatePreferences
{
	int i, count, state ;
	const char *appearanceString, *pskString, *modemString ; 
	NSButton *b ;
	NSString *s, *tabName ;
	StdManager *stdManager ;
	NSRect matrixFrame, viewFrame ;
	PTTHub *pttHub ;
	
	//  window position
	stdManager = [ application stdManagerObject ] ;
	[ [ application mainWindow ] setFrameFromString:[ self stringValueForKey:kWindowPosition ] ] ;
	
	//  Unicode preferences v0.70
	[ application setUseUnicodeForPSK:( [ self intValueForKey:kUseUnicodeForPSK ] != 0 ) ] ;
	
	//  User Defined PTT (v0.60 set up before modem setup)
	s = [ self stringValueForKey:kUserPTTFolder ] ;
	if ( s ) {
		[ userPTTFolderField setStringValue:s ] ; 
		pttHub = [ [ application stdManagerObject ] pttHub ] ;
		if ( pttHub ) {
			if ( [ s length ] > 0 ) [ pttHub updateUserPTTScripts:s ] ;
		}
	}
	//  set up Aural Monitor (before setting up modems when StdManager selects the tab view)
	[ [ application auralMonitor ] updateFromPlist:self ] ;

	tabName = [ self stringValueForKey:kTabName ] ;
	[ stdManager selectTabView:tabName ] ;
	
	//  connections preference
	[ autoConnectCheckbox setState:( [ self intValueForKey:kAutoConnect ] ) ? NSOnState : NSOffState ] ;

	//  set the NetAudio text fields	v0.47
	[ self setMatrix:netInputServiceMatrix fromKey:kNetInputServices ] ;
	[ self setMatrix:netInputAddressMatrix fromKey:kNetInputAddresses ] ;
	[ self setMatrix:netInputPortMatrix fromKey:kNetInputPorts ] ;
	[ self setMatrix:netInputPasswordMatrix fromKey:kNetInputPasswords ] ;
	[ self setMatrix:netOutputServiceMatrix fromKey:kNetOutputServices ] ;
	[ self setMatrix:netOutputPortMatrix fromKey:kNetOutputPorts ] ;
	[ self setMatrix:netOutputPasswordMatrix fromKey:kNetOutputPasswords ] ;

	NSString *ip = @"127.0.0.1" ;	
	if ( [ self hasKey:kEnableNetAudio ] ) {
		if ( [ self intValueForKey:kEnableNetAudio ] != 0 ) ip = [ NSString stringWithCString:[ application localHostIP ] ] ;
	}
	[ self setMatrix:netOutputAddressMatrix fromString:ip ] ;
	
	//  update enable netaudio v0.64d
	[ netAudioEnableCheckbox setState:NSOffState ] ;
	if ( [ self hasKey:kEnableNetAudio ] ) {
		if ( [ self intValueForKey:kEnableNetAudio ] != 0 ) {
			ip = [ NSString stringWithCString:[ application localHostIP ] ] ;
			[ netAudioEnableCheckbox setState:NSOnState ] ;
		}
	}
	else {
		[ self setInt:0 forKey:kEnableNetAudio ] ;
	}
	[ hideWindowCheckbox setState:NSOffState ] ;
	if ( [ self hasKey:kHideWindow ] ) {
		if ( [ self intValueForKey:kHideWindow ] != 0 ) [ hideWindowCheckbox setState:NSOnState ] ;
	}
	else {
		[ self setInt:0 forKey:kHideWindow ] ;
	}

	[ noOpenRouter setState:( [ self intValueForKey:kNoOpenRouter ] == 1 ) ? NSOnState : NSOffState ] ;					//  v0.89
	[ quitWithAutoRouting setState:( [ self intValueForKey:kQuitWithAutoRouting ] == 1 ) ? NSOnState : NSOffState ] ;	//  v0.93b
	
	//  v0.89  MacroScripts
	NSArray *scriptArray = [ prefs objectForKey:kMacroScripts ] ;
	for ( i = 0; i < 6; i++ ) {
		[ self addMacroScript:scriptArray index:i ] ;
	}
	
	//  appearance preferences
	s = [ self stringValueForKey:kAppearancePrefs ] ;
	if ( s ) {
		//  clear Lite as default
		[ [ appearancePrefs cellAtRow:8 column:0 ] setState:NSOffState ] ;

		appearanceString = [ s cStringUsingEncoding:kTextEncoding ] ;
		count = [ s length ] ;
		for ( i = 0; i < count; i++ ) {
			state = appearanceString[i] ;
			if ( i == 6 ) [ self setInt:( state == '1' )?1:0 forKey:kSlashZeros ] ;  //  set kSlashZero item from the kAppearancePrefs
			if ( state == 0 ) break ;
			b = [ appearancePrefs cellAtRow:i column:0 ] ;
			[ b setState:( state == '1' ) ? NSOnState : NSOffState ] ;
		}
	}
	//  PSK preferences
	s = [ self stringValueForKey:kPSKPrefs ] ;
	if ( s ) {
		pskString = [ s cStringUsingEncoding:kTextEncoding ] ;
		count = [ pskPrefs numberOfRows ] ;
		for ( i = 0; i < count; i++ ) {
			state = pskString[i] ;
			if ( state == 0 ) break ;
			b = [ pskPrefs cellAtRow:i column:0 ] ;
			[ b setState:( state == '1' ) ? NSOnState : NSOffState ] ;
		}
	}
	//  Modem preferences - set number of items and position	
	count = [ modemPrefs numberOfRows ] ;
	for ( i = count ; i < 7; i++ ) [ modemPrefs addRow ] ;
	[ modemPrefs sizeToCells ] ;
	matrixFrame = [ modemPrefs frame ] ;
	viewFrame = [ [ modemPrefs superview ] frame ] ;
	matrixFrame.origin.y = ( viewFrame.size.height - matrixFrame.size.height )*0.5 ;
	[ modemPrefs setFrame:matrixFrame ] ;
	// first, clear all titles
	for ( i = 0; i < 7; i++ ) {
		[ [ modemPrefs cellAtRow:i column:0 ] setTitle:@"" ] ;
		[ [ modemPrefs cellAtRow:i column:1 ] setTitle:@"" ] ;
	}	
	[ [ modemPrefs cellAtRow:kRTTYModemOrder column:0 ] setTitle:@"RTTY" ] ;
	[ [ modemPrefs cellAtRow:kWidebandRTTYModemOrder column:0 ] setTitle:@"Wideband RTTY" ] ;
	[ [ modemPrefs cellAtRow:kDualRTTYModemOrder column:0 ] setTitle:@"Dual RTTY" ] ;
	[ [ modemPrefs cellAtRow:kPSKModemOrder column:0 ] setTitle:@"PSK" ] ;
	[ [ modemPrefs cellAtRow:kMFSKModemOrder column:0 ] setTitle:@"MFSK" ] ;
	[ [ modemPrefs cellAtRow:kHellModemOrder column:0 ] setTitle:@"Hellschreiber" ] ;
	[ [ modemPrefs cellAtRow:kSitorModemOrder column:0 ] setTitle:@"SITOR-B" ] ;

	[ [ modemPrefs cellAtRow:kFAXModemOrder%7 column:kFAXModemOrder/7 ] setTitle:@"HF-FAX" ] ;
	[ [ modemPrefs cellAtRow:kCWModemOrder%7 column:kCWModemOrder/7 ] setTitle:@"CW" ] ;
	[ [ modemPrefs cellAtRow:kAMModemOrder%7 column:kAMModemOrder/7 ] setTitle:@"Synchronous AM" ] ;
	[ [ modemPrefs cellAtRow:kASCIIModemOrder%7 column:kASCIIModemOrder/7 ] setTitle:@"ASCII" ] ;
	
	s = [ self stringValueForKey:kModemList ] ;
	if ( s ) {
		modemString = [ s cStringUsingEncoding:kTextEncoding ] ;
		count = kModemsImplemented ;
		for ( i = 0; i < count; i++ ) {
			state = modemString[i] ;
			b = [ modemPrefs cellAtRow:i%7 column:i/7 ] ;
			[ b setState:( state == '1' ) ? NSOnState : NSOffState ] ;			
		}
	}
	
	//  microKeyer (remains here v0.60, user ptt has moved)
	pttHub = [ [ application stdManagerObject ] pttHub ] ;
	if ( pttHub ) {
		//[ microKeyerSetupString setStringValue:[ self stringValueForKey:kMicroKeyerSetup3 ] ] ;		//  v0.68  v0.89
		[ self setupMicroKeyer ] ;
		microKeyerQuitScriptFileName = [ [ NSString alloc ] initWithString:[ self stringValueForKey:kMicroKeyerQuitScript ] ] ;
		[ microKeyerQuitScriptField setStringValue:[ microKeyerQuitScriptFileName lastPathComponent ] ] ;
	}
	
	//  QSO interface
	[ [ application stdManagerObject ] setEnableQSOInterface:( [ self intValueForKey:kQSOInterface ] != 0 ) ? YES : NO ] ;
	logScriptFileName = [ [ self stringValueForKey:kQSOScript ] retain ] ;
	[ logScriptField setStringValue:[ logScriptFileName lastPathComponent ] ] ;						
	[ [ stdManager qsoObject ] logScriptChanged:logScriptFileName ] ;
				
	//  update preferences of each component
	[ [ application userInfoObject ] updateFromPlist:self ] ;
	
	[ stdManager updateFromPlist:self ] ;
	
	//  v0.96d voices
	s = [ self stringValueForKey:kMainReceiverVoice ] ;
	if ( s != nil ) {
		[ mainReceiverSpeechMenu selectItemWithTitle:s ] ;
		if ( [ mainReceiverSpeechMenu indexOfSelectedItem ] < 0 ) [ mainReceiverSpeechMenu selectItemAtIndex:0 ] ;
	}
	[ self mainSpeechMenuChanged:mainReceiverSpeechMenu ] ;
	[ mainReceiverSpeechCheckbox setState:( [ self intValueForKey:kMainReceiverVoiceEnable ] ? NSOnState : NSOffState ) ] ;
	[ self mainSpeechCheckboxChanged:mainReceiverSpeechCheckbox ] ;
	[ mainReceiverVerbatimCheckbox setState:( [ self intValueForKey:kMainReceiverVoiceVerbatim ] ? NSOnState : NSOffState ) ] ;
	[ self mainSpeechVerbatimChanged:mainReceiverVerbatimCheckbox ] ;
	
	s = [ self stringValueForKey:kSubReceiverVoice ] ;
	if ( s != nil ) {
		[ subReceiverSpeechMenu selectItemWithTitle:s ] ;
		if ( [ subReceiverSpeechMenu indexOfSelectedItem ] < 0 ) [ subReceiverSpeechMenu selectItemAtIndex:0 ] ;
	}
	[ self subSpeechMenuChanged:subReceiverSpeechMenu ] ;
	[ subReceiverSpeechCheckbox setState:( [ self intValueForKey:kSubReceiverVoiceEnable ] ? NSOnState : NSOffState ) ] ;
	[ self subSpeechCheckboxChanged:subReceiverSpeechCheckbox ] ;
	[ subReceiverVerbatimCheckbox setState:( [ self intValueForKey:kSubReceiverVoiceVerbatim ] ? NSOnState : NSOffState ) ] ;
	[ self subSpeechVerbatimChanged:subReceiverVerbatimCheckbox ] ;

	s = [ self stringValueForKey:kTransmitterVoice ] ;
	if ( s != nil ) {
		[ transmitterSpeechMenu selectItemWithTitle:s ] ;
		if ( [ transmitterSpeechMenu indexOfSelectedItem ] < 0 ) [ transmitterSpeechMenu selectItemAtIndex:0 ] ;
	}
	[ self transmitSpeechMenuChanged:transmitterSpeechMenu ] ;
	[ transmitterSpeechCheckbox setState:( [ self intValueForKey:kTransmitterVoiceEnable ] ? NSOnState : NSOffState ) ] ;
	[ self transmitSpeechCheckboxChanged:transmitterSpeechCheckbox ] ;
	[ transmitterVerbatimCheckbox setState:( [ self intValueForKey:kTransmitterVoiceVerbatim ] ? NSOnState : NSOffState ) ] ;
	[ self transmitterVerbatimChanged:transmitterVerbatimCheckbox ] ;
	
	// v1.02d more voices
	s = [ self stringValueForKey:kSpeechAssistVoice ] ;
	if ( s != nil ) {
		[ voiceAssistSpeechMenu selectItemWithTitle:s ] ;
		if ( [ voiceAssistSpeechMenu indexOfSelectedItem ] < 0 ) [ mainReceiverSpeechMenu selectItemAtIndex:0 ] ;
	}
	[ self voiceAssistMenuChanged:voiceAssistSpeechMenu ] ;


	//  set up appearance preferences
	debug( "config updating application preferences\n" ) ;
	[ application setAppearancePrefs:appearancePrefs ] ;
	[ stdManager setAppearancePrefs:appearancePrefs ] ;
	[ stdManager setPSKPrefs:pskPrefs ] ;
	
	return true ;
}

//  save the user preferences back into the plist file
- (void)savePlist
{
	int i, count ;
	char *s, str[16] ;
	NSButton *b ;
	StdManager *stdManager ;
	NSString *voice ;
	
	//  version 4 - force BELL off
	[ self setInt:4 forKey:kPrefVersion ] ;
	
	//  remove deprecated keys
	[ self removeKey:kUseCocoaPTT ] ;
	[ self removeKey:kUseMLDXPTT ] ;
	[ self removeKey:kKeyScript ] ;
	[ self removeKey:kUnkeyScript ] ;
	
	//	v0.89 MacroScripts
	NSMutableArray *array = [ [ NSMutableArray alloc ] init ] ;
	for ( i = 0; i < 6; i++ ) [ array addObject:macroScriptFileName[i] ] ;
	[ self setArray:array forKey:kMacroScripts ] ;
	[ array release ] ;
	
	//  window position, tab view item selected
	stdManager = [ application stdManagerObject ] ;
	[ self setString:[ [ application mainWindow ] stringWithSavedFrame ] forKey:kWindowPosition ] ;
	[ self setString:[ stdManager nameOfSelectedTabView ] forKey:kTabName ] ;
	//  QSO interface
	[ self setInt:( [ [ application stdManagerObject ] qsoInterfaceShowing ] ? 1 : 0 ) forKey:kQSOInterface ] ;
	[ self setString:logScriptFileName forKey:kQSOScript ] ;
	
	//  Unicode preferences v0.70
	[ self setInt:( [ application useUnicodeForPSK ] ? 1 : 0 ) forKey:kUseUnicodeForPSK ] ;
	
	//	v0.96d
	voice = ( [ mainReceiverSpeechMenu indexOfSelectedItem ] <= 0 ) ? @"Default Voice" : [ mainReceiverSpeechMenu titleOfSelectedItem ] ;
	[ self setString:voice forKey:kMainReceiverVoice ] ;
	[ self setInt:( ( [ mainReceiverSpeechCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kMainReceiverVoiceEnable ] ;
	
	voice = ( [ subReceiverSpeechMenu indexOfSelectedItem ] <= 0 ) ? @"Default Voice" : [ subReceiverSpeechMenu titleOfSelectedItem ] ;
	[ self setString:voice forKey:kSubReceiverVoice ] ;
	[ self setInt:( ( [ subReceiverSpeechCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kSubReceiverVoiceEnable ] ;
	
	voice = ( [ transmitterSpeechMenu indexOfSelectedItem ] <= 0 ) ? @"Default Voice" : [ transmitterSpeechMenu titleOfSelectedItem ] ;
	[ self setString:voice forKey:kTransmitterVoice ] ;
	[ self setInt:( ( [ transmitterSpeechCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kTransmitterVoiceEnable ] ;
	
	//	v1.02d
	voice = ( [ voiceAssistSpeechMenu indexOfSelectedItem ] <= 0 ) ? @"Default Voice" : [ voiceAssistSpeechMenu titleOfSelectedItem ] ;
	[ self setString:voice forKey:kSpeechAssistVoice ] ;


	//  appearance prefs string (ascii '1's and '0's)
	count = [ appearancePrefs numberOfRows ] ;
	s = str ;
	for ( i = 0; i < count; i++ ) {
		b = [ appearancePrefs cellAtRow:i column:0 ] ;
		*s++ = ( [ b state ] == NSOnState ) ? '1' : '0' ;
	}
	*s = 0 ;
	[ self setString:[ NSString stringWithCString:str encoding:kTextEncoding ] forKey:kAppearancePrefs ] ;
	
	//  PSK prefs string (ascii '1's and '0's)
	count = [ pskPrefs numberOfRows ] ;
	s = str ;
	for ( i = 0; i < count; i++ ) {
		b = [ pskPrefs cellAtRow:i column:0 ] ;
		*s++ = ( [ b state ] == NSOnState ) ? '1' : '0' ;
	}
	*s = 0 ;
	[ self setString:[ NSString stringWithCString:str encoding:kTextEncoding ] forKey:kPSKPrefs ] ;

	//  Modem prefs string (ascii '1's and '0's)
	count = kModemsImplemented ;
	s = str ;
	for ( i = 0; i < count; i++ ) {
		b = [ modemPrefs cellAtRow:i%7 column:i/7 ] ;
		*s++ = ( [ b state ] == NSOnState ) ? '1' : '0' ;
	}
	for ( ; i < 15; i++ ) *s++ = '1' ;
	*s = 0 ;
	[ self setString:[ NSString stringWithCString:str encoding:kTextEncoding ] forKey:kModemList ] ;
	
	//  User Defined PTT
	[ self setString:[ userPTTFolderField stringValue ] forKey:kUserPTTFolder ] ;
	
	//  microkeyer (mH Router)
	//[ self setString:[ microKeyerSetupString stringValue ] forKey:kMicroKeyerSetup3 ] ;		//  v0.68 v0.89
	[ self setString:microKeyerQuitScriptFileName forKey:kMicroKeyerQuitScript ] ;
	[ self setInt:( ( [ microKeyerModeCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kMicroKeyerMode ] ;
	
	//  connection preferences
	[ self setInt:( [ autoConnectCheckbox state ] == NSOnState ) ? 1 : 0  forKey:kAutoConnect ] ;
	
	//  get the NetAudio text fields	v0.47
	[ self setKey:kNetInputServices fromMatrix:netInputServiceMatrix ] ;
	[ self setKey:kNetInputAddresses fromMatrix:netInputAddressMatrix ] ;
	[ self setKey:kNetInputPorts fromMatrix:netInputPortMatrix ] ;
	[ self setKey:kNetInputPasswords fromMatrix:netInputPasswordMatrix ] ;
	[ self setKey:kNetOutputServices fromMatrix:netOutputServiceMatrix ] ;
	[ self setKey:kNetOutputPorts fromMatrix:netOutputPortMatrix ] ;
	[ self setKey:kNetOutputPasswords fromMatrix:netOutputPasswordMatrix ] ;
	
	//  get enable netaudio v0.64d
	[ self setInt:( [ netAudioEnableCheckbox state ] == NSOnState ) ? 1 : 0 forKey:kEnableNetAudio ] ;	
	//  get hide window checkbox	
	[ self setInt:( [ hideWindowCheckbox state ] == NSOnState ) ? 1 : 0 forKey:kHideWindow ] ;
	//	v0.89 keep µH Router closed
	[ self setInt:( [ noOpenRouter state ] == NSOnState ) ? 1 : 0 forKey:kNoOpenRouter ] ;
	//  v0.93b set µH Router to auto routing when cocoaModem quits
	[ self setInt:( [ quitWithAutoRouting state ] == NSOnState ) ? 1 : 0 forKey:kQuitWithAutoRouting ] ;

	//  retrieve info of each component
	[ [ application userInfoObject ] retrieveForPlist:self ] ;
	[ stdManager retrieveForPlist:self ] ;
	
	[ [ application auralMonitor ] retrieveForPlist:self ] ;
	
	[ super savePlist ] ;
}

//  v0.93b set microHAM to auto routing when cocoaModem quits
- (Boolean)quitWithAutoRouting
{
	return ( [ quitWithAutoRouting state ] == NSOnState ) ;
}					

//  preference panel
- (void)showPreferencePanel:(id)sender
{
	prefChanged = NO ;
	[ prefPanel center ] ;
	[ prefPanel orderFront:nil ] ;
}

//  delegate for Pref panel
- (BOOL)windowShouldClose:(id)sender
{
	StdManager *stdManager ;

	//  pref panel closes... set up everything else
	if ( prefChanged ) {
		stdManager = [ application stdManagerObject ] ;
		[ application setAppearancePrefs:appearancePrefs ] ;
		[ stdManager setAppearancePrefs:appearancePrefs ] ;
		[ stdManager setPSKPrefs:pskPrefs ] ;
	}
	return YES ;
}


@end
