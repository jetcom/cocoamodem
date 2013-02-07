//
//  Spectrum.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Feb 3 2005.
	#include "Copyright.h"
//

#import "Spectrum.h"
#include "CMDSPWindow.h"

@implementation Spectrum



//  spectrum view is 818 wide x 96 tall
- (id)initWithFrame:(NSRect)frame 
{
	int i ;
	NSSize size ;
	float x, y, dash[2] = { 1.0, 2.0 } ;

    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		bounds = [ self bounds ] ;
		size = bounds.size ;
		width = size.width ;
		height = size.height ;
		plotWidth = 818 ;
		scale = plotWidth/408 ;
		pixPerdB = 1.25 ;
		mux = 0 ;
		
		alpha = 1.0 ;
		dynamicRangeScale = 10.0 ;
		dynamicRangeOffset = 56 ;
		
		for ( i = 0; i < 512; i++ ) smoothedSpectrum[i] = 0 ;
		
		path = nil ;
		background = [ [ NSBezierPath alloc ] init ] ;
		[ background appendBezierPathWithRect:bounds ] ;
		[ ( backgroundColor = [ NSColor colorWithDeviceRed:0 green:0.1 blue:0 alpha:1 ] ) retain ] ;
		
		//  set up spectrum scale
		[ ( spectrumColor = [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0 alpha:1 ] ) retain ] ;
		spectrumScale = [ [ NSBezierPath alloc ] init ] ;
		[ spectrumScale setLineDash:dash count:2 phase:0 ] ;
		for ( i = 5; i < 80; i += 30 ) {
			y = (int)( height - ( i*pixPerdB ) ) + 0.5 ;
			if ( y <= 0 ) break ;
			[ spectrumScale moveToPoint:NSMakePoint( 0, y ) ] ;
			[ spectrumScale lineToPoint:NSMakePoint( plotWidth, y ) ] ;
		}
		for ( i = 500; i < 3000; i += 500 ) {
			x = ( int )( ( i-400 )*plotWidth/2200.0 ) + 0.5 ;
			[ spectrumScale moveToPoint:NSMakePoint( x, 0 ) ] ;
			[ spectrumScale lineToPoint:NSMakePoint( x, height ) ] ;
		}
		//  set up scale color
		[ ( scaleColor = [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:1 ] ) retain ] ;
				
		//  set up mark/space scales
		[ ( markSpaceColor = [ NSColor colorWithCalibratedRed:0.88 green:0.15 blue:0 alpha:1 ] ) retain ] ;
		markSpace = [ [ NSBezierPath alloc ] init ] ;
		//[ markSpace setLineDash:closedash count:2 phase:0 ] ;
		x = ( int )( ( 2125-400 )*plotWidth/2200.0 ) + 0.5 ;
		[ markSpace moveToPoint:NSMakePoint( x, 8 ) ] ;
		[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
		x = ( int )( ( 2295-400 )*plotWidth/2200.0 ) + 0.5 ;
		[ markSpace moveToPoint:NSMakePoint( x, 8 ) ] ;
		[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;

		//  initialize spectrum fft (use vDSP)
		spectrum = FFTSpectrum( 11, YES ) ;
		busy = NO ;
		
		thread = [ NSThread currentThread ] ;
    }
    return self ;
}

- (BOOL)isOpaque
{
	return YES ;
}

- (void)setTimeConstant:(float)t dynamicRange:(float)dr
{
	alpha = ( t > 0 ) ? 0.186/t : 1.0 ;
	dynamicRangeScale = 10.0*60.0/dr ;
	dynamicRangeOffset = 56 + ( 60-dr )*dr/60.0;
}

//  local
- (void)displayInMainThread
{
	[ self setNeedsDisplay:YES ] ;
}

- (void)clearPlot
{
	if ( path ) [ path release ] ;
	path = nil ;
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)drawRect:(NSRect)frame
{
	if ( thread == [ NSThread currentThread ] && [ self lockFocusIfCanDraw ] ) {
		//  clear background
		[ backgroundColor set ] ;
		[ background fill ] ;
		//  insert scale
		[ scaleColor set ] ;
		[ spectrumScale stroke ] ;
		// mark/space scale
		[ markSpaceColor set ] ;
		[ markSpace stroke ] ;
		//  insert graph
		if ( path ) {
			[ spectrumColor set ] ;
			[ path stroke ] ;
		}
		[ self unlockFocus ] ;
	}
}

/* local */
- (void)newSpectrum:(CMDataStream*)stream
{
	int i ;
	float db, x, y ;
	Boolean pen ;
	float *inArray ;
	
	inArray = stream->array ;
	if ( !inArray ) return ;
	
	//  collect 4096 samples at 11025 s/s before processing spectrum
	for ( i = 0; i < 512; i++ ) timeStorage[mux+i] = inArray[i] ;
	mux += stream->samples ;
	if ( mux >= 2048 ) {
		mux = 0 ;		
		
		CMPerformFFT( spectrum, &timeStorage[0], &spectrumStorage[0] ) ;
		
		//  left side of plot is 400 Hz, right side is 2600 Hz
		//	the 2200 Hz spans 408 data bins in the FFT
		//  400 Hz offset is 74 bins in the FFT
		for ( i = 0; i < 408; i++ ) smoothedSpectrum[i] = smoothedSpectrum[i]*(1-alpha) + spectrumStorage[i+74]*alpha ;
		
		//  note: 1024 points from spectrum (for 2048 data samples) represents 5512.5 Hz, or 5.383 Hz per point.
		//  full scale signal power should be 2048^2 for each 2^11 transform.
		if ( path ) [ path release ] ;
		path = [ [ NSBezierPath alloc ] init ] ;
		[ path setLineWidth:0.75 ] ;
	
		pen = NO ;
		for ( i = 0; i < 408; i++ ) {
			db = dynamicRangeScale*( log10( smoothedSpectrum[i] ) - 5.8 ) ;
			x = i*scale ;
			y = height + db*pixPerdB ;
			if ( pen == YES ) {
				//  pen in down state
				if ( y < 0 || y >= height ) {
					if ( y < 0 ) {
						[ path lineToPoint:NSMakePoint( x, 0.0 ) ] ; 
						ySat = 0.0 ; 
					}
					else {
						[ path lineToPoint:NSMakePoint( x, height-1 ) ] ;
						ySat = height-1 ;
					}
					pen = NO ;
				}
				else [ path lineToPoint:NSMakePoint( x, y ) ] ;
			}
			else {
				//  pen was in up state
				if ( y >= 0 && y < height ) {
					if ( i == 0 ) [ path moveToPoint:NSMakePoint( x, y ) ] ;
					else {
						[ path moveToPoint:NSMakePoint( x-1, ySat ) ] ;
						[ path lineToPoint:NSMakePoint( x, y ) ] ;
					}
					pen = YES ;
				}
				else {
					if ( y < 0 ) ySat = 0.0 ; else ySat = height-1 ;
				}
			}
		}
		[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
	}
}

//  set Mark to zero to disable
- (void)setTonePairMarker:(const CMTonePair*)tonepair
{
	int m, s ;
	float x ;
	NSBezierPath *old ;
	
	old = markSpace ;
	//  left side of plot is 400 Hz
	m = ( tonepair->mark-400 )/2200.0*plotWidth + 0.5 ;
	s = ( tonepair->space-400 )/2200.0*plotWidth + 0.5 ;
	
	markSpace = [ [ NSBezierPath alloc ] init ] ;
	[ markSpace setLineWidth:0.5 ] ;
	x = m + 0.5 ;
	[ markSpace moveToPoint:NSMakePoint( x, 10 ) ] ;
	[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
	x = s + 0.5 ;
	[ markSpace moveToPoint:NSMakePoint( x, 10 ) ] ;
	[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
	
	if ( old ) [ old release ] ;
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)addData:(CMDataStream*)stream
{
	if ( busy ) return ;
	
	busy = YES ;
	[ self newSpectrum:stream ] ;
	busy = NO ;
}

@end
