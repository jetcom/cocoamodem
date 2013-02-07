//
//  HellModulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/29/06.


#ifndef _HELLMODULATOR_H_
	#define _HELLMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CMNCO.h"
	#include "CMFIR.h"
	#include "HellschreiberFont.h"
	#include "MSKGenerator.h"

	#define RINGMASK		0x1fff
	
	//  output pixel stream
	typedef struct {
		int gray ;					//  gray value
		Boolean eof ;
		unsigned char *echo ;		//  full duplex echo either nil or pointer to 14 pixels
	} ToneStream ;
	
	//  ring buffer character stream
	typedef struct {
		int columns ;
		Boolean eof ;
		unsigned char *pixmap ;		//  pointer to start of bitmaps
	} CharacterStream ;

	@class Hellschreiber ;

	@interface HellModulator : MSKGenerator {
		float carrier, fmCarrier ;
		float bitValue, qBitValue ;
		int qBitPhase ;
		Boolean sidebandState ;
		//  bit buffer
		NSLock *charLock ;
		int bitIndex, bitLimit ;
		int charProducer, charConsumer ;
		CharacterStream ring[RINGMASK+1] ;
		ToneStream bitBuffer[512] ;				//  allow up to 512 pixels per character
		int toneStreamIndex ;
		Boolean terminated ;
		Boolean cw ;
		int modulationMode ;
		float deviation ;
		
		Hellschreiber *modem ;
		CMFIR *transmitBPF ;
		float *fir ;
		float bpfBuf[512] ;
		
		Boolean diddle ;
		unsigned char idleColumn[16], diddleCharacter[48] ;
		
		HellschreiberFontHeader *font ;
	}
	
	- (void)setFrequency:(float)freq ;
	- (float)frequency ;
	- (void)createTransmitBPF:(float)center ;
	- (void)setSidebandState:(Boolean)state ;
	
	- (void)setFont:(HellschreiberFontHeader*)font ;
	
	//  send data to Modulator
	- (void)appendASCII:(int)ascii ;
	- (void)insertShortIdle ;
	
	- (void)flushTransmitBuffer ;
	
	- (void)setDiddle:(Boolean)state ;
	- (void)setCW:(Boolean)state ;
	- (void)setMode:(int)mode ;
	
	//  fetching sound samples from modulator
	- (void)getBufferWithIdleFill:(float*)buf length:(int)samples ;
	
	- (void)resetModulator ;
	
	- (void)setModemClient:(Hellschreiber*)client ;
	- (void)transmittedColumn:(unsigned char*)column ;
	- (void)insertEndOfTransmit ;
	- (Boolean)terminated ;

	@end

#endif
