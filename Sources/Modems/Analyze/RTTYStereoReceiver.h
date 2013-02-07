//
//  RTTYStereoReceiver.h
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
//

#ifndef _RTTYSTEREORECEIVER_H_
	#define _RTTYSTEREORECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#import "CMFSKMixer.h"
	#import "RTTYReceiver.h"
	#import "AnalyzeScope.h"
	#import "ChannelSelector.h"
	#import "CMBaudotDecoder.h"		//  CoreModem private

	@class AnalyzeConfig ;
	@class AnalyzeScope ;
	@class ModemSource ;
	@class MultiStereoATC ;
	@class StereoRefATCBuffer ;

	@interface RTTYStereoReceiver : RTTYReceiver {
		ChannelSelector *refPipe ;
		ChannelSelector *dutPipe ;
		CMTappedPipe *refFilter ;
		CMTappedPipe *dutFilter[5], *selectedDUTFilter ;
		
		CMRTTYMatchedFilter *demod[5] ;		// old receiver
		
		CMFSKMixer *refMixer, *mixer ;
		CMRTTYMatchedFilter *refDemod ;
		StereoRefATCBuffer *refATCBuffer ;
		MultiStereoATC *stereoATC ;
		AnalyzeScope *scope ;
		CMBaudotDecoder *decoder ;		// move to CoreModem
		
		CMTappedPipe *bpfBuffer ;
		CMTappedPipe *demodBuffer ;
		ModemSource *modemSource ;
		
		int reference ;
		int dut ;
	}
	
	- (void)setupReceiverChain:(ModemSource*)source config:(AnalyzeConfig*)config ;
	- (void)setReference:(int)refCh dut:(int)dutCh ;
	
	- (ChannelSelector*)refPipe ;
	- (void)setScope:(AnalyzeScope*)scope ;
	- (void)setFileRepeat:(Boolean)state ;

	@end

#endif
