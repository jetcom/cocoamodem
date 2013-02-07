//
//  FrequencyIndicator.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Sep 02 2004.
	#include "Copyright.h"
//

#import "FrequencyIndicator.h"
#include "DisplayColor.h"


@implementation FrequencyIndicator

- (void)awakeFromNib
{
	NSSize bsize ;
	int i, lsize, transformSize ;
	UInt32 bg ;
		
	//  check window depth
	depth = NSBitsPerPixelFromDepth( [ NSWindow defaultDepthLimit ] ) ;  //  m = 24, t = 12, 256 = 8

	sideband = NO ;

	bsize = [ self bounds ].size ;
	width = bsize.width ;  
	height = bsize.height ;  
	
	transformSize = 256 ;

	thread = [ NSThread currentThread ] ;
	[ self setRange:60.0 ] ;
	
	if ( depth >= 24 ) {
		bg = intensity[0] ;
		//  Uses 32 bit/pixel for millions of colors mode, all components of a pixel can then be written with a single int write.
		rowBytes = width*4 ;
		lsize = size = rowBytes*height/4 ;
		bitmap = ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes: NULL 
					pixelsWide:width pixelsHigh:height
					bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rowBytes bitsPerPixel:32 ] ;
	}
	else {
		bg = ( intensity[0] << 16 ) | intensity[0] ;
		rowBytes = ( ( width*2 + 3 )/4 ) * 4 ;
		lsize = ( size = rowBytes*height/2 )/2 ;
		//  Uses 16 bit/pixel for thousands of colors mode, all components of a pixel can then be written with a single short write.
		bitmap = ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes: NULL 
					pixelsWide:width pixelsHigh:height
					bitsPerSample:4 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rowBytes bitsPerPixel:16 ] ;
		
	}
	
	if ( bitmap ) {
		[ bitmap retain ] ;
		pixel = ( UInt32* )[ bitmap bitmapData ] ;
		for ( i = 0; i < lsize; i++ ) pixel[i] = bg ;
		image = [ [ NSImage alloc ] init ] ;
		[ image addRepresentation:bitmap ] ;
		[ self setImageScaling:NSScaleNone ] ;
		[ self setImage:image ] ;
	}
}

- (BOOL)isOpaque
{
	return YES ;
}

//  0 = LSB
- (void)setSideband:(int)state
{
	sideband = ( state == 1 ) ;
}

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *line ;
	float p ;
	
	[ super drawRect:rect ] ;
	line = [ NSBezierPath bezierPath ] ;
	[ line setLineWidth:1 ] ;
	p = width/2 - 15.5 ;
	[ line moveToPoint:NSMakePoint( p, 0 ) ] ;
	[ line lineToPoint:NSMakePoint( p, 4 ) ] ;
	[ line moveToPoint:NSMakePoint( p, height ) ] ;
	[ line lineToPoint:NSMakePoint( p, height-4 ) ] ;
	p = width/2 + 0.5;
	[ line moveToPoint:NSMakePoint( p, 0 ) ] ;
	[ line lineToPoint:NSMakePoint( p, height ) ] ;
	p = width/2 + 16.5 ;
	[ line moveToPoint:NSMakePoint( p, 0 ) ] ;
	[ line lineToPoint:NSMakePoint( p, 4 ) ] ;
	[ line moveToPoint:NSMakePoint( p, height ) ] ;
	[ line lineToPoint:NSMakePoint( p, height-4 ) ] ;
	[ [ NSColor redColor ] set ] ;
	[ line stroke ] ;
}

- (void)setRange:(float)value
{
	NSColor *a, *b, *c, *d ;
	float v, map, inten, p ;
	float r0, g0, b0, a0, r1, g1, b1, a1 ;
	int i ;
	
	exponent = 0.25 ;
	range = value ;
	if ( range > 79 ) p = 1.0 ;
	else {
		if ( range > 59 ) p = 1.414 ;
		else {
			if ( range > 39 ) p = 2.0 ;
			else p = 2.818 ;
		}
	}
	//  create color scale, defined by 4 colors
	//  use a 20000 element table to achieve 85 dB of dynamic range
	a = [ NSColor colorWithCalibratedRed:0.0 green:0 blue:0.2 alpha:0 ] ;
	b = [ NSColor colorWithCalibratedRed:0 green:0.0 blue:0.8 alpha:0 ] ;
	c = [ NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.5 alpha:0 ] ;
	d = [ NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0 alpha:0 ] ;
	
	for ( i = 0; i < 20000; i++ ) {
		map = pow( i/20000.0, p )*2 ;
		if ( map > 1 ) map = 1 ;
		inten = 1.0 ;
		if ( map < .3 ) {
			v = map/.3 ;
			[ a getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
			[ b getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
		}
		else {
			if ( map < 0.95 ) {
				v = ( map-.3 )/0.65 ;
				[ b getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
				[ c getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
			}
			else {
				v = ( map-0.95 )/0.05 ;
				[ c getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
				[ d getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
			}
		}
		r0 = inten*( ( 1.0-v )*r0 + v*r1 ) ;
		g0 = inten*( ( 1.0-v )*g0 + v*g1 ) ;
		b0 = inten*( ( 1.0-v )*b0 + v*b1 ) ;
		
		if ( depth >= 24 ) {
			intensity[i] = [ DisplayColor millionsOfColorsFromRed:r0 green:g0 blue:b0 ] ;
		}
		else {
			intensity[i] = [ DisplayColor thousandsOfColorsFromRed:r0 green:g0 blue:b0 ] ;
		}
	}
}

- (int)plotValue:(float)sample
{
	return pow( sample, exponent ) * 20000.0 ;
}

- (void)displayInMainThread
{
	//[ self setNeedsDisplay:YES ] ;
	[ self display ] ;						//  v0.73
}

// v0.57 - n changed to 1024 for 1000s/sec sampling rate
- (void)newSpectrum:(DSPSplitComplex*)spec size:(int)n
{
	float g[256 /* at least width */], p, q, *re, *im, norm, min, max ;  // needs to be larger than width!
	char *src, *insert ;
	int i, m, index ;
	UInt32 *line ;
	UInt16 *sline ;
	
	if ( n != 1024 ) return ;
	
	re = spec->realp ;
	im = spec->imagp ;
	m = width/2 ;			//  0.32 bug fix (was 192)
	for ( i = 0; i < m; i++ ) {
		p = re[i] ;
		q = im[i] ;
		g[width/2+i] = p*p + q*q ;
	}
	for ( i = 1; i <= m; i++ ) {
		p = re[1024-i] ;
		q = im[1024-i] ;
		g[width/2-i] = p*p + q*q ;
	}
	min = max = g[0] ;
	for ( i = 1; i < width; i++ ) if ( g[i] > max ) max = g[i] ; else if ( g[i] < min ) min = g[i] ;
	norm = 1.0/( max - min + .001 ) ;
	for ( i = 0; i < width; i++ ) g[i] = ( g[i]-min )*norm ;
	
	src = ( ( char* )pixel ) + rowBytes ;
	memcpy( pixel, src, rowBytes*( height-1 ) ) ;
	insert = ( ( char* )pixel ) + rowBytes*( height-1 ) ;
	
	if ( sideband ) {
		if ( depth >= 24 ) {
			line = (UInt32*)( insert ) ;
			for ( i = 0; i < width; i++ ) {
				index = [ self plotValue:g[i] ] ;
				if ( index > 19999 ) index = 19999 ;
				line[i] = intensity[index] ;
			}
		}
		else {
			sline = (UInt16*)( insert ) ;
			for ( i = 0; i < width; i++ ) {
				index = [ self plotValue:g[i] ] ;
				if ( index > 19999 ) index = 19999 ;
				sline[i] = intensity[index] ;
			}
		}
	}
	else {
		if ( depth >= 24 ) {
			line = (UInt32*)( insert ) ;
			for ( i = 0; i < width; i++ ) {
				index = [ self plotValue:g[width-i-1] ] ;
				if ( index > 19999 ) index = 19999 ;
				line[i] = intensity[index] ;
			}
		}
		else {
			sline = (UInt16*)( insert ) ;
			for ( i = 0; i < width; i++ ) {
				index = [ self plotValue:g[width-i-1] ] ;
				if ( index > 19999 ) index = 19999 ;
				sline[i] = intensity[index] ;
			}
		}
	}
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)clear
{
	char *s ;
	UInt32 *line, value ;
	UInt16 *sline ;
	int i ;
	
	value = intensity[0] ;
	if ( depth >= 24 ) {
		line = (UInt32*)( pixel ) ;
		for ( i = 0; i < width; i++ ) line[i] = value ;
	}
	else {
		sline = (UInt16*)( pixel ) ;
		for ( i = 0; i < width; i++ ) sline[i] = value ;
	}

	s = ( (char*)pixel ) + rowBytes ;
	for ( i = 1; i < height; i++ ) {
		memcpy( s, pixel, rowBytes ) ;
		s += rowBytes ;
	}
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}


@end
