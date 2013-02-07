//
//  CMToneReceiver.h
//  CoreModem
//
//  Created by Kok Chen on 11/03/05
//	Ported from cocoaModem, original file dated 7/29/05.


#ifndef _CMTONERECEIVER_H_
	#define _CMTONERECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#include "CMPCO.h"
	#include "CMTappedPipe.h"
	#include "CMFIR.h"

	@interface CMToneReceiver : CMTappedPipe {

		Boolean receiverEnabled ;
		Boolean frequencyLocked ;
		Boolean lockProcessStarted ;
		int acquire ;						//  afc acquisition
		
		CMPCO *vco ;
		float receiveFrequency ;
		
		float *goertzelWindow ;
	}
	
	- (float)goertzel:(float*)x freq:(float)center ;
	- (float)goertzel:(float*)x imag:(float*)y freq:(float)center ;

	- (void)enableReceiver:(Boolean)state ;
	- (Boolean)isEnabled ;
	
	- (float)receiveFrequency ;
	- (void)setReceiveFrequency:(float)tone ;
	
	- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall ;

	@end

#endif
