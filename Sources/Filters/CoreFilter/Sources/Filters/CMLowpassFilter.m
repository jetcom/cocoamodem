//
//  LowpassFilter.m
//  Filter (CoreModem)
//
//  Created by Kok Chen on Sun Aug 15 2004.
	#include "Copyright.h"
//

#import "CMLowpassFilter.h"
#include "CMDSPWindow.h"


@implementation CMLowpassFilter

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		cutoff = 0.0 ;
		if ( fir ) free( fir ) ;			//  v0.80l was malloced in super class
		fir = nil ;
		filter = nil ;
		[ self setCutoff:300.0 length:64 ] ;
	}
	return self ;
}

- (id)initCutoff:(float)low length:(int)len
{
	self = [ super init ] ;
	if ( self ) {
		cutoff = 0.0 ;
		if ( fir ) free( fir ) ;			//  v0.80l was malloced in super class
		fir = nil ;
		filter = nil ;
		[ self setCutoff:low length:len ] ;
	}
	return self ;
}

- (void)updateCutoff:(float)low
{
	[ self setCutoff:low length:n ] ;
}

- (void)setCutoff:(float)low length:(int)len
{
	float w, baseband, sum ;
	int i ;
	
	if ( low < 1.0 ) low = 1.0 ; else if ( low > CMFs/2 ) low = CMFs/2 ;
	if ( low == cutoff ) return ;
	
	n = len ;
	cutoff = low ;
	w = 0.5*low*n/CMFs ;		//  bandwidth of sinc
	
	if ( fir ) free( fir ) ;
	fir = ( float* )malloc( sizeof( float )*n ) ;
	sum = 0 ;
	for ( i = 0; i < n; i++ ) {
		baseband = CMModifiedBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		sum += baseband ;
		fir[i] = baseband ;
	}	
	w = 1/sum ;
	for ( i = 0; i < n; i++ ) fir[i] = fir[i]*w ;
	
	CMDeleteFIR( filter ) ;
	filter = CMFIRFilter( fir, n ) ;
}

- (void)importData:(CMPipe*)pipe
{
	CMDataStream *input ;
	
	if ( !filter ) return ;
	
	input = [ pipe stream ] ;  // use client's stream structure	
	CMPerformFIR( filter, input->array, 512, &outbuf[0] ) ;
	stream = *input ;
	stream.array = outbuf ;
	data = &stream ;
	[ self exportData ] ;
}

@end
