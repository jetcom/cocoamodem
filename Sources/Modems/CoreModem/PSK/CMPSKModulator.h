//
//  CMPSKModulator.h
//  CoreModem 2.0
//
//  Created by Kok Chen on 11/4/05.

#ifndef _CMPSKMODULATOR_H_
	#define _CMPSKMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CMNCO.h"
	#include "CMVaricode.h"

	#define	BITPHASEMASK	0xfff
	#define RINGMASK		0xfff

	typedef struct {
		int bit ;				//  bit polarity
		int character ;			//  either 0 or an ASCII character
	} APSKStream ;

	@interface CMPSKModulator : CMNCO {
		id delegate ;
		float raisedCosine[BITPHASEMASK+16] ;
		float bitPhase, lastBitPhase, dBitPhase ;
		float thisI, lastI ;
		float thisQ, lastQ ;
		float carrier ;
		int pskMode ;
		//  bit buffer
		NSRecursiveLock *bitLock ;
		int bitProducer, bitConsumer ;
		APSKStream ring[RINGMASK+1] ;
		CMVaricode *varicode ;
		Boolean terminated ;
		//  convolution encoder's shift register
		int convolution ;
	}
	
	- (void)setFrequency:(float)freq ;
	- (float)frequency ;
	
	//  send data to Modulator
	- (void)appendASCII:(int)ascii ;
	- (void)insertShortIdle ;
	- (void)insertSquelchTail ;
	
	//  fetching sound samples from modulator
	- (void)getBufferWithIdleFill:(float*)buf length:(int)samples ;
	
	- (void)resetModulator ;
	- (void)setPSKMode:(int)mode ;
	
	//  delegate
	- (id)delegate ;
	- (void)setDelegate:(id)client ;
	- (void)transmittedCharacter:(int)character ;

	@end

#endif
