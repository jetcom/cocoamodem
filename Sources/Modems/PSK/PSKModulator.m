//
//  PSKModulator.m
//  cocoaModem
//
//  Created by Kok Chen on Mon Aug 09 2004.
	#include "Copyright.h"
//

#import "PSKModulator.h"
#import "Application.h"
#import "PSK.h"
#import "CMVaricode.h"
#import "CoreModemTypes.h"


@implementation PSKModulator

//  unmap odd ASCII characters
static int unmap( int d )
{
	if ( d == 216 || d == 175 ) return '0' ;
	if ( d == 0x20ac ) return 0x80 ;				// euro symbol on Windows
	
	return d ;
}

/*
//		tests
- (void)dump:(int)n
{
	int i ;
	
	printf( "dump %x (%d bits)\n", n, [ varicode encode:n ]->length ) ;
	
	int p = [ varicode encode:n ]->length ;
	char *bit = [ varicode encode:n ]->bits ;
	for ( i = 0; i < p; i++ ) printf( "%d", bit[i] ) ;
	printf( "\n" ) ;
}
*/

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		modem = nil ;
		psk125 = NO ;
		basebandFilter = CMFIRLowpassFilter( 40.0, CMFs, 1024 ) ;
		basebandFilter63 = CMFIRLowpassFilter( 80.0, CMFs, 512 ) ;
		basebandFilter125 = CMFIRLowpassFilter( 160.0, CMFs, 256 ) ;		//  v0.64f
	}
	return self ;
}

- (void)setModemClient:(Modem*)client
{
	modem = client ;
}


//  -- override base class to apply LPF on baseband data ---

/* local */
//  insert bits into the ring buffer
- (void)insertBits:(char*)bits length:(int)length fromCharacter:(int)ch
{
	int i ;
	
	[ bitLock lock ] ;
	for ( i = 0; i < length; i++ ) {
		ring[bitProducer].character = ( i == 0 ) ? ch : 0 ;
		ring[bitProducer++].bit = bits[i] ;
		bitProducer &= RINGMASK ;
	}
	[ bitLock unlock ] ;
}

/* local */
- (float)nextAlpha
{
	int iPhase ;
	
	iPhase = bitPhase*(BITPHASEMASK+1) ;
	lastBitPhase = bitPhase ;
	bitPhase += dBitPhase ;
	if ( bitPhase > 1 ) bitPhase -= 1 ;
	return raisedCosine[iPhase] ;
}

- (Boolean)shouldEndTransmission
{
	//  this used to be [ modem shouldEndTransmission]
	return YES ;
}

//  Fetch next data bit modulation from the ring buffer.
//  If the buffer is empty, an idle bit is first inserted into the buffer.
//  A 0 bit (idle) return a phase reversal
- (int)getNextBit
{
	int newBit, newCharacter, bit ;
	char tail[34] ;
	
	if ( terminated ) return 0 ;
	
	if ( bitConsumer == bitProducer ) {
		//  insert an idle bit
		[ bitLock lock ] ;
		ring[bitProducer].character = 0 ;
		ring[bitProducer++].bit = 0 ;
		bitProducer &= RINGMASK ;
		[ bitLock unlock ] ;
	}
	newCharacter = ring[bitConsumer].character ;
	newBit = ring[bitConsumer++].bit ;
	bitConsumer &= RINGMASK ;
	bit = 0 ; //  generate idle
	switch ( newBit ) {
	case 6:
		//  check if at the end of message or a series of messages
		if ( [ self shouldEndTransmission ] ) {
			//  generate carrier tail here (1 = no phase change)
			memset( tail, 1, 33 ) ;									//  send a squelch tail (1)
			tail[0] = 0 ;											//  v0.70 send an extra idle bit
			tail[32] = 5 ;											//  then end transmission
			[ self insertBits:tail length:33 fromCharacter:0 ] ;
		}
		bit = 0 ;
		break ;
	case 5:
		// saw the 5 from the tail set by newbit == 6 above
		// end transmission without a phase change
		terminated = YES ; 
		bit = 1 ;  // continue to generate steady carrier
		break ;
	default:
		//  save character for echo back in fillBuffer
		if ( newCharacter > 1 ) [ self transmittedCharacter:newCharacter ] ;
		//  actual bit
		bit = ( newBit == 0 ) ? 0 : 1 ;
	}
	return bit ;
}

//  v0.64f -- set PSK31/PSK63/PSK125 rate
- (void)setPSKMode:(int)mode
{
	psk125 = ( ( mode & 0x8 ) != 0 ) ;
	pskMode = mode & 0x3 ;
	
	if ( pskMode == kBPSK31 || pskMode == kQPSK31 )  {
		dBitPhase = ( 31.25/CMFs ) ;
	}
	else {
		dBitPhase = ( psk125 ) ? ( 125.0/CMFs ) : ( 62.5/CMFs ) ;
	}
}


//  (local) PSK modulator (client interface is -fillBuffer)
//	For BPSK, the (I,Q) phasor is slewed cosinusoidally between (1,0) and (-1,0).
//  For QPSK, the (I,Q) phasor is slewed cosinusoidally between (1,0), (0,1), (-1,0) and (0,-1).
-(float)nextSample
{
	float alpha, beta, result, slewI, slewQ ;
	int bit, g ;
	double sine, cosine ;
	
	if ( terminated ) return 0.0 ;
	
	alpha = [ self nextAlpha ] ;  // get next raised cosine factor
	beta = 1 - alpha ;

	if ( pskMode == kBPSK31 || pskMode == kBPSK63 ) {
		// only need to work with in-phase signal for BPSK
		
		if ( pskMode == kBPSK31 ) {
			result = [ self sin:carrier ]*CMSimpleFilter( basebandFilter, lastI*alpha + thisI*beta ) ;
		}
		else {
			if ( psk125 == NO ) {
				result = [ self sin:carrier ]*CMSimpleFilter( basebandFilter63, lastI*alpha + thisI*beta ) ;
			}
			else {
				result = [ self sin:carrier ]*CMSimpleFilter( basebandFilter125, lastI*alpha + thisI*beta ) ;
			}
		}

		if ( bitPhase < lastBitPhase ) {
			lastI = ( thisI > 0 ) ? 1.0 : -1.0 ;	// regenerate to make sure error does not grow
			bit = [ self getNextBit ] ;
			//  shift phase if bit == 0
			thisI = ( bit == 0 ) ? ( -lastI ) : lastI ;
		}
	}
	else {
		// need both in-phase and quadrature signals for QPSK
		slewI = lastI*alpha + thisI*beta ;
		slewQ = lastQ*alpha + thisQ*beta ;
		
		//  complex local oscillator
		[ self sin:&sine cos:&cosine delta:carrier ] ;
		result = sine*slewI + cosine*slewQ ;
		
		if ( bitPhase < lastBitPhase ) {
			lastI = thisI ;
			lastQ = thisQ ;
			
			//  encode each bit of data into 2 bits with convolution encoder
			//  notice that bits are inverted from getNextBit on the way into the shift register
			bit = ( [ self getNextBit ] ) ? 0 : 1 ;
			convolution = ( ( convolution << 1 ) + bit ) & 0x1f ;
			
			g = ( convolution & 0x1 ) ? 3 : 0 ;
			g ^= ( convolution & 0x2 ) ? 1 : 0 ;
			g ^= ( convolution & 0x4 ) ? 1 : 0 ;
			g ^= ( convolution & 0x8 ) ? 2 : 0 ;
			g ^= ( convolution & 0x10 ) ? 3 : 0 ;

			//  g = 0 no phase change
			//  g = 1 +90 degree phase change
			//  g = 2 180 degree phase change
			//  g = 3 -90 degree phase change
			//  cocoaModem uses (1,0), (0,1), (-1,0) and (0,-1) as the reference phasors 
			switch ( g ) {
			case 0:
				//  keep the old phasor
				break ;
			case 1:
				//  rotate phasor by +90 degrees
				thisI = -lastQ ;
				thisQ = lastI ;
				break ;
			case 3:
				//  rotate phasor by -90 degrees
				thisI = lastQ ;
				thisQ = -lastI ;
				break ;
			default:
				//  flip phasors by 180 degrees
				//  regenerate phasor amplitudes of { -1,0,+1 } here to keep errors from growing
				if ( lastI*lastI < 0.1 ) {
					thisI = 0.0 ;
					thisQ = ( lastQ > 0 ) ? ( -1.0 ) : 1.0 ;
				}
				else {
					thisI = ( lastI > 0 ) ? ( -1.0 ) : 1.0 ;
					thisQ = 0.0 ;
				}
				break ;
			}
		}
	}
	return result ;
}

//  0.44 - avoid clearing the ring buffer
- (void)resetModulator
{
	bitPhase = lastBitPhase = 0.5 ;		//  start at bit transition
	lastI = -1.0 ;
	thisI = 1.0 ;
	lastQ = thisQ = 0.0 ;
	convolution = 0x1f ;
	//bitProducer = bitConsumer = 0 ;
	terminated = NO ;
}

- (void)resetModulatorAndFlush
{
	[ self resetModulator ] ;
	bitProducer = bitConsumer = 0 ;
}

//  v0.70 Allow ASCII NULL to pass through to -transmittedCharacter in PSK.m
//  clean stream of garbage characters before transmitting.
- (void)appendASCII:(int)ch
{
	int ascii ;
	Encoding *e ;
	
	// sanity check: opt u, i, `, e, n .  Should be trapped before getting here.
	if ( ( ch == 168 ) || ( ch == 710 ) || ( ch == 96 )  || ( ch == 180 ) || ( ch == 732 ) ) return ;

	ascii = unmap( ch ) ;
	e = [ varicode encode:ascii ] ;
	if ( ascii == 0 ) ascii = ASCIINULL ;
	[ self insertBits:e->bits length:e->length fromCharacter:ascii ] ;
}

//  v0.70
//	Send two bytes to the modulator but combine the two into a unsigned short for the character to return to -transmittedCharacter in PSK.m
- (void)appendDoubleByte:(int)first second:(int)second
{
	Encoding *e ;	
	
	if ( first == 0 && second <= 26 ) {
		//  EOT and other control characters
		e = [ varicode encode:second ] ;
		[ self insertBits:e->bits length:e->length fromCharacter:second ] ;
		return ;
	}
	//  v0.81 unmap Shift Zero
	if ( first == 0 && second == 216 ) {
		e = [ varicode encode:'0' ] ;
		[ self insertBits:e->bits length:e->length fromCharacter:( first*256 + second ) ] ;
		return ;
	}
	e = [ varicode encode:first ] ;
	[ self insertBits:e->bits length:e->length fromCharacter:0 ] ;
	e = [ varicode encode:second ] ;
	[ self insertBits:e->bits length:e->length fromCharacter:( first*256 + second ) ] ;
}

- (void)transmittedCharacter:(int)ch
{
	if ( modem ) {
		[ modem transmittedCharacter:ch ] ;
		[ [ modem application ] addToVoice:ch channel:0 ] ;		//  v0.96d	voice synthesizer
	}
}

@end
