//
//  ChannelSelector.h
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
//

#ifndef _CHANNELSELECTOR_H_
	#define _CHANNELSELECTOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"

	@interface ChannelSelector : CMTappedPipe {
		int selected ;
	}

	- (void)selectChannel:(int)channel ;
	
	@end

#endif
