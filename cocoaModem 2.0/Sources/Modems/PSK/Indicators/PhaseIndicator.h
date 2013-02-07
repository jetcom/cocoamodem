//
//  PhaseIndicator.h
//  cocoaModem
//
//  Created by Kok Chen on Tue Sep 07 2004.
//
#ifndef _PHASEINDICATOR_H_
	#define _PHASEINDICATOR_H_

	#import <Cocoa/Cocoa.h>

	@interface PhaseIndicator : NSView {
		NSRect bounds ;
		float width, height ;
		int xpos ;
		NSColor *yellow, *black ;
	}
	- (void)newPhase:(float)radian ;
	- (void)clear ;

	@end

#endif
