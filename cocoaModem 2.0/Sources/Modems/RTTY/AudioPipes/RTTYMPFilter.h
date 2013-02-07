//
//  RTTYMPFilter.h
//  cocoaModem
//
//  Created by Kok Chen on Mon Jun 21 2004.
//

#ifndef _RTTYMPFILTER_H_
	#define _RTTYMPFILTER_H_

	#import <Cocoa/Cocoa.h>
	#include "RTTYMatchedFilter.h"


	@interface RTTYMPFilter : RTTYMatchedFilter {
	}
	
	- (id)initBitWidth:(float)w baud:(float)baudrate ;

	@end

#endif
