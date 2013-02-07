//
//  CMPCO.m
//  CoreModem
//
//  Created by Kok Chen on 11/02/05
//	Based on cocoaModem, original file dated Mon Aug 09 2004.
	#include "Copyright.h"
	

#import "CMPCO.h"
#include "CoreModemTypes.h"


@implementation CMPCO

//   Phase Controlled Oscillator

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		carrier = 1000.0*kPeriod/CMFs ;
		frequency = 1000 ;
		scale = 1.0 ;
		delegate = nil ;
	}
	return self ;
}

- (void)setCarrier:(float)freq 
{
	carrier = freq*kPeriod/CMFs ;
	frequency = freq ;
}

- (float)frequency
{
	return carrier*CMFs/kPeriod ;
}

- (void)tune:(float)freq
{
	carrier += freq*kPeriod/CMFs ;
	[ self vcoChangedTo:carrier*CMFs/kPeriod ] ;
}

- (void)tune:(float)freq phase:(float)angle
{
	carrier += freq*kPeriod/CMFs ;
	theta += angle*kPeriod/360.0 ;
	if ( theta >= kPeriod ) theta -= kPeriod ;
}

- (void)adjustPhase:(float)angle
{
	theta += angle*kPeriod/360.0 ;
	if ( theta >= kPeriod ) theta -= kPeriod ;
}

- (CMAnalyticPair)nextVCOPair
{
	CMAnalyticPair p ;
	double re, im ;
	
	[ self sin:&re cos:&im delta:carrier ] ;
	p.re = re ;
	p.im = im ;
	return p ;
}

- (CMAnalyticPair)nextVCOMixedPair:(float)v
{
	CMAnalyticPair p ;
	double re, im ;
	
	[ self sin:&re cos:&im delta:carrier ] ;
	p.re = re*v ;
	p.im = im*v ;
	return p ;
}

- (double)nextSample
{
	double i, q ;
	
	[ self sin:&q cos:&i delta:carrier ] ;
	return q ;
}

//  delegates
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate ;
}

- (id)delegate
{
	return delegate ;
}

- (void)vcoChangedTo:(float)vcoFreq
{
	if ( delegate && [ delegate respondsToSelector:@selector(vcoChangedTo:) ] ) [ delegate vcoChangedTo:vcoFreq ] ;
}

@end
