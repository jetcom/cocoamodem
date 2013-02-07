//
//  MultiStereoATC.h
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
//

#ifndef _MULTISTEREOATC_H_
	#define _MULTISTEREOATC_H_

	#import <Cocoa/Cocoa.h>
	#include "AnalyzeConfig.h"
	#include "AnalyzeScope.h"
	#include "CMATC.h"
	#include "RTTYDecoder.h"


	@interface MultiStereoATC : CMATC {
		AnalyzeConfig *config ;
		AnalyzeScope *scope ;
		
		RTTYDecoder *dut, *ref ;
		
		CMATCPair atcDummyData[256] ;

		RTTYByte refSync, dutSync ;
		int dutStartBitSearch, refStartBitSearch ;
		int dutSyncOffset, refSyncOffset ;
		int tickDiff, balance, savedByte ;
		int characterCount ;
		float estimate ;
	}

	- (void)setConfigClient:(AnalyzeConfig*)cfg ;
	- (void)importClockData:(CMTappedPipe*)pipe ;
	- (void)setScope:(AnalyzeScope*)scope ;
		
	@end

#endif
