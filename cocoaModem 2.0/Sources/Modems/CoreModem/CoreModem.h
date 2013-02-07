/*
 *  CoreModem.h
 *  CoreModem
 *
 *  Created by Kok Chen on 10/24/05.
 *
 */

#ifndef _COREMODEM_H_
	#define _COREMODEM_H_
	
	#import "CMFSKDemodulator.h"
	#import "CMFSKMatchedFilter.h"
	
	#import "CMFilterBank.h"
	#import "CMBandpassFilter.h"

	@interface CoreModem : NSObject {
	}
	@end
	
	//  static sin/cos tables
	extern float *mssin, *lssin, *mscos, *lscos ;

#endif
