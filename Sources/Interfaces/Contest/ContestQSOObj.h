//
//  ContestQSOObj.h
//  cocoaModem
//
//  Created by Kok Chen on 12/24/04.
//

#ifndef _CONTESTQSOOBJ_H_
	#define _CONTESTQSOOBJ_H_

	#import <Cocoa/Cocoa.h>
	#include "Contest.h"

	@interface ContestQSOObj : NSObject {
		ContestQSO *qso ;
	}
	
	- (id)initWith:(ContestQSO*)q ;
	- (ContestQSO*)ptr ;
	
	- (int)qsoNumber ;
	- (NSString*)callsign ;
	- (int)band ;
	- (DateTime*)time ;
	- (NSString*)exchange ;
	- (NSString*)mode ;
	- (NSString*)rst ;
	
	- (void)setBand:(int)value ;
	- (void)setQSOMode:(char*)m ;
	- (void)setRST:(NSString*)rst ;
	- (void)setExchange:(NSString*)exch ;
	
	//  sorts
	- (NSComparisonResult)sortByNumber:(ContestQSOObj*)other ;
	- (NSComparisonResult)reverseByNumber:(ContestQSOObj*)other ;
	- (NSComparisonResult)sortByCallsign:(ContestQSOObj*)other ;
	- (NSComparisonResult)reverseByCallsign:(ContestQSOObj*)other ;
	- (NSComparisonResult)sortByBand:(ContestQSOObj*)other ;
	- (NSComparisonResult)reverseByBand:(ContestQSOObj*)other ;

	@end

#endif
