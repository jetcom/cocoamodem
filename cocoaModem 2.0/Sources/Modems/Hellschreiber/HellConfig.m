//
//  HellConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Wed Jul 27 2005.
	#include "Copyright.h"
//

#import "HellConfig.h"
#import "Application.h"
#import "HellModulator.h"
#import "Hellschreiber.h"
#import "Messages.h"
#import "ModemDest.h"
#import "ModemEqualizer.h"
#import "ModemSource.h"
#import "Oscilloscope.h"
#import "Plist.h"
#import "PTT.h"
#import "TextEncoding.h"
#import "VUMeter.h"
#import "CMPCO.h"
#import "CMDSPWindow.h"

@implementation HellConfig

//  Hellschreiber Config

- (void)awakeFromModem:(Hellschreiber*)modem
{
	NSString *path ;
	HellschreiberFontHeader *fnt ;
	
	equalize = 1.0 ;
	
	fonts = 0 ;
	//  get default font

	path = [ [ NSBundle mainBundle ] pathForResource:@"cm bitmap" ofType:@"font" ] ;
	fnt = MakeHellFont( [ path cStringUsingEncoding:kTextEncoding ] ) ;
	if ( fnt ){
		font[fonts] = fnt ;
		[ (Hellschreiber*)modemObj addFont:fnt index:fonts ] ;
		fonts++ ;
	}
	
	path = [ [ NSBundle mainBundle ] pathForResource:@"cm bitmap aa" ofType:@"font" ] ;
	fnt = MakeHellFont( [ path cStringUsingEncoding:kTextEncoding ] ) ;
	if ( fnt ) {
		font[fonts] = fnt ;
		[ (Hellschreiber*)modemObj addFont:fnt index:fonts ] ;
		fonts++ ;
	}
	
	path = [ [ NSBundle mainBundle ] pathForResource:@"cm small" ofType:@"font" ] ;
	fnt = MakeHellFont( [ path cStringUsingEncoding:kTextEncoding ] ) ;
	if ( fnt ){
		font[fonts] = fnt ;
		[ (Hellschreiber*)modemObj addFont:fnt index:fonts ] ;
		fonts++ ;
	}

	path = [ [ NSBundle mainBundle ] pathForResource:@"cm small aa" ofType:@"font" ] ;
	fnt = MakeHellFont( [ path cStringUsingEncoding:kTextEncoding ] ) ;
	if ( fnt ){
		font[fonts] = fnt ;
		[ (Hellschreiber*)modemObj addFont:fnt index:fonts ] ;
		fonts++ ;
	}

	path = [ [ NSBundle mainBundle ] pathForResource:@"cm bitmapdoublewide" ofType:@"font" ] ;
	fnt = MakeHellFont( [ path cStringUsingEncoding:kTextEncoding ] ) ;
	if ( fnt ) {
		font[fonts] = fnt ;
		[ (Hellschreiber*)modemObj addFont:fnt index:fonts ] ;
		fonts++ ;
	}
	
	toneMatrix = nil ;
	transmitButton = nil ;
	timeout = nil ;
	soundFileRunning = NO ;
	vuMeter = [ modem vuMeter ] ;
	
	[ super initializeActions ] ;
	
	//  set up modulator
	hellModulator = [ [ HellModulator alloc ] init ] ;
	[ hellModulator setFrequency:10.0 ] ;		// default to 10 Hz carrier
	[ hellModulator setModemClient:modemObj ] ;
	[ hellModulator setFont:font[0] ] ;
	//  test tones
	idleTone = [ [ HellModulator alloc ] init ] ;
	[ idleTone setCW:YES ] ;
	[ idleTone setFrequency:1000.0 ] ;
		
	[ vuMeter setup ] ;
	fastFileSpeed = 4 ;
	[ self setupModemSource:kHellInputDevice channel:LEFTCHANNEL ] ;
	[ self setupModemDest:kHellOutputDevice controlView:soundOutputControls attenuatorView:soundOutputLevel ] ;
	[ modemDest setSoundLevelKey:kHellOutputLevel attenuatorKey:kHellOutputAttenuator ] ;
	
	//  Set up Transmit equalizer
	equalizer = [ [ ModemEqualizer alloc ] initSheetFor:@"Hellschreiber" ] ;
	equalize = 1.0 ;
	
	//  delegate to trap config panel closure
	[ window setDelegate:self ] ;
	
	//  actions
	[ self setInterface:vfoOffset to:@selector(sidebandOrOffsetChanged) ] ;	
	[ self setInterface:sidebandMenu to:@selector(sidebandOrOffsetChanged) ] ;	
	[ self setInterface:diddleButton to:@selector(diddleChanged) ] ;	

	//  start sampling later in an NSTimer driven -checkActive
	[ modemSource enableInput:YES ] ;		
}

- (void)selectFont:(int)index
{
	[ hellModulator setFont:font[index] ] ;
}

- (void)setMode:(int)mode
{
	[ hellModulator setMode:mode ] ;
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

//  0 - LSB
//  1 - USB
- (void)setSideband:(int)index
{
	[ sidebandMenu selectItemAtIndex:index ] ;
	switch ( index ) {
	case 0:
	default:
		[ modemObj selectAlternateSideband:NO ] ;
		[ hellModulator setSidebandState:NO ] ;
		break ;
	case 1:
		[ modemObj selectAlternateSideband:YES ] ;
		[ hellModulator setSidebandState:YES ] ;
		break ;
	}
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
//  get an NSColor for preferences
- (NSColor*)getColorRed:rTag green:gTag blue:bTag from:(Preferences*)pref
{
	float red, green, blue ;
	
	red = [ pref floatValueForKey:rTag ] ;
	green = [ pref floatValueForKey:gTag ] ;
	blue = [ pref floatValueForKey:bTag ] ;
	return [ [ NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1 ] retain ] ;
}

//  preferences maintainence, called from Hellschreiber.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setInt:0 forKey:kHellActive ] ;
	[ pref setInt:1 forKey:kFastPlayback ] ;
	[ pref setInt:1 forKey:kHellSideband ] ;			// default to USB
	[ pref setFloat:0.0 forKey:kHellOffset ] ;			// and no VFO offset
	[ self retrieveActualColorPreferences:pref ] ;

	[ modemSource setupDefaultPreferences:pref ] ;
	[ modemDest setupDefaultPreferences:pref ] ;
	[ equalizer setupDefaultPreferences:pref ] ;
	
	[ pref setInt:0 forKey:kHellDiddle ] ;
}

- (void)updateColorsFromPreferences:(Preferences*)pref
{
	NSColor *color, *sent, *bg, *plot ;

	color = [ self getColor:kHellTextColor from:pref ] ;
	sent = [ self getColor:kHellSentColor from:pref ] ;
	bg = [ self getColor:kHellBackgroundColor from:pref ] ;
	plot = [ self getColor:kHellPlotColor from:pref ] ;		
	 
	//  set colors
	[ textColor setColor:color ] ;
	[ transmitTextColor setColor:sent ] ;
	[ backgroundColor setColor:bg ] ;
	[ plotColor setColor:plot ] ;
	[ oscilloscope setDisplayStyle:0 plotColor:plot ] ;  //  initially spectrum
	[ modemObj setTextColor:color sentColor:sent backgroundColor:bg plotColor:plot ] ;
	[ modemObj updateColorsInViews ] ;
}

//  called from Hellschreiber.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref
{
	int state ;
	
	//  set up active button states and set the button states
	//  later, a Timer would activate to obey these buttons
	[ activeButton setState:( [ pref intValueForKey:kHellActive ] == 1 ) ? NSOnState : NSOffState ] ;
	
	//  now reset active states if autoconnect is off
	if ( [ pref intValueForKey:kAutoConnect ] == 0 ) [ activeButton setState:NSOffState ] ;
	
	[ self updateColorsFromPreferences:(Preferences*)pref ] ;
	
	if ( ( ![ modemSource updateFromPlist:pref ] || ![ modemDest updateFromPlist:pref ] ) && ( [ activeButton state ] == NSOnState ) ) {
		[ activeButton setState:NSOffState ] ;
		//  toggle input attenuator		
		NSString *selStr = [ @"Hellschreiber: " stringByAppendingString:NSLocalizedString( @"Select Sound Card", nil ) ] ;
		[ Messages alertWithMessageText:selStr informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}
	[ modemSource setDeviceLevel:[ (Hellschreiber*)modemObj inputAttenuator:self ] ] ;
	[ equalizer updateFromPlist:pref ] ;

	[ self setSideband:[ pref intValueForKey:kHellSideband ] ] ;
	[ vfoOffset setFloatValue:[ pref floatValueForKey:kHellOffset ] ] ;
	[ self updateDialOffset ] ; //  this updates the labels of the waterfall

	state = [ pref intValueForKey:kFastPlayback ] ;
	[ fileSpeedCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
	[ self updateFileSpeed ] ;
	
	state = [ pref intValueForKey:kHellDiddle ] ;
	[ diddleButton setState:( state ) ? NSOnState : NSOffState ] ;
	[ hellModulator setDiddle:state ] ;

	return true ;
}

- (void)retrieveActualColorPreferences:(Preferences*)pref
{
	[ self set:kHellTextColor fromColor:[ textColor color ] into:pref ] ;
	[ self set:kHellSentColor fromColor:[ transmitTextColor color ] into:pref ] ;
	[ self set:kHellBackgroundColor fromColor:[ backgroundColor color ] into:pref ] ;
	[ self set:kHellPlotColor fromColor:[ plotColor color ] into:pref ] ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref
{
	int index ;
	
	[ self retrieveActualColorPreferences:pref ] ;
	//  Hellschreiber input prefs
	[ modemSource retrieveForPlist:pref ] ;
	[ pref setInt:( ( [ fileSpeedCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kFastPlayback ] ;
	//  Hellschreiber output prefs
	[ modemDest retrieveForPlist:pref ] ;
	[ equalizer retrieveForPlist:pref ] ;
	
	//  active button states and local flag
	[ pref setInt:( [ activeButton state ] == NSOnState )? 1 : 0 forKey:kHellActive ] ;
	[ pref setInt:( [ diddleButton state ] == NSOnState )? 1 : 0 forKey:kHellDiddle ] ;
	index = [ sidebandMenu indexOfSelectedItem ] ;
	[ pref setInt:index forKey:kHellSideband ] ;
	[ pref setFloat:[ vfoOffset floatValue ] forKey:kHellOffset ] ;
}

- (void)startModulator
{
	[ hellModulator resetModulator ] ;
	[ hellModulator insertShortIdle ] ;
}

//  -------------- transmit stream ---------------------
- (Boolean)startTransmit
{
	Boolean canTransmit ;
	float frequency ;

	
	canTransmit = [ (Hellschreiber*)modemObj checkTx ] ;
	if ( !canTransmit ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Hellschreiber not on", nil ) informativeText:NSLocalizedString( @"Click on waterfall", nil ) ] ;
		[ modemObj flushOutput ] ;
		return NO ;
	}

	if ( isActiveButton == YES && isTransmit == NO && interfaceVisible == YES && configOpen == NO ) {
		toneIndex = 0 ;
		//  first stop the audio output stream
		[ modemDest stopSampling ] ;
		//  now set the correct frequency
		frequency = [ (Hellschreiber*)modemObj transmitFrequency ] ;
		[ hellModulator setFrequency:frequency ] ;
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
	if ( isActiveButton == NO ) {
		NSString *selStr = [ @"Hellschreiber: " stringByAppendingString:NSLocalizedString( @"Select Sound Card", nil ) ] ;
		[ Messages alertWithMessageText:selStr informativeText:NSLocalizedString( @"make interface active", nil ) ] ;
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
		[ modemObj transmissionEnded ] ;
	}
	return NO ;
}

- (void)transmitCharacter:(int)ascii
{
	if ( ascii == 5 /* switch to receive */ ) {
		[ hellModulator insertEndOfTransmit ] ;
		return ;
	}
	if ( ascii == 0x6 ) return ;		// ignore %[tx] hint
	
	[ hellModulator appendASCII:ascii ] ;
}

- (void)flushTransmitBuffer
{
	[ hellModulator flushTransmitBuffer ] ;
}

//  accepts a button
//  returns YES if Hellschreiber modemDest is Transmiting
- (Boolean)turnOnTransmission:(Boolean)inState button:(NSButton*)button
{
	Boolean state ;
	
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
	[ self setSideband:[ sidebandMenu indexOfSelectedItem ] ] ;
	[ self updateDialOffset ] ;
}

//  diddle changed
- (void)diddleChanged
{
	[ hellModulator setDiddle:[ diddleButton state ] ] ;
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
	
	//  assume
	//  outputSamplingRate = 11025
	//  outputChannels = 1
	
	switch ( toneIndex ) {
	case 0:
		//  regular transmission
		[ hellModulator getBufferWithIdleFill:outbuf length:samples ] ;		
		if ( [ hellModulator terminated ] ) {
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
	[ hellModulator setOutputScale:outputScale ] ;
	[ idleTone setOutputScale:outputScale ] ;
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
