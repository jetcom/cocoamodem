//
//  MacLoggerDX.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "MacLoggerDX.h"
#import "Messages.h"


@implementation MacLoggerDX

- (id)initWithName:(NSString*)vname
{
	NSString *pttApp ;

	self = [ super initWithName:vname ] ;
	if ( self ) {
		type = kMLDXType ;
		keyScript = unkeyScript = nil ;
		//  first check for existance of MacLoggerDX
		pttApp = [ [ NSWorkspace sharedWorkspace ] fullPathForApplication:@"MacLoggerDX" ] ;	
		if ( pttApp ) {
			Boolean isv5 = NO ;
			NSAppleScript *mldxVersionScript ;
			NSAppleEventDescriptor *event ;
			
			mldxVersionScript = [ self loadScriptFor:@"mldxVersion" ] ;
			if ( mldxVersionScript ) {
				if ( [ self executeScript:mldxVersionScript reply:&event withError:"MacLoggerDX version" ] ) {
					if ( event != nil ) {
						NSString *response = [ event stringValue ] ;
						if ( response ) {
							const char *version = [ response cStringUsingEncoding:NSISOLatin1StringEncoding ] ;
							//	check if version string starts with a 5
							if ( version[0] == '5' ) isv5 = YES ;
							[ Messages logMessage:"Found MacLoggerDX %s", version ] ;
						}
					}
				}
			}
			if ( isv5 ) {
				keyScript = [ self loadScriptFor:@"mldx5Key" ] ;
				unkeyScript = [ self loadScriptFor:@"mldx5Unkey" ] ;
			}
			else {
				keyScript = [ self loadScriptFor:@"mldxKey" ] ;
				unkeyScript = [ self loadScriptFor:@"mldxUnkey" ] ;
			}
			return self ;
		}
	}
	return self ;
}

- (Boolean)connected
{
	return ( keyScript != nil && unkeyScript != nil ) ;
}

- (void)setPTTState:(Boolean)state 
{
	//  don't do anything unless both scripts exist
	if ( keyScript == nil || unkeyScript == nil ) return ;
	
	if ( state ) {
		keyScript = [ self executeScript:keyScript withError:"MacLoggerDX PTT on" ] ;
		if ( keyScript ) connected = YES ;
	} 
	else {
		unkeyScript = [ self executeScript:unkeyScript withError:"MacLoggerDX PTT off" ] ;
		if ( unkeyScript ) connected = YES ;
	}
}

@end
