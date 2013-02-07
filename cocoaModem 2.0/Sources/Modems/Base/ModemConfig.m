//
//  ModemConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Sat Jul 31 2004.
	#include "Copyright.h"
//

#import "ModemConfig.h"
#import "Application.h"
#import "Config.h"
#import "Modem.h"
#import "ModemColor.h"
#import "ModemDest.h"
#import "ModemEqualizer.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Oscilloscope.h"


@implementation ModemConfig

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)initializeActions
{
	agcValue = 0.4 ;			//  v0.88d
	
	[ self setInterface:textColor to:@selector(colorChanged:) ] ;
	[ self setInterface:transmitTextColor to:@selector(colorChanged:) ] ;
	[ self setInterface:backgroundColor to:@selector(colorChanged:) ] ;
	[ self setInterface:plotColor to:@selector(colorChanged:) ] ;
	
	//  send active button changes to activeButtonChanged
	[ self setInterface:activeButton to:@selector(activeButtonChanged) ] ;
	//  send input pad changes to inputPadChanged
	[ self setInterface:inputPad to:@selector(inputPadChanged) ] ;

	//  send file speed changes to fileSpeedChanged
	[ self setInterface:fileSpeedCheckbox to:@selector(fileSpeedChanged) ] ;
	
	//  send plot style button changes
	[ self setInterface:waveformMatrix to:@selector(plotStyleChanged) ] ;
}

//  sets up a modem source with one data channel if ch = (0,1) set up for dual channel if ch = 2
- (void)setupModemSource:(NSString*)inputDevice channel:(int)ch
{
	int speed ;
	NSSlider *inputAttenuator ;
	CMTappedPipe *dataClient ;
	
	isActiveButton = interfaceVisible = isTransmit = configOpen = inputSamplingState = NO ;
	sequenceNumber = 0 ;

	speed = ( fileSpeedCheckbox && [ fileSpeedCheckbox state ] == NSOnState ) ? fastFileSpeed : 1 ;
	
	equalizer = nil ;
	modemSource = [ [ ModemSource alloc ] initIntoView:soundInputControls device:inputDevice fileExtra:soundFileControls playbackSpeed:speed channel:ch client:self ] ;
	
	[ modemSource setupSoundCards ] ;						//  v0.78

	dataClient = [ modemObj dataClient ] ;
	if ( dataClient ) [ self setClient:dataClient ] ;		// data is then sent to the dataClient (except for SDR devices)
	[ modemSource setDelegate:self ] ;						// soundFileStarting, soundFileStopped

	inputAttenuator = [ modemObj inputAttenuator:self ] ;
	if ( inputAttenuator ) {
		// set up input attenuator
		[ modemSource registerLevelSlider:inputAttenuator isScalar:NO ] ;
		[ inputAttenuator setFloatValue:0.0 ] ;
	}
	if ( inputPad ) {
		[ modemSource registerInputPad:inputPad ] ;
		[ inputPad setFloatValue:0.0 ] ;
	}
}

- (void)setupModemDest:(NSString*)outputDevice controlView:(NSView*)controlView attenuatorView:(NSView*)levelView
{
	NSSlider *slider ;
	
	//  set up output sound with this config as the data source of sound channel
	modemDest = [ [ ModemDest alloc ] initIntoView:controlView device:outputDevice level:levelView client:self pttHub:[ [ modemObj managerObject ] pttHub ] ] ;

	[ modemDest setupSoundCards ] ;		//  v0.78
	
	if ( levelView ) {
		//  set up common level slider
		slider = [ modemDest outputLevel ] ;
		if ( slider ) {
			[ modemDest registerLevelSlider:slider isScalar:YES ] ;
		}
	}
}

//	v0.78 cclean up modemsource(s) and modemDest
- (void)applicationTerminating
{
}

- (Modem*)modemObject
{
	return modemObj ;
}

- (PTT*)pttObject
{
	if ( !modemDest ) return nil ;
	return [ modemDest ptt ] ;
}

- (void)openPanel
{
	[ window center ] ;
	[ window orderFront:self ] ;
	//  set ourself as delegate of config's window to catch closes
	[ window setDelegate:self ] ;

	configOpen = YES ;
	[ self updateInputSamplingState ] ;
	if ( isTransmit ) {
		isTransmit = NO ;
		[ modemDest stopSampling ] ;
	}
}

- (long)sequenceNumber
{
	return sequenceNumber ;
}

- (void)closePanel
{
	configOpen = NO ;
	[ window orderOut:self ] ;
}

- (Boolean)transmitActive
{
	return isTransmit ;
}

- (void)setConfigOpen:(Boolean)state
{
	configOpen = state ;
	[ self updateInputSamplingState ] ;		// v 0.29
}

//   override by class instance
- (void)setOutputScale:(float)value
{
}

- (Boolean)soundInputActive
{
	return isActiveButton ;
}

- (void)setSoundInputActive:(Boolean)state
{
	[ activeButton setState:(state) ? NSOnState : NSOffState ] ;
	[ self checkActive ] ;
}

//  check active button
- (Boolean)updateActiveButtonState
{
	//  check active button for state changes
	isActiveButton = ( [ activeButton state ] == NSOnState ) ;
	[ activeButton setTitle:( isActiveButton ) ? NSLocalizedString( @"Active", nil ) : NSLocalizedString( @"Inactive", nil ) ] ;
	
	return isActiveButton ;
}

- (void)updateInputSamplingState
{
	Boolean oldState = inputSamplingState ;
		
	//  turn sampling on if config panel is open or config's interface is selected (v0.27) and is active
	inputSamplingState = ( ( isActiveButton && interfaceVisible ) || configOpen ) ;
	
	if ( inputSamplingState != oldState ) {
		if ( inputSamplingState == YES ) {
			[ modemSource startSampling ] ;
		}
		else {
			[ modemSource stopSampling ] ;
		}
	}
}

//	v0.87
- (void)setKeyerMode
{
	printf( "ModemConfig: setKeyerMode (should override by subclass\n" ) ;
}

//	v0.88d
//	Received an AGC correction value from CMFSKMixer
//	This value should not be called if it is between 0.35 and 0.5.
//	If the value is lower than 0.35, the input sound card gain should be increased
//	If the value is greater than 0.5,the input sound card gain should be reduced
- (void)processAGC:(float)amplitude
{
	if ( amplitude > 0.5 || amplitude < 0.3 ) {
		//  fast AGC
		agcValue = amplitude ;
	}
	else {
		//  slow AGC
		agcValue = agcValue*0.9 + amplitude*0.1 ;
	}
	
	if ( agcValue > 0.50 ) {
		if ( agcValue > 0.70 ) {
			[ modemSource changeDeviceGain:-4 ] ;
			return ;
		}
		[ modemSource changeDeviceGain:-2 ] ;
		return ;
	}
	if ( agcValue < 0.35 ) {
		if ( agcValue < 0.2 ) {
			[ modemSource changeDeviceGain:2 ] ;
			return ;
		}
		[ modemSource changeDeviceGain:1 ] ;
	}
}

- (void)updateVisibleState:(Boolean)state
{
	interfaceVisible = state ;
	//  now check if we need to turn on/off actual sampling
	[ self updateInputSamplingState ] ;
}

- (ModemSource*)inputSource
{
	return modemSource ;
}

- (void)updateFileSpeed
{
	int speed = ( [ fileSpeedCheckbox state ] == NSOnState ) ? fastFileSpeed : 1 ;
	[ modemSource fileSpeedChanged:speed ] ;
}

//  AudioOutputPort callback - override by subclasses
- (int)needData:(float*)outbuf samples:(int)n
{
	return 0 ;
}

//  Plist
//  set preferences to an NSColor (version 1)
- (void)setColorRed:(NSString*)rTag green:(NSString*)gTag blue:(NSString*)bTag fromColor:(NSColor*)color into:(Preferences*)pref
{
	float red, green, blue, alpha ;
	
	[ color getRed:&red green:&green blue:&blue alpha:&alpha ] ;
	[ pref setFloat:red forKey:rTag ] ;
	[ pref setFloat:green forKey:gTag ] ;
	[ pref setFloat:blue forKey:bTag ] ;
}

//  set preferences to an NSColor (version 2)
- (void)set:(NSString*)tag fromColor:(NSColor*)color into:(Preferences*)pref
{
	[ pref setColor:color forKey:tag ] ;
}

- (void)set:(NSString*)tag fromRed:(float)red green:(float)green blue:(float)blue into:(Preferences*)pref
{
	[ pref setRed:red green:green blue:blue forKey:tag ] ;
}

//  get an NSColor for preferences (version 1)
- (NSColor*)getColorRed:(NSString*)rTag green:(NSString*)gTag blue:(NSString*)bTag from:(Preferences*)pref
{
	float red, green, blue ;
	
	red = [ pref floatValueForKey:rTag ] ;
	green = [ pref floatValueForKey:gTag ] ;
	blue = [ pref floatValueForKey:bTag ] ;
	return [ [ NSColor colorWithCalibratedRed:red green:green blue:blue alpha:1 ] retain ] ;
}

//  get an NSColor for preferences (version 2)
- (NSColor*)getColor:(NSString*)tag from:(Preferences*)pref
{
	return [ pref colorValueForKey:tag ] ;
}

- (void)inputAttenuatorChanged:(NSSlider*)inputAttenuator
{
	[ modemSource setDeviceLevel:inputAttenuator ] ;
}

//  this is called from Application.m after the plist has been updated
//  and whenever an "active" button for some mode is pressed or changed by AppleScript
- (void)checkActive
{
	[ self updateActiveButtonState ] ;
	[ modemSource enableInput:YES ] ;
	[ modemDest enableOutput:YES ] ;
	[ self updateInputSamplingState ] ;
	[ modemObj activeChanged:self ] ;
}

//  override by subclasses of ModemConfig
- (void)updateColorsFromPreferences:(Preferences*)pref
{
}

//  override by subclasses of ModemConfig
- (void)retrieveActualColorPreferences:(Preferences*)pref
{
}

//  ---- actions ---------
- (void)activeButtonChanged
{
	[ self checkActive ] ;
}

- (void)colorChanged:(id)sender
{
}

static NSString *freqLabel[] = { @"500", @"1000", @"1500", @"2000", @"2500" } ;

- (void)plotStyleChanged
{
	int i, which ;
	NSTextField *text ;
	
	which = [ waveformMatrix selectedRow ] ;
	[ waveformMatrix deselectAllCells ] ;
	[ waveformMatrix selectCellAtRow:which column:0 ] ;
	
	//  hide spectrum label if waveform style
	for ( i = 0; i < 5; i++ ) {
		text = [ specLabel cellAtRow:0 column:i ] ;
		[ text setStringValue:( which == 0 ) ? freqLabel[i] : @"" ] ;
	}
	[ oscilloscope setDisplayStyle:which plotColor:[ plotColor color ] ] ;
}

- (void)inputPadChanged
{
	[ modemSource setPadLevel:inputPad ] ;
	[ modemSource setDeviceLevel:[ modemObj inputAttenuator:self ] ] ;
}

- (void)fileSpeedChanged
{
	[ self updateFileSpeed ] ;
}

//  delegate to ModemSource
- (void)soundFileStarting:(NSString*)filename
{
}

//  delegate to ModemSource
- (void)soundFileStopped
{
}

//  delegate of config window
- (BOOL)windowShouldClose:(id)sender
{
	[ self setConfigOpen:NO ] ;
	return YES ;
}

//  v0.73 direct file open (shift-Cms-F)
- (void)directOpenSoundFile
{
	[ modemSource openFile:self ] ;
}


@end
