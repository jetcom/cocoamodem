//
//  Waterfall.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Aug 05 2004.
//

#import "Waterfall.h"
#import "Application.h"
#import "CoreFilter.h"
#import "cocoaModemParams.h"
#import "DisplayColor.h"
#import "Messages.h"
#import "Modem.h"


//  Assuming an Fs of 11025 Hz and a buffer of 4096 real samples, this produces an
//  FFT of 2048 samples representing 5512.5 Hz (2.69 Hz/bin)
//  i.e., a 743 bins of FFT represents a 2000 Hz span.
//
//	PSK waterfall width = 778 pixels (approx 2.1 kHz)
//  Wideband RTTY waterfall width = 818 pixels (approx 2.2 kHz)
//
//  For slider markers to span 743 pixels -> slider width = waterfall width thus spans 752 pixels
//
//  In narrow mode,
//  Waterfall displays 400 Hz - 4.5 pixels to 2400 Hz + 4.5 pixels
//  Left edge of waterfall view is bin 144 (387.6 Hz) of FFT and right edge is bin 895 (2409 Hz) of FFT
//
//  In wide mode,
//  Waterfall displays x Hz - x.5 pixels to y Hz + y.5 pixels
//  Left edge of waterfall view is bin 144 (387.6 Hz) of FFT and right edge is bin 895 (2409 Hz) of FFT

@implementation Waterfall

- (id)initWithFrame:(NSRect)frame 
{
    self = [ super initWithFrame:frame ] ;
	if ( self ) {
		fftDelegate = nil ;
		modem = nil ;
		mux = 0 ;
		pixel = nil ;
		sideband = 1 ;						// default to USB
		vfoOffset = 0 ;
		scrollWheelRate = 1.0 ;				// rate tuning changes with scroll wheel
		wideWaterfall = NO ;
		mostRecentTone[0] = mostRecentTone[1] = -1 ;
		memset( timeAverage, 0, 1024*sizeof( float ) ) ;
		refreshRate = 1.0 ;
		refreshCycle = 0.0 ;
		[ self setSpread:15*15.625 ] ;		//  start with MFSK16 spread
	}
	return self ;
}

- (BOOL)isOpaque
{
	return YES ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)createNewImageRep:(Boolean)initialize
{
	UInt32 background ;
	int i, lsize ;

	if ( depth >= 24 ) {
		background = intensity[0] ;
		//  Uses 32 bit/pixel for millions of colors mode, all components of a pixel can then be written with a single int write.
		rowBytes = width*4 ;
		lsize = size = rowBytes*height/4 ;
		bitmap = ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:bitmaps
					pixelsWide:width pixelsHigh:height
					bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rowBytes bitsPerPixel:32 ] ;
	}
	else {
		background = ( intensity[0] << 16 ) | intensity[0] ;
		rowBytes = ( ( width*2 + 3 )/4 ) * 4 ;
		lsize = ( size = rowBytes*height/2 )/2 ;
		//  Uses 16 bit/pixel for thousands of colors mode, all components of a pixel can then be written with a single short write.
		bitmap = ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:bitmaps 
					pixelsWide:width pixelsHigh:height
					bitsPerSample:4 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rowBytes bitsPerPixel:16 ] ;
		
	}
	if ( bitmap && initialize ) {
		pixel = ( UInt32* )[ bitmap bitmapData ] ;
		for ( i = 0; i < lsize; i++ ) pixel[i] = background ;
		image = [ [ NSImage alloc ] init ] ;
		[ image addRepresentation:bitmap ] ;
		[ self setImageScaling:NSScaleNone ] ;
		[ self setImage:image ] ;
	}

}

//   Waterfall is also an AudioDest
- (void)awakeFromModem
{
	NSSize bsize ;
	int i, transformSize ;
	
	fftDelegate = nil ;						//  0.82a
	drawLock = [ [ NSLock alloc ] init ] ;
		
	[ self useControlButton:NO ] ;
		
	//  create notification client for arrow keys
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(arrowKeyTune:) name:@"ArrowKey" object:nil ] ;
	
	if ( waterfallRange ) [ self setInterface:waterfallRange to:@selector(waterfallRangeChanged) ] ;
	if ( waterfallClip ) [ self setInterface:waterfallClip to:@selector(waterfallRangeChanged) ] ;
	if ( noiseReductionButton ) [ self setInterface:noiseReductionButton to:@selector(noiseReductionChanged) ] ;
	[ self noiseReductionChanged ] ;
	if ( timeAverageButton ) [ self setInterface:timeAverageButton to:@selector(timeAverageChanged) ] ;
	[ self timeAverageChanged ] ;
	if ( waterfallWidthButton ) [ self setInterface:waterfallWidthButton to:@selector(waterfallWidthChanged) ] ;
		
	for ( i = 0; i < 1024; i++ ) noiseMask[i] = 0.0 ;
	for ( i = 0; i < 4096; i++ ) denoiseBuffer[i] = 0.0 ;
	denoiseIndex = 0 ;

	//  create the thread that actually computes the FFT and draws
	//  if new data has arrived before the last update is done, the data is simply discarded and not updated to the waterfall

	//  check window depth
	depth = NSBitsPerPixelFromDepth( [ NSWindow defaultDepthLimit ] ) ;  //  m = 24, t = 12, 256 = 8
	if ( depth < 12 ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Use thousands or millions of colors", nil ) informativeText:NSLocalizedString( @"Use Display Preferences", nil ) ] ;
		exit( 0 ) ;
	}
	if ( depth < 24 ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Use Millions of Colors", nil ) informativeText:NSLocalizedString( @"Need more colors", nil ) ] ;
	}	
	bsize = [ self bounds ].size ;
	width = bsize.width ;  
	height = bsize.height ;  
	
	transformSize = 2048 ;
	startingBin = 143 ;
	firstBinFreq = startingBin*11025.0/2/transformSize ;
	hzPerPixel = 11025.0/2/transformSize ;	
	offset = 1000.0 ;
	optionOffset = 2000.0 ;
	click = optionClick = -1.0 ;
	notch = 0 ;
	cycle = 0 ;
	waterfallID = 0 ;
	vfoOffset = 0.0 ;
	
	black = [ [ NSColor blackColor ] retain ] ;
	red = [ [ NSColor greenColor ] retain ] ;
	magenta = [ [ NSColor magentaColor ] retain ] ;
	green = [ [ NSColor greenColor ] retain ] ;

	thread = [ NSThread currentThread ] ;
	[ self setDynamicRange:60.0 ] ;
	
	//	v1.03 handles the Max=c OS X 10.8 case (bitmapData changing)
	bitmap = nil ;
	bitmaps[0] = ( unsigned char* )malloc( sizeof( UInt32 )*( width+2 )*height ) ;
	bitmaps[1] = bitmaps[2] = bitmaps[3] = nil ;
	[ self createNewImageRep:YES ] ;
	
	spectrum = FFTSpectrum( 12, YES ) ;
}

- (void)dealloc
{
	free( bitmaps[0] ) ;
	if ( image ) {
		if ( bitmap ) {
			[ image removeRepresentation:bitmap ] ;
			[ bitmap release ] ;
		}
		[ image release ] ;
	}
	[ super dealloc ] ;
}

- (void)useControlButton:(Boolean)state
{
	useControlKeyInsteadOfOptionKey = state ;
	optionMask = ( useControlKeyInsteadOfOptionKey ) ? NSControlKeyMask : NSAlternateKeyMask ;
}

//  set dynamic range
- (void)setDynamicRange:(float)value clip:(float)clip
{
	NSColor *a, *b, *c, *d, *e ;
	float v, map, inten, p, q ;
	float r0, g0, b0, a0, r1, g1, b1, a1 ;
	int i ;
	
	exponent = 0.25 ;
	range = value + clip*2 ;
	
	if ( range > 89 ) p = 1/1.19 ;					// 90
	else {
		if ( range > 79 ) p = 1.00 ;				// 80
		else {
			if ( range > 69 ) p = 1.19 ;			// 70
			else {
				if ( range > 59 ) p = 1.414 ;		// 60
				else {
					if ( range > 49 ) p = 1.68 ;	// 50
					else p = 2.0 ;					// 40
				}
			}
		}
	}
	//  create color scale, defined by 4 colors
	//  use a 20000 element table to achieve 85 dB of dynamic range
	a = [ NSColor colorWithCalibratedRed:0.0 green:0 blue:0.3 alpha:0 ] ;
	b = [ NSColor colorWithCalibratedRed:0 green:0.1 blue:0.8 alpha:0 ] ;
	c = [ NSColor colorWithCalibratedRed:0.0 green:0.5 blue:0.5 alpha:0 ] ;
	d = [ NSColor colorWithCalibratedRed:0.7 green:0.7 blue:0 alpha:0 ] ;
	e = [ NSColor colorWithCalibratedRed:1.0 green:0.0 blue:0 alpha:0 ] ;
	
	for ( i = 0; i < 20000; i++ ) {
	
		q = ( i*p )/20000.0 ;				// v0.73
		q *= sqrt( p ) ;
		if ( q > 1.0 ) q = 1.0 ;
		
		map = pow( q, p )*2 ;		
		if ( map > 0.65 ) map = 0.65 ;
		inten = 1.0 ;
		if ( map < .01 ) {
			v = map/.01 ;
			[ a getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
			[ b getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
		}
		else {
			if ( map < 0.05 ) {
				v = ( map-.01 )/0.04 ;
				[ b getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
				[ c getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
			}
			else {
				if ( map < 0.1 ) {
					v = ( map-0.05 )/0.05 ;
					[ c getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
					[ d getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
				}
				else {
					v = ( map-0.1 )/0.9 ;
					[ d getRed:&r0 green:&g0 blue:&b0 alpha:&a0 ] ;
					[ e getRed:&r1 green:&g1 blue:&b1 alpha:&a1 ] ;
				}
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

- (void)setDynamicRange:(float)value
{
	[ self setDynamicRange:value clip:0.0 ] ;
}

- (void)setSideband:(int)which
{
	sideband = which ;
}

//  v0.75 -- moved here from MFSKWaterfall (bug in Snow Leopard?)
- (void)setSpread:(float)hertz
{
	spread = hertz/2.69 ;
}

- (void)drawMarker:(float)p width:(float)lineWidth color:(NSColor*)color
{
	NSBezierPath *line ;

	line = [ NSBezierPath bezierPath ] ;
	[ line setLineWidth:lineWidth ] ;
	[ line moveToPoint:NSMakePoint( p, 0 ) ] ;
	[ line lineToPoint:NSMakePoint( p, height ) ] ;
	[ color set ] ;
	[ line stroke ] ;
}

- (void)drawMarkers
{
	float p ;
	
	//  additional drawing here
	if ( click > 0 ) {
		p = click+0.5 ;
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:green ] ;
	}
	if ( optionClick > 0 ) {
		p = optionClick+0.5 ;
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:magenta ] ;
	}
}

- (void)updateInterface
{
	[ self setNeedsDisplay:YES ] ;
	[ waterfallLabel setNeedsDisplay:YES ] ;
	[ waterfallTicks setNeedsDisplay:YES ] ;
	[ waterfallRange setNeedsDisplay:YES ] ;
	[ noiseReductionButton setNeedsDisplay:YES ] ;
	if ( timeAverageButton ) [ timeAverageButton setNeedsDisplay:YES ] ;
}

- (void)drawRect:(NSRect)rect 
{
	[ super drawRect:rect ] ;
	[ self drawMarkers ] ;
}

//  send nil to disable
- (void)enableIndicator:(Modem*)who
{
	modem = who ;
}

/* local */
- (int)plotValue:(float)sample
{
	int value ;
	
	value = pow( sample/(4096.*4096), exponent ) * 20000.0 ;
	return ( value > 19999 ) ? 19999 : value ;
}

- (UInt32)plotIntensity:(float)sample
{
	int value ;
	
	value = pow( sample/(4096.*4096), exponent ) * 20000.0 ;
	if ( value > 19999 ) value = 19999 ;
	
	return intensity[value] ;
}

- (void)setNotch:(NSEvent*)event
{
	Boolean shift ;
	NSPoint location ;
	float f ;
	unsigned int flags ;
	
	flags = [ event modifierFlags ] ;
	shift = ( ( flags & NSShiftKeyMask ) != 0 ) ;
	
	if ( shift ) {
		notch = 0 ;
		return ;
	}
	location = [ self convertPoint:[ event locationInWindow ] fromView:nil ] ;
	f =  firstBinFreq + ( ( sideband == 1 ) ? hzPerPixel*location.x : hzPerPixel*( width - location.x - 1 ) ) ;
	notch = ( f/hzPerPixel ) ;
	if ( notch < 0 ) notch = 0 ;
	
	[ self setDynamicRange:[ waterfallRange floatValue ]-20 ] ;
}

- (void)eitherMouseDown:(NSEvent*)event secondRx:(Boolean)option
{
	Boolean shift ;
	NSPoint location ;
	unsigned int flags ;
	float f, g ;
	
	flags = [ event modifierFlags ] ;
	shift = ( flags & NSShiftKeyMask ) != 0 ;
	
	if ( shift ) {
		[ drawLock lock ] ;
		if ( !option ) click = 0 ; else optionClick = 0 ;
		[ drawLock unlock ] ;
		f = offset = 0 ;
		if ( modem ) [ modem turnOffReceiver:waterfallID option:option ] ;
		return ;
	}
	location = [ self convertPoint:[ event locationInWindow ] fromView:nil ] ;
	
	if ( wideWaterfall ) {
		f =  firstBinFreq + ( ( sideband == 1 ) ? 2*hzPerPixel*location.x : 2*hzPerPixel*( width - location.x - 1 ) ) ;
	}
	else {
		f =  firstBinFreq + ( ( sideband == 1 ) ? hzPerPixel*location.x : hzPerPixel*( width - location.x - 1 ) ) ;
	}
	g = location.y * ( 4096.0 / CMFs ) ;		//  4096 samples per scanline
	[ drawLock lock ] ;
	if ( !option ) {
		click = location.x ; 
		offset = f ;
	}
	else {
		optionClick = location.x ;
		optionOffset = f ;
	}
	[ drawLock unlock ] ;
	
	if ( modem ) [ modem clicked:f secondsAgo:g option:option fromWaterfall:YES waterfallID:waterfallID ] ;
}

- (void)mouseDown:(NSEvent*)event
{
	Boolean option ;
	unsigned int flags ;
	
	flags = [ event modifierFlags ] ;
		
	if ( ( flags & NSCommandKeyMask ) != 0 ) {
		[ self setNotch:event ] ;
		return ;
	}	
	
	option = ( flags & optionMask ) != 0 ;
	[ self eitherMouseDown:event secondRx:option ] ;
}

- (void)rightMouseDown:(NSEvent*)event
{
	if ( useControlKeyInsteadOfOptionKey ) [ self eitherMouseDown:event secondRx:YES ] ;
}

- (void)setScrollWheelRate:(float)speed
{
	scrollWheelRate = speed ;
}

- (void)scrollWheel:(NSEvent*)event
{
	unsigned int flags ;
	float df, dv ;
	Boolean option ;

	if ( modem && [ modem isActiveTab ] ) {
		df = ( ( [ event deltaY ] > 0 ) ? -0.5 : 0.5 )*scrollWheelRate ;
		flags = [ event modifierFlags ] ;
		option = ( flags & optionMask ) != 0 ;
		if ( option ) {
			optionOffset += ( sideband != 0 ) ? ( df ) : ( -df ) ;
			dv = ( optionOffset - firstBinFreq )/hzPerPixel ;
			[ drawLock lock ] ;
			optionClick = ( sideband != 0 ) ? dv : width - dv - 1 ; 
			[ drawLock unlock ] ;
			[ modem clicked:optionOffset secondsAgo:0 option:YES fromWaterfall:NO waterfallID:0 ] ;
		}
		else {
			offset += ( sideband != 0 ) ? ( df ) : ( -df ) ;
			dv = ( offset - firstBinFreq )/hzPerPixel ;
			[ drawLock lock ] ;
			click = ( sideband != 0 ) ? dv : width - dv - 1 ; 
			[ drawLock unlock ] ;
			[ modem clicked:offset secondsAgo:0 option:NO fromWaterfall:NO waterfallID:0 ] ;
		}
	}
}

//  v0.73
- (void)clearMarkers
{
	[ drawLock lock ] ;
	click = optionClick = 0 ;
	[ drawLock unlock ] ;
}

- (void)moveToneTo:(float)tone receiver:(int)uniqueID
{
	float bin ;
	
	mostRecentTone[uniqueID] = tone ;
	
	if ( sideband == 1 ) {
		if ( wideWaterfall ) {						// v0.47
			bin =  ( tone - firstBinFreq )/(2*hzPerPixel ) + 3.5 ;
		}
		else {
			bin = ( tone - firstBinFreq )/hzPerPixel ;	
		}
	}
	else {
		if ( wideWaterfall ) {
			bin = width - ( tone - firstBinFreq )/(2*hzPerPixel) - 4.5 ;
		}
		else {
			bin = width - ( tone - firstBinFreq )/hzPerPixel - 1 ;
		}
	}	
	[ drawLock lock ] ;
	switch ( uniqueID ) {
	case 0:
		if ( click > 0 ) {
			click = bin ; 
			offset = tone ;
		}
		break ;
	case 1:
		if ( optionClick > 0 ) {
			optionClick = bin ;
			optionOffset = tone ;
		}
		break ;
	}
	[ drawLock unlock ] ;
}

//  turn on the frequency indicator and calculate position for drawing
- (void)forceToneTo:(float)tone receiver:(int)uniqueID
{
	[ drawLock lock ] ;
	if ( uniqueID ==  1 ) optionClick = 1 ; else click = 1 ;
	[ drawLock unlock ] ;
	[ self moveToneTo:tone receiver:uniqueID ] ;
}

- (void)arrowKeyTune:(NSNotification*)notify
{
	NSEvent *event ;
	Boolean option ;
	Modem *psk ;
	int ch ;
	unsigned int flags ;
	float df, dv ;
	
	if ( modem && [ modem isActiveTab ] ) {
		psk = modem ;
		//  PSK panel currently open
		event = [ notify object ] ;
		ch = [ [ event characters ] characterAtIndex:0 ] ;		
		switch ( ch ) {
		case NSUpArrowFunctionKey:
			df = 1.0 ;
			break ;
		case NSDownArrowFunctionKey:
			df = -1.0 ;
			break ;
		case NSLeftArrowFunctionKey:
			df = -0.1 ;
			break ;
		case NSRightArrowFunctionKey:
			df = 0.1 ;
			break ;
		default:
			return ;
		}
		flags = [ event modifierFlags ] ;
		option = ( flags & optionMask ) != 0 ;
		if ( option ) {
			optionOffset += ( sideband != 0 ) ? ( df ) : ( -df ) ;
			dv = ( optionOffset - firstBinFreq )/hzPerPixel ;
			[ drawLock lock ] ;
			optionClick = ( sideband != 0 ) ? dv : width - dv - 1 ; 
			[ drawLock unlock ] ;
			[ psk clicked:optionOffset secondsAgo:0 option:YES fromWaterfall:NO waterfallID:0 ] ;
		}
		else {
			if ( ( flags & ( NSAlternateKeyMask|NSControlKeyMask ) ) == 0 )
			offset += ( sideband != 0 ) ? ( df ) : ( -df ) ;
			dv = ( offset - firstBinFreq )/hzPerPixel ;
			[ drawLock lock ] ;
			click = ( sideband != 0 ) ? dv : width - dv - 1 ; 
			[ drawLock unlock ] ;
			[ psk clicked:offset secondsAgo:0 option:NO fromWaterfall:NO waterfallID:0 ] ;
		}
	}
}

- (void)setWaterfallID:(int)index
{
	waterfallID = index ;
}

- (void)displayInMainThread
{
	[ self display ] ;						// v0.73
	//[ self setNeedsDisplay:YES ] ;
}

//  set callback (client should implement -newFFTBuffer (prototype shown below)
//	set to nil to turn callback off
//	Callback is an FFT power spectrum that is 2048 samples long, representing 0-5512.5 Hz (2.69 Hz per bin)
- (void)setFFTDelegate:(id)delegate
{
	fftDelegate = delegate ;
}

//  callback prototype 
- (void)newFFTBuffer:(float*)buffer
{
}

- (void)processBufferAndDisplayInMainThread:(float*)samples
{
	char *src ;
	UInt32 *line ;
	UInt16 *sline ;
	float *startBin, u, v, *output, *p0, *p1, *p2, peak, noise, minv, norm, sum ;
	int i, j, actualStartingBin ;
	float agcCompensation, wiener, averaged[1024], lastv ;

	CMPerformFFT( spectrum, samples, freqBin ) ;
	
	if ( fftDelegate ) [ fftDelegate newFFTBuffer:freqBin ] ;		//  v0.57b
	
	actualStartingBin = ( wideWaterfall ) ? ( startingBin-7 ) : startingBin ;
	
	output = startBin = &freqBin[actualStartingBin] ;

	//  decimate by 2:1 using rectangular window if wide waterfall
	if ( wideWaterfall ) {
		for ( i = startingBin; i < actualStartingBin+width; i++ ) {
			j = i*2 - actualStartingBin ;
			freqBin[i] = ( freqBin[j] + freqBin[j+1] )*0.5 ;
		}
	}

	if ( noiseReduction || doTimeAverage ) {
		//  apply noise reduction
		assert( width <= 1024 ) ;
		
		startBin = &freqBin[actualStartingBin] ;
		p0 = &denoiseBuffer[denoiseIndex] ;
		p1 = &denoiseBuffer[( denoiseIndex+3072 )%4096] ;
		p2 = &denoiseBuffer[( denoiseIndex+2048 )%4096] ;
		for ( i = 0; i < width; i++ ) p0[i] = startBin[i] ;
		
		denoiseIndex = ( denoiseIndex+1024 )%4096 ;
		
		peak = norm = 0.0001 ;
		for ( i = 0; i < width; i++ ) {
			v = p0[i] + p1[i] + p2[i] ;
			u = sqrt( v ) ;
			if ( v > peak ) peak = v ;
			if ( u > norm ) norm = u ;
			averaged[i] = u ;
		}
		// normalize smoothed average sqrt spectra and find normalized min (noise)
		norm = 1.0/norm ;
		minv = 1.0e12 ;
		for ( i = 0; i < width; i++ ) {
			v = averaged[i]*norm ;
			if ( v < minv ) minv = v ;
			noiseMask[i] = v*0.2 + noiseMask[i]*0.8 ;
		}
		noise = minv*2.0 ;										//  estimate of actual noise floor as 6 dB above min
		agcCompensation = 0.03/sqrt( minv ) ;
		if ( agcCompensation > 1.4 ) agcCompensation = 1.4 ; else if ( agcCompensation < 0.3 ) agcCompensation = 0.3 ;
		
		sum = 0.0 ;
		for ( i = 0; i < width; i++ ) {
			v = ( noiseMask[i] + noise ) ;
			if ( v < 0.001 ) v = 0.001 ; else if ( v > 1.0 ) v = 1.0 ;
			u = noiseMask[i] - noise ;
			if ( u < 0.0001 ) u = 0.0001 ;
			wiener = u/v * agcCompensation ;
			averaged[i] = startBin[i] * wiener ;
			sum += averaged[i] ;
		}
		sum /= width*10 ;
		for ( i = 0; i < width; i++ ) {
			u = averaged[i] ;
			if ( u < sum ) u = sum/10 ;
			averaged[i] = u ;
		}
		//  use un-denoised data for waterfall display
		output = averaged ;	
	}
	
	//  v0.73
	if ( doTimeAverage ) {
		sum = 0 ;
		lastv = 0 ;
		for ( i = 0; i < width; i++ ) {
			v = pow( output[i], 2.0 )*0.01 ;
			u = v + lastv ;
			lastv = v ;
			if ( u < timeAverage[i] ) {
				timeAverage[i] = timeAverage[i]*0.8 ;
			}
			else {
				timeAverage[i] = timeAverage[i]*0.5 + u*0.5 ;
			}
			sum += timeAverage[i] ;
		}
		output = timeAverage ;
	}

	//  scroll waterfall up
	
	//	v1.03 -- allocate new BitmapImageRep for Mountain Lion
	[ image removeRepresentation:bitmap ] ;
	[ bitmap release ] ;
	[ self createNewImageRep:NO ] ;	//  create new NSBitmapImage rep with the local buffers
	[ image addRepresentation:bitmap ] ;		
	pixel = ( UInt32* )[ bitmap bitmapData ] ;	//  this should retrieve the local buffer pointer	
	
	src = ( ( char* )pixel ) + rowBytes ;
	memcpy( pixel, src, rowBytes*( height-1 ) ) ;
	
	if ( depth >= 24 ) {
		line = (UInt32*)( ( ( char* )pixel ) + rowBytes*( height-1 ) ) ;
		//startBin = &freqBin[startingBin] ;
		if ( sideband != 0 ) {
			for ( i = 0; i < width; i++ ) line[i] = [ self plotIntensity:output[i] ] ;
		}
		else {
			//   flip plot
			for ( i = 0; i < width; i++ ) line[width-i-1] = [ self plotIntensity:output[i] ] ;
		}
	}
	else {
		sline = (UInt16*)( ( ( char* )pixel ) + rowBytes*( height-1 ) ) ;
		//startBin = &freqBin[startingBin] ;
		if ( sideband != 0 ) {
			for ( i = 0; i < width; i++ ) sline[i] = [ self plotIntensity:output[i] ] ;
		}
		else {
			//  flip plot
			for ( i = 0; i < width; i++ ) sline[width-i-1] = [ self plotIntensity:output[i] ] ;
		}
	}
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ; 
}

- (void)importAndDisplayData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *data ;
	int limit ;

	//  ignore data overruns
	if ( [ drawLock tryLock ] ) {

		stream = [ pipe stream ] ;
		data = stream->array ;

		//  copy new buffer (512) into fft buffer (4096)
		limit = 4096 - stream->samples ;
		if ( mux > limit ) mux = limit ;
		memcpy( &timeSample[mux], data, stream->samples*sizeof(float) ) ;
		mux += stream->samples ;

		if ( mux >= 4096 ) {
			mux = 0 ;
			[ self processBufferAndDisplayInMainThread:timeSample ] ;
		}
		[ drawLock unlock ] ;
	}
	else printf( "waterfall overrun\n" ) ;
}

- (void)importData:(CMPipe*)pipe
{
	if ( !modem ) return ;
	
	refreshCycle += refreshRate ;
	if ( refreshCycle < 0.99 ) return ;
	refreshCycle = 0 ;
	[ self importAndDisplayData:pipe ] ;
}

- (void)setRefreshRate:(float)rate
{
	refreshRate = rate ;
}

- (void)waterfallRangeChanged
{
	float clip ;
	
	clip = ( waterfallClip ) ? [ waterfallClip floatValue ] : 0.0 ;
	[ self setDynamicRange:[ waterfallRange floatValue ] clip:clip ] ;
}

- (void)noiseReductionChanged
{
	if ( noiseReductionButton == nil ) {
		noiseReduction = YES ;
		return ;
	}
	noiseReduction = ( [ noiseReductionButton state ] == NSOnState ) ;
}

//  v0.73  support plist for NR button
- (Boolean)noiseReductionState
{
	return ( [ noiseReductionButton state ] == NSOnState ) ;
}

//  v0.73  support plist for NR button
- (void)setNoiseReductionState:(Boolean)state 
{
	if ( noiseReductionButton != nil ) {
		[ noiseReductionButton setState:( state ) ? NSOnState : NSOffState ] ;
		[ self noiseReductionChanged ] ;
	}
}

- (void)timeAverageChanged
{
	if ( timeAverageButton == nil ) {
		doTimeAverage = NO ;
		return ;
	}
	doTimeAverage = ( [ timeAverageButton state ] == NSOnState ) ;
	memset( timeAverage, 0, sizeof( float )*1024 ) ;
}

- (void)waterfallWidthChanged
{
	int i ;
	
	if ( waterfallWidthButton == nil ) {
		wideWaterfall = NO ;
		return ;
	}
	wideWaterfall = ( [ waterfallWidthButton state ] == NSOnState ) ;
	[ waterfallWidthButton setTitle:( wideWaterfall ) ? @"4 kHz" : @"2 kHz" ] ;
	
	[ self setOffset:vfoOffset sideband:sideband ] ;	
	for ( i= 0; i < 2; i++ ) {
		if ( mostRecentTone[i] > 100 ) [ self moveToneTo:mostRecentTone[i] receiver:i ] ;
	}
}

//  set VFO offset
- (void)setOffset:(float)freq sideband:(int)inSideband
{
	NSRect frame ;
	NSTextField *label ;
	float pixelOffset ;
	int i, fstart, nearest, actual ;
	
	//  For narrow waterfall:
	//  If USB offset = 0, left edge is 400 Hz and right edge 2400 Hz (752 pixels)
	//  If LSB offset = 0, left edge is -2400 Hz and right edge -400 Hz
	//  If USB offset = 2000, left edge is -1600 Hz and right edge is +400 Hz
	//  If LSB offset = 2000, left edge is -400 Hz and right edge is +1600 Hz

	vfoOffset = freq ;	
	nearest = ( (int)freq )/100 ;
	nearest = nearest*100 ;
	if ( ( freq - nearest ) > 50.0 ) nearest += 100 ;
	
	//  sideband: LSB = 0, USB = 1, 2.69179 Hz/pixel
	if ( inSideband == 1 ) {
		//  USB
		pixelOffset = ( freq - nearest )/hzPerPixel ;
		
		if ( wideWaterfall ) {
			fstart = 400 ;
			for ( i = 0; i < 22; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%600 == 0 ) [ label setIntValue:actual ] ; else [ label setStringValue:@"" ] ;
				fstart += 200 ;
			}
		}
		else {
			fstart = 400 ;
			for ( i = 0; i < 21; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%500 == 0 ) [ label setIntValue:actual ] ; else [ label setStringValue:@"" ] ;
				fstart += 100 ;
			}
		}
	}
	else {
		// LSB 
		pixelOffset = -( freq - nearest )/hzPerPixel - 1 + 26 /* 778-752 */ ;

		if ( wideWaterfall ) {
			fstart = 4400 ;
			for ( i = 0; i < 21; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%600 == 0 ) [ label setIntValue:-actual ] ; else [ label setStringValue:@"" ] ;
				fstart -= 200 ;
			}
		}
		else {
			fstart = 2400 ;
			for ( i = 0; i < 21; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%500 == 0 ) [ label setIntValue:-actual ] ; else [ label setStringValue:@"" ] ;
				fstart -= 100 ;
			}
		}
	}
	frame = [ waterfallLabel frame ] ;
	frame.origin.x = pixelOffset - 15 ;
	[ waterfallLabel setFrame:frame ] ;
	[ waterfallLabel display ] ;

	//  fine tune tick marks
	frame = [ waterfallTicks frame ] ;
	frame.origin.x = pixelOffset - 37 ;
	if ( wideWaterfall ) {
		if ( sideband == 0 ) frame.origin.x -= 1.0 ; else frame.origin.x += 3.0 ; 
	}
	else {
		if ( sideband == 1 ) frame.origin.x += 2.5 ;
	}
	
	[ waterfallTicks setFrame:frame ] ;
	[ waterfallTicks display ] ;
}

@end
