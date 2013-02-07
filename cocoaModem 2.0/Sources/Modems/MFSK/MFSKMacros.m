//
//  MFSKMacros.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/16/06.
	#include "Copyright.h"
	
#import "MFSKMacros.h"
#include "Plist.h"
#include "Preferences.h"
#include "MFSK.h"

@implementation MFSKMacros

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
NSString *mfskMessageKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kMFSKMessages ;
		break ;
	case 1:
		s = kMFSKOptMessages ;
		break ;
	case 2:
		s = kMFSKShiftMessages ;
		break ;
	}
	return s ;
}

NSString *mfskTitleKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kMFSKMessageTitles ;
		break ;
	case 1:
		s = kMFSKOptMessageTitles ;
		break ;
	case 2:
		s = kMFSKShiftMessageTitles ;
		break ;
	}
	return s ;
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index 
{
	NSString *mNames[3] = { @"Macros", @"Option Macros", @"Option-Shift Macros" } ;
	
	if ( name ) [ name setStringValue:mNames[index] ] ;
	[ pref setString:@"" forKey:mfskMessageKey(index) ] ;
	[ pref setString:@"" forKey:mfskTitleKey(index) ] ;
}

//  update all macros from the plist (called after fetchPlist )
- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index
{
	[ self updateFromPlist:pref messageKey:mfskMessageKey(index) titleKey:mfskTitleKey(index) ] ;
	return YES ;
}

//  fetch all macros to save to the plist (called befoire savePlist )
- (void)retrieveForPlist:(Preferences*)pref option:(int)index 
{
	[ self retrieveForPlist:pref messageKey:mfskMessageKey(index) titleKey:mfskTitleKey(index) ] ;
}

@end
