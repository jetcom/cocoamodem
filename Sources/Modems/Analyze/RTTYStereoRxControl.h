//
//  RTTYStereoRxControl.h
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
//

#ifndef _RTTYSTEREORXCONTROL_H_
	#define _RTTYSTEREORXCONTROL_H_

	#import <Cocoa/Cocoa.h>
	#include "RTTYRxControl.h"


	@interface RTTYStereoRxControl : RTTYRxControl {
		IBOutlet id refChannelMenu ;
		IBOutlet id dutChannelMenu ;
	}
	
	- (IBAction)channelMenuChanged:(id)sender ;

	@end

#endif
