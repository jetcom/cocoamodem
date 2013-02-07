//
//  SITORDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/6/06.
	#include "Copyright.h"
//

#import "SITORDemodulator.h"

#import "MooreDecoder.h"
#import "SITORBitSync.h"
#import "SITORRxControl.h"


@implementation SITORDemodulator

//  replaces the RTTY ATC and Baudot decoder and with the SITOR-B bit sync and Moore decoder
- (void)initPipelineStages:(CMTonePair*)defaultTonePair decoder:(CMBaudotDecoder*)decoder atc:(CMPipe*)atc bandwidth:(float)bandwidth
{
	CMTonePair sitorTonePair = { 2125.0, 2295.0, 100.0 } ;
	
	[ decoder release ] ;
	[ atc release ] ;
	mooreDecoder = [ [ MooreDecoder alloc ] initWithDemodulator:self ] ;
	atc = [ [ SITORBitSync alloc ] init ] ;
	[ (SITORBitSync*)atc setMooreDecoder:(MooreDecoder*)mooreDecoder ] ;
	[ super initPipelineStages:&sitorTonePair decoder:mooreDecoder atc:atc bandwidth:425.0 ] ;
}

- (void)setControl:(SITORRxControl*)control
{
	if ( mooreDecoder ) [ mooreDecoder setControl:control ] ;
}

- (void)setErrorPrint:(Boolean)state
{
	[ mooreDecoder setErrorPrint:state ] ;
}

@end
