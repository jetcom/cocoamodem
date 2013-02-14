//
//  FFT.c
//  Filter (CoreModem)
//
//  Created by Kok Chen on 11/04/05
//	Ported from cocoaModem, file dated Thu May 27 2004.
	#include "Copyright.h"

#include "CMFFT.h"
#include "CMDSPWindow.h"
#include <vecLib/vDSP.h>

//  create a vDSP power spectrum structure 
CMFFT *FFTSpectrum( int log2n, Boolean useWindow )
{
	CMFFT *fft ;
	
	fft = ( CMFFT*)malloc( sizeof( CMFFT ) ) ;
	
	fft->style = PowerSpectrum ;
	fft->log2n = log2n ;
	fft->size = 1 << log2n ;
	fft->window = ( useWindow ) ? CMMakeModifiedBlackmanWindow( fft->size/2 ) : nil ;
	fft->z.realp = ( float* )malloc( fft->size*sizeof( float )/2 ) ;
	fft->z.imagp = ( float* )malloc( fft->size*sizeof( float )/2 ) ;
	fft->tempBuf.realp = ( float* )malloc( sizeof( float )*16384 ) ;
	fft->tempBuf.imagp = ( float* )malloc( sizeof( float )*16384 ) ;
	fft->vfft = vDSP_create_fftsetup( log2n, FFT_RADIX2 ) ;
	return fft ;
}

CMFFT *FFTForward( int log2n, Boolean useWindow )
{
	CMFFT *fft ;
	
	fft = ( CMFFT*)malloc( sizeof( CMFFT ) ) ;
	
	fft->style = Forward ;
	fft->log2n = log2n ;
	fft->size = 1 << log2n ;
	fft->window = ( useWindow ) ? CMMakeModifiedBlackmanWindow( fft->size ) : nil ;
	fft->tempBuf.realp = (float*)malloc( sizeof(float)*16384 ) ;
	fft->tempBuf.imagp = (float*)malloc( sizeof(float)*16384 ) ;
	if ( useWindow ) {
		fft->realBuf = (float*)malloc( sizeof(float)*fft->size ) ;
		fft->imagBuf = (float*)malloc( sizeof(float)*fft->size ) ;
	}
	fft->vfft = vDSP_create_fftsetup( log2n, FFT_RADIX2 ) ;
	return fft ;
}

void CMPerformFFT( CMFFT *fft, float *input, float *output )
{
	int i, n, nby2 ;
	
	n = fft->size ;
	nby2 = n/2 ;

	switch ( fft->style ) {
	case PowerSpectrum:
		vDSP_ctoz( ( COMPLEX* )input, 2, &fft->z, 1, nby2 ) ; 
		if ( fft->window ) {
			for ( i = 0; i < nby2; i++ ) {
				fft->z.realp[i] *= fft->window[i] ;
				fft->z.imagp[i] *= fft->window[i] ;
			}
		}
		vDSP_fft_zript( fft->vfft, &fft->z, 1, &fft->tempBuf, fft->log2n, FFT_FORWARD ) ;
		vDSP_vsq( fft->z.realp, 1, fft->z.realp, 1, nby2 ) ;
		vDSP_vsq( fft->z.imagp, 1, fft->z.imagp, 1, nby2 ) ;
		vDSP_vadd( fft->z.realp, 1, fft->z.imagp, 1,  &output[0], 1, nby2 ) ;
		break ;
	default:
		break ;
	}
}

void CMPerformComplexFFT( CMFFT *fft, DSPSplitComplex *input, DSPSplitComplex *output )
{
	int i, n ;
	float w ;
	DSPSplitComplex c ;
	
	n = fft->size ;
	
	switch ( fft->style ) {
	case Forward:
		if ( fft->window ) {
			for ( i = 0; i < n; i++ ) {
				w = fft->window[i] ;
				fft->realBuf[i] = input->realp[i] * w ;
				fft->imagBuf[i] = input->imagp[i] * w ;
			}
			c.realp = fft->realBuf ;
			c.imagp = fft->imagBuf ;
			vDSP_fft_zopt( fft->vfft, &c, 1, output, 1, &fft->tempBuf, fft->log2n, FFT_FORWARD ) ;
			break ;
		}
		vDSP_fft_zopt( fft->vfft, input, 1, output, 1, &fft->tempBuf, fft->log2n, FFT_FORWARD ) ;
		break ;
	default:
		break ;
	}
}

void CMDeleteFFT( CMFFT *fft )
{
	switch ( fft->style ) {
	case PowerSpectrum:
		vDSP_destroy_fftsetup( fft->vfft ) ;
		if ( fft->window ) free( fft->window ) ;
		free( fft->z.realp ) ;
		free( fft->z.imagp ) ;
		break ;
	default:
		break ;
	}
	free( fft ) ;
}
