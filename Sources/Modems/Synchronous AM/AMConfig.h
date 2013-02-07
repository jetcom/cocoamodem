//
//  AMConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Jan 17 2007.
//

#ifndef _AMCONFIG_H_
	#define _AMCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#import "ModemConfig.h"
	#import "Preferences.h"
	#import "CMFIR.h"
	
	@class SynchAM ;
	@class Preferences ;
	@class AuralMonitor ;
	
	@interface AMConfig : ModemConfig {
		//  sound interface
		Boolean outputRunning ;
		Boolean soundFileRunning ;
		NSLock *outbufLock ;
		float outputBuffer[1024] ;
		
		//  v0.78
		AuralMonitor *auralMonitor ;
	}

	- (IBAction)openAuralMonitor:(id)sender ;
	
	- (void)awakeFromModem:(SynchAM*)modem ;
	
	- (void)setOutput:(float*)array samples:(int)n ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	@end

#endif
