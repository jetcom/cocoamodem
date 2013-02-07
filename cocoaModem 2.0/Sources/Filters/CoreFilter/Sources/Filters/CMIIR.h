//
//  CMIIR.h
//  Filter (CoreModem)
//
//  Created by Kok Chen on 11/02/05.

#ifndef _CMIIR_H_
	#define _CMIIR_H_

	typedef struct {
		int filterType ;
		int order ;
		double fp1, fp2, fN ;
		double z[16] ;
		double pReal[16] ;
		double pImag[16] ;
		double *pole, *zero ;
	} IIR ;

	float butterworthDesign( int order, int type, float bw, float fCenter, double *pole, double *zero ) ;
	float notchDesign( float bw, float fNotch, double *pole, double *zero ) ;
	
	#define LP  0
	#define HP  1
	#define BP  2

#endif
