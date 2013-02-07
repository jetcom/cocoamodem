//
//  MFSKModulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/17/07.

#import <Cocoa/Cocoa.h>
#import "CMFIR.h"
#import "MFSK.h"
#import "MFSKFEC.h"
#import "NewNCO.h"

@class MFSKVaricode ;
@class ConvolutionCode ;

#define RINGMASK		0xfff

typedef struct {
	int value ;				//  bit polarity for MFSK16 and nibble for DominoEX
	int character ;			//  either 0 or an ASCII character
	int secondaryCharacter ;
} MFSKStream ;

@interface MFSKModulator : NewNCO {
	MFSK *modem ;
	MFSKVaricode *varicode ;
	ConvolutionCode *fec ;
	
	float carrier ;
	//  data ring
	NSLock *bitLock ;
	MFSKStream ring[RINGMASK+1] ;
	int bitProducer, bitConsumer ;
	int idleSequenceState ;
	int terminateCount ;
	int terminateState ;
	int characterRing[64] ;
	int characterRingIndex ;
	//  interleaver
	int interleaverStages ;
	int interleaverIndex ;
	float interleaverRegister[160] ;
	Boolean useFEC ;
	//  modulation
	double baudDDA ;
	int currentFFTBin ;
	float idleFrequency ;
	float sideband ;
	CMFIR *transmitBPF ;
	//  test tone
	Boolean cw ;
}

- (void)setFrequency:(float)freq ;
- (void)setCW:(Boolean)state ;
- (void)setSidebandState:(Boolean)state ;							// LSB = NO 
- (void)setModemClient:(MFSK*)client ;
- (void)setInterleaverStages:(int)stages ;
- (void)resetModulator ;

- (void)appendASCII:(int)ascii ;
- (void)appendEOM ;
- (void)insertValue:(int)value withCharacter:(int)ch secondary:(int)secondaryCh ;
- (void)lockAndInsertValue:(int)value withCharacter:(int)ch secondary:(int)secondaryCh ;

- (void)insertPrimaryASCIIIntoFECBuffer:(int)ascii fromCharacter:(int)ch ;

- (void)insertPrimaryFECVaricodeFor:(int)ascii fromCharacter:(int)echo ;
- (void)insertSecondaryFECVaricodeFor:(int)ascii fromCharacter:(int)echo ;	//  for MFSK16, this is the same as insertPrimaryFECVaricodeFor:

- (int)getNextFECIndex ;
- (int)getNextFECBit ;

- (void)setUseFEC:(Boolean)state ;
- (QuadBits)interleave:(QuadBits)p ;

- (void)getBufferWithIdleFill:(float*)buf length:(int)samples ;
- (void)setScale:(float)value ;
- (void)flushOutput ;
- (Boolean)terminated ;
	
@end

#define NOTTERMINATING		0
#define	TERMINATESTARTED	1
#define	TERMINATETAIL		2
#define	TERMINATED			5

