//
//  NamedFIFO.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/15/06.

#ifndef _NAMEDFIFO_H_
	#define	_NAMEDFIFO_H_

	#import <Cocoa/Cocoa.h>


	@interface NamedFIFO : NSObject {
		char *name ;
		int inputFileDescriptor ;
		int outputFileDescriptor ;
	}
	
	- (id)initWithPipeName:(const char*)fifoName ;
	- (void)stopPipe ;
	
	- (int)inputFileDescriptor ;
	- (int)outputFileDescriptor ;
	
	@end

#endif
