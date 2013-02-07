//
//  PTTDevice.h
//  cocoaPTT
//
//  Created by Kok Chen on 4/4/06.

#ifndef _PTTDEVICE_H_
	#define _PTTDEVICE_H_

	#import <Cocoa/Cocoa.h>
	#include <termios.h>

	@interface PTTDevice : NSObject {
		int fd ;
		struct termios originalTTYAttrs ;
		NSString *name ;
		
		Boolean activeHigh ;
		Boolean useRTS ;
	}

	- (id)initWithDevice:(NSString*)path name:(NSString*)name allowRead:(Boolean)allowRead ;

	- (NSString*)name ;
	- (Boolean)setKey:(int)useRTS active:(Boolean)activeHigh ;
	- (Boolean)setUnkey:(int)useRTS active:(Boolean)activeHigh ;
	
	- (void)close ;

	@end

#endif
