//
//  CrossedEllipse.h
//  cocoaModem
//
//  Created by Kok Chen on Fri May 14 2004.
//

#ifndef _CROSSEDELLIPSE_H_
	#define _CROSSEDELLIPSE_H_


	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "CoreModemTypes.h"
	
	#define FADE	1024
	
	@class Modem ;

	@interface CrossedEllipse : NSImageView {
		NSImage *image ;
		NSBitmapImageRep *bitmap ;
		//  bitmap image
		UInt32 *pixel ;
		int width, height, size ;
		int depth ;
		UInt32 plotRGB ;
		UInt32 plotBackground ;
		UInt32 bg32 ;
		UInt32 grayScale[512] ;
		NSColor *scaleColor ;
		NSBezierPath *axis ;
		
		float scale ;
		float fatness ;
		Modem *modem ;
		float mark[4], space[4] ;
		float markFrequency, spaceFrequency ;
		//  FIR filters
		CMFIR *bpf ;
		float bpfData[512] ;
		// IIR Filters
		Boolean dj0ot ;
		float mGain, sGain ;
		double mPole[5], sPole[5] ;
		double mZero[5], sZero[5] ;
		NSLock *lock ;
		
		int offsetToPhosphorDisplay[FADE] ;
		int currentOffset ;
		float agc, agcCurve[1024] ;
		int displayMux ;
		
		NSLock *overrun ;

		//	v 1.03 -- NSBitmapImagerep buffer
		unsigned char *bitmaps[4] ;
	}
	
	- (void)preSetup ;
	- (void)postSetup:(int)mask r:(int)rshift g:(int)gshift b:(int)bshift a:(int)ashift ;
	- (void)setTonePair:(const CMTonePair*)tonepair ;
	- (void)drawObjects ;
	
	- (void)importData:(CMPipe*)pipe ;
	- (void)importDataIIR:(CMTappedPipe*)pipe ;
	
	- (void)enableIndicator:(Modem*)modem ;
	- (void)clearIndicator ;
	- (void)setPlotColor:(NSColor*)color ;
	
	- (void)setFatness:(float)value ;
	
	- (void)recacheImage ;

	@end

#endif
