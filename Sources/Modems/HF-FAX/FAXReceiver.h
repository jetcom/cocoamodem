//
//  FAXReceiver.h
//  cocoaModem
//
//  Created by Kok Chen on 3/6/2006.
//

#ifndef _FAXRECEIVER_H_
	#define _FAXRECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#import "FAXDisplay.h"
	#import "DataPipe.h"
	#import "CMToneReceiver.h"
	#import "CMFIR.h"
	#import "CMFFT.h"

	@class Modem ;
	
	@interface FAXReceiver : CMToneReceiver {
	
		Modem *client ;
		FAXDisplay *view ;
				
		//  agc
		float agc ;
		
		//  decimating filter
		CMFIR *iFilter, *qFilter ;
		CMFIR *inputBandpassFilter, *limiterBandpassFilter ;
		//  filter bands
		CMFIR *iFilterN[3], *qFilterN[3] ;
		CMFIR *inputBandpassFilterN[3], *limiterBandpassFilterN[3] ;
		//  limiter
		float bandpassFilteredInput[512], limited[512] ;
		//  mixer output (before IF filter)
		float iMixer[512], qMixer[512] ;
		//  IF filtered buffer
		float iOutput[512], qOutput[512] ;
				
		float iReg[3], qReg[3], iDelay[3], qDelay[3], mag ;
		
		DataPipe *datapipe ;
	}
	
	- (id)initFromModem:(Modem*)modem ;
	- (void)changeBandwidthTo:(int)index ;

	@end

#endif
