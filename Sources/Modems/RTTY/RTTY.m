//
//  RTTY.m
//  cocoaModem
//
//  Created by Kok Chen on Sun May 30 2004.
	#include "Copyright.h"


#import "RTTY.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Config.h"
#import "Contest.h"
#import "ExchangeView.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Module.h"
#import "Plist.h"
#import "RTTYConfig.h"
#import "RTTYMacros.h"
#import "RTTYModulator.h"
#import "RTTYReceiver.h"
#import "RTTYRxControl.h"
#import "RTTYTxConfig.h"
#import "Transceiver.h"

@implementation RTTY

//  RTTY : ContestInterface : MacroPanel : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	RTTYConfigSet set = { 
		LEFTCHANNEL, 
		kRTTYInputDevice, 
		kRTTYOutputDevice, 
		kRTTYOutputLevel, 
		kRTTYOutputAttenuator, 
		kRTTYTone, 
		kRTTYMark, 
		kRTTYSpace,
		kRTTYBaud,
		nil,
		kRTTYSquelch,
		kRTTYActive,
		kRTTYStopBits,
		kRTTYMode,
		kRTTYRxPolarity,
		kRTTYTxPolarity,
		kRTTYPrefs,
		kRTTYTextColor,
		kRTTYSentColor,
		kRTTYBackgroundColor,
		kRTTYPlotColor,
		nil,
		kRTTYFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kRTTYAuralMonitor
	} ;

	[ mgr showSplash:@"Creating RTTY Modem" ] ;

	self = [ super initIntoTabView:tabview nib:@"RTTY" manager:mgr ] ;
	if ( self ) {
	
		transmitChannel = 0 ;
		isBreakin = NO ;
		
		//  initialize txConfig before rxConfig
		[ txConfig awakeFromModem:&set rttyRxControl:a.control ] ;
		ptt = [ txConfig pttObject ] ;
		
		b.isAlive = NO ;
		[ ctrl setupWithClient:self index:0 ] ;
		a.isAlive = YES ;
		a.control = ctrl ;
		a.receiver = [ a.control receiver ] ;
		a.view = [ a.control view ] ;
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:NSLocalizedString( @"Main Receiver", nil ) ] ;
		[ a.control useAsTransmitTonePair:YES ] ;

		[ config awakeFromModem:&set rttyRxControl:ctrl txConfig:txConfig ] ;

		currentRxView = [ (RTTYRxControl*)ctrl view ] ;
		[ a.receiver setReceiveView:currentRxView ] ;
		
		//  AppleScript text callback
		[ a.receiver registerModule:[ transceiver1 receiver ] ] ;
		a.transmitModule = [ transceiver1 transmitter ] ;
		
		manager = mgr ;
	}
	return self ;
}

- (void)awakeFromNib
{
	ident = NSLocalizedString( @"RTTY", nil ) ;

	[ self awakeFromContest ] ;
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;
	
	//  actions
	[ transmitButton setAction:@selector(transmitButtonChanged) ] ;
	[ transmitButton setTarget:self ] ;

	[ self initCallsign ] ;
	[ self initColors ] ;
	//  [ self initMacros ] ;   RTTY macros moved to StdManager
	
	[ a.control setTuningIndicatorState:YES ] ;
	//  prefs
	usos = robust = NO ;
	bell = YES ;
	charactersSinceTimerStarted = 0 ;
	timeout = nil ;
	transmitBufferCheck = nil ;
	thread = [ NSThread currentThread ] ;
	//  transmit view 
	indexOfUntransmittedText = 0 ;
	transmitState = sentColor = NO ;
	transmitCount = 0 ;
	transmitCountLock = [ [ NSLock alloc ] init ] ;
	//transmitViewLock = [ [ NSLock alloc ] init ] ;		v0.64b
	
	transmitTextAttribute = [ transmitView newAttribute ] ;
	[ transmitView setDelegate:self ] ;
	//  receive view
	receiveTextAttribute = [ receiveView newAttribute ] ;
	[ receiveView setDelegate:self ] ;
}

//  set rxControl to be the first data client for data
- (CMTappedPipe*)dataClient
{
	return (CMTappedPipe*)ctrl ;
}

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating RTTY sound source" ] ;
	[ a.control setupRTTYReceiver ] ;
	[ txConfig checkActive ] ;
	[ config checkActive ] ;
}

- (void)setIgnoreNewline:(Boolean)state
{
	[ receiveView setIgnoreNewline:state ] ;
}

- (ModemConfig*)configObj:(int)index
{
	//  always return the single config (DualRTTY overides with two sepearte configs)
	return config ;
}

- (RTTYConfig*)configObj
{
	return config ;
}

//  display RTTY Monitor
- (void)showScope
{
	[ a.control showMonitor ] ;
}

- (void)hideScopeOnDeactivation:(Boolean)hide
{
	[ a.control hideMonitorOnDeactivation:hide ] ;
}

- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor
{
	[ super setTextColor:inTextColor sentColor:sentTColor backgroundColor:bgColor plotColor:pColor ] ;
	[ a.control setPlotColor:plotColor ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kRTTYFont ] ;
	[ pref setFloat:14.0 forKey:kRTTYFontSize ] ;
	[ pref setString:@"Verdana" forKey:kRTTYTxFont ] ;
	[ pref setFloat:14.0 forKey:kRTTYTxFontSize ] ;
	
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kRTTYTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kRTTYSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kRTTYBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kRTTYPlotColor ] ;
	
	[ (RTTYConfig*)config setupDefaultPreferences:pref rttyRxControl:a.control ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	
	[ super updateFromPlist:pref ] ;
	
	fontName = [ pref stringValueForKey:kRTTYFont ] ;
	fontSize = [ pref floatValueForKey:kRTTYFontSize ] ;
	[ receiveView setTextFont:fontName size:fontSize attribute:receiveTextAttribute ] ;
	
	fontName = [ pref stringValueForKey:kRTTYTxFont ] ;
	fontSize = [ pref floatValueForKey:kRTTYTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	[ manager showSplash:@"Updating RTTY configurations" ] ;
	[ (RTTYConfig*)config updateFromPlist:pref rttyRxControl:a.control ] ;
	
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;

	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	[ super retrieveForPlist:pref ] ;
	
	font = [ receiveView font ] ;
	[ pref setString:[ font fontName ] forKey:kRTTYFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kRTTYFontSize ] ;
	font = [ transmitView font ] ;
	[ pref setString:[ font fontName ] forKey:kRTTYTxFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kRTTYTxFontSize ] ;

	[ (RTTYConfig*)config retrieveForPlist:pref rttyRxControl:a.control ] ;
}

- (NSSlider*)inputAttenuator:(ModemConfig*)config
{	
	if ( ctrl ) {
		return [ ctrl inputAttenuator ] ;
	}
	return nil ;
}

//	v0.96c
- (void)selectView:(int)index
{
	NSView *pview ;
	
	pview = nil ;
	switch ( index ) {
	case 1:
		pview = receiveView ;
		break ;
	case 0:
		pview = transmitView ;
		break ;
	}
	if ( pview ) [ [ pview window ] makeFirstResponder:pview ] ;
}

@end
