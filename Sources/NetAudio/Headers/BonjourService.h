//
//  BonjourService.h
//
//  Created by Kok Chen on 11/19/07.

	#import <Cocoa/Cocoa.h>
	#import "BonjourSocket.h"
 
	@interface BonjourService : NSObject {
		NSNetServiceBrowser *browser ;
		NSMutableArray *sockets ;
	}

	- (BonjourSocket*)registerService:(NSString*)serviceName ;
	- (void)removeService:(NSString*)serviceName ;
	
	#define SERVICETYPE				@"_apple-ausend._tcp."
	
	@end
