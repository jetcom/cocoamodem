//
//  PSKDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/11/07.
	#include "Copyright.h"
	
#ifndef _PSKDEMODULATOR_H_
	#define _PSKDEMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#import "CMFIR.h"
	#import "CMPSKDemodulator.h"

	typedef struct {
		float imd ;
		float carrier ;
		float noise ;
	} IMDBuffer ;
	
	@class PSK ;
	
	@interface PSKDemodulator : CMPSKDemodulator {
	
		CMComplexFIR *decimate125 ;		// v0.64f
		Boolean psk125 ;
	
		float previousClockSample ;
		int bitSyncPhase ;
		float previousI, previousQ ;		//  simple I,Q from wideband channel
		
		float speci[2048], specq[2048] ;
		
		//  frequency indicator
		int freqIndicatorMux ;
		float freqIndicatorBufI[1024], freqIndicatorBufQ[1024] ;
		int imdMux ;
		float imdBufI[512], imdBufQ[512] ;
		
		//  AFC
		CMFIR *acqFilterI, *acqFilterQ ;
		float freqError, freqErrors[32] ;
		int forcedAFC ;
		//  acquisition
		int acquireIndex ;
		float acquisitionBufferI[1024], acquisitionBufferQ[1024] ;
		int defer ;
		
		//  IMD
		IMDBuffer imdRingBuffer[256] ;		// double ring buffer
		int imdBufferIndex ;
		
		//  cr/lf check
		int crlfCheck ;
		
		PSK *modem ;
		int modemIndex ;
	}

	- (Boolean)receiverEnabled ;
	- (void)newDataBuffer:(float*)array samples:(int)inSamples ;

	- (void)setPSKModem:(PSK*)master index:(int)index ;		//  v0.78
	@end

#endif
