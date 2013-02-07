//
//  ModemDest.m
//  cocoaModem
//
//  Created by Kok Chen on Sun Aug 01 2004.
	#include "Copyright.h"
//

#import "ModemDest.h"
#import "Application.h"
#import "AudioManager.h"
#import "Config.h"
#import "DestClient.h"
#import "Modem.h"
#import "ModemConfig.h"
#import "ModemManager.h"
#import "Messages.h"
#import "Plist.h"
#import "PTT.h"
#import "PTTHub.h"
#import "TextEncoding.h"
#include <math.h>

@implementation ModemDest

//  As a AudioPipe destination, this object is accessed through the the importData: method


- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

//  Init Modem sound destination and sets the interface controls into the given view
//  The client must provide a target with methods 
//
//  - (int)needData:(float*)outbuf samples:(int)n			//  returns 2 if stereo output, 1 for mono output
//  - (void)enableDestinationStream:(Boolean)enable
//  - (void)setOutputScale:(float)value ;

- (id)initIntoView:(NSView*)view device:(NSString*)name level:(NSView*)level client:(DestClient*)inClient pttHub:(PTTHub*)hub
{
	self = [ super init ] ;
	if ( self ) {
		initRate = initCh = initBits = 0 ;
		deviceState = DISABLED ;
		isInput = NO ;
		mostRecentlyUsedDevice = @"" ;
		rateChangeBusy = NO ;
		client = inClient ;
		outputLevelKey = nil ;
			
		resamplingPipeChannels = 1 ;
		resamplingPipe = [ [ ResamplingPipe alloc ] initUnbufferedPipeWithSamplingRate:11025.0 channels:resamplingPipeChannels target:self ] ;
		[ resamplingPipe setInputSamplingRate:11025.0 ] ;
		[ resamplingPipe setOutputSamplingRate:11025.0 ] ;

		deviceName = [ [ NSString alloc ] initWithString:name ] ;
		if ( [ NSBundle loadNibNamed:( hub != nil ) ? @"ModemDest" : @"SimpleModemDest" owner:self ] ) {	
			// loadNib should have set up controlView connectionw
			if ( controlView && view ) {
			
				//  set up connections for super class
				soundCardMenu = outputMenu ;
				sourceMenu = outputDestMenu ;
				samplingRateMenu = outputSamplingRateMenu ;
				channelMenu = outputChannel ;
				paramString = outputParam ;

				[ view addSubview:controlView ] ;
				if ( level && levelView ) [ level addSubview:levelView ] ;
				// PTT menu
				ptt = ( hub ) ? [ [ PTT alloc ] initWithHub:hub menu:pttMenu ] : nil ;
				//  actions
				[ self setInterface:outputMenu to:@selector(outputMenuChanged) ] ;
				[ self setInterface:outputLevel to:@selector(outputLevelChanged) ] ;
				[ self setInterface:outputAttenuator to:@selector(updateAttenuator) ] ;
				[ self setInterface:outputDestMenu to:@selector(sourceMenuChanged) ] ;
				[ self setInterface:outputChannel to:@selector(channelChanged) ] ;
				[ self setInterface:outputSamplingRateMenu to:@selector(samplingRateChanged) ] ;
				
				return self ;
			}
		}
	}
	return nil ;
}

- (id)initIntoView:(NSView*)view device:(NSString*)name level:(NSView*)level client:(DestClient*)inClient channels:(int)ch
{
	self = [ super init ] ;
	if ( self ) {
		initRate = initCh = initBits = 0 ;
		deviceState = DISABLED ;
		isInput = outputMuted = NO ;
		mostRecentlyUsedDevice = @"" ;
		rateChangeBusy = NO ;
		client = inClient ;
		outputLevelKey = nil ;
			
		resamplingPipeChannels = ch ;
		resamplingPipe = [ [ ResamplingPipe alloc ] initUnbufferedPipeWithSamplingRate:11025.0 channels:resamplingPipeChannels target:self ] ;
		[ resamplingPipe setInputSamplingRate:11025.0 ] ;
		[ resamplingPipe setOutputSamplingRate:11025.0 ] ;

		deviceName = [ [ NSString alloc ] initWithString:name ] ;
		
		if ( [ NSBundle loadNibNamed:@"SimpleModemDest" owner:self ] ) {	
			// loadNib should have set up controlView connectionw
			if ( controlView && view ) {
			
				//  set up connections for super class
				soundCardMenu = outputMenu ;
				sourceMenu = outputDestMenu ;
				samplingRateMenu = outputSamplingRateMenu ;
				channelMenu = outputChannel ;
				paramString = outputParam ;

				[ view addSubview:controlView ] ;
				if ( level && levelView ) [ level addSubview:levelView ] ;
				// PTT menu
				ptt = nil ;
				//  actions
				[ self setInterface:outputMenu to:@selector(outputMenuChanged) ] ;
				[ self setInterface:outputLevel to:@selector(outputLevelChanged) ] ;
				[ self setInterface:outputAttenuator to:@selector(updateAttenuator) ] ;
				[ self setInterface:outputDestMenu to:@selector(sourceMenuChanged) ] ;
				[ self setInterface:outputChannel to:@selector(channelChanged) ] ;
				[ self setInterface:outputSamplingRateMenu to:@selector(samplingRateChanged) ] ;
				
				return self ;
			}
		}
	}
	return nil ;
}

- (void)setMute:(Boolean)state
{
	outputMuted = state ;
}

- (PTT*)ptt
{
	return ptt ;
}

//	start input sound card
- (Boolean)startSoundCard
{
	if ( selectedSoundCard == nil ) return NO ;			//  sanity check
	if ( isSampling == YES ) return YES ;				//  already running
	
	if ( audioManager == nil ) {
		audioManager = [ [ NSApp delegate ] audioManager ] ;
		if ( audioManager == nil ) return NO ;
	}
	[ startStopLock lock ] ;							//  wait for any previous start/stop to complete
	[ resamplingPipe makeNewRateConverter ] ;
	isSampling = ( [ audioManager audioDeviceStart:selectedSoundCard->deviceID modemAudio:self ] == 0 ) ;
	[ startStopLock unlock ] ;
	
	return ( isSampling == YES ) ;
}

//	start input sound card
- (Boolean)stopSoundCard
{
	if ( selectedSoundCard == nil ) return NO ;			//  sanity check
	if ( isSampling == NO ) return YES ;

	if ( audioManager == nil ) {
		audioManager = [ [ NSApp delegate ] audioManager ] ;
		if ( audioManager == nil ) return NO ;
	}
	[ startStopLock lock ] ;
	isSampling = ( [ audioManager audioDeviceStop:selectedSoundCard->deviceID modemAudio:self ] != 0 ) ;
	[ startStopLock unlock ] ;
	
	return ( isSampling == NO ) ;
}

- (void)actualSamplingRateSetTo:(float)rate
{
	//  Switch the resampling pipe.
	//	Input (from modem) of the ResamplingPipe stays at 11025 s/s.
	[ resamplingPipe setOutputSamplingRate:rate ] ;
}

//	(Private API)
- (void)turnSamplingOn:(Boolean)state
{
	if ( state == YES ) {
		if ( isSampling == NO ) {
			//  first set sampling rate and source, in case we came here from a different modem interface
			[ self samplingRateChanged ] ;			
			[ self sourceMenuChanged ] ;
			[ self startSoundCard ] ;
		}
	}
	else {
		if ( isSampling == YES ) [ self stopSoundCard ] ;		//  stop sound card only if it is running
	}
}


#define	doNothing	0
#define	turnedOn	1
#define	turnedOff	2

- (void)changeDeviceStateTo:(int)newState
{
	int action = doNothing ;

	switch ( deviceState ) {
	case DISABLED:
		if ( newState == ENABLED ) {
			deviceState = ENABLED ;
			if ( started ) {
				[ self turnSamplingOn:YES ] ;
				action = turnedOn ;
			}
		}
		break ;
	case ENABLED:
		if ( newState == ENABLED ) {
			if ( started == YES ) {
				[ self turnSamplingOn:YES ] ;
				action = turnedOn ;
			}
			else {
				[ self turnSamplingOn:NO ] ;
				action = turnedOff ;
			}
		}
		else {
			deviceState = newState ;
		}
		break ;
	case RUNNING:
		if ( newState == DISABLED ) {
			[ self turnSamplingOn:NO ] ;
			action = turnedOff ;
			deviceState = DISABLED ;
			break ;
		}
		if ( started == NO ) {
			[ self turnSamplingOn:NO ] ;
			action = turnedOff ;
			deviceState = ENABLED ;
			break ;
		}
		break ;
	}
	if ( deviceState == ENABLED && started == YES ) {
		if ( action != turnedOn ) [ self turnSamplingOn:YES ] ;
		return ;
	}
}

- (void)startSampling
{
	started = YES ;
	[ self changeDeviceStateTo:deviceState ] ;  // update state
}

- (void)enableOutput:(Boolean)enable
{
	int newState ;
	
	newState = deviceState ;
	
	if ( enable ) {
		if ( deviceState == DISABLED ) newState = ENABLED ;
	}
	else {
		newState = DISABLED ;
	}
	[ self changeDeviceStateTo:newState ] ;
}

- (void)stopSampling
{
	started = NO ;
	[ self changeDeviceStateTo:deviceState ] ;  // update state
}

//  set output sound level key for preference
- (void)setSoundLevelKey:(NSString*)key attenuatorKey:(NSString*)attenuator
{
	if ( outputLevelKey ) [ outputLevelKey release ] ;
	outputLevelKey = [ [ NSString alloc ] initWithString:key ] ;

	if ( attenuatorKey ) [ attenuatorKey release ] ;
	attenuatorKey = [ [ NSString alloc ] initWithString:attenuator ] ;
}

- (void)updateAttenuator
{
	float value, dB ;
	
	dB = [ outputAttenuator floatValue ] ;
	//value = 0.707*pow( 10.0, dB/20.0 ) ;			// -3.0 dB FS peak
	//value = 0.8414*pow( 10.0, dB/20.0 ) ;			// -1.5 dB FS peak
	value = 0.8913*pow( 10.0, dB/20.0 ) ;			// v0.88 -1.5 dB FS peak instead of -3 dB (note: RTTY filter needs 6% headroom)
	[ client setOutputScale:value ] ;
}


//  v0.76 -- toggle device's sampling state if the output device changes while being active
- (void)changeToNewOutputDevice:(int)index destination:(int)dest refreshSamplingRateMenu:(Boolean)refreshSamplingRateMenu
{
	Boolean wasRunning = isSampling ;
	NSString *newDeviceName = [ [ outputMenu selectedItem ] title ] ;

	if ( wasRunning == YES ) {
		//  stop sampling before switching devices
		[ self stopSampling ] ;
	}	
	if ( [ mostRecentlyUsedDevice isEqualToString:newDeviceName ] == NO ) {
		[ mostRecentlyUsedDevice release ] ;
		mostRecentlyUsedDevice = [ newDeviceName retain ] ;
	}
	if ( wasRunning == YES ) {
		//  resume sampling
		[ self startSampling ] ;
	}
}

//  new audio output device selected
- (void)outputMenuChanged
{
	Boolean wasSampling = NO ;
	
	//  if the device is running. Turn sampling off first
	if ( isSampling ) {
		wasSampling = YES ;
		[ self stopSampling ] ;
	}	
	[ self changeDeviceStateTo:DISABLED ] ;
	[ super soundCardChanged ] ;
	[ self changeDeviceStateTo:ENABLED ] ;
	
	//  resume sampling if we switch while sampling.
	if ( wasSampling ) [ self startSampling ] ;
}

//  output level control changed
//	Note: slider is a scalar value between 0.1 and 1.0 (min = 0 in Core Audio and max = 1)
- (void)outputLevelChanged
{
	scalarSlider = outputLevel ;
	[ self setDeviceLevelFromSlider ] ;
}

//	used by AMConfig and CWMonitor
- (NSSlider*)outputLevel 
{
	return outputLevel ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	float level, attenuator ;
	
	[ pref setString:@"*" forKey:[ deviceName stringByAppendingString:kOutputName ] ] ;
	[ pref setString:@"*" forKey:[ deviceName stringByAppendingString:kOutputSource ] ] ;
	[ pref setString:@"11025" forKey:[ deviceName stringByAppendingString:kOutputSamplingRate ] ] ;
	[ pref setString:@"VOX" forKey:[ deviceName stringByAppendingString:kPTTMenu ] ] ;
	[ pref setInt:0 forKey:[ deviceName stringByAppendingString:kOutputChannel ] ] ;
	level = 0.0 ;
	if ( outputLevel ) level = [ outputLevel floatValue ] ;
	if ( outputLevelKey ) [ pref setFloat:level forKey:outputLevelKey ] ;

	attenuator = 0.0 ;
	if ( outputAttenuator ) attenuator = [ outputAttenuator floatValue ] ;
	if ( attenuatorKey ) [ pref setFloat:attenuator forKey:attenuatorKey ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref updateAudioLevel:(Boolean)updateLevel
{
	Boolean ok ;
	NSString *name, *menuName, *key ;
	float level ;
	int i, destItems, selectedDeviceIndex, sourceIndex ;
	//  make sure there is at least one usable item
	if ( [ outputMenu numberOfItems ] < 1 ) return NO ;
	
	ok = YES ;
	sourceIndex = 0 ;
	//  choose output device from Plist and set up other menus
	name = [ pref stringValueForKey:[ deviceName stringByAppendingString:kOutputName ] ] ;
	
	//  try to select it from the sound card menu
	selectedDeviceIndex = [ self selectSoundCard:name ] ;
	if ( selectedDeviceIndex < 0 ) {
		//  name in Plist no longer found
		ok = NO ;
		channel = 0 ;
		if ( [ outputMenu numberOfItems ] > 0 ) [ outputMenu selectItemAtIndex:0 ] ;
		if ( [ outputDestMenu numberOfItems ] > 0 ) [ outputDestMenu selectItemAtIndex:0 ] ;
	}
	else {		
		//  sound card choosen, -selectSoundCard should also have set up the source menu
		//  now try to select the input source if there is more than one
		if ( [ outputDestMenu numberOfItems ] > 1 ) {
			name = [ pref stringValueForKey:[ deviceName stringByAppendingString:kOutputSource ] ] ;
			sourceIndex = [ self selectSource:name ] ;
			if ( sourceIndex < 0 ) {
				ok = NO ;
				//  could not find source?  Find alternate mappings
				// "Internal speakers" and "Headphones" are interchangable for built-in audio
				destItems = [ outputDestMenu numberOfItems ] ;
				for ( i = 0; i < destItems; i++ ) {
					menuName = [ [ outputDestMenu itemAtIndex:i ] title ] ;
					if ( [ name isEqualToString:@"Internal speakers" ] && [ menuName isEqualToString:@"Headphones" ] ) break ;
					if ( [ name isEqualToString:@"Headphones" ] && [ menuName isEqualToString:@"Internal speakers" ] ) break ;
				}
				if ( i < destItems ) ok = YES ; else i = 0 ;
				[ outputDestMenu selectItemAtIndex:i ] ;
			}
		}
		//  select channel
		channel = [ pref intValueForKey:[ deviceName stringByAppendingString:kOutputChannel ] ] ;
		[ self selectChannel:channel ] ;
	}

	if ( updateLevel == YES ) {
		if ( outputLevel && outputLevelKey ) {
			level = [ pref floatValueForKey:outputLevelKey ] ;
			[ outputLevel setFloatValue:level ] ;
			[ self outputLevelChanged ] ;
			[ Messages logMessage:"%s set to %.3f", [ outputLevelKey cStringUsingEncoding:kTextEncoding ], level ] ;
		}
	}
	else {
		[ self fetchDeviceLevelFromCoreAudio ] ;
	}
	if ( outputAttenuator && attenuatorKey ) {
		level = [ pref floatValueForKey:attenuatorKey ] ;
		[ outputAttenuator setFloatValue:level ] ;
		[ Messages logMessage:"%s set to %.0f dB", [ attenuatorKey cStringUsingEncoding:kTextEncoding ], level ] ;
		[ self updateAttenuator ] ;
	}
	if ( ptt ) {
		NSString *key = [ deviceName stringByAppendingString:kPTTMenu ] ;
		[ ptt selectItem:[ pref stringValueForKey:key ] ] ;
	}
	if ( selectedSoundCard != nil ) {
		// 0.53a sampling rate option
		if ( audioManager == nil || [ audioManager audioDeviceForID:selectedSoundCard->deviceID ] == nil ) {
			key = [ deviceName stringByAppendingString:kOutputSamplingRate ] ;
			name = [ pref stringValueForKey:key ] ;
			if ( name ) {
				[ outputSamplingRateMenu selectItemWithTitle:name ] ;
				[ Messages logMessage:"Updating output sampling rate %s from plist", [ name cStringUsingEncoding:kTextEncoding ] ] ;		//  v0.62
				[ self samplingRateChanged ] ;				//  v0.53b get the rate into the modem
			}
		}
		[ self fetchSamplingRateFromCoreAudio ] ;	//  v0.78 this forces the AudioConverter rates to be set and also when device is already registered
	}
	mostRecentlyUsedDevice = [ [ outputMenu titleOfSelectedItem ] retain ] ;
	return ok ;
}

//  set up this SoundHub from settings in the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	return [ self updateFromPlist:pref updateAudioLevel:YES ] ;
}

//   v0.86
- (void)retrieveForPlist:(Preferences*)pref updateAudioLevel:(Boolean)updateLevel
{
	float level, scalarLevel ;
	NSString *selectedTitle ;
	
	//  v 0.85 reset audio level just in case it was set to OOK
	//  v 0.86 don;t update aural channel
	if ( updateLevel ) scalarLevel = [ self validateDeviceLevel ] ;
	
	if ( ptt ) [ pref setString:[ ptt selectedItem ] forKey:[ deviceName stringByAppendingString:kPTTMenu ] ] ;
	[ pref setString:[ outputMenu titleOfSelectedItem ] forKey:[ deviceName stringByAppendingString:kOutputName ] ] ;
	[ pref setString:[ outputDestMenu titleOfSelectedItem ] forKey:[ deviceName stringByAppendingString:kOutputSource ] ] ;
	[ pref setInt:channel forKey:[ deviceName stringByAppendingString:kOutputChannel ] ] ;
	
	selectedTitle = [ outputSamplingRateMenu titleOfSelectedItem ] ;
	if ( selectedTitle ) [ pref setString:selectedTitle forKey:[ deviceName stringByAppendingString:kOutputSamplingRate ] ] ;

	if ( outputLevel && outputLevelKey ) {
		//level = [ outputLevel floatValue ] ;
		[ pref setFloat:scalarLevel forKey:outputLevelKey ] ;		//  v0.85
	}
	if ( outputAttenuator && attenuatorKey ) {
		level = [ outputAttenuator floatValue ] ;
		[ pref setFloat:level forKey:attenuatorKey ] ;
	}
}

- (void)retrieveForPlist:(Preferences*)pref
{
	[ self retrieveForPlist:(Preferences*)pref updateAudioLevel:YES ] ;
}

//  AudioOutputPort callbacks -- ask client for data
//  needData should return 1 for mono buffer. 2 for stereo buffer.
- (int)needData:(float*)outbuf samples:(int)n channels:(int)ch
{
	return [ client needData:outbuf samples:n ] ;
}

//  delegate for destination panel
- (BOOL)windowShouldClose:(id)sender
{
	return YES ;
}

@end
