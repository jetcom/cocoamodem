//
//  DominoReceiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/23/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DominoReceiver.h"
#import "DominoDemodulator.h"
#import "MFSKModes.h"

//	Documentatation:
//
//	DominoEX implementation http://www.qsl.net/zl1bpu/DOMINO/Technical.htm
//  Domino Varicode http://www.qsl.net/zl1bpu/DOMINO/VaricodeEX.PDF
//	DominoEX modes http://www.qsl.net/zl1bpu/DOMINO/Index.htm
//	FEC Varicode	http://f6cte.free.fr/SPECIFICATIONS.ZIP

@implementation DominoReceiver

- (id)initAsMode:(int)mode
{
	float cutoff ;
	int taps ;
	
	self = [ super initReceiver ] ;
	if ( self ) {
		demodulator = [ [ DominoDemodulator alloc ] initAsMode:mode ] ;
		
		//	reference sampling rate is 16000 s/s
		switch (mode) {
		default:
		case DOMINOEX11:
			//  input decimation, 160 Hz filter to capture 320 Hz of real signal (28 channels at 10.766 Hz + keying sideband)
			actualSamplingRate = 11025.0 ;
			decimationRatio = ( CMFs/500.0 )*16000.0/11025 ;
			cutoff = 160.0 ;
			taps = 1536 ;
			break ;
		case DOMINOEX16:
			//  input decimation, 235 Hz filter to capture 470 Hz of real signal (28 channels at 15.625 Hz + keying sideband)
			actualSamplingRate = 16000.0 ;
			decimationRatio = CMFs/500.0 ;		
			cutoff = 235.0 ;
			taps = 2560 ;
			break ;
		case DOMINOEX22:
			actualSamplingRate = 22050.0 ;
			decimationRatio = ( CMFs/500.0 )*16000.0/22025 ;
			cutoff = 320.0 ;
			taps = 1536 ;
			break ;
		}
		iFilter = CMFIRLowpassFilter( cutoff, CMFs, taps ) ;
		qFilter = CMFIRLowpassFilter( cutoff, CMFs, taps ) ;
	}
	return self ;
}

//  the 125 Hz offset "centers" the 18 bands inside the 28 tuning bands for DominoEX 16.
- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)clicked
{
	if ( sidebandState ) {
		// USB
		receiveFrequency = freq + CARRIEROFFSET*actualSamplingRate/16000.0 ;
	}
	else {
		receiveFrequency = freq - CARRIEROFFSET*actualSamplingRate/16000.0 ;
	}
	[ vco setCarrier:receiveFrequency ] ;
	if ( clicked ) {
		// don't reset demodulator if it is a scroll wheel operation
		[ demodulator resetDemodulatorState ] ;
	}
}

@end
