//
//  CMPCO.h
//  CoreModem
//
//  Created by Kok Chen on 11/02/05.


#ifndef _CMPCO_H_
	#define _CMPCO_H_

	#import <Foundation/Foundation.h>
	#include "CMNCO.h"
	#include "CoreModemTypes.h"

	@interface CMPCO : CMNCO {
		double carrier ;
		float frequency ;
		id delegate ;
	}
	
	- (void)setCarrier:(float)freq ;
	- (float)frequency ;
	
	- (double)nextSample ;
	- (CMAnalyticPair)nextVCOPair ;
	- (CMAnalyticPair)nextVCOMixedPair:(float)v ;
	- (void)tune:(float)freq ;
	- (void)tune:(float)freq phase:(float)theta ;
	- (void)adjustPhase:(float)theta ;
	
	//  delegates
	- (id)delegate ;
	- (void)setDelegate:(id)inDelegate ;
	- (void)vcoChangedTo:(float)vcoFreq ;

	@end

#endif
