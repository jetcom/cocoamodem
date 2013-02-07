//
//  Transceiver.m
//  cocoaModem
//
//  Created by Kok Chen on 9/4/05.
	#include "Copyright.h"
//

#import "Transceiver.h"
#include "Modem.h"
#include "Module.h"
#include "modemTypes.h"

@implementation Transceiver

//  Implements AppleScript "transceiver" class

- (id)initWithModem:(Modem*)parent index:(int)inIndex
{
	self = [ super init ] ;
	if ( self ) {
		index = inIndex ;
		modem = parent ;
		transmitter = [ [ Module alloc ] initWithTransceiver:self receiver:NO index:index ] ;
		receiver = [ [ Module alloc ] initWithTransceiver:self receiver:YES index:index ] ;
	}
	return self ;
}

- (Modem*)modem
{
	return modem ;
}

- (Module*)transmitter
{
	return transmitter ;
}

- (Module*)receiver
{
	return receiver ;
}

//  deprecated
- (NSString*)getStream
{
	return [ receiver stream ] ;
}

// deprecated
- (void)sendStream:(char*)text
{
	[ transmitter setCStream:text ] ;
}

- (Boolean)enable
{
	return [ modem checkEnable:self ] ;
}

- (void)setEnable:(Boolean)sense
{
	[ modem setEnable:self to:sense ] ;
}

- (int)state
{
	return ( [ modem currentTransmitState ] ) ? ModemTransmit : ModemReceive ;
}

- (void)setState:(int)code
{
	Boolean transmitState ;
	
	transmitState = [ modem currentTransmitState ] ;
	//  check if we are already in the correct states
	if ( code == ModemTransmit && transmitState == YES ) return ;
	if ( code != ModemTransmit && transmitState != YES ) return ;
	[ modem selectTransceiver:self andChangeTransmitStateTo:( code == ModemTransmit ) ] ;
}

//  get modulation (4 letter code)
- (int)modulation
{
	return [ modem modulationCodeFor:self ] ;
}

- (void)setModulation:(int)code
{
	[ modem setModulationCodeFor:self to:code ] ;
}
	
@end
