//
//  PSKMatchedFilter.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 9/25/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "PSKMatchedFilter.h"
#include <math.h>

@implementation PSKMatchedFilter

#define piBy2	( 3.1415926535/2 )
#define twopi   ( 3.1415926535*2 )

#define	OKUNEV 


//	v0.96b
static float hann( float t, int n, double baudrate )
{
	return ( 0.5 - 0.5*( cos( 2*t/n*3.1415926 ) ) )  ;
}

- (id)init
{
	int i ;
	float period, sum ;
	
	self = [ super init ] ;
	if ( self ) {
		quality = 1.0 ;
		prevPhase = phaseError = averagePhaseError = 0 ;
		phaseReportCycle = 0 ;
		//  replace kernel
		//  sine kernel
		period = 32 ;
		midBit = period/2 ;
		
		//	half sine matched filter to PSK31 bit, Hann windowed
		//	(transmitter uses a sine window)
		memset( kernel, 0, sizeof( float )*64 ) ;
		for ( i = 0; i < 32; i++ ) kernel[i] = hann( i, 32, 3.1415926/32 )*pow( sin( i*3.1415926/32.0 ), 0.25 ) ; //  v0.96b did not have hanning window
		
		sum = 0.0 ;
		for ( i = 0; i < 64; i++ ) sum += kernel[i] ;
		for ( i = 0; i < 64; i++ ) kernel[i] /= sum ;

		fec = [ [ ConvolutionCode alloc ] initWithConstraintLength:5 generator:0x19 generator:0x17 ] ;
		[ fec setTrellisDepth:17 ] ;
		[ fec resetTrellis ] ;
		

	}
	return self ;
}

static int sign( float a )
{
	if ( a >= 0 ) return 1 ;
	return 0 ;
}

- (int)processOkunevQpskVector
{
	int p0, p1, p2, j1, j2, jx, result, symbol ;
	float msb, lsb ;
	MatchedPair m0, m1, m2 ;
	
	//  estmate from matched filter
	matchedI[ring] = iMatched ;
	matchedQ[ring] = qMatched ;
	
	p0 = ring ;
	m0.i = matchedI[p0] ;
	m0.q = matchedQ[p0] ;

	p1 = ( ring+RING )&RING ;		//  p0-1
	m1.i = matchedI[p1] ;
	m1.q = matchedQ[p1] ;

	p2 = ( ring+RING-1 )&RING ;		//  p0-2
	m2.i = matchedI[p2] ;
	m2.q = matchedQ[p2] ;

	j1 = sign( m1.i*m0.q - m0.i*m1.q + m0.i*m1.i + m0.q*m1.q ) ;
	j2 = sign( m1.i*m0.i + m1.q*m0.q - m1.i*m0.q + m0.i*m1.q ) ;
	jx = j2*2 + j1 ;		//  jx = 0 (180), j=1 (+90), j=2 (-90), j = 3 (0)

	//  hard decode
	switch ( jx ) {
	case 0:
		// 180 degrees
		symbol = 2 ;
		msb = 1 ;
		lsb = 0 ;
		break ;
	case 1:
		// +90 degrees
		symbol = 1 ;
		msb = 0 ;
		lsb = 1 ;
		break ;
	case 2:
		// -90 degrees
		symbol = 3 ;
		msb = 1 ; 
		lsb = 1 ;
		break ;
	case 3:
		//  0 degrees
		symbol = 0 ;
		msb = lsb = 0 ;
		break ;
	}
	
	float decodedBit = 1-[ fec decodeMSB:msb LSB:lsb ] ;
	result = ( decodedBit > 0.5 ) ? 1 : 0 ;
	[ self receivedBit:result ] ;

	//  update ring buffer indices
	ring = ( ring+1 )&RING ;
	return result ;
}

//  estimate the phase angle from a narrow matched filter
- (int)processQpskVector
{
	float iLastRotated, qLastRotated, dot, dotRotated ;
	int result, symbol ;
	
	iLastRotated = -qLast ;
	qLastRotated = iLast ;
	
	dot = iLast*iPulse + qLast*qPulse ;
	dotRotated = iLastRotated*iPulse + qLastRotated*qPulse ;

	if ( fabs( dot ) > fabs( dotRotated ) ) {
		//  0 or 180 degrees
		symbol = ( dot > 0 ) ? 0 : 2 ;
	}
	else {
		//  plus or minus 90 degrees
		symbol = ( dotRotated > 0 ) ? 1 : 3 ;
	}
	//  shift bits into shift register
	convolutionRegister = ( ( convolutionRegister << 2 ) | symbol ) & 0x3ff ;
	result = qpskTable[ convolutionRegister ] ;
	[ self receivedBit:result ] ;
	
	//  save vector for next bit
	iLast = iPulse ;
	qLast = qPulse ;
	//  update ring buffer indeces
	ring = ( ring+1 )&RING ;
	return result ;
}

//  new analytic pair at Fs/16
- (int)qpsk:(float)real imag:(float)imag bitSync:(Boolean)start
{
	float h ;
	int result ;
	
	h = kernel[ bitPhase & 0x3f ] ;
	iMatched += real*h ;
	qMatched += imag*h ;

	h = pulse[ bitPhase & 0x3f ] ;
	iPulse += real*h ;
	qPulse += imag*h ;

	bitPhase++ ;
	result = 0 ;
	
	if ( start ) {
		#ifdef OKUNEV
		result = [ self processOkunevQpskVector ] ;
		#else
		result = [ self processQpskVector ] ;
		#endif
		// dump
		iPulse = qPulse = 0 ;
		iMatched = qMatched = 0 ;
		bitPhase = 0 ;
	}
	if ( delegate && bitPhase == midBit ) {
		iMid = real ;
		qMid = imag ;
		//  compute absolute phase angle
		phase[0] = atan2( imag, real ) ;
		//  compute relative phase angle
		delta = phase[0]-phase[1] ;
		if ( delta > pi ) delta = twopi - delta ; else if ( delta < -pi ) delta = twopi + delta ;
		[ self updateVCOPhase:delta ] ;
		phase[1] = phase[0] ;
	}
	return result ;
}

static float sq1( float p )
{
	return p*p ;
}

//  The DPSK demodulators are taken from Y. Okunev, "Phase and Phase-difference Modulation in Digital Communications" Artech House, 1997, ISBN 0-89006-937-9.

//  v0.57
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

//  v0.57
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

//  v0.57
//  4-chip Okunev
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

float sq( float v )
{
	if ( v > 0 ) return v*v ; else return -v*v ;
}

//  Use a blend of the Okunev 2-chip, 3-chip and 4-chip (extrapolated from the Okunev book) DPSK demodulators.
- (float)bpskEstimate:(float*)bufI imag:(float*)bufQ
{
	int p0, p1, p2, p3 ;
	MatchedPair matchedPair[4] ;
	float q, q1, q2, q3, ai, aq, bi, bq, dot ;
		
	p0 = ring ;
	matchedPair[0].i = ai = bufI[p0] ;
	matchedPair[0].q = aq = bufQ[p0] ;

	p1 = ( ring+RING )&RING ;		//  p0-1
	matchedPair[1].i = bi = bufI[p1] ;
	matchedPair[1].q = bq = bufQ[p1] ;

	p2 = ( ring+RING-1 )&RING ;		//  p0-2
	matchedPair[2].i = bufI[p2] ;
	matchedPair[2].q = bufQ[p2] ;
	
	p3 = ( ring+RING-2 )&RING ;		//  p0-3
	matchedPair[3].i = bufI[p3] ;
	matchedPair[3].q = bufQ[p3] ;
	
	q1 = [ self bpskEstimate2:&matchedPair[0] ] ;
	q2 = [ self bpskEstimate3:&matchedPair[0] ] ;
	q3 = [ self bpskEstimate4:&matchedPair[0] ] ;
	
	//  The dot product of two vectors is related to the cosine as
	//	a.b = |a|.|b|.cos(theta)
	//  For DPSK, |cos(theta)| should be 1.0.
	//	To get the "quality" of a bit, look at ( |a.b|/(|a|.|b|) ) for deviations away from 0 or 180 degrees.
	//  The bit quality is then used to modify a global quality number (reset elsewhere at the beginning of each character).
	
	dot = ai*bi + aq*bq ;
	q = sqrt( dot*dot/( ( ai*ai + aq*aq )*( bi*bi + bq*bq ) + 0.0000001 ) ) ;
	if ( q < quality ) quality = q ;
	
	//  return weighted sum of the three demodulators
	//	q3 is better with quiet conditions and q1 is better with multipath conditions
	
	//return q3 ;
	return ( 0.5*q1 + 0.3*q2 + 0.7*q3 ) ;
}

/* local v0.57 */
//  estimate the phase angle from a combination of matched filter, narrow matched filter and a single mid bit ssample
- (int)processBpskVector
{
	float matchedBit ;
	int result ;
	
	//  v0.57
	//  update the matched filter sequence (the matched ring buffer contains past matched filter values.
	matchedI[ring] = iMatched ;
	matchedQ[ring] = qMatched ;
	
	matchedBit = [ self bpskEstimate:matchedI imag:matchedQ ] ;
	
	result = ( matchedBit > 0.0 ) ? 1 : 0 ;
	
	[ self receivedBit:result ] ;
	
	//  update ring buffer index
	ring = ( ring+1 )&RING ;
	return result ;
}


//  v0.57 (copied from CoreModem to use the new decoders)
//
//  new analytic pair at 1000 s/s (32 samples per bit)
//  start is a flag that indicates the estimated boundary between data bits
//	(i.e., during a transition, the analytic pair at start should be very close to (0,0))
- (int)bpsk:(float)real imag:(float)imag bitSync:(Boolean)bitSync
{
	int result ;
	float h ;
	
	//  Matched filter input I/Q pair
	h = kernel[bitPhase & 0x3f] ;				//  v0.88 sanity check
	iMatched += h*real ;
	qMatched += h*imag ;

	bitPhase++ ;
	
	//  if bitSync is passed in from the client, we are ready to process this DPSK chip
	if ( bitSync ) {
		result = [ self processBpskVector ] ;
		// dump Matched Filter
		iMatched = qMatched = 0 ;
		bitPhase = 0 ;
	}
	//  update phase information if the delegate accepts it (for phase indicator)
	if ( delegate && bitPhase == 30 ) {	
		float t = atan2( imag, real ) ;
		phaseError = prevPhase - t ;
		prevPhase = t ;
		
		if ( phaseError > piBy2 ) phaseError = phaseError - pi ; else if ( phaseError < -piBy2 ) phaseError += pi ;
		if ( phaseError > piBy2 ) phaseError = phaseError - pi ; else if ( phaseError < -piBy2 ) phaseError += pi ;
		averagePhaseError = averagePhaseError*0.9 + phaseError*0.1 ;

		if ( phaseReportCycle == 1 ) [ delegate updateVCOPhase:averagePhaseError ] ;
		phaseReportCycle = ( phaseReportCycle+1 ) % 8 ;
	}

	return result ;
}

- (float)phaseError
{
	return phaseError ;
}

//  prototype for delegate
- (void)receivedBit:(int)bit quality:(float)quality
{
}

//  send current phase to delegate
- (void)receivedBit:(int)bit
{
	if ( delegate && [ delegate respondsToSelector:@selector(receivedBit:quality:) ] ) [ delegate receivedBit:bit quality:quality ] ;
	//  reset the quality figure for the next character (1.0 = good, 0.0 = bad)
	//  this is passed to the delegate in the -receivedBit:quality call (v0.57)
	quality = 1.0 ;
}


@end
