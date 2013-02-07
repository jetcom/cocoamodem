//
//  MFSKIndicator.h
//  cocoaModem
//
//  Created by Kok Chen on Jan 30 2007.
//

#ifndef _MFSKINDICATOR_H_
	#define _MFSKINDICATOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CMFFT.h"

	@interface MFSKIndicator : NSImageView {
		NSImage *image ;
		NSBitmapImageRep *bitmap ;
		int width, height, size, depth, rowBytes ;
		float saved[512] ;
		NSThread *thread ;
		UInt32 intensity[20000] ;
		UInt32 *pixel ;
		float scale, exponent ;
		int cycle ;
	}

	- (void)setScale:(float)scale ;
	- (void)newSpectrum:(float*)spec ;
	- (void)newWideSpectrum:(float*)spec ;
	- (void)clear ;
	
	#define MFSKFREQOFFSET		56				//  pixels to the nominal first bin
	
	@end

#endif
