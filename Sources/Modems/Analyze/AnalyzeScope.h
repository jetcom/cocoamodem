//
//  AnalyzeScope.h
//  cocoaModem
//
//  Created by Kok Chen on 3/4/05.
//

#ifndef _ANALYZESCOPE_H_
	#define _ANALYZESCOPE_H_

	#import <Cocoa/Cocoa.h>
	#include "CMATCTypes.h"

	@interface AnalyzeScope : NSView {
		NSRect bounds ;
		int width, height ;
		int plotWidth, plotOffset ;
		NSColor *scaleColor, *waveformColor, *backgroundColor, *baudotColor ;
		NSBezierPath *background, *waveformScale, *baudot, *plotPath ;
		int index[8] ;
		
		float refData[256], dutData[256], syncData[256], markData[256], spaceData[256], compensatedData[256], markProjection[256], spaceProjection[256] ;
	}

	- (void)updatePlot:(int)index ;
	
	- (void)addReference:(CMATCPair*)data ;
	- (void)addDUT:(CMATCPair*)data ;
	- (void)addCompensated:(CMATCPair*)data ;
	- (void)addSync:(float*)data ;
	
	@end

#endif
