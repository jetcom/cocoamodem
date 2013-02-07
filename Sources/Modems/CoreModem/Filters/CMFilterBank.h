//
//  CMFilterBank.h
//  CoreModem
//
//  Created by Kok Chen on 10/25/05.
//

#ifndef _CMFILTERBANK_H_
	#define _CMFILTERBANK_H_

	#import <Cocoa/Cocoa.h>
	#include "CMTappedPipe.h"

	@interface CMFilterBank : CMTappedPipe {
		CMPipe *filter[32] ;
		CMPipe *selectedFilter ;
		int filters ;
	}

	- (int)filters ;
	- (void)installFilter:(CMPipe*)f ;
	- (void)selectFilter:(int)index ;

	@end

#endif
