//
//  PSKDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/11/07.

#import "PSKDemodulator.h"
#import "PSK.h"
#import "PSKMatchedFilter.h"
#import "VCO8k.h"
#include <math.h>

@implementation PSKDemodulator

- (void)clearImd
{
	int i ;
	IMDBuffer *b ;
	
	imdBufferIndex = 0 ;
	bitSyncPhase = -1 ;
	previousI = previousQ = 0 ;
	imdMux = 0 ;
	b = &imdRingBuffer[0] ;
	for ( i = 0; i < 64; i++ ) {
		b->imd = b->carrier = b->noise = 0 ;
	}
	[ self updateIMD:0 snr:-1.0 ] ;
}

- (id)init
{
	int i ;
	float bw ;
	
	self = [ super init ] ;
	if ( self ) {
	
		modem = nil ;				//  v0.78 controlling modem
		modemIndex = 0 ;			//  0 or 1 to identify the receiver
		
		[ self clearImd ] ;
	
		crlfCheck = 0 ;
		psk125 = NO ;
		
		freqError = 0 ;
		for ( i = 0; i < 32; i++ ) freqErrors[i] = 0 ;
		forcedAFC = 0 ;
		previousClockSample = 0.1 ;
		
		//  replace 512 point FFT with 1024 pt FFT
		CMDeleteFFT( fft ) ;
		fft = FFTForward( 10, YES ) ;
		freeAnalyticBuffer( spec ) ;
		spec = CMMallocAnalyticBuffer( 1024 ) ;

		//  update imd every 1/2 second
		CMDeleteFFT( imdFFT ) ;
		imdFFT = FFTForward( 9, YES ) ;
				
		//  swap a 8000 sampling rate VCO
		[ vco release ] ;
		vco = [ [ VCO8k alloc ] init ] ;
		[ vco setCarrier:receiveFrequency ] ;
		
		//  replace decimation filter with one that has 32 samples per chip
		CMDeleteComplexFIR( decimate31 ) ;
		CMDeleteComplexFIR( decimate63 ) ;
		//  complex decimation lowpass filter for baseband analytic signal (100 Hz cutoff)
		//	Actual matched filtering is performed in PSKMatchedFilter
		decimate = decimate31 = CMComplexFIRDecimateWithCutoff( 8, 200.0, 8000.0, 512 ) ;
		//  complex decimation lowpass filter for PSK63 baseband analytic signal (300 Hz cutoff)
		decimate63 = CMComplexFIRDecimateWithCutoff( 4, 300.0, 8000.0, 512 ) ;
		//  complex decimation lowpass filter for PSK63 baseband analytic signal (400 Hz cutoff)
		decimate125 = CMComplexFIRDecimateWithCutoff( 2, 400.0, 8000.0, 512 ) ;
		// replace comb filter with a 1000 s/s one
		CMDeleteFIR( comb ) ;
		//  comb filter with phase to generate a -ve to +ve zero crossing at tail of matched filter
		comb = CMFIRCombFilter( 31.25, 8000.0/8, 2048, -0.8 ) ;		//  v0.96b clock to center Matched filter; offset was +0.1

		//  replace matched filter with the PSKVer3 matched filter
		pskMatchedFilter = [ [ PSKMatchedFilter alloc ] init ] ;
		[ pskMatchedFilter setDelegate:self ] ;
		
		// replace original filters
		CMDeleteFIR( dataFilterI ) ;
		CMDeleteFIR( dataFilterQ ) ;
		//  32 Hz data filter with Fs/8 sampling rate
		bw = 31.25 * 0.98 ;		//  v0.96c was *0.91
		dataFilterI = CMFIRLowpassFilter( bw, 8000.0/8, 512 ) ;
		dataFilterQ = CMFIRLowpassFilter( bw, 8000.0/8, 512 ) ;
		
		//  48 Hz acquisition filter with Fs/8 sampling rate
		bw = 48 ;
		acqFilterI = CMFIRLowpassFilter( bw, 8000.0/8, 512 ) ;
		acqFilterQ = CMFIRLowpassFilter( bw, 8000.0/8, 512 ) ;
	}
	return self ;
}

//  v0.78
- (void)setPSKModem:(PSK*)master index:(int)index
{
	modem = master ;
	modemIndex = index ;
}

//  0.64f -- added PSK125 to setPSKMode
- (void)setPSKMode:(int)mode
{
	psk125 = ( mode & 0x8 ) != 0 ;	
	pskMode = mode & 0x3 ;
	
	//  samples per buffer after decimation
	if ( pskMode == kBPSK31 || pskMode == kQPSK31 ) {
		decimatedLength = 32 ;
		decimate = decimate31 ;
	}
	else {
		if ( psk125 == NO ) {
			decimatedLength = 64 ;
			decimate = decimate63 ;
		}
		else {
			decimatedLength = 128 ;
			decimate = decimate125 ;
		}
	}
	if ( modem ) [ (PSK*)modem setReceiveFrequency:receiveFrequency mode:decimatedLength forReceiver:modemIndex ] ;
	decimatedOffset = 512-decimatedLength ;
}

- (Boolean)receiverEnabled
{
	return receiverEnabled ;
}

float px( float g )
{
	if ( g >= 0 ) return pow( g, 0.98 ) ; else return -pow( -g, 0.9 ) ;
}

//  prototype for -updateReceiveFrequencyDisplay in PSKReceiver
- (void)updateReceiveFrequencyDisplay:(float)freq
{
}

//  prototype for -setTransmitFrequencyToReceiveFrequency in PSKReceiver
- (void)setTransmitFrequencyToReceiveFrequency
{
}

//  prototype for -setRxOffset in PSKReceiver
- (void)setRxOffset:(float)freq
{
}

static int frame = 0 ;
static int pass = 0 ;
static float ibuf[256], qbuf[256], bbuf[256] ;

- (void)acquireFrequency:(int)range
{
	DSPSplitComplex sinput, output ;
	float u, v, num, denom, afcOffset ;
	int i, j ;

	//  perform FFT
	sinput.realp = &acquisitionBufferI[0] ;
	sinput.imagp = &acquisitionBufferQ[0] ;
	output.realp = &spec->re[0] ;
	output.imagp = &spec->im[0] ;
	CMPerformComplexFFT( fft, &sinput, &output ) ;
	
	//  numerator and denominator of centroid function
	num = denom = 0.0000001 ;
	//  1 Hz per bin, AFC search over (+,-)128 bins
	for ( i = 1; i < range; i++ ) {
		//  negative frequencies
		j = 1024-i ;
		v = spec->re[j] ;
		u = spec->im[j] ;
		u = sqrt( v*v + u*u ) ;
		num += -i*u ;
		denom += u ;
	}
	for ( i = 0; i < range; i++ ) {
		// positive frequencies
		v = spec->re[i] ;
		u = spec->im[i] ;
		u = sqrt( v*v + u*u ) ;
		num += i*u ;
		denom += u ;
	}
	//  afcOffset: +ve means the signal is higher in tone than the VCO
	afcOffset = num*1.024/denom ;
	[ vco tune:afcOffset ] ;
	receiveFrequency = [ vco frequency ] ;
	if ( delegate ) [ delegate updateReceiveFrequencyDisplay:receiveFrequency ] ;
}

//  estimate IMD every 512 (0.512 second) samples, spectrum has a resolution of about 2 Hz
- (Boolean)estimateIMD:(DSPSplitComplex*)spectrum
{
	float *re, *im, u, v, power10, power11, power30, power31, power2, power20, power21, power ;
	int i, index10, index11, diff ;
	
	re = spectrum->realp ;
	im = spectrum->imagp ;
	
	index10 = index11 = 0 ;
	power10 = power11 = -1 ;
	for ( i = 0; i < 16; i++ ) {
		v = re[i] ;
		u = im[i] ;
		power = v*v + u*u ;
		if ( power > power10 ) {
			power10 = power ;
			index10 = i ;
		}
	}
	
	if ( index10 < 7 || index10 > 9 ) return NO ;	//  ignore, too far off tuned
	
	for ( i = 1; i < 12; i++ ) {
		v = re[512-i] ;
		u = im[512-i] ;
		power = v*v + u*u ;
		if ( power > power11 ) {
			power11 = power ;
			index11 = -i ;
		}
	}
	diff = index10 - index11 ;
	
	if ( diff < 15 || diff > 17 ) return NO ;			// peaks don't correspond to idling PSK signal?
		
	//  power at 3rd IMD locations
	i = index10 + 16 ;
	v = re[i] ;
	u = im[i] ;
	power30 = v*v + u*u ;
	
	i = 512+index11-16 ;
	v = re[i] ;
	u = im[i] ;
	power31 = v*v + u*u ;
	
	//  power at 2nd IMD locations
	i = index10 + 24 ;
	v = re[i] ;
	u = im[i] ;
	power20 = v*v + u*u ;
	i = index10 + 23 ;
	v = re[i] ;
	u = im[i] ;
	power = ( power20 += v*v + u*u ) ;

	i = 512+index11-24 ;
	v = re[i] ;
	u = im[i] ;
	power21 = v*v + u*u ;
	i = 512+index11-23 ;
	v = re[i] ;
	u = im[i] ;
	power21 += v*v + u*u ;
	
	//  choose the quieter sideband (in case of QRM)
	if ( power21 < power2 ) power2 = power21 ;
		
	IMDBuffer *d, *b = &imdRingBuffer[imdBufferIndex] ;
	d = b + 128 ;
	imdBufferIndex = ( imdBufferIndex+127 ) & 0x7f ;	//  ready bufferIndex (backwards) for the next spectrum	
	
	//  insert IMD and noise samples
	b->imd = d->imd = power30+power31 ;
	b->carrier = d->carrier = power10+power11 ;
	b->noise = d->noise = power2 ;
	
	//  only update every second
	if ( ( imdBufferIndex & 1 ) != 0 ) return NO ;
			
	//  start with two sample and double until we have enough SNR
	float imd = 0, carrier = 0, noise = 0, imdr ;
	int k, pass ;
	
	k = 4 ;
	i = 0 ;
	
	for ( pass = 0; pass < 3; pass++ ) {
		for ( ; i < k; i++ ) {
			//  accumulate imd, carrier and noise power 
			imd += b->imd ;
			carrier += b->carrier ;
			noise += b->noise ;
			b++ ;
		}
		if ( imd > noise*4 || i >= 128 ) break ;
		k *= 2 ;
	}
		
	//  IMD, with noise correction term
	imdr = ( imd * imd )/( imd+noise+0.0000001 ) / ( ( carrier * carrier )/( carrier + noise + 0.0000001 ) + 0.0000001 ) ;	
	
	if ( imd > noise*2 ) {
		//  if IMD is +6 dB of noise, report unqualified IMD
		[ self updateIMD:imdr snr:imdr*1.01 ] ;
		return YES ;
	}
	//  noise limited case.
	if ( imdr < .0316 ) {
		//  if better than -15 dB IMD, report as noise limited number
		[ self updateIMD:imdr snr:imdr*0.99 ] ;
	}
	else {
		//  otherwise report as "NL"
		[ self updateIMD:-1.0 snr:0.01 ] ;
	}
	return YES ;
}

//  Process wide band input
//	Each call has one chip (32 samples) worth of data samples at 1000 samples/second
//	For the spectrum display, this is collected into 1024 sample frames and an FFT is done for each frame.
//	For the IMD calculations, this is collected into 512 sample frames and an FFT is done for each frame.
//	The result is used by the frequency and IMD indicators.
- (void)processWidebandBuffer:(float*)inphase quadrature:(float*)quadrature
{
	int i, offset ;
	DSPSplitComplex sinput, output ;
	float widebandSpecI[1024], widebandSpecQ[1024] ;
	float currentI, currentQ, detect ;
	
	freqIndicatorMux = freqIndicatorMux & 0x3e0 ;
	for ( i = 0; i < 32; i++ ) {
		freqIndicatorBufI[i+freqIndicatorMux] = inphase[i] ;
		freqIndicatorBufQ[i+freqIndicatorMux] = quadrature[i] ;
	}
	
	//  use a simple BPSK demodulator to look for 180 degree phase transitions
	if ( bitSyncPhase >= 0 && bitSyncPhase < 32 ) {
		currentI = inphase[bitSyncPhase] ;
		currentQ = quadrature[bitSyncPhase] ;
		detect = currentI*previousI + currentQ*previousQ ;		//  Eq. 4.10, Okunev
		previousI = currentI ;
		previousQ = currentQ ;
		if ( detect >= 0 || imdMux > 15 ) imdMux = 0 ;			//  not phase transition chip and sanity check
		//  insert chip into buffer
		offset = imdMux * 32 ;
		for ( i = 0; i < 32; i++ ) {
			imdBufI[offset+i] = inphase[i] ;
			imdBufQ[offset+i] = quadrature[i] ;
		}
		imdMux++ ;
		if ( imdMux >= 16 ) {
			imdMux = 0 ;
			//  successfully gathered 256 samples of consecutive phase changes
			if ( frequencyLocked ) {
				sinput.realp = &imdBufI[0] ;
				sinput.imagp = &imdBufQ[0] ;
				output.realp = &widebandSpecI[0] ;
				output.imagp = &widebandSpecQ[0] ;
				//  512 point FFT, windowed
				CMPerformComplexFFT( imdFFT, &sinput, &output ) ;
				[ self estimateIMD:&output ] ;
			}
		}
	}
	
	freqIndicatorMux += 32 ;
	if ( freqIndicatorMux >= 1024 ) {
		freqIndicatorMux = 0 ;
		if ( frequencyLocked ) {
			sinput.realp = &freqIndicatorBufI[0] ;
			sinput.imagp = &freqIndicatorBufQ[0] ;
			output.realp = &widebandSpecI[0] ;
			output.imagp = &widebandSpecQ[0] ;
			//  1024 point FFT, windowed
			CMPerformComplexFFT( fft, &sinput, &output ) ;
			[ self newSpectrum:&output size:1024 ] ;
		}
	}
}


#define	STARTWAIT		11
#define	ROUGHFETCH		12
#define	ROUGHACQUIRE	13
#define	ROUGHWAIT		14
#define	FINEFETCH		15
#define	FINEACQUIRE		16

//  32 data samples (one chip) arrives in each call to processChipBuffer (but data is not yet bit boundary aligned)
//  (1000 samples/sec)
- (void)processChipBuffer:(float*)inphase quadrature:(float*)quadrature
{
	int i, currentBit ;
	float mag, pi, pq, clockSample ;
	Boolean bitSync ;
	
	if ( acquire > 0 ) {
		switch ( acquire ) {
		case STARTWAIT:
			// wait for new acquisition buffer to make it through the pipeline after clicking
			acquireIndex++ ;
			if ( acquireIndex > 8 ) {
				acquireIndex = 0 ;
				acquire = ROUGHFETCH ;
			}
			break ;
		case ROUGHFETCH:
		case FINEFETCH:
			//  fetch buffers for FFT
			for ( i = 0; i < 32; i++ ) {
				acquisitionBufferI[acquireIndex] = inphase[i] ;
				acquisitionBufferQ[acquireIndex] = quadrature[i] ;
				acquireIndex++ ;
			}
			if ( acquireIndex >= 1024 ) acquire = ( acquire == ROUGHFETCH ) ? ROUGHACQUIRE : FINEACQUIRE ;
			break ;
		case ROUGHACQUIRE:
			// first (wideband) acquire frequency
			[ self acquireFrequency:64 ] ;
			acquire = ROUGHWAIT ;
			acquireIndex = 0 ;
			break ;
		case ROUGHWAIT:
			// wait for vco change in ROUGHACQUIRE to make it through the pipeline before fine acquire
			acquireIndex++ ;
			if ( acquireIndex > 2 ) {
				acquireIndex = 0 ;
				// acquire = FINEFETCH ;
				acquire = 0 ;				//  don't do fine adjustment, go directly to AFC
				forcedAFC = 10 ;
			}
			break ;
		case FINEACQUIRE:
			// second (narrowband) acquire frequency to refine acquisition
			[ self acquireFrequency:20 ] ;
			//  finished with frequency acquistion heuritics
			acquire = 0 ;
			break ;
		default:
			acquireIndex = forcedAFC = 0 ;
			acquire = STARTWAIT ;
		}
		return ;
	}
	frame++ ;
	
	for ( i = 0; i < 32; i++ ) {
		pi = inphase[i] ;
		pq = quadrature[i] ;
		mag = pi*pi + pq*pq + .00001 ;
		clockSample = CMSimpleFilter( comb, mag ) ;
		bitSync = ( previousClockSample < 0 && clockSample >= 0 ) ;
		previousClockSample = clockSample ;
			
		//  set up clock sync index in a unaligned chip (32 samples)
		//	This is used by the IMD logic
		if ( bitSync ) bitSyncPhase = i ; 
		
		ibuf[pass] = pi ;
		qbuf[pass] = pq ;
		bbuf[pass] = bitSync ;
		pass = ( pass+1 ) & 0xff ;
		
		if ( pskMode == kBPSK31 || pskMode == kBPSK63 ) {
			currentBit = [ (PSKMatchedFilter*)pskMatchedFilter bpsk:pi imag:pq bitSync:bitSync ] ;
		} else {
			currentBit = [ pskMatchedFilter qpsk:pi imag:pq bitPhase:bitSync ] ;
		}

		if ( bitSync ) {
		
			int chips ;
			
			if ( forcedAFC > 0 ) chips = 16 ; else chips = 32 ;		//  1/2 second updates during initial tuning

			//  afc track only every 16 chips
			cycle = ( cycle + 1 ) % chips ;
			
			float err = freqErrors[cycle] = 31.25*[ pskMatchedFilter phaseError ]/( 3.1415926*2 ) ;
			freqError += err ;
		
			if ( cycle == 0 ) {
			
				float tune = -freqError*3.1415926*0.5/chips ; 		//  average data from collected chips

				//  check AFC
				if ( [ self afcEnabled ] || forcedAFC > 0 ) {
				
					if ( forcedAFC == 6 ) frequencyLocked = YES ;	//  we should be close enough to print now
					
					//  look for quality of phase error
					float minerr, maxerr, deltaerr ;
					int e ;
					
					minerr = maxerr = freqErrors[0] ;
					for ( e = 1; e < chips; e++ ) {
						if ( freqErrors[e] > maxerr ) maxerr = freqErrors[e] ;
						if ( freqErrors[e] < minerr ) minerr = freqErrors[e] ;
					}
					deltaerr = maxerr - minerr ;
					if ( deltaerr < 1 ) deltaerr = 1 ;
					//  adjust AFC correction term base on phase error quality
					tune = tune/pow( deltaerr, 0.8 ) ;
					
					if ( forcedAFC > 0 ) {
						if ( tune > 1 ) tune = 1 ; else if ( tune < -1 ) tune = -1 ;
					}
					else {
						if ( tune > 0.25 ) tune = 0.25 ; else if ( tune < -0.25 ) tune = -0.25 ;
					}
					
					if ( fabs( tune ) > 0.05 ) {
						[ vco tune:tune ] ;
						receiveFrequency = [ vco frequency ] ;
						if ( delegate ) [ delegate updateReceiveFrequencyDisplay:receiveFrequency ] ;
					}
					if ( forcedAFC > 0 ) {
						forcedAFC-- ;
						if ( forcedAFC == 0 ) {
							//  assume we are tuned; transfer frequency to transmitter
							if ( delegate ) [ delegate setTransmitFrequencyToReceiveFrequency ] ;
							frequencyLocked = YES ;
						}
					}
				}
				freqError = 0 ;
			}
		}
	}
}

//  New data arrives from -newDataBuffer in 512 sample buffers, at 8000 samples/second
- (void)importBuffer:(float*)array
{
	float v, bufferI[256], bufferQ[256], decimatedI[256], decimatedQ[256] ;
	int i, j, k, n, samples ;
	CMAnalyticPair pair ;

	samples = decimatedLength ;
	
	//  decimate and process the 512 original input samples
	//  for PSK31, we mix it down by the VCO and decimate by a factor of 8 (1000 s/s)
	//  for PSK63, we mix it down by the VCO and decimate by a factor of 4	(2000 s/s)
	//  for PSK125, we mix it down by the VCO and decimate by a factor of 2	(4000 s/s)
	//	"samples = decimatedLength" 32 for PSK31, 64 for PSK63, 128 for PSK125, is used to identy the modes
	
	if ( samples == 32 ) {
		//  PSK31
		for ( n = 0; n < 64; n++ ) {
			j = n*8 ;
			for ( i = 0; i < 8; i++ ) {
				v = array[i+j] ;
				//  note:the VCO runs at a rate of Fs
				pair = [ vco nextVCOMixedPair:v ] ;
				input->re[i] = pair.re ;
				input->im[i] = pair.im ;
			}
			pair = CMDecimateAnalyticBuffer( decimate, input, 0 ) ;		//  decimation filter cutoffs are at 100 Hz
			decimatedI[n] = pair.re ;
			decimatedQ[n] = pair.im ;
			
			//  now apply data filter
			if ( acquire != 0 ) {
				//  use broader filter for acquisition
				bufferI[n] = CMSimpleFilter( acqFilterI, pair.re ) ;
				bufferQ[n] = CMSimpleFilter( acqFilterQ, pair.im ) ;
			}
			else {
				bufferI[n] = CMSimpleFilter( dataFilterI, pair.re ) ;
				bufferQ[n] = CMSimpleFilter( dataFilterQ, pair.im ) ;
			}
		}
	}
	else {
		if ( samples == 64 ) {			
			//  PSK63
			for ( n = 0; n < 128; n++ ) {
				j = n*4 ;
				for ( i = 0; i < 4; i++ ) {
					v = array[i+j] ;
					//  note:the VCO runs at a rate of Fs
					pair = [ vco nextVCOMixedPair:v ] ;
					input->re[i] = pair.re ;
					input->im[i] = pair.im ;
				}
				pair = CMDecimateAnalyticBuffer( decimate, input, 0 ) ;		//  decimation filter cutoffs are at 200 Hz
				decimatedI[n] = pair.re ;
				decimatedQ[n] = pair.im ;
				//  now apply data filter
				if ( acquire != 0 ) {
					//  use broader filter for acquisition
					bufferI[n] = CMSimpleFilter( acqFilterI, pair.re ) ;
					bufferQ[n] = CMSimpleFilter( acqFilterQ, pair.im ) ;
				}
				else {
					bufferI[n] = CMSimpleFilter( dataFilterI, pair.re ) ;
					bufferQ[n] = CMSimpleFilter( dataFilterQ, pair.im ) ;
				}
			}
		}
		else {
			if ( samples == 128 ) {
				for ( n = 0; n < 256; n++ ) {
					//  PSK125
					j = n*2 ;
					for ( i = 0; i < 2; i++ ) {
						v = array[i+j] ;
						//  note:the VCO runs at a rate of Fs
						pair = [ vco nextVCOMixedPair:v ] ;
						input->re[i] = pair.re ;
						input->im[i] = pair.im ;
					}
					pair = CMDecimateAnalyticBuffer( decimate, input, 0 ) ;		//  decimation filter cutoffs are at 400 Hz
					decimatedI[n] = pair.re ;
					decimatedQ[n] = pair.im ;
					//  now apply data filter
					if ( acquire != 0 ) {
						//  use broader filter for acquisition
						bufferI[n] = CMSimpleFilter( acqFilterI, pair.re ) ;
						bufferQ[n] = CMSimpleFilter( acqFilterQ, pair.im ) ;
					}
					else {
						bufferI[n] = CMSimpleFilter( dataFilterI, pair.re ) ;
						bufferQ[n] = CMSimpleFilter( dataFilterQ, pair.im ) ;
					}
				}
			}
		}
	}
	//  At this point, for PSK31 we have 64 samples (2 chips at 32 samples per chip) worth of data,
	//  For PSK63 we have 128 samples (4 chips at 32 samples per chip)
	[ self processChipBuffer:bufferI quadrature:bufferQ ] ;
	[ self processChipBuffer:bufferI+32 quadrature:bufferQ+32 ] ;	
	//  wideband (imd, etc)
	[ self processWidebandBuffer:decimatedI quadrature:decimatedQ ] ;
	[ self processWidebandBuffer:decimatedI+32 quadrature:decimatedQ+32 ] ;

	if ( samples != 32 ) {
		if ( samples == 64 ) {
			[ self processChipBuffer:bufferI+64 quadrature:bufferQ+64 ] ;
			[ self processChipBuffer:bufferI+96 quadrature:bufferQ+96 ] ;
			//  wideband (imd, etc)
			[ self processWidebandBuffer:decimatedI+64 quadrature:decimatedQ+64 ] ;
			[ self processWidebandBuffer:decimatedI+96 quadrature:decimatedQ+96 ] ;
		}
		else {
			//  PSK125  v0.64f
			if ( samples == 128 ) {
				for ( k = 64; k < 256; k += 32 ) {
					[ self processChipBuffer:bufferI+k quadrature:bufferQ+k ] ;
					//  wideband (imd, etc)
					[ self processWidebandBuffer:decimatedI+k quadrature:decimatedQ+k ] ;
				}
			}
		}
	}
	//  track PSK center frequency and IMD here using decimated data that has not passed through the data filter
}

//  new data arrives from PSKHub
//	disable print if it is from the click buffer
- (void)newDataBuffer:(float*)array samples:(int)inSamples
{
	int i ;

	if ( !receiverEnabled ) return ;
	
	assert( inSamples == 512 ) ;
	
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

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall
{
	// clear imd readings
	[ self clearImd ] ;	
	[ super selectFrequency:freq fromWaterfall:fromWaterfall ] ;	
	if ( modem ) [ (PSK*)modem setReceiveFrequency:freq mode:decimatedLength forReceiver:modemIndex ] ;
}

//  delegate method
- (void)receivedCharacter:(int)c spectrum:(float*)spectrum quality:(float)quality
{
	if ( delegate && [ delegate respondsToSelector:@selector(receivedCharacter:spectrum:quality:) ] ) [ delegate receivedCharacter:c spectrum:spectrum quality:quality ] ;
}

- (void)receivedBit:(int)bit
{
	printf( "-receivedBit: deprecated, use -receivedBit:quality: instead\n" ) ;
}

//  delegate of CMPSKMatchedFilter to receive decoded bits
//  new bit received from Matched Filter
- (void)receivedBit:(int)bit quality:(float)quality
{
	int decoded, previous ;
	
	//  wait for start bit
	if ( bit == 0 && varicodeCharacter == 0 ) return ;

	varicodeCharacter = varicodeCharacter*2 + bit ;
	if ( ( varicodeCharacter & 0x3 ) == 0 ) {

		if ( printEnabled ) {
			if ( defer++ < 0 ) return ;		//  this flushes two potential bad character syncs when print is initially enabled
			
			decoded = [ varicode decode:varicodeCharacter ] ;

			//  ignore cr/lf pairs  v0.57
			//  apparently some program sends 0xd/0xa from a file
			previous = crlfCheck ;
			crlfCheck = decoded ;
			if ( ( previous == 0xd && crlfCheck == 0xa ) || ( previous == 0xa && crlfCheck == 0xd ) ) {
				varicodeCharacter = 0 ;
				return ;
			}
			
			if ( defer == 1 ) [ self receivedCharacter:'\r' spectrum:imdSpectrum quality:1.0 ] ;
			[ self receivedCharacter:decoded spectrum:imdSpectrum quality:quality ] ;
			defer = 1 ;
			varicodeCharacter = 0 ;
		}
		else {
			varicodeCharacter = 0 ;
			defer = -2 ;
		}
	}
}


@end
