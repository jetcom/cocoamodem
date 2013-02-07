//
//  NetSend.m
//  AUNetSend Example
//
//  Created by Kok Chen on 1/25/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "../Local Headers/NetSend.h"


@implementation NetSend

//  The way the standalone AUNetSend works is this:
//	An NSTimer process is used to call the output renderer of the AUNetSend component.
//	This in turn pulls the data from the input renderer, which is trapped by the input render callback.  The input render callback calls the client's 
//  needNetSendSamples method to fill the buffers. 

//  Callback from Core Audio to get input audio waveform data for the AUNetSend component

//  Callback from Core Audio to get audio waveform data
OSStatus netsendRenderer( void* ref, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 frames, AudioBufferList *ioData )
{
	NetAudioStruct *ns ;
	float *lbuf, *rbuf, scale, *envelope ;
	int i, n ;
	id delegate, ourself ;
	
	ns = (NetAudioStruct*)ref ;
	delegate = ns->delegate ;
	ourself = ns->netSendObj ;
	
	lbuf = ( float* )( ioData->mBuffers[0].mData ) ;
	rbuf = ( float* )( ioData->mBuffers[1].mData ) ;
	
	if ( delegate && [ delegate respondsToSelector:@selector(netSend:needSamples:left:right:) ] ) {
		[ delegate netSend:ourself needSamples:frames left:lbuf right:rbuf ] ;
		switch ( ns->runState ) {
		case kNetAudioRunning:
			return noErr ;
		case kNetAudioStarted:
			//  taper data on using raised cosine of 11ms long
			ns->runState = kNetAudioRunning ;
			n = ( frames > 512 ) ? frames : 512 ;
			envelope = &ns->raisedCosine[0] ;
			for ( i = 0; i < n; i++ ) {
				scale =  envelope[i] ;
				lbuf[i] *= scale ;
				rbuf[i] *= scale ;
			}
			return noErr ;
		case kNetAudioStopped:
			//  taper data off using raised cosine of 11ms long
			ns->runState = kNetAudioIdle ;
			n = ( frames > 512 ) ? frames : 512 ;
			envelope = &ns->raisedCosine[0] ;
			for ( i = 0; i < n; i++ ) {
				scale =  1.0 - envelope[i] ;
				lbuf[i] *= scale ;
				rbuf[i] *= scale ;
			}
			for ( ; i < frames; i++ ) lbuf[i] = rbuf[i] = 0.0 ;
			return noErr ;
		case kNetAudioIdle:
			for ( i = 0; i < frames; i++ ) lbuf[i] = rbuf[i] = 0.0 ;
			return noErr ;
		}
		return -1 ;
	}
	//  no delegate
	switch ( ns->runState ) {
	case kNetAudioRunning:
	case kNetAudioStarted:
		ns->runState = kNetAudioRunning ;
		break ;
	case kNetAudioStopped:
	case kNetAudioIdle:
		ns->runState = kNetAudioIdle ;
		break ;
	}
	for ( i = 0; i < frames; i++ ) lbuf[i] = rbuf[i] = 0.0 ;
	return noErr;
}

- (void)tick:(NSTimer*)timer
{
	AudioUnitRenderActionFlags actionFlags ;
	OSStatus status ;
	
	if ( netAudioStruct.runState == kNetAudioStopped || netAudioStruct.runState == kNetAudioIdle ) {
		[ timer invalidate ] ;
		if  ( netAudioStruct.runState == kNetAudioIdle ) return ;
	}
	if ( [ tickLock tryLock ] ) {
		//  once extra call with kNetAudioStopped
		actionFlags = 0 ;
		status = AudioUnitRender( netSendAudioUnit, &actionFlags, &timeStamp, 0, samplesPerBuffer, &bufferList ) ;
		timeStamp.mSampleTime += samplesPerBuffer ;
		[ tickLock unlock ] ;
	}
}

//  set up stream information, an AudioStreamBasicDescription
- (Boolean)setupStreamFormat:( AudioUnit )unit
{
	AudioStreamBasicDescription streamDescription ;
	UInt32 propertySize ;
	OSStatus status ;
	
	propertySize = sizeof( AudioStreamBasicDescription ) ;
	memset( &streamDescription, 0, propertySize ) ;	
	status = AudioUnitGetProperty( unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamDescription, &propertySize ) ;
	if ( status != 0 ) return NO ;	
	//  set to our paramters
	streamDescription.mBitsPerChannel = 32 ;
	streamDescription.mFramesPerPacket = 1 ;
	streamDescription.mBytesPerPacket = streamDescription.mBytesPerFrame = 4 ;
	streamDescription.mSampleRate = samplingRate ;
	streamDescription.mChannelsPerFrame = channels ;	
	status = AudioUnitSetProperty( unit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &streamDescription, propertySize ) ;
	return ( status == noErr ) ;
}

//  private API
- (Boolean)setCurrentServiceName
{
	return ( AudioUnitSetProperty( netSendAudioUnit, kAUNetSendProperty_ServiceName, kAudioUnitScope_Global, 0, &serviceName, sizeof(CFStringRef) ) == noErr ) ;
}

//  private API
//  note: cannot clear password
- (Boolean)setCurrentPassword
{
	NSString *name = ( password == nil ) ? [ NSString stringWithString:@"" ] : password ;
	return ( AudioUnitSetProperty( netSendAudioUnit, kAUNetSendProperty_Password, kAudioUnitScope_Global, 0, &name, sizeof(CFStringRef) ) == noErr ) ;
}

//  private API
- (Boolean)setCurrentPortNumber
{
	return ( AudioUnitSetProperty( netSendAudioUnit, kAUNetSendProperty_PortNum, kAudioUnitScope_Global, 0, &port, sizeof(port) ) == noErr ) ;
}

//  set the Bonjour service name for the AUNetSend component
- (Boolean)setServiceName:(NSString*)name
{
	if ( name == nil || [ name length ] < 1 ) return NO ;
	
	if ( serviceName != nil && [ name isEqualToString:serviceName ] ) return YES ;
	
	if ( serviceName != nil ) [ serviceName release ] ;
	serviceName = [ [ [ NSString alloc ] initWithString:name ] retain ] ;
	return [ self setCurrentServiceName ] ;
}

//  set password for AUNetSend component
- (Boolean)setPassword:(NSString*)name
{
	if ( password == nil && name == nil ) return YES ;
	if ( password != nil && name != nil && [ name isEqualToString:password ] ) return YES ;
	
	if ( password != nil ) [ password release ] ;
	password = ( name == nil ) ? nil : [ [ [ NSString alloc ] initWithString:name ] retain ] ;
	return [ self setCurrentPassword ] ;
}

//  set the Bonjour service name for the AUNetSend component
- (Boolean)setPortNumber:(int)number 
{
	if ( number == port ) return YES ;
	
	port = number ;
	return [ self setCurrentPortNumber ] ;
}

//  set up the format (liner 32 bit PCM) and Bonjour service name for the AUNetSend unit
- (Boolean)setupAUNetSendService
{
	UInt32 format ;
	OSStatus status ;
	
	format = kAUNetSendPresetFormat_PCMFloat32 ;
	status = AudioUnitSetProperty( netSendAudioUnit, kAUNetSendProperty_TransmissionFormatIndex, kAudioUnitScope_Global, 0, &format, sizeof(format) ) ;
	if ( status != noErr ) return status ;

	[ self setCurrentPortNumber ] ;
	[ self setCurrentServiceName ] ;
	[ self setCurrentPassword ] ;

	return [ self setupStreamFormat:netSendAudioUnit ] ;
}

- (Boolean)setupCallback
{
	AURenderCallbackStruct callback ;
	OSStatus status ;	

	//  setup input callback, passing delegate as the refcon
	callback.inputProc = netsendRenderer ;
	callback.inputProcRefCon = &netAudioStruct ;
	
	status = AudioUnitSetProperty( netSendAudioUnit, kAudioUnitProperty_SetRenderCallback, kAudioUnitScope_Input, 0, &callback, sizeof( callback ) ) ;
	return ( status == noErr ) ;
}

//  Set up an AUNetSend component and returns YES if it is set up successfully.
//  This is a private API
- (Boolean)setupNetSendUnit
{
	OSStatus status ;	
	Component component ;
	ComponentDescription desc ;
	
	desc.componentType = kAudioUnitType_Effect ;
	desc.componentSubType = kAudioUnitSubType_NetSend ;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple ;
	desc.componentFlags = 0 ;
	desc.componentFlagsMask = 0 ;
	component = FindNextComponent( nil, &desc ) ;
	if ( !component ) return NO ;
	netSendAudioUnit = nil ;
	status = OpenAComponent( component, &netSendAudioUnit ) ;
	if ( status != 0 || netSendAudioUnit == nil ) return NO ;
	
	status = AudioUnitInitialize( netSendAudioUnit ) ;
	if ( status != noErr ) return NO ;
	
	[ self setupAUNetSendService ] ;	
	[ self setupCallback ] ;
	
	return YES ;
}

- (Boolean)setupWithService:(NSString*)service delegate:(id)inDelegate samplesPerBuffer:(int)size
{
	int i ;
	
	isReceive = NO ;
	netAudioStruct.netSendObj = self ;
	netAudioStruct.delegate = inDelegate ;

	for ( i = 0; i < channels; i++ ) dataBuffer[i] = nil ;
	[ self setBufferSize:size ] ;
	
	serviceName = service ;
	password = nil ;
	port = 52800 ;
	
	//  initialize time stamp
	timeStamp.mFlags = kAudioTimeStampSampleTimeValid ;
	timeStamp.mSampleTime = 0 ;
	if ( [ self setupNetSendUnit ] == NO ) {
		[ self freeBuffers ] ;
		return NO ;
	}	
	return YES ;
}

- (Boolean)runThread
{
	NSRunLoop *runLoop ;
	
	[ NSThread setThreadPriority:1.0 ] ;
	//  start sampling if there is a delegate and an AUNetReceive has be sucessfully set up, and if we are not already ssampling
	if ( netAudioStruct.delegate == nil || !netSendAudioUnit || runTimer != nil ) return NO ;
	runTimer = [ NSTimer scheduledTimerWithTimeInterval:samplesPerBuffer/samplingRate target:self selector:@selector(tick:) userInfo:self repeats:YES ] ;
	netAudioStruct.runState = kNetAudioStarted ;
	runLoop = [ NSRunLoop currentRunLoop ] ;
	//  thread will stay running in the run loop until the timer is stopped in the tick routine
	while ( netAudioStruct.runState != kNetAudioIdle && [ runLoop runMode:NSDefaultRunLoopMode beforeDate:[ NSDate distantFuture ] ] ) ;
	[ runTimer release ] ;
	runTimer = nil ;
	[ NSThread setThreadPriority:0.25 ] ;
	return NO ;
}

- (Boolean)startSampling
{
	[ timerThreadLock unlockWithCondition:kCommandAvailable ] ;
	return YES ;
}

- (void)stopSampling
{
	//  the tick: timer routine will catch this flag and stop the timer.
	netAudioStruct.runState == kNetAudioStopped ;
}

- (id)initWithService:(NSString*)service delegate:(id)inDelegate samplesPerBuffer:(int)size
{
	self = [ super init ] ;
	if ( self ) {
		netAudioStruct.runState == kNetAudioIdle ;
		if ( [ self setupWithService:service delegate:inDelegate samplesPerBuffer:size ] == NO ) return nil ;
	}
	return self ;
}

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		netAudioStruct.runState == kNetAudioIdle ;
		if ( [ self setupWithService:@"AUNetSend" delegate:nil samplesPerBuffer:512 ] == NO ) return nil ;
	}
	return self ;
}

- (void)setDelegate:(id)delegate
{
	netAudioStruct.delegate = delegate ;
	[ self setupCallback ] ;
}

- (id)delegate
{
	return netAudioStruct.delegate ;
}

//  Delegate methods
- (void)netSend:(NetSend*)aNetSend needSamples:(int)samplesPerBuffer left:(float*)leftBuffer right:(float*)rightBuffer
{
}



@end
