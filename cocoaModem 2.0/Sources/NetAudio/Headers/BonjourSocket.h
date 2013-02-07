//
//  BonjourSocket.h
//
//  Created by Kok Chen on 11/20/07.

	#import <Cocoa/Cocoa.h>
	#import <netinet/in.h>


	@interface BonjourSocket : NSObject {
		NSString *serviceName ;
		struct sockaddr_in socketAddress ;
		Boolean connected ;
		id delegate ;
	}
	
	 - (id)initWithName:(NSString *)name ;
	 - (void)connectSocketAddr:(struct sockaddr_in*)addr ;
	 - (void)disconnect ;
	
	//  properties
	- (NSString*)serviceName ;
	- (char*)ip ;
	- (int)port ;

	//  Delegates
	- (void)setDelegate:(id)inDelegate ;
	- (void)bonjourNetReceiveConnect:(BonjourSocket*)socket ;
	- (void)bonjourNetReceiveDisconnect:(BonjourSocket*)socket ;

	@end
