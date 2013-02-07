//
//  MSKGenerator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/21/06.
	#include "Copyright.h"
	
#import "MSKGenerator.h"
#include "CoreModemTypes.h"


@implementation MSKGenerator

//  static sin/cos tables
extern float *mssin, *lssin, *mscos, *lscos ;

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		needNewBit = YES ;
		cycle = 0 ;
	}
	return self ;
}

- (void)setBaudRate:(float)rate
{
	baudRate = rate ;
	baudDelta = baudRate*kPeriod/CMFs ;
	//  v0.33
	cycle = 0 ;
	bitTheta = 0.0 ;
}

- (Boolean)needNewBit
{
	return needNewBit ;
}

- (Boolean)advanceBitSample
{
	bitTheta += baudDelta ;
	
	needNewBit = ( bitTheta >= kPeriod ) ;
	if ( needNewBit ) {
		cycle = ( cycle+1 )&0x3 ;
		bitTheta -= kPeriod ;
		return YES ;
	}
	return NO ;
}

- (float)sinForModulation
{
	int t, mst, lst ;
	
	t = ( bitTheta + cycle*kPeriod )*0.25 ;
	mst = ( t >> kBits ) & kMask ;
	lst = t & kMask ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	return ( mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] ) ;
}

- (float)cosForModulation
{
	int t, mst, lst ;
	
	t = ( bitTheta + cycle*kPeriod )*0.25 ;
	mst = ( t >> kBits ) & kMask ;
	lst = t & kMask ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	return ( mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] ) ;
}

@end
