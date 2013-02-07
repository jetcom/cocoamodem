//
//  RTTYDecoder.h
//  cocoaModem
//
//  Created by Kok Chen on 3/11/05.
//


#ifndef _RTTYDECODER_H_
	#define _RTTYDECODER_H_

	#import <Cocoa/Cocoa.h>
	#include "RTTYRegister.h"
	#include "CMATCTypes.h"

	typedef struct {
		Boolean frameSync ;
		int offset ;
		int character ;
		float equalization ;
		float confidence ;
		long tick ;
		long syncTick ;
	} RTTYByte ;
	
	@interface RTTYDecoder : NSObject {
		RTTYRegister *mark ;
		RTTYRegister *space ;
		Boolean block ;
		float period ;
	}

	- (id)initWithBitPeriod:(float)bitPeriod ;
	
	- (void)addSamples:(int)size mark:(float*)markArray space:(float*)spaceArray ;
	- (Boolean)symbolSync ;
	- (void)bestSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)sync ;
	- (void)bestAsyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)sync ;
	- (void)checkSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check ;
	- (void)validateSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check ;
	- (float)likelihoodWithMarkOffset:(int)m spaceOffset:(int)s ;
	
	- (void)findFrameSyncForMarkOffset:(int)m spaceOffset:(int)s sync:(RTTYByte*)check ;
	
	- (RTTYRegister*)mark ;
	- (RTTYRegister*)space ;
	- (void)dumpData ;
	
	//  read data from registers
	- (float)markAtBit:(int)bit offset:(int)offset ;
	- (float)spaceAtBit:(int)bit offset:(int)offset ;
	- (void)advance ;
	- (void)getBuffer:(CMATCPair*)pair markOffset:(int)markOffset spaceOffset:(int)spaceOffset ;
	
	- (void)checkSync:(float*)g length:(int)n ;
	
	@end

#endif
