//
//  CMComplexFIR.c
//  Filter (CoreModem)
//
//  Created by Kok Chen on 11/3/05.
	#include "Copyright.h"


#import "CMComplexFIR.h"

//  return a zero filled AnalyticBuffer
CMAnalyticBuffer *CMMallocAnalyticBuffer( int size )
{
	CMAnalyticBuffer *b ;
	float *p, *q ;
	int i ;
	
	b = ( CMAnalyticBuffer* )malloc( sizeof( CMAnalyticBuffer ) ) ;
	b->re = p = ( float* )malloc( sizeof( float )*size ) ;
	b->im = q = ( float* )malloc( sizeof( float )*size ) ;
	b->size = size ;
	
	for ( i = 0; i < size; i++ ) *p++ = *q++ = 0 ;
	return b ;
}

void CMShiftAnalyticBuffer( CMAnalyticBuffer *b, int samples ) 
{
	int n ;
	
	n = sizeof( float )*( 512-samples ) ;
	memmove( b->re, b->re+samples, n ) ;
	memmove( b->im, b->im+samples, n ) ;
}

void freeAnalyticBuffer( CMAnalyticBuffer *b )
{
	free( b->re ) ;
	free( b->im ) ;
	free( b ) ;
}

CMComplexFIR *CMComplexFIRDecimateWithCutoff( int factor, float cutoff, float fsampling, int activeTaps )
{
	CMComplexFIR *fir ;
	
	fir = ( CMComplexFIR* )malloc( sizeof( CMComplexFIR ) ) ;
	
	fir->re = CMFIRDecimateWithCutoff( factor, cutoff, fsampling, activeTaps ) ;
	fir->im = CMFIRDecimateWithCutoff( factor, cutoff, fsampling, activeTaps ) ;
	return fir ;
}

CMAnalyticPair CMDecimateAnalyticBuffer( CMComplexFIR *fir, CMAnalyticBuffer *inBuffer, int offset )
{
	CMAnalyticPair result ;
	
	result.re = CMDecimate( fir->re, inBuffer->re+offset ) ;
	result.im = CMDecimate( fir->im, inBuffer->im+offset ) ;
	
	return result ;
}

void CMDeleteComplexFIR( CMComplexFIR *fir )
{
	CMDeleteFIR( fir->re ) ;
	CMDeleteFIR( fir->im ) ;
	free( fir ) ;
}
