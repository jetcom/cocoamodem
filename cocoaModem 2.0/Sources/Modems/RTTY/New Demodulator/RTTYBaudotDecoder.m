//
//  RTTYBaudotDecoder.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/21/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "RTTYBaudotDecoder.h"
#import "RTTYDemodulator.h"
#import <Baudot.h>


@implementation RTTYBaudotDecoder

- (id)initWithDemodulator:(CMFSKDemodulator*)rx
{
	self = [ super initWithDemodulator:rx ] ;
	if ( self ) {
		printControl = NO ;
	}
	return self ;
}

- (void)setPrintControl:(Boolean)state
{
	printControl = state ;
}

- (void)sendString:(char*)s
{
	int c ;
	
	while ( 1 ) {
		c = *s++ ;
		if ( c == 0 ) return ;
		[ demodulator receivedCharacter:c ] ;
	}
}

//  Baudot decoder -- receives character data from ATC (see [ atc setClient... ] in setupReceiverChain of RTTYReceiver)
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *d ;
	int b, c ;
	
	d = [ pipe stream ] ;
	b = d->userData ;
	
	if ( printControl ) {
		switch ( b ) {
		case 0x00:
			[ self sendString:"<null>" ] ;
			break ;
		case 0x02:
			[ self sendString:"<lf>" ] ;
			break ;
		case 0x08:
			[ self sendString:"<cr>" ] ;
			break ;
		case CMFIGSCODE:
			[ self sendString:"<figs>" ] ;
			break ;
		case CMLTRSCODE:
			[ self sendString:"<ltrs>" ] ;
			break ;
		}
	}
	c = ( b < 0 ) ? '~' : encoding[ b ] ;
	
	if ( c == '*' ) {
		switch ( b ) {
		case 0x05:
			if ( bell ) NSBeep() ;
			return ;
		case 0x00:
			// null
			return ;
		case CMFIGSCODE:
			encoding = CMFigs ;
			return ;
		case CMLTRSCODE:
			encoding = CMLtrs ;
			return ;
		}
	}
	
	//  check for cr/lf pairs	
	if ( c == '\r' ) {
		if ( lf ) {
			lf = NO ;
			return ;
		}
		if ( cr ) /* ignore multiple c/r */ return ;
		c = '\n' ;
		cr = YES ;
		lf = NO ;
	}
	else {
		if ( c == '\n' ) {
			if ( cr ) {
				cr = NO ;
				return ;
			}
			lf = YES ;
			cr = NO ;
		}
		else cr = lf = NO ;
	}
	[ demodulator receivedCharacter:c ];
	//  unshift on space
	if ( c == ' ' && usos ) encoding = CMLtrs ;
}

@end
