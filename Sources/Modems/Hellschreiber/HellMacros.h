//
//  HellMacros.h
//  cocoaModem
//
//  Created by Kok Chen on Mon Jan 30 2006.
//

#ifndef _HELLMACROS_H_
	#define _HELLMACROS_H_

	#import <Cocoa/Cocoa.h>
	#include "MacroSheet.h"

	@interface HellMacros : MacroSheet {
	}
	
	- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index ;
	- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index ;
	- (void)retrieveForPlist:(Preferences*)pref option:(int)index ;

	@end

#endif
