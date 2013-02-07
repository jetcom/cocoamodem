//
//  XE RTTY.h
//  cocoaModem
//
//  Created by Kok Chen on 1/16/05.
//

#ifndef _XE_RTTY_H_
	#define _XE_RTTY_H_

	#import <Cocoa/Cocoa.h>
	#include "RSTExchange.h"


	@interface XERTTY : RSTExchange {
		char exchSent[12] ;
	}

	@end

#endif
