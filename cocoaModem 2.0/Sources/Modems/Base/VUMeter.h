//
//  VUMeter.h
//  cocoaModem
//
//  Created by Kok Chen on 1/31/05.
//

#ifndef _VUMETER_H_
	#define _VUMETER_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "VUSegment.h"

	typedef struct {
		VUSegment *segment ;
		Boolean state ;
		NSColor *onColor ;
	} VUElement ;

	@interface VUMeter : CMPipe {
		IBOutlet id matrix ;
		IBOutlet id background ;
		
		//  vu meter
		VUElement vu[9] ;
		NSColor *vuOffColor ;
		float vuLevel ;
		
		NSLock *overrunLock ;
	}

	- (void)setup ;

	@end

#endif
