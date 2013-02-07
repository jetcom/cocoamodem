//
//  SITORRxControl.h
//  cocoaModem
//
//  Created by Kok Chen on 2/6/06.
//

#ifndef _SITORRXCONTROL_H_
	#define _SITORRXCONTROL_H_

	#import <Cocoa/Cocoa.h>
	#import "CoreFilter.h"
	#import "CoreModemTypes.h"
	#import "RTTYRxControl.h"
	#import "AYTextView.h"
		
	@interface SITORRxControl : RTTYRxControl {
		IBOutlet id lockedIndicator ;
		
		NSColor *onColor, *waitColor, *offColor, *errorColor, *fecColor ;
	}


	- (void)setIndicator:(int)state ;
	
	#define	kSITOROff	0
	#define	kSITOROn	1
	#define	kSITORWait	2
	#define	kSITORFEC	3
	#define	kSITORError	4
	
	@end

#endif
