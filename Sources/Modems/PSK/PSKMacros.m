//
//  PSKMacros.m
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
	#include "Copyright.h"
//

#import "PSKMacros.h"
#import "Plist.h"
#import "Preferences.h"
#import "PSK.h"

@implementation PSKMacros

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
		[ (PSK*)macroInterface selectView ] ;
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
NSString *pskMessageKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kPSKMessages ;
		break ;
	case 1:
		s = kPSKOptMessages ;
		break ;
	case 2:
		s = kPSKShiftMessages ;
		break ;
	}
	return s ;
}

NSString *pskTitleKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kPSKMessageTitles ;
		break ;
	case 1:
		s = kPSKOptMessageTitles ;
		break ;
	case 2:
		s = kPSKShiftMessageTitles ;
		break ;
	}
	return s ;
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index 
{
	NSString *mNames[3] = { @"Macros", @"Option Macros", @"Option-Shift Macros" } ;
	
	if ( name ) [ name setStringValue:mNames[index] ] ;
	[ pref setString:@"" forKey:pskMessageKey(index) ] ;
	[ pref setString:@"" forKey:pskTitleKey(index) ] ;
}

//  update all macros from the plist (called after fetchPlist )
- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index
{
	[ self updateFromPlist:pref messageKey:pskMessageKey(index) titleKey:pskTitleKey(index) ] ;
	return YES ;
}

//  fetch all macros to save to the plist (called befoire savePlist )
- (void)retrieveForPlist:(Preferences*)pref option:(int)index 
{
	[ self retrieveForPlist:pref messageKey:pskMessageKey(index) titleKey:pskTitleKey(index) ] ;
}

@end
