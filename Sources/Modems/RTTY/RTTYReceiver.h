//
//  RTTYReceiver.h
//  cocoaModem
//
//  Created by Kok Chen on 1/17/05.
//

#ifndef _RTTYRECEIVER_H_
	#define _RTTYRECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "CoreModem.h"
	
	enum LockCondition {
		kNoData,
		kHasData
	} ;
	
	@class Application ;
	@class ExchangeView ;
	@class Modem ;
	@class ModemConfig ;
	@class Module ;
	@class RTTYAuralMonitor ;
	@class RTTYRxControl ;

	@interface RTTYReceiver : CMTappedPipe {
		int uniqueID ;
		Application *app ;		//  v0.96d
		
		//  connections (views, buttons, sliders)
		ExchangeView *receiveView ;
		NSMatrix *bandwidthMatrix ;
		NSMatrix *demodulatorModeMatrix ;
		NSSlider *squelch ;
		//  USOS
		Boolean usos ;

		//  AudioPipes (DSP stages for RTTY)
		CMFilterBank *matchedFilter ;
		CMFilterBank *bandpassFilter ;		
		CMBandpassFilter *bpf[5] ;
		CMFSKDemodulator *demodulator ;
		float *clickBuffer[512] ;
		int clickBufferProducer, clickBufferConsumer ;
		NSLock *clickBufferLock ;
		NSConditionLock *newData ;
		CMDataStream cmData ;

		Module *appleScript ;
		
		CMTonePair currentTonePair ;
		Boolean enabled ;
		Boolean slashZero ;
		Boolean sidebandState ;
		
		//  v0.78
		RTTYAuralMonitor *rttyAuralMonitor ;
		
		//  v0.88
		Boolean clickBufferActive ;
	}

	- (id)initReceiver:(int)index modem:(Modem*)modem ;
	- (id)initSuperReceiver:(int)index ;
	- (void)setupReceiverChain:(ModemConfig*)config ;
	- (void)updateInterface ;
	
	- (void)setPrintControl:(Boolean)state ;		//  v0.68
	
	// set up connections
	- (void)setBandwidthMatrix:(NSMatrix*)matrix ;
	- (void)setDemodulatorModeMatrix:(NSMatrix*)matrix ;
	- (void)setReceiveView:(ExchangeView*)view ;
	
	- (CMFSKDemodulator*)demodulator ;
	
	- (void)enableReceiver:(Boolean)state ;
	- (Boolean)enabled ;
	- (void)registerModule:(Module*)module ;
	
	- (void)createClickBuffer ;
	- (void)clicked:(float)history ;
	
	// state settings
	- (void)setSlashZero:(Boolean)state ;
	- (void)setUSOS:(Boolean)state ;
	- (void)setBell:(Boolean)state ;
	- (void)selectBandwidth:(int)index ;
	- (void)selectDemodulator:(int)index ;
	- (void)forceLTRS ;
	
	//  v0.83
	- (void)setFilterCutoffs:(CMTonePair*)tonepair ;
	
	//  v0.89
	- (void)clearClickBuffer ;
	
	//  pipes
	- (CMTappedPipe*)baudotPipe ;
	- (CMTappedPipe*)atcPipe ;
	- (CMTappedPipe*)demodBufferPipe ;
	- (CMTappedPipe*)bpfBufferPipe ;
	
	//  squelch
	- (void)setSquelch:(NSSlider*)squelch ; 
	- (void)setSquelchValue:(float)value ;
	- (void)newSquelchValue:(float)value ;
	- (float)squelchValue ;
	
	//  demodulator parameters
	- (void)rxTonePairChanged:(RTTYRxControl*)control ;
	
	//	v0.78 AuralMonitor
	- (RTTYAuralMonitor*)rttyAuralMonitor ;
	- (void)makeReceiverActive:(Boolean)state ;
	
	- (void)setIgnoreNewline:(Boolean)state ;
	
	@end

#endif
