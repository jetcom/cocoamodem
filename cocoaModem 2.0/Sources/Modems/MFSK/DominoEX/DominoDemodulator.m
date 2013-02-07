//
//  DominoDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/23/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DominoDemodulator.h"
#import "DominoVaricode.h"
#import "MFSK.h"
#import "MFSKModes.h"


@implementation DominoDemodulator

static int secondaryFECDecodeTable[256] = {
	//			0		1		2		3		4		5		6		7		8		9
	/* 0 */		0,		' ',	'!',	'"',	'_',	'$',	'%',	'&',	0,		'\'',		
	/* 1 */		0,		')',	'*',	'(',	'0',	'1',	'2',	'3',	'4',	'5',		//  note flip of /r and /n
	/* 2 */		0,		0,		0,		0,		'+',	',',	'-',	'.',	'/',	':',		
	/* 3 */		';',	'<',	0,		0,		0,		0,		0,		0,		0,		0,		
	/* 4 */		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 5 */		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 6 */		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 7 */		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 8 */		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 9 */		0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 10 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 11 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 12 */	0,		0,		0,		0,		0,		0,		0,		'A',	'B',	'C',		
	/* 13 */	'D',	'E',	'F',	'G',	'H',	'I',	'J',	'K',	'L',	'M',		
	/* 14 */	'N',	'O',	'P',	'Q',	'R',	'S',	'T',	'U',	'V',	'W',		
	/* 15 */	'X',	'Y',	'Z',	'=',	'>',	'?',	'@',	'[',	'\\',	']',		
	/* 16 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 17 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 18 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 19 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 20 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 21 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 22 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 23 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 24 */	0,		0,		0,		0,		0,		0,		0,		0,		0,		0,		
	/* 25 */	0,		0,		0,		0,		0,		0	
} ;


//	note: 256 is error code
- (void)makeIFSKCode
{
	int i, index, previous, delta ;
	SubBin *s ;
	
	for ( index = 0; index < 32; index++ ) {
		for ( previous = 0; previous < 32; previous++ ) {
			delta = index - previous - 2 ;
			if ( delta < 0 ) delta += 18 ;
			iFSKDecodeVector[index][previous] = ( delta < 0 || delta > 16 ) ? 256 : delta ; 
		}
	}
	for ( i = 0; i < 16; i++ ) {
		s = &subbin[i] ;
		s->mostRecentBin = s->nextRecentBin = 0 ;
		s->energy = 0 ;
		s->code[0] = s->bin[0] = 0 ;
	}
	accumulatedCodes = 0 ;
}

//  (Private API)
- (id)initAsDomino:(int)mode
{
	unsigned short p ;
	int i ;

	self = [ super init ] ;
	if ( self ) {
		m = 18 ;
		afcState = 1 ;
		previousModemOffset = -1 ;
		interleaverStages = 4 ;				//  default to 4 stages
		useFEC = NO ;
		ssnr = 1.0 ;
		
		decodeLag = 21 ;
		[ fec setTrellisDepth:decodeLag ] ;
		
		switch ( mode ) {
		case DOMINOEX22:
			baudRate = 21.533 ;
			break ;
		case DOMINOEX16:
			baudRate = 15.625 ;
			break ;
		case DOMINOEX11:
			baudRate = 10.766 ;
			break ;
		case DOMINOEX8:
			baudRate = 7.8125 ;
			break ;
		case DOMINOEX5:
			baudRate = 5.3833 ;
			break ;
		case DOMINOEX4:
			baudRate = 3.90625 ;
			break ;
		}
		[ self makeIFSKCode ] ;		
		holdoff = -1000 ;
		//	primary varicode
		memset( privar, 0, 4096 ) ;
		for ( i = 0; i < 256; i++ ) {
			p = ASCIITOPRIVAR[i] & 0xfff ;
			if ( privar[p] != 0 ) printf( "primary varicode error %x, mapped already to %d attempt to map again to %d\n", p, privar[p], i ) ;
			if ( p != 0 ) privar[p] = i ;
		}
		privar[0] = ' ' ;
		//  secondary Varicode
		memset( secvar, 0, 4096 ) ;
		for ( i = 0; i < 256; i++ ) {
			p = ASCIITOSECVAR[i] & 0xfff ;
			if ( secvar[p] != 0 ) printf( "secondary varicode error %x, mapped already to %d attempt to map again to %d\n", p, secvar[p], i ) ;
			if ( p != 0 ) secvar[p] = i ;
		}		
		memset( avgSpectrum, 0, sizeof( float )*512 ) ;
	}
	return self ;
}

//	Full Rate DominoEX
- (id)initAsMode:(int)mode
{
	int i ;
	float v ;
	
	self = [ self initAsDomino:mode ] ;
	if ( self ) {
		// clock recovery (32 bins)
		clockExtractFFT = FFTForward( 5, NO /*window*/ ) ;
		//  N clock cycles of extraction kernel (each cycle is 32 samples)
		clockExtractionCycles = 15 ;
		prevClock = 0.0 ;
		clockExtractFilter = CMFIRLowpassFilter( 4, 500, clockExtractionCycles*32 ) ;
		for ( i = 0; i < clockExtractionCycles*32; i++ ) {
			v = -cos( i*3.1415926535/16.0 ) ;	
			clockExtractFilter->kernel[i] = clockExtractKernel[i] = v ;	
		}		
		[ self waterfallClicked ] ;
		[ self resetDemodulatorState ] ;
	}
	return self ;
}

- (void)setUseFEC:(Boolean)state
{
	useFEC = state ;
}

#define noCERTEST
#ifdef CERTEST
static long total = 0 ;
static long error = 0 ;
#endif

//	(Private API)
- (void)newIFSKVaricode:(SubBin*)s length:(int)length
{
	int i, primary, secondary, decoded, cc ;
	Boolean err ;
	
	if ( length < 0 ) return ;
	
	err = NO ;
	decoded = 0 ;

	for ( i = 0; i < length; i++ ) {
		decoded = decoded*16 + s->code[i] ;
		if ( s->code[i] > 16 ) {
			err = YES ;
			break ;
		}
	}
	
	#ifdef CERTEST
	total++ ;	
	if ( ( err || ( decoded != 0x4b8 && decoded != 0x6f9 ) ) && total > 50 ) {
		error++ ;
		printf( "*** Beacon error rate %6.2f %% (%4d)\n", ( error*100.0 )/( total-50 ), total, decoded ) ;
	}
	//if ( total > 5000*baudRate/15.625 ) {
	if ( total > 10000*baudRate/15.625 ) {
		NSLog( @"Beacon error rate %6.2f %% (%d)", ( error*100.0 )/( total-50 ), total ) ;
		exit( 0 ) ;
	}
	#endif
	
	decoded &= 0xfff ;
	
	//  found nibble that is start of Varicode, flush accumulated Varicode so far
	
	if ( cnr > squelchThreshold*4 ) {
		if ( holdoff > 1000 ) holdoff = 1000 ;
		if ( holdoff++ >= 0 ) {
			primary = privar[decoded] ;
			if ( primary ) {
				if ( previousChar != '\r' || primary != '\n' ) {
					cc = primary ;
					if ( primary == '\r' ) cc = '\n' ;
					[ modem displayPrimary:cc ] ;
				}
				previousChar = primary ;
			}
			else {
				secondary = secvar[decoded] ;
				if ( secondary ) [ modem displaySecondary:secondary ] ;
			}
		}
	}
}

//	(Private API)
- (void)newSubBin
{
	int i ;
	SubBin *s ;
	
	for ( i = 0; i < 16; i++ ) {
		s = &subbin[i] ;
		s->energy *= 0.7 ;	
		s->code[0] = s->code[accumulatedCodes] ;
		s->bin[0] = s->bin[accumulatedCodes] ;
	}
	accumulatedCodes = 0 ;										//  reset to first nibble
}

//	With FEC: send subbin information to FEC
//	Without FEC: accumulate nibbles for Nibble based Varicode
- (void)processSubbin:(int)subbinWithLargestEnergy
{
	int code ;
	SubBin *s ;
	float snr ;

	if ( useFEC ) {
		QuadBits preInterleave, postInterleave ;
	
		//  At this point we have identified the subbin that contains the largest energy; send to FEC
		s = &subbin[ subbinWithLargestEnergy ] ;
		accumulatedCodes = 0 ;						// no accumulation needed in FEC mode
		code = s->code[ accumulatedCodes ] ;
		
		//	adjust confidence factor for soft decoding if code is obviously wrong
		
		if ( softDecode ) {
			if ( s->notDecoded ) {
				code = 0 ;
				snr = 0.5 ;
			}
			else {
				snr = ssnr ;
				if ( snr < 0.5 ) snr = 0.5 ; else if ( snr > 1 ) snr = 1 ;		//  sanity check
			}
		}
		else snr = 1.0 ;
		
		//  for now, just use s/(s+n) ratio for soft decoding; note: the snr parameter must be above 0.5 to decode
		preInterleave.bit[0] = ( code & 0x8 ) ? snr : 1-snr ;
		preInterleave.bit[1] = ( code & 0x4 ) ? snr : 1-snr ;
		preInterleave.bit[2] = ( code & 0x2 ) ? snr : 1-snr ;
		preInterleave.bit[3] = ( code & 0x1 ) ? snr : 1-snr ;
		postInterleave = [ self deinterleave:preInterleave ] ;
		[ self convolutionDecodeMSB:postInterleave.bit[0] LSB:postInterleave.bit[1] ] ;		//  decode first two bits
		[ self convolutionDecodeMSB:postInterleave.bit[2] LSB:postInterleave.bit[3] ] ;		//  decode next two bits
	}
	else {
		//  At this point we have identified the subbin that contains the largest energy, see if that sub-bin has a "start bit"
		s = &subbin[ subbinWithLargestEnergy ] ;
		code = s->code[ accumulatedCodes ] ;

		s->index = subbinWithLargestEnergy ;
		s->terminatingCode = code ;

		if ( code < 8 ) {
			[ self newIFSKVaricode:s length:accumulatedCodes ] ;
			[ self newSubBin ] ; 
		}
		if ( accumulatedCodes >= 3 ) {
			//  code length exceeded DominoEX specs, flush it
			[ self newIFSKVaricode:s length:accumulatedCodes ] ;
			[ self newSubBin ] ; 
		}
		accumulatedCodes = ( accumulatedCodes+1 )%8 ;
	}
}

//	(Private API)
//	Differential 18FSK decode
//	Input is an array of 16x oversampled frequency bins.
- (void)ifskDecode:(float*)vector
{
	float maxv, avgv, v, largestEnergy, peak ;
	int i, index, bin, subbinWithLargestEnergy, peakIndex, fecCode ;
	SubBin *s ;
	
	accumulatedCodes %= 8 ;		//  sanity check
	
	//  find largest vector for each of the 16 sub-bins and energy
	largestEnergy = 0 ;
	subbinWithLargestEnergy = 0 ;
	peakIndex = 0 ;
	for ( bin = 0; bin < 16; bin++ ) {
		s = &subbin[bin] ;
		maxv = avgv = 0 ;
		index = 0 ;
		for ( i = bin; i < 512; i += 16 ) {
			v = vector[i] ;
			avgv += v;
			if ( v > maxv ) {
				maxv = v ;
				index = i ;
			}
		}
		//  accumulate energy
		v = ( s->energy += maxv ) ;
		if ( v > largestEnergy ) {
			largestEnergy = v ;
			subbinWithLargestEnergy = bin ;
			peakIndex = index ;
		}
		index = ( ( index + 8 )/16 ) & 0x1f ;
		// treat LSB differently
		s->code[ accumulatedCodes ] = fecCode = iFSKDecodeVector[ index ][ s->mostRecentBin ] ;
		s->notDecoded = ( fecCode < 0 || fecCode > 15 ) ;
		s->nextRecentBin = s->mostRecentBin ;
		s->mostRecentBin = s->bin[ accumulatedCodes ] = index ;
	}
	
	// estimate carrier to noise ratio
	avgv = 0.0001 ;
	for ( i = 64; i < 448; i += 16 ) {
		avgv += vector[( peakIndex+i )%512 ] ;
	}
	avgv /= 24 ;
	
	peak = vector[peakIndex] ;
	cnr = cnr*0.92 + 0.08*( peak/avgv ) ;
	ssnr = ssnr*0.92 + 0.08*( peak/ ( peak + avgv ) ) ;

	[ self processSubbin:subbinWithLargestEnergy ] ;
}

//	(Private API)
- (void)updateIndicators:(float*)powerSpectrum threshold:(float)threshold
{
	float u, binOffset[16] ;
	int i, k, minOffset, maxOffset, diffOffset, offset, binMax, binBoundary ;
	
	for ( minOffset = 0; minOffset < 510; minOffset++ ) if ( avgSpectrum[minOffset] > threshold ) break ;
	for ( maxOffset = 510; maxOffset >= 0; maxOffset-- ) if ( avgSpectrum[maxOffset] > threshold ) break ;
	
	//  afcState = 0 - no AFC (afcOffset = 0)
	//  afcState = 1 - perform AFC (update afcOffset)
	//  afcState = 2 - hold afc (don't update afcOffset)
	
	diffOffset = ( maxOffset-minOffset )/16.0 + 0.5 ;
	if ( diffOffset == m ) {
		//  identified bins
		offset = minOffset + 16*5 ;
		//	use all bins of aveSpectrum to identify the bin offset
		for ( k = 0; k < 16; k++ ) {
			u = 0 ;
			for ( i = k; i < 512; i += 16 ) u += avgSpectrum[i] ;
			binOffset[k] = u ;
		}
		//  now find max bin
		u = binOffset[0] ;
		binMax = 0 ;
		for ( i = 1; i < 16; i++ ) {
			if ( binOffset[i] > u ) {
				u = binOffset[i] ;
				binMax = i ;
			}
		}
		//  use bin averages to adjust offset boundary
		binBoundary = binMax-8 ;
		if ( binBoundary < 0 ) binBoundary += 16 ;
		k = offset/16 ;
		i = offset - k*16 ;
		if ( i < 4 && binBoundary > 12 ) k-- ; else if ( i > 12 && binBoundary < 4 ) k++ ;
		offset = k*16 + binBoundary ;
	}
	else offset = 0 ;
		
	if ( afcState == 1 && offset > 0 ) {
		//	Move the RxFreq offset relative to where it was clicked (0 offset = clicked position)	
		if ( offset != previousModemOffset ) {	
			[ modem applyRxFreqOffset:offset*11.025/16.0 - ( CARRIEROFFSET*18.0/16.0 ) ] ;		//  18 bins instead of 16 MFSK16 bins
		}
	}
	//  output to tuning indicator
	if ( freqIndicator ) {
		//  center display around 28 FSK channels			
		[ freqIndicator newWideSpectrum:&powerSpectrum[32] ] ;
		if ( offset > 0 && offset != previousModemOffset ) [ freqLabel setAbsoluteOffset:( offset- 16*5 - 22 ) ] ;
	}
	previousModemOffset = offset ;
}

//  Accepts a new vector of (length) 32 or 64 data samples that are aligned to the symbol clock.
//  Note that the input data are aligned in time, but the tones don't necessarily fall at the center of an FFT bin.
//  This routine creates the frequency alignment.
//	Note that "receive AFC" is always being performed.  The AFC switch only affects transmit sync with receive.
//	Half rate DominoEX modes (8,5) call this with 64 samples, regular rate DominoEX (22,16,11,4) call this with 32 samples
- (void)afcVector:(DSPSplitComplex*)vector length:(int)length
{
	DSPSplitComplex input, output ;
	float vi[512], vq[512], u, threshold ;
	float iOrderedSpectrum[768], qOrderedSpectrum[768], powerSpectrum[512] ;
	int i, k ;
	float *p, *q ;
	
	//  Zero fill and apply a 512 point FFT.
	//  This provides a higher resolution spectrum to find a better estimate of the frequency offset.
	memset( &vi[length], 0, sizeof( float )*( 512-length ) ) ;
	memset( &vq[length], 0, sizeof( float )*( 512-length ) ) ;	
	memcpy( vi, vector->realp, sizeof( float )*length ) ;
	memcpy( vq, vector->imagp, sizeof( float )*length ) ;

	//  take FFT of zero filled 512 samples
	input.realp = &vi[0] ;
	input.imagp = &vq[0] ;
	output.realp = &iOrderedSpectrum[256] ;			//  offset to order spectrum later
	output.imagp = &qOrderedSpectrum[256] ;
	CMPerformComplexFFT( afcFFT, &input, &output ) ;
	
	//  Copy second half of FFT output to the beginning of the result.
	//	The result is an ordered spectrum starting at iOrderedSpectrum[0] (lowest frequency) to iOrderedSpectrum[511] (highest frequency).
	memcpy( iOrderedSpectrum, &iOrderedSpectrum[512], sizeof( float )*256 ) ;
	memcpy( qOrderedSpectrum, &qOrderedSpectrum[512], sizeof( float )*256 ) ;
	
	//	Convolve with a rectangular filter.
	threshold = 0 ;
	for ( i = 0; i < 512; i++ ) {
		u = 0 ;
		if ( i < 512-9 ) {
			p = &iOrderedSpectrum[i] ;
			q = &qOrderedSpectrum[i] ;
			for ( k = 0; k < 9; k++ ) {
				u += ( p[k]*p[k] + q[k]*q[k] ) ;
			}
		}
		powerSpectrum[i] = u ;
					
		//  fast charge slow discharge to obtain average spectrum
		if ( u > avgSpectrum[i] ) {
			u = avgSpectrum[i]*0.2 + u*0.8  ;
		}
		else {
			u = avgSpectrum[i]*0.98 + u*0.02  ;
		}
		avgSpectrum[i] = u ;
		if ( u > threshold ) threshold = u ;
	}
	//  go decode from the spectrum
	[ self ifskDecode:powerSpectrum ] ;	
	[ self updateIndicators:powerSpectrum threshold:threshold*0.3 ] ;
}

- (void)resetDemodulatorState
{
	int i ;
	
	memset( iTime, 0, sizeof( float )*2048 ) ;
	memset( qTime, 0, sizeof( float )*2048 ) ;
	ringIndex = 0 ;
	//  clear clock extraction FIR pipe
	memset( timeAperture, 0, sizeof( float )*64 ) ;
	ssnr = 1.0 ;

	for ( i = 0; i < 32; i++ ) CMPerformFIR( clockExtractFilter, avgSpectrum, 32, timeAperture ) ;
}

- (void)waterfallClicked
{
	[ self resetDemodulatorState ] ;	
	//  clear the average spectrum and symbol clock filter
	memset( avgSpectrum, 0, sizeof( float )*512 ) ;
	[ self newSubBin ] ; 
	holdoff = -2 ;
}

//  use fixed clock extraction for DominoEX
- (void)setClockExtraction:(int)cycles
{
}

//	--- FEC ---

//	Accumulate bits into the bit register.
//  If the signature of the end of a character is seen, flush the accumulated bits to the Varicode decoder.
- (void)varicodeDecode:(int)bit 
{
	int c, secondary ;
	
	decodedBits = ( (decodedBits << 1)  | ( bit&1 ) ) ;
	c = decodedBits & 0x7;
	if ( c == 0x1 ) {
		//  001 received.  00 is the stop bits of a code word and 1 is the start bit of the new code.
		c = [ varicode decode:( decodedBits /= 2 ) ] ;
		
		#ifdef CERTEST
		total++ ;	
		
		if ( c != 131 && total > 50 ) {
			error++ ;
			printf( "*** Beacon error rate %6.2f %% (%4d)\n", ( error*100.0 )/( total-50 ), total ) ;
		}
		//  3500 characters for DominoEX 8 (about 40 minutes of FEC beacon of E)
		if ( total > 7000*baudRate/15.625 ) {
			NSLog( @"Beacon error rate %6.3f %% (%d)", ( error*100.0 )/( total-50 ), total ) ;
			exit( 0 ) ;
		}
		#endif

		if ( c > 0 && modem ) {
			secondary = secondaryFECDecodeTable[ c & 0xff ] ;
			if ( cnr > squelchThreshold*2 ) {
				if ( secondary != 0 ) [ modem displaySecondary:secondary ] ; else if ( c != 0 ) [ modem displayPrimary:c ] ;
			}
			previousChar = c ;
		}
		//  retain only the most recent non-zero bit
		decodedBits = 1;
	}
}

static int deinterleaveStride[] = { 5, 5, 9, 13, 17, 21, 25, 29, 33, 37, 41 } ;
static int deinterleaveSize[] = { 16, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160 } ;

//  Default to 4 stage deinterleaverStages
- (QuadBits)deinterleave:(QuadBits)p
{
	int i, mod ;
	QuadBits quad ;
	
	mod = deinterleaveSize[interleaverStages] ;
	//  fetch the four deinterleaved bits before overwriting some with the new data
	for ( i = 0; i < 4; i++ ) quad.bit[i] = interleaverRegister[ ( interleaverIndex+i*deinterleaveStride[interleaverStages] )%mod ] ;
	//  insert new bits into register
	for ( i = 0; i < 4; i++ ) interleaverRegister[interleaverIndex+i] = p.bit[i] ;
	//  increment the pointer for the next QuadBits set
	interleaverIndex = ( interleaverIndex + 4 )%mod ;	
	
	return quad ;
}

@end
