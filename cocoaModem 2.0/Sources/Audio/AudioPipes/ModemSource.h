//
//  ModemSource.h
//  cocoaModem
//
//  Adapted from PrototypeSource on Thu July 29 2004
//  Created by Kok Chen on Wed May 26 2004.
//


#ifndef _MODEMSOURCE_H_
	#define _MODEMSOURCE_H_

	#import <Cocoa/Cocoa.h>
	#import "modemTypes.h"
	#import "ModemAudio.h"
	#import "AIFFSource.h"
	#import "ResamplingPipe.h"
	
	@class Preferences ;
	
	@interface ModemSource : ModemAudio {
		IBOutlet id inputMenu ;
		IBOutlet id inputSourceMenu ;
		IBOutlet id inputChannel ;
		IBOutlet id inputSamplingRateMenu ;
		IBOutlet id inputParam ;
		
		IBOutlet id controlView ;
		IBOutlet id fileView ;
		
		id delegate ;
		
		Boolean hasReadThread ;

		//  file input
		AIFFSource *sourcePipe ;
		Boolean periodic ;
		NSTimer *soundFileTimer ;
		int playbackSpeed ;	
	}
	
	- (IBAction)openFile:(id)sender ;
	- (IBAction)stopFile:(id)sender ;
	
	- (Boolean)fileRunning ;
	
	//  sound file control
	- (void)setPeriodic:(Boolean)state ;
	- (void)nextSoundFrame ;
	
	- (id)initIntoView:(NSView*)view device:(NSString*)name fileExtra:(NSView*)extra playbackSpeed:(int)speed channel:(int)which client:(CMPipe*)inClient ;

	- (void)fileSpeedChanged:(int)newSpeed ;
	- (void)setFileRepeat:(Boolean)doRepeat ;
	- (void)registerInputPad:(NSTextField*)pad ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	
	//  input channel control
	- (void)startSampling ;
	- (void)enableInput:(Boolean)state ;	
	- (void)stopSampling ;
	
	//  level
	- (void)registerDeviceSlider:(NSSlider*)slider ;
	- (void)setDeviceLevel:(NSSlider*)slider ;
	- (void)setPadLevel:(NSTextField*)pad ;
	
	//  delegates
	- (id)delegate ;
	- (void)setDelegate:(id)inDelegate ;
	- (void)soundFileStarting:(NSString*)filename ;
	- (void)soundFileStopped ;
	
	@end

	#define	LEFTCHANNEL		0
	#define	RIGHTCHANNEL	1
	#define	BOTHCHANNEL		2
	
#endif
