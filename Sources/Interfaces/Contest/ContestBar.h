//
//  ContestBar.h
//  cocoaModem
//
//  Created by Kok Chen on 12/4/04.
//

#ifndef _CONTESTBAR_H_
	#define _CONTESTBAR_H_

	#import <Cocoa/Cocoa.h>
	#include "cocoaModemParams.h"
	#include "StripPhi.h"
	
	@class Application ;
	@class ContestInterface ;
	@class ContestManager ;
	@class Preferences ;

	@interface ContestBar : StripPhi {
		IBOutlet id view ;
		IBOutlet id pauseTime ;
		IBOutlet id repeatingIndicator ;
		IBOutlet id macroMenu ;

		NSTabView *controllingTabView ;
		Application *application ;
		
		//  repeating macros
		ContestManager *manager ;
		ContestInterface *modem ;
		int index ;
		int sheet ;
		NSTimer *delayTimer ;
		NSColor *offColor, *onColor, *waitColor ;
		Boolean repeatActive ;
	}

	- (IBAction)repeatMacro:(id)sender ;
	- (IBAction)stopRepeat:(id)sender ;

	- (id)initIntoTabView:(NSTabView*)tabview app:(Application*)app ;
	- (void)newMacroCalled:(int)index sheet:(int)sheet manager:(ContestManager*)manager modem:(ContestInterface*)inModem ;
	- (void)cancel ;
	- (void)cancelIfRepeatingIsActive ;
	
	- (Boolean)textInsertedFromRepeat ;
	
	//  callback to start the next repeating macro
	- (void)nextMacro:(id)arg ;
	
	- (void)setManager:(ContestManager*)inManager ;
	- (void)setModem:(ContestInterface*)inModem ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;

	@end

#endif
