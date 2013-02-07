//
//  MFSKConfig.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on  2/15/06.
//

#ifndef _MFSKCONFIG_H_
	#define _MFSKCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "CMFIR.h"
	#include "CoreModemTypes.h"
	#include "ModemConfig.h"
	#include "Preferences.h"
	
	@class MFSK ;
	@class MFSKModulator ;
	
	@interface MFSKConfig : ModemConfig {
		IBOutlet id sidebandMenu ;
		IBOutlet id vfoOffset ;
		//  test tone
		IBOutlet id testFreq ;
		
		MFSKModulator *modulator ;
		MFSKModulator *idleTone ;
		float equalize ;
	}
	
	- (IBAction)testToneChanged:(id)sender ;
	- (IBAction)openEqualizer:(id)sender ;
	
	- (void)awakeFromModem:(MFSK*)modem ;
	
	- (Boolean)turnOnTransmission:(Boolean)state button:(NSButton*)button modulator:(MFSKModulator*)modulator ;
	- (Boolean)startTransmit:(MFSKModulator*)modulator ;
	- (Boolean)stopTransmit ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
		
	@end

#endif
