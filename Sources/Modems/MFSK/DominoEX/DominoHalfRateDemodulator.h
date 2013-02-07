//
//  DominoHalfRateDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/4/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DominoDemodulator.h"


@interface DominoHalfRateDemodulator : DominoDemodulator {
	int inputMux ;
	int codes[16] ;
	int previousCode ;
	int nibbles ;
}

@end
