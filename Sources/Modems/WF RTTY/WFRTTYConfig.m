//
//  WFRTTYConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Jan 11 06.
	#include "Copyright.h"
//

#import "WFRTTYConfig.h"
#include "WFRTTY.h"
#include "ModemDest.h"
#include "ModemSource.h"
#include "Oscilloscope.h"
#include "Plist.h"
#include "RTTYRxControl.h"
#include "VUMeter.h"

@implementation WFRTTYConfig

- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control txConfig:(RTTYTxConfig*)inTxConfig
{
	[ super awakeFromModem:set rttyRxControl:control txConfig:inTxConfig ] ;
	[ self setInterface:vfoOffsetField to:@selector(vfoOffsetChanged) ] ;	
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
	if ( [ overrun tryLock ] ) {
		if ( interfaceVisible ) {
			if ( ( isActiveButton && !isTransmit ) || [ modemSource fileRunning ] ) {
				*data = *[ pipe stream ] ;
				[ self exportData ] ;
				[ vuMeter importData:pipe ] ;
			}
			if ( configOpen && oscilloscope ) {
				[ oscilloscope addData:[ pipe stream ] isBaudot:NO timebase:1 ] ;
			}
		}
		[ overrun unlock ] ;
	}
}

- (void)setChannel:(int)n
{
	channel = n ;
}

- (void)vfoOffsetChanged
{
	[ modemRxControl setWaterfallOffset:[ vfoOffsetField floatValue ] ] ;
}

- (void)setupDefaultPreferences:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	[ super setupDefaultPreferences:pref rttyRxControl:control ] ;
	[ pref setFloat:0.0 forKey:configSet.vfoOffset ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control 
{
	[ super updateFromPlist:pref rttyRxControl:control ] ;	
	[ vfoOffsetField setIntValue:[ pref floatValueForKey:configSet.vfoOffset ] ] ;
	[ self vfoOffsetChanged ] ;
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	[ super retrieveForPlist:pref rttyRxControl:control ] ;	
	[ pref setFloat:[ vfoOffsetField floatValue ] forKey:configSet.vfoOffset ] ;
}


@end
