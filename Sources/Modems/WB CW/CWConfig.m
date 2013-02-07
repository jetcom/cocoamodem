//
//  CWConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Jan 11 06.
	#include "Copyright.h"
//

#import "CWConfig.h"
#import "ModemSource.h"
#import "Oscilloscope.h"
#import "PTT.h"
#import "VUMeter.h"

@implementation CWConfig

//  data arrived from input sound source
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


//	v0.87
//	tag =	0	J2A
//			1	OOK
//			2	OOK : digiKeyer
- (void)setCWKeyerMode:(int)tag ptt:(PTT*)ptt
{
	int mode ;
	
	mode = ( tag == 2 ) ? kMicrohamCWRouting : kMicrohamDigitalRouting ;	//  Fixed CW Routing (OOK digiKeyer) or Fixed Digital Routing otherwise.
	if ( ptt ) [ ptt setKeyerMode:mode ] ;
}



@end
