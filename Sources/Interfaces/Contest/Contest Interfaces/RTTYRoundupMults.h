//
//  RTTYRoundupMults.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/26/05.

#ifndef _RTTYROUNDUPMULTS_H_
	#define _RTTYROUNDUPMULTS_H_

	#import <Cocoa/Cocoa.h>
	#include "Contest.h"
	#include "RoundupStatelist.h" 

	@interface RTTYRoundupMults : NSObject {
		IBOutlet id rrMults ;
		IBOutlet id callAreas ;
		IBOutlet id veArea ;
		
		NSColor *workedColor ;
	}
	
	- (void)updateMult:(ContestQSO*)p statelist:(StateList*)rawStateList ;
	- (void)showWindow:(StateList*)rawStateList ;

	@end

#endif
