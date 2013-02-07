//
//  NetReceive.m
//
//  Created by Kok Chen on 1/23/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "../Local Headers/NetReceive.h"

//  This is a Cocoa encapsulation for the AUNetReceive audio unit.
//  It uses Bonjour to connect to an AUNetSend (_apple-ausend._tcp) service.

@implementation NetReceive

//  Set up the host name and port for the AUNetReceive unit
//  also set kAUNetSendProperty_Disconnect [sic] to false, per Bill Stewart @ Apple, to autoconnect
//  if port == 0, use the default AUNetSend host name (local.:52800)
static OSStatus setupService( AudioUnit unit, const char *ip, int port )
{
	UInt32 autoconnect ;
	OSStatus status ;
	NSString *name ;
	
	if ( port != 0 ) {
		name = [ NSString stringWithFormat:@"%s:%d", ip, port ] ;		
		status = AudioUnitSetProperty( unit, kAUNetReceiveProperty_Hostname, kAudioUnitScope_Global, 0, &name, sizeof(name) ) ;	
		if ( status != noErr ) return status ;
	}
	autoconnect = 0 ;
	return AudioUnitSetProperty( unit, kAUNetSendProperty_Disconnect, kAudioUnitScope_Global, 0, &autoconnect, sizeof(UInt32) ) ;	
}

//  private API
- (Boolean)serviceChanged
{
	if ( bonjour ) [ bonjour release ] ;
	if ( netReceiveAudioUnit ) setupService( netReceiveAudioUnit, "0.0.0.0", -1 ) ;
	//  create new BonjourService
	bonjour = [ [ BonjourService alloc ] init ] ;
	if ( bonjour == nil ) return NO ;
	socket = [ bonjour registerService:serviceName ] ;
	[ socket setDelegate:self ] ;
	return YES ;
}

//  call to set AUNetSend Bonjour service name
- (Boolean)setServiceName:(NSString*)name
{
	if ( runTimer ) {
		//  first, stop any sampling process
		[ runTimer invalidate ] ;		
		runTimer = nil ;
		return NO ;
	}
	[ serviceName release ] ;
	serviceName = ( name != nil ) ? [ name retain ] : @"AUNetSend" ;
	return [ self serviceChanged ] ;
}

- (Boolean)setPassword:(NSString*)password
{
	NSString *name = ( password == nil ) ? [ NSString stringWithString:@"" ] : password ;
	return ( AudioUnitSetProperty( netReceiveAudioUnit, kAUNetReceiveProperty_Password, kAudioUnitScope_Global, 0, &name, sizeof(CFStringRef) ) == noErr ) ;
}

- (Boolean)setAddress:(const char*)ip port:(int)port
{
	if ( setupService( netReceiveAudioUnit, ip, port ) != noErr ) return NO ;
	if ( netAudioStruct.delegate && [ netAudioStruct.delegate respondsToSelector:@selector(netReceive:addressChanged:port:) ] ) [ netAudioStruct.delegate netReceive:self addressChanged:ip port:port  ] ;
	return YES ;
}

//  This is the timer process where we ask the NetReceive audio unit for data 
- (void)tick:(NSTimer*)timer
{
	AudioUnitRenderActionFlags actionFlags ;
	OSStatus status ;
	
	if ( netAudioStruct.runState != kNetAudioRunning ) {
		[ timer invalidate ] ;
		return ;
	}
	if ( [ tickLock tryLock ] ) {
		actionFlags = 0 ;
		status = AudioUnitRender( netReceiveAudioUnit, &actionFlags, &timeStamp, 0, samplesPerBuffer, &bufferList ) ;
		timeStamp.mSampleTime += samplesPerBuffer ;
		// send data to delegate
		if ( netAudioStruct.delegate && [ netAudioStruct.delegate respondsToSelector:@selector(netReceive:newSamples:left:right:) ] ) [ netAudioStruct.delegate netReceive:self newSamples:samplesPerBuffer left:dataBuffer[0] right:dataBuffer[1] ] ;
		[ tickLock unlock ] ;
	}
}

- (Boolean)runThread
{
	NSRunLoop *runLoop ;
	
	[ NSThread setThreadPriority:1.0 ] ;
	//  start sampling if there is a delegate and an AUNetReceive has be sucessfully set up, and if we are not already ssampling
	if ( netAudioStruct.delegate == nil || !netReceiveAudioUnit || runTimer != nil ) return NO ;
	runTimer = [ NSTimer scheduledTimerWithTimeInterval:samplesPerBuffer/samplingRate target:self selector:@selector(tick:) userInfo:self repeats:YES ] ;
	netAudioStruct.runState = kNetAudioRunning ;
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
	netAudioStruct.runState = kNetAudioIdle ;
}

//  Set up an AUnetReceive component and returns YES if it is set up successfully.
//  This is a private API
- (Boolean)setupNetReceiveUnit:(Boolean)useBonjour
{
	OSStatus status ;	
	Component component ;
	ComponentDescription desc ;
	
	desc.componentType = kAudioUnitType_Generator ;
	desc.componentSubType = kAudioUnitSubType_NetReceive ;
	desc.componentManufacturer = kAudioUnitManufacturer_Apple ;
	desc.componentFlags = 0 ;
	desc.componentFlagsMask = 0 ;
	component = FindNextComponent( nil, &desc ) ;
	if ( !component ) return NO ;
	netReceiveAudioUnit = nil ;
	status = OpenAComponent( component, &netReceiveAudioUnit ) ;
	if ( status != 0 || netReceiveAudioUnit == nil ) return NO ;
	
	status = AudioUnitInitialize( netReceiveAudioUnit ) ;
	if ( status != noErr ) return NO ;
	
	[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.05 ] ] ;		//  sleep for system to finish setting up before checking Bonjour
	if ( useBonjour ) [ self serviceChanged ] ;
	
	return YES ;
}

//  private API for -init and -initWithService
- (Boolean)setupWithService:(NSString*)service delegate:(id)inDelegate samplesPerBuffer:(int)size useBonjour:(Boolean)useBonjour
{
	int i ;
	
	isReceive = YES ;
	bonjour = nil ;
	socket = nil ;
	netReceiveAudioUnit = nil ;
	netAudioStruct.delegate = inDelegate ;
	
	for ( i = 0; i < channels; i++ ) dataBuffer[i] = nil ;
	[ self setBufferSize:size ] ;
	serviceName = ( service != nil ) ? service : @"AUNetSend" ;
	//  initialize time stamp
	timeStamp.mFlags = kAudioTimeStampSampleTimeValid ;
	timeStamp.mSampleTime = 0 ;
	if ( [ self setupNetReceiveUnit:useBonjour ] == NO ) {
		[ self freeBuffers ] ;
		return NO ;
	}
	return YES ;
}

- (id)initWithService:(NSString*)service delegate:(id)inDelegate samplesPerBuffer:(int)size
{
	self = [ super init ] ;
	if ( self ) {
		if ( [ self setupWithService:service delegate:inDelegate samplesPerBuffer:size useBonjour:YES ] == NO ) return nil ;
	}
	return self ;
}

- (id)initWithAddress:(const char*)ip port:(int)port delegate:(id)inDelegate samplesPerBuffer:(int)size
{
	self = [ super init ] ;
	if ( self ) {
		if ( [ self setupWithService:@"AUNetSend" delegate:inDelegate samplesPerBuffer:512 useBonjour:NO ] == NO ) return nil ;
		if ( setupService( netReceiveAudioUnit, ip, port ) != noErr ) return nil ;
		if ( netAudioStruct.delegate && [ netAudioStruct.delegate respondsToSelector:@selector(netReceive:addressChanged:port:) ] ) [ netAudioStruct.delegate netReceive:self addressChanged:ip port:port ] ;
	}
	return self ;
}

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		if ( [ self setupWithService:@"AUNetSend" delegate:nil samplesPerBuffer:512 useBonjour:YES ] == NO ) return nil ;
	}
	return self ;
}

//  Delegate of BonjourSocket
//
//  Found the Bonjour port that corresponds to the AUNetReceive component.
//  Fetch the IP and port number and set the AUNetReceive hostname.
- (void)bonjourNetReceiveConnect:(BonjourSocket*)inSocket
{
	if ( netReceiveAudioUnit ) setupService( netReceiveAudioUnit, [ inSocket ip ], [ inSocket port ] ) ;
	if ( netAudioStruct.delegate && [ netAudioStruct.delegate respondsToSelector:@selector(netReceive:addressChanged:port:) ] ) [ netAudioStruct.delegate netReceive:self addressChanged:[ inSocket ip ] port:[ socket port ]  ] ;
}

//  Delegate of BonjourSocket
//
//  Bonjour port disconnected.
- (void)bonjourNetReceiveDisconnect:(BonjourSocket*)inSocket
{
	[ self stopSampling ] ;
	if ( netAudioStruct.delegate && [ netAudioStruct.delegate respondsToSelector:@selector(netReceive:disconnectedFromAddress:port:) ] ) [ netAudioStruct.delegate netReceive:self disconnectedFromAddress:[ inSocket ip ] port:[ socket port ] ] ;
}

- (const char*)ip
{
	if ( socket ) return [ socket ip ] ;
	return "" ;
}

- (int)port
{
	if ( socket ) return [ socket port ] ;
	return 0 ;
}

//  Delegate methods
- (void)netReceive:(NetReceive*)aNetReceive newSamples:(int)samplesPerBuffer left:(const float*)leftBuffer right:(const float*)rightBuffer
{
}

- (void)netReceive:(NetReceive*)aNetReceive addressChanged:(const char*)address port:(int)port
{
}

- (void)netReceive:(NetReceive*)aNetReceive disconnectedFromAddress:(const char*)address port:(int)port
{
}

@end
