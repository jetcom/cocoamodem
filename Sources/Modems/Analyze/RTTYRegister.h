//
//  RTTYRegister.h
//  cocoaModem
//
//  Created by Kok Chen on 3/9/05.
//

#ifndef _RTTYREGISTER_H_
	#define _RTTYREGISTER_H_

	#import <Cocoa/Cocoa.h>

	#define	RINGSIZE	4096
	#define	RINGMASK	0xfff
	typedef float RingBuffer[RINGSIZE] ;

	@interface RTTYRegister : NSObject {
		float samplesPerBit ;
		float samplesPerWord ;
		int bitCenter[10] ;
		int wordOffset[32] ;
		RingBuffer array ;
		RingBuffer agc ;
		RingBuffer sync ;
		int maxRegister[256] ;			//  width of AGC register (one 1.5 stop-bit word = 226 samples)
		int accumMax ;
		float smoothedMax ;
		int outPointer ;
		int inPointer ;
	}
	
	- (id)initWithBitPeriod:(float)milliseconds ;
	
	- (void)addSample:(float)data ;
	- (void)addSamples:(int)size array:(float*)data ;
	- (void)advance ;
	
	- (float)charactersAvailable ;
	
	- (int)delay ;
	
	- (float)sample:(int)bit ;
	- (float)sample:(int)bit offset:(int)offset ;
	- (float)sample:(int)bit word:(int)word offset:(int)offset ;
	
	- (float)agc ;
	- (float)agcAtOffset:(int)offset ;
	- (float)agcForWord:(int)word ;
	
	- (void)getBuffer:(float*)buf offset:(int)offset stride:(int)stride ;
	- (void)getCompensatedBuffer:(float*)buf offset:(int)offset stride:(int)stride ;

	@end

#endif
