//
//  SP RTTY.h
//  cocoaModem
//
//  Created by Kok Chen on 3/31/06.
//

#ifndef _SP_RTTY_H_
	#define _SP_RTTY_H_

	#import <Cocoa/Cocoa.h>
	#include "RSTExchange.h"


	@interface SPRTTY : RSTExchange {
		char exchSent[12] ;
	}

	@end

#endif
