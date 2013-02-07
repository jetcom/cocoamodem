//
//  Boxcar.c
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/10/06.

	#include "Copyright.h"

#include "Boxcar.h"
#include "CMDSPWindow.h"

//  create boxcar filter with length, allowing maximum adustment to maxlength
CMFIR *BoxcarFilter( int length, int maxLength )
{
	CMFIR *filter ;
	float *k, gain ;
	int i, n ;
	
	if ( maxLength < length ) maxLength = length ;
	
	filter = CMFIRLowpassFilter( 20 /* not important */, 11025 /*not important*/, maxLength ) ;
	k = filter->kernel ;
	n = filter->activeTaps ;
	gain = 1.0/length ;
	for ( i = 0; i < length; i++ ) *k++ = gain ;
	for ( ; i < n; i++ ) *k++ = 0 ;

	return filter ;
}

//  Blackman window
CMFIR *BlackmanWindow( int length, int maxLength )
{
	CMFIR *filter ;
	if ( maxLength < length ) maxLength = length ;
	
	filter = CMFIRLowpassFilter( 20 /* not important */, 11025 /*not important*/, maxLength ) ;
	adjustBlackmanWindow( filter, length ) ;
	
	return filter ;
}

void adjustBlackmanWindow( CMFIR *filter, int length )
{
	float *k, x, gain ;
	int i, n ;
	
	k = filter->kernel ;
	n = filter->activeTaps ;
	if ( length > n ) length = n ;

	gain = 0.0 ;
	for ( i = 0 ; i < n-length; i++ ) *k++ = 0 ;
	for ( i = 0 ; i < length; i++ ) {
		x = CMBlackmanWindow( i, length ) ;
		*k++ = x ;
		gain += x ;
	}
	gain = 1.0/gain ;
	k = filter->kernel ;
	for ( i = 0; i < n; i++ ) *k++ *= gain ;
}


void adjustBoxcarFilter( CMFIR *filter, int length )
{
	float *k, gain ;
	int i, n, excess ;

	k = filter->kernel ;
	n = filter->activeTaps ;

	if ( length > n ) length = n ;
	gain = 1.0/length ;

	excess = ( n-length ) ;
	for ( i = 0; i < excess; i++ ) *k++ = 0 ;
	for ( ; i < n; i++ ) *k++ = gain ;
}

//  constant slope rising and falling edges
void adjustWaveshapedBoxcarFilter( CMFIR *filter, int length )
{
	float *k, gain ;
	int i, n ;

	k = filter->kernel ;
	n = filter->activeTaps ;
	if ( length > n ) length = n ;
	gain = 1.0/length ;
	for ( i = 0; i < 3; i++ ) *k++ = i*0.33*gain ;
	for ( ; i < length-3; i++ ) *k++ = gain ;
	for ( ; i < length; i++ ) *k++ = (length-i)*0.33*gain ;	
	for ( ; i < n; i++ ) *k++ = 0 ;
}
