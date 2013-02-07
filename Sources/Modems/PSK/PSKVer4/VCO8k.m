//
//  VCO8k.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/13/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "VCO8k.h"


@implementation VCO8k

#undef CMFs
#define CMFs	8000.0			//  use 8000 samples/sec rate

//   Phase Controlled Oscillator

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		carrier = 1000.0*kPeriod/CMFs ;
		scale = 1.0 ;
		delegate = nil ;
	}
	return self ;
}

- (void)setCarrier:(float)freq 
{
	carrier = freq*kPeriod/CMFs ;
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

//  delegates
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate ;
}

- (id)delegate
{
	return delegate ;
}

@end
