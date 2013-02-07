//  hadamard.c
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/25/06.
	#include "Copyright.h"
	

#include "hadamard.h"
#include <stdlib.h>

HadamardTransform *Hadamard( int order )
{
	HadamardTransform *h ;
	
	h = ( HadamardTransform* )malloc( sizeof( HadamardTransform ) ) ;
	h->n = order ;
	h->dir = 1 ;	//  forward transform
	h->buffer = ( float* )malloc( sizeof( float )*order ) ;
	
	return h ;
}

void DeleteHadamard( HadamardTransform *h )
{
	if ( h ) {
		free( h->buffer ) ;
		free( h ) ;
	}
}

void TransformHadamard( HadamardTransform *h, float *in, float *spectrum )
{
  float *d, d1, d2, scale ;
  int i, j, k, n1, n2 ;

	for ( i = 0; i < h->n; i++ ) spectrum[i] = in[i] ;
	if ( h->n < 2 ) return ;

	n1 = 2 ;
	n2 = 1 ;

	while ( n1 <= h->n ) {
		for ( i = 0; i < h->n; i++ ) h->buffer[i] = spectrum[i] ;
		
		for ( i = 0; i < h->n; i += n1 ) {
			k = i ;
			d = &spectrum[i] ;

			for ( j = 0; j < n1; j += 2 ) {

				d1 = h->buffer[k] ;
				d2 = h->buffer[k+n2] ;

				if ( j&0x2 ) {
					d[j] = d1-d2 ;
					d[j+1] = d1+d2 ;
				}
				else {
					d[j] = d1+d2 ;
					d[j+1] = d1-d2 ;
				}
				k++;
			}
		}
		n2 = n1 ;
		n1 *= 2 ;
	}
	if ( h->dir < 0 ) {
		//  need to normalize by order is inverse transform
		scale = 1.0/h->n ;
		for ( i = 0; i < h->n; i++ ) spectrum[i] *= scale ;
    }
}
