//
//  FrequencyIndicator.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Sep 02 2004.
//

#ifndef _FREQUENCYINDICATOR_H_
	#define _FREQUENCYINDICATOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CMFFT.h"

	@interface FrequencyIndicator : NSImageView {
		NSImage *image ;
		NSBitmapImageRep *bitmap ;
		int width, height, size, depth, rowBytes ;
		NSThread *thread ;
		UInt32 intensity[20000] ;
		UInt32 *pixel ;
		float range, exponent ;
		Boolean sideband ;			// NO = LSB
	}

	- (void)setRange:(float)range ;
	- (void)newSpectrum:(DSPSplitComplex*)spec size:(int)size ;
	- (void)clear ;
	
	- (void)setSideband:(int)state ;	// 0 = LSB

	@end

#endif
