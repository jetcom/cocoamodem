//
//  ModemEqualizer.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/29/06.

#ifndef _MODEMEQUALIZER_H_
	#define _MODEMEQUALIZER_H_

	#import <Cocoa/Cocoa.h>

	@class Preferences ;
	
	@interface ModemEqualizer : NSWindow {
		IBOutlet id view ;
		IBOutlet id power ;
		IBOutlet id plot ;

		NSString *deviceName ;
		float response[15] ;				// 0 to 2.8 kHz in 200 Hz steps
		float interpolated[113] ;			// 0 to 2.8 kHz in 25 Hz steps
		
		NSWindow *controllingWindow ;
	}

	- (IBAction)done:(id)sender ;
	- (IBAction)responseUpdated:(id)sender ;

	- (float)amplitude:(float)frequency ;
	
	- (id)initSheetFor:(NSString*)name ;
	- (void)showMacroSheetIn:(NSWindow*)window ;
	
	- (void)setFlatResponse ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (void)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	@end

#endif
