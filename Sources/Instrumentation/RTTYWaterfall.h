//
//  RTTYWaterfall.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/23/05.

#ifndef _RTTYWATERFALL_H_
	#define _RTTYWATERFALL_H_
	
	#import "CoreModemTypes.h"
	#import "Waterfall.h"

	@interface RTTYWaterfall : Waterfall {
		float mark[4], space[4] ;
		float markFreq[4], spaceFreq[4] ;
		float txMark, txSpace ;
		float txMarkFreq, txSpaceFreq ;
		Boolean active[4] ;
		
		float ritOffset, ritOffsetFreq ;
		Boolean ignoreSideband ;
		Boolean ignoreArrowKeys ;
		
		//  float cached markers
		float previousMark ;
	}
	
	- (void)setTonePairMarker:(const CMTonePair*)tonepair index:(int)n ;
	- (void)setTransmitTonePairMarker:(const CMTonePair*)tonepair index:(int)n ;
	- (void)setActive:(Boolean)state index:(int)n ;
	- (void)setIgnoreSideband:(Boolean)state ;
	- (void)setIgnoreArrowKeys:(Boolean)state ;
	
	- (void)useVFOOffset:(float)freq ;
	- (void)setRITOffset:(float)rit ;

	@end

#endif
