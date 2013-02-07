//
//  RTTYConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Mon May 17 2004.
//

#ifndef _RTTYCONFIG_H_
	#define _RTTYCONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "CMFIR.h"
	#include "CoreModemTypes.h"
	#include "ModemConfig.h"
	#include "Preferences.h"
	#include "RTTYTypes.h"
	
	
	@class FSK ;
	@class RTTYRxControl ;
	@class RTTYTxConfig ;
	
	@interface RTTYConfig : ModemConfig {

		IBOutlet id prefMatrix ;				// NSArray of checkboxes
		IBOutlet id sidebandMenu ;
		IBOutlet id afskMenu ;

		RTTYRxControl *modemRxControl ;
		RTTYConfigSet configSet ;
		RTTYTxConfig *txConfig ;
		FSK *fsk ;
		
		NSString *preferredAFSKMenuTitle ;
		NSString *actualAFSKMenuTitle ;
		
		int prefVersion ;
		
		NSLock *overrun ;
	}
	
	- (RTTYConfigSet*)configSet ;
	- (NSPopUpButton*)sidebandMenu ;
	- (NSPopUpButton*)afskMenu ;
	- (FSK*)fsk ;
	- (int)ook ;					//  v0.85  0 = afsk/fsk, 1 = space only, 2 = mark only
	
	- (RTTYTxConfig*)txConfig ;		//  v0.67
	
	- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control txConfig:(RTTYTxConfig*)inTxConfig ;
	
	- (void)txTonePairChanged:(RTTYRxControl*)control ;
	- (void)setTonePairMarker:(const CMTonePair*)tonepair ;	
	
	- (void)updateColorsFromPreferences:(Preferences*)pref configSet:(RTTYConfigSet*)set ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control ;
	- (Boolean)updateFromPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control ;
	- (void)retrieveForPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control ;
	
	
	@end

#endif
