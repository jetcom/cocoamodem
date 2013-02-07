//
//  CMFilter.h
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/28/05.
//

#ifndef _CMFILTER_H_
	#define _CMFILTER_H_

	#import <Cocoa/Cocoa.h>
	#include "CMTappedPipe.h"
	#include "CMFIR.h"

	@interface CMFilter : CMTappedPipe {
		int n ;
		float *fir ;
		CMFIR *filter ;
		float userParam ;
		float outbuf[512] ;
		CMDataStream stream ;
	}
	
	- (float)userParam ;
	- (void)setUserParam:(float)param ;


	@end

#endif
