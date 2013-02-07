//
//  MooreDecoder.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/6/06.

#ifndef _MOOREDECODER_H_
	#define _MOOREDECODER_H_

	#import "CMBaudotDecoder.h"

	@class SITORRxControl ;
	
	@interface MooreDecoder : CMBaudotDecoder {
		unsigned char bitRegister[6], hammingMapped[128] ;		// 7 bit values
		int weight[256] ;
		float syncProbability[14] ;
		int cycle ;
		float squelch ;
		
		int decodeState, err, indicatorDelay ;
		Boolean sync ;
		Boolean errorPrint ;
		
		SITORRxControl *control;
	}

	- (void)setSquelch:(float)value ;
	- (void)setControl:(SITORRxControl*)ctrl ;
	- (void)setErrorPrint:(Boolean)state ;
	
	@end

#endif
