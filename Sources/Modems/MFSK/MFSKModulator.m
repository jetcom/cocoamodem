//
//  MFSKModulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/17/07.
	#include "Copyright.h"
	
	
#import "MFSKModulator.h"
#import "cocoaModemParams.h"
#import "ConvolutionCode.h"
#import "MFSKVaricode.h"
#import "MFSKDemodulator.h"


//  MFSK Modulator
//  ascii -> Varicode -> FEC -> interleave -> 1-of-16 -> Inverse FFT -> audio

@implementation MFSKModulator

//  idle pattern is sent as an ascii null
//  the null character self clocks a previous character without itslef printing
//  if a longer idle is needed, additional zeros are transmitted (into the convolutional decoder) that is at least 8 bits in length
//  i.e.: shortest idle = 1101011100 (NULL)
//  additional idle = 00000000 (1101011100 followed by 8 zero bits is not a proper Varicode word)
//  any longer idles, add 0

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
	
		//  establish baud rate and carrier generator
		bitTheta = 100000.0 ;
		baudDDA = 15.625*kPeriod/CMFs ;
		scale = 0.9 ;
		cw = NO ;
		
		transmitBPF = nil ;
		
		bitLock = [ [ NSLock alloc ] init ] ;
		varicode = [ [ MFSKVaricode alloc ] init ] ;
		fec = [ [ ConvolutionCode alloc ] initWithConstraintLength:7 generator:0x6d generator:0x4f ] ;
		interleaverStages = 10 ;		// 10 stages for MFSK16, 4 stages default for DominoEX

		sideband = 1.0 ;				//  -1 for LSB, +1.0 for USB
		[ self setFrequency:10.0 ] ;	// default to 10 Hz carrier
		[ self resetModulator ] ;
	}
	return self ;
}

- (void)setInterleaverStages:(int)stages
{
	if ( stages < 4 ) stages = 4 ; else if ( stages > 10 ) stages = 10 ;
	interleaverStages = stages ;
}

//  setup carrier for self (NCO object)
- (void)setDDAFrequency:(float)freq
{
	carrier = freq*kPeriod/CMFs ;
}

//  base (idle) frequency of the MFSK signal
- (void)setFrequency:(float)freq
{
	CMFIR *tmp ;
	float side, delta ;
	
	idleFrequency = freq ;
	[ self setDDAFrequency:freq ] ;
	
	if ( transmitBPF ) {
		tmp = transmitBPF ;
		transmitBPF = nil ;
		CMDeleteFIR( tmp ) ;
	}
	side = 15.625*2.8 ;
	delta = 15.625*15 + side ;
	
	if ( sideband > 0 ) {
		transmitBPF = CMFIRBandpassFilter( freq-side, freq+delta, CMFs, 1024 ) ;
	}
	else {
		transmitBPF = CMFIRBandpassFilter( freq-delta, freq+side, CMFs, 1024 ) ;
	}
}

// set sideband state -- LSB = NO 
- (void)setSidebandState:(Boolean)state
{
	sideband = ( state ) ? 1.0 : ( -1.0 ) ;
	[ self setFrequency:idleFrequency ] ;
}

//  called from config to transmit a pure carrier
- (void)setCW:(Boolean)state
{
	cw = state ;
}

- (void)setUseFEC:(Boolean)state
{
	//  do nothing in MFSK16
}

//  Note: caller must apply lock to bitLock
- (void)insertValue:(int)value withCharacter:(int)ch secondary:(int)secondaryCh
{
	ring[bitProducer].character = ch ;
	ring[bitProducer].secondaryCharacter = secondaryCh ;
	ring[bitProducer++].value = value ;
	bitProducer &= RINGMASK ;
}

//	insert bit for MFSK16 and nibble for DominoEX
- (void)lockAndInsertValue:(int)value withCharacter:(int)ch secondary:(int)secondaryCh
{
	[ bitLock lock ] ;
	[ self insertValue:value withCharacter:ch secondary:secondaryCh ] ;
	[ bitLock unlock ] ;
}

//	(Private API)
//  insert bits into the ring buffer 
//	bits is either an ascii string of '0' or '1', or actual interger value 0 or 1
- (void)insertPrimaryASCIIIntoFECBuffer:(int)ascii fromCharacter:(int)ch
{
	int i, length ;
	const char *bits ;
	
	[ bitLock lock ] ;
	idleSequenceState = 0 ;
	bits = [ varicode encode:ascii ] ;
	length = strlen( bits ) ;
	
	for ( i = 0; i < length; i++ ) {
		[ self insertValue:( ( bits[i] == '0' || bits[i] == 0 ) ? 0 : 1 ) withCharacter: ( ( i == 0 ) ? ch : 0 ) secondary:0 ] ;
	}
	[ bitLock unlock ] ;
}

- (void)insertPrimaryFECVaricodeFor:(int)ascii fromCharacter:(int)echo
{
	[ self insertPrimaryASCIIIntoFECBuffer:ascii fromCharacter:echo ] ;
}

//  in MFSK16, this is the same as insert primary varicode
- (void)insertSecondaryFECVaricodeFor:(int)ascii fromCharacter:(int)echo
{
	[ self insertPrimaryFECVaricodeFor:ascii fromCharacter:echo ] ;
}

static char *randBits[] = { "00000", "0000", "000", "00" } ;

//	Private API
//  Fetch next data bit modulation from the ring buffer.
//  If the buffer is empty, an idle seqequence is created.
- (int)getNextFECBit
{
	int newBit, newCharacter ;
	const char *idle ;
	
	if ( terminateState == TERMINATED ) return 0 ;

	if ( bitConsumer == bitProducer ) {	
		if ( terminateState == NOTTERMINATING ) {
			//  Insert an idle bits (generated bits depend on the idleSequenceState, which is cleared to 0 when a new character comes in)
			//  The idle pattern is first sent as an ascii null
			//  the null character self clocks a previous character without itslef printing
			//  if a longer idle is needed, additional zeros are transmitted (into the convolutional decoder) that is at least 8 bits in length
			//  i.e.: shortest idle = 1101011100 (NULL)
			//  This works because 1101011100 followed by 8 or more zero bits is not a proper Varicode word.
			[ bitLock lock ] ;
			switch ( idleSequenceState ) {
			case 0:
				//  insert 0x75c (ASCII NULL)
				idle = [ varicode encode:0 ] ;
				idleSequenceState = 1 ;
				break ;
			case 1:
				//  insert four zeros, to keep under constraint length of convolutional code
				//  this keeps the idle pattern low and still don't generate too many zero dibits
				idle = randBits[ ( rand() & 0x3 ) ] ;
				idleSequenceState = 0 ;
				break ;
			default:
				//  should not get here, but kick it back to NULL, just in case
				idle = [ varicode encode:0 ] ;
				idleSequenceState = 1 ;
				break ;
			}
			while ( *idle ) {
				[ self insertValue:( ( *idle == '0' ) ? 0 : 1 ) withCharacter:0 secondary:0 ] ;
				idle++ ;
			}
			[ bitLock unlock ] ;
		}
		else {
		
			//  a %[rx] (0x5) character places the MFSK modulator in the TERMINATESTATED state
			//  This will send 5 nulls and then the modulator will enter the TERMINATETAIL state, where 52 zeros are transmitted.
			//  The 52 zeros allow the data to flush through the interleaver.
			//  At the end of the TERMINATETAIL, the state is set to TERMINATED.
			
			switch ( terminateState ) {
			case TERMINATESTARTED:
				//  a ^E was seen earlier.  Send 5 nulls before going to the next state
				terminateCount++ ;
				if ( terminateCount < 5 ) [ self insertPrimaryFECVaricodeFor:0 fromCharacter:0 ] ;
				else {
					terminateState = TERMINATETAIL ;
					terminateCount = 0 ;
					[ self insertValue:0 withCharacter:0 secondary:0 ] ;
				}
				break ;
			case TERMINATETAIL:
				//  terminate state has entered the carrier tail state
				terminateCount++ ;
				if ( terminateCount < 52 ) {
					[ self lockAndInsertValue:0 withCharacter:0 secondary:0 ] ;
				}
				else {
					terminateState = TERMINATED ;
					terminateCount = 0 ;
				}
			}
		}
	}
	newCharacter = ring[bitConsumer].character ;
	newBit = ring[bitConsumer++].value ;
	bitConsumer &= RINGMASK ;
	
	//  check for end-of-message that the client has inserted
	switch ( newCharacter ) {
	case 5 /* ^E */:
		//  check first to make sure there are no more macros
		if ( bitConsumer == bitProducer ) {
			//  Character buufer is truly empty at the moment, initiate a terminate sequence
			//  This terminate sequence can be broken with an incoming macro; see -appenASCII:
			terminateState = TERMINATESTARTED ;
			terminateCount = 0 ;
			[ self insertPrimaryASCIIIntoFECBuffer:0 fromCharacter:0 ] ;
			newCharacter = ring[bitConsumer].character ;
			newBit = ring[bitConsumer++].value ;
			bitConsumer &= RINGMASK ;
			//  tell user we have entered the terminating sequence
			[ (MFSK*)modem changeTransmitLight:2 ] ;
		}
		else {
			//  continue transmitting
			return [ self getNextFECBit ] ;
		}
		break ;
	default:
		break ;
	}
	//  save character for echo back in fillBuffer, delayed by 128 characters to compensate for the interleaver
	if ( characterRing[characterRingIndex] != 0 ) [ modem transmittedCharacter:characterRing[characterRingIndex] ] ;
	characterRing[characterRingIndex] = newCharacter ;
	characterRingIndex = ( characterRingIndex+1 ) & 0x3f ;
		
	return ( newBit == 0 ) ? 0 : 1 ;
}

//  Concatenated deinterleaver of 10 stages of the the IZ8BLY Diagonal Interleaver
//  This is a rederivation of the concatenated 4x4 interleaver that is described in
//  http://www.qsl.net/zl1bpu/MFSK/Interleaver.htm
//
//  The recurrence equation is solved as a single linear table that is 160 units long rather 
//	that ten tables that are arranged in 4x4 units.

static int interleaveStride[] = { 5, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41 } ;
static int interleaveSize[] = { 16, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160 } ;

//	DominoEX interleaver (10 stage for MFSK16, 4 stage default for DeomioEX)
- (QuadBits)interleave:(QuadBits)p
{
	int i, mod ;
	QuadBits quad ;
	
	mod = interleaveSize[interleaverStages] ;
	//  insert new bits into register
	
	for ( i = 0; i < 4; i++ ) interleaverRegister[ ( interleaverIndex+i*interleaveStride[interleaverStages] )%mod ] = p.bit[i] ;
	//  fetch the four deinterleaved bits before overwriting some with the new data
	for ( i = 0; i < 4; i++ ) quad.bit[i] = interleaverRegister[ interleaverIndex+i ] ;
	//  increment the pointer for the next QuadBits set
	interleaverIndex = ( interleaverIndex + 4 )%mod ;
	
	return quad ;
}

//  get next FEC encoded dibit by ending the next bit with the Convolutional code
/* local */ - (int)getNextFECEncodedDibit
{
	int bit ;
	
	bit = [ self getNextFECBit ] ;
	//  Replace the stream bit by the convolutional code's dibit.
	//  Keep streambit.character the same.
	return [ fec encodeIntoDibit:bit ] ;	
}

//  get next interleaved QuadBits by getting two FEC encoded Dibits
/* local */ - (QuadBits)getNextInterleavedQuadBits
{
	int dibit ;
	QuadBits q ;
	
	dibit = [ self getNextFECEncodedDibit ] ;
	q.bit[0] = ( dibit & 0x2 ) ? 1.0 : 0.0 ;
	q.bit[1] = ( dibit & 0x1 ) ? 1.0 : 0.0 ;
	dibit = [ self getNextFECEncodedDibit ] ;
	q.bit[2] = ( dibit & 0x2 ) ? 1.0 : 0.0 ;
	q.bit[3] = ( dibit & 0x1 ) ? 1.0 : 0.0 ;
	
	return [ self interleave:q ] ;
}

//	(Private API)
//  Note: MFSK16 needs to gray code the result from here
- (int)getNextFECIndex
{
	QuadBits q ;
	int b ;

	q = [ self getNextInterleavedQuadBits ] ;
	
	if ( terminateState == TERMINATETAIL && terminateCount > 30 ) return 0 ;		//  ignore iterleaver for the end

	b = ( q.bit[0] > 0.5 ) ? 8 : 0 ;
	b += ( q.bit[1] > 0.5 ) ? 4 : 0 ;
	b += ( q.bit[2] > 0.5 ) ? 2 : 0 ;
	b += ( q.bit[3] > 0.5 ) ? 1 : 0 ;

	return b ;
}

- (void)appendEOM
{
	[ self insertPrimaryASCIIIntoFECBuffer:' ' fromCharacter:' ' ] ;
	
	[ bitLock lock ] ;
	idleSequenceState = 0 ;
	[ self insertValue:0 withCharacter:5 secondary:0 ] ;
	[ bitLock unlock ] ;
}

- (void)appendASCII:(int)ascii
{
	// ignore opt u, i, `, e, n (e.g., umlaut prefix)
	if ( ( ascii == 168 ) || ( ascii == 710 ) || ( ascii == 96 )  || ( ascii == 180 ) || ( ascii == 732 ) ) return ;

	switch ( ascii ) {
	case 0x5: // %[rx]
		[ self appendEOM ] ;
		return ;
	case 0x6: // %[tx]
		//  if macros are appended when we are terminating, abort the terminating sequence
		if ( terminateState == TERMINATESTARTED || terminateState == TERMINATETAIL ) {
			terminateState = NOTTERMINATING ;
			[ (MFSK*)modem changeTransmitLight:1 ] ;
		}
		// ignore this non-printing character
		return ;
	default:
		if ( terminateState == NOTTERMINATING ) {
			//  make sure zero is not transmitted as phi
			if ( ascii == Phi || ascii == phi ) ascii = '0' ;
			[ self insertPrimaryASCIIIntoFECBuffer:ascii fromCharacter:ascii ] ;
		}
	}
}

- (void)appendString:(char*)string
{
	while ( *string ) [ self appendASCII:*string++ ] ;
}

static const int grayEncode[] = {
	0x0, 0x1, 0x3, 0x2,
	0x7, 0x6, 0x4, 0x5,
	0xf, 0xe, 0xc, 0xd, 
	0x8, 0x9, 0xb, 0xa
} ;

//  Fetch next audio sample
/* local */ -(float)nextAudioSample
{
	int fftBin ;
	float v ;
	
	if ( terminateState == TERMINATED ) {
		return ( ( transmitBPF ) ? CMSimpleFilter( transmitBPF, 0.0 ) : 0.0 ) ;
	}
	if ( cw ) return  [ self sin:carrier ]*0.9 ;		// test CW tone	
	
	//  check if the next symbol is needed
	if ( [ self modulation:baudDDA ] ) {
		fftBin = grayEncode[ [ self getNextFECIndex ] ] ;
		[ self setDDAFrequency:( idleFrequency + 15.625*sideband*fftBin ) ] ;
	}
	v = [ self sin:carrier ]*0.9 ;
	
	return ( ( transmitBPF ) ? CMSimpleFilter( transmitBPF, v ) : v ) ;
}

- (void)getBufferWithIdleFill:(float*)buf length:(int)samples
{
	int i ;
	
	if ( idleFrequency < 20.0 ) {
		for ( i = 0; i < samples; i++ ) buf[i] = 0.0 ;
		return ;
	}
	for ( i = 0; i < samples; i++ ) buf[i] = [ self nextAudioSample ] ;
}

- (void)setScale:(float)value
{
	//  not called???
	// set the NCO amplitude with scale value
	[ self setOutputScale:value ] ;
}

- (Boolean)terminated
{
	return ( terminateState == TERMINATED ) ;
}

- (void)flushOutput
{
	int i ;
	
	[ bitLock lock ] ;
	bitProducer = bitConsumer = 0 ;
	//  start with 15 symbol periods (approx 1 second) of idle carrier
	for ( i = 0; i < 30; i++ ) [ self insertValue:0 withCharacter:0 secondary:0 ] ;	
	idleSequenceState = 0 ;
	[ bitLock unlock ] ;
}

- (void)resetModulator
{
	int i ;
	
	[ self flushOutput ] ;	
	terminateState = NOTTERMINATING ;
	terminateCount = 0 ;
	//  flush transmit BPF
	if ( transmitBPF ) for ( i = 0; i < 160; i++ ) CMSimpleFilter( transmitBPF, 0.0 ) ;
	//  reset interleaver
	interleaverIndex = 0 ;
	for ( i = 0; i < 160; i++ ) interleaverRegister[i] = 0 ;
	//  reset character ring
	characterRingIndex = 0 ;
	for ( i = 0; i < 64; i++ ) characterRing[i] = 0 ;
	//  reset vco phase
	[ self resetPhase ] ;
}

- (void)setModemClient:(MFSK*)client
{
	modem = client ;
}

@end
