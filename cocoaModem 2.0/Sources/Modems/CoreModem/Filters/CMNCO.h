//
//  CMNCO.h
//  CoreModem
//
//  Created by Kok Chen on 10/28/05.
//

#ifndef _CMNCO_H_
	#define _CMNCO_H_

	#import <Foundation/Foundation.h>

	@interface CMNCO : NSObject {
		// DDAs at the default sampling rate
		double theta ;
		double bitTheta ;
		double current ;
		double scale ;
		double duration ;
		int modulate ;
		
		NSLock *lock ;
		int producer, consumer ;
	}

	- (void)setOutputScale:(float)value ;
	
	- (float)sin:(double)delta ;
	- (float)cos:(double)delta ;
	- (void)sin:(double*)sine cos:(double*)cosine delta:(double)delta ;
	- (Boolean)modulation:(double)delta ;
	
	@end
	
	//  10-bit half resolution tables
	#define kPeriod 262144.0
	#define kMask   0x3ff 
	#define kBits   10

#endif
