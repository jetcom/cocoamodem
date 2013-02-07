//
//  ParametricEqualizer.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/21/07.
	#include "Copyright.h"
	
	
#import "ParametricEqualizer.h"
#include "CMDSPWindow.h"


@implementation ParametricEqualizer

- (void)designEqualizer
{
	CMFFT *fft ;
	DSPSplitComplex cin, cout ;
	float inBufI[512], inBufQ[512], scale, value, gain, adjustedGain ;
	float outBufI[512], outBufQ[512] ;
	int i, j, low, high, mid ;

	//  symmetric spectrum, OK to use forward transform
	fft = FFTForward( 9, NO ) ;
	
	for ( i = 0; i < 512; i++ ) inBufI[i] = inBufQ[i] = 0.0 ;
	
	scale = 256/( 11025/2.0 ) ;
	
	gain = 0 ;
	for ( i = 0; i < ranges; i++ ) {
		low = range[i].low*scale ;
		high = range[i].high*scale ;
		value = fabs( range[i].value ) ;
		
		adjustedGain = value ;
		if ( range[i].low > 500 ) adjustedGain *= 0.5 ;
		if ( range[i].low > 1000 ) adjustedGain *= 0.5 ;
		if ( adjustedGain > gain ) gain = adjustedGain ;
		
		for ( j = low; j < high; j++ ) {
			inBufI[j] = value ;
			if ( j != 0 ) inBufI[512-j] = value ;
		} 
	}
	cin.realp = inBufI ;
	cin.imagp = inBufQ ;
	cout.realp = outBufI ;
	cout.imagp = outBufQ ;
	CMPerformComplexFFT( fft, &cin, &cout ) ;
	
	gain = 1.1/( gain*256.0 ) ;
	
	mid = filter->activeTaps/2 ;
	filter->kernel[mid] = outBufI[0] ;
	for ( i = 0; i < filter->activeTaps; i++ ) filter->kernel[i] = 0 ;
	for ( i = 1; i < mid; i++ ) {
		filter->kernel[mid+i] = filter->kernel[mid-i] = outBufI[i]*gain ;
	}
	filter->kernel[0] = 0 ;
	for ( i = 0; i < filter->activeTaps; i++ ) filter->kernel[i] *= window[i] ;
}

//  Parametric Equalizer
//  max of 64 ranges

- (id)init:(ParametricRange*)rangeArray ranges:(int)n order:(int)order
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		if ( n > 64 ) n = 64 ;
		ranges = n ;
		taps = order ;
		for ( i = 0; i < n; i++ ) range[i] = rangeArray[i] ;
		window = CMMakeBlackmanWindow( order ) ;
		filter = CMFIRLowpassFilter( 100 /* not important */, CMFs, order ) ;
		[ self designEqualizer ] ;
	}
	return self ;
}

- (void)setRange:(int)index to:(float)value
{
	range[index].value = value ;
	[ self designEqualizer ] ;
}

- (CMFIR*)filter
{
	return filter ;
}

@end
