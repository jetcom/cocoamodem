//
//  MFSKConfig.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on  2/15/06.
	#include "Copyright.h"
//

#import "MFSKConfig.h"
#import "CMDSPWindow.h"
#import "Application.h"
#import "Messages.h"
#import "MFSK.h"
#import "MFSKModulator.h"
#import "ModemColor.h"
#import "Messages.h"
#import "ModemDest.h"
#import "ModemEqualizer.h"
#import "ModemSource.h"
#import "modemTypes.h"
#import "Oscilloscope.h"
#import "Plist.h"
#import "PTT.h"

@implementation MFSKConfig

//  MFSK Config

- (void)awakeFromModem:(MFSK*)modem
{		
	toneMatrix = nil ;
	transmitButton = nil ;
	timeout = nil ;
	vuMeter = [ modem vuMeter ] ;
	
	[ super initializeActions ] ;

	fastFileSpeed = 16 ;
	[ self setupModemSource:kMFSKInputDevice channel:LEFTCHANNEL ] ;
	[ self setupModemDest:kMFSKOutputDevice controlView:soundOutputControls attenuatorView:soundOutputLevel ] ;
	[ modemDest setSoundLevelKey:kMFSKOutputLevel attenuatorKey:kMFSKOutputAttenuator ] ;
	//  Set up Transmit equalizer
	equalizer = [ [ ModemEqualizer alloc ] initSheetFor:@"MFSK" ] ;
	equalize = 1.0 ;
	//  test tone
	timeout = nil ;
	idleTone = [ [ MFSKModulator alloc ] init ] ;
	[ idleTone setCW:YES ] ;
	[ idleTone setFrequency:1000.0 ] ;

	//  delegate to trap config panel closure
	[ window setDelegate:self ] ;
	//  start sampling later in an NSTimer driven
	[ modemSource enableInput:YES ] ;
	//  actions
	[ self setInterface:vfoOffset to:@selector(sidebandOrOffsetChanged) ] ;	
	[ self setInterface:sidebandMenu to:@selector(sidebandOrOffsetChanged) ] ;	
}

//	v0.87
- (void)setKeyerMode
{
	PTT *ptt ;
		
	ptt = [ self pttObject ] ;
	if ( ptt ) [ ptt setKeyerMode:kMicrohamDigitalRouting ] ;	//  v0.93b
}

- (NSPopUpButton*)sidebandMenu
{
	return sidebandMenu ;
}

//  0 - LSB
//  1 - USB
- (void)setSideband:(int)index
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

//  accepts a button
//  returns YES if modemDest is Transmiting
- (Boolean)turnOnTransmission:(Boolean)inState button:(NSButton*)button modulator:(MFSKModulator*)m
{
	Boolean state ;
	
	transmitButton = button ;
	state = ( inState ) ? [ self startTransmit:m ] : [ self stopTransmit ] ; 	
	return state ;
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
	if ( ( ( isActiveButton && !isTransmit ) || [ modemSource fileRunning ] ) && interfaceVisible ) {
		*data = *[ pipe stream ] ;
		[ self exportData ] ;
		[ vuMeter importData:pipe ] ;
	}
	if ( configOpen && oscilloscope ) {
		[ oscilloscope addData:[ pipe stream ] isBaudot:NO timebase:1 ] ;
	}
}

//  check active button
- (Boolean)updateActiveButtonState
{
	[ super updateActiveButtonState ] ;	
	return isActiveButton ;
}

- (void)updateDialOffset
{
	float offset ;
	
	offset = [ vfoOffset floatValue ] ;
	//  use LSB/USB to indicate offset sign in modemObj
	if ( offset < 0.0 ) offset = -offset ;
	[ modemObj setWaterfallOffset:offset sideband:[ sidebandMenu indexOfSelectedItem ] ] ;
}

//  -------------- transmit stream ---------------------
- (Boolean)startTransmit:(MFSKModulator*)m
{
	float frequency ;
	Boolean canTransmit ;
	
	canTransmit = [ (MFSK*)modemObj checkIfCanTransmit ] ;
	if ( !canTransmit ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"MFSK cannot transmit.", nil ) informativeText:NSLocalizedString( @"Frequency not set", nil ) ] ;
		[ modemObj flushOutput ] ;
		return NO ;
	}

	frequency = [ (MFSK*)modemObj transmitFrequency ] ;
	modulator = m ;

	if ( isActiveButton == YES && isTransmit == NO && interfaceVisible == YES && configOpen == NO ) {
		toneIndex = 0 ;
		//  first stop the audio output stream
		[ modemDest stopSampling ] ;
		//  now set the modulator to the current frequency
		[ modulator setFrequency:frequency ] ;
		//  adjust amplitude based on equalizer here
		equalize = ( equalizer ) ? [ equalizer amplitude:frequency ] : 1.0 ;

		//  reset the modulator
		[ modulator resetModulator ] ;
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
	if ( isActiveButton == NO ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Sound Card not active", nil ) informativeText:NSLocalizedString( @"make interface active", nil ) ] ;
	}
	else if ( configOpen ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Cannot transmit with the Config Panel open", nil ) informativeText:NSLocalizedString( @"Close Config Panel and try Again", nil ) ] ;
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
		[ modemObj transmissionEnded ] ;
	}
	return NO ;
}


//  ---------------- ModemDest callbacks ---------------------

//  modemDest needs more data
- (int)needData:(float*)outbuf samples:(int)samples
{
	int i ;
	
	//  assume
	//  outputSamplingRate = 11025
	//  outputChannels = 1
	switch ( toneIndex ) {
	case 0:
		//  regular transmission
		[ modulator getBufferWithIdleFill:outbuf length:samples ] ;		
		if ( [ modulator terminated ] ) {
			[ modemObj changeTransmitStateTo:NO ] ;
		}
		break ;
	default:
		//  idle
		[ idleTone getBufferWithIdleFill:outbuf length:samples ] ;
		break ;
	}
	if ( equalizer ) for ( i = 0; i < samples; i++ ) outbuf[i] *= equalize ;
	return 1 ; // output channels
}

- (void)setOutputScale:(float)value
{
	outputScale = value ;
	[ (MFSK*)modemObj setOutputScale:value ] ;
	[ idleTone setOutputScale:value ] ;
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
		toneIndex = 0 ;
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

/* local */
- (void)setupDefaultColorPreferences:(Preferences*)pref
{
	[ self set:kMFSKTextColor fromRed:1.0 green:0.8 blue:0.0 into:pref ] ;
	[ self set:kMFSKBackgroundColor fromRed:0.0 green:0.0 blue:0.0 into:pref ] ;
	[ self set:kMFSKPlotColor fromRed:0.0 green:1.0 blue:0.0 into:pref ] ;
	[ self set:kMFSKSentColor fromRed:0.0 green:0.8 blue:1.0 into:pref ] ;
}

//  preferences maintainence, called from MFSK.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setInt:1 forKey:kFastPlayback ] ;
	[ pref setInt:0 forKey:kMFSKActive ] ;
	[ self setupDefaultColorPreferences:pref ] ;
	[ modemSource setupDefaultPreferences:pref ] ;
	[ modemDest setupDefaultPreferences:pref ] ;
	[ equalizer setupDefaultPreferences:pref ] ;
}

- (void)updateColorsFromPreferences:(Preferences*)pref
{
	NSColor *color, *sent, *bg, *plot ;
		
	color = [ self getColor:kMFSKTextColor from:pref ] ;
	sent = [ self getColor:kMFSKSentColor from:pref ] ;
	bg = [ self getColor:kMFSKBackgroundColor from:pref ] ;
	plot = [ self getColor:kMFSKPlotColor from:pref ] ;		
	//  set colors
	[ textColor setColor:color ] ;
	[ transmitTextColor setColor:sent ] ;
	[ backgroundColor setColor:bg ] ;
	[ plotColor setColor:plot ] ;
	[ oscilloscope setDisplayStyle:0 plotColor:plot ] ;  //  initially spectrum
	[ modemObj setTextColor:color sentColor:sent backgroundColor:bg plotColor:plot ] ;
	[ modemObj updateColorsInViews ] ;
}

//  called from MFSK.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref
{
	int state ;

	[ self updateColorsFromPreferences:(Preferences*)pref ] ;

	if ( ( ![ modemSource updateFromPlist:pref ] || ![ modemDest updateFromPlist:pref ] ) && ( [ activeButton state ] == NSOnState ) ) {
		[ activeButton setState:NSOffState ] ;
		//  toggle input attenuator	
		NSString *selStr = [ @"MFSK16/DominoEX: " stringByAppendingString:NSLocalizedString( @"Select Sound Card", nil ) ] ;	
		[ Messages alertWithMessageText:selStr informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}
	
	//  set up active button state
	state = ( [ pref intValueForKey:kMFSKActive ] == 1 ) ? NSOnState : NSOffState ;
	[ activeButton setState:state ] ;
	//  now reset active states if autoconnect is off
	if ( [ pref intValueForKey:kAutoConnect ] == 0 ) [ activeButton setState:NSOffState ] ;

	[ modemSource setDeviceLevel:[ (MFSK*)modemObj inputAttenuator:self ] ] ;
	[ equalizer updateFromPlist:pref ] ;
		
	[ self setSideband:[ pref intValueForKey:kMFSKSideband ] ] ;
	[ vfoOffset setFloatValue:[ pref floatValueForKey:kMFSKOffset ] ] ;
	[ self updateDialOffset ] ; //  this updates the labels of the waterfall

	state = [ pref intValueForKey:kFastPlayback ] ;
	[ fileSpeedCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
	[ self updateFileSpeed ] ;
		
	return true ;
}

- (void)retrieveActualColorPreferences:(Preferences*)pref
{
	[ self set:kMFSKTextColor fromColor:[ textColor color ] into:pref ] ;
	[ self set:kMFSKSentColor fromColor:[ transmitTextColor color ] into:pref ] ;
	[ self set:kMFSKBackgroundColor fromColor:[ backgroundColor color ] into:pref ] ;
	[ self set:kMFSKPlotColor fromColor:[ plotColor color ] into:pref ] ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref
{
	int index, state ;
	
	[ self retrieveActualColorPreferences:pref ] ;
	//  MFSK input prefs
	[ modemSource retrieveForPlist:pref ] ;
	[ pref setInt:( ( [ fileSpeedCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kFastPlayback ] ;
	//  MFSK output prefs
	[ modemDest retrieveForPlist:pref ] ;
	[ equalizer retrieveForPlist:pref ] ;
	
	//  active button states and local flag
	state = ( [ activeButton state ] == NSOnState )? 1 : 0 ;
	[ pref setInt:state forKey:kMFSKActive ] ;
	index = [ sidebandMenu indexOfSelectedItem ] ;
	[ pref setInt:index forKey:kMFSKSideband ] ;
	[ pref setFloat:[ vfoOffset floatValue ] forKey:kMFSKOffset ] ;
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
	[ self setSideband:[ sidebandMenu indexOfSelectedItem ] ] ;
	[ (MFSK*)modemObj turnOffReceiver:0 option:NO ] ;				//  v0.73
	[ self updateDialOffset ] ;
}

//  ------------------------ Delegates -----------------------
//  delegate for Config panel
- (BOOL)windowShouldClose:(id)sender
{
	configOpen = NO ;
	[ self updateInputSamplingState ] ;
	//  turn tone matrix selection to OFF if it was on
	if ( toneIndex != 0 ) {
		[ toneMatrix deselectAllCells ] ;
		[ toneMatrix selectCellAtRow:0 column:0 ] ;
		[ self selectTestTone:0 ] ;
		toneIndex = 0 ;
	}
	return YES ;
}

@end
