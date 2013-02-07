//
//  HellDisplay.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/26/06.

#import <Cocoa/Cocoa.h>


#ifndef _HELLDISPLAY_H_
	#define _HELLDISPLAY_H_

	#include "AYTextView.h"

	@interface HellDisplay : NSImageView {
		NSImage *image ;
		NSBitmapImageRep *bitmap ;
		
		int width, height, size, depth ;
		int rowBytes, lsize ;
		
		UInt32 *pixel ;
		UInt32 intensity[300] ;	// saturates at 255
		UInt32 echo[300] ;		// saturates at 255
		
		NSRect currentRect ;
		int row, column /* 16 pixel groups */ ;
		
		NSColor *foreground, *background, *txColor ;

		//	v 1.03 -- NSBitmapImagerep buffer
		unsigned char *bitmaps[4] ;
	}

	- (void)addColumn:(float*)column index:(int)index xScale:(int)scale ;
	
	- (void)updateColorsInView ;
	- (void)setTextColors:(NSColor*)inColor transmit:(NSColor*)inTxColor ;
	- (void)setBackgroundColor:(NSColor*)inColor ;
 
	@end

#endif
