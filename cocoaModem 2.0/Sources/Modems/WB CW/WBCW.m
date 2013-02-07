//
//  WBCW.m
//  cocoaModem
//
//  Created by Kok Chen on Dec 1 2006.
	#include "Copyright.h"
//

#import "WBCW.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Config.h"
#import "Contest.h"
#import "ContestManager.h"
#import "CWConfig.h"
#import "CWMacros.h"
#import "CWMonitor.h"
#import "CWReceiver.h"
#import "CWRxControl.h"
#import "CWTxConfig.h"
#import "CWWaterfall.h"
#import "ExchangeView.h"
#import "Messages.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Module.h"
#import "Plist.h"
#import "PTT.h"
#import "RTTYMacros.h"
#import "RTTYModulator.h"
#import "RTTYTxConfig.h"
#import "Spectrum.h"
#import "StdManager.h"
#import "Transceiver.h"

@implementation WBCW

//  WBCW : WFRTTY : ContestInterface : MacroPanel : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	CMTonePair tonepair ;
	float ellipseFatness = 0.9 ;
	int i ;

	RTTYConfigSet setA = { 
		LEFTCHANNEL, 
		kWBCWMainDevice, 
		kWBCWOutputDevice, 
		kWBCWOutputLevel, 
		kWBCWOutputAttenuator, 
		nil, 
		nil, 
		nil,	
		nil,
		kWBCWMainControlWindow,
		kWBCWMainSquelch,
		kWBCWMainActive,
		nil,
		kWBCWMainMode,
		nil,
		nil,
		kWBCWMainPrefs,
		kWBCWMainTextColor,
		kWBCWMainSentColor,
		kWBCWMainBackgroundColor,
		kWBCWMainPlotColor,
		kWBCWMainOffset,
		nil,
		NO,							// usesRTTYAuralMonitor
		nil							// no RTTYAuralMonitor
	} ;

	RTTYConfigSet setB = { 
		RIGHTCHANNEL, 
		kWBCWSubDevice, 
		nil, 
		nil, 
		nil, 
		nil, 
		nil, 
		nil,
		nil,
		kWBCWSubControlWindow,
		kWBCWSubSquelch,
		kWBCWSubActive,
		nil,
		kWBCWSubMode,
		nil,
		nil,
		kWBCWSubPrefs,
		kWBCWSubTextColor,
		kWBCWSubSentColor,
		kWBCWSubBackgroundColor,
		kWBCWSubPlotColor,
		kWBCWSubOffset,
		nil,
		NO,							// usesRTTYAuralMonitor
		nil							// no RTTYAuralMonitor
	} ;

	[ mgr showSplash:@"Creating Wideband CW Modem" ] ;

	self = [ super initIntoTabView:tabview nib:@"WBCW" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		
		//  break-in keying support
		isBreakin = NO ;
		breakinTimer = nil ;
		breakinTimeout = 0 ;
		breakinRelease = 500 ;
		breakinLeadin = 30 ;
		for ( i = 0; i < 512; i++ ) transmittedBuffer[i] = 0.0 ;
		
		sidetoneGain = 1.0 ;

		//  initialize txConfig before rxConfigs
		[ txConfig awakeFromModem:&setA rttyRxControl:a.control ] ;
		ptt = [ txConfig pttObject ] ;
				
		a.isAlive = YES ;
		a.control = [ [ CWRxControl alloc ] initIntoView:receiverA client:self index:0 ] ;
		a.receiver = [ a.control receiver ] ;
		[ a.receiver createClickBuffer ] ;
		currentRxView = a.view = [ a.control view ] ;
		[ a.view setDelegate:self ] ;		//  text selections, etc
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:NSLocalizedString( @"Main Receiver", nil ) ] ;
		[ a.control setEllipseFatness:ellipseFatness ] ;
		[ configA awakeFromModem:&setA rttyRxControl:a.control txConfig:txConfig ] ;
		[ configA setChannel:0 ] ;
		config = configA ;
		control[0] = a.control ;
		configObj[0] = configA ;
		txLocked[0] = NO ;
		
		tonepair = [ a.control baseTonePair ] ;
		tonepair.space = 0 ;
		[ waterfallA setTonePairMarker:&tonepair index:0 ] ;

		b.isAlive = YES ;
		b.control = [ [ CWRxControl alloc ] initIntoView:receiverB client:self index:1 ] ;
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
		tonepair.space = 0 ;
		[ waterfallB setTonePairMarker:&tonepair index:1 ] ;
		
		//  CW Monitor
		[ monitor setupMonitor:NSLocalizedString( @"CW Sidetone", nil ) modem:self main:(CWReceiver*)a.receiver sub:(CWReceiver*)b.receiver ] ;
		
		[ configTab setDelegate:self ] ;

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
	int i ;
	
	ident = NSLocalizedString( @"Wideband CW", nil )  ;
	
	[ self awakeFromContest ] ;
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;
		
	[ self initCallsign ] ;
	[ self initColors ] ;
	[ self initMacros ] ;
	
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
	//transmitViewLock = [ [ NSLock alloc ] init ] ;			v0.64b
	
	if ( transmitView ) {
		transmitTextAttribute = [ transmitView newAttribute ] ;
		[ transmitView setDelegate:self ] ;
	}
	
	waterfall[0] = waterfallA ;
	waterfall[1] = waterfallB ;
	for ( i = 0; i < 2; i++ ) {
		[ waterfall[i] awakeFromModem ] ;
		[ waterfall[i] enableIndicator:self ] ;
		[ waterfall[i] setWaterfallID:i ] ;
	}
	
	//  actions
	if ( transmitButton ) [ self setInterface:transmitButton to:@selector(transmitButtonChanged) ] ;	
	if ( breakinButton ) {
		[ self setInterface:breakinButton to:@selector(breakinButtonChanged) ] ;	
		[ self setInterface:sidetoneSlider to:@selector(sidetoneLevelChanged) ] ;
	}
	if ( transmitSelect ) [ self setInterface:transmitSelect to:@selector(transmitSelectChanged) ] ;	
	if ( contestTransmitSelect ) [ self setInterface:contestTransmitSelect to:@selector(contestTransmitSelectChanged) ] ;	
	if ( risetimeSlider ) {
		[ self setInterface:risetimeSlider to:@selector(cwParametersChanged) ] ;	
		[ self setInterface:weightSlider to:@selector(cwParametersChanged) ] ;	
		[ self setInterface:ratioSlider to:@selector(cwParametersChanged) ] ;	
		[ self setInterface:farnsworthSlider to:@selector(cwParametersChanged) ] ;	
	}
	if ( speedMenu ) [ self setInterface:speedMenu to:@selector(sendingSpeedChanged) ] ;
	if ( leadinField ) {
		[ self setInterface:leadinField to:@selector(breakinParamsChanged) ] ;
		[ self setInterface:releaseField to:@selector(breakinParamsChanged) ] ;
	}

	[ self setInterface:restoreToneA to:@selector(restoreTone:) ] ;
	[ self setInterface:restoreToneB to:@selector(restoreTone:) ] ;
	[ self setInterface:dynamicRangeA to:@selector(dynamicRangeChanged:) ] ;
	[ self setInterface:dynamicRangeB to:@selector(dynamicRangeChanged:) ] ;
	[ self setInterface:transmitLock to:@selector(txLockChanged) ] ;

	[ self setInterface:modulationMenu to:@selector(modulationChanged) ] ;			//  v0.85
}

- (void)initMacros
{
	int i ;
	Application *application ;
	
	currentSheet = check = 0 ;
	application = [ manager appObject ] ;
	for ( i = 0; i < 3; i++ ) {
		macroSheet[i] = [ [ CWMacros alloc ] initSheet ] ;
		[ macroSheet[i] setUserInfo:[ application userInfoObject ] qso:[ (StdManager*)manager qsoObject ] modem:self canImport:YES ] ;
	}
}

- (CMTappedPipe*)dataClient
{
	return (CMTappedPipe*)self ;
}

- (void)setupSpectrum
{
	int i ;
	
	for ( i = 0; i < 2; i++ ) [ control[i] setWaterfall:waterfall[i] ] ;
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
	
	[ monitor setVisibleState:visible ] ;
}

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating Wideband CW sound source" ] ;
	[ (CWRxControl*)a.control setupCWReceiverWithMonitor:monitor ] ;
	[ (CWRxControl*)b.control setupCWReceiverWithMonitor:monitor ] ;
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

- (void)enableWide:(Boolean)state index:(int)n
{
	if ( monitor ) [ monitor enableWide:state index:n ] ;
}

- (void)enablePano:(Boolean)state index:(int)n
{
	if ( monitor ) [ monitor enablePano:state index:n ] ;
}

- (void)changeSpeedTo:(int)speed index:(int)n
{
	if ( n == 0 ) [ (CWReceiver*)a.receiver changeCodeSpeedTo:speed ] ;
	if ( n == 1 ) [ (CWReceiver*)b.receiver changeCodeSpeedTo:speed ] ;
}

- (void)changeSquelchTo:(float)squelch fastQSB:(float)fast slowQSB:(float)slow index:(int)n
{
	if ( n == 0 ) [ (CWReceiver*)a.receiver changeSquelchTo:squelch fastQSB:fast slowQSB:slow ] ;
	if ( n == 1 ) [ (CWReceiver*)b.receiver changeSquelchTo:squelch fastQSB:fast slowQSB:slow ] ;
}

- (void)enableMonitor:(Boolean)state index:(int)n
{
	if ( monitor ) [ monitor setEnabled:state index:n ] ;
}

- (void)monitorLevel:(float)value index:(int)n
{
	if ( monitor ) [ monitor monitorLevel:value index:n ] ;
}

- (void)sidebandChanged:(int)state index:(int)n
{
	if ( monitor ) [ monitor sidebandChanged:state index:n ] ;
}

//  Application sends this through the ModemManager when quitting
- (void)applicationTerminating
{
	//[ monitor setMute:YES ] ;
	[ (CWMonitor*)monitor terminate ] ;
	[ configA applicationTerminating ] ;			//  v0.78 was calling super which dereferenced non-existent (common) config variable instead of configA and configB
	[ configB applicationTerminating ] ;			//  v0.78
	[ ptt applicationTerminating ] ;				//  v0.89
}

- (void)startBreakinTimer
{
	breakinTimer = [ NSTimer scheduledTimerWithTimeInterval:0.010 target:self selector:@selector(breakinCheck:) userInfo:self repeats:YES ] ;
}

- (void)cannotTransmit
{
	if ( contestBar ) {
		[ contestBar cancel ] ;
		[ self flushOutput ] ;
	}
	[ Messages alertWithMessageText:NSLocalizedString( @"Carrier frequency not selected.", nil ) informativeText:NSLocalizedString( @"Frequency not set", nil ) ] ;
}

- (void)transmitButtonChanged
{
	int state ;
	RTTYRxControl *rxControl ;
	CMTonePair tonepair ;
	
	state = ( [ transmitButton state ] == NSOnState ) ;
	if ( state == NO ) {
		//  unconditionally turn transmitter off
		[ super transmitButtonChanged ] ;
		if ( isBreakin && breakinTimer == nil ) {
			//  turn on break-in timer if in breakin button is active
			[ self startBreakinTimer ] ;
		}
		return ;
	}
	rxControl = ( [ transmitSelect selectedColumn ] == 0 ) ? control[0] : control[1] ;
	tonepair = [ rxControl txTonePair ] ;
	
	if ( tonepair.mark > 10.0 ) {
		if ( breakinTimer != nil ) {
			// turn off break in timer if manually transmitting
			[ breakinTimer invalidate ] ;
			breakinTimer = nil ;
		}
		[ super transmitButtonChanged ] ;
	}
	else {
		[ transmitButton setState:NSOffState ] ;
		[ self cannotTransmit ] ;
	}
}

/* local */
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

- (void)txLockChanged
{
	Boolean wasLocked, nowLocked ;
	RTTYRxControl *ctrl ;
	int channel ;

	for ( channel = 0; channel < 2; channel++ ) {
		wasLocked = txLocked[channel] ;
		ctrl = control[ channel ] ;
		nowLocked =  ( [ [ transmitLock cellAtRow:0 column:channel ] state ] == NSOnState ) ;
		txLocked[channel] = nowLocked ;
		//[ ctrl setTransmitLock:nowLocked ] ;
		if ( wasLocked != nowLocked ) {
			lockedTonePair[channel] = [ ctrl rxTonePair ] ;
			if ( nowLocked ) {
				if ( lockedTonePair[channel].mark < 10.0 ) {
					//  v1.02e[ [ NSAlert alertWithMessageText:NSLocalizedString( @"You have not yet selected a frequency in the waterfall!", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"First select frequency", nil ) ] runModal ] ;
					[ Messages alertWithMessageText:NSLocalizedString( @"You have not yet selected a frequency in the waterfall!", nil ) informativeText:NSLocalizedString( @"First select frequency", nil ) ] ;
					nowLocked = NO ;
				}
				[ (CWRxControl*)ctrl lockTonePairToCurrentTone ] ;
			}
			else {
				lockedTonePair[channel].mark = lockedTonePair[channel].space = 0.0 ;
			}
			[ ctrl setTransmitLock:nowLocked ] ;
			[ waterfall[channel] setTransmitTonePairMarker:&lockedTonePair[channel] index:channel ] ; 
		}
	}
}

- (void)changeTransmitStateTo:(Boolean)state
{
	CMTonePair tonepair ;
	int channel ;
	
	[ (CWMonitor*)monitor changeTransmitStateTo:state ] ;
	
	if ( state == YES ) {
		channel = ( [ transmitSelect selectedColumn ] == 0 ) ? 0 : 1 ;
		tonepair = ( txLocked[channel] == YES ) ? lockedTonePair[channel] : [ control[channel] rxTonePair ] ;
		if ( tonepair.mark < 10.0 ) return ;
		[ (CWTxConfig*)txConfig setCarrier:tonepair.mark ] ;
	}
	[ self changeNonAuralTransmitStateTo:state ] ;
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

//  whenever break-in button is set, this timer runs every 100 ms in the main thread
- (void)breakinCheck:(NSTimer*)timer
{
	int total ;
	NSTextStorage *storage ;

	//  check transmitView to see if there are any untransmitted characters
	storage = [ transmitView textStorage ] ;
	total = [ storage length ] ;
	
	if ( indexOfUntransmittedText < total || ![ (CWTxConfig*)txConfig bufferEmpty ] ) {
		breakinTimeout = 0 ;
		if ( transmitState == NO ) {
			[ (CWTxConfig*)txConfig holdOff:breakinLeadin ] ;
			[ self changeTransmitStateTo:YES ] ;
		}
	}
	else {
		//  no text, start the time-out count
		//  fixed 800 ms timeout for now
		if ( transmitState == YES ) {
			breakinTimeout += 10 ;
			if ( breakinTimeout > breakinRelease ) {
				[ self changeTransmitStateTo:NO ] ;
			}
		}
	}
}

//  callback from Morse generator to keep break-in alive
- (void)keepBreakinAlive:(int)duration
{
	//  reset break-in timeout
	breakinTimeout = -( duration+10 ) ;
}

- (void)breakinButtonChanged
{
	Boolean wasBreakin ;
	
	wasBreakin = isBreakin ;
	isBreakin = ( [ breakinButton state ] == NSOnState ) ;
	if ( wasBreakin != isBreakin ) {
		if ( isBreakin ) {
			// create breakin timer in main thread
			[ self performSelectorOnMainThread:@selector(startBreakinTimer) withObject:nil waitUntilDone:NO ] ;
		}
		else {
			//  breakin disabled
			if ( breakinTimer ) [ breakinTimer invalidate ] ;
			breakinTimer = nil ;
		}
	}
}

//  v0.85
- (int)ook:(RTTYConfig*)configr
{
	int tag ;
	
	tag = [ [ modulationMenu selectedItem ] tag ] ;
	return ( tag != 0 ) ;
}

	
- (void)switchCWModemIn:(int)tag
{
	[ configA setCWKeyerMode:tag ptt:ptt ] ;
	[ configB setCWKeyerMode:tag ptt:ptt ] ;
}

//  v0.85
- (void)modulationChanged
{
	int tag ;
	
	tag = [ [ modulationMenu selectedItem ] tag ] ;
	[ (CWTxConfig*)txConfig setModulationMode:tag ] ;
	[ self switchCWModemIn:tag ] ;
}

//  v0.87  switchModemIn for modem with two configs
- (void)switchModemIn
{
	int tag ;
	
	tag = [ [ modulationMenu selectedItem ] tag ] ;
	[ self switchCWModemIn:tag ] ;
}

- (void)cwParametersChanged
{
	float risetime, weight, ratio, farnsworth ;
	
	risetime = [ risetimeSlider floatValue ] ;
	weight = [ weightSlider floatValue ] ;
	ratio = [ ratioSlider floatValue ] ;
	farnsworth = [ farnsworthSlider floatValue ] ;
	[ (CWTxConfig*)txConfig setRisetime:risetime weight:weight ratio:ratio farnsworth:farnsworth ] ;
}

- (void)sendingSpeedChanged
{
	[ (CWTxConfig*)txConfig setSpeed:[ [ speedMenu selectedItem ] tag ] ] ;
}

- (void)breakinParamsChanged
{
	breakinLeadin = [ leadinField intValue ] ;
	breakinRelease = [ releaseField intValue ] ;
}

- (void)sidetoneLevelChanged
{
	float v = [ sidetoneSlider floatValue ] ;
	
	sidetoneGain = ( v < -39.0 ) ? 0.0 : pow( 10.0, [ sidetoneSlider floatValue ]/20.0 ) ;
}

//  transmitted audio buffer
- (void)sendSidetoneBuffer:(float*)buf
{
	int i ;
	
	for ( i = 0; i < 512; i++ ) transmittedBuffer[i] = buf[i]*sidetoneGain ;
	[ monitor transmitted:transmittedBuffer samples:512 ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferencesFromSuper:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kWBCWFontA ] ;
	[ pref setFloat:14.0 forKey:kWBCWFontSizeA ] ;
	[ pref setString:@"Verdana" forKey:kWBCWFontB ] ;
	[ pref setFloat:14.0 forKey:kWBCWFontSizeB ] ;
	
	[ pref setString:@"Verdana" forKey:kWBCWTxFont ] ;
	[ pref setFloat:14.0 forKey:kWBCWTxFontSize ] ;
		
	[ pref setInt:0 forKey:kWBCWTransmitChannel ] ;
	[ pref setInt:1 forKey:kWBCWMainWaterfallNR ] ;
	[ pref setInt:1 forKey:kWBCWSubWaterfallNR ] ;
	
	//  default CW keying parameters
	[ pref setInt:0 forKey:kWBCWBreakin ] ;
	[ pref setFloat:5.0 forKey:kWBCWRisetime ] ;
	[ pref setFloat:0.5 forKey:kWBCWWeight ] ;
	[ pref setFloat:3.0 forKey:kWBCWRatio ] ;
	[ pref setFloat:1.0 forKey:kWBCWFarnsworth ] ;
	[ pref setInt:25 forKey:kWBCWSpeed ] ;
	
	[ pref setInt:0 forKey:kWBCWModulation ] ;		//  v0.85 
	
	[ pref setInt:30 forKey:kWBCWPTTLeadIn ] ;
	[ pref setInt:500 forKey:kWBCWPTTRelease ] ;
	
	[ pref setFloat:0.0 forKey:kWBCWTxSidetoneLevel ] ;
	
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kWBCWMainTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kWBCWMainSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kWBCWMainBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kWBCWMainPlotColor ] ;
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kWBCWSubTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kWBCWSubSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kWBCWSubBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kWBCWSubPlotColor ] ;
	
	[ configA setupDefaultPreferences:pref rttyRxControl:a.control ] ;
	[ configB setupDefaultPreferences:pref rttyRxControl:b.control ] ;

	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (RTTYMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
	
	if ( monitor ) [ monitor setupDefaultPreferences:pref ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	int txChannel, i ;
	
	[ super updateFromPlistFromSuper:pref ] ;
	
	//  v0.73
	[ waterfallA setNoiseReductionState:[ pref intValueForKey:kWBCWMainWaterfallNR ] ] ;
	[ waterfallB setNoiseReductionState:[ pref intValueForKey:kWBCWSubWaterfallNR ] ] ;

	fontName = [ pref stringValueForKey:kWBCWFontA ] ;
	fontSize = [ pref floatValueForKey:kWBCWFontSizeA ] ;
	[ a.view setTextFont:fontName size:fontSize attribute:[ a.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kWBCWFontB ] ;
	fontSize = [ pref floatValueForKey:kWBCWFontSizeB ] ;
	[ b.view setTextFont:fontName size:fontSize attribute:[ b.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kWBCWTxFont ] ;
	fontSize = [ pref floatValueForKey:kWBCWTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	txChannel = [ pref intValueForKey:kWBCWTransmitChannel ] ;
	[ self transmitFrom:txChannel ] ;
	[ transmitSelect selectCellAtRow:0 column:txChannel ] ;
	[ contestTransmitSelect selectCellAtRow:0 column:txChannel ] ;
	[ self transmitSelectChanged ] ;
		
	[ breakinButton setState:( [ pref intValueForKey:kWBCWBreakin ] != 0 ) ? NSOnState : NSOffState ] ;
	[ self breakinButtonChanged ] ;
	[ risetimeSlider setFloatValue:[ pref floatValueForKey:kWBCWRisetime ] ] ;
	[ weightSlider setFloatValue:[ pref floatValueForKey:kWBCWWeight ] ] ;
	[ ratioSlider setFloatValue:[ pref floatValueForKey:kWBCWRatio ] ] ;
	[ farnsworthSlider setFloatValue:[ pref floatValueForKey:kWBCWFarnsworth ] ] ;
	[ self cwParametersChanged ] ;

	//  v0.85

	[ modulationMenu selectItemAtIndex:[ pref intValueForKey:kWBCWModulation ] ] ;
	[ self modulationChanged ] ;
	
	[ sidetoneSlider setFloatValue:[  pref floatValueForKey:kWBCWTxSidetoneLevel ] ] ;
	[ self sidetoneLevelChanged ] ;
	
	[ speedMenu selectItemWithTag:[ pref intValueForKey:kWBCWSpeed ] ] ;
	[ self sendingSpeedChanged ] ;
	
	[ speedMenu selectItemWithTag:[ pref intValueForKey:kWBCWSpeed ] ] ;

	[ leadinField setIntValue:[ pref intValueForKey:kWBCWPTTLeadIn ] ] ;
	[ releaseField setIntValue:[ pref intValueForKey:kWBCWPTTRelease ] ] ;
	[ self breakinParamsChanged ] ;
	
	[ manager showSplash:@"Updating WBCW configurations" ] ;
	[ configA updateFromPlist:pref rttyRxControl:a.control ] ;
	[ configB updateFromPlist:pref rttyRxControl:b.control ] ;
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;
	
	if ( monitor ) [ (CWMonitor*)monitor updateFromPlist:pref ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) {
			[ (CWMacros*)( macroSheet[i] ) updateFromPlist:pref option:i ] ;
		}
	}
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	int i ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	
	[ super retrieveForPlistFromSuper:pref ] ;
	
	font = [ a.view font ] ;
	[ pref setString:[ font fontName ] forKey:kWBCWFontA ] ;
	[ pref setFloat:[ font pointSize ] forKey:kWBCWFontSizeA ] ;
	font = [ b.view font ] ;
	[ pref setString:[ font fontName ] forKey:kWBCWFontB ] ;
	[ pref setFloat:[ font pointSize ] forKey:kWBCWFontSizeB ] ;
	
	font = [ transmitView font ] ;
	[ pref setString:[ font fontName ] forKey:kWBCWTxFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kWBCWTxFontSize ] ;
	
	[ pref setInt:transmitChannel forKey:kWBCWTransmitChannel ] ;
	[ pref setInt:( isBreakin ) ? 1 : 0 forKey:kWBCWBreakin ] ;
	
	[ pref setFloat:[ risetimeSlider floatValue ] forKey:kWBCWRisetime ] ;
	[ pref setFloat:[ weightSlider floatValue ] forKey:kWBCWWeight ] ;
	[ pref setFloat:[ ratioSlider floatValue ] forKey:kWBCWRatio ] ;
	[ pref setFloat:[ farnsworthSlider floatValue ] forKey:kWBCWFarnsworth ] ;
	
	[ pref setInt:[ [ speedMenu selectedItem ] tag ] forKey:kWBCWSpeed ] ;
	[ pref setInt:[ leadinField intValue ] forKey:kWBCWPTTLeadIn ] ;
	[ pref setInt:[ releaseField intValue ] forKey:kWBCWPTTRelease ] ;

	[ pref setInt:[ modulationMenu indexOfSelectedItem ] forKey:kWBCWModulation ] ;		//  v0.85
	
	[ pref setFloat:[ sidetoneSlider floatValue ] forKey:kWBCWTxSidetoneLevel ] ;
	
		//  v0.73
	[ pref setInt:[ waterfallA noiseReductionState ] forKey:kWBCWMainWaterfallNR ] ;
	[ pref setInt:[ waterfallB noiseReductionState ] forKey:kWBCWSubWaterfallNR ] ;
	
	[ (CWConfig*)configA retrieveForPlist:pref rttyRxControl:a.control ] ;
	[ (CWConfig*)configB retrieveForPlist:pref rttyRxControl:b.control ] ;
	
	if ( monitor ) [ monitor retrieveForPlist:pref ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (CWMacros*)( macroSheet[i] ) retrieveForPlist:pref option:i ] ;
	}

}

// ----------------------------------------------------------------

- (void)tonePairChanged:(RTTYRxControl*)ctrl
{
	CMTonePair tonepair ;
	float sideband ;
	int channel ;
	
	channel = ( ctrl == control[0] ) ? 0 : 1 ;
	sideband = [ ctrl sideband ] ;	
	tonepair = ( txLocked[channel] ) ? [ ctrl lockedTxTonePair ] : [ ctrl baseTonePair ] ;
	tonepair.space = 0 ;
	
	[ waterfall[channel] setSideband:sideband ] ;
	[ waterfall[channel] setTonePairMarker:&tonepair index:channel ] ; 
}

//  this is called from the waterfall when it is shift clicked.
//	ident = 0 for main receiver
- (void)turnOffReceiver:(int)channel option:(Boolean)option
{
	CWRxControl *ctrl ;
	
	ctrl = (CWRxControl*)control[channel ] ;
	[ ctrl setFrequency:0.0 ] ;
	[ waterfall[channel] display ] ;		//  force waterfall display to erase marker
	[ ctrl enableCWReceiver:NO ] ;
}

//  waterfall clicked
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)waterfallChannel
{
	CWRxControl *ctrl ;
	CWConfig *cfg ;
	float oldFreq ;
	
	if ( [ txConfig transmitActive ] ) return ;			// don't obey clicks when transmitting
	
	cfg = (CWConfig*)configObj[ waterfallChannel ] ;
	if ( ![ cfg soundInputActive ] ) {
		if ( waterfallChannel == 1 ) [ waterfallB clearMarkers ] ; else [ waterfallA clearMarkers ] ;
		[ Messages alertWithMessageText:NSLocalizedString( @"Sound Card not active", nil ) informativeText:NSLocalizedString( @"Cannot click on inactive waterfall", nil ) ] ;
		return ;
	}
	
	waterfallChannel &= 1 ;
	ctrl = (CWRxControl*)control[ waterfallChannel ] ;	
	oldFreq = [ ctrl rxTonePair ].mark ;
	[ ctrl setFrequency:freq ] ;
	[ ctrl newClick:freq-oldFreq ] ;

	if ( option ) {	
		// control clicked
		printf( "No RIT for now\n" ) ;
		[ ctrl setRIT:0 ] ;				//  no RIT for now
		return ;
	}
	// clear RIT if not control clicked
	[ ctrl setRIT:0.0 ] ;
	
	if ( acquire ) {
		[ [ ctrl receiver ] clicked:secs ] ;
	}
	[ ctrl enableCWReceiver:YES ] ;
	
	[ [ [ NSApp delegate ] application ] setDirectFrequencyFieldTo:freq ] ;
}

- (IBAction)defaultSliders:(id)sender
{
	[ risetimeSlider setFloatValue:5.0 ] ;
	[ weightSlider setFloatValue:0.5 ] ;
	[ ratioSlider setFloatValue:3.0 ] ;
	[ farnsworthSlider setFloatValue:1.0 ] ;
}

- (void)updateMacroButtons
{
	[ self updateModeMacroButtons ] ;		// this overrides the RTTY updateMacroButtons
}

- (Boolean)checkIfCanTransmit
{
	RTTYRxControl *rxControl ;
	CMTonePair tonepair ;
	
	rxControl = ( [ transmitSelect selectedColumn ] == 0 ) ? control[0] : control[1] ;
	tonepair = [ rxControl txTonePair ] ;
	if ( tonepair.mark < 10.0 ) {
		[ self cannotTransmit ] ;
		return NO ;
	}
	return YES ;
}


//  AppleScript support
- (void)setInvert:(Boolean)state module:(Module*)module 
{
	// do nothing in CW
}

- (Boolean)invertFor:(Module*)module
{
	return NO ;
}

- (Boolean)breakinFor:(Module*)module
{
	if ( [ module isReceiver ] ) {
		// receiver, no breakin function
		return NO ;
	}
	//  transmitter 
	return isBreakin ;
}

- (void)setBreakin:(Boolean)state module:(Module*)module 
{
	if ( [ module isReceiver ] ) {
		//  receiver, no breakin
		return ;
	}
	//  set transmitter breakin state
	[ breakinButton setState:( state ) ? NSOnState : NSOffState ] ;
	[ self breakinButtonChanged ] ;
}

//  v0.56
- (int)selectedTransceiver
{
	return transmitChannel+1 ;
}

//  execute string
- (void)executeMacroString:(NSString*)macro
{
	if ( ![ self checkIfCanTransmit ] ) return ;
	
	if ( macro ) [ transmitView insertAtEnd:macro ] ;
	
	if ( transmitCount > 0 ) {
		//  keep transmit on if needed
		if ( transmitState == NO ) {
			[ self changeTransmitStateTo:YES ] ;
		}
	}
}

//  execute a macro in a macroSheet
- (void)executeMacro:(int)index macroSheet:(MacroSheet*)sheet fromContest:(Boolean)fromContest
{
	NSString *macro ;
	 
	macro = [ sheet expandMacro:index modem:self ] ;
	if ( fromContest ) alwaysAllowMacro = 2 ;
	[ self executeMacroString:macro ] ;
}

//  callback from AFSK generator
//  copy from RTTYInterface
- (void)transmittedCharacter:(int)c
{
	if ( c <= 26 ) {
		//  control character in stream
		switch ( c + 'a' - 1 ) {
		case 'e':
			[ transmitCountLock lock ] ;
			transmitCount-- ;
			[ transmitCountLock unlock ] ;
			if ( transmitCount <= 0 ) {
				[ self changeTransmitStateTo:NO ] ;
				[ transmitCountLock lock ] ;
				transmitCount = 0 ;
				[ transmitCountLock unlock ] ;
			}
			//  is also end of macro
			break ;
		case 'z':
			//  end of macro transmitCount balance
			[ transmitCountLock lock ] ;
			if ( transmitCount > 0 ) transmitCount-- ;
			[ transmitCountLock unlock ] ;
			break ;
		default:
			//  for carriage return, newline, etc
			[ self insertTransmittedCharacter:c ] ;
			[ transmitView select ] ;
			break ;
		}
	}
	else {
		[ self setSentColor:YES ] ;
		if ( c == '0' && slashZero ) c = Phi ;
		[ self insertTransmittedCharacter:c ] ;
		[ transmitView select ] ;
	}
}

//  v0.87 NSMenuValidation for modulationMenu
-(BOOL)validateMenuItem:(NSMenuItem*)item
{
	if ( [ item tag ] == 2 && ptt != nil ) {
		//  check if we have a digiKeyer
		return [ ptt hasQCW ] ;
	}	
	return YES ;
}

//	v1.02b
- (float)selectedFrequency
{
	if ( control[0] == nil ) return 0.0 ;
	
	return [ control[0] cwTone ] ;
}

@end
