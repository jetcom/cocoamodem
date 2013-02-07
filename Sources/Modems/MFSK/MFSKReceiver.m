//
//  MFSKReceiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/29/06.
	#include "Copyright.h"
	
	
#import "MFSKReceiver.h"
#import "MFSKDemodulator.h"
#import "MFSKIndicator.h"
#import "MFSKModes.h"

//	MFSK Receiver
//
//	Mix to with a complex LO to center the signal around DC
//	Then upsample by 20 followed by downsampling by 441 to create a 500 Hz sampling period.

@implementation MFSKReceiver

- (id)initReceiver
{
	self = [ super init ] ;
	if ( self ) {
		enabled = NO ;
		sidebandState = YES ;
		demodulator = nil ;
		clickBuffersAllocated = NO ;		//  v0.80l
			
		//  set up VCO at tone's frequency
		receiveFrequency = 972.0 + CARRIEROFFSET ;
		vco = [ [ CMPCO alloc ] init ] ;
		[ vco setCarrier:receiveFrequency ] ;
		
		//  click buffer
		[ self createClickBuffer ] ;
		
		//  input decimation
		nextSample = 150 ;
		outputIndex = 0 ;
	}
	return self ;
}

- (id)init
{
	self = [ self initReceiver ] ;
	if ( self ) {
		demodulator = [ [ MFSKDemodulator alloc ] init ] ;
		
		//  input decimation
		decimationRatio = CMFs/500.0 ;
		iFilter = CMFIRLowpassFilter( 210, CMFs, 512 ) ;
		qFilter = CMFIRLowpassFilter( 210, CMFs, 512 ) ;
	}
	return self ;
}

//  v0.76 leak (not important, since we don;t release the MFSK object)
- (void)dealloc
{
	[ vco release ] ;
	[ demodulator release ] ;
	CMDeleteFIR( iFilter ) ;
	CMDeleteFIR( qFilter ) ;
	
	[ super dealloc ] ;
}

- (MFSKDemodulator*)demodulator 
{
	return demodulator ;
}

- (void)setSidebandState:(Boolean)state
{
	sidebandState = state ;
	[ demodulator setSidebandState:state ] ;
}

- (void)createClickBuffer
{
	int i ;
	
	if ( clickBuffersAllocated ) return ;				//  v0.80l already allocated by super class

	clickBufferProducer = clickBufferConsumer = 0 ;		//  buffer number (512 samples per buffer)
	clickBufferLock = [ [ NSLock alloc ] init ] ;
	for ( i = 0; i < 512; i++ ) {
		// 1 MB buffer, for 262,144 floating point samples (23.77 seconds)
		clickBuffer[i] = (float*)malloc( 512*sizeof( float ) ) ;	
	}
	clickBuffersAllocated = YES ;
}

//  import data at 11025 s/s 
- (void)importArray:(float*)array
{
	CMAnalyticPair pair ;
	float v, fract ;
	int i, n ;
	
	if ( sidebandState == YES ) {
		// USB
		for ( i = 0; i < 512; i++ ) {
			v = array[i] ;
			pair = [ vco nextVCOPair ] ;
			iMixer[i] = pair.re * v ;
			qMixer[i] = pair.im * v ;
		}
	}
	else {
		//  LSB -- reverse spectrum around DC
		for ( i = 0; i < 512; i++ ) {
			v = array[i] ;
			pair = [ vco nextVCOPair ] ;
			iMixer[i] = pair.re * v ;
			qMixer[i] = -pair.im * v ;
		}
	}
	//  Apply lowpass to I and Q channels
	CMPerformFIR( iFilter, iMixer, 512, &iOutput[0] ) ;
	CMPerformFIR( qFilter, qMixer, 512, &qOutput[0] ) ;

	for ( i = 0; i < 512; i++ ) {
		//  resample the lowpass filtered I.F. using nearest neighbor
		n = nextSample ;
		if ( n > 511 ) {
			nextSample -= 512 ;
			break ;
		}
		if ( n < 511 ) {
			fract = nextSample - n ;
			iBuffer[outputIndex] = iOutput[n]*( 1-fract ) + iOutput[n+1]*fract ;
			qBuffer[outputIndex] = qOutput[n]*( 1-fract ) + qOutput[n+1]*fract ;		
		}
		else {
			iBuffer[outputIndex] = iOutput[n] ;
			qBuffer[outputIndex] = qOutput[n] ;		
		}
		nextSample += decimationRatio ;
		outputIndex++ ;
		if ( outputIndex >= 32 ) {
			//  send 32 samples to demodulator
			[ demodulator newBuffer:iBuffer imag:qBuffer ] ;
			outputIndex = 0 ;
		}
	}
}

- (void)consumeClickBufferData
{
	int i ;
	float *array ;
	
	//  copy the stream info but use the buffered data, and set the pointer to the click buffer
	//  process 8 click buffers as fast as possible until the stream has caught up
	for ( i = 0; i < 8; i++ ) {
		if ( clickBufferConsumer == clickBufferProducer ) break ;
		//  push out unprocessed data
		array = clickBuffer[clickBufferConsumer] ;
		clickBufferConsumer = ( clickBufferConsumer+1 ) & 0x1ff ; // wrap around a 512 buffers
		[ self importArray:array ] ;
	}
}

//  input data for MFSK receiver, at 11025 samples/second
//  resample to 8000 and send to the demodulator.
//  decimationRatio (nominally 11025/500) can be fine tuned to compensate for A/D errors.
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *array, *buf ;

	if ( !enabled ) return ;
	
	if ( [ clickBufferLock tryLock ] ) {
		//  copy data into tail of clickBuffer
		stream = [ pipe stream ] ;
		array = stream->array ;
		//  copy another 512 samples into the click buffer (memcpy has problems with auto release pools?)
		buf = clickBuffer[clickBufferProducer] ;
		clickBufferProducer = ( clickBufferProducer+1 ) & 0x1ff ; // 512 click buffers
		memcpy( buf, array, 512*sizeof( float ) ) ;
		[ self consumeClickBufferData ] ;
		[ clickBufferLock unlock ] ;
	}
}

//  new click, set the click buffer pointer so the next time data will be consumed from the buffer
//  each audio stream is 512 samples in size
//  there are 512 of these buffers in the click buffer, or 23.77 seconds worth
- (void)clicked:(float)history
{
	int i ;
	
	if ( !clickBuffer ) return ;
	
	if ( history < 0.1 ) history = 0.1 ;
	if ( history > 20.0 ) history = 20.0 ;
	
	//  0.73 flush decimation filter
	memset( iMixer, 0, sizeof(float)*512 ) ;
	for ( i = 0; i < 4; i++ ) {
		CMPerformFIR( iFilter, iMixer, 512, &iOutput[0] ) ;
		CMPerformFIR( qFilter, iMixer, 512, &qOutput[0] ) ;
	}

	[ clickBufferLock lock ] ;
	clickBufferConsumer = clickBufferProducer + ( 512 - (int)( 21.5*history ) ) ;
	clickBufferConsumer = clickBufferConsumer & 0x1ff ; // wrap around a 256K sample (512*512 samples) floating point buffer
	[ clickBufferLock unlock ] ;
	
	[ demodulator waterfallClicked ] ;
}

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)clicked
{
	if ( sidebandState ) {
		// USB
		receiveFrequency = freq + CARRIEROFFSET ;					// center is 125 Hz higher
	}
	else {
		receiveFrequency = freq - CARRIEROFFSET ;					// center is 125 Hz lower
	}
	[ vco setCarrier:receiveFrequency ] ;
	if ( clicked ) {
		// don't reset demodulator if it is a scroll wheel operation
		[ demodulator resetDemodulatorState ] ;
	}
}

- (void)enableReceiver:(Boolean)state
{
	enabled = state ;
}

- (Boolean)enabled
{
	return enabled ;
}

/*
//  fine tune to sampling by the factor in parts per million
- (void)fineTune:(float)ppm
{
	float ratio ;
	
	ratio = 1.0 + ppm*1e-6 ;
	decimationRatio = CMFs*ratio/500.0 ;
}
*/

@end
