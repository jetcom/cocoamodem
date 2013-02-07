//
//  MFSKIndicatorLabel.h
//  cocoaModem
//
//  Created by Kok Chen on Jan 30 2007.
//

#ifndef _MFSKINDICATORLABEL_H_
	#define _MFSKINDICATORLABEL_H_

	#import <Cocoa/Cocoa.h>
	#include "CMFFT.h"

	@interface MFSKIndicatorLabel : NSImageView {
		int width, height ;
		NSBezierPath *background ;
		int offset ;
		Boolean locked ;
		NSColor *color ;
		int bins ;
	}
	- (void)setBins:(int)value ;			//  v0.73
	- (void)setOffset:(int)index ;
	- (void)setAbsoluteOffset:(int)index ;
	- (void)clear ;

	@end

#endif
