//
//  DominoDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/23/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSKDemodulator.h"

typedef struct {
	short bin[8] ;							//  max bin index (0-31) for each of the 16 sub-bins
	short code[8] ;							//  IFSK decoded (iFSKDecodeVector[current][mostRecent])
	Boolean notDecoded ;
	int mostRecentBin ;						//  most recent bin without regard to Varicode boundary
	int nextRecentBin ;						//  next most recent bin without regard to Varicode boundary
	float energy ;							//  accumulated energy
	int index ;
	int terminatingCode ;
} SubBin ;

@interface DominoDemodulator : MFSKDemodulator {
	SubBin subbin[16] ;
	int iFSKDecodeVector[32][32] ;			//  DFSK transition map
	int accumulatedCodes ;
	unsigned char privar[4096] ;			//  primary varicode
	unsigned char secvar[4096] ;			//  secondary varicode
	int holdoff ;							//  hold off after clicking
	float matchedFilter[16] ;
	float ssnr ;

	//	for indicator
	float avgSpectrum[512] ;
	// modem offset
	float previousModemOffset ;
	//	for statistics
	float baudRate ;
}

- (id)initAsMode:(int)mode ;

//	(Private API)
- (id)initAsDomino:(int)mode ;
- (void)processSubbin:(int)subbinWithLargestEnergy ;
- (void)ifskDecode:(float*)vector ;
- (void)newSubBin ;
- (void)newIFSKVaricode:(SubBin*)s length:(int)length ;
- (void)updateIndicators:(float*)powerSpectrum threshold:(float)threshold ;

@end
