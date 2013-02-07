//
//  Modem.m
//  cocoaModem
//
//  Created by Kok Chen on Sun May 30 2004.
	#include "Copyright.h"
//

#import "Modem.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"  // for RTTYMODE
#import "ExchangeView.h"
#import "ModemConfig.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Preferences.h"
#import "PTT.h"
#import "Transceiver.h"
#import "TextEncoding.h"

@implementation Modem

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

// this is common to all subclasses of Modem.m
- (id)initWithManager:(ModemManager*)mgr 
{
	self = [ super init ] ;
	if ( self ) {
		// create "modules" for AppleScript
		transceiver1 = [ [ Transceiver alloc ] initWithModem:self index:0 ] ;
		transceiver2 = [ [ Transceiver alloc ] initWithModem:self index:1 ] ;
		
		outputBoost = 1.0 ;		//  v0.88
		receiveTextAttribute = transmitTextAttribute = nil ;
		manager = mgr ;
		transceivers = 1 ;
		lastPolledTransceiver = 0 ;
		transmitState = NO ;
		slashZero = NO ;
		transmitCount = 0 ;
		controlKeyState = shiftKeyState = NO ;
		ident = nil ;
		ptt = nil ;
		captured[0] = 0 ;
		enableClick = YES ;
		plistHasBeenUpdated = NO ;
		getCallLock = [ [ NSLock alloc ] init ] ;
		waterfallDate = [ [ NSDate alloc ] init ] ;		//  v0.82
	}
	return self ;
}

- (char*)capturedString
{
	return captured ;
}

//  override in instance of the Modem class to call -initIntoTabView:modemName:app: (see below)
- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	ptt = nil ;
	return [ self initWithManager:mgr ] ;
}

//  Note:Modem class is also an AudioDest
//  initialize, and load the config view from the Nib into the tab view for the modem
- (id)initIntoTabView:(NSTabView*)tabview nib:(NSString*)nib manager:(ModemManager*)mgr
{
	[ self initWithManager:mgr ] ;

	if ( self ) {
		ptt = nil ;
		if ( [ NSBundle loadNibNamed:nib owner:self ] ) {
			// loadNib should have set up modem view
			if ( view ) {
				//  create a new TabViewItem for modem
				modemTabItem = [ [ NSTabViewItem alloc ] init ] ;
				[ modemTabItem setView:view ] ;
				[ modemTabItem setLabel:ident ] ;		// ident set from awakeFromNib
				//  and insert as tabView item
				controllingTabView = tabview ;
				[ controllingTabView insertTabViewItem:modemTabItem atIndex:0 ] ;
				//  create notification client for modifier keys
				[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(keyModifierChanged:) name:@"ModifierFlagsChanged" object:nil ] ;
				
				waterfallProducer = waterfallConsumer = 0 ;

				return self ;
			}
			printf( "cocoaModem: modem %s not connected to any view\n", [ nib cStringUsingEncoding:kTextEncoding ] ) ;
		}
	}
	return nil ;
}

- (NSString*)ident
{
	return ident ;
}

//  default mode to RTTY
- (int)transmissionMode
{
	return RTTYMODE ;
}

- (void)initCallsign
{
	int i ;
	
	//  set up admissable callsign characters
	for ( i = 0; i < 256; i++ ) callChar[i] = 0 ;
	for ( i = 'A'; i <= 'Z'; i++ ) callChar[i] = 1 ;
	for ( i = 'a'; i <= 'z'; i++ ) callChar[i] = 1 ;
	for ( i = '0'; i <= '9'; i++ ) callChar[i] = 1 ;
	callChar['/'] = callChar[0xd8] = 1 ;	// slash-zero

	//  set up admissable exchange characters
	for ( i = 0; i < 256; i++ ) exchChar[i] = 0 ;
	for ( i = 'A'; i <= 'Z'; i++ ) exchChar[i] = 1 ;
	for ( i = 'a'; i <= 'z'; i++ ) exchChar[i] = 1 ;
	for ( i = '0'; i <= '9'; i++ ) exchChar[i] = 1 ;
	exchChar[0xd8] = 1 ;	// slash-zero
}

- (Boolean)isCallChar:(int)c
{
	return ( callChar[ c&0xff ] == 1 ) ;
}

- (void)initColors
{
	//  set up default colors
	sentTextColor = [ [ NSColor blackColor ] retain ] ; 
	textColor = [ [ NSColor blackColor ] retain ] ; 
	backgroundColor = [ [ NSColor whiteColor ] retain ] ;
	plotColor = [ [ NSColor greenColor ] retain ] ;
}

- (void)updateColorsInViews
{
}

//  default modem, ignores receiver index
- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor forReceiver:(int)rx
{
	[ self setTextColor:inTextColor sentColor:sentTColor backgroundColor:bgColor plotColor:pColor ] ;
}

- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor
{
	[ textColor release ] ;
	textColor = [ inTextColor retain ] ;

	[ sentTextColor release ] ;
	sentTextColor = [ sentTColor retain ] ;
	
	[ backgroundColor release ] ;
	backgroundColor = [ bgColor retain ] ;
	
	[ plotColor release ] ;
	plotColor = [ pColor retain ] ;
	
	[ receiveView setBackgroundColor:backgroundColor ] ;
	[ transmitView setBackgroundColor:backgroundColor ] ;
	
	[ receiveView setTextColor:textColor attribute:receiveTextAttribute ] ;
	[ transmitView setViewTextColor:textColor attribute:transmitTextAttribute ] ;
}

- (void)setTransmitTextColor:(NSColor*)sentTColor
{
	[ sentTextColor release ] ;
	sentTextColor = [ sentTColor retain ] ;
}

- (void)setSentColor:(Boolean)state view:(ExchangeView*)eview textAttribute:(TextAttribute*)attr
{
	if ( attr != nil ) {
		if ( state == YES ) {
			if ( sentColor != YES ) {
				[ eview setTextColor:sentTextColor attribute:attr ] ;
				sentColor = YES ;
			}
		}
		else {
			[ eview setTextColor:textColor attribute:attr ] ;
			sentColor = NO ;
		}
	}
}

// change color of default receive view's text
- (void)setSentColor:(Boolean)state
{
	[ self setSentColor:state view:receiveView textAttribute:receiveTextAttribute ] ;
}


- (Application*)application
{
	return [ manager appObject ] ;
}

- (void)directSetFrequency:(float)freq
{
	//  override by modems that can directly set frequency
	[[  [ NSApp delegate ] application ] speakAssist:@"This interface does not support direct frequency access." ] ;
}

- (float)selectedFrequency
{
	//  override by modems that can directly set frequency
	return 0.0 ;
}

//  default to the main config IBOutlet
- (ModemConfig*)configObj:(int)index
{
	return config ;
}

- (ModemConfig*)txConfigObj
{
	return txConfig ;
}

- (Boolean)currentTransmitState
{
	return transmitState ;
}

//  override by subclasses of Modem
- (void)setIgnoreNewline:(Boolean)state
{
}

//  override by subclasses of Modem
- (NSSlider*)inputAttenuator:(ModemConfig*)config
{
	return nil ;
}

//  override from subclasses that has data to import directy into the mode (rather than a receiver of a modem)
- (void)importData:(CMPipe*)pipe
{
}

//  first recipient of the audio stream for this modem
- (CMTappedPipe*)dataClient
{
	printf( "%s did not implement -dataClient\n", [ ident cStringUsingEncoding:kTextEncoding ] ) ;
	return nil ;
}

//  override by modem instances to turn modem on or off
- (void)enableModem:(Boolean)state
{
}

- (void)setVisibleState:(Boolean)visible
{
	if ( config ) [ config updateVisibleState:visible ] ;
}

// called from ModemConfig 
- (void)activeChanged:(ModemConfig*)f
{
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
}

//  overide by subclasses of Modem
- (void)updateSourceFromConfigInfo
{
	printf( "%s did not implement -updateSourceFromConfigInfo\n", [ ident cStringUsingEncoding:kTextEncoding ] ) ;
}

//  subclasses override this to keep (e.g.,, PSK) transmission alive
- (Boolean)shouldEndTransmission
{
	return YES ;
}

- (void)incrementTransmitCount
{
	[ transmitCountLock lock ] ;
	transmitCount++ ;
	[ transmitCountLock unlock ] ;
}

- (void)decrementTransmitCount
{
	[ transmitCountLock lock ] ;
	transmitCount-- ;
	[ transmitCountLock unlock ] ;
}

- (void)clearTransmitCount
{
	[ transmitCountLock lock ] ;
	transmitCount = 0 ;
	[ transmitCountLock unlock ] ;
}

//  v0.87 set microHAM keyerMode when a new modem interface is switched in
- (void)switchModemIn
{
	printf( "Modem.m: switchModemIn (should override in subclass\n" ) ;
}

//  v0.88  2dB output boost
- (float)outputBoost
{
	return outputBoost ;
}

//	v00.89
- (void)flushClickBuffer
{
}

//  ModemManager calls cleanup to all modems when app is terminating. 
//  v 0.78 Modems should override this if some cleanup is needed, and then call this with [ super cleanup ].
- (void)applicationTerminating
{
	[ config applicationTerminating ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	plistHasBeenUpdated = YES ;
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	//  default to no tooltips
	[ manager clearToolTipsInView:view ] ;
}

- (NSTabViewItem*)tabItem
{
	return modemTabItem ;
}

- (Boolean)isActiveTab
{
	return ( [ manager activeTabView ] == modemTabItem ) ;
}

- (void)ptt:(Boolean)state
{
	if ( ptt ) [ ptt executePTT:state ] ;
}

- (Boolean)checkIfCanTransmit
{
	return YES ;
}

// ----------------------------------------------------------------

//  override by subclasses of Modem
- (void)changeTransmitStateTo:(Boolean)state
{
}

//  override by ContestInterface
- (void)transmissionEnded
{
}

- (void)removeToolTips
{
	//  always clear ToolTips for now
	[ manager clearToolTipsInView:view ] ;
}

- (void)useSlashedZero:(Boolean)state
{
	slashZero = state ;
}

//  override in modem implementations
- (void)enterTransmitMode:(Boolean)state
{
}

//  override in modem implementations
- (void)flushAndLeaveTransmit
{
}

//  override in modem implementations
- (void)transmittedCharacter:(int)ch
{
}

//  override in modem implementations
- (void)sendMessageImmediately
{
}

//  override in modem implementations that use waterfalls
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)index
{
}

//  override in modem implementations that use waterfalls
- (void)turnOffReceiver:(int)ident option:(Boolean)option
{
}

- (NSRange)getCallsignString:(NSTextView*)textView from:(NSRange)selectedRange
{			
	int loc, start, end, limit, length, ch = 0 ;
	NSString *string ;
	
	if ( [ getCallLock tryLock ] ) {

		loc = selectedRange.location ;
		if ( loc > 0 ) {
			// ignore selection of first two locations since it can come from a cleared buffer
			// ExchangeView moves the cursor from the end, which causes loc 0 and 1 to be triggered
			// from a cleared buffer
			string = [ [ textView textStorage ] string ] ;
			if ( string ) {
				length = [ string length ] ;
				if ( loc < length ) {
					//  check if clicked character is a callsign character
					if ( callChar[ [ string characterAtIndex:loc ] ] == 0 ) {
						[ getCallLock unlock ] ;
						return NSMakeRange(0,0) ;
					}
					limit = loc-13 ;
					if ( limit < 0 ) limit = 0 ;
					for ( start = loc; start >= limit; start-- ) {
						ch = [ string characterAtIndex:start ] & 0xff ;
						if ( callChar[ch] == 0 ) break ;
					}
					start++ ;
					limit = start+15 ;
					if ( limit > length ) limit = length ;
					for ( end = start; end < limit; end++ ) {
						ch = [ string characterAtIndex:end ] & 0xff ;
						if ( callChar[ch] == 0 ) break ;
					}
					end-- ;
					
					length = end-start+1 ;
					//  too short to be callsign
					if ( length < 3 ) start = length = 0 ;
					[ getCallLock unlock ] ;
					return NSMakeRange(start,length) ;
				}
			}
		}
	}
	return NSMakeRange(0,0) ;
}

- (ModemManager*)managerObject
{
	return manager ;
}

- (NSRange)getExchangeString:(NSTextView*)textView from:(NSRange)selectedRange
{			
	int loc, start, end, limit, length, ch ;
	NSString *string ;
	
	loc = selectedRange.location ;
	length = selectedRange.length ;
	
	if ( loc > 0 ) {
		// ignore selection of first two locations since it can come from a cleared buffer
		// ExchangeView moves the cursor from the end, which causes loc 0 and 1 to be triggered
		// from a cleared buffer
		string = [ [ textView textStorage ] string ] ;
		if ( string ) {
			length = [ string length ] ;
			if ( loc < length ) {
				//  check if clicked character is a exchange character
				ch = [ string characterAtIndex:loc ] ;
				if ( exchChar[ ch ] == 0 ) return NSMakeRange(0,0) ;
				limit = loc-13 ;
				if ( limit < 0 ) limit = 0 ;
				for ( start = loc; start >= limit; start-- ) {
					ch = [ string characterAtIndex:start ] & 0xff ;
					if ( exchChar[ch] == 0 ) break ;
				}
				start++ ;
				limit = start+15 ;
				if ( limit > length ) limit = length ;
				for ( end = start; end < limit; end++ ) {
					ch = [ string characterAtIndex:end ] & 0xff ;
					if ( exchChar[ch] == 0 ) break ;
				}
				end-- ;
				
				length = end-start+1 ;
				//  too short to be exchange
				if ( length <= 0 ) return NSMakeRange(0,0) ;
				
				return NSMakeRange(start,length) ;
			}
		}
	}
	return NSMakeRange(0,0) ;
}

- (void)upperCase:(NSString*)string into:(char*)cstr
{
	int i, n, v ;
	
	n = [ string length ] ;
	if ( n > 30 ) {
		//  too long to worry about
		strncpy( cstr, [ string cStringUsingEncoding:kTextEncoding ], 30 ) ;
	} 
	else {
		strcpy( cstr, [ string cStringUsingEncoding:kTextEncoding ] ) ;
		for ( i = 0; i < n; i++ ) {
			v = cstr[i] & 0xff ;													// v0.25
			if ( v == 216 || v == 175 ) /* slashed zero */ cstr[i] = '0' ;			// v0.25
			else if ( v >= 'a' && v <= 'z' ) {
				v += 'A' - 'a' ;
				cstr[i] = v ;
			}
		}
	}
	cstr[30] = 0 ;
}

- (void)keyModifierChanged:(NSNotification*)notify
{
	unsigned int flags ;
	
	flags = [ (Application*)[ notify object ] keyboardModifierFlags ] ;	
	controlKeyState = ( ( flags & NSControlKeyMask ) != 0 ) ;
	shiftKeyState = ( ( flags & NSShiftKeyMask ) != 0 ) ; 
	optionKeyState = ( ( flags & NSAlternateKeyMask ) != 0 ) ;
}

//  similar to the textView:willChangeSelectionFromCharacterRange: delegate for NSTextView in RTTY and PSK
- (NSRange)captureCallsign:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{
	NSRange range ;
	NSTextStorage *storage ;
	NSString *string ;
	
	//  select callsign field if control-click or right click
	if ( [ (ExchangeView*)textView getAndClearRightMouse ] ) {
		//  only handle simple clicks without dragging
		if ( newSelectedCharRange.length > 0 ) return oldSelectedCharRange ;
		range = [ self getCallsignString:textView from:newSelectedCharRange ] ;
		if ( range.length <= 0 ) return oldSelectedCharRange ;
		
		storage = [ textView textStorage ] ;
		string = [ [ storage attributedSubstringFromRange:range ] string ] ;
		if ( string && [ string length ] < 32 ) {
			[ self upperCase:string into:captured ] ;
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"CapturedCallsign" object:self ] ;
		}
		return range ;
	}
	return newSelectedCharRange ;
}

//  capture the current text selection
- (void)captureSelection:(NSTextView*)textView
{
	NSRange range ;
	NSTextStorage *storage ;
	NSString *string ;
	
	range = [ textView selectedRange ] ;
	if ( range.length > 0 ) {
		storage = [ textView textStorage ] ;
		string = [ [ storage attributedSubstringFromRange:range ] string ] ;
		[ [ manager appObject ] saveSelectedString:string view:textView ] ;
	}
}

//  ---- AppleScript support ----

//  spectrum window
- (NSAppleEventDescriptor*)spectrumPosition 
{
	NSAppleEventDescriptor *desc ;
	
	desc = [ NSAppleEventDescriptor listDescriptor ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:0 ] atIndex:1 ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:0 ] atIndex:2 ] ;
	return desc ;
}

- (void)setSpectrumPosition:(NSAppleEventDescriptor*)point 
{
}

//  respond to a select <modem> command
- (void)selectModem:(NSScriptCommand*)command
{
	[ manager selectModem:self ] ;
}

//  poll the transceivers (round robin)
- (NSString*)stream
{
	NSString *g, *received ;
	int i, index ;
	
	g = @"" ;
	lastPolledTransceiver = ( lastPolledTransceiver+1 )%transceivers ;

	for ( i = 0; i < transceivers; i++ ) {
		index = ( i + lastPolledTransceiver )%transceivers ;
		if ( index == 0 ) {
			received = [ transceiver1 getStream ] ;
			if ( [ received length ] ) {
				g = [ @"[1]" stringByAppendingString:received ] ;
				break ;
			}
		}
		else {
			received = [ transceiver2 getStream ] ;
			if ( [ received length ] ) {
				g = [ @"[2]" stringByAppendingString:received ] ;
				break ;
			}
		}
	}
	return g ;
}

- (void)setStream:(NSString*)text
{
	char *s, *t ;
	int index ;
	
	index = 0 ;
	s = t = (char*)[ text cStringUsingEncoding:kTextEncoding ] ;
	if ( s[0] == '[' && s[2] == ']' && ( s[1] == '1' || s[1] == '2' ) ) {
		t = s+3 ;
		index = s[1] - '1' ;
	}
	if ( index >= transceivers ) return ;
	if ( index == 0 ) [ transceiver1 sendStream:t ] ; else [ transceiver2 sendStream:t ] ;
}

- (Transceiver*)transceiver1
{
	return transceiver1 ;
}

- (Transceiver*)transceiver2
{
	return transceiver2 ;
}

- (void)selectTransceiver:(Transceiver*)transceiver andChangeTransmitStateTo:(Boolean)transmit
{
	//  default to single transciever case
	[ self enterTransmitMode:transmit ] ;
}

//  v0.56
- (int)selectedTransceiver
{
	//  default to single transceiver case
	return 1 ;
}

//  AppleScript support (callbacks from Modules)
- (float)frequencyFor:(Module*)module
{
	return 0.0 ;
}

- (void)setFrequency:(float)freq module:(Module*)module
{
	//  override by subclasses
}

- (void)setTimeOffset:(float)offset index:(int)index 
{
	//  override by subclasses
}

- (float)markFor:(Module*)module
{
	return [ self frequencyFor:module ] ;
}

- (void)setMark:(float)freq module:(Module*)module
{
	[ self setFrequency:freq module:module ] ;
}

- (float)spaceFor:(Module*)module
{
	return [ self frequencyFor:module ] ;
}

- (void)setSpace:(float)freq module:(Module*)module ;
{
	[ self setFrequency:freq module:module ] ;
}

- (float)baudFor:(Module*)module
{
	return 45.45 ;
}

- (void)setBaud:(float)rate module:(Module*)module
{
	//  override by subclasses that has baud rate
}

- (Boolean)invertFor:(Module*)module
{
	return NO ;
}

- (void)setInvert:(Boolean)state module:(Module*)module 
{
	//  override by RTTY subclasses
}

- (Boolean)breakinFor:(Module*)module
{
	return NO ;
}

- (void)setBreakin:(Boolean)state module:(Module*)module 
{
	//  override by RTTY subclasses
}

- (Boolean)checkEnable:(Transceiver*)transceiver
{
	ModemConfig *configp ;
	
	configp = [ self configObj:( transceiver == transceiver2 ) ? 1 : 0 ] ;
	return [ configp soundInputActive ] ;
}

- (void)setEnable:(Transceiver*)transceiver to:(Boolean)sense
{
	ModemConfig *configp ;
	
	configp = [ self configObj:( transceiver == transceiver2 ) ? 1 : 0 ] ;
	[ configp setSoundInputActive:sense ] ;
}

//  override by non RTTY subclasses
- (int)modulationCodeFor:(Transceiver*)transceiver
{
	//  default reply to 45 baud RTTY
	return ModulationRTTY45 ;
}

//  override by non RTTY subclasses
- (void)setModulationCodeFor:(Transceiver*)transceiver to:(int)code
{
}

//  override by subclasses to transmit a string
- (void)transmitString:(const char*)s
{
}

- (void)showConfigPanel
{
	// turn off transmit and open config panel
	if ( transmitState == YES ) [ self changeTransmitStateTo:NO ] ;
	[ config openPanel ] ;
}

//  v0.64c  -- open config panel from Applescript
- (Boolean)openConfigPanel
{
	[ self showConfigPanel ] ;
	[ NSApp activateIgnoringOtherApps:YES ] ;
	return YES ;
}

- (void)closeConfigPanel
{
	[ config closePanel ] ;
}

- (float*)waterfallBuffer:(int)index
{
	WaterfallBuffer *buf ;
	float *p ;

	if ( waterfallConsumer == waterfallProducer ) return nil ;
	
	buf = &waterfallBuffer[waterfallConsumer & WATERFALLBUFFERMASK] ;
	p = buf[0] ;	
	waterfallConsumer = ( waterfallConsumer + 1 ) & WATERFALLBUFFERMASK ;

	return p ;
}

//  AppleScripted waterfall support

//  delegate of Waterfall
//  waterfall.m calls back with a 2048 sample floating point buffer (0-5512.5 Hz) 
//	pow( v, 0.25 )*5.52 gives 200 near full scale input and 35.55 at -30 dB (i.e., about 30 dB per 5.62x)
//  we should get one buffer every 371.5 msec

- (void)newFFTBuffer:(float*)buffer
{
	//NSDate *tempDate ;
	WaterfallBuffer *buf ;
	float *p ;
	int i ;
	
	buf = &waterfallBuffer[waterfallProducer & WATERFALLBUFFERMASK] ;
	p = buf[0] ;
	
	for ( i = 0; i < 1024; i++ ) {
		*p++ = buffer[i] ;
	}
	
	//[ waterfallDate autorelease ] ;
	//waterfallDate = [ [ NSDate date ] retain ] ;
	
	waterfallTouched = -[ waterfallDate timeIntervalSinceNow ] ;		//  v0.82
	
	waterfallProducer = ( waterfallProducer + 1 ) & WATERFALLBUFFERMASK ;
}

//  return milliseconds to wait before the client needs to poll for the next spectrum scanline
- (int)nextWaterfallScanline
{
	double elapsed ;
	
	if ( waterfallConsumer != waterfallProducer ) {
		NSLog( @"nextWaterfallScanline ***\n" ) ;
		return 0.0 ;
	}
	
	
	elapsed = -[ waterfallDate timeIntervalSinceNow ] - waterfallTouched ;

	NSLog( @"nextWaterfallScanline %f\n", ( 0.374 - elapsed )*1000 ) ;
	
	if ( elapsed > 0.374 ) return 374 ;
	

	
	return (int)( ( 0.374 - elapsed )*1000 ) ;
}

//  0.64c AppleScript to reset watchdog timer
- (void)resetWatchdog
{
	charactersSinceTimerStarted++ ;
}

//  v0.64c - show controls Applescript
- (void)setShowControls:(Boolean)state
{
	//  overide by Lite RTTY to turn on/off controls window
}

//  v0.64c show spectrum applescript
- (void)setShowSpectrum:(Boolean)state
{
}

//  v0.64c
- (NSAppleEventDescriptor*)controlsPosition 
{
	NSAppleEventDescriptor *desc ;

	desc = [ NSAppleEventDescriptor listDescriptor ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:0 ] atIndex:1 ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:0 ] atIndex:2 ] ;
	return desc ;
}

//  v0.64c
- (void)setControlsPosition:(NSAppleEventDescriptor*)point 
{
}

//	v0.96c
- (void)selectView:(int)index
{
}

@end
