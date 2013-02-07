//
//  ContestTextField.h
//  cocoaModem
//
//  Created by Kok Chen on 11/17/04.
//

#ifndef _CONTESTTEXTFIELD_H_
	#define _CONTESTTEXTFIELD_H_
	
	#import <Cocoa/Cocoa.h>
	#include "OptionTextField.h"


	@interface ContestTextField : OptionTextField {
		NSText *editor ;
	}
	
	- (void)setContestFont:(NSNotification*)notify ;
	- (Boolean)sameFont:(NSString*)name asBase:(NSString*)base ;
	
	@end

#endif
