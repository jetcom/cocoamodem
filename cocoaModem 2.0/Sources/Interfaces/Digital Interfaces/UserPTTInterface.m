//
//  UserPTTInterface.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "UserPTTInterface.h"


@implementation UserPTTInterface

- (Boolean)updateScriptsFromFolder:(NSString*)newfolder
{
	[ scriptFolder autorelease ] ;
	scriptFolder = [ [ newfolder stringByExpandingTildeInPath ] retain ] ;

	if ( keyScript ) [ keyScript release ] ;
	if ( unkeyScript ) [ unkeyScript release ] ;
	if ( quitScript ) [ quitScript release ] ;
	keyScript = nil ;
	unkeyScript = nil ;
	quitScript = nil ;
	
	if ( scriptFolder && [ scriptFolder length ] > 1 ) {
		keyScript = [ self loadScriptForPath:[ scriptFolder stringByAppendingString:@"/pttKey.scpt" ] ] ;
		if ( keyScript != nil ) {
			unkeyScript = [ self loadScriptForPath:[ scriptFolder stringByAppendingString:@"/pttUnkey.scpt" ] ] ;
			if ( unkeyScript != nil ) {
				quitScript = [ self loadScriptForPath:[ scriptFolder stringByAppendingString:@"/pttQuit.scpt" ] ] ;
			}
			scriptsLoaded = YES ;
		}
		return YES ;
	}
	else {
		scriptFolder = @"" ;
		scriptsLoaded = NO ;
		return NO ;		
	}
}

- (id)initWithName:(NSString*)vname
{
	self = [ super initWithName:vname ] ;
	if ( self ) {
		hasPTT = YES ;
		keyScript = nil ;
		unkeyScript = nil ;
		quitScript = nil ;
		type = kUserPTTType ;
	}
	return self ;
}


- (void)dealloc
{
	if ( keyScript ) [ keyScript release ] ;
	if ( unkeyScript ) [ unkeyScript release ] ;
	if ( quitScript ) [ quitScript release ] ;
	[ scriptFolder autorelease ] ;
	[ super dealloc ] ;
}

- (Boolean)connected
{
	return ( keyScript != nil && unkeyScript != nil ) ;
}

- (void)closeConnection
{
	if ( connected ) {
		if ( quitScript ) quitScript = [ self executeScript:quitScript withError:"User Defined PTT Script" ] ;
		connected = NO ;
	}
}

- (void)setPTTState:(Boolean)state
{
	//  don't do anything unless both scripts exist
	if ( keyScript == nil || unkeyScript == nil ) return ;
	
	if ( state ) {
		keyScript = [ self executeScript:keyScript withError:"User PTT on" ] ;
		if ( keyScript ) connected = YES ;
	} 
	else {
		unkeyScript = [ self executeScript:unkeyScript withError:"User PTT off" ] ;
		if ( unkeyScript ) connected = YES ;
	}
}

@end
