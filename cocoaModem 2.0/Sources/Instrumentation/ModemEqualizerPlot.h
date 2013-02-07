//
//  ModemEqualizerPlot.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/30/06.

#ifndef _MODEMEQUALIZERPLOT_H_
	#define _MODEMEQUALIZERPLOT_H_

	#import <Cocoa/Cocoa.h>


	@interface ModemEqualizerPlot : NSView {
		NSRect bounds ;
		int width, height ;

		NSColor *plotColor, *scaleColor, *backgroundColor ;
		NSBezierPath *plot, *scale, *background ;
	}

	- (void)setResponse:(float*)array ;
	
	@end

#endif
