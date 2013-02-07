//
//  MacroInterface.m
//  cocoaModem
//
//  Created by Kok Chen on 11/20/04.
	#include "Copyright.h"
//

#import "MacroInterface.h"
#import "Application.h"
#import "MacroSheet.h"
#import "Messages.h"
#import "StdManager.h"
#import "RTTYMacros.h"
#import "TextEncoding.h"


@implementation MacroInterface

#define VALIDATE
#define	CC( c )		( ( s[c] & 0x5f ) - 1 )
#define	DC( c )		( ( s[c] & 0x7f ) - 2 )

- (void)initMacros
{
	check = 0 ;
	exclusionLicense = NO ;
	exclusionCount = 0 ;
}

- (void)keyModifierChanged:(NSNotification*)notify
{
	int optionFlag ;
	
	[ super keyModifierChanged:notify ] ;
	//  option flag
	//    0 - no option
	//    1 - option
	//    2 - option shift
	//  update macro button captions
	optionFlag = 0 ;
	if ( optionKeyState ) {
		if ( shiftKeyState ) optionFlag = 2 ; else optionFlag = 1 ;
	}
	currentSheet = optionFlag ;
	[ self updateMacroButtons ] ;
}

- (Boolean)validate:(NSString*)string
{
	const char *s ;
	int i, length ;
	
	length = [ string length ] ;	
	s = [ string cStringUsingEncoding:kTextEncoding ]+1 ;		
	for ( i = 0; i < length-4; i++, s++ ) {
		if ( CC(0) == 64 && DC(2) == 51 && CC(3) == 85 && CC(4) == 84 && CC(1) == 64 ) {
			if ( ++check > 20 ) return NO ;
		}
	}
	return YES ;
	
}

//  override this if needed
- (void)updateMacroButtons
{
	[ self updateModeMacroButtons ] ;
}

- (void)updateModeMacroButtons
{
	NSMatrix *matrix ;
	NSTextField *field ;
	NSButton *button ;
	NSString *string ;
	int i ;
	
	//  fetch matrix of current sheet's title
	matrix = [ macroSheet[currentSheet] titles ] ;
	for ( i = 0; i < 12; i++ ) {
		field = [ matrix cellAtRow:i column:0 ] ;
		string = [ field stringValue ] ;
		if ( messageMatrix ) {
			button = [ messageMatrix cellAtRow:0 column:i ] ;
			if ( string != nil && ![ string isEqualToString:@"" ] ) {
				[ button setTitle:string ] ;
			}
			else {
				[ button setTitle:[ NSString stringWithFormat:@"Mcr %d", i+1 ] ] ;
			}
		}
	}
}

//  execute string
- (void)executeMacroString:(NSString*)macro
{
	if ( macro ) [ transmitView insertAtEnd:macro ] ;
	
	if ( transmitCount > 0 ) {
		//  keep transmit on if needed
		if ( transmitState == NO ) [ self changeTransmitStateTo:YES ] ;
	}
}

//  execute a macro in a macroSheet
- (void)executeMacro:(int)index macroSheet:(MacroSheet*)sheet fromContest:(Boolean)fromContest
{
	NSString *macro ;
	NSRange range ;
	 
	macro = [ sheet expandMacro:index modem:self ] ;
	
	#ifndef VALIDATE
	if ( fromContest ) {
		if ( [ self validate:macro ] ) {
			[ self executeMacroString:macro ] ;
		}
		return ;
	}
	#endif
	
	//  COPYRIGHT NOTICE:
	//  Do not change or remove the following filter from any cocoaModem build.
	if ( fromContest ) {
		range = [ [ macro uppercaseString ] rangeOfString:@"AA5VU" ] ;
		if ( exclusionLicense || range.location != NSNotFound ) {
			exclusionCount++ ;
			if ( exclusionCount > 16 ) {
				[ Messages alertWithMessageText:@"Contest macros disabled." informativeText:@"You are not licensed to use the contest interface in cocoaModem." ] ;
				exclusionLicense = YES ;
				return ;
			}
		}
	}
	//  end of copyright notice.
	
	[ self executeMacroString:macro ] ;
}

//  execute a macro in a (non-contest) macroSheet
- (void)executeMacro:(int)index sheetNumber:(int)n
{
	[ self executeMacro:index macroSheet:macroSheet[n] fromContest:NO ] ;
}

//  execute a macro in the current (non-contest) macroSheet
- (void)executeMacroInSelectedSheet:(int)index
{
	[ self executeMacro:index macroSheet:macroSheet[currentSheet] fromContest:NO ] ;
}

- (MacroSheet*)macroSheet:(int)index
{
	if ( index < 0 || index > 2 ) index = 0 ;
	return macroSheet[index] ;
}

- (void)setMacroSheet:(MacroSheet*)sheet index:(int)i
{
	macroSheet[i] = sheet ;
}

- (IBAction)showMacroSheet:(id)sender
{
	int sheet ;
	
	sheet = currentSheet ;
	currentSheet = 0 ;
	[ macroSheet[sheet] showMacroSheet:[ controllingTabView window ] modem:self ] ;
}

- (IBAction)transmitMessage:(id)sender
{
	int index ;
	NSString *title ;
	
	index = [ sender selectedColumn ] ;
	title = [ macroSheet[currentSheet] title:index ] ;
	if ( title == nil || [ title length ] == 0 ) {
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
		return ;
	}
	[ self executeMacroInSelectedSheet:index ] ;
}


@end
