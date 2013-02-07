//
//  DominoHalfRateDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/4/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DominoHalfRateDemodulator.h"
#import "MFSK.h"

@implementation DominoHalfRateDemodulator

//	Half Rate DominoEX
- (id)initAsMode:(int)mode
{
	int i ;
	float v ;
	
	self = [ self initAsDomino:mode ] ;
	if ( self ) {
		inputMux = 0 ;
		previousCode = 256 ;
		nibbles = 0 ;
		
		//	clock recovery (64 bins)
		clockExtractFFT = FFTForward( 6, NO /* window */ ) ;
		
		//  N clock cycles of extraction kernel (each cycle is 64 samples)
		clockExtractionCycles = 2*6 ;													//  must be even number to represent 64 sample cycles
		prevClock = 0.0 ;
		
		clockExtractFilter = CMFIRLowpassFilter( 4, 500, ( clockExtractionCycles )*32 ) ;
		//  4 extra cycles for fading
		for ( i = 0; i < ( clockExtractionCycles )*32; i++ ) {
			v = -cos( i*3.1415926535/32.0 ) ;	
			clockExtractFilter->kernel[i] = clockExtractKernel[i] = v ;	
		}				
		[ self waterfallClicked ] ;
		[ self resetDemodulatorState ] ;
	}
	return self ;
}

//  New buffer of 32 complex samples arrived
//  Data is assumed to be sampled at 500 samples/second (each symbol clock is therefore 32 samples from one another)
//
//	For half rate DominoEX modes, we accumulate 64 samples before looking for symbol sync
//	-newBuffer:: finds the time alignment and -afcVector: finds the frequency alignment
- (void)newBufferedData:(float*)iBuf imag:(float*)qBuf
{
	DSPSplitComplex input, output ;
	int i, k, index, size, dt ;
	float v, mean, maxv, track[64] ;
	float iSpec[64], qSpec[64] ;
	
	if ( iBuf[0] == 0 && qBuf[0] == 0 ) return ;
	
	//  copy the next 32 samples into the double ring buffer
	size = 32*sizeof( float ) ;
	ringIndex %= 1024 ;
	memcpy( &iTime[ringIndex], &iBuf[0], size ) ;
	memcpy( &iTime[ringIndex+1024], &iBuf[0], size ) ;
	memcpy( &qTime[ringIndex], &qBuf[0], size ) ;
	memcpy( &qTime[ringIndex+1024], &qBuf[0], size ) ;
	ringIndex = ( ringIndex + 32 ) % 1024 ;

	//  process every other 32-samples buffers, since we need to process 64 samples at a time
	if ( inputMux++ < 1 ) return ;
	inputMux = 0 ;
	
	//  Find approx time peak by sliding a 64-point time window and taking a 64-point FFT for each window.
	//	If the FFT is not time aligned, the total power of an IFK signal is split between two bins.  Their energy add, but the square of the sum will be max only when there is time alignment.
	//  For each FFT, the max energy bin is recorded.
	//  The clockExtractFilter provides a sufficient lowpass comb to interpolate the missing data.
	//	Note that the symbol period is twice that of the frame preriod (i.e., one symbol every 64 samples).
	for ( k = 0; k < 64; k++ ) {
		index = ( ringIndex + ( 1024 - 192 ) )%1024 ;
		input.realp = &iTime[k+index] ;
		input.imagp = &qTime[k+index] ;
		output.realp = &iSpec[0] ;
		output.imagp = &qSpec[0] ;
		//  64 point FFT
		CMPerformComplexFFT( clockExtractFFT, &input, &output ) ;
		//  find bin leakage for non time-synchronized transforms
		for ( mean = maxv = 0, i = 0; i < 64; i++ ) {
			v = ( iSpec[i]*iSpec[i]+ qSpec[i]*qSpec[i] ) ;
			mean += v ;
			v = v*v ;
			if ( v > maxv ) maxv = v ;
		}
		if ( mean < .0001 ) return ;
		maxv = maxv/( mean*mean ) ;
		timeAperture[k] =  timeAperture[k] * 0.95 + maxv ;
	}

	//  apply the (running) lowpassed comb to find the symbol alignment
	CMPerformFIR( clockExtractFilter, timeAperture, 64, track ) ;

	//  Find the zero crossing from the 64 filtered symbol transitions. 	
	//  The premise is that the output of the comb will produce a periodic signal that is aligned to the symbol timing.
	//  When we find a zero crossing, that identifies the symbol time alignment and an aligned 32 element data array (at 500 Hz sampling rate) is 
	//  passed to -newTimeVector: to process.
	for ( i = 0; i < 64; i++ ) {
		//  look for a zero crossing and then apply offset to the peak
		//	assume cycle of 64
		if ( prevClock <= 0 && track[i] > 0 ) {
			// found zero crossing, update median filter
			dt = i ;
			if ( fabs( prevClock ) < track[i]*1.5 ) dt-- ;				
			index = ( ringIndex + dt + ( 1024 - 512 + 48 ) )%1024 ;		//  the offset is derived from optimizong DominoEX 8 at -14 dB SNR
			timeOffset = dt ;
			input.realp = &iTime[index] ;
			input.imagp = &qTime[index] ;
			[ self afcVector:&input length:64 ] ;
		}
		prevClock = track[i] ;
	}	
}

//	(Private API)
//	Differential 18FSK decode
//	Input is an array of 16x oversampled frequency bins.
- (void)ifskDecode:(float*)vector
{
	float maxv, v, avgv, largestEnergy, peak ;
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
		s->code[ accumulatedCodes ] = fecCode = iFSKDecodeVector[ index ][ s->mostRecentBin ] ;		
		s->notDecoded = ( fecCode < 0 || fecCode > 15 ) ;
		s->nextRecentBin = s->mostRecentBin ;
		s->mostRecentBin = s->bin[ accumulatedCodes ] = index ;
	}

	peak = vector[peakIndex] ;
	
	// estimate carrier to noise ratio
	if ( peak > 0.000001 ) {
		avgv = peak ;
		for ( i = peakIndex + 240; i < peakIndex + 272; i++ ) {
			avgv += vector[i%512] ;
		}
		avgv /= 32.0 ;
		
		//	S/(S+N) = 1 when no noise
		if ( peak > 0.000001 ) {
		
			float p = peak/( peak + avgv ) ;
			if ( p > ssnr ) ssnr = ssnr*0.92 + 0.08*p ; else ssnr = ssnr*0.98 + 0.02*p ;
			
			cnr = cnr*0.92 + 0.08*( peak/( avgv + .0000001 ) ) ;
		}
	}
	
	/*
	avgv = 0.0001 ;
	for ( i = 64; i < 448; i += 16 ) {
		avgv += vector[( peakIndex+i )%512 ] ;
	}
	avgv /= 24 ;
	
//	ssnr = ssnr*0.92 + 0.08*( ( peak ) / ( peak + avgv ) ) ;
*/

	[ self processSubbin:subbinWithLargestEnergy ] ;
}


@end
