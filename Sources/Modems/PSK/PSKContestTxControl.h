//
//  PSKContestTxControl.h
//  cocoaModem
//
//  Created by Kok Chen on 11/12/04.
//

#ifndef _PSKCONTESTTXCONTROL_H_
	#define _PSKCONTESTTXCONTROL_H_

	#import <Cocoa/Cocoa.h>
	#include "PSKTransmitControl.h"


	@interface PSKContestTxControl : PSKTransmitControl {
	}

	- (IBAction)flushBuffer:(id)sender ;
	
	@end

#endif
