//
//  ASCIIDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/29/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCIIDemodulator.h"
#import "ASCIIATC.h"
#import "ASCIIDecoder.h"
#import "ASCIIReceiver.h"
#import "CMFSKMixer.h"
#import "RTTYMatchedFilter.h"
#import "CMFSKTypes.h"


@implementation ASCIIDemodulator

- (id)initFromReceiver:(RTTYReceiver*)rcvr
{
	CMTonePair defaultTonePair = { 2125.0, 2295.0, 110.0 } ;
	CMATC *atc ;

	self = [ super init ] ;
	if ( self ) {
		isRTTY = YES ;
		delegate = nil ;
		receiver = rcvr ;
		decoder = [ [ ASCIIDecoder alloc ] initWithDemodulator:self ] ;
		atc = [ [ ASCIIATC alloc ] init ] ;
		[ self initPipelineStages:&defaultTonePair decoder:decoder atc:atc bandwidth:500.0 ] ;
	}
	return self ;
}

//  aways keep USOS off
- (void)setUSOS:(Boolean)state
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;

	if ( p != nil ) [ p->decoder setUSOS:NO ] ;
}

- (void)setLTRS:(Boolean)state
{
	//  do nothing in ASCII mode
}

@end
