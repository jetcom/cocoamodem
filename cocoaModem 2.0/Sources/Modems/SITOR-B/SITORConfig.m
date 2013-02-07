//
//  SITORConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Feb 6 06.
	#include "Copyright.h"
//

#import "SITORConfig.h"
#import "SITOR.h"
#import "ModemSource.h"
#import "Oscilloscope.h"
#import "Plist.h"
#import "RTTYRxControl.h"
#import "VUMeter.h"


@implementation SITORConfig

- (void)openPanel
{
	[ window center ] ;
	[ window orderFront:self ] ;
	//  set modem as delegate of config's window to catch closes
	[ window setDelegate:modemObj ] ;
	configOpen = YES ;
	[ self updateInputSamplingState ] ;
}

- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control txConfig:(RTTYTxConfig*)inTxConfig
{
	[ super awakeFromModem:set rttyRxControl:control txConfig:nil ] ;
	[ self setInterface:vfoOffsetField to:@selector(vfoOffsetChanged) ] ;	
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
	if ( ( ( isActiveButton && !isTransmit ) || [ modemSource fileRunning ] ) && interfaceVisible ) {
		*data = *[ pipe stream ] ;
		[ self exportData ] ;
		[ vuMeter importData:pipe ] ;
	}
	if ( configOpen && oscilloscope ) {
		[ oscilloscope addData:[ pipe stream ] isBaudot:NO timebase:1 ] ;
	}
}

@end
