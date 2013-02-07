//
//  UserInfo.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 01 2004.
//

#ifndef _USERINFO_H_
	#define _USERINFO_H_

	#import <Cocoa/Cocoa.h>
	
	@class Preferences ;

	@interface UserInfo : NSWindow {
		IBOutlet id view ;

		IBOutlet id nameField ;
		IBOutlet id callField ;
		IBOutlet id stateField ;
		IBOutlet id country ;
		IBOutlet id gridSquare ;
		IBOutlet id yearLicensed ;
		IBOutlet id arrlSection ;
		IBOutlet id cqZone ;
		IBOutlet id ituZone ;
		IBOutlet id brag ;
		
		NSWindow *controllingWindow ;
	}
	
	- (IBAction)done:(id)sender ;
	
	- (void)showSheet:(NSWindow*)window ;
	
	- (NSString*)macroFor:(int)c ;
	- (NSString*)call ;
	- (NSString*)name ;
	- (NSString*)qth ;
	- (NSString*)section ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;

	@end

#endif
