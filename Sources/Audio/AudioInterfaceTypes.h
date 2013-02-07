//
//  AudioInterfaceTypes.h
//  AudioInterface
//
//  Created by Kok Chen on 11/06/05
//	Ported from cocoaModem, file originally dated Sun Feb 08 2004.

#import <Cocoa/Cocoa.h>
#import "AudioDeviceTypes.h"

typedef struct {		
	AudioDeviceID deviceID ;
	AudioStreamID streamID ; 
	int streamIndex ;				//  v1.1 (fr cocoaModem v0.50) n-th stream of a device
	Boolean isInput ;
	NSString *name ;				//  v0.70 -- was char name[97]
} AudioInterfaceDevice ;

