//
//  Modem.h
//  cocoaModem
//
//  Created by Kok Chen on Sun May 30 2004.
//

#ifndef _MODEM_H_
	#define _MODEM_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "AYTextView.h"
	
	@class Application ;
	@class ExchangeView ;
	@class ModemConfig ;
	@class ModemManager ;
	@class ModemSource ;
	@class Module ;
	@class Preferences ;
	@class PTT ;
	@class RTTYReceiver ;
	@class RTTYRxControl ;
	@class Transceiver ;
	
	typedef struct {
		RTTYRxControl *control ;
		RTTYReceiver *receiver ;
		ExchangeView *view ;
		TextAttribute *textAttribute ;
		Boolean isAlive ;
		Module *transmitModule ;
	} RTTYTransceiver ;
	
	#define	WATERFALLBUFFERMASK 0xf
	typedef float WaterfallBuffer[1024] ;

	@interface Modem : CMPipe {

		IBOutlet id config ;
		IBOutlet id txConfig ;
		IBOutlet id view ;
		IBOutlet id receiveView ;
		IBOutlet id transmitView ;
			
		IBOutlet id leadinField ;	
		IBOutlet id releaseField ;	

		
		//  AppleScript transceiver class
		Transceiver *transceiver1, *transceiver2 ;
		
		NSString *ident ;
		int transceivers ;
		int lastPolledTransceiver ;

		NSTabViewItem *modemTabItem ;
		NSTabView *controllingTabView ;
		ModemManager *manager ;
		//  Text views
		NSColor *textColor, *backgroundColor, *sentTextColor, *plotColor ;
		Boolean sentColor ;
		TextAttribute *receiveTextAttribute, *transmitTextAttribute ;
		//  modifier keys
		Boolean controlKeyState ;
		Boolean shiftKeyState ;
		Boolean optionKeyState ;
		//  modem's visible state
		Boolean visibleState ;
		//  transmit
		NSLock *transmitCountLock ;
		int transmitCount ;
		Boolean transmitState ;
		PTT *ptt ;
		// receive
		Boolean slashZero ;
		//  call recognition and exchange recognition
		char callChar[256] ;
		char exchChar[256] ;
		char captured[33] ;
		Boolean enableClick ;
		NSLock *getCallLock ;
		
		//  break-in
		int breakinLeadin ;
		int breakinRelease ;
		
		// to avoid writing plist that has not been updated
		Boolean plistHasBeenUpdated ;
		
		NSLock *waterfallLock ;
		int waterfallProducer, waterfallConsumer ;
		WaterfallBuffer waterfallBuffer[WATERFALLBUFFERMASK+1] ;
		NSDate *waterfallDate ;
		double waterfallTouched ;
		
		//  watchdog timer
		int charactersSinceTimerStarted ;
		NSTimer *timeout ;
		
		float outputBoost ;
	}
	
	- (void)selectView:(int)index ;				//  v0.96c
	
	- (float)outputBoost ;						//  v0.88

	- (void)switchModemIn ;						//  v0.87
	
	- (float*)waterfallBuffer:(int)index ;		//  v0.64c  (index =0 is first transceiver, if there are more than one waterfall in modem)
	- (int)nextWaterfallScanline ;				//  v0.64c

	- (void)directSetFrequency:(float)freq ;	//  v1.02c
	- (float)selectedFrequency ;				//  v1.02c
 
	- (void)enableModem:(Boolean)state ;
	- (char*)capturedString ;
	
	- (Boolean)openConfigPanel ;
	- (void)showConfigPanel ;
	- (void)closeConfigPanel ;
	- (void)setInterface:(NSControl*)object to:(SEL)selector ;
	
	- (NSString*)ident ;
	- (int)transmissionMode ;		// RTTYMODE, etc
	
	- (NSSlider*)inputAttenuator:(ModemConfig*)config ;
	
	- (void)changeTransmitStateTo:(Boolean)state ;
	- (void)ptt:(Boolean)state ;
	- (void)transmissionEnded ;
	- (Boolean)currentTransmitState ;
	- (void)transmittedCharacter:(int)ch ;
	- (Boolean)shouldEndTransmission ;
	//  transmit count change with locks
	- (void)incrementTransmitCount ;
	- (void)decrementTransmitCount ;
	- (void)clearTransmitCount ;
	- (Boolean)checkIfCanTransmit ;
	
	- (Boolean)isCallChar:(int)c ;
	
	//  the usual init
	- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr ;
	//  call by subclasses to bring in it's nib
	- (id)initIntoTabView:(NSTabView*)tabview nib:(NSString*)nib manager:(ModemManager*)mgr ;
	- (Application*)application ;
	
	- (void)initCallsign ;
	- (void)initColors ;
	
	//  modifier keys
	- (void)keyModifierChanged:(NSNotification*)notify ;
	
	- (void)updateSourceFromConfigInfo ;
	- (ModemConfig*)configObj:(int)index ;
	- (ModemConfig*)txConfigObj ;
	- (ModemManager*)managerObject ;
	
	- (void)updateColorsInViews ;
	- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor ;
	- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor forReceiver:(int)rx ;

	- (void)setTransmitTextColor:(NSColor*)sentTColor ;
	
	- (void)setSentColor:(Boolean)state ;
	- (void)setSentColor:(Boolean)state view:(ExchangeView*)view textAttribute:(TextAttribute*)attr ;
	
	- (void)importData:(CMPipe*)pipe ;  // AudioPipe destination
	- (CMTappedPipe*)dataClient ;

	//  Plist
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	//  cleanups 
	- (void)applicationTerminating ;
	
	//  Global preferences
	- (void)removeToolTips ;
	- (void)useSlashedZero:(Boolean)state ;
	
	- (void)setVisibleState:(Boolean)visible ;
	- (void)activeChanged:(ModemConfig*)f ;
	
	- (void)enterTransmitMode:(Boolean)state ;
	- (void)flushAndLeaveTransmit ;
	
	- (NSTabViewItem*)tabItem ;
	- (Boolean)isActiveTab ;
	
	//  callback from AFSK/PSK generator
	- (void)sendMessageImmediately ;
	
	//  callback from waterfall
	- (void)clicked:(float)freq secondsAgo:(float)sec option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)index ;
	- (void)turnOffReceiver:(int)ident option:(Boolean)option ;
	
	- (NSRange)captureCallsign:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange ;
	- (void)captureSelection:(NSTextView*)obj ;
	- (NSRange)getCallsignString:(NSTextView*)textView from:(NSRange)selectedRange ;
	- (NSRange)getExchangeString:(NSTextView*)textView from:(NSRange)selectedRange ;
	- (void)upperCase:(NSString*)string into:(char*)captured ;
		
	//  -- AppleScript support --
	// commands
	- (void)selectModem:(NSScriptCommand*)command ; 
	//  properties
	- (NSString*)stream ;
	- (void)setStream:(NSString*)text ;
	
	- (NSAppleEventDescriptor*)spectrumPosition ;
	- (void)setSpectrumPosition:(NSAppleEventDescriptor*)point ;
	
	//  class objects
	- (Transceiver*)transceiver1 ;
	- (Transceiver*)transceiver2 ;
	
	//  support for other AppleScript classes
	- (float)frequencyFor:(Module*)module ;
	- (void)setFrequency:(float)freq module:(Module*)module ;
	- (void)setTimeOffset:(float)offset index:(int)index ;	
	- (float)markFor:(Module*)module ;
	- (void)setMark:(float)freq module:(Module*)module ;
	- (float)spaceFor:(Module*)module ;
	- (void)setSpace:(float)freq module:(Module*)module ;
	- (float)baudFor:(Module*)module ;
	- (void)setBaud:(float)rate module:(Module*)module ;
	- (Boolean)invertFor:(Module*)module ;
	- (void)setInvert:(Boolean)state module:(Module*)module ;
	- (Boolean)breakinFor:(Module*)module ;
	- (void)setBreakin:(Boolean)state module:(Module*)module ;
	- (void)transmitString:(const char*)s ;
	
	- (void)flushClickBuffer ;					//  v0.89
	
	- (void)selectTransceiver:(Transceiver*)transceiver andChangeTransmitStateTo:(Boolean)transmit ;
	- (int)selectedTransceiver ;
	
	- (Boolean)checkEnable:(Transceiver*)transceiver ;
	- (void)setEnable:(Transceiver*)transceiver to:(Boolean)sense ;

	- (int)modulationCodeFor:(Transceiver*)transceiver ;
	- (void)setModulationCodeFor:(Transceiver*)transceiver to:(int)code ;
	
	- (void)setIgnoreNewline:(Boolean)state ;
	
	- (void)setShowControls:(Boolean)state ;			//  v0.64c
	- (void)setShowSpectrum:(Boolean)state ;			//  v0.64c

	- (void)resetWatchdog ;								//  v0.64c
	
	- (NSAppleEventDescriptor*)spectrumPosition ;							//  v0.64c
	- (void)setSpectrumPosition:(NSAppleEventDescriptor*)point ;			//  v0.64c
	- (NSAppleEventDescriptor*)controlsPosition ;							//  v0.64c
	- (void)setControlsPosition:(NSAppleEventDescriptor*)point ;			//  v0.64c

	
	@end
	
	#define	kContestModeCQ	0
	#define	kContestModeSP	3


#endif
