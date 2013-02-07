//
//  AppDelegate.h
//  cocoaModem
//
//  Created by Kok Chen on 7/26/05.
//	Renamed from AESupport.m 10/4/09.
	#include "Copyright.h"
//

#ifndef _APPDELEGATE_H_
	#define _APPDELEGATE_H_
	
	#import <Cocoa/Cocoa.h>
	#import "CoreFilterTypes.h"
	
	@class Application ;
	@class AudioManager ;
	@class AuralMonitor ;
	@class Modem ;
	@class ModemManager ;
	@class QSO ;
	@class StdManager ;

	
	@interface AppDelegate : NSScriptCommand {
		Application *application ;
		StdManager *stdManager ;
		
		Boolean windowIsVisible ;
		Boolean isLite ;
	}
	
	- (int)appLevel ;

	- (id)initFromApplication:(Application*)app ;
	- (Application*)application ;
	- (AuralMonitor*)auralMonitor ;
	- (AudioManager*)audioManager ;
	
	- (Boolean)isLite ;
	- (void)setIsLite:(Boolean)state ;
	- (Boolean)windowIsVisible ;
	- (void)setWindowIsVisible:(Boolean)state ;

	// Classes
	- (ModemManager*)interactiveInterface ;
	- (ModemManager*)contestInterface ;
	//  watchdog timer
	- (ModemManager*)watchdogTimer ;
	
	- (Modem*)rttyModem ;
	- (Modem*)pskModem ;
	- (Modem*)hellModem ;
	- (Modem*)dualRTTYModem ;
	- (Modem*)widebandRTTYModem ;
	- (Modem*)cwModem ;
	- (Modem*)mfskModem ;
	
	- (QSO*)qso ;
	- (NSString*)modemName ;
	
	- (int)scriptVersion ;
	- (NSString*)version ;
	
	//  show/hide main window
	- (Boolean)windowState ;
	- (void)setWindowState:(Boolean)state ;
	//  window position
	- (NSAppleEventDescriptor*)windowPosition ;
	- (void)setWindowPosition:(NSAppleEventDescriptor*)point ;
	
	// deprecated AppleScripts
	- (int)modemMode ;
	- (void)setModemMode:(int)interfaceMode ;
	- (int)pskModulation ;
	- (void)setPskModulation:(int)pskModulationType ;
	- (NSString*)qsoCall ;
	- (void)setQsoCall:(NSString*)setstring ;
	- (NSString*)qsoName ;
	- (void)setQsoName:(NSString*)setstring ;
	- (NSString*)pskRxAOffset ;
	- (void)setPskRxAOffset:(NSString*)freq ;
	- (NSString*)pskTxAOffset ;
	- (void)setPskTxAOffset:(NSString*)freq ;
	- (NSString*)pskRxBOffset ;
	- (void)setPskRxBOffset:(NSString*)freq ;
	- (NSString*)pskTxBOffset ;
	- (void)setPskTxBOffset:(NSString*)freq ;
		
	@end

#endif
