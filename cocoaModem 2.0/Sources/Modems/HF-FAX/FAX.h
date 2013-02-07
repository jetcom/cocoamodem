//
//  FAX.h
//  cocoaModem
//
//  Created by Kok Chen on Mar 6 2006.
//

#ifndef _FAX_H_
	#define _FAXR_H_

	#import <Cocoa/Cocoa.h>
	#include "Modem.h"
	
	typedef struct {
		CGContextRef context ;
		unsigned char *bitmap ;
		int rowBytes ;
		int width ;
		int height ;
		int size ;
	} BitmapContext ;
	
	@class FAXConfig ;
	@class FAXReceiver ;
	@class FAXDisplay ;
	@class ModemDistributionBox ;
	@class VUMeter ;

	@interface FAX : Modem {
	
		IBOutlet id waterfall ;
		
		IBOutlet id inputAttenuator ;
		IBOutlet id vuMeter ;

		IBOutlet id bandwidthMenu ;
		
		//   AudioPipes
		FAXReceiver *rx ;
		
		NSThread *thread ;
		
		//  demodulator
		float vfoOffset ;
		int sideband ;
				
		//  Prefs
		Boolean sidebandState ;
		// receive
		NSTimer *receiveWait ;
	}
	
	- (FAXConfig*)configObj ;
	- (VUMeter*)vuMeter ;
	- (FAXDisplay*)faxView ;
	
	- (void)frequencyUpdatedTo:(float)tone ;

	- (void)selectAlternateSideband:(Boolean)state ;
	- (void)setWaterfallOffset:(float)freq sideband:(int)sideband ;
	- (void)receiveFrequency:(float)freq ;
	
	@end

#endif
