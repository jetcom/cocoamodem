/*
 *  hadamard.h
 *  cocoaModem 2.0
 *
 *  Created by Kok Chen on 12/25/06.
 */

#ifndef _HADAMARD_H_
	#define _HADAMARD_H_

	typedef struct {
		int n ;
		int dir ;
		float *buffer ;
	} HadamardTransform ;
	
	HadamardTransform *Hadamard( int order ) ;
	void DeleteHadamard( HadamardTransform *h ) ;
	void TransformHadamard( HadamardTransform *h, float *in, float *spectrum ) ;
	
#endif
