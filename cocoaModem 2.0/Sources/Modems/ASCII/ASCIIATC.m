//
//  ASCIIATC.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/29/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCIIATC.h"
#import "CMATCBuffer.h"

@implementation ASCIIATC

- (id)init
{
	float g ;
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		//  set up bitsync type DataStream
		data = &bitStream ;
		bitStream.array = &syncedData[0] ;
		bitStream.samples = 256 ;
		bitStream.components = bitStream.channels = 1 ;
		
		//  7 bits ASCII
		bitsPerCharacter = 7 ;
		[ self setBitSamplingFromBaudRate:110.0 ] ;
		
		//  note: stopBit must be < 500
		invert = NO ;
		offset = 256 ;
		
		[ self setEqualize:0 ] ;
		memset( input.data, 0, sizeof( CMATCPair )*768 ) ;
		for (i = 0; i < 3; i++ ) {
			memset( agc[i].data, 0, sizeof( CMATCPair )*768 ) ;
			agc[i].markAGC = agc[i].spaceAGC = 0 ;
		}		
		//  alpha^n = 1/2.71828, where n is in steps of Fs/8
		//  first set of AGC constants (1/100) is often encountered
		g = 8.0/CMFs ;
		agc[0].attack = exp( -g/0.0005 ) ;		//  0.5 ms attack time constant
		agc[0].decay = exp( -g/0.120 ) ;		//  120 ms decay time constant
		agc[1].attack = exp( -g/0.001) ;		//  1 ms attack time constant
		agc[1].decay = exp( -g/0.200 ) ;		//  200 ms decay time constant
		agc[2].attack = exp( -g/0.002 ) ;		//  2 ms attack time constant
		agc[2].decay = exp( -g/0.600 ) ;		//  600 ms decay time constant
		
		atcCase[0].startingIndex = 0; atcCase[0].endingIndex = 1 ; atcCase[0].eq = 0 ;
		atcCase[1].startingIndex = 1; atcCase[1].endingIndex = 2 ; atcCase[1].eq = 0 ;
		atcCase[2].startingIndex = 0; atcCase[2].endingIndex = 1 ; atcCase[2].eq = 1 ;
		atcCase[3].startingIndex = 1; atcCase[3].endingIndex = 2 ; atcCase[3].eq = -1 ;
		atcCase[4].startingIndex = 0; atcCase[4].endingIndex = 1 ; atcCase[4].eq = 2 ;
		atcCase[5].startingIndex = 1; atcCase[5].endingIndex = 2 ; atcCase[5].eq = -2 ;
		atcBuffer = [ [ CMATCBuffer alloc ] init ] ;
	}
	return self ;
}

- (void)setBitsPerCharacter:(int)bits
{
	[ super setBitsPerCharacter:bits ] ;
	[ self setBitSamplingFromBaudRate:bitStream.samplingRate ] ;
}

@end
