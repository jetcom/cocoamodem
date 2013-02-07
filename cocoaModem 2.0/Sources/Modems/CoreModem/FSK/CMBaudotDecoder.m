//
//  CMBaudotDecoder.m
//  CoreModem
//
//  Created by Kok Chen on 10/24/05.
//	(ported from cocoaModem, original file dated Fri Jul 16 2004)
	#include "Copyright.h"

#import "CMBaudotDecoder.h"
#import "CMFSKDemodulator.h"
#import "CMBaudot.h"


@implementation CMBaudotDecoder

- (id)initWithDemodulator:(CMFSKDemodulator*)rx
{
	self = [ super init ] ;
	if ( self ) {
		demodulator = rx ;
		encoding = CMLtrs ;
		cr = lf = usos = bell = NO ;
	}
	return self ;
}

- (void)setLTRS
{
	encoding = CMLtrs ;
}

//  Baudot decoder -- receives character data from ATC (see [ atc setClient... ] in setupReceiverChain of RTTYReceiver)
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *d ;
	int b, c ;
	
	d = [ pipe stream ] ;
	b = d->userData ;
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

//  USOS state passed in from CMFSKDemodulator
- (void)setUSOS:(Boolean)state
{
	usos = state ;
}

- (void)setBell:(Boolean)state
{
	bell = state ;
}

@end
