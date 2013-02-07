//
//  ModemAudio.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/19/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "CoreFilter.h"
#import "AudioDeviceTypes.h"
#import "ResamplingPipe.h"

#define BUFLEN		512


typedef struct {
	AudioDeviceID deviceID ;
	AudioStreamID streamID ;
	int streamIndex ;
	NSString *name ;
} SoundCardInfo ;

@class AudioManager ;

@interface ModemAudio : CMTappedPipe {

	SoundCardInfo info[MAXDEVICES] ;
	SoundCardInfo *selectedSoundCard ;
	int soundcards ;					//  input or output sound cards

	AudioManager *audioManager ;
	AudioDeviceID previousDeviceID ;

	NSString *deviceName ;				//  unique name for each ModemSource or ModemDest
	int channels ;
	int deviceState ;
	int channel ;
	int baseChannel ;
	Boolean isInput ;
	Boolean isSampling ;				//  set when virtual AudioDeviceStart/AudioDeviceStop is called
	Boolean restartSamplingOnWakeup ;	
	AudioDeviceIOProc savedIOProc ;
	Boolean started ;
	
	//	sampling rate conversion
	ResamplingPipe *resamplingPipe ;
	int resamplingPipeChannels ;
	float resampledBuffer[1024] ;
	float clientBuffer[1024] ;
	float previousSamplingRate ;
	
	//  (used only by ModemDest)
	float pipeBuffer[512*2] ;					//  max of 512 x stereo samples

	NSLock *startStopLock ;
	Boolean outputMuted ;
	
	ChannelBitPair deviceBitPair ;

	NSTextField *dbPad ;
	NSSlider *dbSlider ;
	NSSlider *scalarSlider ;	
	NSPopUpButton *soundCardMenu ;		//  maps to inputMenu or outputMenu
	NSPopUpButton *sourceMenu ;			//  maps to inputSourceMenu or outputDestMenu
	NSPopUpButton *samplingRateMenu ;	//  maps to inputSamplingRateMenu or outputSamplingRateMenu
	NSPopUpButton *channelMenu ;		//  maps to inputChannel or outputChannel
	NSPopUpButton *paramString ;		//  maps to inputParam or outputParam
	
	float nonOOKLevel ;					//  v0.85
	float currentLevel ;				//  v0.85
	float currentDB ;					//	v0.88d
	float dBmin, dBmax ;				//  c0.88d
}

- (int)channel ;						//  v0.85

- (void)setupSoundCards ;
- (Boolean)isInput ;

- (int)updateSoundCardMenu ;
- (int)soundCardChanged ;
- (int)selectSoundCard:(NSString*)name ;

- (int)updateSourceMenu ;
- (int)sourceMenuChanged ;
- (void)fetchSourceFromCoreAudio ;
- (int)selectSource:(NSString*)name ;

- (Boolean)samplingRateChanged ;
- (void)fetchSamplingRateFromCoreAudio ;
- (void)actualSamplingRateSetTo:(float)rate ;

- (void)updateChannelMenu ;
- (int)channelChanged ;
- (int)selectChannel:(int)channelIndex ;

- (void)registerLevelSlider:(NSSlider*)slider isScalar:(Boolean)useScalar ;
- (void)setOOKDeviceLevel ;													//  v0.85
- (float)validateDeviceLevel ;												//  v0.85
- (void)setDeviceLevelFromSlider ;
- (void)fetchDeviceLevelFromCoreAudio ;
- (Boolean)getDBRange:(AudioValueRange*)dbRange ;

- (void)changeDeviceGain:(int)direction ;									//  v0.88d

- (Boolean)startSoundCard ;
- (Boolean)stopSoundCard ;

- (void)applicationTerminating ;

- (int)needData:(float*)outbuf samples:(int)n channels:(int)ch ;			// prototype used by ResamplingPipe to request data

//  v0.78 interface for AudioManager.m
- (void)inputArrivedFrom:(AudioDeviceID)device bufferList:(const AudioBufferList*)input ;
- (void)accumulateOutputFor:(AudioDeviceID)device bufferList:(const AudioBufferList*)output accumulate:(Boolean)accumulate ;

@end
