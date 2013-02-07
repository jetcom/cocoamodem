//
//  PTT.h
//  cocoaPTT
//
//  Created by Kok Chen on 2/26/06.

#ifndef _PTT_H_
	#define _PTT_H_

	#import <Cocoa/Cocoa.h>
	#include "PTTDevice.h"


	@interface PTT : NSObject {
		IBOutlet id window ;
		IBOutlet id prefPanel ;
		IBOutlet id keyButton ;
		IBOutlet id keyLight ;
		
		IBOutlet id serialPortMenu ;
		IBOutlet id activePrefMatrix ;
		IBOutlet id rtsPrefMatrix ;
		IBOutlet id disableReadCheckbox ;
		
		int useRTS ;					//  0 - use DTR, 1 - use RTS, 2 use both
		Boolean activeHigh ;
		Boolean allowRead ;
		
		NSMutableDictionary *prefs ;
		NSString *plistPath ;
		
		NSString *stream[32] ;
		NSString *path[32] ;
		PTTDevice *ptt ;
		int ports ;
	}
	
	- (IBAction)openPref:(id)sender ;
	- (IBAction)openControl:(id)sender ;
	
	- (int)findPorts ;
	
	- (void)alertMessage:(NSString*)msg informativeText:(NSString*)info ;
	
	- (Boolean)setKey ;
	- (Boolean)setUnkey ;
	
	//  AppleScript
	- (int)keyState ;
	- (void)setKeyState:(int)state ;


	@end

#endif
