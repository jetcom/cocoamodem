//
//  CMPSKMatchedFilter.h
//  CoreModem
//
//  Created by Kok Chen on 11/02/05

#ifndef _CMPSKMATCHEDFILTER_H_
	#define _CMPSKMATCHEDFILTER_H_
	
	#import <Foundation/Foundation.h>
	#include "CoreModemTypes.h"
	#include "CMTappedPipe.h"
	#include "CMFIR.h"

	#define RING	0x1f
	
	@interface CMPSKMatchedFilter : CMTappedPipe {
		float demodulated[512] ;
		CMDataStream mfStream ;
		
		float iMatched, qMatched ;
		float iPulse, qPulse ;
		float iMid, qMid ;
		int bitPhase, midBit ;
		float delta ;			// most recent phase deviation
		
		float matchedI[RING+1], matchedQ[RING+1] ;
		float pulseI[RING+1], pulseQ[RING+1] ;
		float midI[RING+1], midQ[RING+1] ;
		float phase[2] ;
		float kernel[64], pulse[64] ;
		int ring ;

		float iLast, qLast ;
		int convolutionRegister ;
		char qpskTable[1024] ;
		
		id delegate ;
	}
	
	- (id)delegate ;
	- (void)setDelegate:(id)inDelegate ;
	- (void)updateVCOPhase:(float)phase ;
	- (void)receivedBit:(int)bit ;
	
	- (int)bpsk:(float)real imag:(float)imag bitPhase:(Boolean)start ;
	- (int)qpsk:(float)real imag:(float)imag bitPhase:(Boolean)start ;

	- (float)phaseError ;

	@end

#endif
