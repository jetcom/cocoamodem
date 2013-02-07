//
//  WFRTTYConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Jan 11 06.
//

#ifndef _WFRTTYCONFIG_H_
	#define _WFRTTYCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "RTTYConfig.h"

	@interface WFRTTYConfig : RTTYConfig {	
		IBOutlet id vfoOffsetField ;
		int channel ;
	}

	- (void)setChannel:(int)n ;
	- (void)vfoOffsetChanged ;

	@end

#endif
