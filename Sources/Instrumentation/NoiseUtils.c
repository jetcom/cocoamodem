//
//  NoiseUtils.c
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/8/07.
	#include "Copyright.h"

#include "NoiseUtils.h"
#include <stdlib.h>

void initGaussianNoise()
{
	srandom( 0x31415926 ) ;
}

//  sigma = sqrt( variance )
//  for sd = 1.0, total power = 1.0, noise power/Hz with 11025 sampling rate (5512.5 Hz bandwidth) = 0.000178
float gaussianNoise( float sigma )
{
	float t ;
	int i ;
	
	t = 0 ;
	for ( i = 0; i < 9; i++ ) {
		t += ( random() & 0x3fff ) - 0x1fff ;
	}
	t = t*sigma/( 8192.0*9.0*0.1926 ) ;
	return t ;
}