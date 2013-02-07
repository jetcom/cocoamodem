//
//  AuralMonitor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/31/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DestClient.h"
#import "PushedStereoDest.h"
#import "ModemConfig.h"

#define	AURALBUFFERS	16

typedef struct {
	DestClient *client ;
	AudioDevicePropertyListenerProc proc ;
} AuralClient ;

typedef struct {
	float left[512] ;
	float right[512] ;
	DestClient *client[32] ;
	int clients ;
} AuralBuffer ;

@interface AuralMonitor : DestClient {
	IBOutlet id window ;
	IBOutlet id controlView ;
	IBOutlet id levelView ;
	IBOutlet id blendSlider ;
	IBOutlet id muteCheckBox ;
	
	PushedStereoDest *modemDest ;
	
	AuralClient activeClient[64] ;
	int clients ;
	
	AuralBuffer auralBuffer[AURALBUFFERS] ;
	
	float stereoBlend ;								//  v0.88
	float stepAttenuator ;							//  v0.88
	long producerSampleIndex, consumerSampleIndex ;	//  v0.88
	int readHysteresis ;
	Boolean readBlocked ;
	
	NSLock *lock ;
}

- (void)addLeft:(float*)left right:(float*)right samples:(int)samples client:(DestClient*)who ;

- (void)showWindow ;

- (void)addClient:(DestClient*)client ;
- (void)removeClient:(DestClient*)client ;

- (void)unconditionalStop ;

- (void)setupDefaultPreferences:(Preferences*)pref ;
- (void)updateFromPlist:(Preferences*)pref ;
- (void)retrieveForPlist:(Preferences*)pref ;

@end
