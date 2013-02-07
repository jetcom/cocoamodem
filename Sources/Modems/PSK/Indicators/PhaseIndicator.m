//
//  PhaseIndicator.m
//  cocoaModem
//
//  Created by Kok Chen on Tue Sep 07 2004.
	#include "Copyright.h"
//

#import "PhaseIndicator.h"
#include "DisplayColor.h"


@implementation PhaseIndicator

- (BOOL)isOpaque
{
	return YES ;
}

- (void)awakeFromNib
{
	NSSize bsize ;

	bounds = [ self bounds ] ;
	bsize = bounds.size ;
	width = bsize.width ;  
	height = bsize.height ; 
	xpos = -1 ; 
	yellow = [ [ NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.0 alpha:1.0 ] retain ] ;
	black = [ [ NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.1 alpha:1.0 ] retain ] ;
}

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *path ;

	[ black set ] ;
	path = [ NSBezierPath bezierPathWithRect:bounds ] ;
	[ path fill ] ;

	if ( xpos > 0 ) {
		[ yellow set ] ;
		path = [ NSBezierPath bezierPath ] ;
		[ path setLineWidth:1.5 ] ;
		[ path moveToPoint:NSMakePoint( xpos, 0 ) ] ;
		[ path lineToPoint:NSMakePoint( xpos, height ) ] ;
		[ path stroke ] ;
	}
	[ super drawRect:rect ] ;
}

- (void)displayInMainThread
{
	//[ self setNeedsDisplay:YES ] ;
	[ self display ] ;					//  v0.73
}

//  radian is angle between -pi/2 to +pi/2
- (void)newPhase:(float)radian
{
	int previous ;
	
	if ( radian < -1.5708 || radian > 1.5708 ) return ;
	
	previous = xpos ;	
	xpos = ( radian + 1.5708 )/3.14145926*width + 0.5 ;
	if ( xpos != previous ) [ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)clear
{
	xpos = -1 ;
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ];
}
@end
