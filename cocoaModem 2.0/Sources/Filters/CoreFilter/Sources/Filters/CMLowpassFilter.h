//
//  CMLowpassFilter.h
//  Filter (CoreModem)
//
//  Created by Kok Chen on Sun Aug 15 2004.
//

#ifndef _CMLOWPASSFILTER_H_
	#define _CMLOWPASSFILTER_H_

	#import <Foundation/Foundation.h>
	#include "CMFilter.h"


	@interface CMLowpassFilter : CMFilter {
		float cutoff ;
	}

	- (id)initCutoff:(float)low length:(int)len ;
	- (void)setCutoff:(float)low length:(int)n ;
	- (void)updateCutoff:(float)low ;
	
	@end
	
#endif
