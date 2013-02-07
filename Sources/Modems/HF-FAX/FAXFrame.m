//
//  FAXFrame.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/24/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "FAXFrame.h"


@implementation FAXFrame

//  (Private API)
- (NSBitmapImageRep*)createNewImageRep:(unsigned char*)pixbuf topOffset:(int)offset height:(int)length
{
	unsigned char *plane[3] ;
	
	plane[0] = pixbuf + offset*rowBytes ;		//  top of image
	plane[1] = nil ;
	plane[2] = nil ;

	return ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:&plane[0]
				pixelsWide:width 
				pixelsHigh:length
				bitsPerSample:8 
				samplesPerPixel:1 
				hasAlpha:NO 
				isPlanar:NO
				colorSpaceName:@"NSCalibratedWhiteColorSpace" 
				bytesPerRow:rowBytes bitsPerPixel:8 ] ;
}

//  (Private API)
- (NSBitmapImageRep*)createNewHalfsizeImageRep:(unsigned char*)pixbuf height:(int)length
{
	unsigned char *plane[3] ;
	
	plane[0] = pixbuf  ;		//  top of image
	plane[1] = nil ;
	plane[2] = nil ;

	return ( NSBitmapImageRep* )[ [ NSBitmapImageRep alloc ] initWithBitmapDataPlanes:&plane[0]
				pixelsWide:width/2 
				pixelsHigh:length/2
				bitsPerSample:8 
				samplesPerPixel:1 
				hasAlpha:NO 
				isPlanar:NO
				colorSpaceName:@"NSCalibratedWhiteColorSpace" 
				bytesPerRow:rowBytes bitsPerPixel:8 ] ;
}

//	A FAXFrame consists of the NSImage, NSImageRep and a BackingFrame
- (id)initWidth:(int)w height:(int)h
{
	int bufsize ;
	
	self = [ super init ] ;
	if ( self ) {
		width = w ;
		height = h ;
		rowBytes = ( ( width+3 )/4 )*4 ;
		lsize = rowBytes*height ;

		//  local buffer to NSBitmapImageRep
		bufsize = rowBytes*MAXFAXHEIGHT*3 ;
		pixelBuffer = (unsigned char*)malloc( bufsize ) ;
		memset( pixelBuffer, BACKGROUND, bufsize ) ;	
				
		scrollOffset = 0 ;
		bitmapRep = [ self createNewImageRep:pixelBuffer topOffset:scrollOffset height:height ] ;
		bitmapRepLock = [ [ NSLock alloc ] init ] ;

		//  create backing memory
		frame.halfSize = YES ;
		frame.intensity = (unsigned char*)malloc(256) ;
		frame.backing = (unsigned char*)malloc(MAXBACKING) ;
		
		image = [ [ NSImage alloc ] init ] ;
		[ image addRepresentation:bitmapRep ] ;
		imageLock = [ [ NSLock alloc ] init ] ;
		dumpLock = [ [ NSLock alloc ] init ] ;
		
		alternateFolder = nil ;
	}
	return self ;
}

- (void)dealloc
{
	free( frame.backing ) ;
	free( frame.intensity ) ;
	free( pixelBuffer ) ;
	[ bitmapRepLock release ] ;
	[ imageLock release ] ;
	[ dumpLock release ] ;
	[ image release ] ;
	[ super dealloc ] ;
}

- (void)resetFrame
{
	frame.displayRow = frame.origin = frame.input = frame.mark = 0 ;
	frame.correction = 0.0 ;
}

// v0.80 generate a new bitmapImageRep (with proper scrollOffset) to fool the Snow Leopard cache
- (NSBitmapImageRep*)updateGrayImageRep
{
	[ bitmapRepLock lock ] ;
	[ bitmapRep release ] ;
	bitmapRep = [ self createNewImageRep:pixelBuffer topOffset:scrollOffset height:height ] ;
	[ bitmapRepLock unlock ] ;
	
	return bitmapRep ;
}

- (NSImage*)image
{
	return image ;
}

- (BackingFrame*)backingFrame
{
	return &frame ;
}

- (Boolean)passedMark
{
	return ( frame.input > frame.mark ) ;
}

//  Swap to a new NSBitmapImageRep, since Snow Leopard appears to cache it	
//	This is called whenever the image changes and needs to be displayed on the screen
- (void)swapImageRep
{
	[ imageLock lock ] ;
	// remove the old rep
	[ image removeRepresentation:bitmapRep ] ;
	//	and replace with a new one
	[ image addRepresentation:[ self updateGrayImageRep ] ] ;
	[ imageLock unlock ] ;
}

int dump = 0 ;

//  image a line into the backing store
- (void)drawLineAtRow:(int)row
{
	unsigned char *dest, u ;
	int i, i0, i1, avg, imagePointerOffset, previousRow ;
	float sum ;
	double p, p0, p1 ;
	
	if ( frame.halfSize ) {
		if ( ( row & 1 ) == 0 ) return ;

		previousRow = ( row+MAXFAXHEIGHT-1 ) % MAXFAXHEIGHT ;				// previous scanline
		//  process half sized image only once per scanline
		imagePointerOffset = ( ( row-frame.skipRow )/2 ) % MAXFAXHEIGHT ;
		dest = pixelBuffer + ( imagePointerOffset*rowBytes ) ;
		
		//  beginning of line (0) and previous line (1)
		p = frame.origin + frame.horizontalOffset*decimationRatio + 0.5 ;
		p0 = p + row*inputImageWidth ;
		p1 = p + previousRow*inputImageWidth ;
		
		for ( i = 0; i < 1808; i += 2 ) {
			if ( i == 0 || i == 1806 ) {
				//  nearest neighbor average for first and last sample of scanline
				i0 = p0 ;
				i1 = p1 ;
				avg = frame.backing[ i0%MAXBACKING ] + frame.backing[ i1%MAXBACKING ] ;
				i0 = ( p0 += decimationRatio ) ;
				i1 = ( p1 += decimationRatio ) ;
				avg += frame.backing[ i0%MAXBACKING ] + frame.backing[ i1%MAXBACKING ] ;
				*dest++ = frame.intensity[ avg/4 ] ;
			}
			else {
				//  Hamming window the fast scan direction
				i0 = p0 ;
				i1 = p1 ;
				sum = frame.backing[ i0%MAXBACKING ] + frame.backing[ i1%MAXBACKING ] ;
				i0 = ( p0 += decimationRatio ) ;
				i1 = ( p1 += decimationRatio ) ;
				sum += ( frame.backing[ i0%MAXBACKING ] + frame.backing[ i1%MAXBACKING ] )*2.348 ;
				i0 = ( p0 += decimationRatio ) ;
				i1 = ( p1 += decimationRatio ) ;
				sum += frame.backing[ i0%MAXBACKING ] + frame.backing[ i1%MAXBACKING ] ;
				avg = ( sum+0.5 )/8.696 ;
				*dest++ = frame.intensity[ avg ] ;
			}
		}
	}
	else {
		// full sized
		imagePointerOffset = ( row - frame.skipRow ) % MAXFAXHEIGHT ;
		dest = pixelBuffer + ( imagePointerOffset*rowBytes ) ;
		p0 = frame.origin + frame.horizontalOffset*decimationRatio + row*inputImageWidth + 0.5 ;  //  v0.57d

		for ( i = 0; i < 1809; i++ ) {
			i0 = p0 ;
			avg = frame.backing[ i0%MAXBACKING ] ;
			p0 += decimationRatio ;
			u = frame.intensity[ avg ] ;
			*dest++ = u ;
		}
	}
	[ self performSelectorOnMainThread:@selector(swapImageRep) withObject:nil waitUntilDone:YES ] ;
}

- (void)drawEmptyLineAtRow:(int)row
{
	unsigned char *dest ;
	int i, imagePointerOffset, previousRow ;
	
	if ( frame.halfSize ) {
		if ( ( row & 1 ) == 0 ) return ;

		previousRow = ( row+MAXFAXHEIGHT-1 ) % MAXFAXHEIGHT ;				// previous scanline
		//  process half sized image only once per scanline
		imagePointerOffset = ( ( row - frame.skipRow )/2 ) % MAXFAXHEIGHT ;
		dest = pixelBuffer + ( imagePointerOffset*rowBytes ) ;
		
		for ( i = 0; i < 1808; i += 2 ) *dest++ = row * 0.1 ; //BACKGROUND ;
	}
	else {
		// full sized
		imagePointerOffset = ( row - frame.skipRow ) % MAXFAXHEIGHT ;
		dest = pixelBuffer + ( imagePointerOffset*rowBytes ) ;
		
		for ( i = 0; i < 1809; i++ ) *dest++ = BACKGROUND ;
	}
}

- (void)clearSwath:(int)ht
{
	//  clear a swath of NSImage bitmap, this leaves a 32 pixel black space to old image
	memset( pixelBuffer, BACKGROUND, rowBytes*32 ) ;
}

- (int)drawLineInFrameAtRow:(int)row refresh:(Boolean)refresh
{
	int p ;
	unsigned char *dest ;
	
	if ( row < frame.skipRow ) return 0 ;

	[ self drawLineAtRow:row ] ;
	
	if ( refresh ) {
		if ( frame.halfSize ) row /= 2 ;
		//  erase a line that is 32 pixels lower, this should leave a 32 pixel black border to the old image
		p = row-frame.skipRow+32 ;
		if ( p < MAXFAXHEIGHT ) {
			dest = pixelBuffer + ( p*rowBytes ) ;
			memset( dest, BACKGROUND, rowBytes ) ;
		}
		return p ;
	}
	return 0 ;
}

- (int)drawLineAndAdvanceRow
{
	return [ self drawLineInFrameAtRow:frame.displayRow++ refresh:YES ] ;
}

- (void)redrawFrame
{
	int i, n, m ;
	
	//  update all visible scanlines
	n = frame.skipRow ;
	m = frame.displayRow ;
	
	for ( i = n; i < m; i++ ) [ self drawLineAtRow:i ] ;

	frame.mark = [ self frameOffsetForSample:1 ofRow:(frame.displayRow+1) ] ;		
	[ self setSamplingParameters ] ;
}

//  set the horizontal offset (adjusted by decimation ratio)
- (void)setHorizontalOffset:(int)position
{
	frame.horizontalOffset += position/decimationRatio ;
	frame.horizontalOffset %= 1809 ;
	frame.skipRow = frame.displayRow ;
}

- (void)setScrollOffset:(int)offset
{
	scrollOffset = offset ;
}

//  position frame parameters to the start of a new image
- (void)startNewImage
{
	frame.origin = ( frame.horizontalOffset + [ self frameOffsetForSample:0 ofRow:frame.displayRow ] ) % MAXBACKING ;		// new image starts at the end of old image	
	frame.displayRow = frame.skipRow = 0 ;
	frame.input = 0 ;
	frame.mark = [ self frameOffsetForSample:2 ofRow:(frame.displayRow+1 ) ] ;				// trigger point for dumping row
	[ self clearSwath:32 ] ;
}

//  create a grayscale table
//	this table is recomputed each time the black lebel and contrast sliders change
- (void)setGrayscaleFrom:(float)black to:(float)white
{
	float range ;
	int i, v ;
	
	range = white - black ;
	
	for ( i = 0; i < 256; i++ ) {
		v = ( i - black )*256./range ;
		if ( v < 0 ) v = 0 ; else if ( v > 255 ) v = 255 ;
		frame.intensity[i] = v ;
	}
}

- (void)addPixel:(int)v
{
	int index ;
	
	index = ( frame.origin+frame.input )%MAXBACKING ;
	frame.backing[ index ] = v ;
	frame.input++ ;
}

- (int)pixelAtSample:(int)h ofRow:(int)v
{
	int offset ;
	
	offset = ( frame.origin + [ self frameOffsetForSample:h ofRow:v ] ) % MAXBACKING ;
	return frame.backing[offset] ;
}

 //  compute offset from frame.origin into the oversample buffet for a real pixel at (h,v)
- (int)frameOffsetForSample:(int)h ofRow:(int)v
{
	return (int)( ( h + frame.horizontalOffset )*decimationRatio + v*inputImageWidth + 0.5 ) ;
}

- (int)frameOrigin
{
	return frame.origin ;
}

//  -setSamplingParameters will pickk this up
- (void)setPPM:(float)p
{
	ppm = p ;
}

- (void)setHalfSize:(Boolean)isHalfSize
{
	frame.halfSize = isHalfSize ;
}

//  change decimation ratio and fractional width of the FAX transmission
- (void)setSamplingParameters
{
	IOC = 576 ;										// fix IOC to 576 for now
	//  resampling parameters
	imageWidth = IOC*3.1415926 ;					// fractional width
	actualWidth = imageWidth ;						// integral width
	//  decimation
	decimationRatio = ( 11025.0/( IOC*3.1415926535*2 ) ) * ( 1.0+ppm/1000000.0 ) ;
	inputImageWidth = imageWidth*decimationRatio ;	// actual 1/2 second of data
}

- (void)markDisplayRow
{
	frame.rows = frame.displayRow ;
}

- (void)setFrameMark:(int)offset
{
	frame.mark = [ self frameOffsetForSample:1 ofRow:( frame.displayRow+offset ) ] ;	
}

//  horizontal positioning
- (void)mouseDownAt:(float)position
{	
	if ( frame.halfSize ) position *= 2 ;
	if ( position < 0 || position > 1808 ) return ;
	frame.horizontalOffset += position ;
	frame.horizontalOffset %= 1809 ;
	memset( pixelBuffer, BACKGROUND, lsize ) ;
}

// ---------------- save to PDF --------------------

- (void)drawFAXFromFrame:(BackingFrame*)frame
{
	printf( "FAXFrame: need to implement drawFAXFromFrame\n" ) ;
	
	/*
	int i ;
	
	[ self setSamplingParameters ] ;
	//  update all scanlines
	for ( i = frame->skipRow; i < frame->displayRow; i++ ) [ self drawLineAtRow:i ] ;
	for ( ; i < frame->rows; i++ ) [ faxFrame drawEmptyLineAtRow:i ] ;
	*/
}

//	this is executed in the main thread
- (void)dumpFrame:(NSString*)folder
{
	NSBitmapImageRep *imageRep ;
	NSData *imageData ;
	NSImage *frameImage ;
	NSImageView *pdfView ;
	NSSize size ;
	NSRect pdfRect ;
	NSString *name, *date, *filename ;
	unsigned char *imageBuffer ;
	int rows, button ;
	float scale ;
	Boolean halfsize ;
	BOOL isDirectory ;

	//  v0.81 find dimensions and make copy of the bitmap memory
	rows = frame.displayRow - frame.skipRow + 1 ;
	if ( rows < 1 ) rows = 1 ;
	halfsize = frame.halfSize ;
	
	imageBuffer = (unsigned char*)malloc( rowBytes*rows ) ;
	memcpy( imageBuffer, pixelBuffer, rowBytes*rows ) ;
	
	//  now check if folder exist
	folder = [ folder stringByExpandingTildeInPath ] ;
	if ( [ [ NSFileManager defaultManager ] fileExistsAtPath:folder isDirectory:&isDirectory ] == NO || isDirectory == NO ) {
		button = [ [ NSAlert alertWithMessageText:@"FAX folder not found.  Save to your home directory instead?" defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:NSLocalizedString( @"Cancel", nil ) otherButton:nil informativeTextWithFormat:[ NSString stringWithFormat:@"\nFolder %@ is not found.\n", folder ] ] runModal ] ;
		if ( button != 1 ) {
			free( imageBuffer ) ;
			return ;
		}
		folder = alternateFolder = [ [ @"~" stringByExpandingTildeInPath ] retain ] ;
	}
	name = [ [ folder stringByExpandingTildeInPath ] stringByAppendingString:@"/fax " ] ;
	date = [ [ NSDate date ] descriptionWithCalendarFormat:@"%Y-%m-%d %H%M.pdf" timeZone:[ NSTimeZone timeZoneForSecondsFromGMT:0 ] locale:nil ] ;
	filename = [ name stringByAppendingString:date ] ;
	
	if ( halfsize ) {
		imageRep = [ self createNewHalfsizeImageRep:imageBuffer height:rows ] ;
	}
	else {
		imageRep = [ self createNewImageRep:imageBuffer topOffset:0 height:rows ] ;
	}
	if ( imageRep ) {
		imageData = [ imageRep TIFFRepresentation ] ;
		if ( imageData ) {
			//  create a scaled PDF version of the image
			frameImage = [ [ NSImage alloc ] initWithData:imageData ] ;
			if ( frameImage ) {
				scale = 1.0 ;
				size = [ frameImage size ] ;
				pdfView = [ [ NSImageView alloc ] init ] ;
				if ( pdfView ) {
					[ pdfView setImage:frameImage ] ;
					[ pdfView setFrame:NSMakeRect( 0.0, 0.0, size.width, size.height ) ] ;
					pdfRect = [ pdfView bounds ] ;
					if ( halfsize ) {
						pdfRect.origin.y = pdfRect.size.height-rows*0.5 ;
						pdfRect.size.height = rows*0.5 ;			
					}
					imageData = [ pdfView dataWithPDFInsideRect:pdfRect ] ;
					if ( imageData ) [ imageData writeToFile:filename atomically:YES ] ;
					[ pdfView release ] ;
				}
				[ frameImage release ] ;
			}
		}
		[ imageRep release ] ;
	}
	free( imageBuffer ) ;
}

- (void)dumpCurrentFrameToFolder:(NSString*)folder
{
	int button ;
	
	[ dumpLock lock ] ;	
	if ( alternateFolder != nil ) folder = alternateFolder ;	
	if ( folder == nil || [ folder length ] <= 0 ) {
		button = [ [ NSAlert alertWithMessageText:@"FAX folder has not been set up.  Save to your home directory instead?" defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:NSLocalizedString( @"Cancel", nil ) otherButton:nil informativeTextWithFormat:@"" ] runModal ] ;
		if ( button != 1 ) {
			[ dumpLock unlock ] ;
			return ;
		}
		alternateFolder = folder = [ [ @"~" stringByExpandingTildeInPath ] retain ] ;
	}
	[ self performSelectorOnMainThread:@selector(dumpFrame:) withObject:folder waitUntilDone:YES ] ;
	[ dumpLock unlock ] ;
}


@end
