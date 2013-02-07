//
//  PSKConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
//

#ifndef _PSKCONFIG_H_
	#define _PSKCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#import "ModemConfig.h"
	#import "Preferences.h"
	#import "CMFIR.h"
	
	@class PSK ;
	@class PSKAuralMonitor ;
	@class PSKModulator ;
	@class Preferences ;
	 
	@interface PSKConfig : ModemConfig {
		
		IBOutlet id sidebandMenu ;
		IBOutlet id vfoOffset ;
		//  test tone
		IBOutlet id testFreq ;	
		
		//  sound interface
		PSKModulator *pskModulator ;
		PSKModulator *idleTone ;
		Boolean soundFileRunning ;
		float equalize ;
	
		PSKAuralMonitor *auralMonitor ;		//  v0.78
		NSLock *overrun ;
	}
	
	- (IBAction)testToneChanged:(id)sender ;
	- (IBAction)openEqualizer:(id)sender ;
	
	- (void)awakeFromModem:(PSK*)modem ;
	
	//  state changes from PSK panel
	- (Boolean)turnOnTransmission:(Boolean)state button:(NSButton*)button mode:(int)mode ;
	- (void)setTransmitFrequency:(float)freq ;
	- (void)transmitCharacter:(int)acsii ;
	- (void)transmitDoubleByteCharacter:(int)first second:(int)second ;		//  v0.70
	- (void)flushTransmitBuffer ;
	
	- (void)updateDialOffset ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	//  AudioOutputPort callbacks
	- (void)setOutputScale:(float)value ;
	
	@end

#endif
