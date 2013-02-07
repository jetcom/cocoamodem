//
//  LitePSKMatchedFilter.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/19/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "LitePSKMatchedFilter.h"
#import	"LitePSKDemodulator.h"

#define piBy2	( 3.1415926535/2 )


@implementation LitePSKMatchedFilter

- (id)initWithClient:(LitePSKDemodulator*)client
{
	self = [ super init ] ;
	if ( self ) {
		demodulator = client ;
		printEnable = NO ;
	}
	return self ;
}

- (void)setPrintEnable:(Boolean)state
{
	printEnable = state ;
}

static float sq1( float p )
{
	return p*p ;
}

//  2-chip decoder
- (float)bpskEstimate2:(MatchedPair*)matchedPair
{
	MatchedPair m0, m1 ;
	float u, v ;
	
	m0 = matchedPair[0] ;
	m1 = matchedPair[1] ;

	u = sq1( m1.i + m0.i ) + sq1( m1.q + m0.q ) ;
	v = sq1( m1.i - m0.i ) + sq1( m1.q - m0.q ) ;
	
	if ( v > u ) return -v ;
	return u ;
}

//  Okunev 3-chip decoder
- (float)bpskEstimate3:(MatchedPair*)matchedPair
{
	MatchedPair m0, m1, m2 ;
	float u, v ;
	
	m0 = matchedPair[0] ;
	m1 = matchedPair[1] ;
	m2 = matchedPair[2] ;
	
	v = sq1( m2.i + m1.i + m0.i ) + sq1( m2.q + m1.q + m0.q ) ;
	u = sq1( m2.i - m1.i - m0.i ) + sq1( m2.q - m1.q - m0.q ) ;
	if ( u > v ) v = u ;
	
	u = sq1( m2.i - m1.i + m0.i ) + sq1( m2.q - m1.q + m0.q ) ;
	if ( u > v ) return -u ;
	u = sq1( m2.i + m1.i - m0.i ) + sq1( m2.q + m1.q - m0.q ) ;
	if ( u > v ) return -u ;
	
	return v ;
}

- (float)bpskEstimate4:(MatchedPair*)matchedPair
{
	MatchedPair m0, m1, m2, m3 ;
	float u, v ;
	
	m0 = matchedPair[0] ;
	m1 = matchedPair[1] ;
	m2 = matchedPair[2] ;
	m3 = matchedPair[3] ;
	
	v = sq1( m3.i + m2.i + m1.i + m0.i ) + sq1( m3.q + m2.q + m1.q + m0.q ) ;
	u = sq1( m3.i - m2.i + m1.i + m0.i ) + sq1( m3.q - m2.q + m1.q + m0.q ) ;
	if ( u > v ) v = u ;
	
	u = sq1( m3.i + m2.i - m1.i - m0.i ) + sq1( m3.q + m2.q - m1.q - m0.q ) ;
	if ( u > v ) v = u ;

	u = sq1( m3.i - m2.i - m1.i - m0.i ) + sq1( m3.q - m2.q - m1.q - m0.q ) ;
	if ( u > v ) v = u ;
	
	u = sq1( m3.i + m2.i + m1.i - m0.i ) + sq1( m3.q + m2.q + m1.q - m0.q ) ;
	if ( u > v ) return -u ;
	u = sq1( m3.i + m2.i - m1.i + m0.i ) + sq1( m3.q + m2.q - m1.q + m0.q ) ;
	if ( u > v ) return -u ;
	u = sq1( m3.i - m2.i + m1.i - m0.i ) + sq1( m3.q - m2.q + m1.q - m0.q ) ;
	if ( u > v ) return -u ;
	u = sq1( m3.i - m2.i - m1.i + m0.i ) + sq1( m3.q - m2.q - m1.q + m0.q ) ;
	if ( u > v ) return -u ;
	
	return v ;
}

//  Use the Okunev 3-chip DPSK demodulator.
- (float)bpskEstimate:(float*)bufI imag:(float*)bufQ
{
	int p0, p1 ;
	MatchedPair matchedPair[4] ;
	float q, q1, ai, aq, bi, bq, dot ;
		
	p0 = ring ;
	matchedPair[0].i = ai = bufI[p0] ;
	matchedPair[0].q = aq = bufQ[p0] ;

	p1 = ( ring+RING )&RING ;		//  p0-1
	matchedPair[1].i = bi = bufI[p1] ;
	matchedPair[1].q = bq = bufQ[p1] ;

	//p2 = ( ring+RING-1 )&RING ;		//  p0-2
	//matchedPair[2].i = bufI[p2] ;
	//matchedPair[2].q = bufQ[p2] ;
		
	//p3 = ( ring+RING-2 )&RING ;		//  p0-2
	//matchedPair[3].i = bufI[p3] ;
	//matchedPair[3].q = bufQ[p3] ;
	
	q1 = [ self bpskEstimate2:&matchedPair[0] ] ;
	//q2 = [ self bpskEstimate3:&matchedPair[0] ] ;
	//q3 = [ self bpskEstimate4:&matchedPair[0] ] ;
	
	//  The dot product of two vectors is related to the cosine as
	//	a.b = |a|.|b|.cos(theta)
	//  For DPSK, |cos(theta)| should be 1.0.
	//	To get the "quality" of a bit, look at ( |a.b|/(|a|.|b|) ) for deviations away from 0 or 180 degrees.
	//  The bit quality is then used to modify a global quality number (reset elsewhere at the beginning of each character).
	
	dot = ai*bi + aq*bq ;
	q = sqrt( dot*dot/( ( ai*ai + aq*aq )*( bi*bi + bq*bq ) + 0.0000001 ) ) ;
	if ( q < quality ) quality = q ;
	
	//  return weighted sum of the three demodulators
	//return ( q1 + 0.7*q2 + 0.5*q3 ) ;
	//  use only a simple DPSK demodulator
	return q1 ;
}

//  estimate the phase angle from a combination of matched filter, narrow matched filter and a single mid bit ssample
- (int)processBpskVector
{
	float matchedBit ;
	int result = 0 ;
	
	if ( printEnable ) {
		//  update the matched filter sequence (the matched ring buffer contains past matched filter values.
		matchedI[ring] = iMatched ;
		matchedQ[ring] = qMatched ;
		matchedBit = [ self bpskEstimate:matchedI imag:matchedQ ] ;
		
		result = ( matchedBit > 0.0 ) ? 1 : 0 ;
		[ demodulator receivedBit:result quality:quality ] ;
	}
	quality = 1.0 ;
	//  update ring buffer index
	ring = ( ring+1 )&RING ;
	return result ;
}

//  new analytic pair at 1000 s/s (32 samples per bit)
//  start is a flag that indicates the estimated boundary between data bits
//	(i.e., during a transition, the analytic pair at start should be very close to (0,0))
- (int)bpsk:(float)real imag:(float)imag bitSync:(Boolean)bitSync
{
	int result ;
	float h ;
	
	//  Matched filter input I/Q pair
	h = kernel[bitPhase] ;
	iMatched += h*real ;
	qMatched += h*imag ;
	
	bitPhase++ ;
	
	//  if bitSync is passed in from the client, we are ready top process this DPSK chip
	if ( !bitSync ) return 0 ;
	
	result = [ self processBpskVector ] ;
	
	//  compute phase error for AFC (bring phases into (-90,+90) degrees
	float t = atan2( qMatched, iMatched ) ;
	phaseError = prevPhase - t ;
	prevPhase = t ;
	
	if ( phaseError > piBy2 ) phaseError = phaseError - pi ; else if ( phaseError < -piBy2 ) phaseError += pi ;
	if ( phaseError > piBy2 ) phaseError = phaseError - pi ; else if ( phaseError < -piBy2 ) phaseError += pi ;
	
	// dump Matched Filter
	iMatched = qMatched = 0 ;
	bitPhase = 0 ;
	return result ;
}

//	do nothing for QPSK
- (int)qpsk:(float)real imag:(float)imag bitSync:(Boolean)start
{
	return 0 ;
}

@end
