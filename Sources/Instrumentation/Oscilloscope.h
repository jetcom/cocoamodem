//
//  Oscilloscope.h
//  cocoaModem
//
//  Created by Kok Chen on Fri May 21 2004.
//

#ifndef _OSCILLOSCOPE_H_
	#define _OSCILLOSCOPE_H_

	#import <AppKit/AppKit.h>
	#include "CoreFilter.h"
	#include "CoreModemTypes.h"
	
	@interface Oscilloscope : NSView {
	
		IBOutlet id averageButton ;
		IBOutlet id averagePopupMenu ;
		IBOutlet id baselineButton ;
		
		NSRect bounds ;
		int width, height ;
		int style ;
		int mux ;
		int plotWidth ;
		int plotOffset ;
		float scopeFilter[192] ;
		float timeStorage[4096], spectrumStorage[4096], spectrumAverage[2048] ;
		float ySat ;
		float baseline ;			//  for average spectrum baseline equalization 
		int timebase ;
		float alpha ;
		Boolean doBaseline ;
		
		NSColor *plotColor, *scaleColor, *waveformColor, *spectrumColor, *backgroundColor, *markSpaceColor ;
		NSBezierPath *path, *path2, *scale, *background, *waveformScale, *spectrumScale, *markSpace, *baudot ;
		NSLock *pathLock ;
		NSLock *drawLock ;
		
		Boolean busy ;
		Boolean enableMarkSpace ;
		Boolean enableBaudot ;
		
		CMFIR *interpolateBy8[2], *interpolateBy2[2] ;

		CMFFT *spectrum ;
		//FFTData fftIn, fftOut ;
				
		NSThread *thread ;
	}

	- (void)setDisplayStyle:(int)inStyle plotColor:(NSColor*)plotColor ;
	- (void)setTonePairMarker:(const CMTonePair*)tonepair ;
	- (void)addData:(CMDataStream*)stream isBaudot:(Boolean)inBaudot timebase:(int)timebase ;
	- (void)selectTimeConstant:(int)n ;
	
	@end

#endif
