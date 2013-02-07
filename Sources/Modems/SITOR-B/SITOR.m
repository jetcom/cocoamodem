//
//  SITOR.m
//  cocoaModem
//
//  Created by Kok Chen on Feb 6 2006.
	#include "Copyright.h"
//

#import "SITOR.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Config.h"
#import "Contest.h"
#import "WFRTTYConfig.h"
#import "ExchangeView.h"
#import "ModemSource.h"
#import "Module.h"
#import "Plist.h"
#import "RTTYReceiver.h"
#import "RTTYTxConfig.h"
#import "RTTYWaterfall.h"
#import "SITORDemodulator.h"
#import "SITORReceiver.h"
#import "SITORRxControl.h"
#import "Spectrum.h"
#import "StdManager.h"

#import "Transceiver.h"

@implementation SITOR

//  SITOR : (ContestInterface) : (MacroPanel) : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	CMTonePair tonepair ;
	float ellipseFatness = 0.9 ;
	
	[ mgr showSplash:@"Creating SITOR-B Modem" ] ;
	
	RTTYConfigSet setA = { 
		LEFTCHANNEL, 
		kSitorMainDevice, 
		nil, 
		nil, 
		nil, 
		kSitorMainTone, 
		kSitorMainMark, 
		kSitorMainSpace,
		kSitorMainBaud,
		kSitorMainControlWindow,
		kSitorMainSquelch,
		kSitorMainActive,
		nil,
		kSitorMainMode,
		kSitorMainRxPolarity,
		nil,
		kSitorMainPrefs,
		kSitorMainTextColor,
		nil,
		kSitorMainBackgroundColor,
		kSitorMainPlotColor,
		kSitorMainOffset,
		nil,
		NO,							// usesRTTYAuralMonitor
		nil							// no RTTYAuralMonitor
	} ;

	RTTYConfigSet setB = { 
		RIGHTCHANNEL, 
		kSitorSubDevice, 
		nil, 
		nil, 
		nil, 
		kSitorSubTone, 
		kSitorSubMark, 
		kSitorSubSpace,
		kSitorSubBaud,
		kSitorSubControlWindow,
		kSitorSubSquelch,
		kSitorSubActive,
		kSitorSubStopBits,
		kSitorSubMode,
		kSitorSubRxPolarity,
		nil,
		kSitorSubPrefs,
		kSitorSubTextColor,
		nil,
		kSitorSubBackgroundColor,
		kSitorSubPlotColor,
		kSitorSubOffset,
		nil,
		NO,							// usesRTTYAuralMonitor
		nil							// no RTTYAuralMonitor
	} ;

	self = [ super initIntoTabView:tabview nib:@"SITOR" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		
		a.isAlive = YES ;
		a.control = [ [ SITORRxControl alloc ] initIntoView:receiverA client:self index:0 ] ;
		a.receiver = [ a.control receiver ] ;
		currentRxView = a.view = [ a.control view ] ;
		[ a.view setDelegate:self ] ;		//  text selections, etc
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:@"Receiver A" ] ;
		[ a.control setEllipseFatness:ellipseFatness ] ;
		[ configA awakeFromModem:&setA rttyRxControl:a.control txConfig:nil ] ;
		[ configA setChannel:0 ] ;
		
		tonepair = [ a.control baseTonePair ] ;
		[ waterfallA setTonePairMarker:&tonepair index:0 ] ;

		b.isAlive = YES ;
		b.control = [ [ SITORRxControl alloc ] initIntoView:receiverB client:self index:1 ] ;
		b.receiver = [ b.control receiver ] ;
		b.view = [ b.control view ] ;
		[ b.view setDelegate:self ] ;		//  text selections, etc
		b.textAttribute = [ b.control textAttribute ] ;
		[ b.control setName:@"Receiver B" ] ;
		[ b.control setEllipseFatness:ellipseFatness ] ;
		[ configB awakeFromModem:&setB rttyRxControl:b.control txConfig:nil ] ;
		[ configB setChannel:1 ] ;

		tonepair = [ b.control baseTonePair ] ;
		[ waterfallB setTonePairMarker:&tonepair index:1 ] ;
		
		[ configTab setDelegate:self ] ;

		//  AppleScript text callback
		[ a.receiver registerModule:[ transceiver1 receiver ] ] ;
		[ b.receiver registerModule:[ transceiver2 receiver ] ] ;
	}
	return self ;
}

- (void)awakeFromNib
{
	ident = NSLocalizedString( @"SITOR-B", nil )  ;


	[ self awakeFromContest ] ;
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;
	
	[ self initColors ] ;
	
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
	
	[ waterfallA awakeFromModem ] ;
	[ waterfallA enableIndicator:self ] ;
	[ waterfallA setWaterfallID:0 ] ;

	[ waterfallB awakeFromModem ] ;
	[ waterfallB enableIndicator:self ] ;
	[ waterfallB setWaterfallID:1 ] ;
	
	[ self setInterface:restoreToneA to:@selector(restoreTone:) ] ;
	[ self setInterface:restoreToneB to:@selector(restoreTone:) ] ;
	[ self setInterface:dynamicRangeA to:@selector(dynamicRangeChanged:) ] ;
	[ self setInterface:dynamicRangeB to:@selector(dynamicRangeChanged:) ] ;
}

- (void)enterTransmitMode:(Boolean)state
{
	// do nothing
}

- (void)flushAndLeaveTransmit
{
	// do nothing
}

- (CMTappedPipe*)dataClient
{
	return (CMTappedPipe*)self ;
}

- (void)setupSpectrum
{
	[ a.control setWaterfall:waterfallA ] ;
	[ b.control setWaterfall:waterfallB ] ;
}

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating SITOR-B sound source" ] ;
	[ a.control setupRTTYReceiver ] ;
	[ b.control setupRTTYReceiver ] ;
	[ self setupSpectrum ] ;
	[ configA checkActive ] ;
	[ configB checkActive ] ;
}

- (void)setSentColor:(Boolean)state
{
	if ( [ transmitSelect selectedColumn ] == 0 ) {
		[ self setSentColor:state view:a.view textAttribute:a.textAttribute ] ;
	}
	else {
		[ self setSentColor:state view:b.view textAttribute:b.textAttribute ] ;
	}
}

- (int)configChannelSelected
{
	return [ configTab indexOfTabViewItem:[ configTab selectedTabViewItem ] ] ;
}

- (ModemConfig*)configObj:(int)index
{
	return ( index == 0 ) ? configA : configB ;
}

//  return the input attenuator (NSSlider) of the appropriate receiver bank
- (NSSlider*)inputAttenuator:(ModemConfig*)configp
{	
	if ( configp == configA && a.control ) {
		return [ a.control inputAttenuator ] ;
	}
	if ( configp == configB && b.control ) {
		return [ b.control inputAttenuator ] ;
	}
	return nil ;
}

- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor forReceiver:(int)rx 
{
	if ( rx == 0 ) {
		[ super setTextColor:inTextColor sentColor:sentTColor backgroundColor:bgColor plotColor:pColor ] ;
		[ a.view setBackgroundColor:bgColor ] ;
		[ a.view setTextColor:inTextColor attribute:[ a.control textAttribute ] ] ;
		[ a.control setPlotColor:pColor ] ;
	}
	else {
		[ b.view setBackgroundColor:bgColor ] ;
		[ b.view setTextColor:inTextColor attribute:[ b.control textAttribute ] ] ;
		[ b.control setPlotColor:pColor ] ;
	}
}

- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor
{
	[ a.view setBackgroundColor:bgColor ] ;
	[ b.view setBackgroundColor:bgColor ] ;
	
	[ a.control setPlotColor:plotColor ] ;
	[ b.control setPlotColor:plotColor ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ super setupDefaultPreferencesFromSuper:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kSitorFontA ] ;
	[ pref setFloat:14.0 forKey:kSitorFontSizeA ] ;
	[ pref setString:@"Verdana" forKey:kSitorFontB ] ;
	[ pref setFloat:14.0 forKey:kSitorFontSizeB ] ;
	
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kSitorMainTextColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kSitorMainBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kSitorMainPlotColor ] ;
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kSitorSubTextColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kSitorSubBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kSitorSubPlotColor ] ;
	
	[ configA setupDefaultPreferences:pref rttyRxControl:a.control ] ;
	[ configB setupDefaultPreferences:pref rttyRxControl:b.control ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	
	[ super updateFromPlistFromSuper:pref ] ;	

	fontName = [ pref stringValueForKey:kSitorFontA ] ;
	fontSize = [ pref floatValueForKey:kSitorFontSizeA ] ;
	[ a.view setTextFont:fontName size:fontSize attribute:[ a.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kSitorFontB ] ;
	fontSize = [ pref floatValueForKey:kSitorFontSizeB ] ;
	[ b.view setTextFont:fontName size:fontSize attribute:[ b.control textAttribute ] ] ;
	
	[ configA updateFromPlist:pref rttyRxControl:a.control ] ;
	[ configB updateFromPlist:pref rttyRxControl:b.control ] ;
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
	
	[ super retrieveForPlistFromSuper:pref ] ;
	
	font = [ a.view font ] ;
	[ pref setString:[ font fontName ] forKey:kSitorFontA ] ;
	[ pref setFloat:[ font pointSize ] forKey:kSitorFontSizeA ] ;
	font = [ b.view font ] ;
	[ pref setString:[ font fontName ] forKey:kSitorFontB ] ;
	[ pref setFloat:[ font pointSize ] forKey:kSitorFontSizeB ] ;
	
	[ configA retrieveForPlist:pref rttyRxControl:a.control ] ;
	[ configB retrieveForPlist:pref rttyRxControl:b.control ] ;
}

// ----------------------------------------------------------------

- (void)showConfigPanel
{
	// turn off transmit and open config panel
	[ configA openPanel ] ;				// use configA to open the same common panel
	if ( [ self configChannelSelected ] == 0 ) [ configA setConfigOpen:YES ] ; else [ configB setConfigOpen:YES ] ;
}

- (void)closeConfigPanel
{
	[ configA closePanel ] ;
	[ configB closePanel ] ;
}

- (void)tonePairChanged:(RTTYRxControl*)ctrl
{
	CMTonePair tonepair ;
	float sideband ;
	
	tonepair = [ ctrl baseTonePair ] ;
	sideband = [ ctrl sideband ] ;
	if ( ctrl == a.control ) {
		[ waterfallA setSideband:sideband ] ;
		[ waterfallA setTonePairMarker:&tonepair index:0 ] ; 
	}
	else {
		[ waterfallB setSideband:sideband ] ;
		[ waterfallB setTonePairMarker:&tonepair index:1 ] ;
	}
}

- (void)activeChanged:(ModemConfig*)cfg
{
	Boolean active ;
	
	active = [ cfg soundInputActive ] ;
	if ( cfg == configA ) {
		[ waterfallA setActive:active index:0 ] ; 
	}
	else {
		[ waterfallB setActive:active index:0 ] ; 
	}
}

//  waterfall clicked
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)waterfallChannel
{
	CMTonePair tonepair ;
	RTTYTransceiver *transceiver ;
	float shift, delta ;
	int sideband ;
	
	transceiver = ( waterfallChannel == 0 ) ? &a : &b ;
	tonepair = [ transceiver->control baseTonePair ] ;	
	sideband = [ transceiver->control sideband ] ;	
	
	// no adjustment freq += ( sideband == 0 ) ? 2.7 : -2.7 ;			// adjust for cursor position 
	
	if ( option ) {	
		// control clicked
		delta = freq-tonepair.mark ;
		[ transceiver->control setRIT:delta ] ;
		return ;
	}
	
	// clear RIT if not control clicked
	[ transceiver->control setRIT:0.0 ] ;
	shift = fabs( tonepair.mark - tonepair.space ) ;
	if ( sideband == 0 ) {
		tonepair.mark = freq ;
		tonepair.space = freq + shift ;
	}
	else {
		tonepair.mark = freq - shift ;
		tonepair.space = freq ;
	}
	[ transceiver->control setTonePair:&tonepair ] ;
	
	[ [ [ NSApp delegate ] application ] setDirectFrequencyFieldTo:freq ] ;
}

- (void)restoreTone:(id)sender
{
	RTTYTransceiver *transceiver ;

	transceiver = ( sender == restoreToneA ) ? &a : &b ;
	[ transceiver->control setRIT:0.0 ] ;
	[ transceiver->control fetchTonePairFromMemory ] ;
	[ transceiver->control updateTonePairInformation ] ;	// resets tone to memory settings
}

- (void)dynamicRangeChanged:(id)sender
{
	RTTYWaterfall *w ;

	w = ( sender == dynamicRangeA ) ? waterfallA : waterfallB ;
	[ w setDynamicRange:[ [ sender selectedItem ] tag ]*1.0 ] ;
}

- (void)transmitSelectChanged
{
}

- (void)contestTransmitSelectChanged
{
}

//  NSMatrix of NSButtons from Preferences
//  SITOR-B is subclassed from RTTYInterface but has a different pref matrix from the other RTTY modes.
- (void)setRTTYPrefs:(NSMatrix*)rttyPrefs channel:(int)channel
{
	int i, count, state ;
	NSButton *button ;
	SITORReceiver *rx ;
	
	rx = (SITORReceiver*)( ( channel == 0 ) ? a.receiver : b.receiver ) ;
	
	count = [ rttyPrefs numberOfRows ] ;
	for ( i = 0; i < count; i++ ) {
		button = [ rttyPrefs cellAtRow:i column:0 ] ;
		state = [ button state ] ;
		if ( state == NSOnState ) {
			switch ( i ) {
			case 0:
				//  Unshift On Space
				usos = YES ;
				[ rx setUSOS:usos ] ;
				break ;
			case 1:
				//  Disable Baudot BELL
				bell = NO ;
				[ rx setBell:bell ] ;
				break ;
			case 2:
				//  Enable error print
				[ (SITORDemodulator*)[ rx demodulator ] setErrorPrint:YES ] ;
				break ;
			}
		}
		else {
			switch ( i ) {
			case 0:
				//  Unshift On Space
				usos = NO ;
				[ rx setUSOS:usos ] ;
				break ;
			case 1:
				//  Don't disable Baudot BELL
				bell = YES ;
				[ rx setBell:bell ] ;
				break ;
			case 2:
				//  Disable error print
				[ (SITORDemodulator*)[ rx demodulator ] setErrorPrint:NO ] ;
				break ;
			}
		}
	}
}

//  delegate of WF RTTY's config window, disable config scopes
- (BOOL)windowShouldClose:(id)sender
{
	[ configA setConfigOpen:NO ] ;
	[ configB setConfigOpen:NO ] ;
	return YES ;
}

//  delegate to WF RTTY's config panel tab (main/sub receivers)
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	Boolean selectA ;
	
	selectA = ( [ tabView indexOfTabViewItem:tabViewItem ] == 0 ) ;
	[ configA setConfigOpen:selectA ] ;
	[ configB setConfigOpen:!selectA ] ;
}

@end
