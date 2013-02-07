//
//  ConvolutionCode.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/2/07.
	#include "Copyright.h"
	
#import "ConvolutionCode.h"

static int GF2Sum( unsigned int n ) ;

@implementation ConvolutionCode

//  rate 1/2 convolutional encoding
//  for MFSK16, k = 6 (6 state bits + 1 input bit feeding the generator functions)

//  Note: the path in this implementation can only be 64 bits (long long) in length.

- (id)initWithConstraintLength:(int)k generator:(int)a generator:(int)b
{
	int i, order ;
	
	self = [ super init ] ;
	if ( self ) {
	
		//  only allows max of k=30
		assert ( k < 30 ) ;
		order = k-1 ;
		states = ( 1 << order ) ;
		mask = states-1 ;

		//  generator functions (7 bits for MFSK16: 0x6d and 0x4f) -- should have k+1 bits
		generator[0] = a ;
		generator[1] = b ;

		trellisState0 = trellisState1 = nil ;
		outputDibitTable = nil ;
		//  default trellis lag for decoding bit
		[ self setTrellisDepth:45 ] ;
		//  damping factor is the factor applied to the past squared error -- this keeps the error from growing indefinitely
		damping = 0.998 ;		
		//  output mappings (state bit + input bit)
		outputDibitTable = (char*)malloc( states*2*sizeof( char ) ) ;
		for ( i = 0; i < states*2; i++ ) {
			outputDibitTable[i] = ( GF2Sum( generator[0] & i ) << 1 ) + GF2Sum( generator[1] & i )  ;
		}
		trellisState0 = ( TrellisState* )malloc( states*sizeof( TrellisState ) ) ;
		trellisState1 = ( TrellisState* )malloc( states*sizeof( TrellisState ) ) ;
		[ self resetTrellis ] ;
		
	}
	return self ;
}

- (void) dealloc
{
	if ( trellisState0 ) free( trellisState0 ) ;
	if ( trellisState1 ) free( trellisState1 ) ;
	if ( outputDibitTable ) free( outputDibitTable ) ;

	[ super dealloc ] ;
}

//  Two sets of trellis paths are kept.
//  Each set has one trellisState for each state of the decoder.
//  One set is used during even time slots and the other is used during odd time slots (this is to minimize any copying).
- (void)resetTrellis
{
	int i ;
	TrellisState *t, *u ;
	
	stateBits = 0 ;
	trellisCycle = 0 ;
	t = trellisState0 ;
	u = trellisState1 ;
	for ( i = 0; i < states; i++ ) {
		t->pathMetric = u->pathMetric = 0.0 ;
		t->pathBits = u->pathBits = 0 ;
		t++ ;
		u++ ;
	}
}

//  set the lag (number of time periods) to look for the decoded bit
//  initially set to 48
- (void)setTrellisDepth:(int)lag
{
	lagMask = 1 ;
	if ( lag <= 0 ) return ;
	if ( lag > 63 ) lag = 63 ;
	lagMask <<= lag ;
}

//  Encode one bit into a dibit.  bit can either be {0,1} or {'0','1'}
//  Returns two bits in the LSB of the integer and update state of encoder.
//  Update state.
- (int)encodeIntoDibit:(int)bit
{
	int t ;
	
	t = ( ( ( stateBits << 1 ) ) | ( ( bit == 1 || bit == '1' ) ? 1 : 0 ) ) ;
	stateBits = t & mask ;
	return outputDibitTable[ t ] ;
}

//  decode a pair of dibits into a result bit
//	The two inputs should be "soft" values in the range of { 0.0, 1.0 }.
//  e.g., 0 indicates a certainty 0 and 1 indicates a certainty 1 and 0.9 indicates an almost certain 1.0 , etc.
- (int)decodeMSB:(float)firstBit LSB:(float)secondBit
{
	TrellisState *previousState, *currentState, *to ;
	int i, state, t, u, dibit0, dibit1 ;
	float error[4], q, p, pathMetric0, pathMetric1, minpathMetric, survivedPathMetric ;

	//  swap between two memory sets
	if ( trellisCycle == 0 ) {
		previousState = trellisState0 ;
		currentState = trellisState1 ;
		trellisCycle = 1 ;
	}
	else {
		previousState = trellisState1 ;
		currentState = trellisState0 ;
		trellisCycle = 0 ;
	}
	
	//  Each state can emit four possible hard outputs (00, 01, 10 and 11).  Precompute a table of four squared errors for each of these outputs.
	for ( i = 0; i < 4; i++ ) {
		p = firstBit - ( ( i >> 1 ) & 1 ) ;
		q = p*p ;
		p = secondBit - ( i & 1 ) ;
		error[i] = q + p*p ;
	}
	
	//  Update the Trellis.
	//
	//  Note that each state <abcdef> can come from either <0abcde>+f or <1abcde>+f where f is a new input bit.
	//  For each clock, the outputs of <0abcde> and <1abcde> are tested with input f and the one that, together with the existing state errors,
	//  causes the smaller square error is kept as the path which produces <abcdef>
	
	i = 0 ;
	for ( state = 0; state < states; state++ ) {
		to = &currentState[state] ;
		// The ancestor of the current state <abcdef>  can be either <0abcde> or <1abcde> with input = f
		t = ( state & mask ) ;
		u = t + states ;
		dibit0 = outputDibitTable[ t ] ;	// <0abcdef>
		dibit1 = outputDibitTable[ u ] ;	// <1abcdef>		
		t >>= 1 ;
		u >>= 1 ;
		pathMetric0 = previousState[ t ].pathMetric*damping + error[ dibit0 ] ;
		pathMetric1 = previousState[ u ].pathMetric*damping + error[ dibit1 ] ;
		
		if ( pathMetric0 < pathMetric1 ) {
			//  path came from <0abcdef>
			survivedPathMetric = pathMetric0 ;
			to->pathBits = ( previousState[ t ].pathBits << 1 ) ;
		}
		else {
			//  path came from <1abcdef>
			survivedPathMetric = pathMetric1 ;
			to->pathBits = ( previousState[ u ].pathBits << 1 ) + 1 ;
		}
		to->pathMetric = survivedPathMetric ;
		//  mark the lowest squared error that is encountered
		if ( state == 0 || survivedPathMetric < minpathMetric ) {
			minpathMetric = survivedPathMetric ;
			i = state ;
		}
	}
	//  return the proper bit (lagMask) in the path which has the lowest squared error
	return ( ( currentState[i].pathBits & lagMask ) != 0 ) ? 1 : 0 ;
}

//  GF(2) sum (xor) of the bits in n
static int GF2Sum( unsigned int n ) 
{
	int result ;
	
	result = 0 ;
	
	while ( n > 0 ) {
		if ( n & 1 ) result ^= 1 ;
		n >>= 1 ;
	}
	return result ;
}

@end
