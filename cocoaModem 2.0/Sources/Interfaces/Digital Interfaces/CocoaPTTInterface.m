//
//  CocoaPTTInterface.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/16/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "CocoaPTTInterface.h"


@implementation CocoaPTTInterface

- (id)initWithName:(NSString*)vname
{
	NSString *pttApp ;

	self = [ super initWithName:vname ] ;
	if ( self ) {
		hasPTT = YES ;
		type = kCocoaPTTType ;
		
		pttApp = [ [ NSWorkspace sharedWorkspace ] fullPathForApplication:@"cocoaPTT" ] ;
		if ( pttApp ) {
			keyScript = [ self loadScriptFor:@"pttKey" ] ;
			unkeyScript = [ self loadScriptFor:@"pttUnkey" ] ;
			quitScript = [ self loadScriptFor:@"pttQuit" ] ;
			#ifdef DEBUGHUB
			printf( "cocoaPTT scripts returned %d %d %d\n", (int)keyScript, (int)unkeyScript, (int)quitScript ) ;
			#endif
		}
		#ifdef DEBUGHUB
		else {
			printf( "could not find cocoaPTT application\n" ) ;
		}
		#endif
	}
	return self ;
}

- (Boolean)connected
{
	return ( keyScript != nil && unkeyScript != nil ) ;
}

- (void)closeConnection
{
	if ( connected ) {
		if ( quitScript ) quitScript = [ self executeScript:quitScript withError:"cocoaPTT" ] ;
		connected = NO ;
	}
}

- (void)setPTTState:(Boolean)state
{
	//  don't do anything unless both scripts exist
	if ( keyScript == nil || unkeyScript == nil ) return ;
	
	if ( state ) {
		keyScript = [ self executeScript:keyScript withError:"cocoaPTT" ] ;
		if ( keyScript ) connected = YES ;
	} 
	else {
		unkeyScript = [ self executeScript:unkeyScript withError:"cocoaPTT" ] ;
		if ( unkeyScript ) connected = YES ;
	}
}

@end
