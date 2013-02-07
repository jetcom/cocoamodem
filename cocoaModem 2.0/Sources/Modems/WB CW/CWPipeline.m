//
//  CWPipeline.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/25/06.
	#include "Copyright.h"
	
	
#import "CWPipeline.h"
#import "CWMatchedFilter.h"

@implementation CWPipeline

//  [matchedFilter] -> importArray -> stateChangedTo -> processElement -> updateMorseElement -> newCharacter -> [MatchedFilter] ->  [MorseDecoder] .
- (id)initFromClient:(CWMatchedFilter*)matchedFilter
{
	self = [ super init ] ;
	if ( self ) {
		client = matchedFilter ;
		
		clearFloat( dataBuffer, 2048 ) ;
		clearFloat( noiseBuffer, 2048 ) ;
		dataBufferIndex = 0 ;
				
		adjustWaveshapedBoxcarFilter( iAGCFilter = BoxcarFilter( 190, FILTERLENGTH ), 60 ) ;
		adjustWaveshapedBoxcarFilter( qAGCFilter = BoxcarFilter( 190, FILTERLENGTH ), 60 ) ;

		adjustWaveshapedBoxcarFilter( iDecimateFilter = BoxcarFilter( 190, FILTERLENGTH ), 175 ) ;
		adjustWaveshapedBoxcarFilter( qDecimateFilter = BoxcarFilter( 190, FILTERLENGTH ), 175 ) ;
		
		//  post processing limited data filter
		dataFilter0 = BoxcarFilter( 24, 24 ) ;
		dataFilter1 = BoxcarFilter( 24, 24 ) ;
		dataFilter2 = BoxcarFilter( 24, 24 ) ;
		
		keyState = 0 ;
		[ self initElement:&previousElement state:0 valid:NO ] ;
		[ self initElement:&currentElement state:0 valid:NO ] ;
		[ self initElement:&dataElement state:0 valid:NO ] ;
		
		//  thresholds
		[ self setSquelch:-30.0 fastQSB:-20.0 slowQSB:-35.0 ] ;		//  allow fast qqsb to be 20 dB deep.
		keyInterval = timeoutTime = currentState = 0 ;
	}
	return self ;
}

- (void)initElement:(ElementType*)element state:(int)state valid:(Boolean)valid
{
	element->state = state ;
	element->max = 0.0 ;
	element->min = 1.0 ;
	element->interval = 1 ;
	element->valid = valid ;
}

- (void)getNoiseThresholdFromHistogram
{
	float histogram[256], low, middle, high, peak, x ;
	int j, k, n, count ;

	//  first check histogram of local levels
	clearFloat( histogram, 240 ) ;
	peak = 0.0001 ;
	for ( j = 0; j < 100; j++ ) {
		k = ( dataBufferIndex + j - 101 + 2048 ) & 0x7ff ;
		x = noiseBuffer[k] ;
		if ( x > peak ) peak = x ;
	}
	for ( j = 0; j < 100; j++ ) {
		k = ( dataBufferIndex + j - 101 + 2048 ) & 0x7ff ;
		count = noiseBuffer[k]/peak*239.0 ;
		if ( count > 239 ) count= 239 ;
		histogram[count] += 0.003 ;
		n = count ;
		for ( k = 1; k < 16; k++ ) histogram[count+k] += 0.003 ;
		n = 16 ;
		if ( n > count ) n = count ;
		for ( k = 1; k < n; k++ ) histogram[count-k] += 0.003 ;
	}
	//  "signal" is sqrt(i*i+q*q) and therefore has a Rayleigh distribution if the original signal is Gaussian noise dominated.
	//	signal is considered noisy if middle third of the density funtion (histogram) is larger than high third of the density function.
	low = middle = high = 0 ;
	for ( j = 0; j < 80; j++ ) low += histogram[j] ;
	for ( j = 80; j < 150; j++ ) middle += histogram[j] ;
	for ( j = 160; j < 240; j++ ) high += histogram[j] ;
	
	x = middle/(high+middle) ;
	if ( x < 0.5 && high > 0.1*low ) {
		noiseGate = 0.0 ;
		//  now compute peak from the actual signal (instead of the noise gate signal, which goes through a different BPF)
		peak = 0.001 ;
		for ( j = 0; j < 100; j++ ) {
			k = ( dataBufferIndex + j - 101 + 2048 ) & 0x7ff ;
			x = dataBuffer[k] ;
			if ( x > peak ) peak = x ;
		}
		threshold = peak*0.5 ;
	}
	else {
		//  noisy, keep existing threshold
		noiseGate = 1.0 ;
	}
}

- (void)importArray:(float*)array
{
	float x, y, iFiltered[512], qFiltered[512], iDecimateFiltered[512], qDecimateFiltered[512], signal ;
	int i, j, state, t ;
	
	//  At this point, sampling rate is 11025 s/s, lowpass I & Q channels
	//	(one Morse element at 50 wpm is approx 264 elements at 11025 s/s)
	CMPerformFIR( iAGCFilter, array, 512, iFiltered ) ;
	CMPerformFIR( qAGCFilter, array+512, 512, qFiltered ) ;
	CMPerformFIR( iDecimateFilter, array, 512, iDecimateFiltered ) ;
	CMPerformFIR( qDecimateFilter, array+512, 512, qDecimateFiltered ) ;
	
	//  Process data with 8:1 decimation (64 samples)
	for ( i = 0; i < 64; i++ ) {
		j = i*8 ;
		if ( ( i%32 ) == 0 ) [ self getNoiseThresholdFromHistogram ] ;
		
		x = iFiltered[j] ;
		y = qFiltered[j] ;
		noiseBuffer[dataBufferIndex] = sqrt( x*x + y*y ) ;		
		x = iDecimateFiltered[j] ;
		y = qDecimateFiltered[j] ;
		dataBuffer[dataBufferIndex] = sqrt( x*x + y*y ) ;

		dataBufferIndex = ( dataBufferIndex+1 ) & 0x7ff ;
				
		//  pick data sample delayed by 92 samples in data buffer
		t = ( dataBufferIndex + 2048 - 92 ) & 0x7ff ;
		signal = dataBuffer[ t ] ;
	
		smoothedThreshold = smoothedThreshold*0.99 + threshold*0.01 ;
		x = ( signal > smoothedThreshold ) ? 1.0 : 0.0 ;
		x = ( CMSimpleFilter( dataFilter0, x ) > dataThreshold ) ? 1.0 : 0.0 ;
		x = ( CMSimpleFilter( dataFilter1, x ) > dataThreshold ) ? 1.0 : 0.0 ;
		x = CMSimpleFilter( dataFilter2, x ) ;
		if ( x > dataElement.max ) dataElement.max = x ;
		if ( x < dataElement.min ) dataElement.min = x ;
		state = ( x > dataThreshold ) ? 1 : 0 ;
		if ( state != dataElement.state ) {
			//  interval ended
			dataElement.valid = YES ;
			[ self stateChangedTo:&dataElement ] ;
			//  craete next interval
			dataElement.state = state ;
			dataElement.interval = 1 ;
			dataElement.max = 0.0 ;
			dataElement.min = 1.0 ;
		}
		else {
			dataElement.interval++ ;
			if ( dataElement.state == 0 && dataElement.interval > 20 ) {
				//  self imposed timeout to flush the last character, if it is an interword, it is accumulated in -stateChangedTo:
				[ self stateChangedTo:&dataElement ] ;
				dataElement.interval = 1 ;
			}
		}
	}
}

- (void)stateChangedTo:(ElementType*)latestElement
{
	Boolean noisy ;
	
	if ( latestElement->interval <= 0 ) return ;
	
	if ( latestElement->state == currentElement.state ) {
		//  actual state did not change, accumulate into current element
		currentElement.interval += latestElement->interval ;
		if ( latestElement->max > currentElement.max ) currentElement.max = latestElement->max ;
		if ( latestElement->min < currentElement.min ) currentElement.min = latestElement->min ;
		
		if ( currentElement.state == 0 && currentElement.interval > [ client interWord ]/2 ) {
		
			//  flush a word without waiting until the next character to come along
			if ( previousElement.valid ) [ self processElement:&previousElement ] ;
			previousElement.valid = NO ;
			
			//currentElement.interval *= 2;
			[ self processElement:&currentElement ] ;
			currentElement.interval = 0 ;
		}		
		return ;
	}
	else {
		// state apparently changed, check if currentElement (the one before this latest interval) looks like noise
		noisy = ( currentElement.state == 0 ) ? ( currentElement.min > 0.05 ) : ( currentElement.max < 0.95 ) ;

		if ( noisy ) {
			//  merge up to three elements is middle element is noisy
			currentElement.state = latestElement->state ;	
			currentElement.interval += latestElement->interval ;
			if ( latestElement->max > currentElement.max ) currentElement.max = latestElement->max ;
			if ( latestElement->min < currentElement.min ) currentElement.min = latestElement->min ;
			// merge previousElement into current element if previousElement is valid			
			if ( previousElement.valid ) {
				currentElement.interval += previousElement.interval ;
				if ( previousElement.max > currentElement.max ) currentElement.max = previousElement.max ;
				if ( previousElement.min < currentElement.min ) currentElement.min = previousElement.min ;
			}
			previousElement.valid = NO  ;
			return ;
		}
		else {
			//  new state received, flush out previousElement if valid...
			if ( previousElement.valid ) {
				[ self processElement:&previousElement ] ;
			}
			//  ... and copy currentElement into previousElement...
			previousElement = currentElement ;
			currentElement = *latestElement ;
		}
	}
}

- (void)processElement:(ElementType*)element
{
	//  process element for CWPipeline
	//  CWSpeedPipeline has a different -processElement method
	[ client updateMorseElement:element pipe:self ] ;
}

- (void)updateFilter:(int)elementLength
{
	int filterLength ;

	//  adjust matched filter
	//  max matched filter is for approx 12 wpm
	filterLength = elementLength*8 ;		//  matched filter at 11025, while element is defined at 11025/8 sampling rate
	if ( filterLength > 1010 ) filterLength = 1010 ; 
	else if ( filterLength < 200 ) filterLength = 200 ;

	adjustWaveshapedBoxcarFilter( iDecimateFilter, filterLength ) ;
	adjustWaveshapedBoxcarFilter( qDecimateFilter, filterLength ) ;
}


//  squelch value (0.0 means fully squelched)
- (void)setSquelch:(float)db fastQSB:(float)fastQSB slowQSB:(float)slowQSB
{
	squelch = pow( 10.0, db/20.0 )*0.25 ;
	threshold = smoothedThreshold = squelch ;
}

- (void)newClick
{
}

@end
