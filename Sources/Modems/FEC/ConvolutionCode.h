//
//  ConvolutionCode.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/2/07.

#ifndef _CONVOLUTIONCODE_H_
	#define _CONVOLUTIONCODE_H_

	#import <Cocoa/Cocoa.h>
	
	#define	kMaxPathMask	0xff
	#define kMaxPath		( kMaxPathMask+1 )
	
	typedef unsigned long long Unsigned64 ;				//  assume long long is at least 64 bits
	
	typedef struct {
		float pathMetric ;
		Unsigned64 pathBits ;
	} TrellisState ;
	
	@interface ConvolutionCode : NSObject {
		int generator[2] ;
		char *outputDibitTable ;
		unsigned int stateBits ;
		unsigned int states ;
		unsigned int mask ;
		//  path info for each state
		unsigned int trellisCycle ;
		TrellisState *trellisState0, *trellisState1 ;
		Unsigned64 lagMask ;
		float damping ;
	}

	- (id)initWithConstraintLength:(int)n generator:(int)a generator:(int)b ;
	- (void)resetTrellis ;
	- (void)setTrellisDepth:(int)depth ;
	
	- (int)encodeIntoDibit:(int)bit ;
	- (int)decodeMSB:(float)firstBit LSB:(float)secondBit ;
	
	@end

#endif
