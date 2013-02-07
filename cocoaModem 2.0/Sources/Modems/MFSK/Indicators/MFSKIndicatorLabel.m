//
//  MFSKIndicatorLabel.m
//  cocoaModem
//
//  Created by Kok Chen on Jan 30 2007.
	#include "Copyright.h"
//

#import "MFSKIndicatorLabel.h"
#include "DisplayColor.h"

//  Draw fixed tick marks (16 ticks with 16 pixels separation)
@implementation MFSKIndicatorLabel

- (void)awakeFromNib
{
	NSRect bounds ;
	NSSize bsize ;

	offset = 5*16 ;
	locked = YES ;
	bounds = [ self bounds ] ;
	bsize = bounds.size ;
	width = bsize.width ;  
	height = bsize.height ;  
	background = [ [ NSBezierPath alloc ] init ] ;
	[ background appendBezierPathWithRect:bounds ] ;
	color = [ [ NSColor colorWithCalibratedRed:0.95 green:0 blue:0 alpha:1 ] retain ] ;
	bins = 16 ;
}

//	v0.73	for setting to DominoEX bins
- (void)setBins:(int)value
{
	bins = value ;
	//[ self setNeedsDisplay:YES ] ;
	[ self display ] ;				// v0.73
}

- (BOOL)isOpaque
{
	return YES ;
}

//  zero if not locked
- (void)setOffset:(int)index
{
	if ( index < 0 ) return ;
	
	if ( index == 0 && locked ) {
		locked = NO ;
		[ self setNeedsDisplay:YES ] ;
		return ;
	}
	if ( index != offset && index != 0 ) {
		offset = index ;
		locked = YES ;
		[ self display ] ;
		return ;
	}
}

//	Used by DominoEX which does not need a lock indication
- (void)setAbsoluteOffset:(int)index
{
	if ( index < 0 ) return ; 
	
	if ( index != offset ) {
		offset = index ;
		locked = YES ;
		[ self display ] ;
		return ;
	}
}

- (void)clear
{
	locked = NO ;
	offset = 5*16 ;
	[ self setNeedsDisplay:YES ] ;
}

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *line ;
	float p ;
	int i ;
	
	[ [ NSColor blackColor ] set ] ;
	[ background fill ] ;
	
	line = [ NSBezierPath bezierPath ] ;
	[ line setLineWidth:1 ] ;
	p = offset - 8.5 ;		// tick marks between bins
	for ( i = 0; i < bins+1; i++ ) {
		[ line moveToPoint:NSMakePoint( p, 1 ) ] ;
		[ line lineToPoint:NSMakePoint( p, height-1 ) ] ;
		p += 16.0 ;
	}
	[ color set ] ;
	[ line stroke ] ;
}


@end
