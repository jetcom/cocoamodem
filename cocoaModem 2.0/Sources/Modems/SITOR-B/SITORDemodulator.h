//
//  SITORDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/6/06.

#ifndef _SITORDEMODULATOR_H_
	#define _SITORDEMODULATOR_H_
	
	#import "CMFSKDemodulator.h"

	@class MooreDecoder ;
	@class SITORRxControl ;
	
	@interface SITORDemodulator : CMFSKDemodulator {
		MooreDecoder *mooreDecoder ;
	}
	
	- (void)setControl:(SITORRxControl*)control ;
	- (void)setErrorPrint:(Boolean)state ;

	@end

#endif
