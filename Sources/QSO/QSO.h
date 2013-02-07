//
//  QSO.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 08 2004.
//

#ifndef _QSO_H_
	#define _QSO_H_

	#import <Cocoa/Cocoa.h>
	#include "StripPhi.h"
	#include <time.h>


	@class Application ;
	@class Config ;
	
	@interface QSO : StripPhi {
	
		IBOutlet id view ;
		IBOutlet id callsignField ;
		IBOutlet id nameField ;
		IBOutlet id utcDateField ;
		IBOutlet id utcTimeField ;
		
		IBOutlet id callButton ;
		IBOutlet id nameButton ;
		IBOutlet id clearButton ;
		IBOutlet id logButton ;
				
		NSTabView *controllingTabView ;
		Application *application ;
		Config *config ;
		
		int day ;
		NSString *myExchange ;
		NSString *dxExchange ;
		NSString *qsoNumber ;
		NSString *previousNumber ;
		NSAppleScript *appleScript ;
		
		NSString *strippedCallsign ;
		NSString *strippedOp ;
		
		struct tm gmt ;
		struct tm registeredTime ;
		struct tm previousTime ;
	}

	- (id)initIntoTabView:(NSTabView*)tabview app:(Application*)app ;
	
	- (void)setNumber:(NSString*)str ;
	- (void)setExchangeString:(NSString*)str ;
	- (void)setDXExchange:(NSString*)str ;

	- (NSString*)macroFor:(int)c ;
	- (NSString*)macroFor:(int)c count:(int)n ;
	- (void)copyString:(char*)selectedChar into:(int)field ;
	
	- (void)logScriptChanged:(NSString*)fileName ;

	- (void)showOnlyDateAndTime:(Boolean)state ;
	- (void)registerTime ;
	- (NSString*)getRegisteredTime ;
	- (void)registerAndUpdateTime ;
	
	//  v1.01a
	- (void)selectCall ;
	- (void)selectName ;
	
	//  Applescripts
	- (void)setCallsign:(NSString*)str ;
	- (NSString*)callsign ;
	- (void)setOpName:(NSString*)str ;
	- (NSString*)opName ;
	
	@end

#endif
