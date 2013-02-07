//
//  CMFSKModulator.m
//  CoreModem
//
//  Created by Kok Chen on 10/31/05.
	#include "Copyright.h"
//

#import "CMFSKModulator.h"
#import "Application.h"
#import "CoreModemTypes.h"
#import "CMBaudot.h"
#import "FSKHub.h"

#define kRobustThreshold	16

@implementation CMFSKModulator

- (id)init
{
	int i, ltr, fig ;
	CMTonePair tonepair = { 2125.0, 2295.0, 45.45 } ;
	
	self = [ super init ] ;
	if ( self ) {
		delegate = nil ;
		producer = consumer = 0 ;
		usos = YES ;
		shifted = LTRSTATE ;
		spaceFollowedFIGS = NO ;		//  v0.88
		robust = NO ;
		robustCount = 0 ;
		sideband = 0 ;
		bitsPerCharacter = 5 ;
		[ self setTonePair:&tonepair ] ;
		[ self setStopBits:1.5 ] ;
		//  create ascii to baudot translation
		//  LSB 5 bits is the baudot code, LTRSHIFT and FIGSHIFT are the flag bits
		for ( i = 0; i < 128; i++ ) mapping[i] = 0 ;  // fill with Baudot blank
		for ( i = 0; i < 32; i++ ) {
			ltr = CMLtrs[i] ;
			fig = CMFigs[i] ;
			if ( ltr == fig && ltr != 0 && ltr != '*' ) {
				mapping[ltr] = i | CMLTRSHIFT | CMFIGSHIFT ;
			}
			else {
				if ( ltr != 0 && ltr != '*' ) {
					mapping[ltr] = i | CMLTRSHIFT ;
					if ( ltr >= 'A' && ltr <= 'Z' ) mapping[ ltr -'A'+'a' ] = i | CMLTRSHIFT ;
				}
				if ( fig != 0 && fig != '*' ) {
					mapping[fig] = i | CMFIGSHIFT ;
				}
			}
		}
	}
	return self ;
}

//  Rest condition = Mark.  startbit = 0 = space, stop bit = 1 = mark
- (void)setTonePair:(const CMTonePair*)inTonePair
{
	CMTonePair tonepair ;
	double t ;
	
	tonepair = *inTonePair ;
	
	if ( sideband != 0 ) {
		t = tonepair.mark ;
		tonepair.mark = tonepair.space ;
		tonepair.space = t ;
	}
	tonePair.mark = tonepair.mark*kPeriod/CMFs ;
	tonePair.space = tonepair.space*kPeriod/CMFs ;
	bitDDA = tonepair.baud*kPeriod/CMFs ;

	current = tonePair.mark ;
	currentBitDDA = bitDDA ;
	
	startBit.dda = bitDDA ;
	startBit.polarity = 0 ;
	startBit.character = 0 ;
	dataBit[0].dda = bitDDA ;
	dataBit[0].polarity = 0 ;
	dataBit[0].character = 0 ;
	dataBit[1].dda = bitDDA ;
	dataBit[1].polarity = 1 ;
	dataBit[1].character = 0 ;
	[ self setStopBits:stopDuration ] ;
}

//  Stop bits (defaulted to 1.5 by init)
- (void)setStopBits:(float)stopBits
{
	//  sanity check
	if ( stopBits < 0.99 || stopBits > 2.01 ) return ;
	
	stopDuration = stopBits ;
	stopDDA = bitDDA/stopDuration ;
	stopBit.dda = stopDDA ;
	stopBit.polarity = 1 ;
	stopBit.character = 0 ;
}

- (void)setSideband:(int)usb
{
	sideband = usb ;
}

- (void)setUSOS:(Boolean)state
{
	usos = state ;
}

- (void)setRobustMode:(Boolean)state
{
	robust = state ;
	[ [ [ [ NSApp delegate ] application ] fskHub ] setRobustMode:robust ] ;
}

- (void)setBitsPerCharacter:(int)bits 
{
	bitsPerCharacter = bits ;
}

//  append a long mark tone (11 bits long, with no start bit)
- (void)appendLongMark
{
	stream[producer] = stopBit ;
	stream[producer].dda /= 11.0 ;
	producer = ( producer+1 )&CMSTREAMMASK ;
}

/* local */
//  append diddle (LTRS)
- (void)appendDiddle:(int)flag
{
	int i, diddle, tempProducer ;
	
	diddle = CMLTRSCODE ;
	[ lock lock ] ;
	shifted = LTRSTATE ;
	tempProducer = producer ;
	stream[tempProducer] = startBit ;
	stream[tempProducer].character = flag ;			// flag for special diddle character that returns data to RTTY object
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	for ( i = 0; i < 5; i++ ) {
		stream[tempProducer] = dataBit[diddle&1];
		tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
		diddle >>= 1 ; // next bit of diddle character
	}
	stream[tempProducer] = stopBit ;
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	producer = tempProducer ;
	[ lock unlock ] ;
}

//  (Private API)
- (void)appendBits:(int)code ascii:(int)ascii
{
	int i, tempProducer ;
	
	tempProducer = producer ;
	stream[tempProducer] = startBit ;
	stream[tempProducer].character = ascii ;
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	for ( i = 0; i < 5; i++ ) {
		stream[tempProducer] = dataBit[code&1] ;
		tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
		code >>= 1 ;  // next bit of Baudot character
	}
	stream[tempProducer] = stopBit ;
	tempProducer = ( tempProducer+1 )&CMSTREAMMASK ;
	producer = tempProducer ;	
}

//  v0.88 consolidate shift here
- (void)shiftToState:(Boolean)state
{
	[ self appendBits:( ( state == FIGSTATE ) ? CMFIGSCODE : CMLTRSCODE ) ascii:0 ] ;
	shifted = state ;				
	robustCount = 0 ;			
}

//  append a single ascii character
- (void)appendASCII:(int)ascii
{
	int code, echo ;
	
	//  direct LTRS/FIGS output (v0.88 added here from RTTYModulatorBase, but apparently unused?)
	if ( ascii == CMLTRSCODE || ascii == CMFIGSCODE ) {
		[ lock lock ] ;
		[ self shiftToState:( ascii == CMFIGSCODE ) ] ;
		[ lock unlock ] ;
		return ;
	}

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
	case '=':
		/* LTRS */
		code = CMLTRSCODE|CMLTRSHIFT ;
		ascii = 0 ;
		break ;
	case '|':
		/* long mark character */
		[ self appendLongMark ] ;
		[ self appendBits:CMLTRSCODE ascii:0 ] ;
		[ self appendBits:CMLTRSCODE ascii:0 ] ;
		return ;
	default:
		if ( ascii == '\n' ) {
			//  transmit newline from textview as CR
			ascii = '\r' ;
			echo = 0 ;
		}
		code = mapping[ ascii ] ;				// ASCII to Baudot map
		break ;
	}
	
	if ( code != 0 ) {
	
		if ( robust ) robustCount++ ;

		[ lock lock ] ;

		if ( spaceFollowedFIGS ) {
		
			if ( robust == YES ) {
			
					//  check if we need to force a LTRS shift (for USOS) or FIGS shift (for non-USOS)
				if ( usos == YES ) {
					//  transmitting with USOS, check for the case "1<space>A"
					if ( ( code & CMFIGSHIFT ) == 0 ) [ self shiftToState: LTRSTATE ] ;
				}
				else {
						//  transmitting with non-USOS, check for the case "1<space>2"
					if ( ( code & CMLTRSHIFT ) == 0 ) [ self shiftToState : FIGSTATE ] ;
				}
			}
			spaceFollowedFIGS = NO ;
		}

		if ( shifted == FIGSTATE ) {
			// in FIGS at the moment, shift to LTRS if needed
			if ( ( code & CMFIGSHIFT ) == 0 ) [ self shiftToState: LTRSTATE ] ;
		}
		else {
			//  in LTRS at the moment, shift to FIGS if needed
			if ( ( code & CMLTRSHIFT ) == 0 ) [ self shiftToState : FIGSTATE ] ;
		}
		//  send character
		[ self appendBits:( code & 0x1f ) ascii:echo ] ;
		
		//  v0.88  now send extra shift character after a space when we are in robust mode
		if ( ascii == ' ' ) {
			if ( shifted == FIGSTATE ) spaceFollowedFIGS = YES ;					//  v0.88 for USOS compatibility
			if ( usos == YES ) {
				//  note: no explicit LTRS character is sent
				shifted = LTRSTATE ;
			}
		}
		if ( robustCount >= kRobustThreshold ) {
			//  add in extra FIGS and LTRS for robustness, stay in the same shift
			[ self shiftToState: ( shifted == FIGSTATE ) ] ;
		}

		if ( ascii == '\r' ) {
			//  send \n from text view as cr/lf pair
			[ self appendBits:( mapping['\n'] & 0x1f ) ascii:'\n' ] ;
		}
		[ lock unlock ] ;
	}
}

//  append the string, replacing completely any previous string that is in the buffer if clearExistingCharacters is true
- (void)appendString:(char*)s clearExistingCharacters:(Boolean)reset
{
	if ( reset) producer = consumer = 0 ;
	while ( *s ) [ self appendASCII:( *s++ ) ] ;
	bitTheta = 0 ;
	current = tonePair.mark ;
	currentBitDDA = bitDDA ;
}

- (void)clearOutput
{
	if ( consumer < ( producer-1 ) ) consumer = producer-1 ;
}

//  consume from the currect buffer
//  add diddle if there is no more bits to consume
//  If a character is encountered in the stream, the ASCII representation is returned otherwise a 0 is returned.
//  (note: at 11025 samples/sec, an RTTY character takes up about 1830 samples)
- (void)getBufferWithDiddleFill:(float*)buf length:(int)samples
{
	int i ;
	CMBinaryStream *bit ;
	
	for ( i = 0; i < samples; i++ ) {
		buf[i] = [ self sin:current ] ;
		//  modulation
		if ( [ self modulation:currentBitDDA ] ) {
			consumer = ( consumer+1 )&CMSTREAMMASK ;
			if ( consumer == producer ) [ self appendDiddle:0 ] ;
			bit = &stream[consumer] ;
			currentBitDDA = bit->dda ;
			current = ( bit->polarity == 0 ) ? tonePair.space : tonePair.mark ;
			if ( bit->character ) [ self transmittedCharacter:bit->character ] ;
		}
	}
}

- (int)lengthOfActiveStream
{
	int n ;
	
	n = producer - consumer ;
	if ( n < 0 ) n += CMSTREAMMASK+1 ;
	return n ;
}

- (id)delegate 
{
	return delegate ;
}

- (void)setDelegate:(id)client
{
	delegate = client ;
}

// delegate
- (void)transmittedCharacter:(int)ch
{
	if ( delegate && [ delegate respondsToSelector:@selector(transmittedCharacter:) ] ) [ delegate transmittedCharacter:ch ] ;
}

@end
