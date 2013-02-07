//
//  AppleScriptSupport.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "AppleScriptSupport.h"
#import "Messages.h"

@implementation AppleScriptSupport

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		scriptFolder = @"" ;
		scriptsLoaded = NO ;
	}
	return self ;
}

- (Boolean)updateScriptsFromFolder:(NSString*)newfolder
{
	return NO ;
}

- (NSString*)folderName
{
	NSArray *folderPath ;
	
	if ( [ scriptFolder length ] <= 0 ) return @"" ;

	folderPath = [ scriptFolder pathComponents ] ;
	return folderPath[[ folderPath count ]-1] ;
}



- (NSAppleScript*)loadScriptForPath:(NSString*)path withErrorDictionary:(NSDictionary**)dict
{
	NSURL *url ;
	NSAppleScript *script ;

	script = nil ;	
	if ( [ path length ] > 0 ) {
		url = [ NSURL fileURLWithPath:path ] ;
		if ( !url || [ url isFileURL ] == NO ) return nil ;
		script = [ [ NSAppleScript alloc ] initWithContentsOfURL:url error:dict ] ;
		if ( !script ) {
			[ Messages appleScriptError:*dict script:(const char*)[ path cStringUsingEncoding:kTextEncoding ] ] ;
			return nil ;
		}
	}
	return script ;
}

//  load a script file with an arbitrary path name
- (NSAppleScript*)loadScriptForPath:(NSString*)path
{
	NSDictionary *dict ;
	NSAppleScript *result ;
	
	result = [ self loadScriptForPath:path withErrorDictionary:&dict ] ;
	return result ;
}

- (NSAppleScript*)loadScriptFor:(NSString*)scptFile withErrorDictionary:(NSDictionary**)dict
{
	NSString *path ;
	
	path = [ [ NSBundle mainBundle ] pathForResource:scptFile ofType:@"scpt" ] ;
	return [ self loadScriptForPath:path withErrorDictionary:dict ] ;
}

//  load a script file from the Application bundle
- (NSAppleScript*)loadScriptFor:(NSString*)scptFile
{
	NSDictionary *dict ;
	NSAppleScript *result ;
	
	result = [ self loadScriptFor:scptFile withErrorDictionary:&dict ] ;
	return result ;
}

//  return the script back if succeded, return nil if failed
- (NSAppleScript*)executeScript:(NSAppleScript*)script withError:(const char*)msg
{
	NSDictionary *err ;
	
	if ( [ script executeAndReturnError:&err ] ) {
		return script ;
	}
	// AppleScript error
	[ Messages appleScriptError:err script:msg ] ;
	return nil ;
}

//  return the script back if succeded, return nil if failed
- (NSAppleScript*)executeScript:(NSAppleScript*)script reply:(NSAppleEventDescriptor**)eventDescriptorp withError:(const char*)msg
{
	NSDictionary *err ;
	
	*eventDescriptorp = [ script executeAndReturnError:&err ] ;
	if ( *eventDescriptorp != nil ) {
		return script ;
	}
	// AppleScript error
	[ Messages appleScriptError:err script:msg ] ;
	return nil ;
}

@end
