//
//  CWDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/2/06.


#ifndef _CWDEMODULATOR_H_
	#define _CWDEMODULATOR_H_

	#import "CoreModem.h"

	@class CWReceiver ;
	
	@interface CWDemodulator : CMFSKDemodulator {
	}

	- (id)initFromReceiver:(CWReceiver*)cwReceiver ;
	- (void)setCWBandwidth:(float)bandwidth ;
	- (void)setLatency:(int)value ;
	- (void)changeCodeSpeedTo:(int)speed ;
	- (void)changeSquelchTo:(float)squelch fastQSB:(float)fast slowQSB:(float)slow ;
	- (void)newClick:(float)delta ;
	
	@end

#endif
