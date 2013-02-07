//
//  FAXConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Mar 6 2006.
//

#ifndef _FAXCONFIG_H_
	#define _FAXCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "ModemConfig.h"
	#include "Preferences.h"
	#include "CMFIR.h"
	
	@class FAX ;
	@class Preferences ;
	
	@interface FAXConfig : ModemConfig {
		
		IBOutlet id sidebandMenu ;
		IBOutlet id vfoOffset ;
		IBOutlet id deviationCheckbox ;
		
		//  sound interface
		Boolean soundFileRunning ;
	}
	
	- (void)awakeFromModem:(FAX*)modem ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	@end

#endif
