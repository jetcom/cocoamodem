//
//  ContestConfig.m
//  cocoaModem
//
//  Created by Kok Chen on 10/15/04.
	#include "Copyright.h"
//

#import "ContestInterface.h"
#include "Application.h"
#include "Contest.h"
#include "ContestBar.h"
#include "ContestManager.h"
#include "ContestMacroSheet.h"
#include "ContestTextField.h"
#include "ExchangeView.h"
#include "UTC.h"
#include "ModemManager.h"


@implementation ContestInterface

- (id)initIntoTabView:(NSTabView*)tabview nib:(NSString*)nib manager:(ModemManager*)mgr
{
	self = [ super initIntoTabView:tabview nib:nib manager:mgr ] ;
	if ( self ) {
		contestBar = nil ;
		savedString = [ NSString stringWithString:@"" ] ;
	}
	return self ;
}

- (void)setClock:(UTC*)utcp
{
	struct tm *gmt ;
	
	if ( contestDate && contestTime ) {
		gmt = [ utcp utc ] ;
		[ contestDate setStringValue:[ NSString stringWithFormat:@"%02d-%02d-%02d", gmt->tm_mday, gmt->tm_mon+1, ( gmt->tm_year+1900 )%100 ] ] ;
		[ contestTime setStringValue:[ NSString stringWithFormat:@"%02d:%02d", gmt->tm_hour, gmt->tm_min ] ] ;
	}
}

- (void)timeTick:(NSNotification*)notify
{
	[ self setClock:(UTC*)[ notify object ] ] ;
}

- (void)callFieldSelected:(NSNotification*)notify
{
	if ( contestBar ) [ contestBar cancel ] ;
	if ( self != [ contestManager selectedContestInterface ] ) return ;
	currentField = [ notify object ] ;
	selectedField = kCallsignTextField ;
}

- (void)exchFieldSelected:(NSNotification*)notify
{
	if ( contestBar ) [ contestBar cancel ] ;
	if ( self != [ contestManager selectedContestInterface ] ) return ;
	currentField = [ notify object ] ;
	selectedField = kExchangeTextField ;
}

- (void)extraFieldSelected:(NSNotification*)notify
{
	if ( contestBar ) [ contestBar cancel ] ;
	if ( self != [ contestManager selectedContestInterface ] ) return ;
	currentField = [ notify object ] ;
	selectedField = kExtraTextField ;
}

- (void)initContest:(Contest*)newContest master:(Contest*)inMaster manager:(ContestManager*)inManager
{
	Contest *oldContest ;
	
	oldContest = contest ;
	contest = newContest ;
	master = inMaster ;
	contestManager = inManager ;
	selectedField = 0 ;
	[ contest initIntoBox:contestView contestName:[ master contestName ] prototype:[ master prototypeName ] modem:self master:inMaster manager:contestManager ] ;
	if ( oldContest ) [ oldContest release ] ;
	[ self setClock:[ [ manager appObject ] clock ] ] ;
	if ( contestBar ) [ contestBar setManager:contestManager ] ;
}

//  called from awakeFromNib of actual contests
- (void)awakeFromContest
{
	currentSheet = 0 ;
	contestModeIndex = kContestModeCQ ;
	selectedField = 0 ;
	inContestMode = NO ;
	contest = nil ;
	master = nil ;
	contestManager = nil ;
	mainRunLoop = [ NSRunLoop currentRunLoop ] ;
	if ( contestDate && contestTime ) {
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(timeTick:) name:@"MinuteTick" object:nil ] ;
	}
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(callFieldSelected:) name:CallNotify object:nil ] ;
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(exchFieldSelected:) name:ExchangeNotify object:nil ] ;
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(extraFieldSelected:) name:ExtraFieldNotify object:nil ] ;
}

- (void)keyModifierChanged:(NSNotification*)notify
{
	if ( contestBar ) [ contestBar cancel ] ;
	[ super keyModifierChanged:notify ] ;
	//  option flag -- need to update macro button captions (same currentSheet as MacroInterface)
	[ self updateContestMacroButtons ] ;
}

- (void)selectContestMode:(Boolean)state
{
	int whichView ;
	
	if ( contestBar ) [ contestBar cancel ] ;
	whichView = ( state == NO ) ? 0 : 1 ;	// normal = 0, contest = 1
	
	[ contestTab selectTabViewItemAtIndex:whichView ] ;
	inContestMode = state ;
}

//  intercept call from Application to Modem
//  usually occurs when the modem is switched by the tab in the interface window (e.g., from PSK to RTTY)
- (void)setVisibleState:(Boolean)visible
{
	if ( contestBar ) [ contestBar cancel ] ;
	[ super setVisibleState:visible ] ;
	if ( visible == YES ) {
		if ( contestManager ) {
			[ contestManager setActiveContestInterface:self ] ;
		}
		//  setup repeating macro bar
		if ( contestBar ) [ contestBar setModem:self ] ;
		[ self updateContestMacroButtons ] ;
	}
}

- (void)setContestBar:(ContestBar*)bar
{
	contestBar = bar ;
}

- (void)transmissionEnded
{
	if ( contestBar ) {
		//  [ contestBar nextMacro ] 
		//  need to perform as NSRunLoop performSelector... since transmissionEnded is called from a A/D converter thread
		if ( mainRunLoop ) [ mainRunLoop performSelector:@selector(nextMacro:) target:contestBar argument:self order:0 modes:[ NSArray arrayWithObject:NSDefaultRunLoopMode ] ] ;
	}
}

- (void)updateContestMacroButtons
{
	NSMatrix *matrix ;
	NSTextField *field ;
	NSButton *button ;
	NSString *string ;
	int i ;
	
	if ( contestBar ) [ contestBar cancel ] ;
	if ( manager ) {
		//  fetch matrix of current sheet's title
		matrix = [ contestManager macroTitles:currentSheet+contestModeIndex ] ;
		for ( i = 0; i < 8; i++ ) {
			field = [ matrix cellAtRow:i column:0 ] ;
			string = [ field stringValue ] ;
			if ( contestMessageMatrix ) {
				button = [ contestMessageMatrix cellAtRow:0 column:i ] ;
				if ( string != nil && ![ string isEqualToString:@"" ] ) {
					[ button setTitle:string ] ;
				}
				else {
					[ button setTitle:[ NSString stringWithFormat:@"Mcr %d", i+1 ] ] ;
				}
			}
		}
	}
}

- (int)contestModeIndex 
{
	return contestModeIndex ;
}

//  set up the contest bar for repeating the latest invoked macro
- (void)newMacroForContestBar:(int)index sheet:(int)sheet
{
	if ( contestBar ) {
		[ contestBar cancel ] ;
		[ contestBar newMacroCalled:index sheet:sheet manager:contestManager modem:self ] ;
	}
}

- (IBAction)transmitContestMessage:(id)sender
{
	int index, sheet ;

	index = [ sender selectedColumn ] ;
	sheet = currentSheet+contestModeIndex ;
	[ self newMacroForContestBar:index sheet:sheet ] ;
	[ contestManager executeContestMacro:index sheet:sheet modem:self ] ;
}

- (IBAction)showContestMacroSheet:(id)sender
{
	int sheet ;
	
	if ( manager ) {
		if ( contestBar ) [ contestBar cancel ] ;
		sheet = currentSheet + contestModeIndex ;
		currentSheet = 0 ;
		[ contestManager showContestMacroSheet:sheet ] ;
	}
}

//  CQ/SP mode (kContestModeCQ=0, kContestModeSP=3)
- (IBAction)contestModeChanged:(id)sender
{
	int t ;
	
	if ( contestBar ) [ contestBar cancel ] ;
	contestModeIndex = [ [ sender selectedCell ] tag ] ;
	t = ( contestModeIndex ) ? 0 : 1 ;
	[ [ sender cellAtRow:0 column:t ] setState:NSOffState ] ;
	[ [ sender cellAtRow:0 column:1-t ] setState:NSOnState ] ;
	[ self updateContestMacroButtons ] ;
	[ contestManager contestSwitchedToCQ:( contestModeIndex == kContestModeCQ ) ] ;
}

//  overrides the captureCallsign in Modem.m
- (NSRange)captureCallsign:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{
	Boolean properClick, controlClick ;
	NSRange range ;
	NSTextStorage *storage ;
	NSString *string ;
	Boolean locked ;		//  v0.67 (check for too many unlocks)
	
	if ( contestBar ) [ contestBar cancel ] ;
	
	[ (ExchangeView*)textView setAppendLock:YES ] ;
	locked = YES ;

	properClick = [ (ExchangeView*)textView getAndClearMouseClick ] ;
	controlClick = [ (ExchangeView*)textView getAndClearRightMouse ] ;
	
	if ( !properClick || !controlClick || !inContestMode ) {
		range = [ super captureCallsign:textView willChangeSelectionFromCharacterRange:oldSelectedCharRange toCharacterRange:newSelectedCharRange ] ;
	}
	else {
		//  in contest mode, now check if callsign field or exchange field was selected
		switch ( selectedField ) {
		case kCallsignTextField:
			if ( controlKeyState && newSelectedCharRange.length > 0 ) {
				range = oldSelectedCharRange ;
			}
			else {
				range = [ self getCallsignString:textView from:newSelectedCharRange ] ;
				if ( range.length <= 0 ) {
					[ (ExchangeView*)textView setAppendLock:NO ] ;
					locked = NO ;
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"ReselectField" object:nil ] ;
					range = oldSelectedCharRange ;
				}
				else {
					storage = [ textView textStorage ] ;
					string = [ [ storage attributedSubstringFromRange:range ] string ] ;
					if ( string && [ string length ] < 32 ) {
						[ self upperCase:string into:captured ] ;
						[ (ExchangeView*)textView setAppendLock:NO ] ;
						locked = NO ;
						[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"CapturedContestCallsign" object:self ] ;
						range.length = 0 ;
					}
				}
			}
			break ;
		case kExchangeTextField:
			if ( controlKeyState && newSelectedCharRange.length > 0 ) {
				range = oldSelectedCharRange ;
			}
			else {
				range = [ self getExchangeString:textView from:newSelectedCharRange ] ;
				if ( range.length <= 0 ) {
					range = oldSelectedCharRange ;			// 0.45
				}
				else {
					storage = [ textView textStorage ] ;
					string = [ [ storage attributedSubstringFromRange:range ] string ] ;
					if ( string && [ string length ] < 32 ) {
						[ self upperCase:string into:captured ] ;
						[ (ExchangeView*)textView setAppendLock:NO ] ;
						locked = NO ;
						[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"CapturedContestExchange" object:self ] ;
						range.length = 0 ;
					}
				}
			}
			break ;
		case kExtraTextField:
			if ( controlKeyState && newSelectedCharRange.length > 0 ) {
				range = oldSelectedCharRange ;
			}
			else {
				range = [ self getExchangeString:textView from:newSelectedCharRange ] ;
				if ( range.length <= 0 ) {
					range = oldSelectedCharRange ;			// 0.45
				}
				else {
					storage = [ textView textStorage ] ;
					string = [ [ storage attributedSubstringFromRange:range ] string ] ;
					if ( string && [ string length ] < 32 ) {
						[ self upperCase:string into:captured ] ;
						[ (ExchangeView*)textView setAppendLock:NO ] ;
						locked = NO ;
						[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"CapturedSecondExchange" object:self ] ;
						range.length = 0 ;
					}
				}
			}
			break ;
		default:
			//  should not get here
			selectedField = kCallsignTextField ;
			range = newSelectedCharRange ;
			break ;
		}
	}
	if ( locked ) [ (ExchangeView*)textView setAppendLock:NO ] ;
	return range ;
}

- (void)delayedFinishClick:(NSTimer*)timer
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"FinishControlClick" object:nil ] ;
}

- (void)delayedSelectField:(NSTimer*)timer
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"ReselectField" object:nil ] ;
}

- (void)callsignClickSuccessful:(Boolean)success
{
	SEL selector ;

	selector = ( success ) ? @selector(delayedFinishClick:) : @selector(delayedSelectField:) ;
	[ NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:selector userInfo:self repeats:NO ] ;
}


//  ----------- preferences -------------
- (void)setupDefaultPreferences:(Preferences*)pref 
{
	[ super setupDefaultPreferences:pref ] ;
	if ( contestBar ) [ contestBar setupDefaultPreferences:pref ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	Boolean state ;
	
	state = [ super updateFromPlist:pref ] ;
	if ( contestBar ) state = state && [ contestBar updateFromPlist:pref ] ;
	return state ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	[ super retrieveForPlist:pref ] ;
	if ( contestBar ) [ contestBar retrieveForPlist:pref ] ;
}



@end
