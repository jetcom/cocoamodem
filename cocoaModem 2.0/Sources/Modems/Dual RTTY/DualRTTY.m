//
//  DualRTTY.m
//  cocoaModem
//
//  Created by Kok Chen on Sun May 30 2004.
	#include "Copyright.h"
//

#import "DualRTTY.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Config.h"
#import "Contest.h"
#import "ContestManager.h"
#import "DualRTTYConfig.h"
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

@implementation DualRTTY

//  DualRTTY : ContestInterface : MacroPanel : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	RTTYConfigSet setA = { 
		LEFTCHANNEL, 
		kDualRTTYMainDevice, 
		kDualRTTYOutputDevice, 
		kDualRTTYOutputLevel, 
		kDualRTTYOutputAttenuator, 
		kDualRTTYMainTone, 
		kDualRTTYMainMark, 
		kDualRTTYMainSpace,
		kDualRTTYMainBaud,
		kDualRTTYMainControlWindow,
		kDualRTTYMainSquelch,
		kDualRTTYMainActive,
		kDualRTTYMainStopBits,
		kDualRTTYMainMode,
		kDualRTTYMainRxPolarity,
		kDualRTTYMainTxPolarity,
		kDualRTTYMainPrefs,
		kDualRTTYMainTextColor,
		kDualRTTYMainSentColor,
		kDualRTTYMainBackgroundColor,
		kDualRTTYMainPlotColor,
		nil,
		kDualRTTYMainFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kDualRTTYMainAuralMonitor
	} ;

	RTTYConfigSet setB = { 
		RIGHTCHANNEL, 
		kDualRTTYSubDevice, 
		nil, 
		nil, 
		nil, 
		kDualRTTYSubTone, 
		kDualRTTYSubMark, 
		kDualRTTYSubSpace,
		kDualRTTYSubBaud,
		kDualRTTYSubControlWindow,
		kDualRTTYSubSquelch,
		kDualRTTYSubActive,
		kDualRTTYSubStopBits,
		kDualRTTYSubMode,
		kDualRTTYSubRxPolarity,
		kDualRTTYSubTxPolarity,
		kDualRTTYSubPrefs,
		kDualRTTYSubTextColor,
		kDualRTTYSubSentColor,
		kDualRTTYSubBackgroundColor,
		kDualRTTYSubPlotColor,
		nil,
		kDualRTTYSubFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kDualRTTYSubAuralMonitor
	} ;

	[ mgr showSplash:@"Creating Dual RTTY Modem" ] ;

	self = [ super initIntoTabView:tabview nib:@"DualRTTY" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;

		//  initialize txConfig before rxConfigs
		[ txConfig awakeFromModem:&setA rttyRxControl:a.control ] ;
		ptt = [ txConfig pttObject ] ;
		transmitChannel = 0 ;
		
		a.isAlive = YES ;
		a.control = [ [ RTTYRxControl alloc ] initIntoView:receiverA client:self index:0 ] ;
		a.receiver = [ a.control receiver ] ;
		currentRxView = a.view = [ a.control view ] ;
		[ a.view setDelegate:self ] ;		//  text selections, etc
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:NSLocalizedString( @"Main Receiver", nil ) ] ;
		[ configA awakeFromModem:&setA rttyRxControl:a.control txConfig:txConfig ] ;
	
		//  v0.78
		[ txConfig setRTTYAuralMonitor:[ a.receiver rttyAuralMonitor ] ] ;

		b.isAlive = YES ;
		b.control = [ [ RTTYRxControl alloc ] initIntoView:receiverB client:self index:1 ] ;
		b.receiver = [ b.control receiver ] ;
		b.view = [ b.control view ] ;
		[ b.view setDelegate:self ] ;		//  text selections, etc
		b.textAttribute = [ b.control textAttribute ] ;
		[ b.control setName:NSLocalizedString( @"Sub Receiver", nil ) ] ;
		[ (DualRTTYConfig*)configB awakeFromModem:&setB rttyRxControl:b.control txConfig:txConfig ] ;  // note:shared txConfig
			
		[ configTab setDelegate:self ] ;
		[ self setInterface:timeConstant to:@selector(spectrumOptionChanged) ] ;
		[ self setInterface:dynamicRange to:@selector(spectrumOptionChanged) ] ;
		[ self setInterface:channel to:@selector(spectrumOptionChanged) ] ;
		[ self setInterface:transmitSelect to:@selector(transmitSelectChanged) ] ;
		[ self setInterface:contestTransmitSelect to:@selector(contestTransmitSelectChanged) ] ;
		[ self setInterface:restoreToneButton to:@selector(restoreTonePairs) ] ;

		//  AppleScript text callback
		[ a.receiver registerModule:[ transceiver1 receiver ] ] ;
		[ b.receiver registerModule:[ transceiver2 receiver ] ] ;
		a.transmitModule = [ transceiver1 transmitter ] ;
		b.transmitModule = [ transceiver2 transmitter ] ;
	}
	return self ;
}

- (void)awakeFromNib
{
	ident = NSLocalizedString( @"Dual RTTY", nil )  ;
	
	[ self awakeFromContest ] ;
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;
	
	receiveFrame = [ receiverB frame ] ;
	transceiveFrame = [ receiverA frame ] ;
	
	//  actions
	[ transmitButton setAction:@selector(transmitButtonChanged) ] ;
	[ transmitButton setTarget:self ] ;
	
	[ self initCallsign ] ;
	[ self initColors ] ;
	//  application will set our macros to single RTTY macros ... [ self initMacros ] ;
	
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
	
	[ waterfall awakeFromModem ] ;
	[ waterfall setIgnoreSideband:YES ] ;
	[ waterfall setIgnoreArrowKeys:YES ] ;
	[ waterfall enableIndicator:self ] ;
}

- (CMTappedPipe*)dataClient
{
	return (CMTappedPipe*)self ;
}

static float timeConstants[] = { 0.0, 0.2, 0.5, 1.5, 4.0 } ;
static float ranges[] = { 40.0, 50.0, 60.0, 70.0, 80.0 } ;

- (void)setupSpectrum
{
	int t, dr ;
	float tc ;

	switch ( [ channel indexOfSelectedItem ] ) {
	case 0:
		[ b.control setSpectrumView:nil ] ;
		[ b.control setWaterfall:nil ] ;
		[ a.control setSpectrumView:spectrum ] ;
		[ a.control setWaterfall:waterfall ] ;
		break ;
	case 1:
		[ a.control setSpectrumView:nil ] ;
		[ a.control setWaterfall:nil ] ;
		[ b.control setSpectrumView:spectrum ] ;
		[ b.control setWaterfall:waterfall ] ;
		break ;
	default:
		// off
		[ a.control setSpectrumView:nil ] ;
		[ a.control setWaterfall:nil ] ;
		[ b.control setSpectrumView:nil ] ;
		[ b.control setWaterfall:nil ] ;
	}	
	t = [ timeConstant indexOfSelectedItem ] ;
	tc = timeConstants[t] ;
	if ( tc < timeConstants[1] ) {
		// waterfall
		tc = timeConstants[1] ;
		[ dynamicRange setHidden:YES ] ;
		[ spectrum setHidden:YES ] ;
		[ waterfall setHidden:NO ] ;
		[ restoreToneButton setHidden:YES /*NO if we allow clicking*/ ] ;
	}
	else {
		[ dynamicRange setHidden:NO ] ;
		[ waterfall setHidden:YES ] ;
		[ restoreToneButton setHidden:YES ] ;
		[ spectrum setHidden:NO ] ;
		dr = [ dynamicRange indexOfSelectedItem ] ;
		[ spectrum setTimeConstant:tc dynamicRange:ranges[dr] ] ;
		[ spectrum clearPlot ] ;
	}
}

- (void)spectrumOptionChanged
{
	[ self setupSpectrum ] ;
}

- (void)setIgnoreNewline:(Boolean)state
{
	[ a.view setIgnoreNewline:state ] ;
	[ b.view setIgnoreNewline:state ] ;
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
	
	//  v0.78 -- aural monitor
	if ( a.receiver ) [ a.receiver makeReceiverActive:visible ] ;
	if ( b.receiver ) [ b.receiver makeReceiverActive:visible ] ;
}

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating Dual RTTY sound source" ] ;
	[ a.control setupRTTYReceiver ] ;
	[ b.control setupRTTYReceiver ] ;
	[ self setupSpectrum ] ;
	[ txConfig checkActive ] ;
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
		[ txConfig setupTonesFrom:a.control lockTone:NO ] ;
		currentRxView = a.view ;
	}
	else {
		[ a.control useAsTransmitTonePair:NO ] ;
		[ b.control useAsTransmitTonePair:YES ] ;
		[ txConfig setupTonesFrom:b.control lockTone:NO ] ;
		currentRxView = b.view ;
	}
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

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kDualRTTYFontA ] ;
	[ pref setFloat:14.0 forKey:kDualRTTYFontSizeA ] ;
	[ pref setString:@"Verdana" forKey:kDualRTTYFontB ] ;
	[ pref setFloat:14.0 forKey:kDualRTTYFontSizeB ] ;
	
	[ pref setString:@"Verdana" forKey:kDualRTTYTxFont ] ;
	[ pref setFloat:14.0 forKey:kDualRTTYTxFontSize ] ;
		
	[ pref setInt:1 forKey:kDualRTTYSpectrumRange ] ;
	[ pref setInt:1 forKey:kDualRTTYSpectrumChannel ] ;
	[ pref setInt:0 forKey:kDualRTTYSpectrumDecay ] ;
	[ pref setInt:0 forKey:kDualRTTYTransmitChannel ] ;
	
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kDualRTTYMainTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kDualRTTYMainSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kDualRTTYMainBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kDualRTTYMainPlotColor ] ;
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kDualRTTYSubTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kDualRTTYSubSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kDualRTTYSubBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kDualRTTYSubPlotColor ] ;
	
	[ configA setupDefaultPreferences:pref rttyRxControl:a.control ] ;
	[ configB setupDefaultPreferences:pref rttyRxControl:b.control ] ;

	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (RTTYMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	int txChannel ;
	
	[ manager showSplash:@"Updating DualRTTY configurations" ] ;
	[ super updateFromPlist:pref ] ;
	
	fontName = [ pref stringValueForKey:kDualRTTYFontA ] ;
	fontSize = [ pref floatValueForKey:kDualRTTYFontSizeA ] ;
	[ a.view setTextFont:fontName size:fontSize attribute:[ a.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kDualRTTYFontB ] ;
	fontSize = [ pref floatValueForKey:kDualRTTYFontSizeB ] ;
	[ b.view setTextFont:fontName size:fontSize attribute:[ b.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kDualRTTYTxFont ] ;
	fontSize = [ pref floatValueForKey:kDualRTTYTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	[ timeConstant selectItemAtIndex:[ pref intValueForKey:kDualRTTYSpectrumDecay ] ] ;
	[ dynamicRange selectItemAtIndex:[ pref intValueForKey:kDualRTTYSpectrumRange ] ] ;
	[ channel selectItemAtIndex:[ pref intValueForKey:kDualRTTYSpectrumChannel ] ] ;
	
	[ configA updateFromPlist:pref rttyRxControl:a.control ] ;
	[ configB updateFromPlist:pref rttyRxControl:b.control ] ;
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;

	//  preferred transmit channel
	txChannel = [ pref intValueForKey:kDualRTTYTransmitChannel ] ;
	[ self transmitFrom:txChannel ] ;
	[ transmitSelect selectCellAtRow:0 column:txChannel ] ;
	[ contestTransmitSelect selectCellAtRow:0 column:txChannel ] ;
	[ self transmitSelectChanged ] ;
	
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	[ super retrieveForPlist:pref ] ;
	
	font = [ a.view font ] ;
	[ pref setString:[ font fontName ] forKey:kDualRTTYFontA ] ;
	[ pref setFloat:[ font pointSize ] forKey:kDualRTTYFontSizeA ] ;
	font = [ b.view font ] ;
	[ pref setString:[ font fontName ] forKey:kDualRTTYFontB ] ;
	[ pref setFloat:[ font pointSize ] forKey:kDualRTTYFontSizeB ] ;
	
	font = [ transmitView font ] ;
	[ pref setString:[ font fontName ] forKey:kDualRTTYTxFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kDualRTTYTxFontSize ] ;
	
	[ pref setInt:[ timeConstant indexOfSelectedItem ] forKey:kDualRTTYSpectrumDecay ] ;
	[ pref setInt:[ dynamicRange indexOfSelectedItem ] forKey:kDualRTTYSpectrumRange ] ;
	[ pref setInt:[ channel indexOfSelectedItem ] forKey:kDualRTTYSpectrumChannel ] ;
	[ pref setInt:transmitChannel forKey:kDualRTTYTransmitChannel ] ;


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

//  waterfall clicked
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)index
{
	CMTonePair tonepair ;
	RTTYTransceiver *transceiver ;
	Boolean waterfallChannel ;
	float shift ;
	
	// don't allow clicks for this version
	return ;
	
	//  find out if transmitting, if so, don't do anything
	if ( transmitState ) return ;

	waterfallChannel = ( [ channel indexOfSelectedItem ] == 0 ) ;
	transceiver = ( waterfallChannel ) ? &a : &b ;
	
	// get current shift
	tonepair = [ transceiver->control baseTonePair ] ;
	shift = fabs( tonepair.mark - tonepair.space ) ;
	
	//  use click as mark
	tonepair.mark = freq ;
	tonepair.space = freq + shift ;	
	[ transceiver->control setTonePair:&tonepair ] ;
}

- (void)restoreTonePairs
{
	RTTYTransceiver *transceiver ;
	Boolean waterfallChannel ;

	waterfallChannel = ( [ channel indexOfSelectedItem ] == 0 ) ;
	transceiver = ( waterfallChannel ) ? &a : &b ;
	
	[ transceiver->control fetchTonePairFromMemory ] ;
	[ transceiver->control updateTonePairInformation ] ;
}

- (void)transmitSelectChanged
{
	int index ;
	NSView *receiveBox, *transceiveBox ;
	
	index = [ transmitSelect selectedColumn ] ;
	//  move interfaces
	if ( index == 0 ) {
		//  receiverA = transceive
		transceiveBox = receiverA ;
		receiveBox = receiverB ;
	}
	else {
		//  receiverB = transceive
		transceiveBox = receiverB ;
		receiveBox = receiverA ;
	}
	[ transceiveBox setFrame:transceiveFrame ] ;
	[ receiveBox setFrame:receiveFrame ] ;
	[ receiverA setNeedsDisplay:YES ] ;
	[ receiverB setNeedsDisplay:YES ] ;

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

//  delegate of dual RTTY's config window, disable config scopes
- (BOOL)windowShouldClose:(id)sender
{
	[ configA setConfigOpen:NO ] ;
	[ configB setConfigOpen:NO ] ;
	return YES ;
}

//  delegate to dual RTTY's config panel tab (main/sub receivers)
- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
	Boolean selectA ;
	
	selectA = ( [ tabView indexOfTabViewItem:tabViewItem ] == 0 ) ;
	[ configA setConfigOpen:selectA ] ;
	[ configB setConfigOpen:!selectA ] ;
}

- (void)changeTransmitStateTo:(Boolean)state
{
	FSK *fsk ;
	int index, ook, transmitType ;
	DualRTTYConfig *cfg ;
	
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
	transmitState = [ txConfig turnOnTransmission:state button:transmitButton fsk:fsk ook:[ cfg ook ] ] ;			//  v0.85
	[ self performSelectorOnMainThread:@selector(finishTransmitStateChange) withObject:nil waitUntilDone:YES ] ;	//  v0.65
}

//  v0.76 added RTTY Monitor to WFRTTY
- (void)showScope
{
	[ a.control showMonitor ] ;
}

//  ModemManager calls cleanup to all modems when app is terminating. 
//  v 0.77 Modems should override this if some cleanup is needed, and then call this with [ super cleanup ].
//	For Dual RTTY Interface, call both configA and configB
- (void)applicationTerminating
{
	[ configA applicationTerminating ] ;
	[ configB applicationTerminating ] ;
	[ ptt applicationTerminating ] ;				//  v0.89
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
