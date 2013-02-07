//
//  CWModulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/5/07.

#ifndef _CWMODULATOR_H_
	#define _CWMODULATOR_H_

	#import "RTTYModulator.h"
	#import "CMPCO.h"
	#import "Boxcar.h"

	typedef struct {
		int ascii ;
		int state ;
		int duration ;
	} MorseElementType ;
	
	@interface CWModulator : RTTYModulator {
		CMPCO *vco ;
		float carrierFreq ;
		float gain ;
		
		//  test tone
		CMPCO *testTone ;
		float testFreq ;
		int toneIndex ;
		
		CMFIR *waveshape ;
		float speed ;
		float weight ;
		float ratio ;
		float farnsworth ;
		
		//	morse element
		int tick ;
		int state ;
		int ringProducer ;
		int ringConsumer ;
		MorseElementType ring[4096] ;
		
		int transmitHoldoff ;
		
		int interElement ;
		int dit ;
		int dash ;
		int interCharacter ;
		int interWord ;	
		//  Morse
		char *ascii[16384] ;	
	}
	- (void)setCarrier:(float)freq ;
	- (void)setSpeed:(float)speed ;
	- (void)setRisetime:(float)t weight:(float)w ratio:(float)r farnsworth:(float)f ;
	- (void)setModulationMode:(int)index ;
	- (void)holdOff:(int)milliseconds ;
	- (Boolean)bufferEmpty ;
	
	- (void)insertEndOfTransmit ;

	- (int)needData:(float*)outbuf samples:(int)samples ;
	- (void)setGain:(float)v ;
	
	- (void)selectTestTone:(int)index ;
	- (void)setTestFrequency:(float)v ;
	
	@end

#endif
