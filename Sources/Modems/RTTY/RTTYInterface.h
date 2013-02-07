//
//  RTTYInterface.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/17/05.

#ifndef _RTTYINTERFACE_H_
	#define _RTTYINTERFACE_H_

	#import <Cocoa/Cocoa.h>
	#include "ContestInterface.h"
	#include "AYTextView.h"
	
	@class RTTYConfig ;
	@class RTTYRxControl ;
	@class Module ;
	
	@interface RTTYInterface : ContestInterface {
		IBOutlet id transmitButton ;
		IBOutlet id transmitLight ;
		IBOutlet id breakinButton ;
		
		Boolean isBreakin ;
		NSTimer *breakinTimer ;
		int breakinTimeout ;				//  number of passes in the timer where there was no character

		ExchangeView *currentRxView ;
		//  RTTY Prefs
		Boolean usos ;
		Boolean bell ;
		Boolean robust ;
		RTTYTransceiver a, b ;
				
		NSThread *thread ;
		NSTextField *microKeyerSetupField ;

		//  transmit
		int transmitChannel ;
		NSLock *transmitViewLock ;
		NSTimer *transmitBufferCheck ;
		int indexOfUntransmittedText ;
		//  macros
		int alwaysAllowMacro ;
		
		//  v0.83
		Boolean isASCIIModem ;
		int bitsPerCharacter ;
	}

	//  contest
	- (IBAction)flushContestBuffer:(id)sender ;
	- (IBAction)flushTransmitStream:(id)sender ;
	
	- (void)transmitButtonChanged ;
	- (void)afskChanged:(int)index config:(RTTYConfig*)cfg ;
	
	- (void)setRTTYPrefs:(NSMatrix*)rttyPrefs channel:(int)channel ;
	
	- (void)changeTransmitStateTo:(Boolean)state ;
	- (void)finishTransmitStateChange ;
	- (void)insertTransmittedCharacter:(int)c;
	
	- (void)flushOutput ;
	- (void)selectBandwidth:(int)index ;
	- (void)selectDemodulator:(int)index ;
	
	- (NSTextField*)microKeyerSetupField ;

	- (void)clearTuningIndicators ;

	- (void)tonePairChanged:(RTTYRxControl*)control ;
	
	- (float)frequencyFor:(Module*)module ;
	- (RTTYTransceiver*)transmittingTransceiver ;
	
	//  v0.83
	- (Boolean)isASCIIModem ;
	- (int)bitsPerCharacter ;
	
	//  v0.85
	- (int)ook:(RTTYConfig*)configr ;
	
	@end

#endif
