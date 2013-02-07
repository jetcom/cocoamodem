//
//  RTTYSingleFilter.h
//  cocoaModem
//
//  Created by Kok Chen on Mon Jun 21 2004.
//

#ifndef _RTTYSINGLEFILTER_H_
	#define _RTTYSINGLEFILTER_H_

	#import <Cocoa/Cocoa.h>
	#import "RTTYMatchedFilter.h"


	@interface RTTYSingleFilter : RTTYMatchedFilter {
		int tone ;
	}
	
	- (id)initTone:(int)channel baud:(float)baud ;

	@end

#endif
