//
//  MooreDecoder.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/6/06.
	#include "Copyright.h"
	
	
#import "MooreDecoder.h"
#import "CMFSKDemodulator.h"
#import "Moore.h"
#import "SITORRxControl.h"

@implementation MooreDecoder

- (id)initWithDemodulator:(CMFSKDemodulator*)rx
{
	int i, j, n, w ;
	
	self = [ super init ] ;
	if ( self ) {
		squelch = 0.0 ;
		control = nil ;
		demodulator = rx ;
		encoding = mooreLtrs ;
		decodeState = kSITOROff ;
		for ( i = 0; i < 6; i++ ) bitRegister[i] = 0 ;
		cr = lf = usos = bell = NO ;
		for ( i = 0; i < 256; i++ ) {
			w = 0 ;
			n = i ;
			for ( j = 0; j < 8; j++ ) {
				if ( n & 0x1 ) w++ ;
				n >>= 1 ;
			}
			weight[i] = w ;
		}
		indicatorDelay = 0 ;
		// initialize sync
		cycle = 0 ;
		for ( i = 0; i < 14; i++ ) syncProbability[i] = 0.0 ;
		
		//  map index to closest index with a codeword
		for ( i = 0; i < 128; i++ ) {
			hammingMapped[i] = i ;
			if ( mooreLtrs[i] == '~' ) {
				//  not a codeword, try to remap
				n = 0x40 ;
				for ( j = 0; j < 7; j++ ) {
					if ( mooreLtrs[i^n] != '~' ) {
						hammingMapped[i] = i^n ;
						break ;
					}
					n >>= 1 ;
				}
			}
		}
	}
	return self ;
}

- (void)setLTRS
{
	encoding = mooreLtrs ;
}

//  squelch = 0 : maximal squelch
- (void)setSquelch:(float)value
{
	squelch = value ;
}

- (void)setIndicatorState:(int)state
{
	if ( decodeState == state ) return ;
	decodeState = state ;
	if ( control ) [ control setIndicator:state ] ;
}

- (void)setErrorPrint:(Boolean)state
{
	errorPrint = state ;
}

//  Moore decoder -- receives character data from ATC (see [ atc setClient... ] in setupReceiverChain of RTTYReceiver)
- (void)decodeMoore:(int)byte
{
	int b, c ;

	b = byte ;
	c = ( b < 0 ) ? '~' : encoding[ b ] ;

	if ( c == '~' ) {
		if ( errorPrint ) [ demodulator receivedCharacter:'_' ];
		return ;
	}

	if ( c == '*' ) {
		switch ( b ) {
		case 0x34:
			if ( bell ) NSBeep() ;
			return ;
		case 0x70:
		default:
			// null
			return ;
		case MOOREFIGSCODE:
			encoding = mooreFigs ;
			return ;
		case MOORELTRSCODE:
			encoding = mooreLtrs ;
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
	if ( c == ' ' && usos ) encoding = mooreLtrs ;
}

/* local */
// return decded character -- return 0 if sync or alpha and -1 if error.
- (int)decodeFrom:(int)vector and:(int)repeatedFrom
{
	int codedVector, codedRepeat ;
	
	if ( vector == alpha ) return 0 ;		// ignore idle
	
	// find closest codewords
	codedVector = hammingMapped[ vector ] ;
	codedRepeat = hammingMapped[ repeatedFrom ] ;
			
	if ( vector == repeatedFrom && vector == codedVector ) {
		/* perfect copy */ 
		err = 0 ;
		[ self setIndicatorState:kSITOROn ] ;
		return vector ;
	}

	// squelch any possible error
	if ( squelch < 0.25 ) {
		err = 2 ;
		return -1 ;
	}
					
	// allow one of them to have a one bit error (i.e., one matches Hamming correction of the other)
	err = 1 ;
	if ( codedVector == repeatedFrom ) return codedVector ;
	if ( codedRepeat == vector ) return vector ;
	
	if ( squelch < 0.5 ) {
		err = 2 ;
		return -1 ;
	}
	
	// allow both of them to have a one bit error, as long as the Hamming correction matches
	
	if ( codedRepeat == codedVector && mooreLtrs[codedVector] != '~' ) return codedVector ;
	
	if ( squelch < 0.75 ) {
		err = 2 ;
		return -1 ;
	}
	
	//  allow either to go through if it is mapped
	err = 2 ;
	if ( mooreLtrs[codedVector] != '~' ) return codedVector ;
	if ( mooreLtrs[codedRepeat] != '~' ) return codedRepeat ;
	
	return -1 ;
}

- (void)setControl:(SITORRxControl*)ctrl
{
	control = ctrl ;
}


//  data is exported from SITORBitSync to here
//	The stream array contains the sampled data at mid-bit and stream samples contains the number of samples (usually 19 to 20 in a 256 sample buffer at 11025 s/s)
//
//  SITOR-B bit character sync algorithm.
//  -------------------------------------
//
//	Data is received as a synchronous bit stream at 100 baud.
//	
//	Each character has 7 bits with no start or stop bit encoded per CCIR-476 (note: not ITA-3).
//	
//	Data is places into two 7-bit slots in 14-bit group.
//	
//	Each character is sent twice, the first time in an even slot of the 14-bit group and the second time in the odd slot in the 14-bit group.  The repeated character is delayed by five 7-bit character positions.
//	
//	When a character is not ready (i.e., idle), an RQ is sent in its first slot where the character would have appeared, and an alpha where the repeat would have been (5 character times later).
//	
//	A sync pattern is sent as a 14-bit group, with RQ in the even slot and alpha in the second slot.
//	
//	Character sync therefore consists of identifying one out of 14 bit positions when either the character first appears or when characters are repeated (better, since we can do error detection).
//	
//	The RQ-alpha is a strong indication of a character sync (the choice of 1 out of 14 repeated bit positions).
//	
//	An RQ by itself is a weak indication of a character sync.  More than one RQ that are spaced at even character positions is a stronger indication of a character sync.
//	
//	An alpha by itself is another weak indication of character sync.  More than one alpha that are spaced at odd character positions is a stronger indication of a character sync.
//	
//	A 7-bit byte that is repeat after a character delay is another indicator of a a character sync, especially if accompanied by some intervening alpha.


- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	int i, j, bits, index, vector, result, repeatedFrom ;
	float prob, test, max ;
	
	stream = [ pipe stream ] ;
	bits = stream->samples ;
	for ( i = 0; i < bits; i++ ) {
		//  first shift the 7-bit registers
		for ( j = 5; j >= 1; j-- ) {
			bitRegister[j] >>= 1 ;
			if ( bitRegister[j-1] & 0x1 ) bitRegister[j] |= 0x40 ;
		}
		bitRegister[0] >>= 1 ;
		if ( stream->array[i] > 0 ) bitRegister[0] |= 0x40 ;

		//  look for sync clues
		cycle = ( cycle == 13 ) ? 0 : ( cycle+1 ) ;
		
		vector = bitRegister[0] & 0x7f ;
		repeatedFrom = bitRegister[5] ;
		
		//  assign probabilities that this cycle is the start of a repeated character
		prob = 0.0 ;
		sync = NO ;
		
		if ( vector == alpha && bitRegister[1] == RQ ) {
			prob = 3.0 ;		// RQ-alpha pair received
			sync = YES ;
		}
		else {
			if ( vector == repeatedFrom && vector != RQ ) prob = 0.01 ;	// prime during long no-RQ periods
			else {
				if ( vector == alpha && repeatedFrom == RQ ) prob = 2.0 ;
			}
		}
		//  modifiers of base probabilities
		if ( bitRegister[1] == RQ ) prob *= 1.4 ;
		if ( bitRegister[2] == alpha ) prob *= 1.4 ;
		if ( bitRegister[3] == RQ ) prob *= 1.4 ;
		if ( bitRegister[4] == alpha ) prob *= 1.4 ;
		if ( repeatedFrom == RQ ) prob *= 1.4 ;
		
		if ( prob > 0.0 ) {
			//  update sync probabilities
			max = 0.01 ;
			for ( j = 0; j < 14; j++ ) {
				if ( j != cycle ) syncProbability[j] *= 0.98 ;
				if ( syncProbability[j] > max ) max = syncProbability[j] ;
			}
			syncProbability[cycle] += prob/max ;
			//  make sure it does not overflow floating point range!
			if ( syncProbability[cycle] > 100.0 ) {
				for ( j = 0; j < 14; j++ ) syncProbability[j] *= 0.01 ;
			}
		}
		
		//  now find out if this is the beginning of the repeat cycle		
		index = 0 ;
		prob = syncProbability[0] ;
		for ( j = 1; j < 14; j++ ) {
			test = syncProbability[j] ;
			if ( test > prob ) {
				prob = test ;
				index = j ;
			}
		}
		
		//  finally, check for printable character if this is the repeated bit cycle
		if ( index == cycle ) {
			//  bit cycle for repeated character
			result = [ self decodeFrom:vector and:repeatedFrom ] ;
			if ( result != 0 ) {
				[ self decodeMoore:result ] ;
			}
			
			if ( sync ) {
				if ( decodeState == kSITOROff || decodeState == kSITORError ) [ self setIndicatorState:kSITORWait ] ;
			}
			else {
				switch ( err ) {
				case 0:
					if ( indicatorDelay <= 0 ) [ self setIndicatorState:kSITOROn ] ; else indicatorDelay-- ;
					break ;
				case 1:
					[ self setIndicatorState:kSITORFEC ] ;
					indicatorDelay = 3 ;
					break ;
				case 2:
					[ self setIndicatorState:kSITORError ] ;
					indicatorDelay = 3 ;
					break ;
				default:
					if ( indicatorDelay <= 0 ) [ self setIndicatorState:kSITOROff ] ; else indicatorDelay-- ;
					break ;
				}
				
			}

		}
	}
}

	

@end
