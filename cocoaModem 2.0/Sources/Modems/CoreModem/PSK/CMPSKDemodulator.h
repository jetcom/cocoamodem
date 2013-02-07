//
//  CMPSKDemodulator.h
//  CoreModem
//
//  Created by Kok Chen on 11/3/05.

#ifndef _CMPSKDEMODULATOR_H_
	#define _CMPSKDEMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#import "CMPSKmatchedFilter.h"
	#import "CMToneReceiver.h"
	#import "CMVaricode.h"
	#import "CMPSKModes.h"
	#import "CMComplexFIR.h"
	#import "CMFFT.h"


	@interface CMPSKDemodulator : CMToneReceiver {
		id delegate ;
		
		//  decimation filters
		int decimatedLength, decimatedOffset ;
		CMAnalyticBuffer *decimatedBuffer ;
		CMComplexFIR *decimate ;
		CMComplexFIR *decimate31 ;
		CMComplexFIR *decimate63 ;
		//  psk31 filters
		CMFIR *comb ;
		CMFIR *dataFilterI, *dataFilterQ ;
		CMFIR *imdFilterI, *imdFilterQ ;
		//  data matched filter
		CMPSKMatchedFilter *pskMatchedFilter ;
		//  varicode decoder
		CMVaricode *varicode ;

		float baseI[65], baseQ[65], bitClock[65] ;
		CMAnalyticBuffer *input ; 
		CMAnalyticBuffer *spec ;
		
		CMFFT *fft, *imdFFT ;
		float acquisitionFilter ;
		Boolean printEnabled ;
		
		float clickBuffer[ 0x20000 ] ;
		int clickBufferProducer, clickBufferConsumer ;
		
		float lastAng ;
		float phaseLoop ;
		int cycle ;
		int pskMode ;
		int mux ;
		int varicodeCharacter ;

		//  IMD
		int imdBufferPointer ;
		float lastIMD, imdBufferI[288], imdBufferQ[288] ;
		float imdSpectrum[256] ;
		Boolean hasIMD, lastBit ;
	}
	
	- (void)setPSKMode:(int)mode ;
	
	//  delegates
	- (void)setDelegate:(id)inDelegate ;
	- (id)delegate ;
	- (void)receivedCharacter:(int)c spectrum:(float*)spectrum ;
	- (void)newSpectrum:(DSPSplitComplex*)buf size:(int)length ;
	- (Boolean)afcEnabled ;
	- (float)squelchValue ;
	- (void)updateIMD:(float)imd snr:(float)snr ;
	- (void)updatePhase:(float)ang ;
	- (void)updateDisplayFrequency:(float)tone ;
	- (void)setTransmitFrequency:(float)tone ;
	

	@end

#endif
