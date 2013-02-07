//
//  UserInfo.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 01 2004.
	#include "Copyright.h"
//

#import "UserInfo.h"
#import "Plist.h"
#import "Preferences.h"
#import <time.h>

@implementation UserInfo

- (id)init
{
	NSRect rect ;
	
	self = [ super init ] ;
	if ( self ) {
		if ( [ NSBundle loadNibNamed:@"UserInfo" owner:self ] ) {   
			rect = [ view bounds ] ;
			[ self setFrame:rect display:NO ] ;
			[ [ self contentView ] addSubview:view ] ;
		}
	}
	return self ;
}

- (NSString*)call
{
	return [ callField stringValue ] ;
}

- (NSString*)name
{
	return [ nameField stringValue ] ;
}

- (NSString*)qth
{
	return [ stateField stringValue ] ;
}

- (NSString*)section
{
	return [ arrlSection stringValue ] ;
}

- (void)showSheet:(NSWindow*)window
{
	controllingWindow = window ;
	[ NSApp beginSheet:self modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil ] ;
	[ NSApp runModalForWindow:self ] ;
	//  ... modal mode waits for stopModal in -done
	[ NSApp endSheet:self ] ;
	[ self orderOut:controllingWindow ] ;
}

//  fetch macro
- (NSString*)macroFor:(int)c
{
	NSString *str ;
	
	switch ( c ) {
	case 'a':
		//  arrl section
		str = [ arrlSection stringValue ] ;
		break ;
	case 'b':
		// brag tape
		str = @"\n" ;
		str = [ str stringByAppendingString:[ brag string ] ] ;
		str = [ str stringByAppendingString:@"\n" ] ;
		break ;
	case 'c':
		//  callsign
		str = [ callField stringValue ] ;
		break ;
	case 'g':
		//  grid square
		str = [ gridSquare stringValue ] ;
		break ;
	case 'h':
		// name
		str = [ nameField stringValue ] ;
		break ;
	case 's':
		//  state
		str = [ stateField stringValue ] ;
		break ;
	case 'S':
		//  country
		str = [ country stringValue ] ;
		break ;
	case 'y':
		//  year licensed
		str = [ yearLicensed stringValue ] ;
		break ;
	case 'z':
		//  CQ zone
		str = [ cqZone stringValue ] ;
		break ;
	case 'Z':
		//  ITU zone
		str = [ ituZone stringValue ] ;
		break ;
	default:
		str = @"----" ;
		break ;
	}
	return str ;
}

- (IBAction)done:(id)sender
{
	[ NSApp stopModal ] ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"MyCall" object:nil ] ;
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setString:@"" forKey:kInfoName ] ;
	[ pref setString:@"" forKey:kInfoCall ] ;
	[ pref setString:@"" forKey:kBragTape ] ;
	[ pref setString:@"" forKey:kInfoState ] ;
	[ pref setString:@"" forKey:kInfoCountry ] ;
	[ pref setString:@"" forKey:kInfoGridSquare ] ;
	[ pref setString:@"" forKey:kInfoYearLic ] ;
	[ pref setString:@"" forKey:kInfoSection ] ;
	[ pref setString:@"" forKey:kInfoZone ] ;
	[ pref setString:@"" forKey:kInfoITU ] ;
}

//  update all parameters from the plist (called after fetchPlist )
- (Boolean)updateFromPlist:(Preferences*)pref
{
	[ nameField setStringValue:[ pref stringValueForKey:kInfoName ] ] ;
	[ callField setStringValue:[ pref stringValueForKey:kInfoCall ] ] ;
	[ stateField setStringValue:[ pref stringValueForKey:kInfoState ] ] ;
	[ country setStringValue:[ pref stringValueForKey:kInfoCountry ] ] ;
	[ gridSquare setStringValue:[ pref stringValueForKey:kInfoGridSquare ] ] ;
	[ yearLicensed setStringValue:[ pref stringValueForKey:kInfoYearLic ] ] ;
	[ arrlSection setStringValue:[ pref stringValueForKey:kInfoSection ] ] ;
	[ cqZone setStringValue:[ pref stringValueForKey:kInfoZone ] ] ;
	[ ituZone setStringValue:[ pref stringValueForKey:kInfoITU ] ] ;
	[ brag insertText:[ pref stringValueForKey:kBragTape ] ] ;
	
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	[ pref setString:[ nameField stringValue ] forKey:kInfoName ] ;
	[ pref setString:[ callField stringValue ] forKey:kInfoCall ] ;
	[ pref setString:[ stateField stringValue ] forKey:kInfoState ] ;
	[ pref setString:[ country stringValue ] forKey:kInfoCountry ] ;
	[ pref setString:[ gridSquare stringValue ] forKey:kInfoGridSquare ] ;
	[ pref setString:[ yearLicensed stringValue ] forKey:kInfoYearLic ] ;
	[ pref setString:[ arrlSection stringValue ] forKey:kInfoSection ] ;
	[ pref setString:[ cqZone stringValue ] forKey:kInfoZone ] ;
	[ pref setString:[ ituZone stringValue ] forKey:kInfoITU ] ;
	[ pref setString:[ brag string ] forKey:kBragTape ] ;
}

@end
