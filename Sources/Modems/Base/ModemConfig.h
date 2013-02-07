//
//  ModemConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Sat Jul 31 2004.
//

#ifndef _MODEMCONFIG_H_
	#define _MODEMCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "DestClient.h"
	
	@class Modem ;
	@class ModemSource ;
	@class ModemDest ;
	@class ModemEqualizer ;
	@class Preferences ;
	@class PTT ;
	@class VUMeter ;
	
	@interface ModemConfig : DestClient {
		IBOutlet id window ;
		IBOutlet id modemObj ;
		
		//  common control
		IBOutlet id activeButton ;
		IBOutlet id soundOutputLevel ;
		IBOutlet id waveformMatrix ;	
		IBOutlet id textColor ;
		IBOutlet id transmitTextColor ;
		IBOutlet id backgroundColor ;
		IBOutlet id plotColor ;
		
		//  input controls
		IBOutlet id soundInputControls ;
		IBOutlet id soundFileControls ;
		IBOutlet id fileSpeedCheckbox ;
		IBOutlet id inputPad ;
		
		//  output controls
		IBOutlet id soundOutputControls ;
		
		//  instrumentation scope
		IBOutlet id oscilloscope ;
		IBOutlet id specLabel ;
		
		//  Equalizer
		ModemEqualizer *equalizer ;
		
		//  states
		Boolean isActiveButton ;
		Boolean interfaceVisible ;
		Boolean isTransmit ;
		Boolean inputSamplingState ;
		Boolean configOpen ;
		long sequenceNumber ;
		
		//  sound interface
		ModemSource *modemSource ;
		ModemSource *modemSource2 ;
		ModemDest *modemDest ;
		VUMeter *vuMeter ;
		
		//  transmit
		float tempBuffer[512], bpfBuf[512] ;
		NSButton *transmitButton ;
		NSTimer *timeout ;		

		//  tone generator
		NSMatrix *toneMatrix ;
		int toneIndex ;
		float outputScale ;
		
		//  sound file
		int fastFileSpeed ;
		
		//	AGC
		float agcValue ;
	}
	
	//	v0.78 cleanups
	- (void)applicationTerminating ;
	
	//  v0.87
	- (void)setKeyerMode ;
	//	v0.88d
	- (void)processAGC:(float)amplitude ;
	
	//  inits and actions
	- (void)setInterface:(NSControl*)object to:(SEL)selector ;
	- (void)initializeActions ;
	
	- (Modem*)modemObject ;
	- (PTT*)pttObject ;
	- (long)sequenceNumber ;
	
	//  open/close window
	- (void)openPanel ;
	- (void)closePanel ;
	- (void)setConfigOpen:(Boolean)state ;

	//  modem input
	- (void)setupModemSource:(NSString*)inputDevice channel:(int)ch ;
	- (ModemSource*)inputSource ;
	- (void)updateInputSamplingState ;
	- (void)updateFileSpeed ;
	
	//  modem states
	- (void)checkActive ;
	- (Boolean)soundInputActive ;
	- (void)setSoundInputActive:(Boolean)state ;
	- (Boolean)updateActiveButtonState ;
	- (void)updateVisibleState:(Boolean)state ;
	- (Boolean)transmitActive ;
	
	- (void)inputAttenuatorChanged:(NSSlider*)inputAttenuator ;
	
	//  sound output
	- (void)setupModemDest:(NSString*)outputDevice controlView:(NSView*)controlView attenuatorView:(NSView*)attenuatorView ;
	
	//  color support
	- (void)updateColorsFromPreferences:(Preferences*)pref ;
	- (void)retrieveActualColorPreferences:(Preferences*)pref ;
	
	//  prefs
	- (void)setColorRed:(NSString*)rTag green:(NSString*)gTag blue:(NSString*)bTag fromColor:(NSColor*)color into:(Preferences*)pref ;

	- (void)set:(NSString*)tag fromRed:(float)red green:(float)green blue:(float)blue into:(Preferences*)pref ;
	- (void)set:(NSString*)tag fromColor:(NSColor*)color into:(Preferences*)pref ;
	- (NSColor*)getColorRed:(NSString*)rTag green:(NSString*)gTag blue:(NSString*)bTag from:(Preferences*)pref ;
	- (NSColor*)getColor:(NSString*)tag from:(Preferences*)pref ;
	
	- (void)soundFileStarting:(NSString*)str ;
	- (void)directOpenSoundFile ;

	@end
	
	//  v0.93b microHAM routing
	#define	kMicrohamAutoRouting		0
	#define	kMicrohamDigitalRouting		2
	#define	kMicrohamCWRouting			4
	#define	kMicrohamFSKRouting			5

#endif
