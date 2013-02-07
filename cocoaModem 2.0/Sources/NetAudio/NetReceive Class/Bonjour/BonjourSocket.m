//
//  BonjourSocket.m
//
//  Created by Kok Chen on 11/20/07.
//  Copyright 2007 Kok Chen, W7AY. All rights reserved.
//

#import "../../Headers/BonjourSocket.h"
#import <arpa/inet.h>

@implementation BonjourSocket


//  BonjourSocket stores the service name and socket address of a Bonjour port
//	Whenever it is called with a Unix sockaddr, it can call a delegate to inform the delgate that a new connection has been made.
//  Whenever it is called to disconnect, it can call a delegate to inform the delegate that an existing connection has been terminated.
//
//  BonjourSocket is used by BonjourService.

 - (id)initWithName:(NSString *)name 
 {
	self = [ super init ] ;
	if ( self ) {
		serviceName = [ [ NSString alloc ] initWithString:name ] ;
		connected = NO ;
		delegate = nil ;
	}
	return self ;
 }
 
- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate ;
}

// delegate method
- (void)soundFileStarting:(NSString*)filename
{
	if ( delegate && [ delegate respondsToSelector:@selector(soundFileStarting:) ] ) [ delegate soundFileStarting:filename ] ;
}

//  delegate method
- (void)bonjourNetReceiveConnect:(BonjourSocket*)socket
{
	// used by delegate to receive a connection
}
 
- (void)bonjourNetReceiveDisconnect:(BonjourSocket*)socket
{
	// used by delegate to receive a disconnection
}
 
 - (void)connectSocketAddr:(struct sockaddr_in*)addr 
 {
	socketAddress = *addr ;	
	connected = YES ;	
	if ( delegate && [ delegate respondsToSelector:@selector(bonjourNetReceiveConnect:) ] ) [ delegate bonjourNetReceiveConnect:self ] ;
 }
 
 - (void)disconnect
 {
	connected = NO ;
	if ( delegate && [ delegate respondsToSelector:@selector(bonjourNetReceiveDisconnect:) ] ) [ delegate bonjourNetReceiveDisconnect:self ] ;
 }
 
 - (void)dealloc
 {
	[ serviceName release ] ;
	[ super dealloc ] ;
 }
 
 - (NSString*)serviceName
 {
	return serviceName ;
 }
 
 - (char*)ip
 {
	return inet_ntoa( socketAddress.sin_addr ) ;
 }
 
 - (int)port
 {
	return ntohs( socketAddress.sin_port ) ;
 }
 
@end
