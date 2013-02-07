//
//  CWMacros.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/10/07.


#ifndef _CWMACROS_H_
	#define _CWMACROS_H_

	#import <Cocoa/Cocoa.h>
	#import "MacroSheet.h"

	@interface CWMacros : MacroSheet {
	}
	
	- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index ;
	- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index ;
	- (void)retrieveForPlist:(Preferences*)pref option:(int)index ;

	@end

#endif
