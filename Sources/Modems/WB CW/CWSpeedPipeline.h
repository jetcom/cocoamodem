//
//  CWSpeedPipeline.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/27/06.

#ifndef _CWSPEEDPIPELINE_H_
	#define _CWSPEEDPIPELINE_H_

	#import "CWPipeline.h"


	@interface CWSpeedPipeline : CWPipeline {
		CMFFT *spectrum ; 
		
		ElementType intervalHistory[64] ;
		int intervalHistoryIndex ;

		float keyHistogram[1024] ;
		float unkeyHistogram[1024] ;
		
		float speedEstimate[5] ;
	}
	
	- (MorseTiming)estimateMorseTiming ;
	- (float*)histogram ;
	
	@end

#endif
