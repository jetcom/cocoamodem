//
//  ModemDest.h
//  cocoaModem
//
//  Created by Kok Chen on Sun Aug 01 2004.
//

#ifndef _MODEMDEST_H_
	#define _MODEMDEST_H_
	
	//  Device States
	#define DISABLED	0		// caused by enableOutput:NO
	#define ENABLED		1		// caused by enableOutput:YES
	#define RUNNING		2		// caused by started and ENABLED


	#import <Cocoa/Cocoa.h>
	#import "ModemAudio.h"

	@class DestClient ;
	@class ModemConfig ;
	@class Preferences ;
	@class PTT ;
	@class PTTHub ;

	@interface ModemDest : ModemAudio {
		IBOutlet id outputMenu ;
		IBOutlet id outputDestMenu ;
		IBOutlet id outputChannel ;
		IBOutlet id outputSamplingRateMenu ;		// v0.53a
		IBOutlet id outputParam ;
		
		IBOutlet id controlView ;
		IBOutlet id levelView ;
		IBOutlet id outputLevel ;
		IBOutlet id outputAttenuator ;
		
		IBOutlet id pttMenu ;
		PTT *ptt ;
			
		DestClient *client ;
		Boolean useMenus ;
		
		Boolean rateChangeBusy ;
		
		NSString *outputLevelKey ;
		NSString *attenuatorKey ;
		
		NSString *mostRecentlyUsedDevice ;			//  v0.76
		
		//  initial values
		int initCh, initRate, initBits ;
	}

	- (id)initIntoView:(NSView*)view device:(NSString*)name level:(NSView*)level client:(DestClient*)inClient pttHub:(PTTHub*)pttHub ;
	- (id)initIntoView:(NSView*)view device:(NSString*)name level:(NSView*)level client:(DestClient*)inClient channels:(int)ch ;
	- (PTT*)ptt ;
		
	//  output channel control
	- (void)startSampling ;
	- (void)enableOutput:(Boolean)enable ;
	- (void)stopSampling ;
	- (void)setMute:(Boolean)state ;
	
	- (void)setSoundLevelKey:(NSString*)key attenuatorKey:(NSString*)attenuator ;
	
	- (void)changeToNewOutputDevice:(int)index destination:(int)dest refreshSamplingRateMenu:(Boolean)refreshSamplingRateMenu ;
	- (void)updateAttenuator ;

	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref updateAudioLevel:(Boolean)updateLevel ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref updateAudioLevel:(Boolean)update ;		//  v0.85
	
	- (NSSlider*)outputLevel ;

	@end

#endif
