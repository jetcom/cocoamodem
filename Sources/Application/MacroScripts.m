//
//  MacroScripts.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/20/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "MacroScripts.h"
#import "Messages.h"

@implementation MacroScripts

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		for ( i = 0; i < 6; i++ ) appleScript[i] = nil ;
	}
	return self ;
}

- (void)dealloc
{
	int i ;
	
	for ( i = 0; i < 6; i++ ) {
		if ( appleScript[i] != nil ) [ appleScript[i] release ] ;
	}
	[ super dealloc ] ;
}

//	return nil if failed.
- (NSAppleScript*)setScriptFile:(NSString*)fileName index:(int)index
{
	NSURL *url ;
	NSDictionary *dict ;
	NSAppleScript *script ;
	
	dict = nil ;
	appleScript[index] = nil ;
	if ( [ fileName length ] > 0 ) {
		url = [ NSURL fileURLWithPath:[ fileName stringByExpandingTildeInPath ] ] ;
		script = [ [ NSAppleScript alloc ] initWithContentsOfURL:url error:&dict ] ;
		if ( script != nil ) {
			if ( [ script compileAndReturnError:&dict ] ) {
				appleScript[index] = script ;
				[ dict release ] ;
				return script ;
			}
		}
		[ Messages appleScriptError:dict script:"Macro Script" ] ;
	}
	return nil ;
}

- (void)executeMacroScript:(int)index
{
	NSDictionary *dict ;
	NSAppleScript *script ;
	
	script = appleScript[index] ;
	if ( script ) {
		dict = [ [ NSDictionary alloc ] init ] ; ;
		if ( ![ script executeAndReturnError:&dict ] ) {
			//  if error, remove AppleScript after a warning message
			[ Messages appleScriptError:dict script:"Macro Script" ] ;
			[ script release ] ;
			appleScript[index] = nil ;
		}
		[ dict release ] ;
	}
}


@end
