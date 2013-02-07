//
//  NetReceive.h
//
//  Created by Kok Chen on 1/23/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#ifndef _NETRECEIVE_H_
	#define _NETRECEIVE_H_

	#import <Cocoa/Cocoa.h>
	#import "../Headers/NetAudio.h"
	#import "../Local Headers/BonjourService.h"


	typedef struct {
		AudioUnit netReceiveUnit ;
	} CallbackInfo ;

	@interface NetReceive : NetAudio {
		AudioUnit netReceiveAudioUnit ;
		BonjourService *bonjour ;
		BonjourSocket *socket ;
		CallbackInfo callbackInfo ;
	}
	
	- (id)initWithAddress:(const char*)ip port:(int)port delegate:(id)inDelegate samplesPerBuffer:(int)size ;
	
	- (Boolean)setAddress:(const char*)ip port:(int)port ;
			
	//  Start sampling.
	//	If the delegate is set and delegate has the method newNetReceiveSamples, the delegate should start receiving buffers.
	//  If sampling cannot be started, startSampling returns false.
	- (Boolean)startSampling ;
	
	//  Stop sampling.
	- (void)stopSampling ;	
	
	//  IP number
	//  ip returns a C string that has the IPv4 address of the AUNetSend/AUNetReceive pair (e.g., "192.168.1.100")
	- (const char*)ip ;
	
	//  Port number
	//  port returns the port of the AUNetSend/AUNetReceive pair. MacOS X AUNetSend tyically starts at port 52800.	
	- (int)port ;
	
	//  Delegate method to receive new data from AUNetReceive.
	//  left and right are the floating point stereo buffers.
	- (void)netReceive:(NetReceive*)aNetReceive newSamples:(int)samplesPerBuffer left:(const float*)leftBuffer right:(const float*)rightBuffer ;

	//  Delegate method that is called when Bonjour detects an IP/port address change.
	//  The delegate can then call -ip and -port to get the new values
	- (void)netReceive:(NetReceive*)aNetReceive addressChanged:(const char*)address port:(int)port ;

	//  Delegate method that is called when Bonjour finds the port has disconnected.
	- (void)netReceive:(NetReceive*)aNetReceive disconnectedFromAddress:(const char*)address port:(int)port ;

	@end

#endif
