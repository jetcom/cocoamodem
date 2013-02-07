//
//  DominoModulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/16/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSKModulator.h"

typedef unsigned char CodeString[4] ;

@interface DominoModulator : MFSKModulator {
	CodeString primaryVaricode[256], secondaryVaricode[256] ;
	char beaconString[2048] ;
	char defaultBeaconString[64] ;
	NSString *defaultString ;
	char *beaconPtr ;
	int deltaTone ;
	int lastTone ;
	float binWidth ;			//  15.625 for DominoEX 16 and DominoEX 8
	int baudRatio ;				//  2 for DominoEX 4, DominoEX 5 and DominoEX 8, 1 for full rate modes
}

- (void)setBinWidth:(float)hz baudRatio:(int)inBaudRatio ;
- (void)setBeacon:(char*)msg ;

- (void)insertSecondaryASCIIIntoFECBuffer:(int)ascii fromCharacter:(int)ch ;
 
@end
