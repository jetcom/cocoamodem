//
//  CrossedEllipse.m
//  cocoaModem
//
//  Created by Kok Chen on Fri May 14 2004.
	#include "Copyright.h"
//

#import "CrossedEllipse.h"
#include "Messages.h"
#include "CoreFilter.h"
#include "CoreModemTypes.h"

@implementation CrossedEllipse

//  CrossedEllipse is also an AudioPipe destination (i.e., has importData method)

- (id)initWithFrame:(NSRect)frame 
{
	int i ;
	float x ;
	
    self = [ super initWithFrame:frame ] ;
	if ( self ) {
		modem = nil ;
		overrun = [ [ NSLock alloc ] init ] ;
		fatness = 1.0 ;
		
		//  phosphor decay is modeled with a ring buffer of FADE entries
		//  a point leaves the ring buffer when the border of the ring buffer 
		//  (the integer currentOffset meets up with the point)
		
		for ( i = 0; i < FADE; i++ ) offsetToPhosphorDisplay[i] = 0 ;
		currentOffset = 0 ;
		
		for ( i = 0; i < 4; i++ ) mark[i] = space[i] = 0.0 ;
		agc = 1.0 ;
		displayMux = 0 ;
		for ( i = 0; i < 1024; i++ ) {
			x = i/1024.0 ;
			if ( x < 0.1 ) x = 0.1 ;
			agcCurve[i] = x*1.1 ;
		}
	}
	return self ;
}

- (BOOL)isOpaque
{
	return YES ;
}

- (void)setFatness:(float)value
{
	fatness = value ;
}

//  create IIR filters for mark and space frequencies
- (void)setTonePair:(const CMTonePair*)tonepair
{
	float mf, sf, bw ;
	
	mf = tonepair->mark ;
	sf = tonepair->space ;
	
	if ( mf > sf ) {
		bw = sf ;
		sf = mf ;
		mf = bw ;
	}
	markFrequency = mf ;
	spaceFrequency = sf ;
	
	[ lock lock ] ;
	if ( !dj0ot ) {
		//  scale fliter bandwidth by the shift
		//  nominally set a 170 Hz shift to a filter bandwidth of 210 Hz
		bw = fabs( mf-sf )*210.0*fatness/170.0 ;
		
		if ( bw > 300 ) bw = 300 ; 
				
		bpf = CMFIRBandpassFilter( mf-150, sf+150, CMFs, 128 ) ;
		mGain = 1.5*butterworthDesign( 4, BP, bw, mf, &mPole[0], &mZero[0] ) ;
		sGain = 1.5*butterworthDesign( 4, BP, bw, sf, &sPole[0], &sZero[0] ) ;
	}
	else {
		//  notch filters not working yet...
		mGain = 100*notchDesign( 2., sf, &mPole[0], &mZero[0] ) ;
		sGain = 100*notchDesign( 2., mf, &sPole[0], &sZero[0] ) ;
	}
	[ lock unlock ] ;
}

/* local */
int alp( int low, int high, int value, int shift )
{
	int p ;
	float mapped ;
	
	if ( value > 255 ) value = 255 ;
	mapped = sqrt( value/255.0 ) ;
	p = ( low*(1-mapped) + high*mapped ) ;
	return p << shift ;
}

- (void)preSetup
{
	scaleColor = [ [ NSColor colorWithCalibratedRed:0.5 green:0.5 blue:0.5 alpha:1.0 ] retain ] ;
}

- (void)postSetup:(int)mask r:(int)rshift g:(int)gshift b:(int)bshift a:(int)ashift
{
}

- (void)createNewImageRep:(Boolean)initialize
{
	int i, rowBytes, lsize ;

	if ( depth >= 24 ) {
		//  Uses 32 bit/pixel for millions of colors mode, all components of a pixel can then be written with a single int write.
		rowBytes = width*4 ;
		lsize = size = rowBytes*height/4 ;
		bitmap = ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:bitmaps 
					pixelsWide:width pixelsHigh:height
					bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rowBytes bitsPerPixel:32 ] ;
	}
	else {
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
		for ( i = 0; i < lsize; i++ ) pixel[i] = bg32 ;
		image = [ [ NSImage alloc ] init ] ;
		[ image addRepresentation:bitmap ] ;
		[ self setImageScaling:NSScaleNone ] ;
		[ self setImage:image ] ;
	}
}

//   note: CrossedEllipse is also an AudioDest
- (void)awakeFromNib
{
	NSSize bsize ;
	float half ;
	int i, mask, rshift, gshift, bshift, ashift ;
	CMTonePair tonepair = { 2125.0, 2295.0, 45.45 } ;
	
	lock = [ [ NSLock alloc ] init ] ;
	
	depth = NSBitsPerPixelFromDepth( [ NSWindow defaultDepthLimit ] ) ;  //  m = 24, t = 12, 256 = 8
	if ( depth < 12 ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Use thousands or millions of colors", nil ) informativeText:NSLocalizedString( @"Use Display Preferences", nil ) ] ;
		exit( 0 ) ;
	}
	if ( depth < 24 ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Use Millions of Colors", nil ) informativeText:NSLocalizedString( @"Need more colors", nil ) ] ;
	}	
	
	[ self preSetup ] ;
	bsize = [ self bounds ].size ;
	width = bsize.width ;  
	height = bsize.height ;  
	scale = (int)( 0.4286*width ) ;  //  60 pixels for a 140x140 view
	
	if ( depth >= 24 ) {
		#if __BIG_ENDIAN__
		rshift = 24 ;
		gshift = 16 ;
		bshift = 8 ;
		ashift = 0 ;
		#else 
		rshift = 0 ;
		gshift = 8 ;
		bshift = 16 ;
		ashift = 24 ;
		#endif
		
		for ( i = 0; i < 512; i++ ) {
			grayScale[i] = alp( 0, 0, i, rshift ) + alp( 16, 255, i, gshift ) + alp( 0, 0, i, bshift ) + ( 0xff << ashift ) ;
		}
		plotRGB = grayScale[255] ;
		plotBackground = bg32 = grayScale[0] ;					
		size = width*height ;
		mask = 0xff ;
	}
	else {
		#if __BIG_ENDIAN__
		rshift = 12 ;
		gshift = 8 ;
		bshift = 4 ;
		ashift = 0 ;
		#else
		rshift = 4 ;
		gshift = 0 ;
		bshift = 12 ;
		ashift = 8 ;
		#endif

		for ( i = 0; i < 256; i++ ) {
			grayScale[i] = alp( 0, 0, i, rshift ) + alp( 1, 15, i, gshift ) + alp( 0, 0, i, bshift ) + ( 0xf << ashift ) ;
		}

		plotRGB = grayScale[255] ;
		plotBackground = grayScale[0] ;					
		bg32 = ( plotBackground << 16 ) | plotBackground ;  // two repeated pixels
		size = width*height/2 ;
		mask = 0xf ;
	}

	//	v1.03 handles the Max=c OS X 10.8 case (bitmapData changing)
	bitmap = nil ;
	bitmaps[0] = ( unsigned char* )malloc( sizeof( UInt32 )*( width+2 )*height ) ;
	bitmaps[1] = bitmaps[2] = bitmaps[3] = nil ;
	[ self createNewImageRep:YES ] ;
	
	//  axes
	half = width/2 + 0.5 ;
	axis = [ [ NSBezierPath alloc ] init ] ;
	[ axis moveToPoint:NSMakePoint( half, half-scale ) ] ;
	[ axis lineToPoint:NSMakePoint( half, half+scale ) ] ;
	[ axis moveToPoint:NSMakePoint( half-scale, half ) ] ;
	[ axis lineToPoint:NSMakePoint( half+scale, half ) ] ;
	
	[ self postSetup:mask r:rshift g:gshift b:bshift a:ashift ] ;
	
	//  create default mark and space filters
	dj0ot = false ;
	[ self setTonePair:&tonepair ] ;
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

//  send nil to disable
- (void)enableIndicator:(Modem*)who
{
	modem = who ;
}

//  use IIR Mark and Space filters
- (void)importDataIIR:(CMTappedPipe*)pipe
{
	CMDataStream *stream ;
	float *data, s, wm, ws, x, y, gain, agcGain, rho ;
	float mPole1, mPole2, mPole3, mPole4, mZero1 ;
	float sPole1, sPole2, sPole3, sPole4, sZero1 ;
	int i, io, samples, ox, oy, xp, yp, offset, max, dx, dy, gray ;
	Boolean widePixel ;
	UInt16 *spix ;
	
	stream = [ pipe stream ] ;
	data = stream->array ;
	samples = stream->samples ;
	
	widePixel = ( depth >= 24 ) ;
	spix = (UInt16*)pixel ;
	
	xp = width/2 ;
	yp = height/2 ;
	max = width*height - 1 ;
	gain = scale/mGain ;
	
	//  moderately BPF around the signal to remove noise
	CMPerformFIR( bpf, data, samples, bpfData ) ;
	
	//  remove [samples] of oldest phosphor values to make sure they are erased in pixel memory
	assert( samples < FADE ) ;
	io = currentOffset ;
	if ( widePixel ) {
		for ( i = 0; i < samples; i++ ) {
			offset = offsetToPhosphorDisplay[io] ;
			pixel[offset] = plotBackground ;
			io++ ;
			if ( io >= FADE ) io = 0  ;
		}
	}
	else {
		for ( i = 0; i < samples; i++ ) {
			offset = offsetToPhosphorDisplay[io] ;
			spix[offset] = plotBackground ;
			io++ ;
			if ( io >= FADE ) io = 0  ;
		}
	}
	
	mZero1 = mZero[1] ;
	mPole1 = mPole[1] ;
	mPole2 = mPole[2] ;
	mPole3 = mPole[3] ;
	mPole4 = mPole[4] ;
	sZero1 = sZero[1] ;
	sPole1 = sPole[1] ;
	sPole2 = sPole[2] ;
	sPole3 = sPole[3] ;
	sPole4 = sPole[4] ;
	
	for ( i = 0; i < samples; i++ ) {
		s = bpfData[i]  ;
		agc = 0.98*agc + 0.02*( fabs( s ) ) ;
		if ( agc > 1 ) agc = 1 ;
		
		if ( !dj0ot ) {
			//  mark filter 4th order IIR BPF (x axis)
			wm = s - mPole1*mark[0] - mPole2*mark[1] - mPole3*mark[2] - mPole4*mark[3] ;
			x = ( wm - 2*mark[1] + mark[3] ) ;
			// update mark delay line
			mark[3] = mark[2] ;
			mark[2] = mark[1] ;
			mark[1] = mark[0] ;
			mark[0] = wm ;
			//  space filter 4th order IIR (y axis)
			ws = s - sPole1*space[0] - sPole2*space[1] - sPole3*space[2] - sPole4*space[3] ;
			y = ( ws - 2*space[1] + space[3] ) ;
			//  update space delay line
			space[3] = space[2] ;
			space[2] = space[1] ;
			space[1] = space[0] ;
			space[0] = ws ;
		}
		else {
			//  mark filter 2nd order IIR Notch (x axis)
			wm = s - mPole1*mark[0] - mPole2*mark[1] ;
			x = ( wm + mZero1*mark[0] + mark[1] ) ;
			// update mark delay line
			mark[1] = mark[0] ;
			mark[0] = wm ;
			//  space filter 2nd order IIR Notch (y axis)
			ws = s - sPole1*space[0] - sPole2*space[1] ;
			y = ( ws + sZero1*space[0] + space[1] ) ;
			//  update space delay line
			space[1] = space[0] ;
			space[0] = ws ;
		}
		agcGain = gain/agcCurve[ (int)( agc*1023 ) ] ;
		
		//  x tilt:     2295=0.19
		ox = (x+0.19*y)*agcGain ;
		//  y tilt:     2125=0.19
		oy = -(y+0.19*x)*agcGain ;
		
		dy = oy+yp-1.0 ;
		dx = ox+xp ;
		if ( dy > height-1 ) dy = height-1 ; else if ( dy < 0 ) dy = 0 ;
		if ( dx > width-1 ) dx = width-1 ; else if ( dx < 0 ) dx = 0 ;
		offset = dy*width + dx ;
		if ( offset > max ) offset = max ; else if ( offset < 0 ) offset = 0 ;
		//  add the new point, update phosphor and bitmapRep
		offsetToPhosphorDisplay[currentOffset] = offset ;
		//  go to the next displayble point
		currentOffset++ ;
		if ( currentOffset >= FADE ) currentOffset = 0 ;
	}
	//  recompute phosphor decays and write to pixel memory
	rho = 500.1 ;
	io = currentOffset-1 ;
	if ( widePixel ) {
		for ( i = 0; i < FADE; i++ ) {
			if ( io < 0 ) io = FADE-1 ;
			offset = offsetToPhosphorDisplay[io] ;
			gray = rho ;
			pixel[offset] = grayScale[gray] ;
			rho *= 0.998 ;
			io-- ;
		}
	}
	else {
		for ( i = 0; i < FADE; i++ ) {
			if ( io < 0 ) io = FADE-1 ;
			offset = offsetToPhosphorDisplay[io] ;
			gray = rho ;
			spix[offset] = grayScale[gray] ;
			rho *= 0.998 ;
			io-- ;
		}
	}
}

//  assume data is 11025, 1 channel, 512 samples
- (void)importDataInMainThread:(CMPipe*)pipe
{
	NSRect currentRect ;
	
	if ( !modem ) return ;
	
	//  update data to mark and space filters
	if ( [ lock tryLock ] ) {
		[ self importDataIIR:(CMTappedPipe*)pipe ] ;
		
		//	v1.03 -- allocate new BitmapImageRep for Mountain Lion
		[ image removeRepresentation:bitmap ] ;
		[ bitmap release ] ;
		[ self createNewImageRep:NO ] ;				//  create new NSBitmapImage rep with the local buffers
		[ image addRepresentation:bitmap ] ;		
	
		if ( ( ++displayMux & 0x3 ) == 0 ) {
			//  use a smaller rect to keep refresh time down
			if ( displayMux > 16 ) {
				// once in a while, update the entire display to clean any crud
				displayMux = 0 ;
				[ self setNeedsDisplay:YES ] ;
			}
			else {
				currentRect.origin.x = currentRect.origin.y = 10 ;
				currentRect.size.width = currentRect.size.height = 120 ;
				[ self setNeedsDisplayInRect:currentRect ] ;
			}
		}
		[ lock unlock ] ;
	}
}

- (void)importData:(CMPipe*)pipe
{
	if ( !modem ) return ;
	
	[ self performSelectorOnMainThread:@selector(importDataInMainThread:) withObject:pipe waitUntilDone:NO ] ;
}

- (void)drawObjects
{
	[ scaleColor set ] ;
	[ axis stroke ] ;
}

- (void)drawRect:(NSRect)rect 
{
	[ super drawRect:rect ] ;
	[ self drawObjects ] ;
}

- (void)displayInMainThread
{
	[ self setNeedsDisplay:YES ] ;
}

- (void)clearIndicator
{
	int i ;

	for ( i = 0; i < size; i++ ) pixel[i] = bg32 ;
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)setPlotColor:(NSColor*)color ;
{
	UInt32 p ;
	
	if ( depth >= 24 ) {
		p = 0xff ; // alpha
		p |= ( (int)( [ color redComponent ]*255.5 ) ) << 24 ;
		p |= ( (int)( [ color greenComponent ]*255.5 ) ) << 16 ;
		p |= ( (int)( [ color blueComponent ]*255.5 ) ) << 8 ;
	}
	else {
		p = 0xf ; // alpha
		p |= ( (int)( [ color redComponent ]*15.5 ) ) << 12 ;
		p |= ( (int)( [ color greenComponent ]*15.5 ) ) << 8 ;
		p |= ( (int)( [ color blueComponent ]*15.5 ) ) << 4 ;
	}
	plotRGB = p ;
}

- (void)recacheImage
{
	NSImage *im ;
	
	im = [ [ self image ] retain ] ;
	[ self setImage:nil ] ;
	[ self setImage:im ] ;
	[ im release ] ;
}

@end
