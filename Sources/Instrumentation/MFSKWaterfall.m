//
//  MFSKWaterfall.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/28/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSKWaterfall.h"


@implementation MFSKWaterfall

- (id)initWithFrame:(NSRect)frame 
{
	self = [ super initWithFrame:frame ] ;
	if ( self ) {
		[ self setSpread:15*15.625 ] ;		//  lowest to highest tone for MFSK16
	}
	return self ;
}

- (void)drawMarkers
{
	float p ;
	
	//  additional drawing here
	if ( click > 0 ) {
		p = click+0.5 ;
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:green ] ;

		p = click+spread+0.5 ;
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:green ] ;
	}
}

@end
