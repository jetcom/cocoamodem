//
//  CMFSKModulator.h
//  CoreModem
//
//  Created by Kok Chen on 10/31/05.

#ifndef _CMFSKMODULATOR_H_
	#define _CMFSKMODULATOR_H_

	#import "CMNCO.h"
	#import "CoreModemTypes.h"


	typedef struct {
		int polarity ;			//  0 == mark, 1 == space
		double dda ;
		int character ;			//  either 0 or an ASCII character
		int code ;				//  v0.88  0 or the orriginal code (e.g. Baudot)
	} CMBinaryStream ;
	
	#define CMLTRSHIFT		0x20
	#define CMFIGSHIFT		0x40
	#define CMSTREAMMASK	0xffff
	
	#define	FIGSTATE		YES
	#define	LTRSTATE		NO


	@interface CMFSKModulator : CMNCO {
		id delegate ;
		CMTonePair tonePair ;
		double bitDDA ;
		double currentBitDDA ;
		double stopDDA ;
		float stopDuration ;				// stop bit duration
		
		CMBinaryStream stopBit ;
		CMBinaryStream startBit ;
		CMBinaryStream dataBit[2] ;
		CMBinaryStream stream[CMSTREAMMASK+1] ;

		int mapping[256] ;					// ascii to baudot mapping (v0.83 includes ASCII-to-ASCII mapping)
		int sideband ;						// 0 = LSB, 1 = USB
		Boolean usos ;
		Boolean shifted ;
		Boolean robust ;
		int robustCount ;
		
		int bitsPerCharacter ;				//  v0.83
		
		Boolean spaceFollowedFIGS ;			//  v0.88  USOS "compatibility mode"
	}
	
	- (void)shiftToState:(Boolean)state ;	//  v0.88
			
	- (void)setTonePair:(const CMTonePair*)tonepair ;
	- (void)setStopBits:(float)stopBits ;
	- (void)setSideband:(int)usb ;
	- (void)setUSOS:(Boolean)state ;
	- (void)setRobustMode:(Boolean)state ;

	- (void)appendASCII:(int)ascii ;
	- (void)appendString:(char*)s clearExistingCharacters:(Boolean)reset ;
	- (void)clearOutput ;
	
	- (void)getBufferWithDiddleFill:(float*)buf length:(int)samples ;
	- (int)lengthOfActiveStream ;
	
	- (id)delegate ;
	- (void)setDelegate:(id)client ;
	- (void)transmittedCharacter:(int)ch ;
	
	//  v0.83
	- (void)setBitsPerCharacter:(int)bits ;
	
	//  private API
	- (void)appendLongMark ;
	
	@end

#endif
