//
//  SITORBitSync.h
//  CoreModem 2.0
//
//  Created by Kok Chen on 2/7/06

#ifndef _SITORBITSYNC_H_
	#define _CMATC_H_
	
	#import <Cocoa/Cocoa.h>
	#import "CoreModemTypes.h"
	#import "CMTappedPipe.h"
	#import "CMFIR.h"
	#import "MooreDecoder.h"
	
	typedef struct {
		float mark ;
		float space ;
	} ATCPair ;

	typedef struct {
		ATCPair data[768] ;
		float attack, decay ;
		float markAGC, spaceAGC ;
	} ATCStream ;

	
	@interface SITORBitSync : CMTappedPipe {
		//  generate bitsynced data stream
		CMDataStream bitStream ;
		float syncedData[256] ;
		float previousClockValue ;
		Boolean invert ;

		ATCStream input ;		//  input data
		ATCStream postAGC ;		//  input data that has gone through AGC
		
		float squelch ;
		
		//  ATC AGC
		float agcAttack ;
		float agcDecay ;
		
		CMFIR *bitClockFilter ;
		MooreDecoder *decoder ;
		
		//  scope tap
		CMPipe *atcBuffer ;
		
		// RTTY tests
		int rttyTestIndex, rttyTestCycles, rttyTestReject ;
		float rttyTestAccum[256] ;
	}

	- (void)setBitSamplingFromBaudRate:(float)baudrate ;
	- (CMPipe*)atcWaveformBuffer ;
	
	- (void)setMooreDecoder:(MooreDecoder*)decode ;
	- (void)setEqualize:(int)mode ; 
	- (void)setInvert:(Boolean)isInvert ;
	- (void)setSquelch:(float)value ;
	
	@end
	
#endif
