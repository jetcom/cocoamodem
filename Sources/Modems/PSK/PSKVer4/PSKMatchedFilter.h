//
//  PSKMatchedFilter.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 9/25/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "CMPSKmatchedFilter.h"
#import "ConvolutionCode.h"


typedef struct {
	float i ;
	float q ;
} MatchedPair ;

@interface PSKMatchedFilter : CMPSKMatchedFilter {
	ConvolutionCode *fec ;
	float quality, cosTheta ;
	float prevPhase, phaseError, averagePhaseError ;
	int phaseReportCycle ;
}

- (int)bpsk:(float)real imag:(float)imag bitSync:(Boolean)bitSync ;
- (int)qpsk:(float)real imag:(float)imag bitSync:(Boolean)bitSync ;

- (float)phaseError ;

@end
