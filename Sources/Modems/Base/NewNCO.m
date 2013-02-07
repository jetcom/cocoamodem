//
//  NewNCO.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/20/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "NewNCO.h"
#include "CoreModem.h"		//  for sin/cos table


@implementation NewNCO

//  v0.73 Subclassed CMNCO to allow start of transmission to be at 0 phase

- (float)sin:(double)delta
{
	int t, mst, lst ;
	double th, p ;
	
	t = theta ;
	if ( t > kPeriod ) t -= kPeriod ;
	
	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	p = ( mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] )*scale ;
	
	//  increment after computing sine
	th = ( theta += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta = th ;
	}
	return p ;
}

- (float)cos:(double)delta
{
	int t, mst, lst ;
	double th, p ;
	
	t = theta ;
	if ( t > kPeriod ) t -= kPeriod ;

	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	p = ( mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] )*scale ;

	th = ( theta += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta = th ;
	}
	return p ;
}

- (void)resetPhase
{
	theta = 0 ;
}


@end
