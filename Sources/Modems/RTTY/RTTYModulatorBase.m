//
//  RTTYModulatorBase.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/21/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "RTTYModulatorBase.h"

#import "Application.h"
#import "AppDelegate.h"
#import "Baudot.h"
#import "CoreModemTypes.h"
#import "FSKHub.h"
#import "RTTYModulatorBase.h"

#define kRobustThreshold	16


@implementation RTTYModulatorBase

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		delegate = nil ;
		producer = consumer = 0 ;
		ook = 0 ;							//  v0.85
		ookAssert = YES ;					//  v0.85
		currentBaudotCharacter = 0x1f ;
		[ self initSetup ] ;
	}
	return self ;
}

- (void)initSetup
{
	int i, ltr, fig ;
	CMTonePair tonepair = { 2125.0, 2295.0, 45.45 } ;

	usos = YES ;
	shifted = robust = NO ;
	sideband = 0 ;
	robustCount = 0 ;
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

//  v0.85
- (void)setOOK:(int)ookState invert:(Boolean)invertTransmit
{
	ook = ookState ;
	if ( ook && invertTransmit ) ook = 2 ;
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
	if ( ook ) current = 0 ;
	currentBitDDA = bitDDA ;
	
	startBit.dda = bitDDA ;
	startBit.polarity = 0 ;
	startBit.character = 0 ;
	startBit.code = 0 ;
	dataBit[0].dda = bitDDA ;
	dataBit[0].polarity = 0 ;
	dataBit[0].character = 0 ;
	dataBit[0].code = 0 ;
	dataBit[1].dda = bitDDA ;
	dataBit[1].polarity = 1 ;
	dataBit[1].character = 0 ;
	dataBit[1].code = 0 ;
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
	stopBit.code = 0 ;
}

- (void)setSideband:(int)usb
{
	sideband = usb ;
}

- (void)setUSOS:(Boolean)state
{
	usos = state ;
}

#ifdef MOVEDTOBASECLASS
//  append a long mark tone (11 bits long, with no start bit)
- (void)appendLongMark
{
	stream[producer] = stopBit ;
	stream[producer].dda /= 11.0 ;
	producer = ( producer+1 )&CMSTREAMMASK ;
}
#endif

//  (Private API)
//  append diddle (LTRS)
- (void)appendDiddle:(int)flag
{
	int i, diddle, tempProducer ;
	
	diddle = CMLTRSCODE ;
	[ lock lock ] ;
	shifted = NO ;
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

//	(Private API)
- (void)appendBits:(int)code ascii:(int)ascii
{
	int i, tempProducer ;
	
	tempProducer = producer ;
	stream[tempProducer] = startBit ;
	stream[tempProducer].character = ascii ;
	stream[tempProducer].code = code ;
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

#ifdef USEBASECLASS
//  append a single ascii character
- (void)appendASCII:(int)ascii
{
	int code, echo ;
	
	if ( ascii == CMLTRSCODE || ascii == CMFIGSCODE ) {
		[ lock lock ] ;
		[ self appendBits:ascii ascii:0 ] ;
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
		return ;
	default:
		if ( ascii == '\n' ) {
			ascii = '\r' ;
			echo = 0 ;
		}
		code = mapping[ ascii ] ;		// ASCII to Baudot map
		break ;
	}
	if ( code != 0 ) {
		if ( robust ) robustCount++ ;
		[ lock lock ] ;
		if ( shifted ) {
			// in FIGS at the moment, shift to LTRS if needed
			if ( ( code & CMFIGSHIFT ) == 0 ) [ self shiftToState:LTRSTATE ] ;
		}
		else {
			//  in LTRS at the moment, shift to FIGS if needed
			if ( ( code & CMLTRSHIFT ) == 0 ) [ self shiftToState:FIGSTATE ] ;
		}

		//  send character
		[ self appendBits:( code & 0x1f ) ascii:echo ] ;
		
		if ( ascii == '\r' ) {
			//  send \n from text view as cr/lf pair
			[ self appendBits:( mapping['\n'] & 0x1f ) ascii:'\n' ] ;
		}
		[ lock unlock ] ;
	}
}
#endif

//  append the string, replacing completely any previous string that is in the buffer if clearExistingCharacters is true
- (void)appendString:(char*)s clearExistingCharacters:(Boolean)reset
{	
	if ( reset ) producer = consumer = 0 ;
	while ( *s ) [ self appendASCII:( *s++ ) ] ;
	
	bitTheta = 0 ;
	current = ( !ook ) ? tonePair.mark : ookMark ;			//  v0.85
	currentBitDDA = bitDDA ;
}

- (void)clearOutput
{
	if ( consumer < ( producer-1 ) ) consumer = producer-1 ;
}

//  v0.88 send Baudot character to FSKHub so OOK aural Monitor can fetch it
- (void)setAuralTransmitCharacter:(int)code
{
	[ [ [ [ NSApp delegate ] application ] fskHub ] setCurrentBaudotCharacter:code ] ;
}

//  v0.85
//	2500 Hz tone burts
- (void)getOOKBufferWithDiddleFill:(float*)buf length:(int)samples
{
	int i ;
	CMBinaryStream *bit ;
	float v ;
	
	for ( i = 0; i < samples; i++ ) {
		v = [ self sin:current ] ;
		buf[i] = ( ookAssert ) ? v : 0.0 ;
		//  modulation
		if ( [ self modulation:currentBitDDA ] ) {
			consumer = ( consumer+1 )&CMSTREAMMASK ;
			if ( consumer == producer ) [ self appendDiddle:0 ] ;
			bit = &stream[consumer] ;
			currentBitDDA = bit->dda ;
			current = ookMark ;
			ookAssert = ( bit->polarity == 0 ) ;
			if ( ook == 2 ) ookAssert = !ookAssert ;
			//  set clock for zero crossing
			theta = 0 ;
			if ( bit->code ) [ self setAuralTransmitCharacter:bit->code ] ;				//  v0.88
			if ( bit->character ) [ self transmittedCharacter:bit->character ] ;
		}
	}
}

//  consume from the currect buffer
//  add diddle if there is no more bits to consume
//  If a character is encountered in the stream, the ASCII representation is returned otherwise a 0 is returned.
//  (note: at 11025 samples/sec, an RTTY character takes up about 1830 samples)
- (void)getBufferWithDiddleFill:(float*)buf length:(int)samples
{
	int i ;
	CMBinaryStream *bit ;
	
	if ( ook != 0 ) {
		[ self getOOKBufferWithDiddleFill:buf length:samples ] ;
		return ;
	}
	for ( i = 0; i < samples; i++ ) {
		buf[i] = [ self sin:current ] ;
		//  modulation
		if ( [ self modulation:currentBitDDA ] ) {
			consumer = ( consumer+1 )&CMSTREAMMASK ;
			if ( consumer == producer ) [ self appendDiddle:0 ] ;
			bit = &stream[consumer] ;
			currentBitDDA = bit->dda ;
			current = ( bit->polarity == 0 ) ? tonePair.space : tonePair.mark ;
			if ( bit->code ) [ self setAuralTransmitCharacter:bit->code ] ;				//  v0.88
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
