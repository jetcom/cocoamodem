//
//  CWMixer.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/3/06.


#ifndef _CWMIXER_H_
	#define _CWMIXER_H_

	#import "CoreModemTypes.h"
	#import "CMPipe.h"
	#import "CMFIR.h"
	
	@class CWReceiver ;
	
	@interface CWMixer : CMPipe {
		float analyticSignal[1024] ;	// split complex signal, 512 samples
		//  local oscillators
		CMDDA mark, space ;
		CMDataStream mixerStream ;
		CMFIR *iFilter, *qFilter ;
		CMFIR *iFilter256, *qFilter256 ;
		CMFIR *iFilter512, *qFilter512 ;
		CMFIR *iFilter768, *qFilter768 ;
		CMFIR *iFilter1024, *qFilter1024 ;
		float iIF[512], qIF[512] ;
		CWReceiver *receiver ;
		// aural path?
		Boolean isAural ;
	}

	- (void)setTonePair:(const CMTonePair*)tonepair ;

	- (void)setReceiver:(CWReceiver*)cwReceiver ;
	- (void)setCWBandwidth:(float)bandwidth ;
	
	- (void)setAural:(Boolean)state ;
			
	@end

#endif
