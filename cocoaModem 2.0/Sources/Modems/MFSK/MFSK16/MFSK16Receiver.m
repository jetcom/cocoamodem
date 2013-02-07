//
//  MFSK16Receiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/16/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSK16Receiver.h"
#import "MFSK16Demodulator.h"

@implementation MFSK16Receiver

- (id)init
{
	self = [ super initReceiver ] ;
	if ( self ) {
		demodulator = [ [ MFSK16Demodulator alloc ] init ] ;
		//  input decimation
		decimationRatio = CMFs/500.0 ;
		iFilter = CMFIRLowpassFilter( 210, CMFs, 512 ) ;
		qFilter = CMFIRLowpassFilter( 210, CMFs, 512 ) ;
	}
	return self ;
}

@end
