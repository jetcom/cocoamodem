//
//  SynchAM.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/07.

#ifndef _SYNCHAM_H_
	#define _SYNCHAM_H_

	#include "Modem.h"

	@class AMDemodulator ;
    @class VUMeter ;

	@interface SynchAM : Modem {
		IBOutlet id waterfall ;
		IBOutlet id inputAttenuator ;
		IBOutlet id vuMeter ;	
		
		IBOutlet id volumeSlider ;
		IBOutlet id muteCheckbox ;

		IBOutlet id lockRangeSlider ;
		IBOutlet id lockOffsetSlider ;
		IBOutlet id lockLight ;	
		int lockState ;
		
		IBOutlet id equalizerCheckbox ;
		IBOutlet id eq300Slider ;
		IBOutlet id eq600Slider ;
		IBOutlet id eq1200Slider ;
		IBOutlet id eq2400Slider ;
		IBOutlet id eq4800Slider ;

		//  demodulator
		AMDemodulator *demodulator ;
		//  output
		float outputScale ;			// stepped attenuator in aural config
	}

	- (int)setLock:(float)delta freq:(float)f ;
	- (void)setOutput:(float*)array samples:(int)n ;
	- (void)setOutputScale:(float)v ;
	
	- (VUMeter*)vuMeter ;
	- (void)setWaterfallOffset:(float)freq sideband:(int)sideband ;

	@end

#endif
