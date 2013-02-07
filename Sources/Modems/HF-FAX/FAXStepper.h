//
//  FAXStepper.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/19/06.

#ifndef _FASSTEPPER_H_
	#define _FASSTEPPER_H_

	#import <Cocoa/Cocoa.h>


	@interface FAXStepper : NSStepper {
		int steps ;
	}
	- (int)steps ;

	@end

#endif
