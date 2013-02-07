//
//  MFSK16Demodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/16/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSKDemodulator.h"
#import "MFSKVaricode.h"

@interface MFSK16Demodulator : MFSKDemodulator {
}

//  Decoder
- (void)decodeBins:(float*)vector buffered:(Boolean)state ;				//  v0.73

@end
