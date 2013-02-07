//
//  MFSK16Demodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/16/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSK16Demodulator.h"
#import "MFSK.h"

@implementation MFSK16Demodulator


- (id)init
{
	int i ;
	float v ;
	
	self = [ super init ] ;
	
	if ( self ) {
		// clock recovery (32 bins)
		clockExtractFFT = FFTForward( 5, YES /*window*/ ) ;
		//  N clock cycles of extraction kernel (each cycle is 32 samples)
		clockExtractionCycles = 15 ;
		prevClock = 0.0 ;
		clockExtractFilter = CMFIRLowpassFilter( 4, 500, clockExtractionCycles*32 ) ;
		for ( i = 0; i < clockExtractionCycles*32; i++ ) {
			v = -cos( i*3.1415926535/16.0 ) ;	
			clockExtractFilter->kernel[i] = clockExtractKernel[i] = v ;	
		}
		[ self resetDemodulatorState ] ;
	}
	return self ;
}

- (void)setInterleaverStages:(int)stages
{
	interleaverStages = 10 ;
}

//  24 bins decoded from the raw signal, the 16 (18 for Domino) desired bins should be within this set.
//
//  Wait until we have established that the highest received bin is 15 bins (17 for Domino) higher than the lowest received bin before decoding.
//  In the meantime, buffer up the input.
//  NOTE: check the offset for cases where the peak moves to an adjacent bin.
//
//  return the lowest bin chosen or zero if not yet locked
- (int)newFreqVector:(float*)vector
{	
	int i, j, index, delta, highest, lowest, count ;
	float maxv, v, searchVector[24] ;
	FreqBins *bins ;
	Boolean inSync ;
	
	lowest = 0 ;		//  v0.73
	
	//  Keep constant track of the range of bins received, use a fast attack slow delay function for each bin so that 
	//  a bin "stays around" for a little while.
	maxv = 0.001 ;
	for ( i = 0; i < 24; i++ ) {
		//  accumulate bins using fast attack slow decay
		if ( vector[i] > smoothedVector[i] ) {
			v = smoothedVector[i]*0.5 + vector[i]*0.5 ;
		}
		else {
			v = smoothedVector[i]*0.98 + vector[i]*0.02 ;
		}			
		searchVector[i] = smoothedVector[i] = v ;
		if ( v > maxv ) maxv = v ;
	}
	
	
	maxv = 1.0/maxv ;
	count = 0 ;
	for ( i = 0; i < 24; i++ ) {
		searchVector[i] *= maxv ;
		if ( searchVector[i] > 0.1 ) count++ ; else searchVector[i] = 0 ;  // v0.73 changed threshold from 0.01 to 0.05
	}
		
	delta = 0 ;	
	if ( count > 2 ) {
		//  search for up to m largest ones (m = 16 for MFSK16, 18 for DominoEX-16,...)
		highest = 0 ;
		lowest = 24 ;
		for ( i = 0; i < m; i++ ) {
			maxv = 0.0 ;
			index = 0 ;
			//  find surviving member
			for ( j = 0; j < 24; j++ ) {
				v = searchVector[j] ;
				if ( v > maxv ) {
					maxv = v ;
					index = j ;
				}
			}
			if ( maxv < 0.01 ) break ;		// finished search
			searchVector[index] = -1 ;
			if ( index > highest ) highest = index ;
			if ( index < lowest ) lowest = index ;
		}
		delta = highest - lowest ;
	}
	
	lowestAFCBin = ( delta == (m-1) ) ? lowest : ( -1 ) ;
	
	if ( afcState == 1 ) {
		//  AFC is turned on
		//  Stay in sync as long as we are already in sync and there are fewer than 16 bins separating the bins that are above the threshold
		if ( delta >=  m ) {
			hasSync = NO ;
		}
		else {
			if ( hasSync ) {
				// was in sync, we just need a few bins that are above the threshold to remain in sync
				hasSync = ( count > 3 ) ;
			}
			else {
				// was not in sync, wait until we see 12 bins above the threshold plus the delta is 15 to switch to synced state
				// to be more conservative, we can use count >= 16.
				hasSync = ( delta == ( m-1 ) && count >= 12 ) ;
			}
		}
		inSync = hasSync ;
	}
	else {
		//  AFC is either turned off or on hold
		if ( afcState == 0 ) {
			// AFC is turned off, use the central 16 bins, (if AFC is on hold, mainain the most recent AFC bin)
			lowestAFCBin = 5 ;
		}
		lowest = lowestAFCBin ;
		inSync = YES ;
	}
	if ( delta == ( m-1 ) && count > 3 ) {
		//  candidate lowest and highest (plus two others in between) bins identified
		//  turn freq indicator label into locked state before flushing click buffer
		//  update UI even before the first character is decoded
		
		[ self updateRxFreqLabelAndField:lowestAFCBin ] ;
				
		//  assume we are still in sync if the delta is 15 and we have at least 4 bins that have recently been touched 
		if ( hasSync || count > 4 ) {
			
			//  intermediate bins all active, flush saved data
			while ( bufferedFreqConsumer != bufferedFreqProducer ) {
				//  consume any unused data
				[ self decodeBins:bufferedFreqBins[bufferedFreqConsumer].bin+lowest buffered:YES ] ;
				bufferedFreqConsumer = ( bufferedFreqConsumer+1 )%0xff ;
			}
			//  send most recent data
			[ self decodeBins:vector+lowest buffered:NO ] ;
			//  and reset the buffer pointers for the next time we are out of range
			bufferedFreqProducer = bufferedFreqConsumer = 0 ;
			return lowestAFCBin ;
		}
	}
	//  Have not yet established a frequency range to decode the bins, buffer them up for now
	//  v0.73 make some sanity check before buffering (delta > 1 confirms a DominoEX df = 2)
	if ( lowest > 0 && delta > 1 ) {
		if ( delta >= m ) {
			// delta wider than MFSK range?
			bufferedFreqProducer = bufferedFreqConsumer = 0 ;
		}
		else {
			bins = &bufferedFreqBins[bufferedFreqProducer] ;
			for ( i = 0; i < 24; i++ ) bins->bin[i] = vector[i] ;
			bufferedFreqProducer = ( bufferedFreqProducer+1 )&0xff ;
			if ( bufferedFreqProducer == bufferedFreqConsumer ) {
				//  Overrun.  Keep only the most recent 256 values
				bufferedFreqConsumer = ( bufferedFreqConsumer+1 )&0xff ;
			}
		}
	}	
	return 0 ;
}

//  Accepts a new vector of 32 or 64 data samples that are aligned to the symbol clock.
//  Note that the input data are aligned in time, but the tones don't necessarily fall at the center of an FFT bin.
//  This routine creates the frequency alignment.
//
//	For MFSK16, length is assumed to always be 32
- (void)afcVector:(DSPSplitComplex*)vector length:(int)length
{
	DSPSplitComplex input, output ;
	float vi[512], vq[512], u, v, peak ;
	float iSpec[512], qSpec[512], iOrderedSpectrum[512], qOrderedSpectrum[512], powerSpectrum[384] ;
	int i, j, k, offset, binOffset ;
	
	//  Zero fill and apply a 512 point FFT.
	//  This provides a higher resolution spectrum to find a better estimate of the frequency offset.
	for ( i = 0; i < 32; i++ ) {
		vi[i] = vector->realp[i] ;
		vq[i] = vector->imagp[i] ;
	}
	for ( ; i < 512; i++ ) vi[i] = vq[i] = 0.0 ;
	input.realp = &vi[0] ;
	input.imagp = &vq[0] ;
	output.realp = &iSpec[0] ;
	output.imagp = &qSpec[0] ;
	CMPerformComplexFFT( afcFFT, &input, &output ) ;
	//  512 point order spectrum from lowest to highest frequency
	for ( i = 0; i < 512; i++ ) {
		j = ( i + 256 ) % 512 ;
		iOrderedSpectrum[i] = iSpec[j] ;
		qOrderedSpectrum[i] = qSpec[j] ;
	}
	
	//  afcState = 0 - no AFC (afcOffset = 0)
	//  afcState = 1 - perform AFC (update afcOffset)
	//  afcState = 2 - hold afc (don't update afcOffset)
	if ( afcState == 1 ) {
		//  update afcOffset value
		//  first find the offset of the global peak
		//	v0.73 sum 11 bins instead of looking for the tallest bin.
		offset = 5 ;
		peak = -1 ;
		for ( i = 0; i < 512-11; i++ ) {
			for ( u = v = 0, k = 0; k < 11; k++ ) {
				u += iOrderedSpectrum[i+k] ;
				v += qOrderedSpectrum[i+k] ;
			}
			u = u*u + v*v ;
			if ( u > peak ) {
				peak = u ;
				offset = i+5 ;
			}
		}
		//  Now fold the offset (reduce it to offset within a bit width)
		offset = offset%16 ;
		
		//  The following AFC code is changed to accomodate DominoEX which just uses offset as the "current" tone
		int diff = ( offset-absoluteOffset+1024 )%16 ;
		if ( diff >= 8 ) diff = diff - 16 ;
		
		correction = correction*0.75 + diff*0.25 ;
		absoluteOffset += correction ;
	}
	else {
		if ( afcState == 0 ) absoluteOffset = 48 ;
	}
	
	//  Resample the spectrum at the absolute offset to get 24 samples
	//	the next step (-newFreqVector:) will pick the proper 16 of these 24 to use	
	for ( i = 0; i < 24; i++ ) {
		j = i*16 + absoluteOffset - 6 ;											//  v0.73
		for ( u = v = 0, k = 0 ; k < 13; k++ ) {
			u += iOrderedSpectrum[k+j] ;
			v += qOrderedSpectrum[k+j] ;
		}
		iSpec[i] = u*u + v*v ;
	}	
	//  16 of these 24 bins are the actual data
	//  returned value has the coarseness of an MFSK channel spacing (i.e., 16x the original 512 point FFT)
	binOffset = [ self newFreqVector:iSpec ] ;
		
	//  output to tuning indicator
	if ( freqIndicator ) {
		for ( i = 0; i < 384; i++ ) {
			u = iOrderedSpectrum[i+MFSKFREQOFFSET] ;
			v = qOrderedSpectrum[i+MFSKFREQOFFSET] ;
			powerSpectrum[i] = u*u + v*v ;
		}
		[ freqIndicator newSpectrum:&powerSpectrum[0] ] ;		
		if ( binOffset <= 0 ) binOffset = 0 ;
		[ self updateRxFreqLabelAndField:binOffset ] ;
	}
}

//  tone weights in gray code
const int grayDecode[] = {
	0x0, 0x1, 0x3, 0x2,
	0x6, 0x7, 0x5, 0x4,
	0xc, 0xd, 0xf, 0xe, 
	0xa, 0xb, 0x9, 0x8
} ;

//  convert an array of 16 frequency bins into a 4 bit index.
//  Reindexed as a gray code by using the toneWeight array
//  The offset parameter chooses which is the first vector in the input array to use as the base bin.
//
//  Returns the 4-bit index of 1-of-16 bins after gray code rearrangement.
//  Each of the 4 bits are returns as a foating point number between 0 and 1.0, for use in soft decoding.
- (QuadBits)softEncode:(float*)vector
{
	QuadBits result ;
	float maxv, noisev, u, v, pr, mappedVector[16], accum0, accum1, accum2, accum3 ;
	int i, index, largest ;
	
	// zero-address the vector vector[0..15] is now the range.
	//  initialize to bin 0 
	result.bit[0] = result.bit[1] = result.bit[2] = result.bit[3] = 0.0 ;
	
	//  check CNR
	//  find largest vector
	maxv = vector[0] ;
	index = 0 ;
	for ( i = 1; i < 16; i++ ) {
		v = vector[i] ;
		if ( v > maxv ) {
			maxv = v ;
			index = i ;
		}
	}
	noisev = 0 ;
	for ( i = 0; i < 16; i++ ) {
		if ( i != index ) {
			v = vector[i] ;
			noisev += v ;
		}
	}
	noisev = noisev/15 ;
	//  normalize noise to 1 Hz noise bandwidth, apply delay and then smooth
	v = maxv/( ( noisev + 0.000001 )*3 ) ;
	//  Estimate carrier to noise ratio
	//  the thruput through the de-interleaver is about 40 clock cycles
	//  deinterlever outputs two dibits per clock cycle, and the Viterbi decoder is set to 45 lags or about 22 clock cycles
	//  A 64 stage delay line is used to delay the CNR measurement for use as the output CNR.
	cnrCycle &= 0x3f ;
	u = delayedCNR[cnrCycle] ;
	delayedCNR[cnrCycle] = v ;
	cnrCycle++ ;
	cnr = cnr*0.92 + v*0.08 ;
		
	if ( !softDecode ) {
		//  hard decoder
		//  use largest vector as 4 bit code word
		largest = grayDecode[index] ;
		result.bit[0] = ( largest & 0x8 ) ? 1.0 : 0.0 ;
		result.bit[1] = ( largest & 0x4 ) ? 1.0 : 0.0 ;
		result.bit[2] = ( largest & 0x2 ) ? 1.0 : 0.0 ;
		result.bit[3] = ( largest & 0x1 ) ? 1.0 : 0.0 ;
	}
	else {
		//  soft decoder
		//  factor of 1.35 arrived at empirically with Gaussian noise
		for ( i = 0; i < 16; i++ ) {
			v =  vector[i] ;
			mappedVector[grayDecode[i]] = pow( v, 1.35 ) ;
		}		
		//  normalize input vector into probabilities
		u = 0.0000001 ;
		for ( i = 0; i < 16; i++ ) u += mappedVector[i] ;
		for ( i = 0; i < 16; i++ ) mappedVector[i] /= u ;

		accum0 = accum1 = accum2 = accum3 = 0.0 ;
		for ( i = 0; i < 16; i++ ) {
			pr = mappedVector[i] ;
			if ( i & 0x8 ) accum0 += pr ;
			if ( i & 0x4 ) accum1 += pr ;
			if ( i & 0x2 ) accum2 += pr ;
			if ( i & 0x1 ) accum3 += pr ;
		}
		result.bit[0] = accum0 ;
		result.bit[1] = accum1 ;
		result.bit[2] = accum2 ;
		result.bit[3] = accum3 ;
	}
	return result ;
}

//	added v0.73 
- (void)decodeBins:(float*)vector buffered:(Boolean)state
{
	[ self decodeBits:[ self softEncode:vector ] ] ;
}

//  Concatenated deinterleaver of 10 stages of the the IZ8BLY Diagonal Interleaver
//  This is a rederivation of the concatenated 4x4 interleaver that is described in
//  http://www.qsl.net/zl1bpu/MFSK/Interleaver.htm
//
//  The recurrence equation is solved as a single linear table that is 160 units long rather 
//	that ten tables that are arranged in 4x4 units.

- (QuadBits)deinterleave:(QuadBits)p
{
	int i ;
	QuadBits quad ;
	
	//  fetch the four deinterleaved bits before overwriting some with the new data
	for ( i = 0; i < 4; i++ ) quad.bit[i] = interleaverRegister[ ( interleaverIndex+i*41 )%160 ] ;
	//  insert new bits into register
	for ( i = 0; i < 4; i++ ) interleaverRegister[interleaverIndex+i] = p.bit[i] ;
	//  increment the pointer for the next QuadBits set
	interleaverIndex = ( interleaverIndex + 4 )%160 ;	
	
	return quad ;
}


@end
