//
//  DigitalInterfaces.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "DigitalInterfaces.h"
#import "CocoaPTTInterface.h"
#import "MacLoggerDX.h"
#import "MicroKeyer.h"
#import "ModemConfig.h"
#import "UserPTTInterface.h"
#import "VOXInterface.h"


@implementation DigitalInterfaces


- (id)init
{
	NSArray *array ;
	MicroKeyer *keyer ;
	int i, n ;
	
	self = [ super init ] ;
	if ( self ) {
	
		voxInterface = [ [ VOXInterface alloc ] initWithName:@"VOX" ] ;
		cocoaPTTInterface = [ [ CocoaPTTInterface alloc ] initWithName:@"CocoaPTT" ] ;
		userPTTInterface = [ [ UserPTTInterface alloc ] initWithName:@"User PTT" ] ;
		mldxInterface = [ [ MacLoggerDX alloc ] initWithName:@"MacLoggerDX" ] ;

		//  Router returns nil if Router is unavalable
		router = [ [ Router alloc ] init ] ;
		numberOfDigiKeyers = numberOfDigiKeyerIIs = numberOfMicroKeyers = numberOfCWKeyers = 0 ;
		
		if ( router != nil ) {
			array = [ router connectedKeyers ] ;
			if ( array == nil ) return 0 ;
			n = [ array count ] ;
			for ( i = 0; i < n; i++ ) {
				keyer = array[i] ;
				if ( [ keyer isDigiKeyer ] == YES ) numberOfDigiKeyers++ ;
				if ( [ keyer isDigiKeyerII ] == YES ) numberOfDigiKeyerIIs++ ;
				if ( [ keyer isMicroKeyer ] == YES ) numberOfMicroKeyers++ ;
				if ( [ keyer isCWKeyer ] == YES ) numberOfCWKeyers++ ;
			}
		}
	}
	return self ;
}

- (id)initWithoutRouter
{
	self = [ super init ] ;
	if ( self ) {
	
		voxInterface = [ [ VOXInterface alloc ] initWithName:@"VOX" ] ;
		cocoaPTTInterface = [ [ CocoaPTTInterface alloc ] initWithName:@"CocoaPTT" ] ;
		userPTTInterface = [ [ UserPTTInterface alloc ] initWithName:@"User PTT" ] ;
		mldxInterface = [ [ MacLoggerDX alloc ] initWithName:@"MacLoggerDX" ] ;
		//  set Router to nil
		router = nil ;
		numberOfDigiKeyers = numberOfDigiKeyerIIs = numberOfMicroKeyers = numberOfCWKeyers = 0 ;
	}
	return self ;
}

- (DigitalInterface*)voxInterface 
{
	return voxInterface ;
}

- (DigitalInterface*)cocoaPTTInterface
{
	return cocoaPTTInterface ;
}

- (DigitalInterface*)userPTTInterface
{
	return userPTTInterface ;
}

- (DigitalInterface*)macLoggerDX
{
	return mldxInterface ;
}

- (NSArray*)microHAMKeyers
{
	if ( router == nil ) return @[] ;
	return [ router connectedKeyers ] ;
}

//	return the first microKeyer found
- (MicroKeyer*)microKeyer
{
	NSArray *keyers ;
	MicroKeyer *keyer ;
	int i, n ;
	
	if ( router == nil ) return nil ;
	
	keyers = [ router connectedKeyers ] ;
	n = [ keyers count ] ;
	for ( i = 0; i < n; i++ ) {
		keyer = keyers[i] ;
		if ( [ keyer isMicroKeyer ] ) return keyer ;
	}
	return nil ;
}

- (MicroKeyer*)digiKeyer
{
	NSArray *keyers ;
	MicroKeyer *keyer ;
	int i, n ;
	
	if ( router == nil ) return nil ;
	
	keyers = [ router connectedKeyers ] ;
	n = [ keyers count ] ;
	for ( i = 0; i < n; i++ ) {
		keyer = keyers[i] ;
		if ( [ keyer isDigiKeyer ] ) return keyer ;
	}
	return nil ;
}

- (MicroKeyer*)cwKeyer
{
	NSArray *keyers ;
	MicroKeyer *keyer ;
	int i, n ;
	
	if ( router == nil ) return nil ;
	
	keyers = [ router connectedKeyers ] ;
	n = [ keyers count ] ;
	for ( i = 0; i < n; i++ ) {
		keyer = keyers[i] ;
		if ( [ keyer isCWKeyer ] ) return keyer ;
	}
	return nil ;
}


- (void)useDigitalModeOnlyForFSK:(Boolean)state
{
	NSArray *keyers ;
	int i, n ;
	
	if ( router == nil ) return ;
	
	keyers = [ router connectedKeyers ] ;
	n = [ keyers count ] ;
	for ( i = 0; i < n; i++ ) {
		[ (MicroKeyer*)keyers[i] useDigitalModeForFSK:state ] ;
	}
}

- (int)numberOfDigiKeyers
{
	return numberOfDigiKeyers ;
}

- (int)numberOfDigiKeyerIIs
{
	return numberOfDigiKeyerIIs ;
}

- (int)numberOfMicroKeyers
{
	return numberOfMicroKeyers ;
}

- (int)numberOfCWKeyers
{
	return numberOfCWKeyers ;
}

- (Router*)router
{
	return router ;
}

- (void)dealloc
{
	if ( voxInterface ) [ voxInterface release ] ;
	[ super dealloc ] ;
}

- (void)terminate:(Config*)config
{
	NSString *routerQuitScriptFile ;	
	NSArray *keyers ;
	int i, n ;
	
	if ( router ) {
		if ( [ config quitWithAutoRouting ] == YES ) {
			//  v0.93b
			keyers = [ router connectedKeyers ] ;
			n = [ keyers count ] ;
			for ( i = 0; i < n; i++ ) {
				[ (MicroKeyer*)keyers[i] setKeyerMode:kMicrohamAutoRouting ] ;
			}
		}
		routerQuitScriptFile = [ config microKeyerQuitScriptFileName ] ;	
		if ( routerQuitScriptFile != nil && [ routerQuitScriptFile length ] > 0 ) [ router runQuitScript:routerQuitScriptFile ] ; else [ router closeRouter ] ;
		[ router release ] ;
		router = nil ;
	}
}

- (void)closePTTConnections
{
	[ cocoaPTTInterface closeConnection ] ;
	[ userPTTInterface closeConnection ] ;
}

@end
