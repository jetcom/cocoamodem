//
//  NetSend.h
//  AUNetSend Example
//
//  Created by Kok Chen on 1/25/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#ifndef _NETSEND_H_
	#define _NETSEND_H_

	#import <Cocoa/Cocoa.h>
	#import <AudioUnit/AudioUnit.h>
	#import "../Headers/NetAudio.h"
	

	@interface NetSend : NetAudio {
		AudioUnit netSendAudioUnit ;
		NSString *password ;
		UInt32 port ;
	}
	
	- (Boolean)setPortNumber:(int)number ;
	
	//  Start sampling.
	//	If the delegate is set and delegate has the method needNetSendSamples, the delegate should start receiving buffers.
	//  If sampling cannot be started, startSampling returns false.
	- (Boolean)startSampling ;
	
	//  Stop sampling.
	- (void)stopSampling ;	

	//  Delegate method to pull new data from the client.
	//  left and right are the floating point stereo buffers.
	//  The delegate should fill the two buffers with new data.
	- (void)netSend:(NetSend*)aNetSend needSamples:(int)samplesPerBuffer left:(float*)leftBuffer right:(float*)rightBuffer ;
	
	@end

#endif
