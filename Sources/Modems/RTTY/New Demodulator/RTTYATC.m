//
//  RTTYATC.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/27/07.
	#include "Copyright.h"


#import "RTTYATC.h"
#import "CMATCBuffer.h"


@implementation RTTYATC

//  ---- NOTE: this is not currently used, see CMATC.h -------

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		producer = consumer = decodeConsumer = 0 ;
		ringState = 0 ;
	}
	return self ;
}

//  compute an offset start and stop bit (offset by 64 bits from base start (0.5 bit period) and stop (7.0 bit period)
- (void)setBitSamplingFromBaudRate:(float)baudrate
{
	[ super setBitSamplingFromBaudRate:baudrate ] ;
	characterPeriod = bitTime*( bitsPerCharacter+2.5 ) ;
	fixedCharacterAdvance = characterPeriod ;
	firstStopBit = bitTime*( bitsPerCharacter + 1.5 ) ;
}

/* local */
//  output 5-bit character for each decoded character, and also the bitsynced waveform
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
	vDSP_vsmul( syncedData, 1, &norm, syncedData, 1, 256 ) ;

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
								noiseThreshold = [ self scanForBadTransitions:&agc[0].data[i] ] ;
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

//  previous sync position is at "offset" (a float) from 
- (void)extractCharacterFromRing
{
	//int startOffset, i, excess, bits[5], result ;
	//float start, stop ;
	//CMATCPair *r ;
	
	#ifdef LATER
	printf( "extractCharacterFromRing... excess = %d (producer %d, consumer %d)\n", (int)( producer-consumer ), (int)producer, (int)consumer ) ;
	
	while ( 1 ) {
		excess = producer - consumer ;
		if ( excess <= ( characterPeriod+64 ) ) break ;
		
		r = &ring[0].data[startOffset & ATCRINGMASK] 
		
						
		start = r[startBit].mark - r[startBit].space ;
		stop = r[stopBit].mark - r[stopBit].space ;
		
		if ( start > 0 || stop < 0 ) {
			printf( "--- bad sync, consumer = %d\n", (int)consumer ) ;
			
			consumer = ( consumer + 16 ) ;			//  test -------
			
			ringState &= ( ~HASSYNC ) ;
			return ;
		}
		ringState |= HASSYNC ;

		printf( "extract character at offset %d\n", startOffset ) ;
		
		//  fine tune
		for ( i = 0; i < 5; i++ ) bits[i] = 0 ;
		[ self decodeCharacterFrom:r eq:0 into:bits ] ;
		result = threshold( bits, bitsPerCharacter ) ;
		[ self exportCharacter:result buffer:r ] ;
		
		consumer = ( startOffset + fixedCharacterAdvance ) ;
		
		printf( "consumer now at %d after read\n", (int)consumer ) ;
	}	
	#endif
}

//  Check the ring buffer from startIndex, for available bits, for a start bit.
//  return the index, 
//	or -1 if a start bit was found without an accompanying stop bit, or a start bit was not found.
- (long long)findSync:(CMATCPair*)ringData start:(long long)startIndex available:(int)available
{
	int i, startOffset, bestIndex ;
	CMATCPair *r ;
	float start, stop, best, test ;
	
	for ( i = 0; i < available; i++ ) {		
		startOffset = startIndex+i ;
		r = &ringData[startOffset & ATCRINGMASK] ;	
		start = r[startBit].mark - r[startBit].space ;
		if ( start < 0 ) {
			stop = r[stopBit].mark - r[stopBit].space ;
			if ( stop > 0 ) {
				stop = r[firstStopBit].mark - r[firstStopBit].space ;
				if ( stop > 0 ) {
				
					//  found potential character start, now fine tune
					if ( i == 0 ) {
						startIndex += ATCRINGSIZE + 16 ;
						available += 16 ;
					}
					else {
						available = available - i + 16 ;
					}
					if ( available > 32 ) available = 32 ;
					
					best = r[firstStopBit].mark - r[firstStopBit].space + r[stopBit].mark - r[stopBit].space -  r[startBit].mark + r[startBit].space ;
					bestIndex = startOffset ;
					
					for ( i = 0; i < available; i++ ) {
						startOffset = startIndex+i ;
						r = &ringData[startOffset & ATCRINGMASK] ;	
						start = r[startBit].mark - r[startBit].space ;
						if ( start < 0 ) {
							stop = r[stopBit].mark - r[stopBit].space ;
							if ( stop > 0 ) {
								//  check for best midbit
								test = r[firstStopBit].mark - r[firstStopBit].space + r[stopBit].mark - r[stopBit].space -  r[startBit].mark + r[startBit].space ;
								if ( test > best ) {
									best = test ;
									bestIndex = startOffset ;
								}
							}
						}
					}
					return bestIndex ;
				}
			}
		}
	}
	return ( -1 ) ;
}

//  Look for a potential start-stop and confirm by
//		1) the next start bit also has a legitimate stop bit, or
//		2) there are 7 bits of stop.
- (Boolean)scanRingForSync:(int)startingPosition
{
	return NO ;
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
	int i, samples, size, limit ;
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
	
	[ (CMATCBuffer*)atcBuffer atcData:&agc[2] ] ;
	
	//  move tail to head of buffers
	size = sizeof( CMATCPair )*512 ;
	memcpy( input.data, &input.data[256], size ) ;
	for ( i = 0; i < 3; i++ ) memcpy( agc[i].data, &agc[i].data[256], size ) ;
		
	//  copy the AGC buffers into the ring buffers
	//  The ring buffer has a copy right after it, i.e.,
	//	ring0, ring1, ring2,... ringN-1, ringN, ringN+1, ringN+2, ..., ringN+N-1.
	//
	//  ring0 through ringN-1 is the ring buffer and ringN through ringN+N-1 is a copy of the ring.
	//  This allows the ring to be linearly addressed from even near the tail of the buffer.
	
	size = sizeof( CMATCPair )*samples ;
	for ( i = 0; i < 3; i++ ) {
		memcpy( &ring[i].data[producer & ATCRINGMASK], agc[i].data, size ) ;
		memcpy( &ring[i].data[( producer & ATCRINGMASK )+ATCRINGSIZE], agc[i].data, size ) ;
	}
	producer = ( producer+samples ) ;
	
	if ( ( ringState &HASSYNC ) == 0 ) {
	
		printf( "consumer at %d starting to scan for sync\n", (int)consumer ) ;

		limit = producer - decodeConsumer - characterPeriod*4 ;
		
		//  check for sync through available ring samples
		for ( i = 0; i < limit; i += 8 ) {
			if ( [ self scanRingForSync:( decodeConsumer+i ) ] ) break ;
		}
	}
	
	if ( ( ringState &HASSYNC ) != 0 ) {
		[ self extractCharacterFromRing ] ;
	}
}

@end
