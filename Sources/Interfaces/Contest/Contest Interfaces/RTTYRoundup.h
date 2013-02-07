//
//  RTTYRoundup.h
//  cocoaModem
//
//  Created by Kok Chen on 11/27/04.
//

#ifndef _RTTYROUNDUP_H_
	#define _RTTYROUNDUP_H_

	#import <Cocoa/Cocoa.h>
	#include "RoundupStatelist.h"
	#include "RSTExchange.h"


	@class RTTYRoundupMults ;
	
	@interface RTTYRoundup : RSTExchange {
		char exchSent[12] ;
		Boolean isDX ;
		RTTYRoundupMults *mult ;
	}

	@end

#endif
