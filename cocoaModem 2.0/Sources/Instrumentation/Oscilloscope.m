//
//  Oscilloscope.m
//  cocoaModem
//
//  Created by Kok Chen on Fri May 21 2004.
	#include "Copyright.h"
//

#import "Oscilloscope.h"
#import "CMDSPWindow.h"

@implementation Oscilloscope

static int pixPerdB = 3 ;

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initWithFrame:(NSRect)frame 
{
	int i ;
	NSSize size ;
	float x, y, h, s, dash[2] = { 1.0, 2.0 }, closedash[2] = { 1.0, 1.0 } ;
	
    self = [ super initWithFrame:frame ] ;
    if ( self ) {
		bounds = [ self bounds ] ;
		size = bounds.size ;
		width = size.width ;
		height = size.height ;
		plotWidth = 512 ;
		plotOffset = 4 ;
		mux = 0 ;
		doBaseline = NO ;
		baseline = alpha = 1.0 ;
		
		path = path2 = nil ;
		markSpace = nil ;
		pathLock = [ [ NSLock alloc ] init ] ;
		drawLock = [ [ NSLock alloc ] init ] ;
		background = [ [ NSBezierPath alloc ] init ] ;
		[ background appendBezierPathWithRect:bounds ] ;
		[ ( backgroundColor = [ NSColor colorWithDeviceRed:0 green:0.1 blue:0 alpha:1 ] ) retain ] ;
		
		//  set up spectrum scale
		[ ( spectrumColor = [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0 alpha:1 ] ) retain ] ;
		spectrumScale = [ [ NSBezierPath alloc ] init ] ;
		[ spectrumScale setLineDash:dash count:2 phase:0 ] ;
		for ( i = 5; i < 106; i += 20 ) {
			y = height - ( i*pixPerdB ) + 0.5 ;
			if ( y <= 0 ) break ;
			[ spectrumScale moveToPoint:NSMakePoint( plotOffset, y ) ] ;
			[ spectrumScale lineToPoint:NSMakePoint( plotWidth+plotOffset, y ) ] ;
		}
		for ( i = 500; i < 3000; i += 500 ) {
			x = 4.5 + ( int )( i*512/2756.25 ) ;
			[ spectrumScale moveToPoint:NSMakePoint( x, 0 ) ] ;
			[ spectrumScale lineToPoint:NSMakePoint( x, height ) ] ;
		}
		
		//  set up waveform scale
		[ ( waveformColor = [ NSColor colorWithCalibratedRed:0 green:1 blue:0.1 alpha:1 ] ) retain ] ;
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
		
		//  set up mark/space scales
		markSpaceColor = [ [ NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:1 ] retain ] ;
		markSpace = [ [ NSBezierPath alloc ] init ] ;
		[ markSpace setLineDash:closedash count:2 phase:0 ] ;
		x = 200.5 ;
		[ markSpace moveToPoint:NSMakePoint( x, 10 ) ] ;
		[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
		x = 300.5 ;
		[ markSpace moveToPoint:NSMakePoint( x, 10 ) ] ;
		[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
		enableMarkSpace = NO ;
		
		baudot = [ [ NSBezierPath alloc ] init ] ;
		for ( i = 1; i < 8; i++ ) {
			x = plotOffset + (int)( i*30.32*2 ) + 0.5 ;
			[ baudot moveToPoint:NSMakePoint( x, 10 ) ] ;
			[ baudot lineToPoint:NSMakePoint( x, height-10 ) ] ;
		}
		enableBaudot = NO ;
		
		//  initial display style (spectrum)
		[ self setDisplayStyle:0 plotColor:nil ] ;
		
		//  initialize interpolation filters
		s = 0.0 ;
		for ( i = 0; i < 192; i++ ) {
			h = CMSinc( i, 192, 16 /*12*/ )*CMBlackmanWindow( i, 192 ) ; 
			scopeFilter[i] = h ;
			s += h ;
		}
		s = 1./s ;
		for ( i = 0; i < 192; i++ ) scopeFilter[i] *= s ;

		for ( i = 0; i < 2; i++ ) {
			//  filters for one of each of 2 channels
			interpolateBy8[i] = CMFIRInterpolate( 8, scopeFilter, 192/8 ) ;
			interpolateBy2[i] = CMFIRInterpolate( 2, scopeFilter, 192/2 ) ;
		}	
		
		for ( i = 0; i < 2048; i++ ) spectrumAverage[i] = 0.0 ;
		//  initialize spectrum fft (use vDSP)
		spectrum = FFTSpectrum( 11, YES ) ;
		busy = NO ;
		
		thread = [ NSThread currentThread ] ;
    }
    return self ;
}

- (void)awakeFromNib
{
	if ( averageButton ) [ self setInterface:averageButton to:@selector(averageButtonChanged) ] ;
	if ( averagePopupMenu ) [ self setInterface:averagePopupMenu to:@selector(averageMenuChanged) ] ;
	if ( baselineButton ) {
		[  self setInterface:baselineButton to:@selector(baselineButtonChanged) ] ;
		[ baselineButton setEnabled:NO ] ;
	}
}

- (void)averageButtonChanged
{
	if ( averageButton ) {
		if ( [ averageButton state ] == NSOnState ) {
			alpha = 0.186/0.5 ;
			[ baselineButton setEnabled: YES ] ;
			return ;
		}
	}
	alpha = 1.0 ;
	[ baselineButton setEnabled: NO ] ;
}

static float timeConstants[] = { 0.0, 0.2, 0.5, 1.5, 4.0 } ;

//  v0.64c allows Lite window to change thetime constant
- (void)selectTimeConstant:(int)n
{
	float tc ;

	tc = timeConstants[n] ;
	alpha = ( tc > 0 ) ? 0.186/tc : 1.0 ;
}

- (void)averageMenuChanged
{
	int t ;
	float tc ;
	
	if ( averagePopupMenu ) {
		t = [ averagePopupMenu indexOfSelectedItem ] ;
		tc = timeConstants[t] ;								//  v0.65 bug fix (was moved to electTimeConstant instead of copied!)
		alpha = ( tc > 0 ) ? 0.186/tc : 1.0 ;				//  v0.65 bug fix
		[ baselineButton setEnabled: ( t > 0 ) ] ;
	}
}

- (void)baselineButtonChanged
{
	doBaseline = ( [ baselineButton state ] == NSOnState ) ;
}

- (BOOL)isOpaque
{
	return YES ;
}

- (void)drawRect:(NSRect)frame
{
	if ( [ pathLock tryLock ] ) {
		//  clear background
		[ backgroundColor set ] ;
		[ background fill ] ;
		//  insert scale
		[ scaleColor set ] ;
		[ scale stroke ] ;
		// mark/space scale
		if ( style == 0 && enableMarkSpace ) {
			[ markSpaceColor set ] ;
			[ markSpace stroke ] ;
		}
		//  baudot bit markers (30.32*2 pixels apart)
		if ( style == 1 && enableBaudot ) {
			[ markSpaceColor set ] ;
			[ baudot stroke ] ;
		}
		//  insert graph
		if ( path ) {
			[ plotColor set ] ;
			[ path stroke ] ;
		}
		if ( path2 ) {
			[ plotColor set ] ;
			[ path2 stroke ] ;
		}
		[ pathLock unlock ] ;
	}
}

//  local
- (void)displayInMainThread
{
	[ self setNeedsDisplay:YES ] ;
}

/* local */
- (void)newWaveform:(CMDataStream*)stream
{
	int i, synci, channels, channelOffset, plotSamples ;
	float output1[512*8], output2[512*8], *syncd, *synce ;
	float u, v, w, yoffset, xgain, ygain, x, y, *inArray ;
	
	inArray = stream->array ;
	channels = stream->channels ;
	channelOffset = stream->samples ;
	plotSamples = plotWidth ;
	xgain = 1.0 ;
	
	if ( !inArray ) return ;
	
	if ( timebase <= 1 ) {
		//  interpolate
		CMPerformFIR( interpolateBy8[0], inArray, plotWidth, output1 ) ;
		if ( channels > 1 ) CMPerformFIR( interpolateBy8[1], inArray+channelOffset, plotWidth, output2 ) ;
		
		//  for timebase == 1, display once each 4 frames
		if ( mux++ < 3 ) return ;
		
		mux = 0 ;
		//  find the best zero crossing to use as start of a waveform
		w = 1.0 ;
		synci = 16 ;
		u = output1[synci] ;
		for ( i = synci; i < 1000; i++ ) {
			v = output1[i] ;
			if ( u < 0 && v >= 0 && v < w ) {
				w = v ;
				synci = i ;
			}
			u = v ;
		}
		syncd = &output1[synci] ;
		synce = &output2[synci] ;
	}
	else {
		if ( timebase <= 4 ) {
			CMPerformFIR( interpolateBy2[0], inArray, stream->samples, output1 ) ;
			if ( channels > 1 ) CMPerformFIR( interpolateBy2[1], inArray+channelOffset, stream->samples, output2 ) ;
			syncd = &output1[0] ;
			synce = &output2[0] ;
		}
		else {
			//  no filtering if timebase >= 8, stretch plot to cover x scale
			plotSamples = stream->samples ;
			if ( plotSamples > plotWidth ) plotSamples = plotWidth ;
			xgain = plotWidth/plotSamples ;
			syncd = &inArray[0] ;
			synce = &inArray[512] ;
		}
	}
	//  create new plot
	yoffset = height/2 ;
	ygain = -yoffset*0.75 ;
		
	if ( path ) [ path release ] ;
	path = [ [ NSBezierPath alloc ] init ] ;
	for ( i = 0; i < plotSamples; i++ ) {
		x = plotOffset + i*xgain ;
		y = yoffset - syncd[i]*ygain ;
		if ( y >= height ) y = height-1 ; else if ( y < 0 ) y = 0 ;
		if ( i == 0 ) [ path moveToPoint:NSMakePoint( x, y ) ] ; else [ path lineToPoint:NSMakePoint( x, y ) ] ;
	}
	
	if ( path2 ) [ path2 release ] ;
	path2 = nil ;
	
	if ( channels > 1 ) {
		path2 = [ [ NSBezierPath alloc ] init ] ;
		for ( i = 0; i < plotSamples; i++ ) {
			x = plotOffset + i*xgain ;
			y = yoffset - synce[i]*ygain ;
			if ( y >= height ) y = height-1 ; else if ( y < 0 ) y = 0 ;
			if ( i == 0 ) [ path2 moveToPoint:NSMakePoint( x, y ) ] ; else [ path2 lineToPoint:NSMakePoint( x, y ) ] ;
		}
	}
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

/* local */
- (void)newSpectrum:(CMDataStream*)stream
{
	int i, count ;
	float sum, db, x, y, avg, threshold, beta, base ;
	Boolean pen ;
	float *inArray ;
	
	inArray = stream->array ;
	if ( !inArray ) {
		NSLog( @"Oscilloscope - no spectral data?\n" ) ;
		return ;
	}
	
	//  collect 4096 samples at 11025 s/s before processing spectrum
	for ( i = 0; i < plotWidth; i++ ) timeStorage[mux+i] = inArray[i] ;
	mux += stream->samples ;
	if ( mux >= 4096 ) {
		mux = 0 ;		
		
		//  take average of 2 power spectra
		CMPerformFFT( spectrum, &timeStorage[0], &spectrumStorage[0] ) ;
		CMPerformFFT( spectrum, &timeStorage[2048], &spectrumStorage[2048] ) ;
		
		//  note: 512 points from spectrum (2048 data samples) represents 2756.25 Hz, or 5.3833 Hz per pixel.
		//  full scale signal power should be 2048^2 for each 2^11 transform.
		if ( path2 ) [ path2 release ] ;
		path2 = nil ;
		if ( path ) [ path release ] ;
		path = [ [ NSBezierPath alloc ] init ] ;
		[ path setLineWidth:0.75 ] ;
	
		pen = NO ;
		beta = 1.0 - alpha ;
		base = ( doBaseline ) ? baseline : 1.414*10 ;
		
		for ( i = 0; i < plotWidth; i++ ) {
		
			sum = ( spectrumStorage[i] + spectrumStorage[i+2048] ) ;
			
			spectrumAverage[i] = spectrumAverage[i]*beta + sum*alpha ;
			
			sum = spectrumAverage[i]*base ;
			
			//  scale to 0dB = approx full scale, 1 unit per dB
			db = 10.0*log10( sum ) - 64.237 ; // including factor for averaging 2 spectra
			x = i+plotOffset+0.5 ;
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
		if ( doBaseline ) {
			avg = 0.0 ;
			for ( i = 30; i < plotWidth; i++ ) avg += spectrumAverage[i] ;
			threshold = avg/plotWidth * 6 ;
			avg = 0.0 ;
			count = 1 ;
			for ( i = 0; i < plotWidth; i++ ) {
				x =  spectrumAverage[i] ;
				if ( x < threshold ) {
					avg += x ;
					count++ ;
				}
			}
			threshold = avg/count * 6 ;
			avg = 0.0 ;
			count = 1 ;
			for ( i = 0; i < plotWidth; i++ ) {
				x =  spectrumAverage[i] ;
				if ( x < threshold ) {
					avg += x ;
					count++ ;
				}
			}			
			baseline = 0.01/( avg/count ) ;
		}
		[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
	}
}

//  set Mark frequency to zero to disable
- (void)setTonePairMarker:(const CMTonePair*)tonepair
{
	int m, s ;
	float x ;
	
	[ pathLock lock ] ;
	if ( tonepair == nil || tonepair->mark < 0.1 || tonepair->space < 0.1 ) {
		enableMarkSpace = NO ;
		[ pathLock unlock ] ;
		return ;
	}
	m = tonepair->mark/2756.25*plotWidth + 0.5 ;
	s = tonepair->space/2756.25*plotWidth + 0.5 ;
	
	//  replace old BezierPath for mark/space markers
	if ( markSpace ) [ markSpace release ] ;
	markSpace = [ [ NSBezierPath alloc ] init ] ;
	[ markSpace setLineWidth:0.5 ] ;
	x = plotOffset + m + 0.5 ;
	[ markSpace moveToPoint:NSMakePoint( x, 10 ) ] ;
	[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
	if ( s > 0.1 ) {
		x = plotOffset + s + 0.5 ;
		[ markSpace moveToPoint:NSMakePoint( x, 10 ) ] ;
		[ markSpace lineToPoint:NSMakePoint( x, height-10 ) ] ;
	}
	enableMarkSpace = YES ;
	[ pathLock unlock ] ;
}

- (void)addData:(CMDataStream*)stream isBaudot:(Boolean)inBaudot timebase:(int)inTimebase
{
	if ( busy ) return ;
	
	if ( [ drawLock tryLock ] ) {
		enableBaudot = inBaudot ;
		timebase = inTimebase ;
		busy = YES ;
		if ( style == 1 ) [ self newWaveform:stream ] ; else [ self newSpectrum:stream ] ;
		busy = NO ;
		[ drawLock unlock ] ;
	}
}

- (void)setDisplayStyle:(int)inStyle plotColor:(NSColor*)newWaveformColor
{
	if ( newWaveformColor ) {
		//  replace waveform color with requested color
		[ newWaveformColor retain ] ;
		[ waveformColor release ] ;
		waveformColor = newWaveformColor ;
	}
	style = inStyle ;
	
	if ( style == 1 ) {
		plotColor = waveformColor ; 
		scaleColor = spectrumColor ;
		scale = waveformScale ;
	}
	else {
		plotColor = spectrumColor ;
		scaleColor = waveformColor ; 
		scale = spectrumScale ;
	}
	mux = 0 ;
}

@end
