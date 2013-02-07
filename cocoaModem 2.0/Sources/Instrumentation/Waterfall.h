//
//  Waterfall.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Aug 05 2004.
//

#ifndef _WATERFALL_H_
	#define _WATERFALL_H_

	#import <Cocoa/Cocoa.h>
	#import "CMFFT.h"

	@class Modem ;
	@class CMPipe ;
	
	@interface Waterfall : NSImageView {
	
		IBOutlet id waterfallLabel ;
		IBOutlet id waterfallTicks ;
		IBOutlet id waterfallRange ;
		IBOutlet id waterfallClip ;
		IBOutlet id noiseReductionButton ;
		IBOutlet id timeAverageButton ;
		IBOutlet id waterfallWidthButton ;

		NSImage *image ;
		NSBitmapImageRep *bitmap ;
		Modem *modem ;
		int mux ;
		int width, height, size, depth ;
		int cycle ;
		int startingBin ;
		int notch ;
		float click, optionClick ;
		float offset, optionOffset ;
		float scrollWheelRate ;
		float firstBinFreq ;
		float hzPerPixel ;
		int waterfallID ;
		NSColor *red, *magenta, *green, *black ;
		
		Boolean useControlKeyInsteadOfOptionKey ;
		Boolean noiseReduction ;
		Boolean doTimeAverage ;
		unsigned int optionMask ;
		
		NSLock *drawLock ;
		NSThread *thread ;
		UInt32 intensity[20000] ;
		UInt32 *pixel ;
		int rowBytes ;
		int sideband ; // 0 = LSB, 1 = USB
		float vfoOffset ;
		float range ;
		float exponent ;
		//  fft
		CMFFT *spectrum ;
		float timeSample[4096], freqBin[4096] ;
		id fftDelegate ;
		
		float noiseMask[1024] ;
		float denoiseBuffer[4096] ;
		int denoiseIndex ;
		
		float timeAverage[1024] ;
		float refreshRate ;
		float refreshCycle ;
		
		Boolean wideWaterfall ;
		float mostRecentTone[2] ;

		//  v0.75 currently only used in MFSKWaterfall
		float spread ;
		
		//	v 1.03 -- NSBitmapImagerep buffer
		unsigned char *bitmaps[4] ;
	}
	
	- (void)setFFTDelegate:(id)delegate ;		//  v0.57b will call client back with -newFFTBuffer
	
	- (void)awakeFromModem ;
	- (void)importData:(CMPipe*)pipe ;
	- (void)importAndDisplayData:(CMPipe*)pipe ;
	- (void)processBufferAndDisplayInMainThread:(float*)samples ;
	- (void)drawMarkers ;
	- (void)drawMarker:(float)p width:(float)width color:(NSColor*)color ;
	- (void)updateInterface ;
	
	- (void)setRefreshRate:(float)rate ;				//  v0.73
	- (Boolean)noiseReductionState ;					//  v0.73
	- (void)setNoiseReductionState:(Boolean)state ;		//  v0.73
	- (void)clearMarkers ;								//  v0.73
	
	- (void)setSpread:(float)hertz ;				//  v0.74
	
	- (void)useControlButton:(Boolean)state ;
	- (void)noiseReductionChanged ;
	- (void)timeAverageChanged ;

	- (void)setScrollWheelRate:(float)speed ;
	- (void)enableIndicator:(Modem*)who ;
	- (void)setSideband:(int)sideband ;
	- (void)setOffset:(float)freq sideband:(int)sideband ;
	- (void)setDynamicRange:(float)range ;
	- (void)setWaterfallID:(int)index ;
	- (void)moveToneTo:(float)tone receiver:(int)uniqueID ;
	- (void)forceToneTo:(float)tone receiver:(int)uniqueID ;
	
	- (void)eitherMouseDown:(NSEvent*)event secondRx:(Boolean)option ;
	- (void)arrowKeyTune:(NSNotification*)notify ;
	
	- (UInt32)plotIntensity:(float)sample ;
	
	@end

#endif
