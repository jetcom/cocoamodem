//
//  MFSKVaricode.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/30/07.


#import <Cocoa/Cocoa.h>
#import "CMVaricode.h"


@interface MFSKVaricode : CMVaricode {
	int past ;
}

- (const char*)encode:(int)ascii ;
- (int)decode:(int)n ;
- (void)useCode:(char**)code ;

@end
