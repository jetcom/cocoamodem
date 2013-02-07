//
//  ContestBar.m
//  cocoaModem
//
//  Created by Kok Chen on 12/4/04.
	#include "Copyright.h"
//

#import "ContestBar.h"
#include "Messages.h"
#include "ContestInterface.h"
#include "ContestManager.h"
#include "Plist.h"
#include "Preferences.h"


@implementation ContestBar

- (id)initIntoTabView:(NSTabView*)tabview app:(Application*)app
{
	NSTabViewItem *tabItem ;
	
	self = [ super init ] ;
	if ( self ) {
		application = app ;
		manager = nil ;
		modem = nil ;
		index = sheet = -1 ;
		repeatActive = NO ;
		delayTimer = nil ;
		offColor = [ NSColor colorWithCalibratedWhite:0.5 alpha:1.0 ] ;
		waitColor = [ NSColor orangeColor ] ;
		onColor = waitColor ;

		if ( [ NSBundle loadNibNamed:@"ContestBar" owner:self ] ) {
			// loadNib should have set up view
			if ( view ) {
				//  create a new TabViewItem for QSO
				tabItem = [ [ NSTabViewItem alloc ] init ] ;
				[ tabItem setLabel:@"Contest" ] ;
				[ tabItem setView:view ] ;
				//  and insert as tabView item
				controllingTabView = tabview ;
				[ controllingTabView insertTabViewItem:tabItem atIndex:2 ] ;
				return self ;
			}
		}
	}
	[ self release ] ;
	return nil ;
}

- (void)cancel
{
	if ( repeatActive && modem && [ modem currentTransmitState ] ) {
		//  is transmitting
		[ modem flushAndLeaveTransmit ] ;
	}
	if ( delayTimer ) {
		//  cancel any pending pause
		[ delayTimer invalidate ] ;
		delayTimer = nil ;
	}
	//  cancel future requests for repeating macros from the ContestInterface (see nextMacro: below)
	[ repeatingIndicator setBackgroundColor:offColor ] ;
	repeatActive = NO ;
}

- (void)cancelIfRepeatingIsActive
{
	if ( delayTimer || repeatActive ) [ self cancel ] ;
}

//  this is where the delay timer fires (see nextMacro: below)
- (void)repeating:(NSTimer*)timer
{
	delayTimer = nil ;
	[ repeatingIndicator setBackgroundColor:onColor ] ;
	[ manager executeContestMacro:index sheet:sheet modem:modem ] ;
}

//  this is called from ContestInterface:transmissionEnded to request that we fire up the timer for to send another repeating macro
//	Repeat macros are not repeated from an NSTimer since it is the pause between macros that are significant.
//  When the ContestInterface sees that a macro is done, it calls nextMaco: here and if the repeat is active, we will fire off the delay timer
//  that launches the next macro.
- (void)nextMacro:(id)arg
{
	float pause ;
	
	if ( repeatActive && !delayTimer ) {
		pause = [ pauseTime floatValue ] ;
		//  pause limits of 0.5 min to 10 seconds max
		if ( pause < 0.5 ) pause = 0.5 ; else if ( pause > 10.0 ) pause = 10.0 ;
		[ repeatingIndicator setBackgroundColor:waitColor ] ;
		delayTimer = [ NSTimer scheduledTimerWithTimeInterval:pause target:self selector:@selector(repeating:) userInfo:nil repeats:NO ] ;
	}
	else [ delayTimer invalidate ] ;		// v0.33
}

- (void)setManager:(ContestManager*)inManager
{
	manager = inManager ;
	repeatActive = NO ;
}

- (void)setModem:(ContestInterface*)inModem
{
	modem = inModem ;
	repeatActive = NO ;
}

- (void)newMacroCalled:(int)inIndex sheet:(int)inSheet manager:(ContestManager*)inManager modem:(ContestInterface*)inModem
{
	if ( delayTimer ) [ self cancel ] ;
	
	index = inIndex ;
	sheet = inSheet ;
	manager = inManager ;
	modem = inModem ;
	repeatActive = NO ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setFloat:2.7 forKey:kContestRepeat ] ;
	[ pref setInt:0 forKey:kContestRepeatMenu ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	float pause ;
	int n ;
	
	pause = [ pref floatValueForKey:kContestRepeat ] ;
	[ pauseTime setStringValue:[ NSString stringWithFormat:@"%.1f", pause ] ] ;
	n = [ pref intValueForKey:kContestRepeatMenu ] ;
	[ macroMenu selectItemAtIndex:n ] ;
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	float pause ;
	
	pause = [ pauseTime floatValue ] ;
	[ pref setFloat:pause forKey:kContestRepeat ] ;
	[ pref setInt:[ macroMenu indexOfSelectedItem ] forKey:kContestRepeatMenu ] ;
}

- (Boolean)textInsertedFromRepeat
{
	return repeatActive ;
}

- (IBAction)repeatMacro:(id)sender 
{
	int tag, sh ;
	
	if ( repeatActive || manager == nil || modem == nil ) return ;
	
	if ( ![ modem checkIfCanTransmit ] ) return ;
	
	//  find which macro to send
	tag = [ [ macroMenu selectedItem ] tag ] ;
	if ( tag == 1111 ) {
		//  "last macro"
		if ( index < 0 || sheet < 0 ) {
			[ Messages alertWithMessageText:NSLocalizedString( @"No prior macro sent", nil ) informativeText:NSLocalizedString( @"Select a macro", nil ) ] ;
			return ;
		}
	}
	else {
		sh = tag / 100 ;
		tag = tag % 100 ;
		if ( sh < 0 || sh > 2 || tag < 0 || tag > 7 ) /* internal error */ return ;
		sheet = sh + kContestModeCQ ;
		index = tag ;
	}
	//  This switches on the macro repeats.
	//  We will call the Contestmanager to execute the macro the first time here, after which
	//  the ContestManager will call nextMacro: here.  As long as repeatActive is set, we will fire off the macro again in
	//  nextMacro: with the set delay time.
	
	repeatActive = YES ;
	[ repeatingIndicator setBackgroundColor:onColor ] ;
	
	if ( [ modem currentTransmitState ] ) /* already transmitting */ return ;
	// start a macro otherwise
	if ( ![ manager executeContestMacro:index sheet:sheet modem:modem ] ) {
		[ self cancel ] ;
		[ Messages alertWithMessageText:NSLocalizedString( @"Macro is empty", nil ) informativeText:NSLocalizedString( @"selected macro is empty", nil ) ] ;
	}
}

- (IBAction)stopRepeat:(id)sender
{
	[ self cancel ] ;
}

@end
