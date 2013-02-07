//
//  StdManager.h
//  cocoaModem
//
//  Created by Kok Chen on 8/7/05.
//

#ifndef _STDMANAGER_H_
	#define _STDMANAGER_H_

	#include "ModemManager.h"
	
	@class Analyze ;
	@class Config ;
	@class Contest ;
	@class ContestBar ;
	@class ContestInterface ;
	@class DualRTTY ;
	@class Hellschreiber ;
	@class PSK ;
	@class QSO ;
	@class RTTYMacros ;
	@class SITOR ;

	@interface StdManager : ModemManager {

		IBOutlet id qsoTabviewTextured ;
		IBOutlet id qsoTabviewUntextured ;
		IBOutlet id contestManager ;

		NSTabView *qsoTabview ;
		QSO *qso ;
		ContestBar *contestBar ;

		NSToolTipTag tooltip ;
		Boolean enableCloseButton ;
		Boolean isTextured ;
		
		Contest *contest ;
		Boolean qsoShowing ;
		Boolean contestInCQ ;
		
		//  common macro sheet for all RTTY macros
		RTTYMacros *rttyMacroSheet[3] ;
	}
	
	//	v0.97	open/close PSK31 TableView
	- (IBAction)openTableView:(id)sender ;
	- (IBAction)closeTableView:(id)sender ;
	- (IBAction)nextStationInTableView:(id)sender ;
	- (IBAction)previousStationInTableView:(id)sender ;		//  v1.01c
	
	- (Boolean)executeContestMacroFromShortcut:(int)n sheet:(int)sheet modem:(ContestInterface*)modem ;
	- (void)useContestMode:(Boolean)state ;
	
	- (void)switchCurrentModemToTransmit:(Boolean)state ;
	- (void)flushCurrentModem ;
	
	- (NSString*)selectedModemName ;
	- (void)selectDefaultModem ;					//  v0.53b
	
	- (void)selectView:(int)index ;					//  v0.96c
	
	//  RTTY mode
	- (void)updateRTTYMacroButtons ;
	- (void)displayRTTYScope ;
	
	- (NSTabView*)qsoTabviewObject ;
	- (void)updateQSOWindow ;
	- (Boolean)qsoInterfaceShowing ;
	- (void)toggleQSOShowing ;
	- (void)setEnableQSOInterface:(Boolean)state ;
	
	//  v1.01a
	- (void)selectQSOCall ;
	- (void)selectQSOName ;	

	- (Contest*)currentContest ;
	- (Contest*)selectContest:(NSString*)contestName parser:(NSXMLParser*)parser ;
	- (Boolean)executeContestMacroFromShortcut:(int)n sheet:(int)sheet modem:(ContestInterface*)modem ;

	- (void)showCabrilloInfo ;
	
	//  class references for AppleScript
	- (Modem*)rttyModem ;
	- (Modem*)dualRTTYModem ;
	- (Modem*)wfRTTYModem ;
	- (Modem*)cwModem ;
	- (Modem*)mfskModem ;
	- (Modem*)pskModem ;
	- (Modem*)hellschreiberModem ;
	- (Modem*)sitorModem ;
	- (QSO*)qsoObject ;

	@end

#endif
