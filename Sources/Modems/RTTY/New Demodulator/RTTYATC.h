//
//  RTTYATC.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/27/07.

#ifndef _RTTYATC_H_
	#define _RTTYATC_H_

	#include "CMATC.h"
	#include "CMFIR.h"
	
	#define	ATCRINGMASK		0x1fff
	#define ATCRINGSIZE		( ATCRINGMASK+1 )
	
	typedef struct {
		CMATCPair data[ATCRINGSIZE*2] ;		// double ring buffer of approx 6 seconds
		int samplesSinceSpace ; 
		long long lastSpace ;
	} CMATCRing ;

	//  ringState
	#define	HASSYNC			0x1
	#define	HASSPACE		0x2
	
	@interface RTTYATC : CMATC {
		float characterPeriod ;
		int fixedCharacterAdvance ;
		int firstStopBit ;
		
		CMATCRing ring[3] ;					// contains same data as agc[3], but is a 8192 long ring buffer
		long long producer ;
		long long consumer ;
		long long decodeConsumer ;
		int ringState ;
	}

	@end

#endif
