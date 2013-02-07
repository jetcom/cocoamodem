//
//  AudioManager.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/5/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "AudioManager.h"
#import "Messages.h"

//  AudioDeviceStart and AudioDeviceStop does not allow the same AudioDeviceIOProc to be used more than once per AudioDeviceID.
//	Different modeminterfaces that uses the same device can therefore not subclass off the same base class that uses the same AudioDeviceIOProc.
//	AudioManager handles all AudioDeviceIOProc callbacks and issue AudioDeviceStart/AudioDeviceStop and demux the data from the different modems.
//	AudioManager also handles system device changes and forward the information to the clients of a device.

//  forward references
static OSStatus deviceListenerProc( AudioDeviceID inDeviceID, UInt32 channel, Boolean isInput, AudioDevicePropertyID property, void *client ) ;


@implementation AudioManager

//	Return RegisteredAudioDevice of AudioDeviceID, or nil, if device not registered.
- (RegisteredAudioDevice*)audioDeviceForID:(AudioDeviceID)devID
{
	int i ;
	
	if ( devID < 2048 && cachedDevice[devID] != nil && cachedDevice[devID]->deviceID == devID ) return cachedDevice[devID] ;
	
	// out of cache range, check each registered deviceID
	for ( i = 0; i < registeredAudioDevices; i++ ) {
		if ( registeredAudioDevice[i]->deviceID == devID ) return registeredAudioDevice[i] ;
	}
	return nil ;
}

//	A Core Audio input request comes to this (deviceInputProc) callback.
//	This then calls the modemSource(s) that are linked to the deviceID

static OSStatus deviceInputProc( AudioDeviceID devID, const AudioTimeStamp* now, const AudioBufferList* input, 
                       const AudioTimeStamp* time, AudioBufferList* unused, const AudioTimeStamp* inOutputTime, 
                       void* user )
{
	int i, activeClients ;
	ModemAudio **clientList ;
	RegisteredAudioDevice *audioDevice ;
	ModemAudio *activeModemAudio[256] ;
	NSAutoreleasePool *pool ;
	
	pool = [ [ NSAutoreleasePool alloc ] init ] ;	
	audioDevice = [ (AudioManager*)user audioDeviceForID:devID ] ;
	if ( audioDevice != nil ) {
	
		//  lock and copy current ModemSources registered to receive data from the DeviceID
		[ audioDevice->lock lock ] ;
		activeClients = audioDevice->activeInputClients ;
		clientList = &audioDevice->activeInputModemAudio[0] ;
		for ( i = 0; i < activeClients; i++ ) activeModemAudio[i] = clientList[i] ;
		[ audioDevice->lock unlock ] ;
		
		//  now submit data to the list of ModemSources (ModemAudio)
		for ( i = 0; i < activeClients; i++ ) {
			[ activeModemAudio[i] inputArrivedFrom:devID bufferList:input ] ;
		}
	}
	[ pool release ] ;
    return 0 ;
}

//	A Core Audio output request comes to this (deviceOutputProc) callback.

static OSStatus deviceOutputProc( AudioDeviceID devID, const AudioTimeStamp* now, const AudioBufferList* unused, 
                       const AudioTimeStamp* time, AudioBufferList* output, const AudioTimeStamp* outputTime, 
                       void* user )
{
	int i, activeClients ;
	ModemAudio **clientList ;
	RegisteredAudioDevice *audioDevice ;
	ModemAudio *activeModemAudio[256] ;
	NSAutoreleasePool *pool ;
	
	pool = [ [ NSAutoreleasePool alloc ] init ] ;	
	audioDevice = [ (AudioManager*)user audioDeviceForID:devID ] ;
	if ( audioDevice != nil ) {
	
		//  lock and copy current ModemSources registered to receive data from the DeviceID
		[ audioDevice->lock lock ] ;
		activeClients = audioDevice->activeOutputClients ;
		clientList = &audioDevice->activeOutputModemAudio[0] ;
		for ( i = 0; i < activeClients; i++ ) activeModemAudio[i] = clientList[i] ;
		[ audioDevice->lock unlock ] ;
		
		//  now fetch (accumulate) data from the list of ModemSources (ModemAudio)
		for ( i = 0; i < activeClients; i++ ) {
			[ activeModemAudio[i] accumulateOutputFor:devID bufferList:output accumulate:( i != 0 ) ] ;
		}
	}
	[ pool release ] ;
     return 0 ;
}

//	(Private API)
- (void)removePropertyListenerFor:(RegisteredAudioDevice*)audioDevice
{
	OSStatus status ;

	if ( audioDevice == nil ) return ;
	
	status = AudioDeviceRemovePropertyListener( audioDevice->deviceID, /*master*/0, kAudioPropertyWildcardSection, kAudioPropertyWildcardPropertyID, deviceListenerProc ) ;
	audioDevice->propertyListenerProc = nil ;
}

//	(Private API)
- (void)addPropertyListenerFor:(RegisteredAudioDevice*)audioDevice
{
	OSStatus status ;
	
	if ( audioDevice == nil ) return ;
	
	if ( audioDevice->propertyListenerProc != nil ) [ self removePropertyListenerFor:audioDevice ] ;

	status = AudioDeviceAddPropertyListener( audioDevice->deviceID, /*master*/0, kAudioPropertyWildcardSection, kAudioPropertyWildcardPropertyID, deviceListenerProc, self ) ;
	audioDevice->propertyListenerProc = (AudioDevicePropertyListenerProc*)deviceListenerProc ;
}

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		registeredAudioDevices = 0 ;
		for ( i = 0; i < 2048; i++ ) cachedDevice[i] = nil ;
	}
	return self ;
}

- (void)dealloc
{
	int i ;
	RegisteredAudioDevice *cachedAudioDevice ;
	
	for ( i = 0; i < registeredAudioDevices; i++ ) {
		cachedAudioDevice = registeredAudioDevice[i] ;
		if ( cachedAudioDevice->activeInputClients > 0 ) AudioDeviceStop( cachedAudioDevice->deviceID, deviceInputProc ) ;
		if ( cachedAudioDevice->activeOutputClients > 0 ) AudioDeviceStop( cachedAudioDevice->deviceID, deviceOutputProc ) ;
		AudioDeviceRemoveIOProc( cachedAudioDevice->deviceID, deviceInputProc ) ;
		AudioDeviceRemoveIOProc( cachedAudioDevice->deviceID, deviceOutputProc ) ;
		if ( cachedAudioDevice->propertyListenerProc != nil ) [ self removePropertyListenerFor:cachedAudioDevice ] ;
		[ cachedAudioDevice->lock release ] ;
		free( cachedAudioDevice ) ;
	}
	[ super dealloc ] ;
}

//	(Private API)
- (void)addClient:(ModemAudio*)client toDevice:(RegisteredAudioDevice*)dev list:(ModemAudio**)list listSize:(int*)count
{
	int i, inCount ;

	inCount = *count ;
	if ( inCount >= 256 ) {
		NSLog( @"AudioManager -addClient: too many clients?" ) ;
		return ;
	}

	//  check if client is already in the list
	for ( i = 0; i < inCount; i++ ) {
		if ( list[i] == client ) {
			NSLog( @"AudioManager -addClient: client already active?" ) ;
			return ;
		}
	}
	[ dev->lock lock ] ;
	list[inCount] = client ;
	*count = inCount+1 ;
	[ dev->lock unlock ] ;
}

//	(Private API)
- (void)removeClient:(ModemAudio*)client fromDevice:(RegisteredAudioDevice*)dev list:(ModemAudio**)list listSize:(int*)count
{
	int i, j, inCount ;

	inCount = *count ;
	//  look for the client in the active list
	for ( i = 0; i < inCount; i++ ) {
		if ( list[i] == client ) {
			//  found the entry to remove
			[ dev->lock lock ] ;
			inCount-- ;
			*count = ( inCount < 0 ) ? 0 : inCount ;
			for ( j = i; j < inCount; j++ ) list[j] = list[j+1] ;
			[ dev->lock unlock ] ;
			return ;
		}
	}
	NSLog( @"AudioManager -removeInputClient: client not found in active list?" ) ;
}

- (int)getDeviceInfo:(AudioDeviceID)devID streams:(DeviceStream*)streams isInput:(Boolean)isInput
{
	int i, j, n, m ;
	UInt32 datasize ;
	OSStatus status ;
	AudioBufferList audioBufferList ;
	AudioBuffer *audioBuffer ;
	DeviceStream *stream ;
	
	n = 0 ;
	datasize = 0 ;
	status = AudioDeviceGetPropertyInfo( devID, 0, isInput, kAudioDevicePropertyStreamConfiguration, &datasize, NULL ) ;
	if ( status == 0 && datasize == sizeof( AudioBufferList ) ) {
		status = AudioDeviceGetProperty( devID, 0, isInput, kAudioDevicePropertyStreamConfiguration, &datasize, &audioBufferList ) ;
		if ( status == 0 ) {
			//  limit to MAXSTREAMS
			n = audioBufferList.mNumberBuffers ;
			if ( n > 16 ) n = MAXSTREAMS ; 
			for ( i = 0; i < n; i++ ) {
				stream = &streams[i] ;
				audioBuffer = &audioBufferList.mBuffers[i] ;
				m = audioBuffer->mNumberChannels ;
				if ( m > MAXCHANNELS ) m = MAXCHANNELS ;
				stream->channels = m ;
				//  first check if there is a master control
				datasize = sizeof( AudioValueRange ) ;
				status = AudioDeviceGetProperty( devID, 0, isInput, kAudioDevicePropertyVolumeRangeDecibels, &datasize, &stream->channelInfo[0].dbRange ) ;
				stream->hasMasterControl = ( status == 0 ) ;
				
				if ( stream->hasMasterControl == NO ) {
					for ( j = 0; j < m; j++ ) {
						datasize = sizeof( AudioValueRange ) ;
						status = AudioDeviceGetProperty( devID, j+1, isInput, kAudioDevicePropertyVolumeRangeDecibels, &datasize, &stream->channelInfo[j].dbRange ) ;
						if ( status != 0 ) stream->channelInfo[j].dbRange.mMinimum = stream->channelInfo[j].dbRange.mMaximum = 0.0 ;
					}
				}
			}
		}
	}
	return n ;
}

- (RegisteredAudioDevice*)registeredAudioDeviceForID:(AudioDeviceID)devID
{
	RegisteredAudioDevice *audioDevice ;
	
	audioDevice = [ self audioDeviceForID:devID ] ;
	if ( audioDevice != nil ) return audioDevice ;
	
	//  device not yet registered, create a RegisteredAudioDevice struct
	audioDevice = (RegisteredAudioDevice*)malloc( sizeof(RegisteredAudioDevice) ) ;
	audioDevice->deviceID = devID ;
	audioDevice->inputClients = audioDevice->outputClients = 0 ;
	audioDevice->activeInputClients = audioDevice->activeOutputClients = 0 ;
	audioDevice->lock = [ [ NSLock alloc ] init ] ;
	audioDevice->propertyListenerProc = nil ;
	[ self addPropertyListenerFor:audioDevice ] ;
	
	audioDevice->inputStreams = [ self getDeviceInfo:devID streams:&audioDevice->inputStream[0] isInput:YES ] ;

	audioDevice->outputStreams = [ self getDeviceInfo:devID streams:&audioDevice->outputStream[0] isInput:NO ] ;

	registeredAudioDevice[registeredAudioDevices++] = audioDevice ;
	if ( devID < 2048 ) cachedDevice[devID] = audioDevice ;	
	//  now add CoreAudio procs for this device
	AudioDeviceAddIOProc( devID, deviceInputProc, self ) ;
	AudioDeviceAddIOProc( devID, deviceOutputProc, self ) ;
	
	return audioDevice ;
}

- (float)sliderValueForDeviceID:(AudioDeviceID)devID isInput:(Boolean)isInput channel:(int)channel
{
	RegisteredAudioDevice *audioDevice ;
	DeviceStream *stream ;
	Float32 db ;
	UInt32 datasize ;
	OSStatus status ;
	int streams ;

	audioDevice = [ self audioDeviceForID:devID ] ;
	if ( audioDevice == nil ) return NODBVALUE ;
	
	//  device had been in use, fetch the kAudioDevicePropertyVolumeDecibels
	
	if ( isInput == YES ) {
		streams = audioDevice->inputStreams ;
		stream = &audioDevice->inputStream[0] ;
	}
	else {
		streams = audioDevice->outputStreams ;
		stream = &audioDevice->outputStream[0] ;
	}
	if ( streams <= 0 ) return NODBVALUE ;
	
	//  use stream[0] for now
	datasize = sizeof( Float32 ) ;
	if ( stream->hasMasterControl ) {
		status = AudioDeviceGetProperty( devID, 0, isInput, kAudioDevicePropertyVolumeDecibels, &datasize, &db ) ;
	}
	else {
		status = AudioDeviceGetProperty( devID, channel+1, isInput, kAudioDevicePropertyVolumeDecibels, &datasize, &db ) ;
	}
	if ( status != noErr ) return NODBVALUE ; 
	return db ;
}

- (void)audioDeviceRegister:(AudioDeviceID)devID modemAudio:(ModemAudio*)client
{
	Boolean isInputClient ;
	RegisteredAudioDevice *dev ;
	
	isInputClient = [ client isInput ] ;
	dev = [ self registeredAudioDeviceForID:devID ] ;
	
	if ( isInputClient == YES ) {
		[ self addClient:client toDevice:dev list:&dev->inputModemAudio[0] listSize:&dev->inputClients ] ;
	}
	else {
		[ self addClient:client toDevice:dev list:&dev->outputModemAudio[0] listSize:&dev->outputClients ] ;
	}
}

- (void)audioDeviceUnregister:(AudioDeviceID)devID modemAudio:(ModemAudio*)client
{
	Boolean isInputClient ;
	RegisteredAudioDevice *dev ;
	
	isInputClient = [ client isInput ] ;
	dev = [ self registeredAudioDeviceForID:devID ] ;
	
	if ( isInputClient ) {
		[ self removeClient:client fromDevice:dev list:&dev->inputModemAudio[0] listSize:&dev->inputClients ] ;
	}
	else {
		[ self removeClient:client fromDevice:dev list:&dev->outputModemAudio[0] listSize:&dev->outputClients ] ;
	}
}

- (OSStatus)audioDeviceStart:(AudioDeviceID)devID modemAudio:(ModemAudio*)client
{
	OSStatus status ;
	Boolean isRunning, isInputClient ;
	RegisteredAudioDevice *dev ;
	
	isInputClient = [ client isInput ] ;
	dev = [ self registeredAudioDeviceForID:devID ] ;
	
	if ( isInputClient == YES ) {
		isRunning = ( dev->activeInputClients > 0 ) ;
		[ self addClient:client toDevice:dev list:&dev->activeInputModemAudio[0] listSize:&dev->activeInputClients ] ;
		//  return if device is already running
		if ( isRunning ) return 0 ;
		status = AudioDeviceStart( dev->deviceID, deviceInputProc ) ;
	}
	else {
		isRunning = ( dev->activeOutputClients > 0 ) ;
		[ self addClient:client toDevice:dev list:&dev->activeOutputModemAudio[0] listSize:&dev->activeOutputClients ] ;
		//  return if device is already running
		if ( isRunning ) return 0 ;
		status = AudioDeviceStart( dev->deviceID, deviceOutputProc ) ;
	}
	return status ;
}

- (OSStatus)audioDeviceStop:(AudioDeviceID)devID modemAudio:(ModemAudio*)client
{
	OSStatus status ;
	Boolean isRunning, isInputClient ;
	RegisteredAudioDevice *dev ;
	
	isInputClient = [ client isInput ] ;
	dev = [ self registeredAudioDeviceForID:devID ] ;
	
	if ( isInputClient ) {
		isRunning = ( dev->activeInputClients > 0 ) ;
		[ self removeClient:client fromDevice:dev list:&dev->activeInputModemAudio[0] listSize:&dev->activeInputClients ] ;
		//  after removal, do we still have active devices?
		//	if so, or it was already stopped, just return
		if ( dev->activeInputClients > 0 || isRunning == NO ) return 0 ;	
		//  otherwise, stop the device
		status = AudioDeviceStop( dev->deviceID, deviceInputProc ) ;
	}
	else {
		isRunning = ( dev->activeOutputClients > 0 ) ;
		[ self removeClient:client fromDevice:dev list:&dev->activeOutputModemAudio[0] listSize:&dev->activeOutputClients ] ;
		//  after removal, do we still have active devices?
		//	if so, or it was already stopped, just return
		if ( dev->activeOutputClients > 0 || isRunning == NO ) return 0 ;
		status = AudioDeviceStop( dev->deviceID, deviceOutputProc ) ;
	}
	return status ;
}

- (void)putCodecsToSleep
{
	int i ;
	RegisteredAudioDevice *cachedID ;

	//  check list of sound cards and stop any one that is running	
	for ( i = 0; i < registeredAudioDevices; i++ ) {
		cachedID = registeredAudioDevice[i] ;
		if ( cachedID->activeInputClients > 0 ) AudioDeviceStop( cachedID->deviceID, deviceInputProc ) ;
		if ( cachedID->activeOutputClients > 0 ) AudioDeviceStop( cachedID->deviceID, deviceOutputProc ) ;
	}
}

- (void)wakeCodecsUp
{
	int i ;
	RegisteredAudioDevice *cachedID ;

	//  check list of sound cards and start any one that should be running
	for ( i = 0; i < registeredAudioDevices; i++ ) {
		cachedID = registeredAudioDevice[i] ;
		if ( cachedID->activeInputClients > 0 ) AudioDeviceStart( cachedID->deviceID, deviceInputProc ) ;
		if ( cachedID->activeOutputClients > 0 ) AudioDeviceStart( cachedID->deviceID, deviceOutputProc ) ;
	}
}

//  get all modems that are registered even if they are not active
- (int)getRegisteredModemAudioListFor:(AudioDeviceID)deviceID isInput:(Boolean)isInput modemAudioList:(ModemAudio***)audioList ;
{
	int n ;
	RegisteredAudioDevice *audioDevice ;
	
	audioDevice = [ self audioDeviceForID:deviceID ] ;
	if ( audioDevice == nil ) return 0 ;		//  no one has the deviceID registered
	
	if ( isInput ) {
		n = audioDevice->inputClients ;
		if ( audioList != nil ) *audioList = audioDevice->inputModemAudio ;
	}
	else {
		n = audioDevice->outputClients ;
		if ( audioList != nil ) *audioList = audioDevice->outputModemAudio ;
	}
	return n ;
}


- (int)getModemAudioListFor:(AudioDeviceID)deviceID isInput:(Boolean)isInput modemAudioList:(ModemAudio***)audioList ;
{
	int n ;
	RegisteredAudioDevice *audioDevice ;
	
	audioDevice = [ self audioDeviceForID:deviceID ] ;
	if ( audioDevice == nil ) return 0 ;		//  no one has the deviceID registered
	
	if ( isInput ) {
		n = audioDevice->activeInputClients ;
		if ( audioList != nil ) *audioList = audioDevice->activeInputModemAudio ;
	}
	else {
		n = audioDevice->activeOutputClients ;
		if ( audioList != nil ) *audioList = audioDevice->activeOutputModemAudio ;
	}
	return n ;
}

//	(Private API)
- (void)muted:(AudioDeviceID)deviceID isInput:(Boolean)isInput
{
	int n ;
	
	n = [ self getModemAudioListFor:deviceID isInput:isInput modemAudioList:nil ] ;
	if ( n > 0 ) [ Messages alertWithMessageText:@"Warning: Another application has muted a sound card used by cocoaModem" informativeText:@"" ] ;
}

//	(Private API)
- (void)sourceChanged:(AudioDeviceID)deviceID isInput:(Boolean)isInput
{
	int i, n ;
	ModemAudio **audioList ;
	
	n = [ self getRegisteredModemAudioListFor:deviceID isInput:isInput modemAudioList:&audioList ] ;
	//  ask all ModemAudio with this AudioDeviceID to update their sources
	for ( i = 0; i < n; i++ ) [ audioList[i] fetchSourceFromCoreAudio ] ;
}

//	(Private API)
- (void)samplingRateChanged:(AudioDeviceID)deviceID isInput:(Boolean)isInput
{
	int i, n ;
	ModemAudio **audioList ;
	
	n = [ self getRegisteredModemAudioListFor:deviceID isInput:isInput modemAudioList:&audioList ] ;
	//  ask all ModemAudio with this AudioDeviceID to update their sources
	for ( i = 0; i < n; i++ ) {
		[ audioList[i] fetchSamplingRateFromCoreAudio ] ;
	}
}


//	(Private API)
- (void)audioLevelChanged:(AudioDeviceID)deviceID isInput:(Boolean)isInput
{
	int i, n ;
	ModemAudio **audioList ;
	
	n = [ self getRegisteredModemAudioListFor:deviceID isInput:isInput modemAudioList:&audioList ] ;
	//  ask all ModemAudio with this AudioDeviceID to update their sources
	for ( i = 0; i < n; i++ ) [ audioList[i] fetchDeviceLevelFromCoreAudio ] ;
}

//  AudioDeviceListenerProc for all registered devices end up here
static OSStatus deviceListenerProc( AudioDeviceID inDeviceID, UInt32 channel, Boolean isInput, AudioDevicePropertyID property, void *selfp )
{
	if ( property == 0 ) return 0 ;
	
	//  NOTE: when device sampling rate changes, the following can return (in this order)
	//	kAudioStreamPropertyPhysicalFormat						'pft '
	//	kAudioStreamPropertyVirtualFormat						'sfmt'
	//	kAudioDevicePropertyNominalSampleRate					'nsrt'
	//	kAudioDevicePropertyLatency								'ltnc'
	//	kAudioDevicePropertySafetyOffset						'saft'
	//	kAudioDevicePropertyDeviceIsRunningSomewhere			'gone'
	
	//  NOTE: when volume changes, the foillowing are returned
	//  kAudioDevicePropertyVolumeScalar						'volm'		(not always from Audio MIDI Setup)
    //  kAudioDevicePropertyVolumeDecibels						'vold'		(not always from Audio MIDI Setup)
	//	kAudioHardwareServiceDeviceProperty_VirtualMasterVolume	'vmvc'		defined in AudioToolbox/AudioServices.h
	//	AudioHardwareServiceDeviceProperty_VirtualMasterBalance	'vmbc'		defined in AudioToolbox/AudioServices.h

	//  NOTE: when source changes, the following are returned
	//  kAudioDevicePropertyDeviceHasChanged					'diff'
	//	kAudioDevicePropertyDataSource							'ssrc'
	
	//	NOTE: when bits/channels changes,
	//	kAudioStreamPropertyPhysicalFormat						'pft '
	//  kAudioDevicePropertyAvailableNominalSampleRates			'nsr#'
	//	kAudioStreamPropertyVirtualFormat						'sfmt'
	//	kAudioDevicePropertyStreamConfiguration					'slay'
	
	//	NOTE: when mute changes,
	//	kAudioDevicePropertyMute								'mute'
	
	//	NOTE: when sampling starts,
	//  kAudioDevicePropertyDeviceIsRunningSomewhere			'gone' 
    //	kAudioDevicePropertyDeviceIsRunning						'goin'

	//	NOTE: when sampling stops,
    //	kAudioDevicePropertyDeviceIsRunning						'goin'
	//  kAudioDevicePropertyDeviceIsRunningSomewhere			'gone' 
 

	switch ( property ) {
	case kAudioDevicePropertyMute:
		[ (AudioManager*)selfp muted:inDeviceID isInput:isInput ] ;
		return 0 ;
	case kAudioDevicePropertyDataSource:
		[ (AudioManager*)selfp sourceChanged:inDeviceID isInput:isInput ] ;
		return 0 ;
	case kAudioDevicePropertyNominalSampleRate:
		[ (AudioManager*)selfp samplingRateChanged:inDeviceID isInput:isInput ] ;
		return 0 ;
	case kAudioDevicePropertyVolumeDecibels:
	case 'vmvc':
		[ (AudioManager*)selfp audioLevelChanged:inDeviceID isInput:isInput ] ;
		return 0 ;
	}
	
	if ( 0 ) {
		char *s = (char*)&property ;
		NSLog( @"---- AudioManager:deviceListenerProc %c%c%c%c deviceID = %d isInput %d\n", s[3], s[2], s[1], s[0], (int)inDeviceID, isInput ) ;
	}
	return 0 ;
}

@end
