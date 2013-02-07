//
//  SynchAM.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/07.
	
#import "SynchAM.h"
#import "AMConfig.h"
#import "AMDemodulator.h"
#import "AMWaterfall.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Plist.h"
#import "VUMeter.h"


@implementation SynchAM

//  SynchAM : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	[ mgr showSplash:@"Creating Synch-AM Modem" ] ;

	self = [ super initIntoTabView:tabview nib:@"SynchAM" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		lockState = -1 ;
		outputScale = 0.707 ;
	}
	return self ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)awakeFromNib
{
	ident = NSLocalizedString( @"Synch-AM", nil ) ;

	[ (AMConfig*)config awakeFromModem:self ] ;
	[ waterfall awakeFromModem ] ;
	[ waterfall enableIndicator:self ] ;
	
	[ self setInterface:lockRangeSlider to:@selector(lockParamsChanged) ] ;	
	[ self setInterface:lockOffsetSlider to:@selector(lockParamsChanged) ] ;	

	[ self setInterface:volumeSlider to:@selector(volumeChanged) ] ;	
	[ self setInterface:muteCheckbox to:@selector(volumeChanged) ] ;	
	
	[ self setInterface:equalizerCheckbox to:@selector(equalizerCheckboxChanged) ] ;	
	[ self setInterface:eq300Slider to:@selector(equalizerChanged:) ] ;	
	[ self setInterface:eq600Slider to:@selector(equalizerChanged:) ] ;	
	[ self setInterface:eq1200Slider to:@selector(equalizerChanged:) ] ;	
	[ self setInterface:eq2400Slider to:@selector(equalizerChanged:) ] ;	
	[ self setInterface:eq4800Slider to:@selector(equalizerChanged:) ] ;
	
	[ self setInterface:inputAttenuator to:@selector(inputAttenuatorChanged) ] ;
	
	demodulator = [ [ AMDemodulator alloc ] init ] ;
	[ demodulator setClient:self ] ;
	
	[ vuMeter setup ] ;
}

//  v0.87
- (void)switchModemIn
{
	//  do nothing in receive only interface
}

- (NSSlider*)inputAttenuator:(ModemConfig*)config
{
	return inputAttenuator ;
}

- (void)inputAttenuatorChanged
{
	[ [ (AMConfig*)config inputSource ] setDeviceLevel:inputAttenuator ] ;
}

- (void)equalizerChanged:(id)sender
{
	int n ;
	float value ;
	
	if ( sender == eq300Slider ) n = 300 ;
	else if ( sender == eq600Slider ) n = 600 ;
	else if ( sender == eq1200Slider ) n = 1200 ;
	else if ( sender == eq2400Slider ) n = 2400 ;
	else if ( sender == eq4800Slider ) n = 4800 ;
	else return ;
	
	value = [ sender floatValue ]*0.95 ;
	if ( value < .01 ) value = .01 ;
	value = sqrt( value ) ;
	[ demodulator setEqualizer:n value:value ] ;
}

- (void)equalizerCheckboxChanged 
{
	if ( [ equalizerCheckbox state ] == NSOnState ) {
		[ eq300Slider setEnabled:YES ] ;
		[ self equalizerChanged:eq300Slider ] ;
		[ eq600Slider setEnabled:YES ] ;
		[ self equalizerChanged:eq600Slider ] ;
		[ eq1200Slider setEnabled:YES ] ;
		[ self equalizerChanged:eq1200Slider ] ;
		[ eq2400Slider setEnabled:YES ] ;
		[ self equalizerChanged:eq2400Slider ] ;
		[ eq4800Slider setEnabled:YES ] ;
		[ self equalizerChanged:eq4800Slider ] ;
		[ demodulator setEqualizerEnable:YES ] ;
	}
	else {
		[ eq300Slider setEnabled:NO ] ;
		[ eq600Slider setEnabled:NO ] ;
		[ eq1200Slider setEnabled:NO ] ;
		[ eq2400Slider setEnabled:NO ] ;
		[ eq4800Slider setEnabled:NO ] ;
		[ demodulator setEqualizerEnable:NO ] ;
	}
}

- (void)lockParamsChanged
{
	float width, center, fc, low, high ;
	
	width = [ lockRangeSlider floatValue ]*0.5 ;
	center = [ lockOffsetSlider floatValue ] ;
	
	low = center-width ;
	high = center+width ;
	
	if ( low < -90 ) {
		low = -90 ;
		high = low+width*2 ;
		if ( high > 110 ) high = 110 ;
	}
	if ( high > 110 ) {
		high = 110 ;
		low = high - width*2 ;
		if ( low < -90 ) low = -90 ;
	}
	
	low += 200 ;
	high += 200 ;
	
	fc = [ demodulator carrier ] ;
	if ( fc < low ) fc = low ; else if ( fc > high ) fc = high ;
	
	[ waterfall setTrack:fc low:low high:high ] ;
	[ demodulator setTrack:fc low:low high:high ] ;
}

- (void)volumeChanged
{
	float slider, v ;
	
	if ( [ muteCheckbox state ] == NSOnState ) {
		v = 0.0 ;
	}
	else {
		slider = [ volumeSlider floatValue ] ;
		v = pow( 10.0, slider/20.0 )*outputScale ;
	}
	[ demodulator setVolume:v ] ;
}

- (void)setOutputScale:(float)v
{
	outputScale = v ;
	[ self volumeChanged ] ;
}

- (CMPipe*)dataClient
{
	return self ;
}

//  overide base class to change AudioPipe pipeline (assume source is normalized)
//		source 
//		. self(importData)
//			. demodulator
//				. self
//			. waterfall
//			. VU Meter

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating Synchronous AM sound source" ] ;
	//  send codec data here
	[ (AMConfig*)config setClient:(CMTappedPipe*)self ] ;
	[ (AMConfig*)config checkActive ] ;
}

//  process the new data buffer
- (void)importData:(CMPipe*)pipe
{
	if ( demodulator ) [ demodulator importData:pipe ] ;
	if ( waterfall ) [ waterfall importData:pipe ] ;
	if ( vuMeter ) [ vuMeter importData:pipe ] ;
}

- (void)setOutput:(float*)array samples:(int)n
{
	[ (AMConfig*)config setOutput:array samples:n ] ;
}

- (int)setLock:(float)delta freq:(float)f
{
	NSColor *color ;
	int state ;
	
	delta = fabs( delta ) ;
	if ( delta > 2.0 ) {
		state = 0 ;
		color = [ NSColor grayColor ] ;
	}
	else {
		 if ( delta < 1.0 ) {
			color = [ NSColor greenColor ] ; 
			state = 2 ;
		}
		else {
			color = [ NSColor yellowColor ] ;
			state = 1 ;
		}
	}
	if ( state != lockState ) {
		[ lockLight setBackgroundColor:color ] ;
		lockState = state ;
	}
	[ waterfall setTrack:f ] ;
	return lockState ;
}

- (VUMeter*)vuMeter
{
	return vuMeter ;
}

- (void)setWaterfallOffset:(float)freq sideband:(int)polarity
{
	[ waterfall setOffset:freq sideband:polarity ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ super setupDefaultPreferences:pref ] ;
	[ (AMConfig*)config setupDefaultPreferences:pref ] ;
	
	[ pref setFloat:0.0 forKey:kSynchAMLockCenter ] ;
	[ pref setFloat:50.0 forKey:kSynchAMLockRange ] ;
	[ pref setFloat:-30.0 forKey:kSynchAMVolume ] ;
	
	[ pref setFloat:0.5 forKey:kSynchAMEq300 ] ;
	[ pref setFloat:0.5 forKey:kSynchAMEq600 ] ;
	[ pref setFloat:0.5 forKey:kSynchAMEq1200 ] ;
	[ pref setFloat:0.5 forKey:kSynchAMEq2400 ] ;
	[ pref setFloat:0.5 forKey:kSynchAMEq4800 ] ;
	[ pref setInt:0 forKey:kSynchAMEqEnable ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	[ super updateFromPlist:pref ] ;
	
	[ manager showSplash:@"Updating Synchronous AM configurations" ] ;
	[ (AMConfig*)config updateFromPlist:pref ] ;
	
	[ lockOffsetSlider setFloatValue:[ pref floatValueForKey:kSynchAMLockCenter ] ] ;
	[ lockRangeSlider setFloatValue:[ pref floatValueForKey:kSynchAMLockRange ] ] ;
	[ self lockParamsChanged ] ;

	[ volumeSlider setFloatValue:[ pref floatValueForKey:kSynchAMVolume ] ] ;
	[ self volumeChanged ] ;
	
	[ eq300Slider setFloatValue:[ pref floatValueForKey:kSynchAMEq300 ] ] ;
	[ self equalizerChanged:eq300Slider ] ;
	[ eq600Slider setFloatValue:[ pref floatValueForKey:kSynchAMEq600 ] ] ;
	[ self equalizerChanged:eq600Slider ] ;
	[ eq1200Slider setFloatValue:[ pref floatValueForKey:kSynchAMEq1200 ] ] ;
	[ self equalizerChanged:eq1200Slider ] ;
	[ eq2400Slider setFloatValue:[ pref floatValueForKey:kSynchAMEq2400 ] ] ;
	[ self equalizerChanged:eq2400Slider ] ;
	[ eq4800Slider setFloatValue:[ pref floatValueForKey:kSynchAMEq4800 ] ] ;
	[ self equalizerChanged:eq4800Slider ] ;
	
	[ equalizerCheckbox setState:( [ pref intValueForKey:kSynchAMEqEnable ] == 0 ) ? NSOffState : NSOnState ] ;
	[ self equalizerCheckboxChanged ] ;
	
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	
	[ pref setFloat:[ lockOffsetSlider floatValue ] forKey:kSynchAMLockCenter ] ;
	[ pref setFloat:[ lockRangeSlider floatValue ] forKey:kSynchAMLockRange ] ;
	[ pref setFloat:[ volumeSlider floatValue ] forKey:kSynchAMVolume ] ;

	[ pref setFloat:[ eq300Slider floatValue ] forKey:kSynchAMEq300 ] ;
	[ pref setFloat:[ eq600Slider floatValue ] forKey:kSynchAMEq600 ] ;
	[ pref setFloat:[ eq1200Slider floatValue ] forKey:kSynchAMEq1200 ] ;
	[ pref setFloat:[ eq2400Slider floatValue ] forKey:kSynchAMEq2400 ] ;
	[ pref setFloat:[ eq4800Slider floatValue ] forKey:kSynchAMEq4800 ] ;
	
	[ pref setInt:( [ equalizerCheckbox state ] == NSOffState ) ? 0 : 1 forKey:kSynchAMEqEnable ] ;

	[ super retrieveForPlist:pref ] ;
	[ (AMConfig*)config retrieveForPlist:pref ] ;
}

@end
