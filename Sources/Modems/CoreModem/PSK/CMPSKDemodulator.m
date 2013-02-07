//
//  CMPSKDemodulator.m
//  CoreModem
//
//  Created by Kok Chen on 11/3/05.
	#include "Copyright.h"
	
#import "CMPSKDemodulator.h"

@implementation CMPSKDemodulator

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		delegate = nil ;
		//  set up vco
		[ vco setDelegate:self ] ;
		[ vco setOutputScale:8.0 ] ;

		for ( i = 0; i < 65; i++ ) baseI[i] = baseQ[i] = bitClock[i] = 0 ;
		for ( i = 0; i < 256; i++ ) imdSpectrum[i] = -1.0 ;
		
		//  matched filter
		pskMatchedFilter = [ [ CMPSKMatchedFilter alloc ] init ] ;
		[ pskMatchedFilter setDelegate:self ] ;
		
		//  decimation lowpass filters for baseband analytic signal
		decimate = decimate31 = CMComplexFIRDecimateWithCutoff( 16, 300.0, CMFs, 256 ) ;
		//  decimation lowpass filters for PSK63 baseband analytic signal
		decimate63 = CMComplexFIRDecimateWithCutoff( 8, 300.0, CMFs, 256 ) ;
		
		//  32 Hz data filter with Fs/16 sampling rate
		dataFilterI = CMFIRLowpassFilter( 32, CMFs/16, 256 ) ;
		dataFilterQ = CMFIRLowpassFilter( 32, CMFs/16, 256 ) ;
		//  150 Hz filter to estimate IMD (must have same length as above)
		imdFilterI = CMFIRLowpassFilter( 150, CMFs/16, 256 ) ;
		imdFilterQ = CMFIRLowpassFilter( 150, CMFs/16, 256 ) ;
		
		//  comb filter with phase to generate a -ve to +ve zero crossing at data mid-bit
		comb = CMFIRCombFilter( 31.25, CMFs/16, 1024, 1.5708 ) ;
		
		//  varicode decoder
		varicode = [ [ CMVaricode alloc ] init ] ;
		
		mux = 0 ;
		pskMode = kBPSK31 ;
		decimatedLength = 32 ;
		decimatedOffset = 512-decimatedLength ;
		phaseLoop = lastAng = 0.0 ;
		imdBufferPointer = 0 ;
		lastBit = NO ;
		lastIMD = 123.0 ;
		cycle = 0 ;
		varicodeCharacter = 0 ;
		frequencyLocked = printEnabled = NO ;
		clickBufferProducer = clickBufferConsumer = 0 ;

		//  create aligned memory
		input = CMMallocAnalyticBuffer( 16 ) ;
		decimatedBuffer = CMMallocAnalyticBuffer( 512 ) ;
		spec = CMMallocAnalyticBuffer( 512 ) ;
		
		fft = FFTForward( 9, YES ) ;
		imdFFT = FFTForward( 8, YES ) ;
	}
	return self ;
}

/* local */
//  called from importData
//  0.17 - use FFT to estimate IMD
- (void)importBuffer:(float*)array
{
	float u, v, pi, pq, sum, diff, mag, angle, dAngle,imdi, imdq ;
	float f0, f1, fN, *iptr, *qptr ;
	float snr, imd ;
	CMAnalyticPair pair ;
	DSPSplitComplex sinput, output ;
	Boolean newBit, currentBit ;
	int i, j, n, samples, peak ;
	
	samples = decimatedLength ;
	//  move old decimation data over	
	CMShiftAnalyticBuffer( decimatedBuffer, samples ) ;
			
	//  decimate and process the 512 original input samples
	//  for PSK31, we mix it down by the VCO and decimate by a factor of 16
	//  for PSK63, we mix it down by the VCO and decimate by a factor of 8
	
	iptr = &decimatedBuffer->re[decimatedOffset] ;
	qptr = &decimatedBuffer->im[decimatedOffset] ;
	
	for ( n = 0; n < samples; n++ ) {
		if ( samples == 32 ) {
			j = n*16 ;
			//  mix down to baseband I and Q
			for ( i = 0 ; i < 16; i++ ) {
				v = array[i+j] ;
				//  note:the VCO runs at a rate of Fs
				pair = [ vco nextVCOMixedPair:v ] ;
				input->re[i] = pair.re ;
				input->im[i] = pair.im ;
			}
		}
		else {
			j = n*8 ;
			//  mix down to baseband I and Q
			for ( i = 0 ; i < 8; i++ ) {
				v = array[i+j] ;
				//  note:the VCO runs at a rate of Fs
				pair = [ vco nextVCOMixedPair:v ] ;
				input->re[i] = pair.re ;
				input->im[i] = pair.im ;
			}
		}		
		pair = CMDecimateAnalyticBuffer( decimate, input, 0 ) ;
		iptr[n] = pair.re ;
		qptr[n] = pair.im ;
	}

	//  process decimated data
	iptr = &decimatedBuffer->re[decimatedOffset] ;
	qptr = &decimatedBuffer->im[decimatedOffset] ;
	baseI[0] = baseI[samples] ;
	baseQ[0] = baseQ[samples] ;
	bitClock[0] = bitClock[samples] ;
	
	for ( n = 0; n < samples; n++ ) {	

		//  data filter
		baseI[n+1] = pi = CMSimpleFilter( dataFilterI, iptr[n] ) ;
		baseQ[n+1] = pq = CMSimpleFilter( dataFilterQ, qptr[n] ) ;
		mag = pi*pi + pq*pq + .00001 ;
		bitClock[n+1] = CMSimpleFilter( comb, mag ) ;
		
		imdi = CMSimpleFilter( imdFilterI, iptr[n] ) ;
		imdq = CMSimpleFilter( imdFilterQ, qptr[n] ) ;
		
		if ( imdBufferPointer >= 0 && imdBufferPointer < 288 ) {
			imdBufferI[imdBufferPointer] = imdi ;
			imdBufferQ[imdBufferPointer] = imdq ;
			imdBufferPointer++ ;
		}

		if ( frequencyLocked ) {
			if ( bitClock[n] < 0 && bitClock[n+1] >= 0 ) {
				if ( [ self afcEnabled ] ) {
					// AFC at midbit
					if ( fabs( pi ) < .001 && fabs( pq ) < .001 ) angle = 0.0 ; else 
					if ( fabs( pi ) < fabs( pq ) ) {
						angle = -atan(pi/pq) ; 
					}
					else {
						angle = atan(pq/pi) ;
					}
					if ( lastAng != 0 && lastAng*angle > 0 ) {
						if ( cycle == 0 ) {
							phaseLoop = phaseLoop*0.99 + ( angle - lastAng )*0.01*0.05 ;
							dAngle = phaseLoop ;
							[ vco tune:dAngle ] ;
						}
					}
					lastAng = angle ;
					//  afc track only every 2 cycles
					cycle++ ;
					if ( cycle > 2 ) cycle = 0 ;
				}
			}
			//  edge of data bit
			newBit = ( bitClock[n] > 0 && bitClock[n+1] <= 0 ) ;
			if ( pskMode == kBPSK31 || pskMode == kBPSK63 ) {
				currentBit = [ pskMatchedFilter bpsk:pi imag:pq bitPhase:newBit ] ;
			} else {
				currentBit = [ pskMatchedFilter qpsk:pi imag:pq bitPhase:newBit ] ;
			}
			if ( newBit ) {
	
				if ( lastBit != currentBit || fabs( [ pskMatchedFilter phaseError ] ) > 0.5 ) imdBufferPointer = 0 ; 
				lastBit = currentBit ;
				
				if ( imdBufferPointer >= 288 ) {
				
					sinput.realp = &imdBufferI[32] ;
					sinput.imagp = &imdBufferQ[32] ;
					output.realp = &spec->re[0] ;
					output.imagp = &spec->im[0] ;
					CMPerformComplexFFT( imdFFT, &sinput, &output ) ;
					
					for ( i = 0; i < 256; i++ ) {
						// compute power spectrum
						imdSpectrum[i] = spec->re[i]*spec->re[i] + spec->im[i]*spec->im[i] ;
					}
					//  search for peak at 0.5*31.25 Hz component
					peak = 1 ;
					f0 = imdSpectrum[1] ;
					for ( i = 2; i < 12; i++ ) {
						if ( imdSpectrum[i] > f0 ) {
							f0 = imdSpectrum[i] ;
							peak = i ;
						}
					}
					f0 += imdSpectrum[peak-1] + imdSpectrum[peak+1] + .001 ;
					
					f1 = 0 ;
					for ( i = 6; i < 18; i++ ) f1 += imdSpectrum[peak+i] ;

					peak += 18 ;		// position of 2.0*31.25 Hz (noise measure)
					fN = ( imdSpectrum[peak-2]+imdSpectrum[peak-1]+imdSpectrum[peak]+imdSpectrum[peak+1]+imdSpectrum[peak+2] )*2.0 ;
				
					snr = f0/( fN + .0000001 ) ;
					imd = f1/f0 ;
					if ( f1 > fN ) [ self updateIMD:imd snr:snr ] ;
					
					//  check for next idle pattern
					imdBufferPointer = 0 ;
				}
			}
		}
	}
	//  at this point, we have gathered 32 new samples at a rate of Fs/16 (or 64 new sampes at Fs/8 for PSK63)
	//  these have been appended into 512-sample decimatedI,decimatedQ buffers
	
	//  acquisition loop
	if ( mux++ >= 8 || acquire > 0 ) {
		//  moving window FFT (32 samples are updated each time)
		//  the PSK31 sidebands are located at about bins (+,-)24
		sinput.realp = &decimatedBuffer->re[0] ;
		sinput.imagp = &decimatedBuffer->im[0] ;
		output.realp = &spec->re[0] ;
		output.imagp = &spec->im[0] ;
		CMPerformComplexFFT( fft, &sinput, &output ) ;
			
		if ( acquire > 0 ) {
			hasIMD = NO ;
			imdBufferPointer = 0 ;
			//  FFT based AFC acquisition
			sum = 0.01 ;
			diff = 0 ;
			for ( i = 1; i < 24; i++ ) {
				v = spec->re[i] ;
				u = spec->im[i] ;
				u = sqrt( v*v + u*u ) ;
				diff += u*i ;
				sum += u*i ;
			}
			for ( i = 1; i < 24; i++ ) {
				v = spec->re[512-i] ;
				u = spec->im[512-i] ;
				u = sqrt( v*v + u*u ) ;
				diff -= u*i ;
				sum += u*i ;
			}
			u = diff/sum ;
			//  smoothing filter for acquisition loop
			acquisitionFilter = acquisitionFilter*0.3 + u*0.7 ;
			
			[ vco tune:acquisitionFilter ] ;

			if ( fabs( acquisitionFilter ) < 0.03 ) {
				acquire-- ;
				if ( acquire <= 0 ) {
					[ self setTransmitFrequency:[ vco frequency ] ] ;
					frequencyLocked = YES ;
				}
			}
		}
	}
	[ self newSpectrum:&output size:512 ] ;
}

//  new PSK data (512 samples per buffer, 0.046 seconds)
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *array ;
	int i ;

	if ( !receiverEnabled ) return ;
	
	stream = [ pipe stream ] ;
	array = stream->array ;
	
	//  copy into clickBuffer
	memcpy( &clickBuffer[clickBufferProducer], array, sizeof( float )*512 ) ;
	clickBufferProducer = ( clickBufferProducer+512 ) & 0x1ffff /* wrap to 128K buffer */ ;
	
	if ( !frequencyLocked ) {		//  use history click buffer
		// not locked yet, feed new data into demodulator
		[ self importBuffer:array ] ;
	}
	else {
		if ( !printEnabled ) varicodeCharacter = 0 ;
		printEnabled = YES ;
		for ( i = 0; i < 4; i++ ) {
			//  flush and clicked data at 4x speed
			if ( clickBufferProducer == clickBufferConsumer ) break ;
			[ self importBuffer:&clickBuffer[clickBufferConsumer] ] ;
			clickBufferConsumer = ( clickBufferConsumer+512 ) & 0x1ffff ; // wrap to 128K buffer
		}
	}
}

- (void)setPSKMode:(int)mode
{
	pskMode = mode ;
	//  samples per buffer after decimation
	if ( pskMode == kBPSK31 || pskMode == kQPSK31 ) {
		decimatedLength = 32 ;
		decimate = decimate31 ;
	}
	else {
		decimatedLength = 64 ;
		decimate = decimate63 ;
	}
	decimatedOffset = 512-decimatedLength ;
}

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall
{
	if ( fromWaterfall ) {	
		//  turn FFT based AFC aquisition on
		frequencyLocked = printEnabled = NO ;
		clickBufferProducer = clickBufferConsumer = 0 ;
		acquisitionFilter = 0.0 ;
		acquire = 10 ;					//  number of frame for acquistion
	}
	else {
		frequencyLocked = YES ;
		acquire = 0 ;
	}
	//  now setup receive VCO
	receiveFrequency = freq ;
	[ vco setCarrier:freq ] ;
	receiverEnabled = YES ;
}

//  delegate of CMPSKMatchedFilter to receive decoded bits
//  new bit received from Matched Filter
- (void)receivedBit:(int)bit
{
	int decoded, i ;
	DSPSplitComplex sinput, output ;
	
	//  wait for start bit
	if ( bit == 0 && varicodeCharacter == 0 ) return ;
	
	varicodeCharacter = varicodeCharacter*2 + bit ;
	if ( ( varicodeCharacter & 0x3 ) == 0 ) {
		if ( printEnabled ) {
			decoded = [ varicode decode:varicodeCharacter ] ;
			
					sinput.realp = &decimatedBuffer->re[256] ;
					sinput.imagp = &decimatedBuffer->im[256] ;
					output.realp = &spec->re[0] ;
					output.imagp = &spec->im[0] ;
					CMPerformComplexFFT( imdFFT, &sinput, &output ) ;
					
					for ( i = 0; i < 256; i++ ) {
						// compute power spectrum
						imdSpectrum[i] = spec->re[i]*spec->re[i] + spec->im[i]*spec->im[i] ;
					}

			[ self receivedCharacter:decoded spectrum:imdSpectrum ] ;
			varicodeCharacter = 0 ;
		}
	}
}

//  delegate of CMPSKMatchedFilter
- (void)updateVCOPhase:(float)ang
{
	[ self updatePhase:ang ] ;
}

//  delegate of CMPCO
- (void)vcoChangedTo:(float)tone
{
	receiveFrequency = tone ;
	[ self updateDisplayFrequency:tone ] ;
}

- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate ;
}

- (id)delegate
{
	return delegate ;
}

//  delegate method
- (void)newSpectrum:(DSPSplitComplex*)buf size:(int)length
{
	if ( delegate && [ delegate respondsToSelector:@selector(newSpectrum:size:) ] ) [ delegate newSpectrum:buf size:length ] ;
}

//  delegate method
- (Boolean)afcEnabled
{
	if ( delegate && [ delegate respondsToSelector:@selector(afcEnabled) ] ) return [ delegate afcEnabled ] ;
	return NO ;
}

//  delegate method
- (float)squelchValue
{
	if ( delegate && [ delegate respondsToSelector:@selector(squelchValue) ] ) return [ delegate squelchValue ] ;
	return NO ;
}

//  delegate method
- (void)updateIMD:(float)imd snr:(float)snr
{
	//  snr == 0 -- no reading
	if ( imd == lastIMD ) return ;
	lastIMD = imd ;
	
	if ( delegate && [ delegate respondsToSelector:@selector(updateIMD:snr:) ] ) [ delegate updateIMD:imd snr:snr ] ;
}

//  delegate method
- (void)updateDisplayFrequency:(float)tone
{
	if ( delegate && [ delegate respondsToSelector:@selector(updateDisplayFrequency:) ] ) [ delegate updateDisplayFrequency:tone ] ;
}

//  delegate method
- (void)setTransmitFrequency:(float)tone
{
	if ( delegate && [ delegate respondsToSelector:@selector(setTransmitFrequency:) ] ) [ delegate setTransmitFrequency:tone ] ;
}

//  delegate method
- (void)receivedCharacter:(int)c spectrum:(float*)spectrum
{
	if ( delegate && [ delegate respondsToSelector:@selector(receivedCharacter:spectrum:) ] ) [ delegate receivedCharacter:c spectrum:spectrum ] ;
}

//  delegate method
- (void)updatePhase:(float)ang
{
	if ( delegate && [ delegate respondsToSelector:@selector(updatePhase:) ] ) [ delegate updatePhase:ang ] ;
}

@end
