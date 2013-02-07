//
//  ContestManager.h
//  cocoaModem
//
//  Created by Kok Chen on 10/17/04.
//

#ifndef _CONTESTMANAGER_H_
	#define _CONTESTMANAGER_H_

	#import <Cocoa/Cocoa.h>
	#include "modemTypes.h"
	
	@class Cabrillo ;
	@class Contest ;
	@class ContestInterface ;
	@class ContestLog ;
	@class ContestMacroSheet ;
	@class Preferences ;
	@class QSO ;
	@class UserInfo ;

	@interface ContestManager : NSObject {
		IBOutlet id application ;
		IBOutlet id stdManager ;
		IBOutlet id contestMenu ;
		IBOutlet id cabrilloMenuItem ;
		IBOutlet id saveMenuItem ;
		IBOutlet id saveAsMenuItem ;
		IBOutlet id showLogMenuItem ;
		IBOutlet id showMultMenuItem ;
		IBOutlet id recentContestMenuItem ;
		IBOutlet id clearQSOMenuItem ;
		IBOutlet id ignoreNewlineMenuItem ;
		
		NSMenuItem *selectedMenuItem ;
		Boolean isContestName ;
		Boolean isMacros ;
		Boolean isCabrillo ;
		Boolean ignoreNewline ;
		Boolean isCaption, isMessage, isExchange ;
		Boolean isCName, isAddr1, isAddr2, isAddr3, isEmail, isCategory, isBand, isCallUsed, isNameUsed, isClub, isOperator, isSoapbox ;
		int messageSheet ;
		int captionSheet ;
		Boolean xmlError ;
		Boolean allowDupe ;
		
		//  log
		ContestLog *contestLog ;
		
		//  save file
		Boolean dirty ;
		Boolean sessionStarted ;
		NSString *saveFileName ;
		
		//  contest strings
		NSString *contestName ;
		NSString *prototypeName ;
		NSString *contestCallsign ;
		NSString *myName ;
		
		UserInfo *userInfo ;
		Cabrillo *cabrilloInfo ;
		QSO *qsoInfo ;
		//  macros
		ContestMacroSheet *contestMacroSheet[6] ;
		//  master contest instance
		Contest *master ;
		//  clients
		ContestInterface *currentModem ;
		ContestInterface *client[64] ;
		int clients ;
		//  preferences
		Preferences *preference ;
	}
	
	- (IBAction)newContest:(id)sender ;
	- (IBAction)continueContest:(id)sender ;
	- (IBAction)recentContest:(id)sender ;

	- (IBAction)createCabrillo:(id)sender ;	
	- (IBAction)saveContest:(id)sender ;
	- (IBAction)saveContestAs:(id)sender ;
	
	- (IBAction)showLog:(id)sender ;
	- (IBAction)showMults:(id)sender ;
	- (IBAction)clearQSO:(id)sender ;
	
	- (void)awakeFromApplication ;
	- (void)initContestMacros ;
	- (void)saveMacrosToXML:(FILE*)file ;
	- (void)saveCabrilloToXML:(FILE*)file ;
	- (void)contestSwitchedToCQ:(Boolean)cqmode ;
	- (void)actualSaveContest ;
	
	- (void)setAllowDupe:(Boolean)state ;
	- (Boolean)allowDupe ;
	- (void)setDirty:(Boolean)state ;
	- (void)journalChanged ;
	- (Boolean)okToQuit ;
	- (void)displayInfo:(char*)info ;
	
	- (Contest*)selectContest:(NSString*)newContest parser:(NSXMLParser*)parser ;
	
	- (Contest*)contestObject ;
	- (void)addContestClient:(ContestInterface*)modem ;
	- (void)startUp ;
	
	- (void)newQSOCreated:(struct _ContestQSO*)q ;
	- (void)changeQSO:(struct _ContestQSO*)oldqso to:(char*)callsign ;
	
	- (void)setActiveContestInterface:(ContestInterface*)interface ;
	- (ContestInterface*)selectedContestInterface ;
	
	- (Cabrillo*)cabrilloObject ;
	- (UserInfo*)userInfoObject ;
	- (void)showCabrilloInfoSheet:(NSWindow*)window ;
	
	- (void)showContestMacroSheet:(int)n ;
	- (NSMatrix*)macroTitles:(int)sheet ;
	- (Boolean)executeContestMacro:(int)n sheet:(int)sheet modem:(ContestInterface*)modem ;
	- (Boolean)executeContestMacroFromShortcut:(int)n sheet:(int)sheet modem:(ContestInterface*)modem ;
	- (NSString*)expandMacroInUserAndQSOInfo:(const char*)macro ;

	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;

	#define kTempFile "/tmp/cocoaModemTempFile"
	
	@end

#endif
