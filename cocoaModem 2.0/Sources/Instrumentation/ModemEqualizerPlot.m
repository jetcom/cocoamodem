//
//  ModemEqualizerPlot.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/30/06.
	#include "Copyright.h"
	
	
#import "ModemEqualizerPlot.h"


@implementation ModemEqualizerPlot

- (id)initWithFrame:(NSRect)frame 
{
	NSSize size ;
	int i,n ;
	float x, dash[2] = { 2.0, 1.0 }, xp[41] ;
	
    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		bounds = [ self bounds ] ;
		size = bounds.size ;
		width = size.width ;
		height = size.height ;

		plotColor = [ [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0 alpha:1 ] retain ] ;
		plot = nil ;
		
		//  background
		backgroundColor = [ [ NSColor colorWithDeviceRed:0 green:0.1 blue:0 alpha:1 ] retain ] ;
		background = [ [ NSBezierPath alloc ] init ] ;
		[ background appendBezierPathWithRect:bounds ] ;
		//  scale
		scaleColor = [ [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:1 ] retain ] ;
		scale = [ [ NSBezierPath alloc ] init ] ;
		[ scale setLineDash:dash count:2 phase:0 ] ;
		for ( i = 0; i < 4; i++ ) {
			n = ( 0.1 + i*0.24 )*width ;
			x = n + 0.5 ;
			[ scale moveToPoint:NSMakePoint( x, 0 ) ] ;
			[ scale lineToPoint:NSMakePoint( x, height ) ] ;
		}
		for ( i = 0; i < 41; i++ ) xp[i] = i*0.1 ;	//  flat response 
		[ self setResponse:xp ] ;
	}
	return self ;
}

//  accepts a response curve (dB) from 400 Hz to 2400 Hz inclusive (81 samples) at 25 Hz resolution
- (void)setResponse:(float*)array
{
	int i ;
	float x, y ;
	
	if ( plot ) [ plot release ] ;
	plot = [ [ NSBezierPath alloc ] init ] ;
	for ( i = 0; i < 81; i++ ) {
		x = ( 0.1 + array[i]*0.24 )*width ;
		y = height*( 1.0 - i/82.0 ) - 8.0 ;
		if ( i == 0 ) [ plot moveToPoint:NSMakePoint( x, y ) ] ; else [ plot lineToPoint:NSMakePoint( x, y ) ] ;
	}
}

- (void)drawRect:(NSRect)frame
{
	[ backgroundColor set ] ;
	[ background fill ] ;
	//  insert scale
	[ scaleColor set ] ;
	[ scale stroke ] ;
	if ( plot ) {
		//  insert plot
		[ plotColor set ] ;
		[ plot stroke ] ;
	}
}

@end
