//
//  Preferences.m
//  cocoaModem
//
//  Created by Kok Chen on Thu May 20 2004.
	#include "Copyright.h"
//

#import "Preferences.h"
#import "Plist.h"
#import "TextEncoding.h"
#import <CoreFoundation/CoreFoundation.h>


@implementation Preferences

/*  -------------------------------------------------------------------------
	
	1) Preferences init during app startup
		a) new empty dictionary created
	...
	
	2) Config initPreference called
		a) adds default items to dictionary
		b) calls Config to fetchPlist, this updates the defaulted items
	...
	
	3) cocoaModem applicationShouldTerminate called
		a) calls Config to savePlist
		b) application quits.
	------------------------------------------------------------------------ */

- (id)init
{
	NSString *bundleName, *plistPath ;
	char *s, str[128] ;
	int i ;

	self = [ super init ] ;
	if ( self ) {
		hasPlist = NO ;
		// create dictionary to hold preference data
		prefs = [ [ NSMutableDictionary alloc ] init ] ;
		//  make default pathname from bundle info
		bundleName = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleIdentifier" ] ;
		strcpy( str, kPlistDirectory ) ;
		if ( bundleName ) {
			strcat( str, [ bundleName cStringUsingEncoding:kTextEncoding ] ) ;
			strcat( str, ".plist" ) ;
		}
		else {
			//  use default name if plist path is not in bundle
			strcat( str, kDefaultPlist ) ;
		}
		//  v0.76 - Bundle name has changed to use a dash instead of spaces; place the space back to keep using the old plist
		s = str ;
		for ( i = 0; i < 120; i++ ) {
			if ( *s == 0 ) break ;
			if ( *s == '-' ) *s = ' ' ;
			s++ ;
		}
		plistPath = [ NSString stringWithCString:str encoding:kTextEncoding ] ;
		path = [ [ NSString alloc ] initWithString:[ plistPath stringByExpandingTildeInPath ] ] ;
	}
	return self ;
}

// this is for creating a standalone disctionary (e.g., for exporting macros)
- (id)initWithPath:(NSString*)name
{
	self = [ super init ] ;
	if ( self ) {
		hasPlist = NO ;
		// create dictionary to hold preference data
		prefs = [ [ NSMutableDictionary alloc ] init ] ;
		prefs[kNoOpenRouter] = @0 ;
		path = [ name retain ] ;
	}
	return self ;
}

- (void)dealloc
{
	[ prefs release ] ;
	[ path release ] ;
	[ super dealloc ] ;
}

/* local */
//  remove key from old plist
- (void)remove:(NSString*)key
{
	[ prefs removeObjectForKey:key ] ;
}

//  Merge in plist data from .plist file
- (void)fetchPlist:(Boolean)importIfMissing
{	
	NSData *xmlData, *oldXmlData ;
	NSString *errorString, *oldPlistPath, *oldpath ;
	id plist ;
	int button ;

	xmlData = [ NSData dataWithContentsOfFile:path ] ;
	if ( xmlData ) {
		//  get plist from XML data
		plist = (id)CFPropertyListCreateFromXMLData( kCFAllocatorDefault, (CFDataRef)xmlData, kCFPropertyListImmutable, (CFStringRef*)&errorString ) ;
		if ( plist ) {
			// merge and overwrite default values
			[ prefs addEntriesFromDictionary:plist ] ;
			CFRelease( plist ) ;
		}
		//  v0.76 fix leaked memory
		if ( errorString ) CFRelease( errorString ) ;

		hasPlist = YES ;
	}
	else {
		hasPlist = NO ;
		if ( importIfMissing ) {
			//  make default pathname from bundle info
			oldPlistPath = [ NSString stringWithCString:"~/Library/Preferences/w7ay.cocoaModem.plist" encoding:kTextEncoding ] ;
			oldpath = [ oldPlistPath stringByExpandingTildeInPath ] ;
			oldXmlData = [ NSData dataWithContentsOfFile:oldpath ] ;
			if ( oldXmlData ) {
				button = [ [ NSAlert alertWithMessageText:NSLocalizedString( @"Import Preferences from older version of cocoaModem?", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:NSLocalizedString( @"Skip", nil ) otherButton:nil informativeTextWithFormat:@"" ] runModal ] ;
				if ( button == NSAlertDefaultReturn ) {
					// found 1.0 plist, make it the 2.0 plist
					plist = (id)CFPropertyListCreateFromXMLData( kCFAllocatorDefault, (CFDataRef)oldXmlData, kCFPropertyListImmutable, (CFStringRef*)&errorString ) ;
					if ( plist ) {		
						[ prefs addEntriesFromDictionary:plist ] ;
						CFRelease( plist ) ;
						hasPlist = YES ;
					}
				}
			}
		}
	}
}

//  Write preference out to .plist file.
//  The XML formatting is done by the NSMutableDictionary class upon a writeToFile call.
- (void)savePlist
{
	Boolean status ;
	
	status = [ prefs writeToFile:path atomically:YES ] ;
}

//  check if key is in dictionary
- (Boolean)hasKey:(NSString*)key
{
	return ( prefs[key] != nil ) ;
}

- (Boolean)booleanValueForKey:(NSString*)key
{
	id obj = prefs[key] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSNumber class ] ] ) return NO ;
	return [ obj boolValue ] ;
}


- (int)intValueForKey:(NSString*)key
{
	id obj = prefs[key] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSNumber class ] ] ) return 0 ;
	return [ obj intValue ] ;
}

- (void)incrementIntValueForKey:(NSString*)key
{
	id obj = prefs[key] ;
	int intval ;
	
	if ( obj && [ obj isKindOfClass:[ NSNumber class ] ] ) {
		intval = [ obj intValue ] ;
		[ self setInt:intval+1 forKey:key ] ;
	}
}

- (void)setBoolean:(Boolean)value forKey:(NSString*)key
{
	NSNumber *num ;
	
	num = [ NSNumber numberWithBool:value ] ;
	prefs[key] = num ;
}

- (void)setInt:(int)value forKey:(NSString*)key
{
	NSNumber *num ;
	
	num = @(value) ;
	prefs[key] = num ;
}

- (float)floatValueForKey:(NSString*)key
{
	id obj = prefs[key] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSNumber class ] ] ) return 0 ;
	return [ obj floatValue ] ;
}

- (void)setFloat:(float)value forKey:(NSString*)key
{
	NSNumber *num ;
	
	num = @(value) ;
	prefs[key] = num ;
}

- (NSString*)stringValueForKey:(NSString*)key
{
	id obj = prefs[key] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSString class ] ] ) return nil ;
	return ( (NSString*)obj ) ;
}

- (void)setString:(NSString*)obj forKey:(NSString*)key
{
	if ( obj == nil ) {
		// printf( "Preferences: bad string value for key %s\n", [ key cStringUsingEncoding:kTextEncoding ] ) ;
		return ;
	}
	prefs[key] = obj ;
}

- (NSArray*)arrayForKey:(NSString*)key
{
	id obj = prefs[key] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSArray class ] ] ) return nil ;
	return ( (NSArray*)obj ) ;
}

- (void)setArray:(NSArray*)obj forKey:(NSString*)key
{
	if ( obj == nil ) {
		printf( "Preferences: bad array value for key %s\n", [ key cStringUsingEncoding:kTextEncoding ] ) ;
		return ;
	}
	prefs[key] = obj ;
}

//	v0.78
- (NSDictionary*)dictionaryForKey:(NSString*)key
{
	id obj = prefs[key] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSDictionary class ] ] ) return nil ;
	return ( (NSDictionary*)obj ) ;
}

//  v0.78
- (void)setDictionary:(NSDictionary*)obj forKey:(NSString*)key
{
	if ( obj == nil ) {
		printf( "Preferences: bad dictionary value for key %s\n", [ key cStringUsingEncoding:kTextEncoding ] ) ;
		return ;
	}
	prefs[key] = obj ;
}

//	v0.72
- (NSObject*)objectForKey:(NSString*)key
{
	return prefs[key] ;
}

//  Color in our Plist is expressed as an array of three floating point (R,G,B) elements
- (NSColor*)colorValueForKey:(NSString*)key
{
	NSArray *color ;
	NSColor *rgb ;
	float r, g, b ;
	
	color = prefs[key] ;		//  should be an NSArray
	r = [ color[0] floatValue ] ;
	g = [ color[1] floatValue ] ;
	b = [ color[2] floatValue ] ;
	rgb = [ [ NSColor colorWithCalibratedRed:r green:g blue:b alpha:1 ] retain ] ;
	return rgb ;
}

//  Color in our Plist is expressed as an array of three floating point (R,G,B) elements
- (void)setColor:(NSColor*)color forKey:(NSString*)key
{
	NSNumber *r, *g, *b ;
	float red, green, blue, alpha ;
	
	[ color getRed:&red green:&green blue:&blue alpha:&alpha ] ;
	r = @(red) ;
	g = @(green) ;
	b = @(blue) ;
	prefs[key] = @[r, g, b] ;
}

//  Color in our Plist is expressed as an array of three floating point (R,G,B) elements
- (void)setRed:(float)red green:(float)green blue:(float)blue forKey:(NSString*)key
{
	NSNumber *r, *g, *b ;

	r = @(red) ;
	g = @(green) ;
	b = @(blue) ;
	prefs[key] = @[r, g, b] ;
}

- (void)removeKey:(NSString*)key
{
	[ prefs removeObjectForKey:key ] ;
}


@end
