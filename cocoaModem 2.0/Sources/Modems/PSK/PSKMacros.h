//
//  PSKMacros.h
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
//

#ifndef _PSKMACROS_H_
	#define _PSKMACROS_H_

	#import <Cocoa/Cocoa.h>
	#import "MacroSheet.h"

	@interface PSKMacros : MacroSheet {
	}
	
	- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index ;
	- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index ;
	- (void)retrieveForPlist:(Preferences*)pref option:(int)index ;

	@end

#endif
