//
//  Spectrum.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Feb 3 2005.
//

#ifndef _SPECTRUM_H_
	#define _SPECTRUM_H_

	#import <AppKit/AppKit.h>
	#include "CoreFilter.h"
	#include "CoreModemTypes.h"
	#include "modemTypes.h"
	
	@interface Spectrum : NSView {
		NSRect bounds ;
		int width, height ;
		int mux ;
		float plotWidth ;
		float timeStorage[2048], spectrumStorage[2048], smoothedSpectrum[512] ;
		float ySat ;
		float scale ;
		float pixPerdB ;
		float alpha, dynamicRangeScale, dynamicRangeOffset ;
		
		NSColor *scaleColor, *spectrumColor, *backgroundColor, *markSpaceColor ;
		NSBezierPath *path, *background, *spectrumScale, *markSpace ;
		
		Boolean busy ;
		CMFFT *spectrum ;
				
		NSThread *thread ;
	}
	
	- (void)setTimeConstant:(float)t dynamicRange:(float)dr ;
	- (void)setTonePairMarker:(const CMTonePair*)tonepair ;
	- (void)addData:(CMDataStream*)stream ;
	- (void)clearPlot ;
	
	@end

#endif
