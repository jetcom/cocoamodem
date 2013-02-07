//
//  ModemSource.m
//  cocoaModem
//
//  Adapted from PrototypeSource.m on Jul 29 2004
//  Created by Kok Chen on Wed May 26 2004.
	#include "Copyright.h"
//

#import "ModemSource.h"
#import "AIFFSource.h"
#import "Application.h"
#import "AudioManager.h"
#import "Config.h"
#import "Messages.h"
#import "ModemConfig.h"
#import "TextEncoding.h"
#import "Plist.h"

@implementation ModemSource

//  The ModemSource is an CMPipe source.
//  ModemSource gets waveform data from two places, a CoreAudio soundcard or an AIFF/WAV file (AIFFSource)

//  This function receives calls from the CoreAudio when a buffer is received from the device.
//	Data is written into the ResamplingPipe for resampling to 11025 s/s
//
//  NOTE: samples must be multiples of 512
//	In the current implementation of buffer sizes, 256 stereo samples are received per deviceInputProc call.


- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

//  init ModemSource and sets the interface controls into the given view
//  file extra are controls for substituting a file for the sound source (set extra to nil if not needed)
//
//  Device States
#define DISABLED	0		// caused by enableInput:NO
#define ENABLED		1		// caused by enableInput:YES
#define RUNNING		2		// caused by started and ENABLED

- (id)initIntoView:(NSView*)view device:(NSString*)name fileExtra:(NSView*)extra playbackSpeed:(int)speed channel:(int)ch client:(CMPipe*)client
{
	self = [ super init ] ;
	if ( self ) {
		channel = ch ;
		isInput = YES ;
		delegate = nil ;
		started = hasReadThread = NO ;
		
		resamplingPipe = [ [ ResamplingPipe alloc ] initWithSamplingRate:11025.0 channels:2 ] ;	// v0.90 set to 2 channels always
		[ resamplingPipe setInputSamplingRate:11025.0 ] ;
		[ resamplingPipe setOutputSamplingRate:11025.0 ] ;

		//  insert an AIFFSource in between us and the client so AIFF files can be inserted
		sourcePipe = [ [ AIFFSource alloc ] pipeWithClient:client ] ;
		[ sourcePipe setSamplingRate:CMFs ] ;
		[ self setClient:sourcePipe ] ;
		
		playbackSpeed = speed ;
		periodic = YES ;
		soundFileTimer = nil ;
		deviceState = DISABLED ;
		dbSlider = nil ;
		deviceName = [ [ NSString alloc ] initWithString:name ] ;
		if ( [ NSBundle loadNibNamed:@"ModemSource" owner:self ] ) {
			
			//  set up connections for super class
			soundCardMenu = inputMenu ;
			sourceMenu = inputSourceMenu ;
			samplingRateMenu = inputSamplingRateMenu ;
			channelMenu = inputChannel ;
			paramString = inputParam ;
			
			// loadNib should have set up controlView connections
			if ( view && controlView ) [ view addSubview:controlView ] ;
			if ( extra && fileView ) [ extra addSubview:fileView ] ;
			// actions
			[ self setInterface:inputMenu to:@selector(inputMenuChanged) ] ;
			[ self setInterface:inputSourceMenu to:@selector(sourceMenuChanged) ] ;
			[ self setInterface:inputChannel to:@selector(channelChanged) ] ;
			[ self setInterface:inputSamplingRateMenu to:@selector(samplingRateChanged) ] ;
			if ( ch > 1 ) {
				//  stereo, don't show channel selection
				[ inputChannel setHidden:YES ] ;
			}
			return self ;
		}
	}
	return nil ;
}

- (void)setPeriodic:(Boolean)state
{
	periodic = state ;
	if ( state == NO && soundFileTimer ) {
		[ soundFileTimer invalidate ] ;
		soundFileTimer = nil ;
	}
}

- (void)setFileRepeat:(Boolean)doRepeat
{
	[ sourcePipe setFileRepeat:doRepeat ] ;
}

- (void)registerInputPad:(NSTextField*)pad
{
	dbPad = pad ;
}

//	(Private API)
//  this routine is called periodically by NSTimer, simulating the importData from AudioHubChannel
//  everytime this routine is called, it submits the next 512 sound samples to the appropriate AudioPipe
- (void)nextMonoSoundFileFrame:(NSTimer*)timer
{
	ModemSource *p ;
	int offset, stride ;
		
	if ( outputClient == nil ) {
		[ timer invalidate ] ;
		NSLog( @"mono output client missing for ModemSource\n" ) ;
		return ;
	}
	p = (ModemSource*)[ timer userInfo ] ;
	p->data->samples = 512 ;
	
	stride = [ sourcePipe soundFileStride ] ;
	//  if file is mono, fetch left (mono) channel even if right channel is requested
	offset = ( p->channel != RIGHTCHANNEL /* LEFTCHANNEL or BOTHCHANNEL */ || stride <= 1 ) ? 0 : 1 ;

	//  the following causes the sourcePipe to export data to this object (importData:)
	if ( [ sourcePipe insertNextFileFrameWithOffset:offset ] ) [ timer invalidate ] ;
}

//	(Private API)
//  this routine is called periodically by NSTimer, simulating the importData from AudioHubChannel
//  everytime this routine is called, it submits the next 512 stereo sound samples to the client AudioPipes
- (void)nextStereoSoundFileFrame:(NSTimer*)timer
{
	ModemSource *p ;
		
	if ( outputClient == nil ) {
		[ timer invalidate ] ;
		return ;
	}
	p = (ModemSource*)[ timer userInfo ] ;
	p->data->samples = 512 ;
	
	if ( [ sourcePipe insertNextStereoFileFrame ] ) [ timer invalidate ] ;	
}

//  hasNewData for 11025 samples/second.  Assume number of samples are BUFLEN (512) in size
//  Also change the LRLRLR stream to a LLLLL...RRRRRR stream for stereo channel.
- (void)hasNew11025Data:(float*)inbuf
{
	int i ;
	
	//  check if device return only a single channel
	if ( channels == 1 ) {
		//  v0.93 mono channel from ResamplingPipe is copied into split stereo channels
		for ( i = 0; i < 512; i++ ) {	
			clientBuffer[i] = clientBuffer[i+512] = inbuf[i] ;
		}
	}
	else {
		//  the base channel is the even channel of a stereo pair of channels
		//  for a stereo device, baseChannel is 0.
		inbuf += baseChannel ;
		//  copy the two channels of data
		for ( i = 0; i < 512; i++ ) {			
			clientBuffer[i] = inbuf[0] ;
			clientBuffer[i+512] = inbuf[1] ;
			inbuf += channels ;
		}
	}
	//  update our (CMTappedPipe) data source info
	data->samplingRate = 11025.0 ;
	data->array = &clientBuffer[channel*512] ;
	data->samples = 512 ;
	data->components = 1 ;
	data->channels = 1 ;

	[ sourcePipe importData:self offset:0 ] ;
	if ( tapClient ) [ tapClient importData:self ] ;
}

//  v0.57b reduce autorelease flush from 3000 cycles (1 minute) to 500 cycles
//	this used to feed hasNewData of the AudioInput port.
//  It is blocked waiting for data from the AudioConverter
- (void)readThread:(id)client
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
		
	while ( [ resamplingPipe eof ] == NO ) {
		//  NOTE: uses decimation even when input sampling rate 11025 s/s
		//	This gives the system more sound card buffering.
	
		[ resamplingPipe readResampledData:resampledBuffer samples:512 ] ;
		
		[ self hasNew11025Data:resampledBuffer ] ;

		#ifdef NODRAIN
		//  v0.80 no longer drain since there is no leak, and was not stable in Leopard
		//  memory management of readThread
		//  periodically create a new Autorelease pool, so that auto release memory can be cleared
		//	in Tiger and Leopard, drain the autorelease pool 
		if ( cycle++ > 1001 ) {
			if ( delayedRelease ) {
				
				//  delay actual release of the old pool by one lap time to allow AudioConverter to completely drain.
				//	as a result, we will use about twice the amount of real memory for the thread.
				
				//	don't drain pool in Snow Leopard
				SInt32 systemVersion = 0 ;
				Gestalt( gestaltSystemVersionMinor, &systemVersion ) ;
				if ( systemVersion < 6 /* before snow leopard */ ) {
					//[ delayedRelease release ] ;		// v0.57b changed to drain, back to release
				}
				delayedRelease = nil ;
			}
			cycle = 0 ;
			delayedRelease = pool ;
			pool = [ [ NSAutoreleasePool alloc ] init ] ;
		}
		#endif
	}	
	//  mark so that next time we need a ReadThread, it is recreated
	hasReadThread = NO ;

	[ pool release ] ;
	[ NSThread exit ] ;
}

//	start input sound card
- (Boolean)startSoundCard
{
	UInt32 datasize ;
	AudioStreamBasicDescription asbd, psbd ;
	
	datasize = sizeof( AudioStreamBasicDescription ) ;
	asbd.mChannelsPerFrame = 2 ;
    AudioStreamGetProperty( selectedSoundCard->streamID, 0, kAudioDevicePropertyStreamFormat, &datasize, &asbd ) ;
	[ resamplingPipe setNumberOfChannels:asbd.mChannelsPerFrame ] ;
	
	
	datasize = sizeof( AudioStreamBasicDescription ) ;
	psbd.mChannelsPerFrame = 2 ;
    AudioStreamGetProperty( selectedSoundCard->streamID, 0, kAudioStreamPropertyPhysicalFormat, &datasize, &psbd ) ;

	//  0.93d  don't change channels/bits, but just report it
	[ paramString setStringValue:[ NSString stringWithFormat:@"%d ch/%d", (int)asbd.mChannelsPerFrame, (int)psbd.mBitsPerChannel ] ] ;
		
	if ( selectedSoundCard == nil ) return NO ;			//  sanity check
	if ( isSampling == YES ) return YES ;				//  already running
	
	if ( audioManager == nil ) {
		audioManager = [ [ NSApp delegate ] audioManager ] ;
		if ( audioManager == nil ) return NO ;
	}
	[ startStopLock lock ] ;							//  wait for any previous start/stop to complete
	if ( hasReadThread == NO ) {
		//  create read thread only when needed
		[ NSThread detachNewThreadSelector:@selector(readThread:) toTarget:self withObject:self ] ;
		hasReadThread = YES ;
	}
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
	//  Switch the resampling pipe to convert data into.
	//	Output (to modem) if ResamplingPipe stays at 11025 s/s.
	[ resamplingPipe setInputSamplingRate:rate ] ;
}

//	(Private API)
- (void)turnSamplingOn:(Boolean)state
{
	if ( selectedSoundCard == nil ) return ;
	
	if ( state == YES ) {
		if ( isSampling == NO ) {
			//  first set sampling rate and source, in case we came here from a different modem interface
			[ self samplingRateChanged ] ;
			[ self sourceMenuChanged ] ;		
			[ self startSoundCard ] ; 
		}
	}
	else {
		if ( isSampling == YES ) [ self stopSoundCard ] ;
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
			if ( [ sourcePipe soundFileActive ] == NO && started == YES ) {
				[ self turnSamplingOn:YES ] ;
				action = turnedOn ;
			}
		}
		break ;
	case ENABLED:
		if ( newState == ENABLED ) {
			//  normal start/stop sampling (while device is enabled)
			if ( [ sourcePipe soundFileActive ] == NO && started == YES ) {
				[ self turnSamplingOn:YES ] ;
				action = turnedOn ;
			}
			if ( started == NO ) {
				[ self turnSamplingOn:NO ] ;
				action = turnedOff ;
			}
		}
		else {
			deviceState = newState ;
		}
		break ;
	case RUNNING:
		if ( [ sourcePipe soundFileActive ] == YES ) {
			[ self turnSamplingOn:NO ] ;
			action = turnedOff ;
			break ;
		}
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
	if ( deviceState == ENABLED && started == YES && [ sourcePipe soundFileActive ] == NO ) {
		if ( action != turnedOn ) [ self turnSamplingOn:YES ] ;
		return ;
	}
	//  added v0.21
	if ( deviceState == DISABLED && [ sourcePipe soundFileActive ] == NO ) {
		if ( action != turnedOff ) [ self turnSamplingOn:NO ] ;
		return ;
	}
	if ( deviceState == RUNNING && [ sourcePipe soundFileActive ] == YES ) {
		if ( action != turnedOff ) [ self turnSamplingOn:NO ] ;
		return ;
	}
}

- (void)fileSpeedChanged:(int)newSpeed
{
	playbackSpeed = newSpeed ;
}

- (void)registerDeviceSlider:(NSSlider*)slider
{
	dbSlider = slider ;
}

//	Note: source level is in db
- (void)setDeviceLevel:(NSSlider*)slider
{
	dbSlider = slider ;
	[ self setDeviceLevelFromSlider ] ;
}

- (void)setPadLevel:(NSTextField*)pad 
{
	dbPad = pad ;
	[ self setDeviceLevelFromSlider ] ;
}

//	(Private API)
- (void)startSoundFile:(NSString*)filename
{
	float t ;
	
	if ( [ sourcePipe soundFileActive ] ) {
		[ self soundFileStarting:filename ] ;
		data->array = nil ;
		data->samplingRate = [ sourcePipe samplingRate ] ;
		data->components = [ sourcePipe soundFileStride ] ;
		data->channels = 2 ;
		//  assume 512 samples at ( 11025 samples per second * playbackSpeed )
		t = 512.0/( data->samplingRate*playbackSpeed ) ;

		switch ( channel ) {
		default:
		case LEFTCHANNEL:
		case RIGHTCHANNEL:
			soundFileTimer = [ NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(nextMonoSoundFileFrame:) userInfo:self repeats:periodic ] ;
			break ;
		case 2:
			soundFileTimer = [ NSTimer scheduledTimerWithTimeInterval:t target:self selector:@selector(nextStereoSoundFileFrame:) userInfo:self repeats:periodic ] ;
			break ;
		}
		if ( !periodic ) soundFileTimer = nil ;
	}
}

//  get the next sound file frame in 1 ms
- (void)nextSoundFrame
{
	if ( !periodic && [ sourcePipe soundFileActive ] == YES ) {
		switch ( channel ) {
		default:
		case LEFTCHANNEL:
		case RIGHTCHANNEL:
			[ NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(nextMonoSoundFileFrame:) userInfo:self repeats:periodic ] ;
			break ;
		case 2:
			[ NSTimer scheduledTimerWithTimeInterval:0.001 target:self selector:@selector(nextStereoSoundFileFrame:) userInfo:self repeats:periodic ] ;
			break ;
		}
	}
}

//  pass pipe to destinations
- (void)importData:(CMPipe*)inPipe
{
	[ sourcePipe importData:inPipe offset:channel&0x1 ] ;		// v0.50 multichannel -- map channel to 0 or 1
	if ( tapClient ) [ tapClient importData:inPipe ] ;
}

/* local */
- (void)stopSoundFile
{
	if ( soundFileTimer ) {
		[ soundFileTimer invalidate ] ;
		soundFileTimer = nil ;
	}
	[ sourcePipe stopSoundFile ] ;
	[ self changeDeviceStateTo:deviceState ] ;  // update state
	[ self soundFileStopped ] ;
}

- (void)startSampling
{
	started = YES ;
	[ self changeDeviceStateTo:deviceState ] ;  // update state
}

- (void)enableInput:(Boolean)enable
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

//  new audio input device selected
- (void)inputMenuChanged
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

- (IBAction)openFile:(id)sender
{
	NSArray *fileTypes ;
	NSString *path ;
	
	if ( soundFileTimer ) {
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
		return ;
	}
	[ self stopSampling ] ;
	fileTypes = [ NSArray arrayWithObjects:@"aif", @"aiff", @"wav", nil ] ; 
	
	path = [ sourcePipe openSoundFileWithTypes:fileTypes ] ;
	if ( path ) {
		//  if soundFile.active, starts the timer fired sound file data, if not, the A/D converter is restarted 
		if ( [ sourcePipe soundFileActive ] ) {
			[ self startSoundFile:path ] ; 
		}
	}
	[ self startSampling ] ;
}

- (Boolean)fileRunning
{
	return [ sourcePipe soundFileActive ] ;
}

- (IBAction)stopFile:(id)sender
{
	[ self stopSoundFile ] ;
	if ( !soundFileTimer ) {
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
		return ;
	}
	[ self changeDeviceStateTo:deviceState ] ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setString:@"*" forKey:[ deviceName stringByAppendingString:kInputName ] ] ;
	[ pref setString:@"*" forKey:[ deviceName stringByAppendingString:kInputSource ] ] ;
	[ pref setString:@"11025" forKey:[ deviceName stringByAppendingString:kInputSamplingRate ] ] ;
	[ pref setInt:channel forKey:[ deviceName stringByAppendingString:kInputChannel ] ] ;
	[ pref setFloat:0.0 forKey:[ deviceName stringByAppendingString:kInputPad ] ] ;
	[ pref setFloat:0.0 forKey:[ deviceName stringByAppendingString:kInputSlider ] ] ;
}

//  set up this ModemSource from settings in the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	Boolean ok ;
	NSString *name ;
	int sourceIndex, selectedDeviceIndex ;
	float pad, slider ;

	//  make sure there is at least one usable item
	if ( [ inputMenu numberOfItems ] < 1 ) return NO ;

	ok = YES ;
	sourceIndex = 0 ;
	//  get input sound card name from Plist
	name = [ pref stringValueForKey:[ deviceName stringByAppendingString:kInputName ] ] ;
	
	//  try to select it from the sound card menu
	selectedDeviceIndex = [ self selectSoundCard:name ] ;
	if ( selectedDeviceIndex < 0 ) {
		//  name in Plist no longer found
		ok = NO ;
		channel = 0 ;
		if ( [ inputMenu numberOfItems ] > 0 ) [ inputMenu selectItemAtIndex:0 ] ;
		if ( [ inputSourceMenu numberOfItems ] > 0 ) [ inputSourceMenu selectItemAtIndex:0 ] ;		// v0.52
	}
	else {
		//  sound card choosen, -selectSoundCard should also have set up the source menu
		//  now try to select the input source if there is more than one
		if ( [ inputSourceMenu numberOfItems ] > 1 ) {
			name = [ pref stringValueForKey:[ deviceName stringByAppendingString:kInputSource ] ] ;
			sourceIndex = [ self selectSource:name ] ;
			if ( sourceIndex < 0 ) {
				ok = NO ;
				[ inputSourceMenu selectItemAtIndex:0 ] ;
			}
		}
		//  select channel
		channel = [ pref intValueForKey:[ deviceName stringByAppendingString:kInputChannel ] ] ;
		[ self selectChannel:channel ] ;
	}
	
	// v0.52 sanity check channel
	int menuItems =  [ inputChannel numberOfItems ] ;
	if ( channel >= 0 && channel < menuItems ) // 0.52
		[ inputChannel selectItemAtIndex:channel ] ;		// v0.50 allow multi-channel

	//  setup input pad
	pad = [ pref floatValueForKey:[ deviceName stringByAppendingString:kInputPad ] ] ;
	if ( dbPad ) {
		[ dbPad setStringValue:[ NSString stringWithFormat:@"%d", (int)pad ] ] ;
		[ Messages logMessage:"Updating input pad to %d from plist", (int)pad ] ;
	}
	
	NSString *key = [ deviceName stringByAppendingString:kInputSlider ] ;
	slider = [ pref floatValueForKey:key ] ;
	
	if ( dbSlider != nil ) {
		[ dbSlider setFloatValue:slider ] ;
		[ Messages logMessage:"Updating input attenuator to %.1f from plist", slider ] ;
	}
	[ self setDeviceLevelFromSlider ] ;

	if ( selectedSoundCard != nil ) {
		if ( audioManager == nil || [ audioManager audioDeviceForID:selectedSoundCard->deviceID ] == nil ) {
			// 0.53a sampling rate option
			NSString *rateString = [ pref stringValueForKey:[ deviceName stringByAppendingString:kInputSamplingRate ] ] ;
			[ Messages logMessage:"Updating input sampling rate %s from plist", [ rateString cStringUsingEncoding:kTextEncoding ] ] ;		//  v0.62
			if ( rateString ) [ inputSamplingRateMenu selectItemWithTitle:rateString ] ;
			[ self samplingRateChanged ] ;			//  v0.62
		}
		[ self fetchSamplingRateFromCoreAudio ] ;	//  v0.78 this forces the AudioConverter rates to be set and also when device is already registered
	}
	return ok ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	NSString *selectedTitle ;
	
	[ pref setString:[ inputMenu titleOfSelectedItem ] forKey:[ deviceName stringByAppendingString:kInputName ] ] ;
	[ pref setString:[ inputSourceMenu titleOfSelectedItem ] forKey:[ deviceName stringByAppendingString:kInputSource ] ] ;
	[ pref setInt:channel forKey:[ deviceName stringByAppendingString:kInputChannel ] ] ;
	
	selectedTitle = [ inputSamplingRateMenu titleOfSelectedItem ] ;
	if ( selectedTitle ) [ pref setString:selectedTitle forKey:[ deviceName stringByAppendingString:kInputSamplingRate ] ] ;
	
	//  retrieve pad value from device (AudioInputPort, AudioSoundChannel)
	if ( dbPad ) [ pref setFloat:[ dbPad floatValue ] forKey:[ deviceName stringByAppendingString:kInputPad ] ] ;
	if ( dbSlider ) [ pref setFloat:[ dbSlider floatValue ] forKey:[ deviceName stringByAppendingString:kInputSlider ] ] ;
}

- (id)delegate
{
	return delegate ;
}

- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate ;
}

// delegate method
- (void)soundFileStarting:(NSString*)filename
{
	if ( delegate && [ delegate respondsToSelector:@selector(soundFileStarting:) ] ) [ delegate soundFileStarting:filename ] ;
}

//  delegate method
- (void)soundFileStopped
{
	if ( delegate && [ delegate respondsToSelector:@selector(soundFileStopped) ] ) [ delegate soundFileStopped ] ;
}

- (void)dealloc
{
	[ deviceName release ] ;
	[ sourcePipe release ] ;
	[ super dealloc ] ;
}

@end
