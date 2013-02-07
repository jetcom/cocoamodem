//
//  BonjourService.m
//
//  Created by Kok Chen on 11/19/07.
//  Copyright 2007 Kok Chen, W7AY. All rights reserved.
//

#import "../../Local Headers/BonjourService.h"


//  BonjourService sets up an NSNetServiceBrowser to watch for AUNetSend SERVICETYPE ("_apple-ausend._tcp.") sockets.
//
//  BonjourService accepts a list of service names to monitor.  A client makes a request to BonjourService using the 
//	-registerService: method.  BonjourService will return a BonjourSocket for each service name is registered.
//
//  Whenever BonjourService detects a connection, it will check the connection against the list that it was asked to monitor.
//	If the socket is one of the BonjourSocket it is monitoring, BonjourService passes the Unix sockaddr to the target BonjourSocket.
//
//  Each BonjourSocket can accept a delegate (different instances of BonjourSocket can have its own delegate).  Whenever a 
//  BonjourSocket receives sockaddr indicating a new connection, it can call the delegate with the -bonjourNetReceiveConnect: method.
//
//  When BonjourService detects a disconnect on one of the sockets it is monitoring, it passes the disconnection information
//	to the BonjourSocket and in turn BonjourSocket can inform its delegate.
//
//	Note that each BonjourSocket has its own delegate.


@implementation BonjourService

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		browser = nil ;
		sockets = [ [ NSMutableArray alloc ] initWithCapacity:8 ] ;
	}
	return self ;
}

- (void)dealloc
{
	if ( browser ) {
		[ browser stop ] ;
		[ browser release ] ;
	}
	[ super dealloc ] ;
}

- (void)findServices
{
	if ( browser ) [ browser release ] ;	
	
	browser = [ [ NSNetServiceBrowser alloc ] init ] ;
	[ browser setDelegate:self ] ;
	[ browser searchForServicesOfType:SERVICETYPE inDomain:@"" ] ;
}

- (BonjourSocket*)registerService:(NSString*)serviceName
{
	BonjourSocket *socket ;
	
	socket = [ [ BonjourSocket alloc ] initWithName:serviceName ] ;
	if ( socket == nil ) return nil ;
	[ sockets addObject:socket ] ;
	[ self findServices ] ;			// rescan for services
	return socket ;
}

- (void)removeService:(NSString*)serviceName
{
	BonjourSocket *socket ;
	int i, n ;
	
	n = [ sockets count ] ;
	for ( i = 0; i < n; i++ ) {
		socket = [ sockets objectAtIndex:i ] ;
		if ( [ [ socket serviceName ] isEqualToString:serviceName ] ) {
			[ sockets removeObjectAtIndex:i ] ;
			[ socket release ] ;
			[ self findServices ] ;		//  rescan for sevices
			return ;
		}
	}
}

//  delegate for NSNetServiceBrowser that was created from -findServices:
//  NSNetServiceBrowser calls this for each service it finds.
//  In turn, this method asks for address resolution from NSNetService, which calls -netServiceDidResolveAddress:
- (void)netServiceBrowser:(NSNetServiceBrowser*)inBrowser didFindService:(NSNetService*)service moreComing:(BOOL)moreComing 
{
	//  found service
	//  now resolve address for this server, it should either call -netServiceDidResolveAddress or -didNotResolve below
	[ service retain ] ;
	[ service setDelegate:self ] ;
	[ service resolveWithTimeout:3.0 ] ;		//  resolve address to get address and port
}

- (void)netServiceBrowser:(NSNetServiceBrowser*)netServiceBrowser didRemoveService:(NSNetService*)service moreComing:(BOOL)moreServicesComing
{
	[ self findServices ] ;			//  update service
}

//  Catch address resolutions for NSNetService resolveWithTimeout messages in -netServiceBrowser:didFindService
//  Creates a NetAudioDevice for each device that is found.
//  When the last service is reached, -netServiceDidResolve address signals the main thread by unlocking the lock.
- (void)netServiceDidResolveAddress:(NSNetService*)service 
{
	NSString *serviceName ;
	NSArray *addresses ;
	NSData *data ;
	BonjourSocket *socket ;
	struct sockaddr_in *addr ;
	int i, skts, count, index ;
	
	serviceName = [ service name ] ;
	addresses = [ service addresses ] ;
	count = [ addresses count ] ;
	for ( index = 0; index < count; index++ ) {
		//  find an address among the address listed		
		data = [ addresses objectAtIndex:index ] ;
		addr = (struct sockaddr_in*)[ data bytes ] ;
		if ( addr->sin_family == AF_INET ) {
			// found an IPv4 address, check name against list in sockets array
			skts = [ sockets count ] ;
			for ( i = 0; i < skts; i++ ) {
				socket = [ sockets objectAtIndex:i ] ;
				if ( [ serviceName isEqualToString:[ socket serviceName ] ] ) {
					//  found it... set up address
					[ socket connectSocketAddr:addr ] ;
					[ service release ] ;
					return ;
				}
			}
		}
	}
	//  did not find any IPv4 address	
	[ service release ] ;	
}

- (void)netService:(NSNetService*)service didNotResolve:(NSDictionary*)error 
{
	[ browser stop ] ;
	[ browser release ] ;
	[ service release ] ;
}

@end
