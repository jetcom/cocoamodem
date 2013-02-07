//
//  PSKConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
	#include "Copyright.h"
//

#import "PSKConfig.h"
#import "Application.h"
#import "Messages.h"
#import "Oscilloscope.h"
#import "ModemDest.h"
#import "ModemEqualizer.h"
#import "ModemSource.h"
#import "Plist.h"
#import "PSK.h"
#import "PSKAuralMonitor.h"
#import "PSKModulator.h"
#import "PTT.h"
#import "CMPCO.h"
#import "CMDSPWindow.h"


@implementation PSKConfig

//  PSK Config

- (void)awakeFromModem:(PSK*)modem
{
	toneMatrix = nil ;
	transmitButton = nil ;
	timeout = nil ;
	soundFileRunning = NO ;
	[ self setClient:modem ] ;
	
	overrun = [ [ NSLock alloc ] init ] ;
	
	[ super initializeActions ] ;

	//  set up modulator
	pskModulator = [ [ PSKModulator alloc ] init ] ;
	[ pskModulator setFrequency:10.0 ] ;		// default to 10 Hz carrier
	[ pskModulator setModemClient:modemObj ] ;
	
	//  actions
	[ self setInterface:vfoOffset to:@selector(sidebandOrOffsetChanged) ] ;	
	[ self setInterface:sidebandMenu to:@selector(sidebandOrOffsetChanged) ] ;	

	//  test tones
	idleTone = [ [ PSKModulator alloc ] init ] ;
	[ idleTone setFrequency:1000.0 ] ;
	
	fastFileSpeed = 4 ;
	[ self setupModemSource:kPSKInputDevice channel:LEFTCHANNEL ] ;
	[ self setupModemDest:kPSKOutputDevice controlView:soundOutputControls attenuatorView:soundOutputLevel ] ;
	[ modemDest setSoundLevelKey:kPSKOutputLevel attenuatorKey:kPSKOutputAttenuator ] ;
	
	//	Transmit monitor (cached at -needData)
	auralMonitor = nil ;
	//  Set up Transmit equalizer
	equalizer = [ [ ModemEqualizer alloc ] initSheetFor:@"PSK" ] ;
	equalize = 1.0 ;
	//  delegate to trap config panel closure
	[ window setDelegate:self ] ;
	
	//  start sampling later in an NSTimer driven -checkActive
	[ modemSource enableInput:YES ] ;		
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *scopeData ;
	
	sequenceNumber++ ;
	if ( [ overrun tryLock ] ) {
		//  discard overuns
		if ( interfaceVisible ) {
			if ( ( isActiveButton && !isTransmit ) || [ modemSource fileRunning ] ) {
				*data = *[ pipe stream ] ;
				[ self exportData ] ;
			}
			if ( configOpen && oscilloscope ) {
				scopeData = [ pipe stream ] ;
				[ oscilloscope addData:scopeData isBaudot:NO timebase:1 ] ;
			}
		}
		[ overrun unlock ] ;
	}
}

//  0 - LSB
//  1 - USB
- (void)setPSKSideband:(int)index
{
	[ sidebandMenu selectItemAtIndex:index ] ;
	switch ( index ) {
	case 0:
	default:
		[ modemObj selectAlternateSideband:NO ] ;
		break ;
	case 1:
		[ modemObj selectAlternateSideband:YES ] ;
		break ;
	}
}

//	v0.87
- (void)setKeyerMode
{
	PTT *ptt ;
		
	ptt = [ self pttObject ] ;
	if ( ptt ) [ ptt setKeyerMode:kMicrohamDigitalRouting ] ;	//  v0.93b
}

/* local */
//  set preferences to an NSColor
- (void)setColorRed:rTag green:gTag blue:bTag fromColor:(NSColor*)color into:(Preferences*)pref
{
	float red, green, blue, alpha ;
	
	[ color getRed:&red green:&green blue:&blue alpha:&alpha ] ;
	[ pref setFloat:red forKey:rTag ] ;
	[ pref setFloat:green forKey:gTag ] ;
	[ pref setFloat:blue forKey:bTag ] ;
}

/* local */
//  get an NSolor for preferences
- (NSColor*)getColorRed:rTag green:gTag blue:bTag from:(Preferences*)pref
{
	float red, green, blue ;
	
	red = [ pref floatValueForKey:rTag ] ;
	green = [ pref floatValueForKey:gTag ] ;
	blue = [ pref floatValueForKey:bTag ] ;
	return [ [ NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1 ] retain ] ;
}

//  preferences maintainence, called from PSK.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setInt:0 forKey:kPSKActive ] ;
	[ pref setInt:1 forKey:kFastPlayback ] ;
	[ pref setInt:1 forKey:kPSKSideband ] ;				// default to USB
	[ pref setFloat:0.0 forKey:kPSKOffset ] ;			// and no VFO offset
	[ self retrieveActualColorPreferences:pref ] ;

	[ modemSource setupDefaultPreferences:pref ] ;
	[ modemDest setupDefaultPreferences:pref ] ;
	[ equalizer setupDefaultPreferences:pref ] ;
}

- (void)updateColorsFromPreferences:(Preferences*)pref
{
	NSColor *color, *sent, *bg, *plot ;
	int version ;

	version = [ pref intValueForKey:kPrefVersion ] ;
	
	color = [ self getColor:kPSKTextColor from:pref ] ;
	sent = [ self getColor:kPSKSentColor from:pref ] ;
	bg = [ self getColor:kPSKBackgroundColor from:pref ] ;
	plot = [ self getColor:kPSKPlotColor from:pref ] ;		

	//  set colors
	[ textColor setColor:color ] ;
	[ transmitTextColor setColor:sent ] ;
	[ backgroundColor setColor:bg ] ;
	[ plotColor setColor:plot ] ;
	[ oscilloscope setDisplayStyle:0 plotColor:plot ] ;  //  initially spectrum
	[ modemObj setTextColor:color sentColor:sent backgroundColor:bg plotColor:plot ] ;
}

//  called from PSK.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref
{
	int state ;
	
	//  set up active button states and set the button states
	//  later, a Timer would activate to obey these buttons
	[ activeButton setState:( [ pref intValueForKey:kPSKActive ] == 1 ) ? NSOnState : NSOffState ] ;
	
	//  now reset active states if autoconnect is off
	if ( [ pref intValueForKey:kAutoConnect ] == 0 ) [ activeButton setState:NSOffState ] ;
	
			
	[ self updateColorsFromPreferences:(Preferences*)pref ] ;
	
	if ( ( ![ modemSource updateFromPlist:pref ] || ![ modemDest updateFromPlist:pref ] ) && ( [ activeButton state ] == NSOnState ) ) {
		[ activeButton setState:NSOffState ] ;
		//  toggle input attenuator		
		[ Messages alertWithMessageText:NSLocalizedString( @"PSK settings needs to be reselected", nil ) informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}
	[ modemSource setDeviceLevel:[ (PSK*)modemObj inputAttenuator:self ] ] ;
	[ equalizer updateFromPlist:pref ] ;
	
	[ self setPSKSideband:[ pref intValueForKey:kPSKSideband ] ] ;
	[ vfoOffset setFloatValue:[ pref floatValueForKey:kPSKOffset ] ] ;
	[ self updateDialOffset ] ; //  this updates the labels of the waterfall

	state = [ pref intValueForKey:kFastPlayback ] ;
	[ fileSpeedCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
	[ self updateFileSpeed ] ;

	
	return true ;
}

- (void)retrieveActualColorPreferences:(Preferences*)pref
{
	int version ;

	version = [ pref intValueForKey:kPrefVersion ] ;
	
	[ self set:kPSKTextColor fromColor:[ textColor color ] into:pref ] ;
	[ self set:kPSKSentColor fromColor:[ transmitTextColor color ] into:pref ] ;
	[ self set:kPSKBackgroundColor fromColor:[ backgroundColor color ] into:pref ] ;
	[ self set:kPSKPlotColor fromColor:[ plotColor color ] into:pref ] ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref
{
	int index ;
	
	[ self retrieveActualColorPreferences:pref ] ;
	//  PSK input prefs
	[ modemSource retrieveForPlist:pref ] ;
	[ pref setInt:( ( [ fileSpeedCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kFastPlayback ] ;
	//  PSK output prefs
	[ modemDest retrieveForPlist:pref ] ;
	[ equalizer retrieveForPlist:pref ] ;
	
	//  active button states and local flag
	[ pref setInt:( [ activeButton state ] == NSOnState )? 1 : 0 forKey:kPSKActive ] ;
	index = [ sidebandMenu indexOfSelectedItem ] ;
	[ pref setInt:index forKey:kPSKSideband ] ;
	[ pref setFloat:[ vfoOffset floatValue ] forKey:kPSKOffset ] ;
}

- (void)startModulator
{
	[ pskModulator resetModulator ] ;
	[ pskModulator insertShortIdle ] ;
}

//  -------------- transmit stream ---------------------

- (void)setTransmitFrequency:(float)freq
{
	[ pskModulator setFrequency:freq ] ;
}

- (Boolean)startTransmit
{
	Boolean canTransmit ;
	float frequency ;
	
	canTransmit = [ (PSK*)modemObj checkTx ] ;
	if ( !canTransmit ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Selected PSK Transceiver not on", nil ) informativeText:NSLocalizedString( @"need to set xcvr", nil ) ] ;
		[ modemObj flushOutput ] ;
		return NO ;
	}

	if ( isActiveButton == YES && interfaceVisible == YES && isTransmit == NO && configOpen == NO ) {
		toneIndex = 0 ;
		//  first stop the audio output stream
		[ modemDest stopSampling ] ;
		//  now set the correct frequency
		frequency = [ (PSK*)modemObj transmitFrequency ] ;
		[ self setTransmitFrequency:frequency ] ;
		//  adjust amplitude based on equalizer here
		equalize = ( equalizer ) ? [ equalizer amplitude:frequency ] : 1.0 ;

		//  turn on the modulator
		[ self startModulator ] ;
		//  finally turn output stream back on
		[ modemDest startSampling ] ;
		if ( transmitButton ) {
			[ transmitButton setTitle:NSLocalizedString( @"Receive", nil ) ] ;
			[ transmitButton setState:NSOnState ] ;
		}
		isTransmit = YES ;
		return YES ;
	}
	isTransmit = NO ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
	if ( transmitButton ) {
		[ transmitButton setTitle:NSLocalizedString( @"Transmit", nil ) ] ;
		[ transmitButton setState:NSOffState ] ;
	}
	if ( !isActiveButton ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"psk sound not active", nil ) informativeText:NSLocalizedString( @"make interface active", nil ) ] ;
	}
	else if ( configOpen ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Close Config Panel", nil ) informativeText:NSLocalizedString( @"Close Config Panel and try Again", nil ) ] ;
	}
	return NO ;
}

- (Boolean)stopTransmit
{
	if ( isTransmit ) {
		isTransmit = NO ;
		[ modemDest stopSampling ] ;
		if ( transmitButton ) {
			[ transmitButton setTitle:NSLocalizedString( @"Transmit", nil ) ] ;
			[ transmitButton setState:NSOffState ] ;
		}
		[ self flushTransmitBuffer ] ; // 0.46
		[ modemObj transmissionEnded ] ;
	}
	return NO ;
}

- (void)transmitCharacter:(int)ascii
{
	if ( ascii == 0x5 ) {							// %[rx]
		[ pskModulator insertSquelchTail ] ;
		return ;
	}
	if ( ascii == 0x6 ) return ;					// ignore %[tx] for now
	[ pskModulator appendASCII:ascii ] ;
}

//  v0.70
- (void)transmitDoubleByteCharacter:(int)first second:(int)second
{
	if ( first == 0 ) {
		if ( second == 0x5 ) {							// %[rx]
			[ pskModulator insertSquelchTail ] ;
			return ;
		}
		if ( second == 0x6 ) return ;					// ignore %[tx] for now
	}
	[ pskModulator appendDoubleByte:first second:second ] ;
}

- (void)flushTransmitBuffer
{
	[ pskModulator resetModulatorAndFlush ] ;		// v0.44
}

//  accepts a button
//  returns YES if PSK modemDest is Transmiting
- (Boolean)turnOnTransmission:(Boolean)inState button:(NSButton*)button mode:(int)mode
{
	Boolean state ;
	
	[ pskModulator setPSKMode:mode ] ;
	transmitButton = button ;
	state = ( inState ) ? [ self startTransmit ] : [ self stopTransmit ] ; 	
	return state ;
}

/* local */
- (void)selectTestTone:(int)index
{
	float freq ;
	
	if ( !toneMatrix ) return ;
	
	[ toneMatrix deselectAllCells ] ;
	[ toneMatrix selectCellAtRow:0 column:index ] ;
	if ( timeout ) {
		[ timeout invalidate ] ;
		timeout = nil ;
	}
	switch ( index ) {
	case 0:
		[ modemDest stopSampling ] ;
		[ modemObj ptt:NO ] ;
		break ;
	default:
		toneIndex = index ;
		freq = [ testFreq floatValue ] ;
		[ idleTone setFrequency:freq ] ;
		[ modemObj ptt:YES ] ;
		[ modemDest startSampling ] ;
		break ;
	}
}

//  watchdog timer, turn test tone off
- (void)timedOut:(NSTimer*)timer
{
	timeout = nil ;
	[ self selectTestTone:0 ] ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
}

- (void)updateDialOffset
{
	float offset ;
	
	if ( 0 && soundFileRunning ) {
		//  use "USB" for soundfiles, with 0 vfo offset
		[ modemObj setWaterfallOffset:0.0 sideband:1 ] ;
		return ;
	}
	
	offset = [ vfoOffset floatValue ] ;
	//  use LSB/USB to indicate offset sign in modemObj
	if ( offset < 0.0 ) offset = -offset ;
	[ modemObj setWaterfallOffset:offset sideband:[ sidebandMenu indexOfSelectedItem ] ] ;
}

//  called from ModemSource when file starts
- (void)soundFileStarting:(NSString*)filename
{
	soundFileRunning = YES ;
	[ self updateDialOffset ] ;
}

//  called from ModemSource when file stopped
- (void)soundFileStopped
{
	soundFileRunning = NO ;
	[ self updateDialOffset ] ;
}

// -------------------------------------------------------------------
- (void)colorChanged:(NSColorWell*)client
{
	[ oscilloscope setDisplayStyle:[ waveformMatrix selectedRow ] plotColor:[ plotColor color ] ] ;
	[ modemObj setTextColor:[ textColor color ] sentColor:[ transmitTextColor color ] backgroundColor:[ backgroundColor color ] plotColor:[ plotColor color ] ] ;
}

//  sideband or VFO offset changed
- (void)sidebandOrOffsetChanged
{
	[ self setPSKSideband:[ sidebandMenu indexOfSelectedItem ] ] ;
	[ self updateDialOffset ] ;
}

- (IBAction)testToneChanged:(id)sender 
{
	int index ;
	
	toneMatrix = sender ;
	index = [ toneMatrix selectedColumn ] ;
	[ self selectTestTone:index ] ;
	if ( index != 0 ) timeout = [ NSTimer scheduledTimerWithTimeInterval:3*60 target:self selector:@selector(timedOut:) userInfo:self repeats:NO ] ;
}

- (IBAction)openEqualizer:(id)sender
{
	if ( equalizer ) [ equalizer showMacroSheetIn:window ] ;
}


//  ---------------- ModemDest callbacks ---------------------

//  modemDest needs more data
- (int)needData:(float*)outbuf samples:(int)samples
{
	int i ;
	float v ;
	
	//  assume
	//  outputSamplingRate = 11025
	//  outputChannels = 1
	
	//  cache auralMonitor
	if ( auralMonitor == nil ) auralMonitor = [ (PSK*)outputClient auralMonitor ] ;
	
	switch ( toneIndex ) {
	case 0:
		//  regular transmission
		[ pskModulator getBufferWithIdleFill:outbuf length:samples ] ;
		if ( outbuf[samples-2] == 0.0 && outbuf[samples-1] == 0.0 ) [ modemObj changeTransmitStateTo:NO ] ;
		break ;
	default:
		//  idle
		[ idleTone getBufferWithIdleFill:outbuf length:samples ] ;
		break ;
	}
	//  send prescaled value to aural monitor
	if ( auralMonitor ) [ auralMonitor importTransmitData:outbuf ] ;
	
	if ( equalizer ) v = equalize*outputScale ; else v = outputScale ;
	
	for ( i = 0; i < samples; i++ ) outbuf[i] *= v ;
	
	return 1 ; // output channels
}

- (void)setOutputScale:(float)value
{
	outputScale = value * [ modemObj outputBoost ] ;		//  v0.88 allow 2 dB boost
	[ pskModulator setOutputScale:1.0 ] ;					//  v0.78 apply scale at needData
	[ idleTone setOutputScale:1.0 ] ;
}

//  ------------------------ Delegates -----------------------
//  delegate for Config panel
- (BOOL)windowShouldClose:(id)sender
{
	configOpen = NO ;
	[ self updateInputSamplingState ] ;
	[ modemDest stopSampling ] ;
	//  turn tone matrix selection to OFF
	[ toneMatrix deselectAllCells ] ;
	[ toneMatrix selectCellAtRow:0 column:0 ] ;
	toneIndex = 0 ;

	return YES ;
}

@end
