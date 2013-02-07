//
//  AMDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/18/07.


#ifndef _AMDEMODULATOR_H_
	#define _AMDEMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CMFIR.h"
	#include "CMPCO.h"
	#include "ParametricEqualizer.h"
	
	@class CMPipe ;
	@class SynchAM ;

	@interface AMDemodulator : NSObject {
		SynchAM *client ;
		CMFIR *carrierFilter, *sidebandFilter, *iFilter, *qFilter, *iAudioFilter, *qAudioFilter, *outputFilter ;
		CMPCO *carrierVco, *downshiftVco, *upshiftVco ;
		int cyclesSinceAdjust ;
		float fc, fd, fshift, fl, fh ;
		float volume ;
		float excessDelta ;
		//  ParametricEqualizer 
		ParametricEqualizer *equalizer ;
		CMFIR *eqFilter ;
		Boolean equalizerEnable ;
	}

	- (void)setClient:(SynchAM*)owner ;
	- (void)importData:(CMPipe*)pipe ;
	
	- (float)carrier ;
	- (void)setTrack:(float)carrier low:(float)low high:(float)high ;
	- (void)setVolume:(float)value ;
	
	- (void)setEqualizer:(int)freq value:(float)v ;
	- (void)setEqualizerEnable:(Boolean)state ;
	
	@end

#endif
