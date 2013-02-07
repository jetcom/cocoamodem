//
//  DualRTTYConfig.m
//  cocoaModem
//
//  Created by Kok Chen on 9/11/05.
	#include "Copyright.h"
//

#import "DualRTTYConfig.h"
#include "DualRTTY.h"
#include "ModemDest.h"
#include "ModemSource.h"
#include "Oscilloscope.h"
#include "VUMeter.h"


@implementation DualRTTYConfig

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
