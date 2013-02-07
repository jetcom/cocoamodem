//
//  MicroKeyer.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/1/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "MicroKeyer.h"
#import "KeyerInterface.h"
#import "RouterCommands.h"

@implementation MicroKeyer


- (void)finishInit
{
	type = kMicroHAMType ;
	useDigitalModeForFSK = NO ;
	
	fskWriteDescriptor = flagsReadDescriptor = pttWriteDescriptor = controlWriteDescriptor = 0 ;
	//  obtain ports to keyer functions
	
	obtainRouterPorts( nil, &pttWriteDescriptor, OPENPTT|WRITEONLY, readFileDescriptor, writeFileDescriptor ) ;
	obtainRouterPorts( nil, &controlWriteDescriptor, OPENCONTROL|WRITEONLY, readFileDescriptor, writeFileDescriptor ) ;
	//  obtain ports for FSK if the keyer supports it
	if ( [ self isMicroKeyer ] || [ self isDigiKeyer ] ) {
		obtainRouterPorts( nil, &fskWriteDescriptor, OPENFSK|WRITEONLY, readFileDescriptor, writeFileDescriptor ) ;
		obtainRouterPorts( &flagsReadDescriptor, nil, OPENFLAGS, readFileDescriptor, writeFileDescriptor ) ;
	}
}

//  old (single keyer) µH Router
- (id)initWithReadFileDescriptor:(int)keyerReadFileDescriptor writeFileDescriptor:(int)keyerWriteFileDescriptor serialNumber:(char*)dummySerial
{
	self = [ super initWithName:@"" ] ;
	if ( self ) {
		newStyle = NO ;
		strcpy( keyerID, dummySerial ) ;
		readFileDescriptor = keyerReadFileDescriptor ;
		writeFileDescriptor = keyerWriteFileDescriptor ;
		[ self finishInit ] ;
	}
	return self ;
}

//  new (multi keyer) µH Router
- (id)initWithKeyerID:(char*)kid
{
	int routerRd, routerWr ;

	self = [ super initWithName:@"" ] ;
	if ( self ) {
		newStyle = YES ;
		strcpy( keyerID, kid ) ;
		readFileDescriptor = writeFileDescriptor = 0 ;
		//  open read/write ports to Router
		routerRd = open( "/tmp/microHamRouterRead", O_RDONLY ) ;
		routerWr = open( "/tmp/microHamRouterWrite", O_WRONLY ) ;
		if ( routerRd > 0 && routerWr > 0 ) {
			obtainKeyerPortsFromKeyerID( &readFileDescriptor, &writeFileDescriptor, kid, routerRd, routerWr ) ;
			close( routerRd ) ;
			close( routerWr ) ;
			[ self finishInit ] ;
		}
	}
	return self ;
}

- (NSString*)keyerTypeString
{
	if ( [ self isMicroKeyerI ] ) return @"microKeyer" ;
	if ( [ self isMicroKeyerII ] ) return @"microKeyer II" ;
	if ( [ self isDigiKeyerI ] ) return @"digiKeyer" ;
	if ( [ self isDigiKeyerII ] ) return @"digiKeyer II" ;
	if ( [ self isCWKeyer ] ) return @"cwKeyer" ;
	return @"unknown microHAM keyer" ;
}

- (Boolean)hasFSK
{
	return ( [ self isDigiKeyer ] || [ self isMicroKeyer ] ) ;
}

- (Boolean)connected
{
	return YES ;
}

static Boolean isType( char *kid, char *type )
{
	return ( kid[0] == type[0] && kid[1] == type[1] ) ;
}

- (Boolean)isMicroKeyer
{
	return ( isType( keyerID, "MK" ) || isType( keyerID, "M2" ) ) ;
}

- (Boolean)isMicroKeyerI
{
	return ( isType( keyerID, "MK" ) ) ;
}

- (Boolean)isMicroKeyerII
{
	return ( isType( keyerID, "M2" ) ) ;
}

- (Boolean)isDigiKeyer
{
	return ( isType( keyerID, "DK" ) || isType( keyerID, "D2" ) ) ;
}

- (Boolean)isDigiKeyerI
{
	return ( isType( keyerID, "DK" ) ) ;
}

- (Boolean)isDigiKeyerII
{
	return ( isType( keyerID, "D2" ) ) ;
}

- (Boolean)isCWKeyer
{
	return isType( keyerID, "CK" ) ;
}

- (void)dealloc
{
	char closeRequest = CLOSEKEYER ;
	
	if ( pttWriteDescriptor > 0 ) close( pttWriteDescriptor ) ;
	if ( controlWriteDescriptor > 0 ) close( controlWriteDescriptor ) ;
	if ( fskWriteDescriptor > 0 ) close( fskWriteDescriptor ) ;
	if ( flagsReadDescriptor > 0 ) close( flagsReadDescriptor ) ;
	write( writeFileDescriptor, &closeRequest, 1 ) ;
	if ( readFileDescriptor > 0 ) close( readFileDescriptor ) ;
	if ( writeFileDescriptor > 0 ) close( writeFileDescriptor ) ;

	[ super dealloc ] ;
}

- (char*)keyerID
{
	return keyerID ;
}

- (int)flagsReadDescriptor
{
	return flagsReadDescriptor ;
}

- (int)fskWriteDescriptor
{
	return fskWriteDescriptor ;
}

- (int)controlWriteDescriptor
{
	return controlWriteDescriptor ;
}

- (int)pttWriteDescriptor
{
	return pttWriteDescriptor ;
}

- (void)setPTTState:(Boolean)state
{	
	write( pttWriteDescriptor, (state) ? "1" : "0", 1 ) ;
}

- (void)useDigitalModeForFSK:(Boolean)state 
{
	useDigitalModeForFSK = state ;
}

- (void)setKeyerMode:(int)mode
{
	unsigned char control[] = { 0x0f, 0x02, 0x00, 0x8f } ;
	
	control[2] = mode ;
	if ( controlWriteDescriptor > 0 ) write( controlWriteDescriptor, control, 4 ) ;
}

- (void)selectForFSK
{
	unsigned char control[] = { 0x0a, 0x03, 0x8a } ;

	if ( useDigitalModeForFSK && ( [ self isMicroKeyer ] || [ self isMicroKeyerII ] || [ self isDigiKeyer ] || [ self isDigiKeyerII ] ) ) {
		write( controlWriteDescriptor, control, 3 ) ;
	}
}

- (Boolean)hasQCW
{
	return [ self isDigiKeyerII ] ; 
}

@end
