//
//  RTTYTxConfig.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/6/06.

#ifndef _RTTYTXCONFIG_H_
	#define _RTTYTXCONFIG_H_

	#import "CMFIR.h"
	#import "CoreModemTypes.h"
	#import "ModemConfig.h"
	#import "Preferences.h"
	#import "RTTYAuralMonitor.h"
	#import "RTTYTypes.h"

	@class RTTYModulator ;
	@class RTTYRxControl ;
	@class FSK ;

	@interface RTTYTxConfig : ModemConfig {
	
		IBOutlet id stopBits ;

		RTTYRxControl *rttyRxControl ;
		RTTYConfigSet configSet ;
		RTTYModulator *afsk ;
		FSK *fsk ;
		int ook ;						//  v0.85
		CMFIR *transmitBPF ;
		float *fir ;
		float outputSamplingRate ;
		int currentLow, currentHigh ;
		int outputChannels ;
		
		float equalize ;
		Boolean usosState ;				//  v0.84
		
		//  the following flags keep txConfigs from being called more than once
		Boolean hasSetupDefaultPreferences ;
		Boolean hasRetrieveForPlist ;
		Boolean hasUpdateFromPlist ;
		
		RTTYAuralMonitor *rttyAuralMonitor ;
	}
	
	- (IBAction)openAuralMonitor:(id)sender ;

	- (IBAction)testToneChanged:(id)sender ;
	- (IBAction)stopBitsChanged:(id)sender ;
	- (IBAction)openEqualizer:(id)sender ;

	- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control ;
	- (void)setupTonesFrom:(RTTYRxControl*)control lockTone:(Boolean)state ;
	- (void)setRTTYAuralMonitor:(RTTYAuralMonitor*)mon ;

	//  state changes from RTTY panel
	- (Boolean)turnOnTransmission:(Boolean)state button:(NSButton*)button fsk:(FSK*)inFSK ;
	- (Boolean)turnOnTransmission:(Boolean)state button:(NSButton*)button fsk:(FSK*)inFSK ook:(int)inOOK ;		//  v0.85
	- (void)transmitCharacter:(int)acsii ;
	- (void)flushTransmitBuffer ;

	//  AudioOutputPort callbacks
	- (void)setOutputScale:(float)value ;
	
	- (Boolean)startFSKTransmit ;
	- (RTTYModulator*)afskObj ;
	- (void)setUSOS:(Boolean)state ;
	- (void)stopSampling ;

	- (void)updateColorsFromPreferences:(Preferences*)pref configSet:(RTTYConfigSet*)set ;
	- (void)setupDefaultPreferences:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control ;
	- (Boolean)updateFromPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control ;
	- (void)retrieveForPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control ;

	- (CMTonePair*)transmitTonePair ;			// v0.67
	
	- (void)setBitsPerCharacter:(int)bits ;		// v0.83

	@end

#endif
