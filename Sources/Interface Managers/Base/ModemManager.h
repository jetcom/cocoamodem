//
//  ModemManager.h
//  cocoaModem
//
//  Created by Kok Chen on 8/7/05.
//

#ifndef _MODEMMANAGER_H_
	#define _MODEMMANAGER_H_

	#import <Cocoa/Cocoa.h>
	#include "modemTypes.h"
	#import "ASColor.h"
	
	@class Application ;
	@class ASPoint ;
	@class ContestInterface ;
	@class Messages ;
	@class Modem ;
	@class Preferences ;
	@class PTTHub ;
	@class SoftRock ;
	
	typedef struct {
		NSString *name ;			//  AppleScript name
		Modem *modem ;
		NSTabViewItem *tabItem ;
		Boolean contest ;
		Boolean rttyMacro ;			// use shared RTTY macros
		Boolean slashedZero ;
		Boolean receiveOnly ;
		int	numberOfReceiveViews ;	//  v0.96c
		Boolean updatedFromPlist ;
	} InstalledModem ;

	@interface ModemManager : NSObject {
		IBOutlet id application ;
		IBOutlet id tabviewTextured ;
		IBOutlet id tabviewUntextured ;
		IBOutlet id tabviewLite ;
		IBOutlet id logView ;
		IBOutlet id waitPanel ;
		IBOutlet id waitProgressBar ;
		
		IBOutlet id selectReceive1MenuItem ;
		IBOutlet id selectReceive2MenuItem ;
		IBOutlet id selectTransmitMenuItem ;

		NSTabView *tabview ;
		Messages *log ;
		
		//  PTT
		PTTHub *ptt ;		
		
		//  modems
		Modem *rtty ;
		Modem *psk ;
		Modem *dualRTTY ;
		Modem *wfRTTY ;
		Modem *asciiRTTY ;
		Modem *cw ;
		Modem *mfsk ;
		Modem *hell ;
		Modem *sitor ;
		Modem *analyze ;
		Modem *selectedModem ;
		
		// Preferences
		Preferences *preferences ;		//  0.53b
		
		// SDR
		SoftRock *softRock ;
		
		InstalledModem installedModem[32] ;
		int installedModems ;
		
		NSPoint origin ;
		Boolean windowLocked ;
		
		Boolean takesContestMenus ;
		Boolean useWatchdog ;
		Boolean isLiteWindow ;
		Boolean finishedCreatingModems ;		// v0.41
	}
	
	- (IBAction)showDiagnostic:(id)sender ;
	- (IBAction)testDump:(id)sender ;
	
	- (void)setupWindow:(Boolean)textured lite:(Boolean)lite ;
	- (void)useSmoothPattern:(Boolean)state ;
	- (void)showConfigPanel ;
	- (void)closeConfigPanels ;
	- (void)showSoftRock ;
	
	- (void)setModemAtTab:(NSTabViewItem*)tabViewItem ;		//  v0.41
	- (void)updateContestBar:(ContestInterface*)modem ;		//  v0.53b (implemented in StdManager)
	
	- (PTTHub*)pttHub ;
	
	- (void)applicationTerminating ;
	
	- (void)createModems:(Preferences*)pref startModemsFromPlist:(Preferences*)modemList ;
	- (Modem*)currentModem ;
	- (Boolean)modemIsVisible:(Modem*)modem ;
	- (void)setModemCanTransmit:(Boolean)state ;
	- (Boolean)useWatchdog ;
	
	- (void)updateModemSources ;
	- (void)activateModems:(Boolean)state ;
	- (void)enableModems:(Boolean)state ;
	
	//  selecting modems in interface
	- (Boolean)selectModem:(Modem*)modem ;
	- (void)selectTabView:(NSString*)viewName ;
	- (void)selectModemInTabViewItem:(NSTabViewItem*)tabViewItem ;		//  v0.53d
	- (NSString*)nameOfSelectedTabView ;
	- (NSTabViewItem*)activeTabView ;
	
	- (void)showSplash:(NSString*)msg ;
	- (void)updateRTTYMacroButtons ;
	
	- (void)clearToolTipsInView:(NSView*)view ;

	- (Application*)appObject ;
	- (NSWindow*)windowObject ;

	- (Boolean)okToQuit ;

	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	- (void)setAppearancePrefs:(NSMatrix*)appearancePrefs ;
	- (void)setPSKPrefs:(NSMatrix*)pskPrefs ;

	//  ---- AppleScript support ----
	// select command
	- (void)selectInterface:(NSScriptCommand*)command ; 
	//  reset watchdog
	- (void)resetWatchdog:(NSScriptCommand*)command ; 
	//  contest band
	- (int)band ;
	- (void)setBand:(int)data ;
	//  window position
	- (NSData*)position ;
	- (void)setPosition:(NSData*)data ;
	//  window lock
	- (Boolean)lock ;
	- (void)setLock:(Boolean)state ;
	//  window color
	- (NSColor*)backgroundColor ;
	- (void)setBackgroundColor:(NSColor*)color ;
	
	- (Boolean)windowState ;
	- (void)setWindowState:(Boolean)state ;
	- (NSPoint)windowPosition ;
	- (void)setWindowPosition:(NSPoint)origin ;

	//  v0,70
	- (void)setUseShiftJIS:(Boolean)state ;
	- (void)setUseRawForPSK:(Boolean)state ;
	//  v0.71
	- (void)setAllowShiftJISForPSK:(Boolean)state ;
	//	v1.02b
	- (void)directSetFrequency:(float)freq ;
	- (float)selectedFrequency ;
	//  v1.02c
	- (void)speakModemSelection ;
	- (void)selectNextModem ;
	- (void)selectPreviousModem ;
	
	//  deprecated AppleScript support
	- (int)modemMode ;
	- (void)setModemMode:(int)interfaceMode ;
	- (int)pskModulation ;
	- (void)setPskModulation:(int)pskModulationType ;

	@end

#endif
