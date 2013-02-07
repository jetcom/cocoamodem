//
//  ParametricEqualizer.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/21/07.

#ifndef _PARAMETRICEQUALIZER_H_
	#define _PARAMETRICEQUALIZER_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	
	typedef struct {
		float low ;
		float high ;
		float value ;
	} ParametricRange ;

	@interface ParametricEqualizer : NSObject {
		CMFIR *filter ;
		ParametricRange range[64] ;
		int ranges ;
		int taps ;
		float *window ;
	}

	- (id)init:(ParametricRange*)rangeArray ranges:(int)n order:(int)order ;
	- (CMFIR*)filter ;
	
	- (void)setRange:(int)index to:(float)value ;
	
	@end

#endif
