//
//  HellMacros.m
//  cocoaModem
//
//  Created by Kok Chen on Mon Jan 30 2006.
	#include "Copyright.h"
//

#import "HellMacros.h"
#include "Plist.h"
#include "Preferences.h"
#include "Hellschreiber.h"

@implementation HellMacros

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
NSString *hellMessageKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kHellMessages ;
		break ;
	case 1:
		s = kHellOptMessages ;
		break ;
	case 2:
		s = kHellShiftMessages ;
		break ;
	}
	return s ;
}

NSString *hellTitleKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kHellMessageTitles ;
		break ;
	case 1:
		s = kHellOptMessageTitles ;
		break ;
	case 2:
		s = kHellShiftMessageTitles ;
		break ;
	}
	return s ;
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index 
{
	NSString *mNames[3] = { @"Macros", @"Option Macros", @"Option-Shift Macros" } ;
	
	if ( name ) [ name setStringValue:mNames[index] ] ;
	[ pref setString:@"" forKey:hellMessageKey(index) ] ;
	[ pref setString:@"" forKey:hellTitleKey(index) ] ;
}

//  update all macros from the plist (called after fetchPlist )
- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index
{
	[ self updateFromPlist:pref messageKey:hellMessageKey(index) titleKey:hellTitleKey(index) ] ;
	return YES ;
}

//  fetch all macros to save to the plist (called befoire savePlist )
- (void)retrieveForPlist:(Preferences*)pref option:(int)index 
{
	[ self retrieveForPlist:pref messageKey:hellMessageKey(index) titleKey:hellTitleKey(index) ] ;
}

@end
