//
//  Cabrillo.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 01 2004.
//

#ifndef _CABRILLO_H_
	#define _CABRILLO_H_

	#import <Cocoa/Cocoa.h>
	
	@class Contest ;
	@class ContestManager ;
	@class Preferences ;

	@interface Cabrillo : NSWindow {
		IBOutlet id view ;

		IBOutlet id categoryMenu ;
		IBOutlet id bandMenu ;
		IBOutlet id exchangeSent ;
		IBOutlet id allowDupe ;

		IBOutlet id callUsedField ;
		IBOutlet id nameUsedField ;
		IBOutlet id operatorsField ;
		IBOutlet id clubField ;

		IBOutlet id nameField ;
		IBOutlet id addr1Field ;
		IBOutlet id addr2Field ; 
		IBOutlet id addr3Field ;
		IBOutlet id emailField ;
		
		IBOutlet id soapboxView ;
		
		IBOutlet id fontField ;
		IBOutlet id tempFolder ;

		IBOutlet id logExtension ;
		
		NSWindow *controllingWindow ;
		ContestManager *manager ;
		FILE *journalFile ;
		NSString *name ;
	}
	
	- (IBAction)done:(id)sender ;
	- (IBAction)import:(id)sender ;
	- (IBAction)export:(id)sender ;
	- (IBAction)selectTempFolder:(id)sender ;
	- (IBAction)clearTempFolder:(id)sender ;
	
	- (id)initWithManager:(ContestManager*)manager ;
	- (FILE*)openJournalFile:(Contest*)contest ;
	- (FILE*)reOpenJournalFile:(Contest*)contest ;
	- (void)closeJournalFile ;
	- (FILE*)journal ;
	
	//  used by contest manager to save to XML
	- (void)saveFieldsToFile:(FILE*)file ;
	
	- (void)setExchange:(NSString*)string ;
	- (NSString*)exchangeString ;
	- (NSString*)logExtensionString ;
	
	- (void)setCName:(NSString*)string ;
	- (void)setCAddr1:(NSString*)string ;
	- (void)setCAddr2:(NSString*)string ;
	- (void)setCAddr3:(NSString*)string ;
	- (void)setEmail:(NSString*)string ;
	- (void)setCategory:(NSString*)string ;
	- (void)setBand:(NSString*)string ;
	- (void)setCallUsed:(NSString*)string ;
	- (void)setNameUsed:(NSString*)string ;
	- (void)setClub:(NSString*)string ;
	- (void)setOperators:(NSString*)string ;
	- (void)setSoapbox:(NSString*)string ;

	//  contest fonts
	- (void)setFonts ;
	
	- (NSString*)category ;
	- (NSString*)band ;
	
	- (NSString*)name ;
	- (NSString*)addr1 ;
	- (NSString*)addr2 ;
	- (NSString*)addr3 ;
	- (NSString*)email ;

	- (NSString*)callUsed ;
	- (NSString*)nameUsed ;
	- (NSString*)club ;
	- (NSString*)operators ;
	- (NSString*)soapbox ;
	
	- (void)showSheet:(NSWindow*)window ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;

	@end

#endif
