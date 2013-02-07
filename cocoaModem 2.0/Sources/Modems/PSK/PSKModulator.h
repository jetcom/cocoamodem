//
//  PSKModulator.h
//  cocoaModem
//
//  Created by Kok Chen on Mon Aug 09 2004.
//

#import <Cocoa/Cocoa.h>
#import "CMPSKModulator.h"
#import "CMFIR.h"

@class Modem ;

#define	ASCIINULL		0x10000			//  v0.70 use when null is inserted in the modulated stream, to distinuish from 0

@interface PSKModulator : CMPSKModulator {
	Modem *modem ;
	CMFIR *basebandFilter, *basebandFilter63, *basebandFilter125 ;
	Boolean psk125 ;
}

- (void)appendDoubleByte:(int)first second:(int)second ;		//  v0.70
- (void)setModemClient:(Modem*)client ; 
- (void)resetModulatorAndFlush ;								//  v0.44

@end
