//
//  DigitalInterface.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/16/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "DigitalInterface.h"


@implementation DigitalInterface

- (id)initWithName:(NSString*)vname
{
	self = [ super init ] ;
	if ( self ) {
		type = 0 ;
		hasPTT = connected = NO ;
		name =[ [ NSString alloc ] initWithString:vname ] ;
	}
	return self ;
}

- (Boolean)connected
{
	return NO ;
}

- (id)init
{
	NSLog( @"DigitalInterface needs to be initialized with name" ) ;
	return nil ;
}

- (void)dealloc
{
	[ name release ] ;
	[ super dealloc ] ;
}

- (NSString*)name
{
	return name ;
}

- (int)type
{
	return type ;
}

- (Boolean)hasPTT
{
	return hasPTT ;
}

- (void)setPTTState:(Boolean)state 
{
}

- (Boolean)hasFSK
{
	return NO ;
}

- (Boolean)hasOOK
{
	return NO ;
}

- (void)closeConnection
{
}

@end
