//
//  CMNCO.m
//  CoreModem
//
//  Created by Kok Chen on Tue Jun 29 2004.
	#include "Copyright.h"
//

#import "CMNCO.h"
#include "CoreModem.h"
#include "CoreModemTypes.h"


@implementation CMNCO

//  Numerically controlled oscillator 

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		theta = bitTheta = 0 ;
		lock = [ [ NSLock alloc ] init ] ;
		scale = 0.1 ;
		producer = consumer = 0 ;
		modulate = 0 ;
	}
	return self ;
}

- (void)setOutputScale:(float)value
{
	scale = value ;
}

//  modulation DDA return true if changed
- (Boolean)modulation:(double)delta
{
	double th ;
	
	th = ( bitTheta += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		bitTheta = th ;
		return YES ;
	}
	return NO ;
}

//  use double angle formula to compute sin(t)
//  NOTE: delta must be less than kPeriod and greater than or equal to 0
- (float)sin:(double)delta
{
	int t, mst, lst ;
	double th ;
	
	th = ( theta += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta = th ;
	}
	t = th ;
	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	return ( mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] )*scale ;
}

//  use double angle formula to compute cos(t)
//  NOTE: delta must be less than kPeriod and greater than or equal to 0
- (float)cos:(double)delta
{
	int t, mst, lst ;
	double th ;
	
	th = ( theta += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta = th ;
	}
	t = th ;
	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	return ( mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] )*scale ;
}

- (void)sin:(double*)sine cos:(double*)cosine delta:(double)delta
{
	int t, mst, lst ;
	double th ;
	
	th = ( theta += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta = th ;
		while ( th > kPeriod ) {
			th -= kPeriod ;
			theta = th ;
		}
	}
	else if ( th < 0 ) {
		th += kPeriod ;
		theta = th ;
		while ( th < kPeriod ) {
			th += kPeriod ;
			theta = th ;
		}
	}
	t = th ;
	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	//*sine = ( mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] )*scale ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	//*cosine = ( mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] )*scale ;
	
	//  v0.76 performance tune
	double sina = mssin[mst] ;
	double cosa = mscos[mst] ;
	double sinb = lssin[lst] ;
	double cosb = lscos[lst] ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	*sine = ( sina*cosb + cosa*sinb )*scale ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	*cosine = ( cosa*cosb - sina*sinb )*scale ;

}


@end
