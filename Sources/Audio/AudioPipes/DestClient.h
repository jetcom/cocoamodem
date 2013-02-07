//
//  DestClient.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/1/06.

#ifndef _DESTCLIENT_H_
	#define	_DESTCLIENT_H_
	
	#import <Cocoa/Cocoa.h>
	#import "CoreFilter.h"

	@class ModemDest ;
	
	@interface DestClient : CMTappedPipe {

	}
	
	- (void)setOutputScale:(float)value ;
	
	//  ResamplingPipe callback
	- (int)needData:(float*)outbuf samples:(int)n ;


	@end

#endif
