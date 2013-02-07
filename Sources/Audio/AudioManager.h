//
//  AudioManager.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/5/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ModemAudio.h"

#define	MAXSTREAMS	16
#define	MAXCHANNELS	16

#define	NODBVALUE	100.0

typedef struct {
	AudioValueRange dbRange ;
} DeviceChannel ;

typedef struct {
	int channels ;
	Boolean hasMasterControl ;
	DeviceChannel channelInfo[MAXCHANNELS] ;
} DeviceStream ;

//	Each deviceID has its own IOProc and a list of input and output DeviceStream (see above). 
typedef struct {
	AudioDeviceID deviceID ;
	
	//  actively sampling clients
	int activeInputClients ;
	ModemAudio *activeInputModemAudio[256] ;
	int activeOutputClients ;
	ModemAudio *activeOutputModemAudio[256] ;
	
	//  all clients that need deviceListener
	int inputClients ;
	ModemAudio *inputModemAudio[256] ;
	int outputClients ;
	ModemAudio *outputModemAudio[256] ;

	//  stream info for deviceID
	int inputStreams ;
	DeviceStream inputStream[MAXSTREAMS];
	int outputStreams ;
	DeviceStream outputStream[MAXSTREAMS] ;

	NSLock *lock ;
	AudioDevicePropertyListenerProc *propertyListenerProc ;
	
} RegisteredAudioDevice ;

@interface AudioManager : NSObject {
	int registeredAudioDevices ;
	RegisteredAudioDevice *registeredAudioDevice[256] ;
	RegisteredAudioDevice *cachedDevice[2048] ;
}

- (RegisteredAudioDevice*)audioDeviceForID:(AudioDeviceID)devID ;

- (float)sliderValueForDeviceID:(AudioDeviceID)devID isInput:(Boolean)isInput channel:(int)channel ;

- (void)audioDeviceRegister:(AudioDeviceID)devID modemAudio:(ModemAudio*)client ;
- (void)audioDeviceUnregister:(AudioDeviceID)devID modemAudio:(ModemAudio*)client ;

- (OSStatus)audioDeviceStart:(AudioDeviceID)devID modemAudio:(ModemAudio*)client ;
- (OSStatus)audioDeviceStop:(AudioDeviceID)devID modemAudio:(ModemAudio*)client ;

- (void)putCodecsToSleep ;
- (void)wakeCodecsUp ;

@end
