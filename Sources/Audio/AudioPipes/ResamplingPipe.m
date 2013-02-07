//
//  ResamplingPipe.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/22/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ResamplingPipe.h"
#import "ModemAudio.h"


@implementation ResamplingPipe

//	v0.90	convert data into stereo and keep AudioConverter working with Stereo

- (void)setNumberOfChannels:(int)ch
{
	//  v0.93c -- set up basic description with updated channels instead of stereo channels
	channels = ch ;
	basicDescription.mChannelsPerFrame = ch ;
	basicDescription.mBytesPerFrame = 4 * basicDescription.mChannelsPerFrame ;
	basicDescription.mBytesPerPacket = 4 * basicDescription.mChannelsPerFrame ;
	basicDescription.mBitsPerChannel = 32 ;
	//  set up rate/channels that will cause an initialization when first use
	currentInputSamplingRate = currentOutputSamplingRate = -1 ;
}

//	(Private API)
- (void)finishInit:(float)rate channels:(int)ch
{
	inputSamplingRate = outputSamplingRate = rate ;
	
	basicDescription.mSampleRate = rate ;
	basicDescription.mFormatID = kAudioFormatLinearPCM ;
	basicDescription.mFormatFlags = kLinearPCMFormatFlagIsFloat ;
	#if __BIG_ENDIAN__
	basicDescription.mFormatFlags |= kLinearPCMFormatFlagIsBigEndian ;
	#endif
	basicDescription.mFramesPerPacket = 1 ;	
	[ self setNumberOfChannels:ch ] ;			//  v0.93c
	rateConverter = nil ;
	odd = NO ;
	remainingSamples = 0 ;
}

//	Add an AudioConverter to a DataPipe
- (id)initWithSamplingRate:(float)rate channels:(int)ch
{
	self = [ super initWithCapacity:16384*128*sizeof(float) ] ;
	if ( self ) {
		unbufferedTarget = nil ;
		useConstantOutputBufferSize = YES ;
		[ self finishInit:rate channels:ch ] ;
	}
	return self ;
}

//  this is used by ModemDest
- (id)initUnbufferedPipeWithSamplingRate:(float)rate channels:(int)ch target:(ModemAudio*)target
{
	self = [ super initWithCapacity:512*2*sizeof(float) ] ;			//  stereo 512 sample buffer
	if ( self ) {
		unbufferedTarget = target ;
		useConstantOutputBufferSize = YES ;
		[ self finishInit:rate channels:ch ] ;
	}
	return self ;
}

- (void)dealloc
{
	if ( rateConverter ) {
		AudioConverterDispose( rateConverter ) ;
		rateConverter = nil ;
	}
	[ super dealloc ] ;
}

- (void)setInputSamplingRate:(float)rate
{
	inputSamplingRate = rate ;
}

- (void)setOutputSamplingRate:(float)rate
{
	outputSamplingRate = rate ;
}

- (int)channels
{
	return channels ;
}


- (int)write:(float*)buf samples:(int)samples
{
	int written, i ;
	float *b, u ;
	
	if ( unbufferedTarget != nil ) return 0 ;		//  cannot write into an unbuffered resampling pipe
	
	if ( channels == 1 ) {
		//	v0.93c - only write a single channel into the resampling pipe if mono
		b = stereoBuffer ;
		if ( samples > 1024 ) samples = 1024 ;
		for ( i = 0; i < samples; i++ ) {
			u = buf[i] ;
			*b++ = u ;
		}
		written = [ self write:stereoBuffer length:samples*sizeof( float ) ] ;
		return written / ( sizeof( float ) ) ;
	}
	//  stereo input
	written = [ self write:buf length:samples*channels*sizeof( float ) ] ;
	return written / ( channels*sizeof( float ) ) ;
}

//	AudioConverterInputDataProc (see CoreAudio AudioConverter documentation)
//
//  AudioConverterFillBuffer in readResampledData causes data to be read from this proc.
//  dataSize depends on the decimation ratio.
//	In the ressampleProc implementation, we block on multiple read( fdIn,... ) calls until we have all
//	of dataSize available.  And excess data that is unused is written into the resampleData
//
//  readThread will block here if there is no data in the pipe.

static OSStatus resampleProc( AudioConverterRef converter, UInt32 *dataSize, void **outData, void *userData )
{
	int n ;
	float *buf ;
	ResamplingPipe *p ;
	
	//  limit return size of our buffer size
	n = *dataSize ;
	if ( n > 8192 ) n = 8192 ;
	
	//	alternate between two buffers
	p = (ResamplingPipe*)userData ;
	buf = (float*)p->resampledBuffer ;
	if ( p->odd ) buf += 8192 ;
	p->odd = !p->odd ;
		
	n = [ p readData:buf length:n ] ;	//  block here until all data arrives
	
	*outData = (void*)( buf ) ;
	*dataSize = n ;
	return 0 ;
}

//	data is fetched from the "target" in 512 sample chunks.
//	If the buffer runs out, another 512 sampels are pulled from the target.
//	In the unbuffered case here, we skip the pipe entirely.
static OSStatus unbufferedResampleProc( AudioConverterRef converter, UInt32 *dataSize, void **outData, void *userData )
{
	int n, m ;
	float *buf ;
	ResamplingPipe *p ;
	
	p = (ResamplingPipe*)userData ;
	if ( p->unbufferedTarget == nil ) {
		*dataSize = 0 ;
		return 0 ;
	}
	if ( p->useConstantOutputBufferSize == NO ) {
		//  For clients that can supply variable number of samples (or supplies zero filled buffer)
		//	The client should return the actual number of samples supplied if it is less than the requested number of samples
		m = *dataSize/sizeof(float)/p->channels ;	
		buf = (float*)p->resampledBuffer ;
		n = [ p->unbufferedTarget needData:buf samples:m channels:p->channels ]*p->channels*sizeof(float) ;
	}
	else {
		//  Always ask for a constant number of samples from the client.
		buf = (float*)p->resampledBuffer ; 
		if ( p->remainingSamples <= 0 ) {
			[ p->unbufferedTarget needData:buf samples:512 channels:p->channels ] ;
			p->remainingSamples = 512 ;
		}		
		//  limit return size of our buffer size
		n = *dataSize ;
		m = p->remainingSamples*sizeof( float )*p->channels ;
		if ( n > m ) n = m ;
		
		buf = buf + ( 512 - p->remainingSamples )*p->channels ;
		p->remainingSamples -= n/sizeof( float ) ;
	}
	*outData = (void*)( buf ) ;
	*dataSize = n ;
	return 0 ;
}

- (void)setUseConstantOutputBufferSize:(Boolean)constant
{
	useConstantOutputBufferSize = constant ;
}

- (void)makeNewRateConverter
{
	AudioStreamBasicDescription in, out ;
	UInt32 quality ;
	OSStatus status ;

	if ( rateConverter ) {
		//  a rate converter already exists
		AudioConverterReset( rateConverter ) ;
		AudioConverterDispose( rateConverter ) ;
		rateConverter = nil ;
	}
	in = basicDescription ;
	in.mSampleRate = inputSamplingRate ;
	out = basicDescription ;
	out.mSampleRate = outputSamplingRate ;
	
	remainingSamples = 0 ;			//  v0.85
	
	//  create a SamplerateConverter for this read thread
	status = AudioConverterNew( &in, &out, &rateConverter ) ;
	
	//  set up as high quality rate converter	
	quality = kAudioConverterQuality_Max ;
	AudioConverterSetProperty( rateConverter, kAudioConverterSampleRateConverterQuality, sizeof( UInt32 ), &quality ) ;
	currentInputSamplingRate = inputSamplingRate ;
	currentOutputSamplingRate = outputSamplingRate ;
}

//	return -1 if EOF
//	return number of samples otherwise
- (int)readResampledData:(float*)buf samples:(int)samples
{
	OSStatus status ;
	UInt32 audioConvertByteSize ;
	
	if ( [ self eof ] == YES ) return -1 ;
	
	if ( rateConverter == nil || inputSamplingRate != currentInputSamplingRate || outputSamplingRate != currentOutputSamplingRate ) {
		//  need to create new rate converter
		[ self makeNewRateConverter ] ;
	}
	//  get rate converted data and send to client
	audioConvertByteSize = samples*channels*sizeof( float ) ;		//  v0.92  (was set to 2 channels in v0.90, which does not work for output unbuffered channels)
	
	if ( unbufferedTarget != nil ) {
		status = AudioConverterFillBuffer( rateConverter, unbufferedResampleProc, self, &audioConvertByteSize, buf ) ; 
	}
	else {	
		status = AudioConverterFillBuffer( rateConverter, resampleProc, self, &audioConvertByteSize, buf ) ; 
	}	
	if ( status == 0 ) return audioConvertByteSize / ( sizeof( float )*channels ) ; //	v0.92 was fixed to stereo in v0.90
	return 0 ;
}

@end
