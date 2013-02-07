//
//  AppleScript_TestsAppDelegate.m
//  AppleScript Tests
//
//  Created by Kok Chen on 12/2/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "AppleScript_TestsAppDelegate.h"

@implementation AppleScript_TestsAppDelegate


- (void)applicationDidFinishLaunching:(NSNotification*)note 
{
	NSURL *url ;
	NSString *path ;
	NSDictionary *error ;
	NSAppleScript *script ;
	NSAppleEventDescriptor *desc ;
	int iter ;
	
	path = [ [ NSBundle mainBundle ] pathForResource:@"nextSpectrum" ofType:@"txt" ] ;
	url = [ NSURL fileURLWithPath:path ] ;
	
	for ( iter = 0; iter < 256; iter++ ) {
		script = [ [ NSAppleScript alloc ] initWithContentsOfURL:url error:&error ] ;
		if ( !script ) {
			printf( "script error\n" ) ;
			exit( 0 ) ;
		}
		desc = [ script executeAndReturnError:&error ] ;
		if ( desc != nil ) printf( "%2d: %d\n", iter, desc.int32Value ) ;
		[ script release ] ;
	}
	exit( 0 ) ;
}

@end
