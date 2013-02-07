//
//  RTTYMacros.h
//  cocoaModem
//
//  Created by Kok Chen on Sat Jul 03 2004.
//

#ifndef _RTTYMACROS_H_
	#define _RTTYMACROS_H_

	#import <Cocoa/Cocoa.h>
	#include "MacroSheet.h"

	@interface RTTYMacros : MacroSheet {
	}
	
	- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index ;
	- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index ;
	- (void)retrieveForPlist:(Preferences*)pref option:(int)index ;

	@end

#endif
