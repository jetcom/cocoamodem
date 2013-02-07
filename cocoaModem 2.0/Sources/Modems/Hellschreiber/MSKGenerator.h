//
//  MSKGenerator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/21/06.

#ifndef _MSKGENERATOR_H_
	#define _MSKGENERATOR_H_

	#import <Cocoa/Cocoa.h>
	#import "CMNCO.h"


	@interface MSKGenerator : CMNCO {
		Boolean needNewBit ;
		float baudRate ;
		double baudDelta ;
		int cycle ;
	}
	
	- (void)setBaudRate:(float)rate ;
	- (Boolean)needNewBit ;

	- (Boolean)advanceBitSample ;
	- (float)sinForModulation ;
	- (float)cosForModulation ;

	@end

#endif
