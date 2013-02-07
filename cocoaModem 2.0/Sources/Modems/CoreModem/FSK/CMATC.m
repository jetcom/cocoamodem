//
//  CMATC.m
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Fri Jul 16 2004)
	#include "Copyright.h"

#import "CMATC.h"
#import "CMATCBuffer.h"
#import <vecLib/vDSP.h>
#import <math.h>

//  Multiple Automatic Threshold Correction
//  ATC is patterned after Marvin Frerking, "Digital Signal Processing in Communication Systems," Chapman & Hall 1993, ISBN 0-442-01616-6
//  Multiple parallel ATC processors are used for different parameters (AGC, etc)

//  The input of CMATC is taken from the mark and space matched filter output,
//  the output (exportData) consists of characater data for the Baudot decoder and its associated waveform start-5 data bits-stop.
//	The thresholded matched filter waveform can be read from the CMPipe atcWaveformBuffer.

static float startBitMatch( CMATCPair *p, int halfBit, int eq ) ;
static int transitions( CMATCPair* pair, int bitn, int bitsPerCharacter ) ;
static int bitWeight( int* bits, int bitsPerCharacter ) ;
static int threshold( int* bits, int bitsPerCharacter ) ;
	

@implementation CMATC

- (id)init
{
	float g ;
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		//  set up bitsync type DataStream
		data = &bitStream ;
		bitStream.array = &syncedData[0] ;
		bitStream.samples = 256 ;
		bitStream.components = bitStream.channels = 1 ;
		
		bitsPerCharacter = 5 ;
		[ self setBitSamplingFromBaudRate:45.45 ] ;
		
		//  note: stopBit must be < 500
		invert = NO ;
		offset = 256 ;
		
		[ self setEqualize:0 ] ;
		memset( input.data, 0, sizeof( CMATCPair )*768 ) ;
		for (i = 0; i < 3; i++ ) {
			memset( agc[i].data, 0, sizeof( CMATCPair )*768 ) ;
			agc[i].markAGC = agc[i].spaceAGC = 0 ;
		}		
		//  alpha^n = 1/2.71828, where n is in steps of Fs/8
		//  first set of AGC constants (1/100) is often encountered
		g = 8.0/CMFs ;
		agc[0].attack = exp( -g/0.0005 ) ;		//  0.5 ms attack time constant
		agc[0].decay = exp( -g/0.120 ) ;		//  120 ms decay time constant
		agc[1].attack = exp( -g/0.001) ;		//  1 ms attack time constant
		agc[1].decay = exp( -g/0.200 ) ;		//  200 ms decay time constant
		agc[2].attack = exp( -g/0.002 ) ;		//  2 ms attack time constant
		agc[2].decay = exp( -g/0.600 ) ;		//  600 ms decay time constant
		
		atcCase[0].startingIndex = 0; atcCase[0].endingIndex = 1 ; atcCase[0].eq = 0 ;
		atcCase[1].startingIndex = 1; atcCase[1].endingIndex = 2 ; atcCase[1].eq = 0 ;
		atcCase[2].startingIndex = 0; atcCase[2].endingIndex = 1 ; atcCase[2].eq = 1 ;
		atcCase[3].startingIndex = 1; atcCase[3].endingIndex = 2 ; atcCase[3].eq = -1 ;
		atcCase[4].startingIndex = 0; atcCase[4].endingIndex = 1 ; atcCase[4].eq = 2 ;
		atcCase[5].startingIndex = 1; atcCase[5].endingIndex = 2 ; atcCase[5].eq = -2 ;
		atcBuffer = [ [ CMATCBuffer alloc ] init ] ;
	}
	return self ;
}

- (CMPipe*)atcWaveformBuffer
{
	return atcBuffer ;
}

- (void)setBitsPerCharacter:(int)bits
{
	if ( bits < 4 ) bits = 4 ; else if ( bits > 8 ) bits = 8 ;
	bitsPerCharacter = bits ;
}

- (void)setBitSamplingFromBaudRate:(float)baudrate
{
	int i ;
	
	bitStream.samplingRate = baudrate ;

	bitn = ( bitTime = CMFs/( baudrate*8 ) ) ;
	startBit = bitTime*0.5 ;								// mid of start bit from first mark-to-space transition

	stopBit = bitTime*( bitsPerCharacter+2 ) ;				// mid of stop bit from first mark-to-space transition, use 1.5 stop bits


	characterAdvance = bitTime*( bitsPerCharacter + 2 ) - 6 ;		//  v0.83 bpc + start + stop bits
	
	//  compute for up to 8 bit case
	for ( i = 0; i < 10; i++ ) {
		bitPos[i] = ( i+1.5 )*bitTime ; 
		transitionPos[i] = ( i+1.0 )*bitTime ;
	}
}

- (void)setEqualize:(int)mode
{
	switch ( mode ) {
	default:
	case 0:
		equalizerQuanta = /* 4 msec */ ( 0.004*CMFs )/8 ;
		break ;
	case 1:
		equalizerQuanta = /* 6 msec */ ( 0.006*CMFs )/8 ;
		break ;
	case 2:
		equalizerQuanta = /* 8 msec */ ( 0.008*CMFs )/8 ;
		break ;
	}
}

- (void)setInvert:(Boolean)isInvert
{
	invert = isInvert ;
}

- (void)setSquelch:(float)value
{
	//  squelch threshold (value = 0.0 == maximal squelching)
	squelch = 1.0 - value ;
}

/* local */
//  output N-bit character for each decoded character, and also the bitsynced waveform
- (void)exportCharacter:(int)ch buffer:(CMATCPair*)pair
{
	int i ;
	float norm, v ;
	CMATCPair *p ;

	bitStream.userData = ch ;
	
	//  copy synced waveform and normalize
	norm = 0.01 ;
	for ( i = 0; i < 256; i++ ) {
		p = &pair[i] ;
		v = p->mark - p->space ;
		syncedData[i] = v ;
		v = fabs( v ) ;
		if ( v > norm ) norm = v ;
	}
	norm = 0.5/norm ;
	vsmul( syncedData, 1, &norm, syncedData, 1, 256 ) ;

	[ self exportData ] ;
}

//  decode the characters, applying a common shift and a differential shift (equalizer) of the
//  time axis
- (void)decodeCharacterFrom:(CMATCPair*)pair eq:(int)eq into:(int*)decode
{
	int i, index ;
	CMATCPair *p, *q ;
	
	for ( i = 0; i < bitsPerCharacter; i++ ) {
		index = bitPos[i] ;
		p = &pair[ index ] ;
		q = &pair[ index + eq ] ;
		if ( p->mark > 0 && q->space < 0 ) decode[i] += 1 ;
		else {
			if ( p->mark < 0 && q->space > 0 ) decode[i] -= 1 ;
		}
		decode[i] += ( p->mark > q->space ) ? 1 : (-1) ;
	}
}

//  find extra transitions in start and N (default 5) data bits
static int transitions( CMATCPair* pair, int bitn, int bitsPerCharacter )
{
	int i, k, n, count ;
	float u, v ;
	CMATCPair *p ;
	
	pair += 8 ;
	n = bitn - 16 ;
	count = 0 ;
	
	for ( i = 0; i < ( bitsPerCharacter+1 ); i++ ) {
		p = pair ;
		u = p->mark - p->space ;
		for ( k = 0; k < n; k++ ) {
			p++ ;
			v = p->mark - p->space ;
			if ( u > 0 && v <= 0 || u < 0 && v >= 0 ) count++ ;
			u = v ;
		}
		pair += bitn ;
	}
	return count ;
}

//  threshold each bit and return 5-bit code
static int threshold( int* bits, int bitsPerCharacter )
{
	int i, result ;
	
	result = 0 ;
	for ( i = bitsPerCharacter-1; i >= 0; i-- ) {
		result *= 2 ;
		if ( bits[i] > 0 ) result += 1 ;
	}
	return result ;
}

static int bitWeight( int* bits, int bitsPerCharacter )
{
	int i, result ;
	
	result = 0 ;
	for ( i = 0; i < bitsPerCharacter; i++ ) result += abs( bits[i] ) ;
	return result ;
}

//  return a matched filter estimate of a stop/start bit transition
//  the match filter is abs( t-t0 ) and should provide a zero crossing at the optimal location
//  the output should be negative to a positive line from t<t0 to t>t0
//  Space signal is shifted by equalization adjustment.
static float startBitMatch( CMATCPair *p, int halfBit, int eq )
{
	CMATCPair *q, *s, *t ;
	float u ;
	int i ;
	
	u = 0 ;
	q = p-1 ;
	s = p+eq ;
	t = s-1 ;
	for ( i = 0; i < halfBit; i++ ) {
		u += i*( p->mark + - s->space + q->mark - t->space ) ;
	}
	return u ;
}

- (int)scanForBadTransitions:(CMATCPair*)s
{
	float start, prevStart, v ;
	int i, count, k ;
	
	s += 16 ;
	count = 0 ;
	start = startBitMatch( s++, startBit, 0 ) ;
	for ( i = 0; i < stopBit-startBit; i++ ) {
		prevStart = start ;
		start = startBitMatch( s++, startBit, 0 ) ;
		if ( ( prevStart > 0 && start < 0 ) || ( prevStart < 0 && start > 0 ) ) {
			v = ( i-16 )/bitTime ;
			k = v+0.5 ;
			v = v - k ;
			if ( v < -0.35 || v > 0.35 ) count++  ;
		}
	}
	return count ;
}

- (void)checkForCharacter
{
	int i, k, n, startIndex, result, bits[8], weight, agree, noiseThreshold ;
	float edge, prevEdge ;
	CMATCPair *atc[3], *ref, *pair ;
	CMATCCase *a ;
	
	offset -= 256 ;
	if ( offset > 384 ) return ;
	
	while ( 1 ) {
	
		ref = &agc[0].data[offset-1] ;
		edge = startBitMatch( ref, startBit, 0 ) ;
		//  scan for start bit in the first AGC stream
		
		for ( i = offset ; i < 280; i++ ) {
		
			ref = &agc[0].data[i] ;
			prevEdge = edge ;
			edge = startBitMatch( ref, startBit, 0 ) ;
			
			if ( prevEdge > 0 && edge <= 0 ) {
				
				//  try only if there are not too many (noisy) transitions
				if ( transitions( ref, bitn, bitsPerCharacter ) < 4 ) {
					//  use conservative check on the stop bit (either MO or SO should trigger space)
					if ( ref[stopBit].mark > 0 || ref[stopBit].space < 0 ) {
					
						// fetch the ATC streams with the three AGC time constants
						atc[0] = ref ;
						atc[1] = &agc[1].data[i] ;
						atc[2] = &agc[2].data[i] ;
						
						startIndex = i ;						
						weight = 0 ;
						
						for ( n = 0; n < 6; n++ ) {
							//  case n of atcCases 
							a = &atcCase[n] ;
							for ( k = 0; k < bitsPerCharacter; k++ ) a->bits[k] = 0 ;
							for ( k = a->startingIndex ; k <= a->endingIndex; k++ ) {
								//  adjust start bit location for this particular equalization, and then decode
								pair = atc[k] ;
								[ self decodeCharacterFrom:pair eq:a->eq*equalizerQuanta into:a->bits ] ;
							}
							a->weight = bitWeight( a->bits, bitsPerCharacter ) ;
							if ( a->weight > weight ) weight = a->weight ;
						}

						//  create final bit accumulators from the "best" decodings
						for ( k = 0; k < bitsPerCharacter; k++ ) bits[k] = 0 ;
						for ( n = 0; n < 6; n++ ) {
							//  case n of atcCases 
							a = &atcCase[n] ;
							for ( k = 0; k < bitsPerCharacter; k++ ) bits[k] += a->bits[k] ;
						}

						//  find character to print from the different set ups
						result = threshold( bits, bitsPerCharacter ) ;
						//  find how many cases agree
						agree = 0 ;
						for ( n = 0; n < 6; n++ ) {
							//  case n of atcCases 
							a = &atcCase[n] ;
							if ( ( result ^ threshold( a->bits, bitsPerCharacter ) ) == 0 ) agree++ ;
						}
						if ( result > 0 ) {
							if ( weight >= ( 16*squelch ) && ( agree > 5*squelch ) ) {
								noiseThreshold = [ self scanForBadTransitions:&agc[0].data[i] ]*( 4.0/bitsPerCharacter ) ;
								if ( noiseThreshold <=  ( 1.05-squelch )*8 ) {
									[ self exportCharacter:result buffer:ref ] ;
								}
							}
							i = startIndex + characterAdvance ;
						}
						else i += bitn ;
						break ;
					}
				}
			}
		}
		offset = i ;
		if ( offset >= 280 ) return ;
	}
}

//  computed AGC compensated data
static void updateAGC( CMATCStream *in, CMATCStream *out )
{
	int i ;
	float att, dec, m, s, v ;
	CMATCPair *din, *dout;
	
	att = out->attack ;
	dec = out->decay ;
	// look ahead 22ms to compute AGC
	
	din = &in->data[384+100] ;
	dout = &out->data[384-1] ;
	m = out->markAGC ;
	s = out->spaceAGC ;
	dout++ ;
	for ( i = 384; i < 384+256; i++ ) {
		v = din->mark ;
		m = ( ( v > m ) ? att : dec )*( m - v ) + v ;
		dout->mark = v - m*0.5 ;
		v = din->space ;
		s = ( ( v > s ) ? att : dec )*( s - v ) + v ;
		dout->space = v - s*0.5 ;
		din++ ;
		dout++ ;
	}
	out->markAGC = m ;
	out->spaceAGC = s ;
}

//  NOTE: sampling rate here is Fs/8, decimated by the matched filter
//        with 256 samples per frame
//
//  For Fs = 11025, the sampling rate here is about 1378 s/s (0.726ms per sample)
//  For 45.45 baud, each bit is 22ms or 30.32 samples.
//
//  new data is stuffed into the end of a 768-sample delay line
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	int i, samples, size ;
	float *m, *s ;
	CMATCPair *p ;
	
	stream = [ pipe stream ] ;
	bitStream.sourceID = stream->sourceID ;
	samples = stream->samples ;
	if ( samples > 256 ) samples = 256 ;
	
	//  invert M/S polarity here.
	if ( invert ) {
		s = stream->array ;
		m = stream->array+samples ;
	}
	else {
		m = stream->array ;
		s = stream->array+samples ;
	}	
	//  copy input data into tail of buffer
	//  input is split complex.  put it into ATCpair format
	p = &input.data[512] ;
	
	for ( i = 0; i < 256; i++ ) {
		p->mark = *m++ ;
		p->space = *s++ ;
		p++ ;
	}
		
	//  AGC streams
	updateAGC( &input, &agc[0] ) ;
	updateAGC( &input, &agc[1] ) ;
	updateAGC( &input, &agc[2] ) ;
	
	[ self checkForCharacter ] ;
	
	[ (CMATCBuffer*)atcBuffer atcData:&agc[2] ] ;

	//  move tail to head of buffers
	size = sizeof( CMATCPair )*512 ;
	memcpy( input.data, &input.data[256], size ) ;
	for ( i = 0; i < 3; i++ ) memcpy( agc[i].data, &agc[i].data[256], size ) ;
}

@end
