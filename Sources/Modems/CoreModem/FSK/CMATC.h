//
//  CMATC.h
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Fri Jul 16 2004)
//

#ifndef _CMATC_H_
	#define _CMATC_H_
	
	#import <Cocoa/Cocoa.h>
	#include "CoreModemTypes.h"
	#include "CMTappedPipe.h"
	#include "CMATCTypes.h"
	
	@interface CMATC : CMTappedPipe {
		//  generate bitsynced data stream
		CMDataStream bitStream ;
		float syncedData[256] ;
		float bitTime ;
		int startBit ;
		int stopBit ;
		int characterAdvance ;
		int bitn ;
		//  bit position and transition position in samples (Fs/8)
		int bitPos[10] ;
		int transitionPos[10] ;
		int offset ;
		int bitsPerCharacter ;
		Boolean invert ;

		CMATCStream input ;   //  input data
		CMATCStream agc[3] ;  //  input data that has gone through AGC
		CMATCCase atcCase[6] ;
		
		// multi-ATC params
		int equalizerQuanta ;
		float squelch ;
		
		//  scope tap
		CMPipe *atcBuffer ;
	}

	- (void)setBitSamplingFromBaudRate:(float)baudrate ;
	- (CMPipe*)atcWaveformBuffer ;
	
	- (void)setBitsPerCharacter:(int)bits ;
	- (void)setEqualize:(int)mode ; 
	- (void)setInvert:(Boolean)isInvert ;
	- (void)setSquelch:(float)value ;
	
	- (void)checkForCharacter ;
	
	@end
	
#endif
