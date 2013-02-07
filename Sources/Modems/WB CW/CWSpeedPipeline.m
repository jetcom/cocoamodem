//
//  CWSpeedPipeline.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/27/06.
	#include "Copyright.h"
	
#import "CWSpeedPipeline.h"
#import "CWMatchedFilter.h"

@implementation CWSpeedPipeline

//  [matchedFilter] -> importArray -> stateChangedTo -> processElement.

- (id)initFromClient:(CWMatchedFilter*)matchedFilter
{
	self = [ super initFromClient:matchedFilter ] ;
	if ( self ) {

		spectrum = FFTSpectrum( 12, YES ) ;
		
		clearFloat( keyHistogram, 1024 ) ;	
		clearFloat( unkeyHistogram, 1024 ) ;	
		[ self newClick ] ;
	}
	return self ;
}

- (void)newClick
{
	int i ;
	
	for ( i = 0; i < 64; i++ ) intervalHistory[i].valid = NO ;
	intervalHistoryIndex = 0 ;
	for ( i = 0; i < 4; i++ ) speedEstimate[i] = 20.0 ;
}

//  Save element into the interval history.
//  The interval history is used whenever a speed estimate is needed
- (void)processElement:(ElementType*)element
{
	intervalHistory[intervalHistoryIndex] = *element ;
	intervalHistoryIndex = ( intervalHistoryIndex+1 ) & 0x3f ;
}

- (void)addHistogramElement:(ElementType*)e histogram:(float*)histogram
{
	int i, k, n ;
	
	if ( e->state == 0 ) {
		if ( e->min > 0.02 ) return ;
	}
	else {
		if ( e->max < 0.98 ) return ; 
	}
	
	n = e->interval ;
	for ( i = 0; i < 16; i++ ) {
		k = n - 16 + i ;
		if ( k > 0 && k < 1024 ) histogram[k] += i ;
	}
	for ( i = 16; i > 0; i-- ) {
		k = n + 16 - i ;
		if ( k > 0 && k < 1024 ) histogram[k] += i ;
	}
}

//  create a histogram of intervalHistory
- (int)makeHistograms
{
	ElementType *e ;
	int i, n ;
	
	clearInt( keyHistogram, 1024 ) ;
	clearInt( unkeyHistogram, 1024 ) ;
	n = 0 ;
	for ( i = 0; i < 64; i++ ) {
		e = &intervalHistory[i] ;
		if ( e->valid == YES ) {
			[ self addHistogramElement:e histogram:( e->state == 0 ) ? unkeyHistogram : keyHistogram ] ;
			if ( e->state == 0 ) n++ ;
		}
	}
	return n ;
}

//  estimate code speed from the intervalHistory
- (MorseTiming)estimateMorseTiming 
{
	MorseTiming result ;
	int i, n, nmin, nmax, lowerLimit, upperLimit ;
	float min, max, sum, v, m, d, initial, lower, higher, estimate, initialEstimate, lowEstimate, highEstimate, interelementEstimate, keyValue, sorted[4] ;

	result.speed = 0 ;
	if ( [ self makeHistograms ] < 8 ) return result ;	//  not enough data since beginning
	
	
	//  check keyed data if it is very noisy at the low end (very rapid changes)
	m = d = 0.0 ;
	for ( i = 0; i < 16; i++ ) m += keyHistogram[i] ;
	for ( i = 16; i < 250; i++ ) d += keyHistogram[i] ;
	if ( m > d ) return result ;

	//  check unkeyed data if it is very noisy at the low end (very rapid changes)
	m = d = 0.0 ;
	for ( i = 0; i < 16; i++ ) m += unkeyHistogram[i] ;
	for ( i = 16; i < 250; i++ ) d += unkeyHistogram[i] ;
	if ( m > d ) return result ;
		
	//  first estimate dit rate
	m = 0.0 ;
	n = 0 ;
	for ( i = 16; i < 1024; i++ ) {
		v = keyHistogram[i] ;
		if ( v > m ) {
			m = v ;
			n = i ;
		}
	}
	if ( n > 340 ) n /= 3 ;
	
	//  find mean around the guess
	lowerLimit = n - 16 ;
	upperLimit = n + 16 ;
	m = 0.0 ;
	d = .00001 ;
	for ( i = lowerLimit; i < upperLimit; i++ ) {
		v = keyHistogram[i] ;
		m += v*i ;
		d += v ;
	}
	estimate = initialEstimate = m/d ;
	n = initialEstimate + 0.5 ;
	if ( n < 10 ) return result ;
	
	initial = keyHistogram[n] + 0.00001 ;
	
	//  look for peak around n/3
	lowerLimit = n/3 - 8 ;
	upperLimit = n/3 + 8 ;
	if ( lowerLimit < 0 ) lowerLimit = 0 ;
	m = 0.0 ;
	d = .00001 ;
	for ( i = lowerLimit; i < upperLimit; i++ ) {
		v = keyHistogram[i] ;
		m += v*i ;
		d += v ;
	}
	lowEstimate = m/d ;
	if ( lowEstimate < lowerLimit || lowEstimate > upperLimit ) lowEstimate = n/3 ;
	lower = keyHistogram[ (int)( lowEstimate + 0.5 ) ]/initial ;
	
	//  now look for peak at between 2.5 and 3.8 x of n
	lowerLimit = n*2.5 ;
	upperLimit = n*3.5 ;
	if ( upperLimit > 1024 ) upperLimit = 1024 ;
	m = 0.0 ;
	d = .00001 ;
	for ( i = lowerLimit; i < upperLimit; i++ ) {
		v = keyHistogram[i] ;
		m += v*i ;
		d += v ;
	}
	highEstimate = m/d + 0.5 ;
	if ( highEstimate < lowerLimit || highEstimate > upperLimit ) highEstimate = n*3 ;
	
	higher = keyHistogram[ (int)( highEstimate +0.5 ) ]/initial ;
	
	if ( ( lower + higher ) > 0.1 ) {
		
		if ( higher < 0.1 && lower > higher*2 && n > 45 ) estimate = lowEstimate ;
		//  check is energy is in the high frequencies (small interval numbers), if so, reject as noise
		if ( estimate < 8 ) return result ;
		
		n = estimate + 0.5 ;
		keyValue = keyHistogram[n] ;
		
		if ( keyValue < .01 ) return result ;
				
		//  now check the interelement (unkeyed) spacings
		lowerLimit = n - 16 ;
		upperLimit = n + 16 ;
		m = 0.0 ;
		d = .00001 ;
		for ( i = lowerLimit; i < upperLimit; i++ ) {
			v = unkeyHistogram[i] ;
			m += v*i ;
			d += v ;
		}
		interelementEstimate = m/d ;
		n = interelementEstimate ;
		v = unkeyHistogram[n]/keyValue ;
		if ( v < 0.18 ) return result ;
		
		v = 18.0*92.0*2.0/( estimate+interelementEstimate ) ;
		if ( v > 100 ) return result ;
		
		//  look for three speed estimates that are close to one another
		for ( i = 0; i < 4; i++ ) speedEstimate[i] = speedEstimate[i+1] ;
		speedEstimate[4] = v ;
		// remove the smallest and largest
		min = max = speedEstimate[0] ; 
		nmin = nmax = 0 ;
		for ( i = 1; i < 5; i++ ) {
			if ( speedEstimate[i] > max ) {
				max = speedEstimate[i]  ;
				nmax = i ;
			}
			else if ( speedEstimate[i] < min ) {
				min = speedEstimate[i]  ;
				nmin = i ;
			}
		}
		n = 0 ;
		for ( i = 0; i < 5; i++ ) {
			if ( i != nmax && i != nmin ) {
				sorted[n++] = speedEstimate[i] ;
			}
		}
		
		sum = 0.0 ;
		for ( i = 0; i < 3; i++ ) sum += sorted[i] ;
		sum = sum*0.333 ;
		for ( i = 0; i < 3; i++ ) {
			if ( fabs( sorted[i]-sum ) > 1.0 ) {
				return result ;
			}
		}
		result.speed = sum ;
		result.dit = estimate ;
		result.interElement = interelementEstimate ;
		result.interSymbol = 3*result.interElement ;
		result.dash = 3*result.dit ;
		
		return result ;
	}
	return result ;
}

- (float*)histogram
{
	return &keyHistogram[0] ;
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


@end
