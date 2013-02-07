//
//  MFSKMacros.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/16/06.

#ifndef _MFSKMACROS_H_
	#define _MFSKMACROS_H_

	#import <Cocoa/Cocoa.h>
	#include "MacroSheet.h"

	@interface MFSKMacros : MacroSheet {
	}
	
	- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index ;
	- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index ;
	- (void)retrieveForPlist:(Preferences*)pref option:(int)index ;

	@end

#endif
