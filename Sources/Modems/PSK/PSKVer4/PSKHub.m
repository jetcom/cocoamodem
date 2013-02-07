//
//  PSKHub.m
//  cocoaModem 2.0  v0.57b
//
//  Created by Kok Chen on 10/18/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "PSKHub.h"
#import "PSK.h"
#import "PSKDemodulator.h"
#import "PSKReceiver.h"
#import "Waterfall.h"
#import <AudioUnit/AudioUnitProperties.h>

#define	REMOVECOUNT		6		// defer removal from LitPSKDemodulator list (in case of QSB)

@implementation PSKHub

//  local
//  set up AudioConverter to resample from 11025 to 8000 samples per second
- (void)setupResampler
{
	AudioStreamBasicDescription basicDescription, outDescription ;
	OSStatus status ;
	
	basicDescription.mSampleRate = 11025 ;
	basicDescription.mFormatID = kAudioFormatLinearPCM ;
	basicDescription.mFormatFlags = kLinearPCMFormatFlagIsFloat ;
	#if __BIG_ENDIAN__
	basicDescription.mFormatFlags |= kLinearPCMFormatFlagIsBigEndian ;
	#endif
	basicDescription.mFramesPerPacket = 1 ;										
	basicDescription.mChannelsPerFrame = 1 ;
	basicDescription.mBytesPerFrame = 4 * basicDescription.mChannelsPerFrame ;
	basicDescription.mBytesPerPacket = 4 * basicDescription.mChannelsPerFrame ;
	basicDescription.mBitsPerChannel = 32 ;

	outDescription = basicDescription ;
	outDescription.mSampleRate = 8000 ;

	//  create a SamplerateConverter for this read thread
	status = AudioConverterNew( &basicDescription, &outDescription, &rateConverter ) ;
	//  set up as high quality rate converter	
	UInt32 quality = kAudioConverterQuality_Max ;
	AudioConverterSetProperty( rateConverter, kAudioConverterSampleRateConverterQuality, sizeof( UInt32 ), &quality ) ;
	//  create a pipe for the input data and read thread to pull the resampled data
	[ NSThread detachNewThreadSelector:@selector(readThread:) toTarget:self withObject:self ] ;
}

- (id)initHub
{	
	self = [ super init ] ;
	if ( self ) {
		poolBusy = [ [ NSLock alloc ] init ] ;
		pskDemodulatorLock = [ [ NSLock alloc ] init ] ;
		dataPipe = [ [ DataPipe alloc ] initWithCapacity:2048*sizeof(float) ] ;
		[ self setupResampler ] ;		
		receiver = nil ;
		hasBrowser = NO ;
		enabled = NO ;
		
		//  main demodulator
		mainDemodulator = [ [ PSKDemodulator alloc ] init ] ;
		[ mainDemodulator setDelegate:self ] ;
	}
	return self ;
}

- (void)dealloc
{
	AudioConverterReset( rateConverter ) ;
	AudioConverterDispose( rateConverter ) ;
	[ dataPipe release ] ;
	[ pskDemodulatorLock release ] ;
	[ poolBusy release ] ;
	
	[ super dealloc ] ;
}

- (void)setPSKModem:(PSK*)modem index:(int)index
{
	if ( mainDemodulator ) [ mainDemodulator setPSKModem:modem index:index ] ;
}

//  callback only used by PSKBrowserHub
- (void)newFFTBuffer:(float*)inSpectrum
{
}

- (Boolean)demodulatorEnabled
{
	return [ mainDemodulator isEnabled ] ;
}

- (void)enableReceiver:(Boolean)state
{
	enabled = state ;
	[ mainDemodulator enableReceiver:state ] ;
}

//  wait for demodulator to go completely quiescent before releasing it
- (void)delayedRelease:(NSTimer*)timer
{
	LitePSKDemodulator *u ;
	
	u = [ timer userInfo ] ;
	[ u release ] ;
}


- (void)setReceiveFrequency:(float)tone
{
	[ mainDemodulator setReceiveFrequency:tone ] ;
}

- (void)setPSKMode:(int)mode
{
	[ mainDemodulator setPSKMode:mode ] ;
}

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall
{
	[ mainDemodulator selectFrequency:freq fromWaterfall:fromWaterfall ] ;
}

- (float)receiveFrequency
{
	return [ mainDemodulator receiveFrequency ] ;
}

- (void)setDelegate:(PSKReceiver*)delegate
{
	receiver = delegate ;
	[ mainDemodulator setDelegate:receiver ] ;
}

//  New resampled data buffer (at 8000 s/s) arrives.
- (void)sendBufferToDemodulators:(float*)buffer samples:(int)samples
{	
	assert( samples == 512 ) ;
	[ mainDemodulator newDataBuffer:buffer samples:samples ] ;
}

//  ------------------------------------------------------------------------
//	AudioConverterInputDataProc (see CoreAudio AudioConverter documentation)
//
//  AudioConverterFillBuffer in the readThread causes data to be read from this proc.
//  readThread will block here if there is no data in the pipe.

static OSStatus inputResampleProc( AudioConverterRef converter, UInt32 *dataSize, void **outData, void *userData )
{
	UInt32 m ;
	PSKHub *obj ;
	
	obj = (PSKHub*)userData ;
	
	// block here waiting for data	
	[ obj->dataPipe readData:obj->audioStream length:512*sizeof(float) ] ;
	m = 512*sizeof(float) ;
	*outData = obj->audioStream ;
	*dataSize = m ;

	return 0 ;
}

//  This thread runs constantly (but is blocked in the inputResampleProc when data is stopped (nothing coming input -importBuffer). 
- (void)readThread:(id)client
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ], *delayedRelease = nil ;
	int samples, runLoopCycle ;
	float inputBuffer[512] ;
	UInt32 audioConvertByteSize ;
	OSStatus status ;
			
	runLoopCycle = 0 ;
	
	//  Loop continuously requesting data at 8000 s/s.  
	//  This thread will block in the inputResampleProc
	//  When a complete buffer is received, it is sent to -hasNewdata
	while ( 1 ) {
		audioConvertByteSize = 512*sizeof( float ) ;
		
		//  get rate converted data and send to client
		status = AudioConverterFillBuffer( rateConverter, inputResampleProc, self, &audioConvertByteSize, inputBuffer ) ;
		if ( status == 0 ) {
			samples = audioConvertByteSize / sizeof( float ) ;
			[ self sendBufferToDemodulators:inputBuffer samples:samples ] ;
		}
		//  memory management of readThread (release every 100 seconds)
		if ( runLoopCycle++ > 1501 ) {
			//  periodically flush the Autorelease pool
			if ( delayedRelease ) {
				//  delay actual release of the old pool by one lap time to allow AudioConverter to completely drain.
				//	as a result, we will use about twice the amount of real memory for the thread.
				[ poolBusy lock ] ;
				//	v0.76 : don't drain pool in Snow Leopard
				SInt32 systemVersion = 0 ;
				Gestalt( gestaltSystemVersionMinor, &systemVersion ) ;
		
				if ( systemVersion < 6 /* before snow leopard */ ) {
					[ delayedRelease drain ] ;		// v0.57b
				}
				delayedRelease = nil ;
				[ poolBusy unlock ] ;
			}
			runLoopCycle = 0 ;
			delayedRelease = pool ;
			pool = [ [ NSAutoreleasePool alloc ] init ] ;
		}
	}	
	[ pool release ] ;
	[ NSThread exit ] ;
}

- (Boolean)isEnabled
{
	return [ mainDemodulator receiverEnabled ] ;
}

//  How it works:
//
//  Data comes here from PSKReceiver as 512 floating point packets at 11025 (CMFs) samples/second.
//  we simply write the 512 floating point samples into the resampling pipe.
//  This will be subsequently be picked up by a waiting -inputResampleProc that is initiated when the readThread calls AudioConverter.
//	The readThread is blocked by the inputResamplingProc, which in turn is blocked waiting for a buffer write from here.
//	The readThread receives 8000 s/s data, which it then send to the demodulators.
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	
	if ( ![ self isEnabled ] ) return ;

	[ poolBusy lock ] ;
	stream = [ pipe stream ] ;
	[ dataPipe write:stream->array length:512*sizeof( float ) ] ;
	[ poolBusy unlock ] ;
}

@end
