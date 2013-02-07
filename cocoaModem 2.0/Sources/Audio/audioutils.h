/*
 *  audioutils.h
 *  Sound
 *
 *  Created by kchen on Thu Jun 20 2002.
 *  Copyright (c) 2002, 2003, 2004 W7AY. All rights reserved.
 *
 */
 
#ifndef _AUDIOUTILS_H_
	#define _AUDIOUTILS_H_

	#include <Carbon/Carbon.h>
	#include <CoreAudio/AudioHardware.h>
	#import "AudioDeviceTypes.h"
	
	int enumerateAudioDevices( AudioDeviceID* list, int n ) ;
	
	void getDeviceParams( int streamID, Boolean isInput, DevParams *devParams ) ;
	int getFormatForStream( int streamID, int channel, AudioStreamExtendedDescription *streamDesc ) ;
	
	int getPhysicalFormatForStream( int streamID, int channel, AudioStreamExtendedDescription *streamDesc ) ;
	
	int setBufferSize( int deviceID, Boolean input, int size ) ;
	
	void setFormatForStream( int streamID, int channel, AudioStreamExtendedDescription *streamDesc ) ;	
	Boolean setParamsForDevice( int streamID, Boolean isInput, float rate, int bits, int channels ) ;
	
	void initAudioUtils() ;
	AudioStreamInfo* infoForStream( AudioStreamID streamID ) ;
	OSStatus audioDeviceChangeInputProc( AudioDeviceID deviceID, AudioDeviceIOProc proc, void *clientData ) ;
	OSStatus audioDeviceChangeOutputProc( AudioDeviceID deviceID, AudioDeviceIOProc proc, void *clientData ) ;

	
#endif
