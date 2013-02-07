//
//  DataPipe.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/3/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DataPipe : NSObject {
	NSConditionLock *lock ;	
	int capacity ;
	char *data ;	
	int bytes ;	
	Boolean eof ;
	//  write retry
	int timeout ;
	float writeRetryTime ;
}

- (id)initWithCapacity:(int)bytes ;

- (int)write:(void*)data length:(int)bytes ;
- (Boolean)eof ;
- (void)setEOF ;

- (int)readAvailableData:(void*)data max:(int)maxBytes ;
- (int)readData:(void*)data length:(int)bytes ;

@end
