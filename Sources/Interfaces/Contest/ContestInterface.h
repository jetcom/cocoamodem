//
//  ContestInterface.h
//  cocoaModem
//
//  Created by Kok Chen on 10/15/04.
//

#ifndef _CONTESTINTERFACE_H_
	#define _CONTESTINTERFACE_H_

	#import <Cocoa/Cocoa.h>
	#include "Modem.h"
	#include "MacroInterface.h"

	@class Contest ;
	@class ContestBar ;
	@class ContestManager ;
	@class Modem ;

	@interface ContestInterface : MacroInterface {
	
		IBOutlet id contestTab ;
		IBOutlet id contestMode ;		// (CQ, S&P)
		IBOutlet id contestView ;
		IBOutlet id contestMessageMatrix ;
		IBOutlet id contestDate ;
		IBOutlet id contestTime ;
		
		NSRunLoop *mainRunLoop ;
		
		Modem *modemClient ;
		Contest *contest ;
		Contest *master ;
		ContestManager *contestManager ;
		ContestBar *contestBar ;
		int contestModeIndex ;
		Boolean inContestMode ;
		
		NSString *savedString ;
		
		int selectedField ;
		NSTextField *currentField ;  // the most recent field set from contest panel
	}
	
	- (IBAction)showContestMacroSheet:(id)sender ;
	- (IBAction)transmitContestMessage:(id)sender ;
	- (IBAction)contestModeChanged:(id)sender ;
	
	- (void)awakeFromContest ;
	- (void)initContest:(Contest*)newContest master:(Contest*)master manager:(ContestManager*)manager ;
	- (void)selectContestMode:(Boolean)state ;
	- (int)contestModeIndex ;
	- (void)newMacroForContestBar:(int)index sheet:(int)sheet ;
	
	- (void)updateContestMacroButtons ;
	
	- (void)callsignClickSuccessful:(Boolean)state ;
	
		
	- (void)setContestBar:(ContestBar*)bar ;

	
	@end

#endif
