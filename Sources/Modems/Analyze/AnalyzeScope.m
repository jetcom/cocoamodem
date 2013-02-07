//
//  AnalyzeScope.m
//  cocoaModem
//
//  Created by Kok Chen on 3/4/05.
	#include "Copyright.h"
//

#import "AnalyzeScope.h"


@implementation AnalyzeScope

- (id)initWithFrame:(NSRect)frame 
{
	int i ;
	NSSize size ;
	float x, y, closedash[2] = { 1.0, 1.0 } ;
	
    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		bounds = [ self bounds ] ;
		size = bounds.size ;
		width = size.width ;
		height = size.height ;
		plotWidth = 512 ;
		plotOffset = 4 ;
		
		for ( i = 0; i < 256; i++ ) {
			refData[i] = dutData[i] = syncData[i] = markData[i] = spaceData[i] = 0 ;
		}
		
		background = [ [ NSBezierPath alloc ] init ] ;
		[ background appendBezierPathWithRect:bounds ] ;
		backgroundColor = [ NSColor colorWithDeviceRed:0 green:0.1 blue:0 alpha:1 ] ;
		[ backgroundColor retain ] ;
		
		//  set up waveform scale
		waveformColor = [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:1 ] ;
		[ waveformColor retain ] ;
		scaleColor = [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0 alpha:1 ] ;
		[ scaleColor retain ] ;
		baudotColor = [ NSColor colorWithCalibratedRed:0.7 green:0 blue:0 alpha:1 ] ;
		[ baudotColor retain ] ;
		
		waveformScale = [ [ NSBezierPath alloc ] init ] ;
		[ waveformScale setLineDash:closedash count:2 phase:0 ] ;
		y = height/2 + 0.5 ;
		[ waveformScale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
		[ waveformScale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		y = ( ( int )( height*0.125 ) ) + 0.5 ;
		[ waveformScale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
		[ waveformScale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		y = ( ( int )( height*0.875 ) ) + 0.5 ;
		[ waveformScale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
		[ waveformScale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		
		baudot = [ [ NSBezierPath alloc ] init ] ;
		for ( i = 1; i < 8; i++ ) {
			x = plotOffset + (int)( i*30.32*2 ) + 0.5 ;
			[ baudot moveToPoint:NSMakePoint( x, 10 ) ] ;
			[ baudot lineToPoint:NSMakePoint( x, height-10 ) ] ;
		}
		plotPath = nil ;
		
		for ( i = 0; i < 8; i++ ) {
			index[i] = (int)( i*30.32 + 30.32*0.5 + 0.5 ) ;
		}
	}
    return self ;
}

- (void)drawRect:(NSRect)frame
{
	if ( [ self lockFocusIfCanDraw ] ) {
		//  clear background
		[ backgroundColor set ] ;
		[ background fill ] ;
		//  insert scale
		[ scaleColor set ] ;
		[ waveformScale stroke ] ;
		//  baudot bit markers (30.32*2 pixels apart)
		[ baudotColor set ] ;
		[ baudot stroke ] ;
		//  insert graph
		if ( plotPath ) {
			[ waveformColor set ] ;
			[ plotPath stroke ] ;
		}
		[ self unlockFocus ] ;
	}
}

//  local
- (void)displayInMainThread
{
	[ self setNeedsDisplay:YES ] ;
}

- (void)updatePlot:(int)which
{
	float *data, yoffset, ygain, xgain, x, y ;
	int i ;
	
	//  check if update is needed and which mode
	
	switch ( which ) {
	case 0:
	default:
		data = refData ;
		break ;
	case 1:
		data = dutData ;
		break ;
	case 2:
		data = markData ;
		break ;
	case 3:
		data = spaceData ;
		break ;
	case 4:
		data = syncData ;
		break ;
	case 5:
		data = compensatedData ;
		break ;
	case 6:
		data = markProjection ;
		break ;
	case 7:
		data = spaceProjection ;
		break ;
	}
	//  create new plot
	yoffset = height/2 ;
	ygain = -yoffset*0.75 ;
	xgain = 2 ;
		
	if ( plotPath ) [ plotPath release ] ;
	plotPath = [ [ NSBezierPath alloc ] init ] ;
	for ( i = 0; i < 256; i++ ) {
		x = plotOffset + i*xgain ;
		y = yoffset - data[i]*ygain ;
		if ( y >= height ) y = height-1 ; else if ( y < 0 ) y = 0 ;
		if ( i == 0 ) [ plotPath moveToPoint:NSMakePoint( x, y ) ] ; else [ plotPath lineToPoint:NSMakePoint( x, y ) ] ;
	}
	printf( "In Analyze\n" ) ;
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)addReference:(CMATCPair*)data
{
	int i ;
	float a, t, scale ;
	
	scale = fabs( data[0].mark - data[0].space ) + .001 ;
	for ( i = 0; i < 256; i++ ) {
		t = data[i].mark - data[i].space ;
		a = fabs( t ) ;
		if ( a > scale ) scale = a ;
		refData[i] = t ;
	}
	scale = 1.0/scale ;
	for ( i = 0; i < 256; i++ ) refData[i] *= scale ;
}

- (void)addDUT:(CMATCPair*)data
{
	int i ;
	float a, t, scale ;
	
	scale = fabs( data[0].mark - data[0].space ) + .001 ;
	for ( i = 0; i < 256; i++ ) {
		t = data[i].mark - data[i].space ;
		a = fabs( t ) ;
		if ( a > scale ) scale = a ;
		dutData[i] = t ;
	}
	scale = 1.0/scale ;
	for ( i = 0; i < 256; i++ ) {
		dutData[i] *= scale ;
		markData[i] = data[i].mark * scale*2 - 1.0 ;
		spaceData[i] = data[i].space * scale*2 - 1.0 ;
	}
}

- (void)addCompensated:(CMATCPair*)data
{
	int i, j ;
	float a, scale, t ;
	
	scale = fabs( data[0].mark - data[0].space ) + .001 ;
	for ( i = 0; i < 256; i++ ) {
		t = data[i].mark - data[i].space ;
		a = fabs( t ) ;
		if ( a > scale ) scale = a ;
	}
	scale = 1.0/scale ;

	for ( i = 0; i < 256; i++ ) {
		if ( ( data[i].mark * scale*2 - 1.0 )*( data[i].space * scale*2 - 1.0 ) < 0 ) {
			compensatedData[i] = ( ( data[i].mark * scale*2 - 1.0 ) > 0 ) ? 1.0 : -1.0 ;
		}
		else {
			compensatedData[i] = 0 ;
		}
		
		//  index[2] is bit 0
		for ( j = 2; j < 7; j++ ) {
			if ( compensatedData[index[j]] == 0 ) {
				//  indeterminate bit
				if ( compensatedData[index[j-1]]*compensatedData[index[j+1]] < 1 ) {
									
					compensatedData[index[j]] = compensatedData[index[j+1]]*0.5 ;
					compensatedData[index[j]-1] = compensatedData[index[j+1]]*0.5 ;
					compensatedData[index[j]+1] = compensatedData[index[j+1]]*0.5 ;
				}
			}
		}
		
		markProjection[i] = ( data[i].mark * scale*2 - 1.0 ) ;
		spaceProjection[i] = ( data[i].space * scale*2 - 1.0 ) ;
	}
}

- (void)addSync:(float*)data
{
	int i ;
	
	for ( i = 0; i < 256; i++ ) {
		syncData[i] = data[i] ;
	}
}

@end
