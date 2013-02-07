//
//  ASCIIModulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/30/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCIIModulator.h"


@implementation ASCIIModulator


- (void)initSetup
{
	int i ;
	CMTonePair tonepair = { 2125.0, 2295.0, 110.0 } ;

	usos = NO ;
	shifted = robust = NO ;
	sideband = 0 ;
	robustCount = 0 ;
	bitsPerCharacter = 7 ;
	[ self setTonePair:&tonepair ] ;
	[ self setStopBits:2.0 ] ;
	for ( i = 0; i < 256; i++ ) mapping[i] = i ;  // set the encoding table to ASCII-to-ASCII mapping
}

//	(Private API)
//	in ASCIIModulator, -appendBits appends ASCII bits
- (void)appendBits:(int)code ascii:(int)ascii
{
	int i, tempProducer ;
	
	shifted = NO ;
	tempProducer = producer ;
	stream[tempProducer] = startBit ;
	stream[tempProducer].character = ascii ;
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	for ( i = 0; i < bitsPerCharacter; i++ ) {
		stream[tempProducer] = dataBit[code&1] ;
		tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
		code >>= 1 ;  // next bit of ASCII character
	}
	stream[tempProducer] = stopBit ;
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	producer = tempProducer ;	
}

//  (Private API)
//  append diddle (0x7f or 0xff)
- (void)appendDiddle:(int)flag
{
	int i, diddle, tempProducer ;
	
	diddle = 0xff ;
	[ lock lock ] ;
	shifted = NO ;
	tempProducer = producer ;
	stream[tempProducer] = startBit ;
	stream[tempProducer].character = flag ;			// flag for special diddle character that returns data to RTTY object
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	for ( i = 0; i < bitsPerCharacter; i++ ) {
		stream[tempProducer] = dataBit[diddle&1];
		tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
		diddle >>= 1 ; // next bit of diddle character
	}
	stream[tempProducer] = stopBit ;
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	producer = tempProducer ;
	[ lock unlock ] ;
}

//  unmap phi to zero
static int unmap( int d )
{
	if ( d == 216 || d == 175 ) return '0' ;
	d &= 0x7f ;
	return d ;
}

//  append a single ascii character
- (void)appendASCII:(int)ascii
{
	int code, echo ;
	
	ascii = unmap( ascii ) ;			// this will unmap any phi into zero and also map '\n' into '\r'

	if ( ascii <= 26 ) {
		//  control characters
		switch ( 'a'+ascii-1 ) {
		case 'e':
			[ self appendDiddle:0 ] ;
			[ self appendDiddle:ascii ] ;
			return ;
		case 'z':
			[ self appendDiddle:ascii ] ;
			return ;
		}
	}
	echo = ascii ;
	
	switch ( ascii ) {
	case '|':
		/* long mark character */
		[ self appendLongMark ] ;
		return ;
	default:
		if ( ascii == '\n' ) {
			//  transmit newline from textview as CR
			ascii = '\r' ;
			echo = 0 ;
		}
		code = mapping[ ascii ] ;		// ASCII to ASCII map
		break ;
	}
	if ( code != 0 ) {
		[ lock lock ] ;
		[ self appendBits:( code & 0xff ) ascii:echo ] ;		//  send 8 bit ASCII and let appenBits shorten it if needed to 7 bits
		if ( ascii == '\r' ) {
			//  send \n from text view as cr/lf pair
			[ self appendBits:( mapping['\n'] & 0x1f ) ascii:'\n' ] ;
		}
		[ lock unlock ] ;
	}
}

@end
