//
//  CMPSKModulator.m
//  CoreModem
//
//  Created by Kok Chen on 11/4/05.
	#include "Copyright.h"
//

#import "CMPSKModulator.h"
#include "CMPSKModes.h"
#include "CoreModemTypes.h"


@implementation CMPSKModulator

//  CMPSKModulator works in a pull fashion.
//  Characters are sent to the modulator using -appendASCII (or -insertShortIdle or -insertSquelchTail)
//  Sound buffers are then fetched from the modulator using -fillBuffer.
//  if there are not enough characters to make up the full buffer, idle characters will be generated

- (id)init
{
	int i ;
	float angle ;
	
	self = [ super init ] ;
	if ( self ) {
		delegate = nil ;
		for ( i = 0; i < BITPHASEMASK+16; i++ ) {
			angle = i/( BITPHASEMASK+1.0 ) ;
			if ( angle > 1.0 ) angle = 1.0 ;
			angle *= 3.141592653589 ;
			raisedCosine[i] = ( cos( angle ) + 1.0 )*0.5 ;
		}
		//  phase (0 to 1)
		[ self setPSKMode:kBPSK31 ] ;
		bitLock = [ [ NSRecursiveLock alloc ] init ] ;
		varicode = [ [ CMVaricode alloc ] init ] ;
		[ self resetModulator ] ;
	}
	return self ;
}

- (id)delegate
{
	return delegate ;
}

- (void)setDelegate:(id)client
{
	delegate = client ;
}

- (float)frequency
{
	return carrier*CMFs/kPeriod ;
}

//  setup carrier for self (NCO object)
- (void)setFrequency:(float)freq
{
	carrier = freq*kPeriod/CMFs ;
}

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

- (void)appendASCII:(int)ascii
{
	Encoding *e ;
	
	e = [ varicode encode:ascii ] ;
	[ self insertBits:e->bits length:e->length fromCharacter:ascii ] ;
}

//  insert a short sequence of idle tone
- (void)insertShortIdle
{
	char idle[32] ;
	
	//  stuff with initial idle (0) bits (31 bits at 31.25 per second)
	memset( idle, 0, 32 ) ;
	[ self insertBits:idle length:31 fromCharacter:0 ] ;
}

- (void)insertSquelchTail
{
	char tail[1] ;

	//  send a 6 in the stream to indicate the need of a squelch carrier tail if at the
	//  end of a message or a series of messages
	tail[0] = 6 ;
	[ self insertBits:tail length:1 fromCharacter:0 ] ;
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
	char tail[31] ;
	
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
			memset( tail, 1, 31 ) ;
			tail[30] = 5 ;
			[ self insertBits:tail length:31 fromCharacter:0 ] ;
		}
		break ;
	case 5:
		// saw the 5 from the tail set by newbit == 6 above
		// end transmission without a phase change
		terminated = YES ; 
		bit = 1 ;  // continue to generate steady carrier
		break ;
	default:
		//  save character for echo back in fillBuffer
		if ( newCharacter ) [ self transmittedCharacter:newCharacter ] ;
		//  actual bit
		bit = ( newBit == 0 ) ? 0 : 1 ;
	}
	return bit ;
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
		result = [ self sin:carrier ]*( lastI*alpha + thisI*beta ) ;
		
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

- (void)getBufferWithIdleFill:(float*)buf length:(int)samples
{
	int i ;
	for ( i = 0; i < samples; i++ ) buf[i] = [ self nextSample ] ;
}

- (void)resetModulator
{
	bitPhase = lastBitPhase = 0.5 ;		//  start at bit transition
	lastI = -1.0 ;
	thisI = 1.0 ;
	lastQ = thisQ = 0.0 ;
	convolution = 0x1f ;
	bitProducer = bitConsumer = 0 ;
	terminated = NO ;
}

//  set PSK31/PSK63 rate
- (void)setPSKMode:(int)mode
{
	pskMode = mode ;
	dBitPhase = ( pskMode == kBPSK31 || pskMode == kQPSK31 ) ? ( 31.25/CMFs ) : ( 62.5/CMFs ) ;
}

// delegates
- (void)transmittedCharacter:(int)ch
{
	if ( delegate && [ delegate respondsToSelector:@selector(transmittedCharacter:) ] ) [ delegate transmittedCharacter:ch ] ;
}

@end
