//
//  BARTG.h
//  cocoaModem
//
//  Created by Kok Chen on 2/12/06.
//

#ifndef _BARTG_H_
	#define _BARTG_H_

	#import <Cocoa/Cocoa.h>
	#include "RSTExchange.h"


	@interface BARTG : RSTExchange {
		char exchSent[12] ;
		Boolean isDX ;
	}

	@end

#endif
