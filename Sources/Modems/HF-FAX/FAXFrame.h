//
//  FAXFrame.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/24/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define	MAXFAXHEIGHT	3200
#define	MAXBACKING		((MAXFAXHEIGHT+64)*2000)			// allow 600 scanline headroom and 2000 samples wide
#define BACKGROUND		112									//  gary background value


//  backing store parameters
typedef struct {
	int origin ;					//  point to origin in backing[], this number is always less than MAXBACKING
	int rows ;
	float correction ;				//  fractional correction of frame
	int input ;						//  next input location.  offset from frameOrigin, this number can be greater than MAXBACKING
	int mark ;						//  location to process data, offset from frameOrigin, this number can be greater than MAXBACKING
	int horizontalOffset ;	
	unsigned char *backing ;
	unsigned char *intensity ;	
	Boolean halfSize ;
	int displayRow, skipRow ;
} BackingFrame ;


@interface FAXFrame : NSObject {
	NSImage *image ;
	NSBitmapImageRep *bitmapRep ;
	BackingFrame frame ;

	NSLock *imageLock ;
	NSLock *bitmapRepLock ;
	NSLock *updateLock ;
	NSLock *dumpLock ;
	
	unsigned char *pixelBuffer ;
	int width, height, rowBytes, lsize, viewHeight ;
	int scrollOffset ;
	
	//  resampling by 11025/(IOC*pi*2) nominal decimation
	int IOC ;
	float imageWidth ;			//  fractional width based on IOC
	int actualWidth ;			//  width truncated to integer pixels
	float decimationRatio ;
	float inputImageWidth ;		//  actual fractional sample length of 1/2 second of data
	float ppm ;
	
	//  v0.81  save folder
	NSString *alternateFolder ;
}

- (id)initWidth:(int)w height:(int)h ;
- (void)resetFrame ;

- (NSImage*)image ;
- (BackingFrame*)backingFrame ;

- (void)swapImageRep ;

- (void)drawLineAtRow:(int)row ;
- (int)drawLineInFrameAtRow:(int)row refresh:(Boolean)refresh ;
- (int)drawLineAndAdvanceRow ;
- (void)redrawFrame ;

- (void)markDisplayRow ;
- (void)setFrameMark:(int)offset ;

- (void)dumpCurrentFrameToFolder:(NSString*)folder ;

//	image position
- (void)startNewImage ;
- (void)setHorizontalOffset:(int)position ;
- (void)clearSwath:(int)ht ;
- (int)frameOrigin ;
- (int)frameOffsetForSample:(int)h ofRow:(int)v ;
- (void)setSamplingParameters ;
- (void)setScrollOffset:(int)offset ;

- (Boolean)passedMark ;
- (void)setPPM:(float)p ;
- (void)setHalfSize:(Boolean)isHalfSize ;
- (void)mouseDownAt:(float)position ;

//	image intensity
- (void)setGrayscaleFrom:(float)black to:(float)white ;
- (void)addPixel:(int)v ;
- (int)pixelAtSample:(int)h ofRow:(int)v ;

@end
