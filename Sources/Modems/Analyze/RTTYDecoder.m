//
//  RTTYDecoder.m
//  cocoaModem
//
//  Created by Kok Chen on 3/11/05.
	#include "Copyright.h"
//

#import "RTTYDecoder.h"
#include <math.h>


@implementation RTTYDecoder

//  The RTTY decoder consists of two RTTYRegisters (one for the mark and one for the space channel)

- (id)init
{
	self = [ self initWithBitPeriod:22.0 ] ;
	return self ;
}

- (id)initWithBitPeriod:(float)bitPeriod
{
	self = [ super init ] ;
	if ( self ) {
		period = bitPeriod ;
		mark = [ [ RTTYRegister alloc ] initWithBitPeriod:period ] ;
		space = [ [ RTTYRegister alloc ] initWithBitPeriod:period ] ;
		block = NO ;
	}
	return self ;
}

- (void)dumpData
{
	int i, k, m ;
	float s, t, u, v, a ;
	
	m = 4 ;
	for ( i = -128*m; i < 128*m; i += m ) {
		s = t = u = v = 0 ;
		for ( k = 0; k < m; k++ ) {
			a = [ mark sample:0 offset:i+k ] - [ space sample:0 offset:i+k ] ;
			if ( fabs(a) > fabs( s ) ) s = a ;
			a = [ mark agcAtOffset:i+k ] ;
			if ( a > u ) u = a ;
			a = [ space agcAtOffset:i+k ] ;
			if ( a > v ) v = a ;
		}
		v = - v ;
		t = u + v ;

		printf( "%8.4f\t%8.4f\t%8.4f\t%8.4f\n", s, t*2, u*2, v*2 ) ;
	}
}

- (void)addSamples:(int)size mark:(float*)markArray space:(float*)spaceArray
{
	assert( size == 256 ) ;
	[ mark addSamples:size array:markArray ] ;
	[ space addSamples:size array:spaceArray ] ;
}


- (void)advance
{
	[ mark advance ] ;
	[ space advance ] ;
}

- (RTTYRegister*)mark
{
	return mark ;
}

- (RTTYRegister*)space
{
	return space ;
}

- (float)markAtBit:(int)bit offset:(int)offset
{
	return [ mark sample:bit offset:offset ] ;
}

- (float)spaceAtBit:(int)bit offset:(int)offset
{
	return [ space sample:bit offset:offset ] ;
}

- (float)sample:(int)bit word:(int)w offset:(int)offset
{
	float a ;
	
	a = [ mark sample:bit word:w offset:offset ] - [ space sample:bit word:w offset:offset ] ;
	return a ;
}

static float wi[6] = { 1.0, 1.0, 1.0, 1.0, 1.0, 1.0 } ;

- (float)syncWeight:(int)offset
{
	float a, b, d, n ;
	int i, w ;
	
	n = 0.0 ;
	d = 0.000000001 ;
	//  word -3, -2, -1, 0, +1
	for ( i = 0; i < 5; i++ ) {
		w = i - 3 ;
		if ( w != 7 ) {
			//  compute for all but current character
			b = wi[i] ;
			a = b*[ self sample:-3 word:w offset:offset ] ;
			d += a*a ;
			n += a ;
			a = b*[ self sample:-2 word:w offset:offset ] ;
			d += a*a ;
			n += a ;
			a = b*[ self sample:-1 word:w offset:offset ] ;
			d += a*a ;
			n -= a ;
			a = b*[ self sample:5 word:w offset:offset ] ;
			d += a*a ;
			n += a ;
			a = b*[ self sample:6 word:w offset:offset ] ;
			d += a*a ;
			n += a ;
		}
	}
	a = n/sqrt( 25.0*d ) ;
	return a ;
}

- (float)newSyncWeight:(int)offset
{
	float a, d, n ;
	int i, w ;
	
	n = 0.0 ;
	d = 0.000000001 ;
	//  word -3, -2, -1, 0, +1
	for ( i = -2; i < 5; i++ ) {
		w = i - 3 ;
		//  compute for all but current character
		a = [ self sample:-3 word:w offset:offset ] ;
		d += a*a ;
		n += a ;
		a = [ self sample:-2 word:w offset:offset ] ;
		d += a*a ;
		n += a ;
		a = [ self sample:-1 word:w offset:offset ] ;
		d += a*a ;
		n -= a ;
		
		/*
		a = 1.5*[ self leadingEdge:-1 word:w offset:offset ] ;
		n -= fabs( a ) ;
		*/
	}
	a = n/sqrt( 21.0*d ) ;
	return a ;
}

/* local */
//  relative certainty of frame sync for a single character
//  looks for 2 samples of previous stop bits, start bit and following stop bits, together with the stop/start transition
- (float)singleSyncWeight:(int)offset
{
	float a, d, n, agc ;
	
	n = 0.0 ;
	d = 0.000000001 ;
	
	agc = [ mark agcForWord:0 ] - [ space agcForWord:0 ] ;
	
	a = [ self sample:-3 word:0 offset:offset ] - agc ;
	d += a*a ;
	n += a ;
	
	a = [ self sample:-2 word:0 offset:offset ] - agc ;
	d += a*a ;
	n += a ;
	
	a = [ self sample:-1 word:0 offset:offset ] - agc ;
	d += a*a ;
	n -= a ;
	
	a = [ self sample:5 word:0 offset:offset ] - agc ;
	d += a*a ;
	n += a ;
	
	a = [ self sample:6 word:0 offset:offset ] - agc ;
	d += a*a ;
	n += a ;
	
	/*
	a = 3.0*[ self leadingEdge:-1 word:0 offset:offset ] - agc ;
	n -= fabs( a ) ;
	*/
	
	return n/sqrt( 5.0*d ) ;
}

- (float)forwardSyncWeight:(int)offset
{
	float a, d, n, agc ;
	int i ;
	
	n = 0.0 ;
	d = 0.000000001 ;
	
	for ( i = 0; i < 3; i++ ) {
		agc = [ mark agcForWord:i ] - [ space agcForWord:i ] ;
		if ( i == 0 ) {
			//  pre-stop
			a = [ self sample:-3 word:i offset:offset ] - agc ;
			d += a*a ;
			n += a ;
		}
		// leading stop bit
		a = [ self sample:-2 word:i offset:offset ] - agc ;
		d += a*a ;
		n += a ;
		// start bit
		a = [ self sample:-1 word:i offset:offset ] - agc ;
		d += a*a ;
		n -= a ;
		//  trailing stop bit
		a = [ self sample:5 word:i offset:offset ] - agc ;
		d += a*a ;
		n += a ;
		if ( i == 2 ) {
			//  post-stop
			a = [ self sample:6 word:i offset:offset ] - agc ;
			d += a*a ;
			n += a ;
		}
		/*
		//  stop-start transition
		a = 3.0*[ self leadingEdge:-1 word:i offset:offset ] - agc ;
		n -= fabs( a ) ;
		*/
	}
	return n/sqrt( 11.0*d ) ;
}
		
- (float)OldasyncWeight:(int)offset
{
	float a, d, n ;
	int i ;
	
	n = 0.0 ;
	d = 0.000000001 ;

	a = [ self sample:-2 word:0 offset:offset ] ;
	d += a*a ;
	n += a ;
	a = [ self sample:-1 word:0 offset:offset ] ;
	d += a*a ;
	n -= a ;
	for ( i = 0; i < 5; i++ ) {
		a = [ self sample:i word:0 offset:offset ] ;
		d += a*a ;
		n += fabs( a ) ;
	}
	a = [ self sample:5 word:0 offset:offset ] ;
	d += a*a ;
	n += a ;

	a = n/sqrt( 8.0*d ) ;
	return a ;
}

- (float)asyncWeight:(int)offset
{
	float a, n, s0, s1, s2 ;
	int i ;

	s0 = 0 ;
	s0 = [ self sample:-2 word:0 offset:offset ] ;
	if ( s0 < 0 ) return 0.0 ;
	s1 = [ self sample:-1 word:0 offset:offset ] ;
	if ( s1 > 0 ) return 0.0 ;
	s2 = [ self sample:5 word:0 offset:offset ] ;
	if ( s2 < 0 ) return 0.0 ;

	n = 2*( s0 - s1 + s2 ) ;
	
	for ( i = 0; i < 5; i++ ) {
		a = [ self sample:i word:0 offset:offset ] ;
		n += fabs( a ) ;
	}
	return n ;
}

- (void)checkSync:(float*)g length:(int)n
{
	int i ;
	
	for ( i = 0; i < n; i++ ) g[i] = [ self syncWeight:i ] ;
}

- (void)getBuffer:(CMATCPair*)pair markOffset:(int)markOffset spaceOffset:(int)spaceOffset
{
	[ mark getBuffer:( &pair->mark ) offset:markOffset stride:2 ] ;
	[ space getBuffer:( &pair->space ) offset:spaceOffset stride:2 ] ;
}

//  to reduce false positives, look for previous character's stop bit, the start bit and also the stop bit after the data bits.
- (Boolean)symbolSync
{
	float stop, start ;
	
	//  previous character's stop bit
	stop = [ mark sample:-2 ] - [ space sample:-2 ] ;
	if ( stop < 0 ) return NO ;
	
	start = [ mark sample:-1 ] - [ space sample:-1 ] ;
	if ( start > 0 ) return NO ;

	stop = [ mark sample:5 ] - [ space sample:5 ] ;
	return ( stop > 0 ) ;
}

//  return the index that has the best sync position
- (void)bestSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check
{
	float stop, start, q, qmax ;
	int bestOffset, i ;
	
	check->frameSync = NO ;
	check->confidence = 0 ;
	
	//  previous character's stop bit
	stop = [ mark sample:-2 offset:m ] - [ space sample:-2 offset:s ] ;
	if ( stop < 0 ) return ;
	
	start = [ mark sample:-1 offset:m ] - [ space sample:-1 offset:s ] ;
	if ( start > 0 ) return ;

	stop = [ mark sample:5 offset:m ] - [ space sample:5 offset:s ] ;
	if ( stop < 0 ) return ;
	
	bestOffset = 0 ;
	qmax = [ self syncWeight:0 ] ;
	for ( i = 0; i < 30; i++ ) {
		q = [ self syncWeight:i ] ;
		if ( q > qmax ) {
			qmax = q ;
			bestOffset = i ;
		}
	}
	//if ( qmax > 0.99 ) qmax = 0.99 ; else if ( qmax < .1 ) qmax = 0.1 ;
	check->frameSync = YES ;
	check->confidence = qmax ; // qmax/( 1.0 - qmax ) ;
	check->offset = bestOffset ;
}

//  return the index that has the best sync position
- (void)validateSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check
{
	float start, stop, q, qmax, mMax, sMax, atc ;
	int bestOffset, i ;
	
	check->frameSync = NO ;
	check->confidence = 0 ;
	
	mMax = [ mark agcAtOffset:m ] ;
	sMax = [ space agcAtOffset:s ] ;
	atc = ( mMax - sMax ) ;
	
	//  previous character's stop bit
	stop = [ mark sample:-2 offset:m ] - [ space sample:-2 offset:s ] - atc ;
	if ( stop < 0 ) return ;
	
	start = [ mark sample:-1 offset:m ] - [ space sample:-1 offset:s ] - atc ;
	if ( start > 0 ) return ;

	stop = [ mark sample:5 offset:m ] - [ space sample:5 offset:s ] - atc ;
	if ( stop < 0 ) return ;
	
	bestOffset = 0 ;
	qmax = [ self syncWeight:0 ] ;
	for ( i = 0; i < 20; i++ ) {
		q = [ self syncWeight:i ] ;
		if ( q > qmax ) {
			qmax = q ;
			bestOffset = i ;
		}
	}
	check->frameSync = YES ;
	check->confidence = qmax ; // qmax/( 1.0 - qmax ) ;
	check->offset = bestOffset ;
}

//  check the next 256 samples for a frame sync, by looking only at a single character's frame
- (void)findFrameSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check
{
	float q, qmax ;
	int bestOffset, i ;
	
	check->frameSync = NO ;
	check->confidence = 0 ;
	
	bestOffset = 0 ;
	qmax = [ self syncWeight:0 ] ;
	for ( i = 0; i < 256; i++ ) {
		q = [ self forwardSyncWeight:i ] ;
		if ( q > qmax ) {
			qmax = q ;
			bestOffset = i ;
		}
	}
	if ( qmax > 0.66 ) {
		check->frameSync = YES ;
		check->confidence = qmax ;
		check->offset = bestOffset ;
		return ;
	}

	qmax = [ self syncWeight:0 ] ;
	for ( i = 0; i < 256; i++ ) {
		q = [ self singleSyncWeight:i ] ;
		if ( q > qmax ) {
			qmax = q ;
			bestOffset = i ;
		}
	}
	if ( qmax > 0.66 ) check->frameSync = YES ;
	check->confidence = qmax ;
	check->offset = bestOffset ;
}

- (void)checkSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check
{
	float q, qmax ;
	int bestOffset, i ;
	float array[400] ;
		
	check->frameSync = NO ;
	check->confidence = 0 ;
	
	bestOffset = 0 ;
	qmax = [ self syncWeight:0 ] ;
	for ( i = 0; i < 5; i++ ) {
		q = [ self forwardSyncWeight:i ] ;
		array[i] = q ;
		if ( q > qmax ) {
			qmax = q ;
			bestOffset = i ;
		}
	}
	if ( qmax > 0.66 ) {
		check->frameSync = YES ;
		check->confidence = qmax ;
		check->offset = bestOffset ;
	}
	check->frameSync = YES ;
	check->confidence = qmax ; // qmax/( 1.0 - qmax ) ;
	check->offset = bestOffset ;
}

//  return the index that has the best async position
- (void)bestAsyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check
{
	float stop, start, q, qmax, mmax, smax, mv, sv ;
	int bestOffset, i ;
	
	check->frameSync = NO ;
	check->confidence = 0 ;
	
	//  previous character's stop bit
	mv = [ mark sample:-2 offset:m ] ;
	mmax = 0.05*[ mark agcAtOffset:m ] ;
	if ( mv < mmax ) return ;
	sv = [ space sample:-2 offset:s ] ;
	stop = mv - sv ;
	if ( stop < 0 ) return ;
	
	mv = [ mark sample:-1 offset:m ] ;
	sv = [ space sample:-1 offset:s ] ;
	smax = 0.05*[ space agcAtOffset:s ] ;
	if ( sv < smax ) return ;
	start = mv - sv ;
	if ( start > 0 ) return ;
	
	mv = [ mark sample:5 offset:m ] ;
	if ( mv < mmax ) return ;
	sv = [ space sample:5 offset:s ] ;
	stop = mv - sv ;
	if ( stop < 0 ) return ;
	
	bestOffset = 0 ;
	qmax = [ self asyncWeight:0 ] ;
	for ( i = 1; i < 30; i++ ) {
		q = [ self asyncWeight:i ] ;
		if ( q > qmax ) {
			qmax = q ;
			bestOffset = i ;
		}
	}
	stop = [ mark sample:5 offset:bestOffset ] - [ space sample:5 offset:bestOffset ] ;
	start = -[ mark sample:-1 offset:bestOffset ] + [ space sample:-1 offset:bestOffset ] ;

	q = fabs( stop ) + 0.01 ;
	if ( fabs( start ) > q ) q = fabs( start ) ;
	
	qmax = ( stop + start )/( 2*q ) ;
	
	
	//if ( qmax > 0.99 ) qmax = 0.99 ; else if ( qmax < .1 ) qmax = 0.1 ;
	check->frameSync = ( qmax > 0.4 ) ;
	check->confidence = qmax ; // qmax/( 1.0 - qmax ) ;
	check->offset = bestOffset ;
}

- (float)likelihoodWithMarkOffset:(int)m spaceOffset:(int)s
{
	float sum, v ;
	int i ;
	
	sum = 0.0 ;
	for ( i = -1; i < 6; i++ ) {
		v = [ mark sample:i offset:m ] - [ space sample:i offset:s ] ;
		sum += fabs( v ) ;
	}
	return sum ;
}


@end
