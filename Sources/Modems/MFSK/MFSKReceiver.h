//
//  MFSKReceiver.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/29/06.

#ifndef _MFSKRECEIVER_H_
	#define _MFSKRECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "CMTappedPipe.h"
	#include "CMFFT.h"
	#include "CMPCO.h"

	@class MFSKDemodulator ;
	@class MFSKIndicator ;

	@interface MFSKReceiver : CMTappedPipe {
		MFSKDemodulator *demodulator ;
		
		Boolean enabled ;
		Boolean clickBuffersAllocated ;			//  v0.80l
		
		//  mixer
		CMPCO *vco ;
		float receiveFrequency ;		
		float iMixer[512], qMixer[512] ;		//  mixer output (before IF filter)
		float decimationRatio ;
		float nextSample ;
		int outputIndex ;
		CMFIR *iFilter, *qFilter ;
		//  IF filtered buffer
		float iOutput[512], qOutput[512] ;
		float iBuffer[32], qBuffer[32] ;
		// sideband
		Boolean sidebandState ;
		
		// click buffer
		NSLock *clickBufferLock ;
		float *clickBuffer[512] ;
		int clickBufferProducer, clickBufferConsumer ;
	}

	- (id)initReceiver ;
	- (void)enableReceiver:(Boolean)state ;
	- (Boolean)enabled ;
	- (void)setSidebandState:(Boolean)state ;
	
	- (MFSKDemodulator*)demodulator ;
	- (void)importArray:(float*)array ;		// direct data entry (exposed for loopback)
	
	// click buffer support
	- (void)createClickBuffer ;
	- (void)clicked:(float)history ;
	- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)clicked ;

	@end

#endif
