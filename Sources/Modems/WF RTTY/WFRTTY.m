//
//  WFRTTY.m
//  cocoaModem
//
//  Created by Kok Chen on Jan 11 2006.
	#include "Copyright.h"
//

#import "WFRTTY.h"
#import "AppDelegate.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Config.h"
#import "Contest.h"
#import "ContestManager.h"
#import "ExchangeView.h"
#import "FSK.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Module.h"
#import "Plist.h"
#import "RTTYMacros.h"
#import "RTTYModulator.h"
#import "RTTYReceiver.h"
#import "RTTYRxControl.h"
#import "RTTYTxConfig.h"
#import "RTTYWaterfall.h"
#import "Spectrum.h"
#import "Transceiver.h"
#import "WFRTTYConfig.h"

@implementation WFRTTY

//  WFRTTY : ContestInterface : MacroPanel : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr nib:(NSString*)nib
{
	CMTonePair tonepair ;
	float ellipseFatness = 0.9 ;
	
	RTTYConfigSet setA = { 
		LEFTCHANNEL, 
		kWFRTTYMainDevice, 
		kWFRTTYOutputDevice, 
		kWFRTTYOutputLevel, 
		kWFRTTYOutputAttenuator, 
		kWFRTTYMainTone, 
		kWFRTTYMainMark, 
		kWFRTTYMainSpace,
		kWFRTTYMainBaud,
		kWFRTTYMainControlWindow,
		kWFRTTYMainSquelch,
		kWFRTTYMainActive,
		kWFRTTYMainStopBits,
		kWFRTTYMainMode,
		kWFRTTYMainRxPolarity,
		kWFRTTYMainTxPolarity,
		kWFRTTYMainPrefs,
		kWFRTTYMainTextColor,
		kWFRTTYMainSentColor,
		kWFRTTYMainBackgroundColor,
		kWFRTTYMainPlotColor,
		kWFRTTYMainOffset,
		kWFRTTYMainFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kWFRTTYMainAuralMonitor
	} ;

	RTTYConfigSet setB = { 
		RIGHTCHANNEL, 
		kWFRTTYSubDevice, 
		nil, 
		nil, 
		nil, 
		kWFRTTYSubTone, 
		kWFRTTYSubMark, 
		kWFRTTYSubSpace,
		kWFRTTYSubBaud,
		kWFRTTYSubControlWindow,
		kWFRTTYSubSquelch,
		kWFRTTYSubActive,
		kWFRTTYSubStopBits,
		kWFRTTYSubMode,
		kWFRTTYSubRxPolarity,
		kWFRTTYSubTxPolarity,
		kWFRTTYSubPrefs,
		kWFRTTYSubTextColor,
		kWFRTTYSubSentColor,
		kWFRTTYSubBackgroundColor,
		kWFRTTYSubPlotColor,
		kWFRTTYSubOffset,
		kWFRTTYSubFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kWFRTTYSubAuralMonitor
	} ;

	self = [ super initIntoTabView:tabview nib:nib manager:mgr ] ;
	if ( self ) {
		manager = mgr ;

		//  initialize txConfig before rxConfigs (nte at this point rttyRxControls is undefined)
		[ txConfig awakeFromModem:&setA rttyRxControl:nil ] ;
		ptt = [ txConfig pttObject ] ;
		
		a.isAlive = YES ;
		a.control = [ [ RTTYRxControl alloc ] initIntoView:receiverA client:self index:0 ] ;
		a.receiver = [ a.control receiver ] ;
		[ a.receiver createClickBuffer ] ;
		currentRxView = a.view = [ a.control view ] ;
		[ a.view setDelegate:self ] ;		//  text selections, etc
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:NSLocalizedString( @"Main Receiver", nil ) ] ;
		[ a.control setEllipseFatness:ellipseFatness ] ;
		[ configA awakeFromModem:&setA rttyRxControl:a.control txConfig:txConfig ] ;
		[ configA setChannel:0 ] ;
		control[0] = a.control ;
		configObj[0] = configA ;
		txLocked[0] = NO ;
		
		//  v0.78
		[ txConfig setRTTYAuralMonitor:[ a.receiver rttyAuralMonitor ] ] ;
		
		tonepair = [ a.control baseTonePair ] ;
		[ waterfallA setTonePairMarker:&tonepair index:0 ] ;

		b.isAlive = YES ;
		b.control = [ [ RTTYRxControl alloc ] initIntoView:receiverB client:self index:1 ] ;
		b.receiver = [ b.control receiver ] ;
		[ b.receiver createClickBuffer ] ;
		b.view = [ b.control view ] ;
		[ b.view setDelegate:self ] ;		//  text selections, etc
		b.textAttribute = [ b.control textAttribute ] ;
		[ b.control setName:NSLocalizedString( @"Sub Receiver", nil ) ] ;
		[ b.control setEllipseFatness:ellipseFatness ] ;
		[ configB awakeFromModem:&setB rttyRxControl:b.control txConfig:txConfig ] ;	// note:shared txConfig
		[ configB setChannel:1 ] ;
		control[1] = b.control ;
		configObj[1] = configB ;
		txLocked[1] = NO ;
		tonepair = [ b.control baseTonePair ] ;
		[ waterfallB setTonePairMarker:&tonepair index:1 ] ;

		[ configTab setDelegate:self ] ;

		//  AppleScript text callback
		[ a.receiver registerModule:[ transceiver1 receiver ] ] ;
		a.transmitModule = [ transceiver1 transmitter ] ;
		if ( !isLite ) {
			[ b.receiver registerModule:[ transceiver2 receiver ] ] ;
			b.transmitModule = [ transceiver2 transmitter ] ;
		}
	}
	return self ;
}

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	isLite = NO ;
	[ mgr showSplash:@"Creating Wideband RTTY Modem" ] ;
	return [ self initIntoTabView:tabview manager:mgr nib:@"WFRTTY" ] ;
}

//  v0.83
- (void)commonAwakeFromNib
{
	int i ;
	
	[ self awakeFromContest ] ;
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;
		
	[ self initCallsign ] ;
	[ self initColors ] ;
	//  application will set our macros to single RTTY macros ... [ self initMacros ] ;
	
	receiveFrame = [ groupB frame ] ;
	transceiveFrame = [ groupA frame ] ;
	
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
	
	if ( transmitView ) {
		transmitTextAttribute = [ transmitView newAttribute ] ;
		[ transmitView setDelegate:self ] ;
	}
	
	waterfall[0] = waterfallA ;
	waterfall[1] = waterfallB ;
	for ( i = 0; i < 2; i++ ) {
		if ( waterfall[i] ) {
			[ waterfall[i] awakeFromModem ] ;
			[ waterfall[i] enableIndicator:self ] ;
			[ waterfall[i] setWaterfallID:i ] ;
			[ waterfall[i] setFFTDelegate:self ] ;
		}
	}
	
	//  actions
	if ( transmitButton ) [ self setInterface:transmitButton to:@selector(transmitButtonChanged) ] ;	
	if ( transmitSelect ) [ self setInterface:transmitSelect to:@selector(transmitSelectChanged) ] ;	
	if ( contestTransmitSelect ) [ self setInterface:contestTransmitSelect to:@selector(contestTransmitSelectChanged) ] ;	
	[ self setInterface:restoreToneA to:@selector(restoreTone:) ] ;
	[ self setInterface:restoreToneB to:@selector(restoreTone:) ] ;
	[ self setInterface:dynamicRangeA to:@selector(dynamicRangeChanged:) ] ;
	[ self setInterface:dynamicRangeB to:@selector(dynamicRangeChanged:) ] ;
	[ self setInterface:transmitLock to:@selector(txLockChanged) ] ;
}

- (void)awakeFromNib
{
	ident = ( isLite ) ? NSLocalizedString( @"RTTY", nil ) : NSLocalizedString( @"Wideband RTTY", nil ) ;
	[ self commonAwakeFromNib ] ;
}

//  v0.89  also called from Applescript
- (void)flushClickBuffer
{
	[ a.receiver clearClickBuffer ] ;
	if ( b.isAlive ) [ b.receiver clearClickBuffer ] ;
}

//  ModemManager calls cleanup to all modems when app is terminating. 
//  v 0.78 Modems should override this if some cleanup is needed, and then call this with [ super cleanup ].
//	For WBRTTY Interface, call both configA and configB
- (void)applicationTerminating
{
	[ configA applicationTerminating ] ;
	[ configB applicationTerminating ] ;
	[ ptt applicationTerminating ] ;			//  v0.89
}

- (CMTappedPipe*)dataClient
{
	return (CMTappedPipe*)self ;
}

//  v0.87  switchModemIn for modem with two configs
- (void)switchModemIn
{
	[ configA setKeyerMode ] ;
	[ configB setKeyerMode ] ;
}

- (void)setupSpectrum
{
	int i ;
	
	for ( i = 0; i < 2; i++ ) if ( waterfall[i] ) [ control[i] setWaterfall:waterfall[i] ] ;
}

//	v1.02b
- (void)directSetFrequency:(float)freq
{
	[ self clicked:freq secondsAgo:0.0 option:NO fromWaterfall:NO waterfallID:0 ] ;
}

//	v1.02b
- (float)selectedFrequency
{
	if ( control[0] == nil ) return 0.0 ;
	
	return [ control[0] rxTonePair ].mark ;
}

- (void)setVisibleState:(Boolean)visible
{
	//  update things in the contest interface
	if ( contestBar ) [ contestBar cancel ] ;
	if ( visible == YES ) {
		if ( contestManager ) {
			[ contestManager setActiveContestInterface:self ] ;
		}
		//  setup repeating macro bar
		if ( contestBar ) [ contestBar setModem:self ] ;
		[ self updateContestMacroButtons ] ;
	}
	//  update both configA and configB visibility
	[ configA updateVisibleState:visible ] ;
	[ configB updateVisibleState:visible ] ;
	//  v0.78 to turn AuralMonitor on and off
	if ( a.receiver ) [ a.receiver makeReceiverActive:visible ] ;
	if ( b.receiver ) [ b.receiver makeReceiverActive:visible ] ;
}

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating Wideband RTTY sound source" ] ;
	[ a.control setupRTTYReceiver ] ;
	[ b.control setupRTTYReceiver ] ;
	[ self setupSpectrum ] ;
	[ txConfig checkActive ] ;		// setup txConfig first
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

- (void)transmitFrom:(int)index
{
	transmitChannel = index ;
	
	if ( transmitChannel == 0 ) {
		[ a.control useAsTransmitTonePair:YES ] ;
		[ b.control useAsTransmitTonePair:NO ] ;
		[ txConfig setupTonesFrom:a.control lockTone:txLocked[0] ] ;
		currentRxView = a.view ;
	}
	else {
		[ a.control useAsTransmitTonePair:NO ] ;
		[ b.control useAsTransmitTonePair:YES ] ;
		[ txConfig setupTonesFrom:b.control lockTone:txLocked[1] ] ;
		currentRxView = b.view ;
	}
}

- (void)setIgnoreNewline:(Boolean)state
{
	[ a.view setIgnoreNewline:state ] ;
	[ b.view setIgnoreNewline:state ] ;
}

- (Boolean)transmitIsLocked:(int)index
{
	return ( [ [ transmitLock cellAtRow:0 column:index ] state ] == NSOnState ) ;
}

//  v0.88b
- (void)changeTransmitStateTo:(Boolean)state
{
	Boolean txFixed ;
	FSK *fsk ;
	WFRTTYConfig *cfg ;
	int index, ook, transmitType ;
		
	if ( state ) {
		txFixed = [ self transmitIsLocked:transmitChannel ] ;
		//  if transmit tones are locked, set transmit with locked tone
		[ txConfig setupTonesFrom:control[transmitChannel] lockTone:txFixed ] ;
	}	
	index = [ transmitSelect selectedColumn ] ;
	cfg = ( index == 0 ) ? configA : configB ;
	fsk = [ cfg fsk ] ;
	ook = [ self ook:cfg ] ;
	
	//  transmitType = 0:AFSK, 1:FSK, 2:OOK
	if ( ook != 0 ) transmitType = 2 ;
	else {
		if ( fsk == nil ) transmitType = 0 ; else transmitType = ( [ fsk useSelectedPort ] <= 0 ) ? 0 : 1 ;
	}
	[ [ a.receiver rttyAuralMonitor ] setTransmitState:state transmitType:transmitType ] ;							//  v0.88b

	transmitState = [ txConfig turnOnTransmission:state button:transmitButton fsk:fsk ook:ook ] ;					//  v0.85
	[ self performSelectorOnMainThread:@selector(finishTransmitStateChange) withObject:nil waitUntilDone:YES ] ;	//  v0.65
}

//	v0.88  original -changeTransmitStateTo for WBCW
- (void)changeNonAuralTransmitStateTo:(Boolean)state
{
	Boolean txFixed ;
	FSK *fsk ;
	WFRTTYConfig *cfg ;
	int index ;
	
	if ( state ) {
		txFixed = [ self transmitIsLocked:transmitChannel ] ;
		//  if transmit tones are locked, set transmit with locked tone
		[ txConfig setupTonesFrom:control[transmitChannel] lockTone:txFixed ] ;
	}	
	index = [ transmitSelect selectedColumn ] ;
	cfg = ( index == 0 ) ? configA : configB ;
	fsk = [ cfg fsk ] ;
	
	transmitState = [ txConfig turnOnTransmission:state button:transmitButton fsk:fsk ook:[ self ook:cfg ] ] ;			//  v0.85
	[ self performSelectorOnMainThread:@selector(finishTransmitStateChange) withObject:nil waitUntilDone:YES ] ;	//  v0.65
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
	[ super setTextColor:inTextColor sentColor:sentTColor backgroundColor:bgColor plotColor:pColor ] ;

	[ a.view setBackgroundColor:bgColor ] ;
	[ b.view setBackgroundColor:bgColor ] ;
	
	[ a.view setTextColor:textColor attribute:[ a.control textAttribute ] ] ;
	[ b.view setTextColor:textColor attribute:[ b.control textAttribute ] ] ;

	[ a.control setPlotColor:plotColor ] ;
	[ b.control setPlotColor:plotColor ] ;
}

- (void)setupDefaultPreferencesFromSuper:(Preferences*)pref
{
	[ super setupDefaultPreferences:pref ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kWFRTTYFontA ] ;
	[ pref setFloat:14.0 forKey:kWFRTTYFontSizeA ] ;
	[ pref setString:@"Verdana" forKey:kWFRTTYFontB ] ;
	[ pref setFloat:14.0 forKey:kWFRTTYFontSizeB ] ;
	
	[ pref setString:@"Verdana" forKey:kWFRTTYTxFont ] ;
	[ pref setFloat:14.0 forKey:kWFRTTYTxFontSize ] ;
	[ pref setInt:1 forKey:kRTTYMainWaterfallNR ] ;
	[ pref setInt:1 forKey:kRTTYSubWaterfallNR ] ;
		
	[ pref setInt:0 forKey:kWFRTTYTransmitChannel ] ;
	[ pref setInt:0 forKey:kWFRTTYLockA ] ;
	[ pref setInt:0 forKey:kWFRTTYLockB ] ;

	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kWFRTTYMainTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kWFRTTYMainSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kWFRTTYMainBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kWFRTTYMainPlotColor ] ;
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kWFRTTYSubTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kWFRTTYSubSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kWFRTTYSubBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kWFRTTYSubPlotColor ] ;
	
	[ configA setupDefaultPreferences:pref rttyRxControl:a.control ] ;
	[ configB setupDefaultPreferences:pref rttyRxControl:b.control ] ;

	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (RTTYMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
}

- (Boolean)updateFromPlistFromSuper:(Preferences*)pref
{
	return [ super updateFromPlist:pref ] ;
}

//  disable transmit lock buttons if FSK is used
- (void)afskChanged:(int)order config:(RTTYConfig*)cfg
{
	int index ;
	
	index = ( cfg == configA ) ? 0 : 1 ;
	[ [ transmitLock cellAtRow:0 column:index ] setEnabled:( order == 0 ) ] ;
}

- (void)setTransmitLockButton:(int)index toState:(Boolean)locked
{
	[ [ transmitLock cellAtRow:0 column:index ] setState:( locked ) ? NSOnState : NSOffState ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	int txChannel ;
	Boolean locked ;
	
	[ super updateFromPlist:pref ] ;
	
	fontName = [ pref stringValueForKey:kWFRTTYFontA ] ;
	fontSize = [ pref floatValueForKey:kWFRTTYFontSizeA ] ;
	[ a.view setTextFont:fontName size:fontSize attribute:[ a.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kWFRTTYFontB ] ;
	fontSize = [ pref floatValueForKey:kWFRTTYFontSizeB ] ;
	[ b.view setTextFont:fontName size:fontSize attribute:[ b.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kWFRTTYTxFont ] ;
	fontSize = [ pref floatValueForKey:kWFRTTYTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	txChannel = [ pref intValueForKey:kWFRTTYTransmitChannel ] ;
	[ self transmitFrom:txChannel ] ;
	[ transmitSelect selectCellAtRow:0 column:txChannel ] ;
	[ contestTransmitSelect selectCellAtRow:0 column:txChannel ] ;
	//  update visual interfaces
	[ self transmitSelectChanged ] ;
	
	locked = ( [ pref intValueForKey:kWFRTTYLockA ] != 0 ) ;
	[ self setTransmitLockButton:0 toState:locked ] ;
	[ control[0] setTransmitLock:locked ] ;
	txLocked[0] = locked ;
	
	locked = ( [ pref intValueForKey:kWFRTTYLockB ] != 0 ) ;
	[ self setTransmitLockButton:1 toState:locked ] ;
	[ control[1] setTransmitLock:locked ] ;
	txLocked[1] = locked ;
	
	//  v0.73
	[ waterfallA setNoiseReductionState:[ pref intValueForKey:kRTTYMainWaterfallNR ] ] ;
	[ waterfallB setNoiseReductionState:[ pref intValueForKey:kRTTYSubWaterfallNR ] ] ;
	
	[ manager showSplash:@"Updating WFRTTY configurations" ] ;
	[ configA updateFromPlist:pref rttyRxControl:a.control ] ;	
	[ configB updateFromPlist:pref rttyRxControl:b.control ] ;
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;

	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

- (void)retrieveForPlistFromSuper:(Preferences*)pref
{
	[ super retrieveForPlist:pref ] ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	
	[ super retrieveForPlist:pref ] ;
	
	if ( [ [ NSApp delegate ] isLite ] == NO ) {		//  v0.64d don't play with fonts of Lite window
		font = [ a.view font ] ;
		[ pref setString:[ font fontName ] forKey:kWFRTTYFontA ] ;
		[ pref setFloat:[ font pointSize ] forKey:kWFRTTYFontSizeA ] ;
		font = [ b.view font ] ;
		[ pref setString:[ font fontName ] forKey:kWFRTTYFontB ] ;
		[ pref setFloat:[ font pointSize ] forKey:kWFRTTYFontSizeB ] ;
		
		font = [ transmitView font ] ;
		[ pref setString:[ font fontName ] forKey:kWFRTTYTxFont ] ;
		[ pref setFloat:[ font pointSize ] forKey:kWFRTTYTxFontSize ] ;
	}
	
	[ pref setInt:transmitChannel forKey:kWFRTTYTransmitChannel ] ;
	
	[ pref setInt:( ( [ self transmitIsLocked:0 ] ) ? 1 : 0 ) forKey:kWFRTTYLockA ] ;
	[ pref setInt:( ( [ self transmitIsLocked:1 ] ) ? 1 : 0 ) forKey:kWFRTTYLockB ] ;
	
	//  v0.73
	[ pref setInt:[ waterfallA noiseReductionState ] forKey:kRTTYMainWaterfallNR ] ;
	[ pref setInt:[ waterfallB noiseReductionState ] forKey:kRTTYSubWaterfallNR ] ;

	[ configA retrieveForPlist:pref rttyRxControl:a.control ] ;
	[ configB retrieveForPlist:pref rttyRxControl:b.control ] ;
}

// ----------------------------------------------------------------

- (void)showConfigPanel
{
	// turn off transmit and open config panel
	if ( transmitState == YES ) [ self changeTransmitStateTo:NO ] ;
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
	int channel ;
	
	channel = ( ctrl == control[0] ) ? 0 : 1 ;
	sideband = [ ctrl sideband ] ;	
	tonepair = ( txLocked[channel] ) ? [ ctrl lockedTxTonePair ] : [ ctrl baseTonePair ] ;
	
	if ( waterfall[channel] ) {
		[ waterfall[channel] setSideband:sideband ] ;
		[ waterfall[channel] setTonePairMarker:&tonepair index:channel ] ; 
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

//  v0.64e -- set click history from AppleScript
- (void)setTimeOffset:(float)timeOffset index:(int)index
{
	RTTYRxControl *ctrl ;

	if ( transmitState == NO ) {
		ctrl = control[ index&1 ] ;
		[ [ ctrl receiver ] clicked:timeOffset ] ;
	}
}

//  waterfall clicked
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)waterfallChannel
{
	CMTonePair rxTonepair ;
	float shift, delta ;
	int sideband ;
	RTTYRxControl *ctrl ;
	WFRTTYConfig *cfg ;
	
	if ( [ txConfig transmitActive ] ) return ;			// don't obey clicks when transmitting
	
	waterfallChannel &= 1 ;
	ctrl = control[ waterfallChannel ] ;
	rxTonepair = [ ctrl baseTonePair ] ;	
	shift = fabs( rxTonepair.mark - rxTonepair.space ) ;
	delta = freq-rxTonepair.mark ;
	sideband = [ ctrl sideband ] ;	
		
	if ( option ) {	
		// control clicked
		[ ctrl setRIT:delta ] ;
		return ;
	}
	
	// clear RIT if not control clicked
	[ ctrl setRIT:0.0 ] ;
	if ( sideband == 0 ) {
		rxTonepair.mark = freq ;
		rxTonepair.space = freq + shift ;
	}
	else {
		rxTonepair.mark = freq - shift ;
		rxTonepair.space = freq ;
	}
	[ ctrl setTonePair:&rxTonepair ] ;
	
	cfg = configObj[ waterfallChannel ] ;
	
	if ( acquire ) {
		[ [ ctrl receiver ] clicked:secs ] ;
	}
	[ [ [ NSApp delegate ] application ] setDirectFrequencyFieldTo:freq ] ;
}

- (void)txLockChanged
{
	CMTonePair tonepair ;
	Boolean wasLocked, nowLocked ;
	RTTYRxControl *ctrl ;
	int channel ;
	
	for ( channel = 0; channel < 2; channel++ ) {
		wasLocked = txLocked[ channel ] ;
		ctrl = control[ channel ] ;
		nowLocked =  [ self transmitIsLocked:channel ] ;
		txLocked[channel] = nowLocked ;
		[ ctrl setTransmitLock:nowLocked ] ;
		if ( wasLocked != nowLocked ) {
			[ control[channel] setTransmitLock:nowLocked ] ;
			tonepair = [ ctrl baseTonePair ] ;
			if ( waterfall[channel] ) [ waterfall[channel] setTonePairMarker:&tonepair index:channel ] ; 
			if ( nowLocked ) {
				//  show the locked Tx Tone pair
				tonepair = [ ctrl lockedTxTonePair ] ;
			}
			else {
				//  lock tx to rx
				tonepair.mark = tonepair.space = 0 ;
			}
			if ( waterfall[channel] ) [ waterfall[channel] setTransmitTonePairMarker:&tonepair index:channel ] ; 
		}
	}
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

	w = ( sender == dynamicRangeA ) ? waterfall[0] : waterfall[1] ;
	[ w setDynamicRange:[ [ sender selectedItem ] tag ]*1.0 ] ;
}

- (void)transmitSelectChanged
{
	int index ;
	NSBox *receiveBox, *transceiveBox ;
	
	index = [ transmitSelect selectedColumn ] ;
	
	//  move interfaces
	if ( index == 0 ) {
		//  receiverA = transceive
		transceiveBox = groupA ;
		receiveBox = groupB ;
	}
	else {
		//  receiverB = transceive
		transceiveBox = groupB ;
		receiveBox = groupA ;
	}
	[ transceiveBox setFrame:transceiveFrame ] ;
	[ groupA setNeedsDisplay:YES ] ;
	
	if ( !isLite ) {
		[ receiveBox setFrame:receiveFrame ] ;
		[ groupB setNeedsDisplay:YES ] ;
	}
	
	[ contestTransmitSelect selectCellAtRow:0 column:index ] ;
	[ self transmitFrom:index ] ;
}

- (void)contestTransmitSelectChanged
{
	int index ;
	
	index = [ contestTransmitSelect selectedColumn ] ;
	[ transmitSelect selectCellAtRow:0 column:index ] ;
	[ self transmitSelectChanged ] ;
	[ self transmitFrom:index ] ;
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

//  v0.76 added RTTY Monitor to WFRTTY
- (void)showScope
{
	[ a.control showMonitor ] ;
}

//	v0.96c
- (void)selectView:(int)index
{
	NSView *pview ;
	
	pview = nil ;
	switch ( index ) {
	case 1:
		pview = [ a.control view ] ;
		break ;
	case 2:
		pview = [ b.control view ] ;
		break ;
	case 0:
		pview = transmitView ;
		break ;
	}
	if ( pview ) [ [ pview window ] makeFirstResponder:pview ] ;
}

@end
