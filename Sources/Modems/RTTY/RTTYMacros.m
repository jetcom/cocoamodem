//
//  RTTYMacros.m
//  cocoaModem
//
//  Created by Kok Chen on Sat Jul 03 2004.
	#include "Copyright.h"
//

#import "RTTYMacros.h"
#include "Plist.h"
#include "Preferences.h"
#include "RTTY.h"

@implementation RTTYMacros

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
	if ( str[0] == 'b' ) {
		// bandwidth
		switch ( str[1] ) {
		case '1':
			[ (RTTY*)macroInterface selectBandwidth:0 ] ;
			break ;
		case '2':
			[ (RTTY*)macroInterface selectBandwidth:1 ] ;
			break ;
		case '3':
			[ (RTTY*)macroInterface selectBandwidth:2 ] ;
			break ;
		}
		return YES ;
	}
	if ( str[0] == 'd' ) {
		// demodulator
		switch ( str[1] ) {
		case '1':
			[ (RTTY*)macroInterface selectDemodulator:4 ] ;
			break ;
		case '2':
			[ (RTTY*)macroInterface selectDemodulator:3 ] ;
			break ;
		case '3':
			[ (RTTY*)macroInterface selectDemodulator:2 ] ;
			break ;
		}
		return YES ;
	}
	return NO ;
}

NSString *rttyMessageKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kRTTYMessages ;
		break ;
	case 1:
		s = kRTTYOptMessages ;
		break ;
	case 2:
		s = kRTTYShiftMessages ;
		break ;
	}
	return s ;
}

NSString *rttyTitleKey( int index )
{
	NSString *s ;
	
	switch ( index ) {
	case 0:
	default:
		s = kRTTYMessageTitles ;
		break ;
	case 1:
		s = kRTTYOptMessageTitles ;
		break ;
	case 2:
		s = kRTTYShiftMessageTitles ;
		break ;
	}
	return s ;
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref option:(int)index 
{
	if ( name ) {
		if ( index == 0 ) [ name setStringValue:@"Macros" ] ;
		if ( index == 1 ) [ name setStringValue:@"Option Macros" ] ;
		if ( index == 2 ) [ name setStringValue:@"Option-Shift Macros" ] ;
	}
	[ pref setString:@"" forKey:rttyMessageKey(index) ] ;
	[ pref setString:@"" forKey:rttyTitleKey(index) ] ;
}

//  update all macros from the plist (called after fetchPlist )
- (Boolean)updateFromPlist:(Preferences*)pref option:(int)index
{
	[ self updateFromPlist:pref messageKey:rttyMessageKey(index) titleKey:rttyTitleKey(index) ] ;
	return YES ;
}

//  fetch all macros to save to the plist (called before savePlist )
- (void)retrieveForPlist:(Preferences*)pref option:(int)index 
{
	[ self retrieveForPlist:pref messageKey:rttyMessageKey(index) titleKey:rttyTitleKey(index) ] ;
}

@end
