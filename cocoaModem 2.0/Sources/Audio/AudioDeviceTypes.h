/*
 *  AudioDeviceTypes.h
 *  cocoaModem 2.0
 *
 *  Created by Kok Chen on 5/24/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */

//  Note: this should not include any Cocoa classes

#import <AudioToolbox/AudioFile.h>
#import <CoreAudio/AudioHardware.h>
#import <CoreAudio/CoreAudioTypes.h> 

#define	MAXDEVICES	32

typedef struct {
	AudioFileID ID ;
	UInt32 fileFormat ;
	UInt64 bytes ;
	UInt64 samples ;
	UInt64 currentSample ;
	int sampleSize ;	//  size per channel, in bytes
	int stride ;		//  stride to the next sample, in units of sampleSize
	Boolean repeatFile ;
	Boolean isBigEndian ;
	Boolean isSigned ;
	AudioStreamBasicDescription basicDescription ;
	Boolean active ;
	union {
		short u[1024] ;
		char b[1024] ;
	} buf ;
} AudioSoundFile ;

typedef struct {
	int channels ;
	int bits ;
} ChannelBitPair ;

typedef struct {
	float min ;
	float max ;
} MinMax ;
	
typedef struct {
	int bitPairs ;
	ChannelBitPair channelBitPair[64] ;
} DevParams ;

typedef struct {
	AudioStreamBasicDescription basic ;
	int sampleRanges ;
	MinMax sampleRange[256] ;
} AudioStreamExtendedDescription ;

typedef struct {
	float sampleRate ; 
	int channelsPerFrame ;
	int bitsPerChannel ;
	int rates ; //  sampling rates capable
	float rate[16] ;
} AudioInterfaceParameters ;

typedef struct {
	int bitPairs ;
	ChannelBitPair bitPair[64] ;
} AudioInterfaceDeviceParameters ;


enum {
	noProc = 0,
	hasProc
} ;

typedef struct {
	AudioStreamID streamID ;
	float samplingRate ;
	int bits;
	int channels ;
} AudioStreamInfo ;

typedef struct {
	AudioDeviceIOProc inputProc ;
	void* inputClient ;
	AudioDeviceIOProc outputProc ;
	void* outputClient ;
} AudioDeviceInfo ;

