//
//  CMBandpassFilter.m
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/24/05
//	(ported from cocoaModem, original file dated Thu Jun 10 2004)
	#include "Copyright.h"

#import "CMBandpassFilter.h"
#import "CMDSPWindow.h"


@implementation CMBandpassFilter

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		lowCutoff = highCutoff = 0.0 ;
		fir = nil ;
		filter = nil ;
		[ self setLowCutoff:1960.0 highCutoff:2460.0 length:128 ] ;
	}
	return self ;
}

- (id)initLowCutoff:(float)low highCutoff:(float)high length:(int)len
{
	self = [ super init ] ;
	if ( self ) {
		fir = nil ;
		filter = nil ;
		[ self setLowCutoff:low highCutoff:high length:len ] ;
	}
	return self ;
}

- (void)updateLowCutoff:(float)low highCutoff:(float)high
{
	[ self setLowCutoff:low highCutoff:high length:n ] ;
}

- (void)setLowCutoff:(float)low highCutoff:(float)high length:(int)len
{
	float center, temp, w, t, x, f, baseband, sum ;
	int i, oldlen ;
	
	if ( high < low ) {
		//  sanity check
		temp = high ;
		high = low ;
		low = temp ;
	}
	if ( low < 1.0 || low == lowCutoff && high == highCutoff ) return ;
	
	oldlen = n ;
	n = len ;
	lowCutoff = low ;
	highCutoff = high ;
	center = ( low + high )*0.5 ;
	f = 0.5*center*n/CMFs ;
	w = 0.5*( high-low )*n/CMFs ;		//  bandwidth of sinc
	
	if ( oldlen != n ) {
		if ( fir ) free( fir ) ;
		fir = ( float* )malloc( sizeof( float )*n ) ;
	}
	sum = 0 ;
	for ( i = 0; i < n; i++ ) {
		t = n/2 ;
		x = ( i + 0.5 - t )/t ;
		baseband = CMModifiedBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		sum += baseband ;
		fir[i] = baseband*sin( 2.0*CMPi*f*x ) ;
	}
	w = 2/sum ;
	for ( i = 0; i < n; i++ ) fir[i] *= w ;
	
	if ( filter == nil ) {
		filter = CMFIRFilter( fir, n ) ;
	}
	else {
		CMUpdateFIRFilter( filter, fir, n ) ;
	}
}

@end
