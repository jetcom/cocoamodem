//
//  HellDisplay.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/26/06.
	#include "Copyright.h"


#import "HellDisplay.h"
#include "DisplayColor.h"
#include "Messages.h"


@implementation HellDisplay

//  receiveView of Hellschreiber.m
//  size of image is 900 pixels wide and 512 high inside a scollview that is 288 pixels high

- (void)setGrayscale:(NSColor*)back to:(NSColor*)fore index:(int)index
{
	float r, g, b, r0, g0, b0, r1, g1, b1, t, u, alpha ;
	int i ;
	UInt32 gray ;
	
	[ back getRed:&r0 green:&g0 blue:&b0 alpha:&alpha ] ;
	[ fore getRed:&r1 green:&g1 blue:&b1 alpha:&alpha ] ;

	for ( i = 0; i < 300; i++ ) {
		t = i/255.0 ;
		if ( t > 1.0 ) t = 1.0 ;
		u = 1.0 - t ;		
		
		r = u*r0 + t *r1 ;
		g = u*g0 + t *g1 ;
		b = u*b0 + t *b1 ;
		
		if ( depth >= 24 ) {
			gray = [ DisplayColor millionsOfColorsFromRed:r green:g blue:b ] ;
			if ( index == 0 ) intensity[i] = gray ; else echo[i] = gray ;
		}
		else {
			gray = [ DisplayColor thousandsOfColorsFromRed:r green:g blue:b ] ;
			if ( index == 0 ) intensity[i] = gray ; else echo[i] = gray ;
		}
	}
}

- (void)createNewImageRep:(Boolean)initialize
{
	UInt32 bg ;
	int i ;

	if ( depth >= 24 ) {
		bg = intensity[0] ;
		//  Uses 32 bit/pixel for millions of colors mode, all components of a pixel can then be written with a single int write.
		rowBytes = width*4 ;
		lsize = size = rowBytes*height/4 ;
		bitmap = ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:bitmaps 
					pixelsWide:width pixelsHigh:height
					bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
					colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:rowBytes bitsPerPixel:32 ] ;
	}
	else {
		bg = ( intensity[0] << 16 ) | intensity[0] ;
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
		for ( i = 0; i < lsize; i++ ) pixel[i] = bg ;
		image = [ [ NSImage alloc ] init ] ;
		[ image addRepresentation:bitmap ] ;
		[ self setImageScaling:NSScaleNone ] ;
		[ self setImage:image ] ;
	}
}

- (id)initWithFrame:(NSRect)frame
 {
	NSSize bsize ;

    self = [ super initWithFrame:frame ];
    if ( self ) {
	
		row = 512-36 ;
		column = 0 ;
		
		background = [ [ NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0 ] retain ] ;
		foreground = [ [ NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:0 ] retain ] ;
		txColor = [ [ NSColor colorWithCalibratedRed:0.0 green:1.0 blue:1.0 alpha:0 ] retain ] ;
		
		//  check window depth
		depth = NSBitsPerPixelFromDepth( [ NSWindow defaultDepthLimit ] ) ;  //  m = 24, t = 12, 256 = 8
		if ( depth < 24 ) {
			[ Messages alertWithMessageText:NSLocalizedString( @"Use Millions of Colors", nil ) informativeText:NSLocalizedString( @"Use Display Preferences", nil ) ] ;
			exit( 0 ) ;
		}	
		bsize = [ self bounds ].size ;
		width = bsize.width ;  
		height = bsize.height ;  

		[ self setGrayscale:background to:foreground index:0 ] ;
		[ self setGrayscale:background to:txColor index:1 ] ;
		
		//	v1.03 handles the Max=c OS X 10.8 case (bitmapData changing)
		bitmap = nil ;
		bitmaps[0] = ( unsigned char* )malloc( sizeof( UInt32 )*( width+2 )*height ) ;
		bitmaps[1] = bitmaps[2] = bitmaps[3] = nil ;
		[ self createNewImageRep:YES ] ;
	
    }
    return self;
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

- (BOOL)isOpaque
{
	return YES ;
}

- (void)setTextColors:(NSColor*)inColor transmit:(NSColor*)inTxColor
{
	NSColor *old ;
	
	old = foreground ;
	foreground = [ inColor retain ] ;
	if ( old ) [ old release ] ;
	[ self setGrayscale:background to:foreground index:0 ] ;
	
	old = txColor ;
	txColor = [ inTxColor retain ] ;
	if ( old ) [ old release ] ;
	[ self setGrayscale:background to:txColor index:1 ] ;
}

- (void)setBackgroundColor:(NSColor*)inColor
{
	NSColor *old ;
	
	old = background ;
	background = [ inColor retain ] ;
	if ( old ) [ old release ] ;
	[ self setGrayscale:background to:foreground index:0 ] ;
}

//  local
- (void)displayInMainThread
{
	[ self setNeedsDisplay:YES ] ;
}

//  local
- (void)displayInCurrentRect
{
	[ self setNeedsDisplayInRect:currentRect ] ;
}

//  clear to background colors
- (void)updateColorsInView
{
	int i ;
	
	for ( i = 0; i < lsize; i++ ) pixel[i] = intensity[0] ;
	[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
}

//  add a column of 28 half-pixels of data, magnified by 2
//  (the column is expanded into two pixel columns)
- (void)addColumn:(float*)columnData index:(int)index xScale:(int)scale
{
	int i, j, k, rowIncr, lastColumn ;
	UInt32 *ptr, *qtr, clear, *gray ;
	float x ;
	char *src ;
	Boolean refreshAll ;
	
	if ( row >= 512 ) {
		row = 512 - 1 ;
		return ;
	}
	gray = ( index == 0 ) ? &intensity[0] : &echo[0] ;
	
	//	v1.03 -- allocate new BitmapImageRep for Mountain Lion
	[ image removeRepresentation:bitmap ] ;
	[ bitmap release ] ;
	[ self createNewImageRep:NO ] ;				//  create new NSBitmapImage rep with the local buffers
	[ image addRepresentation:bitmap ] ;		
	pixel = ( UInt32* )[ bitmap bitmapData ] ;	//  this should retrieve the local buffer pointer	
	
	if ( depth >= 24 ) {
		refreshAll = NO ;
		rowIncr = rowBytes/4 ;
		for ( i = 0; i < scale; i++ ) {
			ptr = pixel + ( (row+31)*rowIncr + column ) ;
			for ( j = 0; j < 28; j++ ) {
				*ptr = gray[ (int)( columnData[j]*255.4 ) ] ;
				ptr -= rowIncr ;
			}
			column++ ;
			lastColumn = 900 ;			
			if ( column >= lastColumn-35 ) {
				row -= 1 ;
				// move data up one pixel row
				src = ( ( char* )pixel ) + rowBytes ;
				memcpy( pixel, src, rowBytes*( height-1 ) ) ;
				// clear last row
				ptr = pixel + ( (height-1)*rowIncr ) ;
				clear = ( column == (lastColumn - 35) ) ? gray[64] : gray[0] ;
				for ( j = 0; j < rowIncr; j++ ) *ptr++ = clear ;
				if ( column >= lastColumn ) {
					column = 0 ;
					row += 36 ;
					//  now copy the tail of the old line into the new line
					for ( k = 0; k < 31; k++ ) {
						ptr = pixel + ( (height-1-k)*rowIncr ) ;
						qtr = pixel + ( (height-37-k)*rowIncr + lastColumn-20 ) ;
						for ( j = 0; j < 20; j++ ) ptr[j] = qtr[j] ;
					}
					column += 20 ;
				}
				refreshAll = YES ;
			}
		}
		if ( refreshAll ) [ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:nil waitUntilDone:NO ] ;
		else {
			// refresh only newly changed pixels
			x = column - 4 ;
			if ( x < 0 ) x = 0 ;
			currentRect = NSMakeRect( x, 0, 8, 32 ) ;	
			[ self performSelectorOnMainThread:@selector(displayInCurrentRect) withObject:nil waitUntilDone:NO ] ;
		}
	}
}

- (void)drawRect:(NSRect)rect 
{
	[ super drawRect:rect ] ;
}

@end
