//
//  CWReceiver.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/2/06.

#ifndef _CWRECEIVER_H_
#define _CWRECEIVER_H_

	#import "RTTYReceiver.h"
	#import "CMPCO.h"
	
	@class CWRxControl ;
	@class CWAuralFilter ;
	@class CWMonitor ;

	@interface CWReceiver : RTTYReceiver {
		int buffer ;
		CMFIR *sidetoneFilter ;
		float cwBandwidth ;
		float cwFrequency ;
		float sidetoneFrequency ;
		CMPCO *vco ;
		CWRxControl *cwRxControl ;
		CWAuralFilter *aural ;
		CWMonitor *monitor ;
	}
	
	- (void)received:(float*)inphase quadrature:(float*)quadrature wide:(float*)wide samples:(int)n ;
	- (void)needSidetone:(float*)outbuf inphase:(float*)inph quadrature:(float*)quad wide:(float*)wide samples:(int)n wide:(Boolean)wide ;
	- (void)setMonitorEnable:(Boolean)state ;

	- (void)setupReceiverChain:(ModemConfig*)config monitor:(CWMonitor*)mon ;		//  v0.78
	
	- (void)changingStateTo:(Boolean)state ;
	- (void)changeCodeSpeedTo:(int)speed ;
	- (void)changeSquelchTo:(float)squelch fastQSB:(float)fast slowQSB:(float)slow ;
	
	- (void)updateFilters ;
	- (void)setCWBandwidth:(float)bandwidth ;
	- (void)setLatency:(int)latency ;
	- (void)setSidetoneFrequency:(float)freq ;
	- (void)setCWSpeed:(float)wpm limited:(Boolean)limited ;
	- (void)newClick:(float)delta ;
	
	@end

#endif
