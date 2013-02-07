//
//  Hellschreiber.h
//  cocoaModem
//
//  Created by Kok Chen on Wed Jul 27 2005.
//

#ifndef _HELLSCHREIBER_H_
	#define _HELLSCHREIBER_H_

	#import <Cocoa/Cocoa.h>
	#include "ContestInterface.h"
	#include "AYTextView.h"
	#include "HellschreiberFont.h"
	
	typedef struct {
		CGContextRef context ;
		unsigned char *bitmap ;
		int rowBytes ;
		int width ;
		int height ;
		int size ;
	} FAXBitmapContext ;
	
	@class HellConfig ;
	@class HellReceiver ;
	@class ModemDistributionBox ;
	@class VUMeter ;

	@interface Hellschreiber : ContestInterface {
	
		IBOutlet id waterfall ;
		IBOutlet id transmitButton ;
		IBOutlet id transmitLight ;
		
		IBOutlet id slopeSlider ;
		IBOutlet id upButton ;
		IBOutlet id downButton ;
		IBOutlet id fontMenu ;
		IBOutlet id modeMenu ;

		IBOutlet id inputAttenuator ;
		IBOutlet id vuMeter ;
		
		//   AudioPipes
		HellReceiver *rx ;
		
		NSThread *thread ;
		
		//  demodulator
		float vfoOffset ;
		int sideband ;
		Boolean frequencyLocked ;
				
		//  Prefs
		Boolean sidebandState ;
		int alignedFont ;
		int unalignedFont ;
		
		//  transmit
		NSLock *transmitViewLock ;
		NSTimer *transmitBufferCheck ;
		int indexOfUntransmittedText ;
		TextAttribute *transmitAttribute ;
		Boolean frequencyDefined ;
		// receive
		NSTimer *receiveWait ;
		TextAttribute *textAttribute ;

		int fonts ;
		HellschreiberFontHeader *font[10] ;
		Boolean modeNeedsAlignedFont ;
	}
	
	- (IBAction)flushTransmitStream:(id)sender ;
	
	- (void)modeChanged ;
	
	- (HellConfig*)configObj ;
	- (VUMeter*)vuMeter ;
	
	- (Boolean)checkTx ;
	- (float)transmitFrequency ;
	- (Boolean)transmitting ;
	- (void)flushOutput ;
	- (void)flushAndLeaveTransmit ;
	
	- (void)frequencyUpdatedTo:(float)tone ;

	- (void)selectAlternateSideband:(Boolean)state ;
	- (void)setWaterfallOffset:(float)freq sideband:(int)sideband ;
	- (void)receiveFrequency:(float)freq ;
	
	- (void)addFont:(HellschreiberFontHeader*)font index:(int)index ;
	- (void)setAlignedFont:(NSString*)name ;
	- (void)setUnalignedFont:(NSString*)name ;
	
	//  callback from PSK generator
	- (void)changeTransmitStateTo:(Boolean)state ;
	
	//  demodulated data
	- (void)addColumn:(float*)column index:(int)index xScale:(int)scale ;

	@end
	
	//  modeMenu tags
	#define	HELLFELD		0
	#define	HELLFM245		1
	#define	HELLFM105		2


#endif
