//
//  RTTYMixer.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/8/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "RTTYMixer.h"
#import "RTTYAuralMonitor.h"

@implementation RTTYMixer

- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *array ;

	[ super importData:pipe ] ;

	if ( auralMonitor ) {
		stream = [ pipe stream ] ;
		array = stream->array ;
		[ auralMonitor newBandpassFilteredData:array scale:1.0 fromReceiver:YES ] ;
	}
}

- (void)setTonePair:(const CMTonePair*)tonepair
{
	[ super setTonePair:tonepair ] ;
	if ( auralMonitor ) [ auralMonitor setTonePair:tonepair ] ;
}

- (void)tonePairSelectedFromMemory:(const CMTonePair*)tonepair
{
}


@end
