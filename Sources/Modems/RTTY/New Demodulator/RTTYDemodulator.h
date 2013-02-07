//
//  RTTYDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/27/07.


#ifndef _RTTYDEMODULATOR_H_
	#define _RTTYDEMODULATOR_H_

	#import "CMFSKDemodulator.h"
	#import "RTTYBaudotDecoder.h"
	#import "RTTYAuralMonitor.h"

	@interface RTTYDemodulator : CMFSKDemodulator {
		RTTYBaudotDecoder *decoder ;
		RTTYAuralMonitor *auralMonitor ;
	}

	- (void)setPrintControl:(Boolean)state ;


	@end
#endif
