//
//  RTTYModulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/31/05.

#ifndef _RTTYMODULATOR_H_
	#define _RTTYMODULATOR_H_

	#import "RTTYModulatorBase.h"

	@class Modem ;

	@interface RTTYModulator : RTTYModulatorBase {
		Modem *modem ;
		//  second tone (for two tone test)
		double theta2 ;
		CMTonePair toneFrequencies ;
	}

	
	- (void)setModemClient:(Modem*)client ;
	
	- (CMTonePair*)toneFrequencies ;
	
	//  test tones
	- (void)getBufferWithRepeatFill:(float*)buf length:(int)samples ;
	- (void)getBufferOfMarkTone:(float*)buf length:(int)samples ;
	- (void)getBufferOfSpaceTone:(float*)buf length:(int)samples ;
	- (void)getBufferOfTwoTone:(float*)buf length:(int)samples ;
	
	//  second tone
	- (float)sin2:(double)delta ;
	- (float)cos2:(double)delta ;

	@end

#endif
