//
//  CWMacros.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/10/07.
	#include "Copyright.h"
	

#import "CWMacros.h"
#import "Plist.h"
#import "Preferences.h"
#import "WBCW.h"

@implementation CWMacros

//  button macros
- (Boolean)executeButtonMacro:(char*)str modem:(MacroInterface*)macroInterface
{
	if ( str[0] == 'r' && str[1] == 'x' ) {
		//  add to end of stream
		excessTransmitMacros-- ;
		[ self appendToMessageBuf:[ NSString stringWithFormat:@"%c", 5 /*^E*/ ] ] ;
		return YES ;
	}
	if ( str[0] == 't' && str[1] == 'x' ) {
		//  immediate
		[ self appendToMessageBuf:[ NSString stringWithFormat:@"%c", 6 /*^F*/ ] ] ;
		excessTransmitMacros++ ;
		[ macroInterface sendMessageImmediately ] ;
		return YES ;
	}
	//  v0.89 MacroScript
	if ( str[0] == 'a' ) {
		return [ self executeMacroScript:str ] ;
	}
	return NO ;
}

/* local */
NSString *cwMessageKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kWBCWMessages ;
		break ;
	case 1:
		s = kWBCWOptMessages ;
		break ;
	case 2:
		s = kWBCWShiftMessages ;
		break ;
	}
	return s ;
}

NSString *cwTitleKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kWBCWMessageTitles ;
		break ;
	case 1:
		s = kWBCWOptMessageTitles ;
		break ;
	case 2:
		s = kWBCWShiftMessageTitles ;
		break ;
	}
	return s ;
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index 
{
	NSString *mNames[3] = { @"Macros", @"Option Macros", @"Option-Shift Macros" } ;
	
	if ( name ) [ name setStringValue:mNames[index] ] ;
	[ pref setString:@"" forKey:cwMessageKey(index) ] ;
	[ pref setString:@"" forKey:cwTitleKey(index) ] ;
}

//  update all macros from the plist (called after fetchPlist )
- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index
{
	[ self updateFromPlist:pref messageKey:cwMessageKey(index) titleKey:cwTitleKey(index) ] ;
	return YES ;
}

//  fetch all macros to save to the plist (called befoire savePlist )
- (void)retrieveForPlist:(Preferences*)pref option:(int)index 
{
	[ self retrieveForPlist:pref messageKey:cwMessageKey(index) titleKey:cwTitleKey(index) ] ;
}



@end
