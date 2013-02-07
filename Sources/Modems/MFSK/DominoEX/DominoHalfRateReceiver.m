//
//  DominoHalfRateReceiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/3/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DominoHalfRateReceiver.h"
#import "DominoHalfRateDemodulator.h"
#import "MFSKModes.h"


@implementation DominoHalfRateReceiver

- (id)initAsMode:(int)mode
{
	float cutoff ;
	
	self = [ super init ] ;
	if ( self ) {
		enabled = NO ;
		sidebandState = YES ;
		demodulator = [ [ DominoHalfRateDemodulator alloc ] initAsMode:mode ] ;
			
		//  set up VCO at tone's frequency
		receiveFrequency = 972.0 + CARRIEROFFSET ;
		vco = [ [ CMPCO alloc ] init ] ;
		[ vco setCarrier:receiveFrequency ] ;
		
		//  click buffer
		[ self createClickBuffer ] ;
		
		//	reference sampling rate is 16000 s/s
		switch (mode) {
		default:
		case DOMINOEX4:
			//  input decimation, 120 Hz filter to capture 230 Hz of real signal (28 channels at 7.8125 Hz + keying sideband)
			actualSamplingRate = 8000.0 ;
			decimationRatio = ( CMFs/500.0 )*16000.0/8000 ;		
			cutoff = 120.0 ;
			break ;
		case DOMINOEX5:
			//  input decimation, 160 Hz filter to capture 320 Hz of real signal (28 channels at 10.766 Hz + keying sideband)
			actualSamplingRate = 11025.0 ;
			decimationRatio = ( CMFs/500.0 )*16000.0/11025 ;		
			cutoff = 160.0 ;
			break ;
		case DOMINOEX8:
			//  input decimation, 235 Hz filter to capture 470 Hz of real signal (28 channels at 15.625 Hz + keying sideband)
			actualSamplingRate = 16000.0 ;
			decimationRatio = CMFs/500.0 ;		
			cutoff = 235.0 ;
			break ;
		}
		nextSample = 150 ;
		outputIndex = 0 ;
		iFilter = CMFIRLowpassFilter( cutoff, CMFs, 1024 ) ;
		qFilter = CMFIRLowpassFilter( cutoff, CMFs, 1024 ) ;
	}
	return self ;
}

@end
