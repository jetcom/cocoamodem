//
//  VUMeter.m
//  cocoaModem
//
//  Created by Kok Chen on 1/31/05.
	#include "Copyright.h"
//

#import "VUMeter.h"
#include "modemTypes.h"


@implementation VUMeter

- (void)setup 
{
	int i, n ;
	float v ;
	
	overrunLock = [ [ NSLock alloc ] init ] ;
	//  VU meter
	vuOffColor = [ [ NSColor colorWithCalibratedRed:0.25 green:0.25 blue:0.25 alpha:1 ] retain ] ;
	for ( i = 0; i < 9; i++ ) {
		vu[i].segment = [ matrix cellAtRow:0 column:i ] ;
		vu[i].state = NO ;
		if ( i == 7 ) vu[i].onColor = [ NSColor colorWithCalibratedRed:0.9 green:0.9 blue:0 alpha:1 ] ;
		else if ( i == 8 ) vu[i].onColor = [ NSColor colorWithCalibratedRed:0.85 green:0 blue:0 alpha:1 ] ;
		else vu[i].onColor = [ NSColor colorWithCalibratedRed:0 green:0.7 blue:0 alpha:1 ] ;
		[ vu[i].onColor retain ] ;
		[ vu[i].segment setBackgroundColor:vuOffColor ] ;
	}
	
	//  red at -0.5 dBmax, yellow at -1.0 dBmax and then 3 dB per step below that
	for ( i = 0; i < 1416; i++ ) {
		v = i/1415.0 ;
		if ( v > 0.89 ) n = 9 ;
		else if ( v > 0.8 ) n = 8 ;
		else if ( v > 0.5656 ) n = 7 ;
		else if ( v > 0.4 ) n = 6 ;
		else if ( v > 0.2828 ) n = 5 ;
		else if ( v > 0.2 ) n = 4 ;
		else if ( v > 0.1414 ) n = 3 ;
		else if ( v > 0.1 ) n = 2 ;
		else if ( v > 0.0707 ) n = 1 ; else n = 0 ;		
		vuSegmentTable[i] = n ;
	}
	vuLevel = 0.0 ;
}

//  sets the color of each VU meter segment
//  NOTE:  this is executed in the main thread from -importData
- (void)importDataInMainThread:(CMPipe*)pipe
{
	int i, n, index ;
	float v, *array ;
	VUElement *vi ;
	Boolean hasChange ;
	
	if ( [ overrunLock tryLock ] ) {
		array = [ pipe stream ]->array ;	
		//  sample about 20ms of data for amplitude
		for ( i = 0; i < 30; i++ ) {
			v = array[i] ;
			if ( v < 0 ) v = -v ;
			if ( v > vuLevel ) vuLevel = v ; else vuLevel = vuLevel*0.998 + v*0.002 ;
		}
		
		index = vuLevel*1414.2 ;
		if ( index > 1415 ) index = 1415 ;
		n = vuSegmentTable[index] ;
		
		hasChange = NO ;
		for ( i = 0; i < 9 ; i++ ) {
			vi = &vu[i] ;
			if ( n >= (i+1) ) {
				if ( vi->state == NO ) {
					[ vi->segment setBackgroundColor:vi->onColor ] ;
					vi->state = YES ;
					hasChange = YES ;
				}
			}
			else {
				if ( vi->state == YES ) {
					[ vi->segment setBackgroundColor:vuOffColor ] ;
					vi->state = NO ;
					hasChange = YES ;
				}
			}
		}
		if ( hasChange ) [ matrix display ] ;		//  v0.73 changed from setNeedsDisplay
		[ overrunLock unlock ] ;
	}
}

- (void)importData:(CMPipe*)pipe
{
	[ self performSelectorOnMainThread:@selector(importDataInMainThread:) withObject:pipe waitUntilDone:NO ] ;
}


@end
