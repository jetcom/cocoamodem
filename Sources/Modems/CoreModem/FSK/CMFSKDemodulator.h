//
//  CMFSKDemodulator.h
//  CoreModem
//
//  Created by Kok Chen on 10/24/05.
//

#ifndef _CMFSKDEMODULATOR_H_
	#define _CMFSKDEMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#import "CMTappedPipe.h"
	#import "CMBandpassFilter.h"
	#import "CoreModemTypes.h"
	
	@class CMATC ;
	@class CMBaudotDecoder ;
	@class CMFSKMixer ;
	@class ModemConfig ;
	@class RTTYReceiver ;

	@interface CMFSKDemodulator : CMTappedPipe {
		id delegate ;
		CMTonePair tonePair ;
		void *pipeline ;
		RTTYReceiver *receiver ;
		//  RTTY polarity
		Boolean sidebandState ;
		Boolean isRTTY ;
	}
	
	- (id)initSuper ;
	- (id)initFromReceiver:(RTTYReceiver*)rcvr ;
	
	- (void)initPipelineStages:(CMTonePair*)pair decoder:(CMBaudotDecoder*)decoder atc:(CMPipe*)atc bandwidth:(float)bandwidth ;
	- (void)setConfig:(ModemConfig*)cfg ;
	- (void)setupDemodulatorChain ;
	- (void)makeDemodulatorActive:(Boolean)state ;
	
	- (RTTYReceiver*)receiver ;
	- (Boolean)isRTTY ;
	
	- (CMFSKMixer*)mixer ;
	
	//  for SITOR-B, AMTOR, etc
	- (void)replaceDecoderWith:(CMBaudotDecoder*)decoder ;
	
	- (void)setBitsPerCharacter:(int)bits ;
	
	//  decoded data
	- (void)setDelegate:(id)inDelegate ;
	- (id)delegate ;
	- (void)receivedCharacter:(int)c ;

	//  demodulator options
	- (void)setTonePair:(const CMTonePair*)tonepair ;
	- (void)setEqualizer:(int)index ;
	- (void)setBell:(Boolean)state ;
	- (void)setUSOS:(Boolean)state ;
	- (void)setSquelch:(float)value ;
	- (void)useBandpassFilter:(CMPipe*)bpf ;
	- (void)useMatchedFilter:(CMPipe*)mf ;
	- (void)setLTRS:(Boolean)state ;

	
	- (CMBandpassFilter*)makeFilter:(float)bandwidth ;
	- (void)updateFilter:(CMBandpassFilter*)filter ;
	
	//  scope taps
	- (CMPipe*)atcWaveform ;
	- (CMPipe*)baudotWaveform ;
	
	@end

#endif
