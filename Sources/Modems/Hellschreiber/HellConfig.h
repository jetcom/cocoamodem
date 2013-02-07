//
//  HellConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Wed Jul 27 2005.
//

#ifndef _HELLCONFIG_H_
	#define _HELLCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "ModemConfig.h"
	#include "Preferences.h"
	#include "CMFIR.h"
	#include "HellModulator.h"
	#include "HellschreiberFont.h"
	
	@class Hellschreiber ;
	@class Preferences ;
	
	@interface HellConfig : ModemConfig {
		
		IBOutlet id sidebandMenu ;
		IBOutlet id vfoOffset ;
		//  test tone
		IBOutlet id testFreq ;
		// Hellschreiber diddle
		IBOutlet id diddleButton ;	
		
		//  sound interface
		HellModulator *hellModulator ;
		HellModulator *idleTone ;
		Boolean soundFileRunning ;
		float equalize ;
		
		//  fonts
		int fonts ;
		HellschreiberFontHeader *font[10] ;

	}
	
	- (IBAction)testToneChanged:(id)sender ;
	- (IBAction)openEqualizer:(id)sender ;

	- (NSPopUpButton*)sidebandMenu ;
	
	- (void)awakeFromModem:(Hellschreiber*)modem ;
	
	//  state changes from Hellschreiber panel
	- (Boolean)turnOnTransmission:(Boolean)state button:(NSButton*)button ;
	- (void)transmitCharacter:(int)acsii ;
	- (void)flushTransmitBuffer ;
	- (void)setMode:(int)mode ;
	
	- (void)updateDialOffset ;
	- (void)selectFont:(int)index ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	//  AudioOutputPort callbacks
	- (void)setOutputScale:(float)value ;
	
	@end

#endif
