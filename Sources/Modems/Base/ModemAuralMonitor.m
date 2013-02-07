//
//  ModemAuralMonitor.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/12/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ModemAuralMonitor.h"
#import "Application.h"


@implementation ModemAuralMonitor

extern float *mssin, *lssin, *mscos, *lscos ;

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		auralMonitor = [ [ NSApp delegate ] auralMonitor ] ;
		muted = YES ;
		masterGain = 1.0 ;
		clickBufferActive = NO ;		//  v0.88
		resampleClickBuffer = NO ;
	}
	return self ;
}

//  v0.88 set from modems to indicate the click buffer is active (buffer rates higher than real time)
- (void)setClickBufferActive:(Boolean)state
{
	clickBufferActive = state ;
}

- (void)setClickBufferResampling:(Boolean)state
{
	resampleClickBuffer = state ;
}

//  v0.88
- (Boolean)clickBufferBusy
{
	return clickBufferActive ;
}

//  v0.88
- (Boolean)performClickBufferResampling
{
	return resampleClickBuffer ;
}

//  theta is scaled so that a 0 represents 0 degrees and a full 16 bit number represents 2.pi degrees
- (void)setDDA:(CMDDA*)dda freq:(float)freq
{
	dda->freq = freq ;
	dda->deltaTheta = ( 262144.0 )*freq/CMFs ;
	dda->theta = 0.0 ;
	dda->cost = 1.0 ;
	dda->sint = 0.0 ;
}


//  update sine and cosine to the next time sample
//  return sine
- (CMAnalyticPair)updateDDA:(CMDDA*)dda
{
	int t, mst, lst ;
	double th ;
	CMAnalyticPair p ;
	
	th = ( dda->theta += dda->deltaTheta ) ;
	if ( th > 262144.0 ) {
		th -= 262144.0 ;
		dda->theta = th ;
	}
	t = th ;
	mst = ( t >> 10 ) ;
	lst = t & 0x3ff ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	//dda->sint = mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	//dda->cost = mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] ;

	//  v0.76 performance tune
	double sina = mssin[mst] ;
	double cosa = mscos[mst] ;
	double sinb = lssin[lst] ;
	double cosb = lscos[lst] ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	dda->sint = sina*cosb + cosa*sinb ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	dda->cost = cosa*cosb - sina*sinb ;
	
	p.re = dda->cost ;
	p.im = dda->sint ;
	return ( p ) ;
}


@end
