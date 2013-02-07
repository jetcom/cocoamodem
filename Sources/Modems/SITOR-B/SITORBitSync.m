//
//  SITORBitSync.m
//  CoreModem 2.0
//
//  Created by Kok Chen on 2/7/06
	#include "Copyright.h"

#import "SITORBitSync.h"
#include <vecLib/vDSP.h>
#include <math.h>

//  Obtain bit clock and feed the bits to the Moore decoder.

@implementation SITORBitSync

- (id)init
{
	float g ;
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		//  set up bitsync type DataStream
		data = &bitStream ;
		bitStream.array = &syncedData[0] ;
		bitStream.samples = 256 ;
		bitStream.components = bitStream.channels = 1 ;
		previousClockValue = 0 ;
		
		invert = NO ;
		decoder = nil ;
		
		memset( input.data, 0, sizeof( ATCPair )*768 ) ;
		memset( postAGC.data, 0, sizeof( ATCPair )*768 ) ;
		
		//  comb filter for transition at midbit, after delay through the comb filter
		//bitClockFilter = CMFIRCombFilter( 100.0, CMFs/8, 1024, 0.2 ) ;		
		bitClockFilter = CMFIRCombFilter( 100.0, CMFs/8, 1024, 0.2 ) ;		

		//  alpha^n = 1/2.71828, where n is in steps of Fs/8
		//  first set of AGC constants (1/100) is often encountered
		g = 8.0/CMFs ;
		postAGC.attack = exp( -g/0.0005 ) ;		//  0.5 ms attack time constant
		postAGC.decay = exp( -g/0.120 ) ;		//  120 ms decay time constant
		
		postAGC.markAGC = postAGC.spaceAGC = 0.0 ;
		
		//  for RTTY 1.5 stop bit tests
		rttyTestIndex = rttyTestCycles = rttyTestReject = 0 ;
		for ( i = 0; i < 256; i++ ) rttyTestAccum[i] = 0 ;
	}
	return self ;
}

- (void)setMooreDecoder:(MooreDecoder*)decode
{
	decoder = decode ;
}

- (CMPipe*)atcWaveformBuffer
{
	return atcBuffer ;
}

- (void)setBitSamplingFromBaudRate:(float)baudrate
{
}

- (void)setEqualize:(int)mode
{
	//  no eualizer in SITOR reader
}

- (void)setInvert:(Boolean)isInvert
{
	invert = isInvert ;
}

- (void)setSquelch:(float)value
{
	//  squelch threshold (value = 0.0 == maximal squelching)
	if ( decoder ) [ decoder setSquelch:value ] ;
}

//  computed AGC compensated data (looks at "future" data to determine AGC)
static void updateAGC( ATCStream *in, ATCStream *out )
{
	int i ;
	float att, dec, m, s, v ;
	ATCPair *din, *dout;
	
	att = out->attack ;
	dec = out->decay ;
	// look ahead 22ms to compute AGC
	
	din = &in->data[384+100] ;
	dout = &out->data[384-1] ;
	m = out->markAGC ;
	s = out->spaceAGC ;
	dout++ ;
	for ( i = 384; i < 384+256; i++ ) {
		v = din->mark ;
		m = ( ( v > m ) ? att : dec )*( m - v ) + v ;
		dout->mark = v - m*0.5 ;
		v = din->space ;
		s = ( ( v > s ) ? att : dec )*( s - v ) + v ;
		dout->space = v - s*0.5 ;
		din++ ;
		dout++ ;
	}
	out->markAGC = m ;
	out->spaceAGC = s ;
}

/* local */
//  test 1.5 bit stop bit synchronous character sync extraction
#define RTTYTESTLIMIT	32
- (void)rttyTest:(float*)p
{
	int k, n, i, remain ;
	
	if ( rttyTestReject++ < 17 ) return ;
	
	n = 11025*.022*7.5/8 ;		// 7.5 bit cycle, at 8x decimation
	
	remain = 256 ;
	
	for ( k = 0; k < 3; k++ ) {
		if ( remain <= 0 ) return ;
		for ( i = rttyTestIndex; i < n; i++ ) {
			rttyTestAccum[i] += *p++ ;
			remain-- ;
		}
			
		rttyTestCycles++ ;

		//  dump data
		if ( rttyTestCycles >= RTTYTESTLIMIT ) {
			for ( i = 0; i < n; i++ ) printf( "%f\n", rttyTestAccum[i] ) ;
			exit( 0 ) ;
		}
		
		rttyTestIndex = 0 ;
		if ( remain < n ) {
			for ( i = 0; i < remain; i++ ) rttyTestAccum[i] += *p++ ;
			rttyTestIndex = i ;
			return ;
		}
	}
	
}

//  NOTE: sampling rate here is Fs/8, decimated by the matched filter
//        with 256 samples per frame
//
//  For Fs = 11025, the sampling rate here is about 1378 s/s (0.726ms per sample)
//  For 45.45 baud, each bit is 22ms or 30.32 samples.
//
//  new data is stuffed into the end of a 768-sample delay line
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	int i, samples, size, dataBits ;
	float *m, *s, u, v, sliced[256], squared[256], clockExtract[256] ;
	ATCPair *p ;
	
	stream = [ pipe stream ] ;
	bitStream.sourceID = stream->sourceID ;
	samples = stream->samples ;
	if ( samples > 256 ) samples = 256 ;
	
	//  invert M/S polarity here.
	if ( invert ) {
		s = stream->array ;
		m = stream->array+samples ;
	}
	else {
		m = stream->array ;
		s = stream->array+samples ;
	}
	//  copy input data into tail of buffer
	//  input is split complex. Put it into ATCpair format
	p = &input.data[512] ;
	
	for ( i = 0; i < 256; i++ ) {
		p->mark = *m++ ;
		p->space = *s++ ;
		p++ ;
	}
		
	//  gain control the input data
	updateAGC( &input, &postAGC ) ;
	
	//  use this as a base for for RTTY 1.5 stop bit tests
	#ifdef RTTYTEST
	p = &postAGC.data[0] ;
	for ( i = 0; i < 256; i++ ) {
		v = ( p->mark - p->space ) ;
		sliced[i] = v ;
		p++ ;
	}
	[ self rttyTest:sliced ] ;
	#endif

	
	p = &postAGC.data[0] ;
	for ( i = 0; i < 256; i++ ) {
		v = ( p->mark - p->space ) ;
		sliced[i] = v ;
		squared[i] = v*v ;
		p++ ;
	}
	//  LPF data to extract clock
	//  note that since the LPF is 256 in length and symmetrical, the output is delayed by 128 samples
	CMPerformFIR( bitClockFilter, squared, 256, clockExtract ) ;
		
	//  actual data is here
	dataBits = 0 ;
	v = previousClockValue ;
	for ( i = 0; i < 256; i++ ) {
		u = clockExtract[i] ;
		if ( v <= 0.0 && u > 0 ) {
			// leading edge of clock
			syncedData[dataBits++] = sliced[i] ;
		}
		v = u ;
	}
	previousClockValue = u ;
	bitStream.samples = dataBits ;
	
	//  export to decoder
	[ self exportData ] ;

	//  move tail to head of buffers
	size = sizeof( ATCPair )*512 ;
	memcpy( input.data, &input.data[256], size ) ;
	memcpy( postAGC.data, &postAGC.data[256], size ) ;
}

@end
