//
//  MFSKIndicator.m
//  cocoaModem
//
//  Created by Kok Chen on Jan 30 2007.
	#include "Copyright.h"
//

#import "MFSKIndicator.h"
#include "DisplayColor.h"


@implementation MFSKIndicator

- (void)awakeFromNib
{
	NSSize bsize ;
	int i, lsize ;
	UInt32 bg ;
		
	//  check window depth
	depth = NSBitsPerPixelFromDepth( [ NSWindow defaultDepthLimit ] ) ;  //  m = 24, t = 12, 256 = 8

	cycle = 0 ;

	bsize = [ self bounds ].size ;
	width = bsize.width ;  
	height = bsize.height ;  
	if ( width > 512 ) width = 512 ;	//  array limit
	
	thread = [ NSThread currentThread ] ;
	[ self setScale:24.0 ] ;
	
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

- (void)setScale:(float)f
{
	NSColor *a, *b, *c, *d ;
	float v, map, inten, p ;
	float r0, g0, b0, a0, r1, g1, b1, a1 ;
	int i ;
	
	exponent = 0.25 ;
	p = scale = f ;
	//  create color scale, defined by 4 colors
	a = [ NSColor colorWithCalibratedRed:0.0 green:0 blue:0.2 alpha:0 ] ;
	b = [ NSColor colorWithCalibratedRed:0 green:0.0 blue:0.8 alpha:0 ] ;
	c = [ NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.5 alpha:0 ] ;
	d = [ NSColor colorWithCalibratedRed:0.8 green:0.7 blue:0 alpha:0 ] ;
	
	for ( i = 0; i < 20000; i++ ) {
		map = pow( i/20000.0, p )*4 ;
		if ( map > 1 ) map = 1 ;
		inten = 1.0 ;
		if ( map < .3 ) {
			v = map/.3 ;
			[ a getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
			[ b getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
		}
		else {
			if ( map < 0.97 ) {
				v = ( map-.3 )/0.67 ;
				[ b getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
				[ c getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
			}
			else {
				v = ( map-0.97 )/0.03 ;
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

- (void)newSpectrum:(float*)spec width:(int)slots
{
	float g[512], norm, min, max ;
	char *src, *insert ;
	int i, index ;
	UInt32 *line ;
	UInt16 *sline ;
	
	if ( slots >= width-2 ) slots = width-2 ;
	
	//  make copy of input spectrum
	//  if the input spectrum is shorter than width, zero fill the remainder
	g[0] = g[1] = 0 ;
	for ( i = 2; i < slots; i++ ) g[i] = spec[i] ;
	for ( ; i < width; i++ ) g[i] = 0 ;
	
	min = max = g[0] ;
	for ( i = 1; i < width; i++ ) if ( g[i] > max ) max = g[i] ; else if ( g[i] < min ) min = g[i] ;
	norm = 1.0/( max - min + .001 ) ;
	for ( i = 0; i < width; i++ ) g[i] = ( g[i]-min )*norm ;
	if ( cycle == 0 ) {
		//  init accumulator
		cycle = 1 ;
		for ( i = 0; i < width; i++ ) saved[i] = g[i] ;
		return ;
	}
	if ( cycle < 5 ) {
		//  accumulate
		for ( i = 0; i < width; i++ ) {
			if ( saved[i] < g[i] ) saved[i] = g[i] ;
		}
		cycle++ ;
		return ;
	}
	else {
		for ( i = 0; i < width; i++ ) {
			if ( saved[i] > g[i] ) g[i] = saved[i] ;
		}
		cycle = 0 ;
	}
	src = ( ( char* )pixel ) + rowBytes ;
	memcpy( pixel, src, rowBytes*( height-1 ) ) ;
	insert = ( ( char* )pixel ) + rowBytes*( height-1 ) ;
	
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
	[ self performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO ] ;		//  v0.73 -- was displayInMainThread
}

// accept a 384 point power spectrum and display it
- (void)newSpectrum:(float*)spec
{
	[ self newSpectrum:spec width:384 ] ;
}

// accept a 512 point power spectrum and display it
- (void)newWideSpectrum:(float*)spec
{
	[ self newSpectrum:spec width:448 ] ;
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
	[ self performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO ] ;
}


@end
