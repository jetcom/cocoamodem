//
//  CMFFT.h
//  Filter (CoreModem)
//
//  Created by Kok Chen on 11/4/05
//	Ported from cocoaModem, original file dated Thu May 27 2004.

#ifndef _CMFFT_H_
	#define _CMFFT_H_

	#include <Carbon/Carbon.h>
	#include <vecLib/vDSP.h>
	
	typedef enum {
		Forward,
		Inverse,
		PowerSpectrum
	} CMFFTStyle ;
	
	typedef COMPLEX_SPLIT FFTData ;
	
	typedef struct {
		int log2n ;
		int size ;
		float *window ;
		DSPSplitComplex tempBuf ;
		float *realBuf, *imagBuf ;
		CMFFTStyle style ;
		FFTSetup vfft ;
		COMPLEX_SPLIT z ;
	} CMFFT ;
		
	CMFFT *FFTSpectrum( int log2n, Boolean useWindow ) ;
	CMFFT *FFTForward( int log2n, Boolean useWindow ) ;

	void CMPerformFFT( CMFFT *fft, float *input, float *output ) ;
	void CMPerformComplexFFT( CMFFT *fft, DSPSplitComplex *input, DSPSplitComplex *output ) ;
	void CMDeleteFFT( CMFFT *fft ) ;

#endif
