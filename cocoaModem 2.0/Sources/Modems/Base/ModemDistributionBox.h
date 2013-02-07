//
//  ModemDistributionBox.h
//  cocoaModem
//
//  Created by Kok Chen on Wed Jun 09 2004.
//

#ifndef _MODEMDISTRIBUTIONBOX_H_
	#define _MODEMDISTRIBUTIONBOX_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"

	@interface ModemDistributionBox : CMTappedPipe {
		CMPipe *first ;
		CMPipe *second ;
	}

	- (void)setFirst:(CMPipe*)p1 second:(CMPipe*)p2 ;
	- (void)setFirst:(CMPipe*)p1 ;
	- (void)setSecond:(CMPipe*)p2 ;

	@end
#endif
