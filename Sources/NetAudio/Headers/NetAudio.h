//
//  NetAudio.h
//  NetAudio
//
//  Created by Kok Chen on 1/31/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#ifndef _NETAUDIO_H_
	#define _NETAUDIO_H_

	#import <Cocoa/Cocoa.h>
	#import <AudioUnit/AudioUnit.h>

	typedef enum {
		kNetAudioIdle,
		kNetAudioStarted,
		kNetAudioRunning,
		kNetAudioStopped
	} NetAudioRunState ;

	typedef struct {
		id netSendObj ;
		id delegate ;
		NetAudioRunState runState ;
		float raisedCosine[512] ;
	} NetAudioStruct ;

	typedef enum {
		kWaitForCommand,
		kCommandAvailable
	} LockCondition ;

	@interface NetAudio : NSObject {
		Boolean isReceive ;					//  direction YES for NetReceive, NO for NetSend
		NSString *serviceName ;
		NetAudioStruct netAudioStruct ;
		
		//  Timer thread
		NSConditionLock *timerThreadLock ;
		NSThread *timerThread ;

		//  sampling process
		NSLock *tickLock ;
		NSTimer *runTimer ;
		
		//  device parameters
		UInt32 channels ;					// stereo = 2
		UInt32 samplesPerBuffer ;			// typically 512
		float samplingRate ;				// typically 44100.0

		//  AudioUnit Buffers
		AudioBufferList bufferList ;
		AudioBuffer audioBuffer[2] ;
		float *dataBuffer[2] ;
		AudioTimeStamp timeStamp ;
	}

	- (id)initWithService:(NSString*)service delegate:(id)inDelegate samplesPerBuffer:(int)size ;
	
	- (void)setDelegate:(id)inDelegate ;
	- (id)delegate ;
	
	//  Method to set AUNetSend Bonjour service name
	- (Boolean)setServiceName:(NSString*)name ;
	- (NSString*)serviceName ;									//  return service name or nil
	
	- (Boolean)setPassword:(NSString*)password ;

	- (Boolean)isNetReceive ;
	
	//  -- private APIs --
	//  Size of buffer that are returned in newNetReceiveSamples.
	//  The default size is 515.
	//  Size = 512 means 512 stereo samples, i.e., 512 left and 512 right samples.
	- (void)setBufferSize:(int)size ;
	- (void)freeBuffers ;

	//  private API
	- (Boolean)runThread ;

	@end

#endif
