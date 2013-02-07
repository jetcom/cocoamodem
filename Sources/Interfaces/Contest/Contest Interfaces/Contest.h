//
//  Contest.h
//  cocoaModem
//
//  Created by Kok Chen on Mon Oct 04 2004.
//

#ifndef _CONTEST_H_
	#define _CONTEST_H_

	#import <Cocoa/Cocoa.h>
	#include <stdio.h>
	#include <time.h>
	#include "cocoaModemParams.h"
	#include "modemTypes.h"
	#include "UpperFormatter.h"
	#include "StripPhi.h"	
	
	#define MAXQ	8192
	
	typedef struct _ContestQSO ContestQSO ;
	typedef struct _Callsign Callsign ;
	
	struct _ContestQSO {
		Callsign *callsign ;
		char *exchange ;
		ContestQSO *next ;
		float frequency ;
		short rst ;
		short mode ;
		unsigned short qsoNumber ;
		DateTime time ;
	} ;

	struct _Callsign {
		char callsign[64] ;
		ContestQSO *link ;
		Callsign *next ;
	} ;
	
	@class Cabrillo ;
	@class ContestInterface ;
	@class ContestManager ;
	@class TransparentTextField ;
	@class UserInfo ;
	
	
	@interface Contest : StripPhi {
		
		IBOutlet id qsoNumberField ;
		IBOutlet id contestView ;
		IBOutlet id bandMenu ;
		IBOutlet id logButton ;
		IBOutlet id clearButton ;

		IBOutlet id watermark ;
		
		FILE *backup ;
		TransparentTextField *previousField ;

		ContestInterface /*Modem*/ *client ;
		
		Callsign *activeCall ;
		Callsign qso[MAXQ] ;
		ContestQSO *qsoList[MAXQ], *sortedQSOList[MAXQ] ;
		int numberOfQSO ;
		
		int activeBand ;
		int activeMode ;
		int activeTime ;
		int activeQSONumber ;
		Boolean oncePerMode ;			// one QSO per mode  (false = allow FSK and PSK in the same band)
		Boolean oncePerBand ;			// false = only once
		Boolean manyPerBand ;			// true = keep working the same station
		Boolean dupeState ;
		//  xml
		NSXMLParser *parser ;			//  Panther
		CFXMLTreeRef xmlRoot ;			//  Jaguar
		Boolean parseContestName ;
		Boolean parseContestLog ;
		Boolean parseQSO ;
		Boolean parseContest ;
		
		NSString *contestName ;
		NSString *prototypeName ;
		NSString *savedCallsign ;
		NSString *savedExchange ;

		ContestManager *manager ;
		Contest *master, *activeSubordinate ;
		
		Contest *subordinate[16] ;
		int subordinates ;
		Boolean bandMenuBypass ;
		
		//  Cabrillo
		FILE *cabrilloFile ;
		const char *cabrilloContest ;
		const char *cabrilloCategorySuffix ;
		UserInfo *userInfo ;
		Cabrillo *cabrillo ;
		NSString *usedCallString ;
		float importedFrequency ;
		//  field activity				
		Boolean busy ;
		NSMutableString *previousCall ;
		
		//  alphabet/numeric check
		Boolean isAlpha[256] ;
		Boolean isNumeric[256] ;
	}
	
	- (void)setInterface:(NSControl*)object to:(SEL)selector ;
	- (void)initializeActions ;
	
	//  this is for initializing the master
	- (id)initContestName:(NSString*)name prototype:(NSString*)prototype parser:(NSXMLParser*)inParser manager:(ContestManager*)mgr ;
	//  this is for initializing each instance for a modem
	- (id)initIntoBox:(NSBox*)box contestName:(NSString*)name prototype:(NSString*)prototype modem:(ContestInterface*)inClient master:(Contest*)master manager:(ContestManager*)mgr ;

	- (void)addSubordinate:(Contest*)sub ;
	- (Contest*)activeSubordinate ;
	- (ContestInterface*)modemClient ;
	- (void)selectFirstResponder ;
	- (void)selectFirstResponderInActivePanel ;
	
	- (float)defaultFrequencyForBand ;
	- (void)switchBandTo:(int)which index:(int)index ;
	- (void)bandSwitched:(int)band ;
	- (void)selectField:(NSTextField*)field ;
	- (void)updateBandMenu:(float)frequency ;
		
	//  dupe
	- (Boolean)setDupeState:(Boolean)state ;
	- (Boolean)isDuped ;
	- (void)setWatermarkState:(Boolean)state ;
	- (void)setSmallWatermarkState:(Boolean)state ;
	
	int band( float frequency ) ;
	float rttyFrequency( int band ) ;
	
	- (void)saveXML:(NSString*)path ;
	- (void)saveXMLHead:(FILE*)file isJournal:(Boolean)isJournal ;
	- (void)saveContest:(NSString*)path ;
	- (void)saveLogToXML:(FILE*)file ;
	
	- (NSString*)contestName ;
	- (NSString*)prototypeName ;
	- (NSString*)callsign ;
	- (NSString*)qsoNumber ;
	- (NSString*)dxExchange ;
	
	- (Callsign*)currentCallsign ;
	- (NSString*)fetchCallString ;
	- (NSString*)fetchSavedCallString ;
	- (NSString*)fetchExchangeNumberString ;
	- (NSString*)fetchReceivedExchange ;
	- (NSString*)fetchSavedReceivedExchange ;
	
	//  journaling
	- (void)journalQSO:(ContestQSO*)q ;
	- (void)updateQSOToJournal:(FILE*)file ;
	- (void)saveQSOToXML:(FILE*)file qso:(ContestQSO*)q ;
	- (void)createNewJournal ;
	
	//  save contest fields
	void saveCallToXML( FILE* file, ContestQSO* q ) ;
	void saveDateToXML(FILE* file, ContestQSO* q ) ;
	void saveTimeToXML( FILE* file, ContestQSO* q ) ;
	void saveModeToXML( FILE* file, ContestQSO* q ) ;
	void saveExchangeToXML( FILE* file, ContestQSO* q ) ;
	void saveFrequencyToXML( FILE* file, ContestQSO* q ) ;
	void saveQSONumberToXML( FILE* file, ContestQSO* q ) ;
	
	- (void)setupFields ;
	- (void)selectActiveField ;
	- (Boolean)isEmpty:(NSTextField*)field ;
	
	- (Callsign*)hash:(const char*)call ;
	
	- (Callsign*)receivedCallsign:(NSString*)call band:(int)band isDupe:(Boolean*)isDupe ;
	- (void)createQSO:(ContestQSO*)p callsign:(Callsign*)call mode:(int)mode ;
	- (void)newQSO:(int)n ;
	- (void)clearCurrentQSO ;
	- (ContestQSO*)createQSOFromCurrentData ;
	- (Callsign*)getCallsign:(const char*)call ;
	
	//  move ContestQSO* under a different callsign
	- (void)changeQSO:(ContestQSO*)oldqso to:(char*)callsign ;
	
	//  Cabrillo
	- (void)writeCabrilloToPath:(NSString*)path callsign:(NSString*)callsign ;
	- (void)writeCabrilloFields ;
	- (void)writeCabrilloCategory ;
	- (void)setCabrillo:(Cabrillo*)obj ;
	- (void)setCabrilloContestName:(const char*)str ;
	- (void)setCabrilloCategorySuffix:(const char*)str ;
	- (void)writeCabrilloQSOs ;
	
	- (void)logMacro ;
	
	// Mults
	- (void)createMult:(ContestQSO*)p ;
	- (void)showMultsWindow ;

	//  AppleScript support
	- (void)selectBand:(int)which ;
	- (int)selectedBand ;

	
	int modeForString(NSString* str ) ;
	char* stringForMode(int mode) ;
	
	void makeDateTime( DateTime* dt, time_t t ) ;
	
	@end
	

#endif
