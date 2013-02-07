//
//  UTC.h
//  cocoaModem
//
//  Created by Kok Chen on 11/28/04.
//

#ifndef _UTC_H_
	#define _UTC_H_
	
	#import <Cocoa/Cocoa.h>
	#include <time.h>


	@interface UTC : NSObject {
		struct tm gmttime ;
		time_t t ;
	}

	- (struct tm*)setTime ;
	- (struct tm*)utc ;
	
	@end

#endif
