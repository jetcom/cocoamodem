//
//  SITORReceiver.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/6/06.

#ifndef _SITORRECEIVER_H_
	#define _SITORRECEIVER_H_

	#include "RTTYReceiver.h"
	
	@class SITORRxControl ;
	
	@interface SITORReceiver : RTTYReceiver {

	}

	- (void)setControl:(SITORRxControl*)control ;
	
	@end

#endif
