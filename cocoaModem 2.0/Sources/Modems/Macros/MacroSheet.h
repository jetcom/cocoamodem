//
//  MacroSheet.h
//  cocoaModem
//
//  Created by Kok Chen on Mon May 31 2004.
//

#ifndef _MACROSHEET_H_
	#define _MACROSHEET_H_

	#import <Cocoa/Cocoa.h>

	@class MacroInterface ;
	@class Preferences ;
	@class QSO ;
	@class UserInfo ;
	
	@interface MacroSheet : NSWindow {
		IBOutlet id view ;
		IBOutlet id name ;
		IBOutlet id titleMatrix ;
		IBOutlet id macroMatrix ;
		IBOutlet id importButton ;
		IBOutlet id exportButton ;
		
		NSWindow *controllingWindow ;
		UserInfo *userInfo ;
		QSO *qso ;
		MacroInterface *modem ;
		NSString *macroBuf ;
		int excessTransmitMacros ;
	}
	
	- (IBAction)done:(id)sender ;
	- (IBAction)import:(id)sender ;
	- (IBAction)export:(id)sender ;

	- (id)initSheet ;
	- (void)performDone ;
	- (void)setUserInfo:(UserInfo*)info qso:(QSO*)qsoObj modem:(MacroInterface*)modem canImport:(Boolean)canImport ;
	- (void)setModem:(MacroInterface*)modem ;
	
	- (void)showMacroSheet:(NSWindow*)window modem:(MacroInterface*)modem ;
		
	NSString *nextMsg( NSString **full ) ;
	
	- (NSObject*)getMessageObject ;
	- (NSObject*)getCaptionObject ;
	
	- (NSMatrix*)titles ;
	- (NSString*)title:(int)index ;
	- (NSString*)macro:(int)index ;
	- (NSString*)expandMacro:(int)index modem:(MacroInterface*)modem ;
	- (Boolean)executeButtonMacro:(char*)str modem:(MacroInterface*)macroInterface ;
	- (Boolean)executeMacroScript:(char*)str ;
	- (void)appendToMessageBuf:(NSString*)string ;

	- (void)updateFromMessageObject:(NSObject*)msgObject titleObject:(NSObject*)titleObject ;

	- (void)setupDefaultPreferences:(Preferences*)pref messageKey:(NSString*)messageKey titleKey:(NSString*)titleKey ;
	- (void)updateFromPlist:(Preferences*)pref messageKey:(NSString*)messageKey titleKey:(NSString*)titleKey ;
	- (void)retrieveForPlist:(Preferences*)pref messageKey:(NSString*)messageKey titleKey:(NSString*)titleKey ;

	@end

#endif
