//
//  ASCIIReceiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/28/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCIIReceiver.h"
#import "ASCIIDemodulator.h"
#import "RTTYAuralMonitor.h"
#import "RTTYSingleFilter.h"
#import "RTTYMPFilter.h"


@implementation ASCIIReceiver

- (id)initReceiver:(int)index
{
	CMTonePair defaultTones = { 2125.0, 2295.0, 110.0 } ;
	
	self = [ super init ] ;
	if ( self ) {
		uniqueID = index ;
		receiveView = nil ;
		squelch = nil ;
		currentTonePair = defaultTones ;
		enabled = slashZero = sidebandState = NO ;
		demodulatorModeMatrix = nil ;
		bandwidthMatrix = nil ;		
		appleScript = nil ;
		usos = YES ;
		
		//  local CMDataStream
		cmData.samplingRate = 11025.0 ;
		cmData.samples = 512 ;
		cmData.components = 1 ;
		cmData.channels = 1 ;
		data = &cmData ;
		newData = [ [ NSConditionLock alloc ] initWithCondition:kNoData ] ;
		[ NSThread detachNewThreadSelector:@selector(receiveThread:) toTarget:self withObject:self ] ;
		clickBufferLock = nil ;
		
		rttyAuralMonitor = [ [ RTTYAuralMonitor alloc ] init ] ;
		
		demodulator = [ [ ASCIIDemodulator alloc ] initFromReceiver:self ] ;
				
		bandpassFilter = [ [ CMFilterBank alloc ] init ] ;
		matchedFilter = [ [ CMFilterBank alloc ] init ] ;
		
		// create bandpass filter bank for 110 baud
		bpf[0] = [ demodulator makeFilter:275.0 ] ;
		bpf[1] = [ demodulator makeFilter:500.0 ] ;
		bpf[2] = [ demodulator makeFilter:830.0 ] ;
		bpf[3] = [ demodulator makeFilter:1160.0 ] ;
		bpf[4] = [ demodulator makeFilter:1200.0 ] ;
		[ bandpassFilter installFilter:bpf[0] ] ;
		[ bandpassFilter installFilter:bpf[1] ] ;
		[ bandpassFilter installFilter:bpf[2] ] ;
		[ bandpassFilter installFilter:bpf[3] ] ;
		[ bandpassFilter installFilter:bpf[4] ] ;
		[ bandpassFilter selectFilter:1 ] ;
		[ demodulator useBandpassFilter:bandpassFilter ] ;
		
		//  create matched filter bank
		[ matchedFilter installFilter:[ [ RTTYSingleFilter alloc ] initTone:0 baud:110.0 ] ] ;					//  Mark-only
		[ matchedFilter installFilter:[ [ RTTYSingleFilter alloc ] initTone:1 baud:110.0 ] ] ;					//  Space-only
		[ matchedFilter installFilter:[ [ RTTYMPFilter alloc ] initBitWidth:0.35 baud:110.0 ] ] ;				//  MP+
		[ matchedFilter installFilter:[ [ RTTYMPFilter alloc ] initBitWidth:0.70 baud:110.0 ] ] ;				//  MP-
		[ matchedFilter installFilter:[ [ RTTYMatchedFilter alloc ] initDefaultFilterWithBaudRate:110.0 ] ] ;	//  MS		v0.32
	
		[ matchedFilter selectFilter:4 ] ;
		[ demodulator useMatchedFilter:matchedFilter ] ;

		return self ;
	}
	return nil ;
}


@end
