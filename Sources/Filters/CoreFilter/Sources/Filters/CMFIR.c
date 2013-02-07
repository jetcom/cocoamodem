//
//  CMFIR.c
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/24/05
//	(ported from cocoaModem created on Mon May 24 2004)
	#include "Copyright.h"

#include "CMFIR.h"
#include "CMDSPWindow.h"
#include <string.h>

static float *bandpassKernel( float low, float high, float fs, int activeTaps ) ;
static float *combKernel( float freq, float fs, int activeTaps, float phase ) ;
static float *lowpassKernel( float cutoff, float fs, int activeTaps, float ratio ) ;
static void updateLowpassKernel( float *kernel, float cutoff, float fs, int activeTaps, float decimationRatio ) ;
static void updateBandpassKernel( float *kernel, float low, float high, float fs, int activeTaps ) ;


//  NOTE: filter sizes should be divisible by 4 to use Altivec!!!

//  NOTE:  don't use dotpr() in vDSP
//	       It seems to sporadically returning NAN when run in development mode in xCode 1.5.
//		   Instead, use conv() with a result length of 1.


//  create a vDSP convolution structure for an FIR filter
//  Filter array kernel should have activeTaps entries
CMFIR *CMFIRFilter( float *kernel, int activeTaps )
{
	CMFIR *fir ;
	int i, n ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = 1 ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMFilter ;
	fir->delaylineHead = 0 ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*2 ) ;
	
	n = activeTaps ;
	//  reverse kernel for convolution
	fir->kernel = ( float* )malloc( sizeof( float )*n ) ;
	for ( i = 0; i < n; i++ ) fir->kernel[n-1-i] = kernel[i] ;
	return fir ;
}

// update a structure that already exists
void CMUpdateFIRFilter( CMFIR *fir, float *kernel, int activeTaps )
{
	int i, n ;
	
	fir->stride = 1 ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMFilter ;
	fir->delaylineHead = 0 ;
	
	n = activeTaps ;
	for ( i = 0; i < n; i++ ) fir->kernel[n-1-i] = kernel[i] ;
}

//  create a vDSP convolution structure for interpolation
//  Filter array kernel should have activeTaps*factor entries
CMFIR *CMFIRInterpolate( int factor, float *kernel, int activeTaps )
{
	CMFIR *fir ;
	int i, n ;
	float sum, gain ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = factor ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMInterpolate ;
	fir->delaylineHead = 0 ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*2 ) ;
	
	n = factor*activeTaps ;
	//  reverse kernel for convolution
	fir->kernel = ( float* )malloc( sizeof( float )*n ) ;
	sum = 0.0 ;
	for ( i = 0; i < n; i++ ) sum += kernel[i] ;
	gain = factor/sum ;
	
	for ( i = 0; i < n; i++ ) fir->kernel[n-1-i] = kernel[i]*gain ;
	return fir ;
}

//  create a vDSP convolution structure for decimation
//  Filter array kernel should have activeTaps entries
CMFIR *CMFIRDecimate( int factor, float *kernel, int activeTaps )
{
	CMFIR *fir ;
	int i, n ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = factor ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMDecimate ;
	fir->delaylineHead = 0 ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*3 ) ;
	
	n = activeTaps ;
	//  reverse kernel for convolution
	fir->kernel = ( float* )malloc( sizeof( float )*n ) ;
	for ( i = 0; i < n; i++ ) fir->kernel[n-1-i] = kernel[i] ;
	return fir ;
}

//  create a vDSP convolution structure for simple low pass filtering
//  Filter array kernel should have activeTaps entries
CMFIR *CMFIRLowpassFilter( float cutoff, float fsampling, int activeTaps )
{
	CMFIR *fir ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = 1 ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMFilter ;
	fir->delaylineHead = 0 ;
	fir->fsampling = fsampling ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*2 ) ;
	
	fir->kernel = lowpassKernel( cutoff, fsampling, activeTaps, 1.0 ) ;
	return fir ;
}

void CMUpdateFIRLowpassFilter( CMFIR *fir, float cutoff )
{
	updateLowpassKernel( fir->kernel, cutoff, fir->fsampling, fir->activeTaps, 1.0 ) ;
}

//  create a vDSP convolution structure for simple band pass filtering
//  Filter array kernel should have activeTaps entries
CMFIR *CMFIRBandpassFilter( float low, float high, float fsampling, int activeTaps )
{
	CMFIR *fir ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = 1 ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMFilter ;
	fir->delaylineHead = 0 ;
	fir->fsampling = fsampling ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*2 ) ;
	
	fir->kernel = bandpassKernel( low, high, fsampling, activeTaps ) ;
	return fir ;
}

void CMUpdateFIRBandpassFilter( CMFIR *fir, float low, float high )
{
	updateBandpassKernel( fir->kernel, low, high, fir->fsampling, fir->activeTaps ) ;
}

CMFIR *CMFIRCombFilter( float freq, float fsampling, int activeTaps, float phase )
{
	CMFIR *fir ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = 1 ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMFilter ;
	fir->delaylineHead = 0 ;
	fir->fsampling = fsampling ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*2 ) ;
	
	fir->kernel = combKernel( freq, fsampling, activeTaps, phase ) ;
	return fir ;
}

CMFIR *CMFIRDecimateWithCutoff( int factor, float cutoff, float fsampling, int activeTaps )
{
	CMFIR *fir ;
	int i ;
	float r ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = factor ;
	fir->activeTaps = activeTaps ;
	fir->style = kCMDecimate ;
	fir->delaylineHead = 0 ;
	fir->fsampling = fsampling ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), activeTaps*3 ) ;
	
	fir->kernel = lowpassKernel( cutoff, fsampling, activeTaps, factor ) ;
	
	//  scale to unity gain
	r = 1.0/factor ;
	for ( i = 0; i < activeTaps; i++ ) fir->kernel[i] *= r ;

	return fir ;
}

//  create a vDSP convolution structure for an FIR filter
//  Filter array kernel should have activeTaps entries
CMFIR *CMDelayLine( int delayUnits )
{
	CMFIR *fir ;
	
	fir = ( CMFIR* )malloc( sizeof( CMFIR ) ) ;
	fir->stride = 1 ;
	fir->activeTaps = delayUnits ;
	fir->style = kCMDelayLine ;
	fir->delaylineHead = 0 ;
	fir->fsampling = 0.0 ;
	
	//  delay line to provide FIR overlap
	fir->delayLine = ( float* )calloc( sizeof( float ), fir->activeTaps*2 ) ;
	
	fir->kernel = nil ;			// no kernel
	return fir ;
}

//  return a kernel for a lowpass filter
//  use unmodified Blackman window
static float *lowpassKernel( float cutoff, float fs, int activeTaps, float decimationRatio )
{
	float *kernel, sum, w ;
	double baseband ;
	int i, n ;
	
	n = activeTaps ;
	sum = 0 ;
	w = activeTaps*cutoff/fs ;		//  bandwidth of sinc
	
	kernel = ( float* )calloc( sizeof( float ), n ) ;
	for ( i = 0; i < n; i++ ) {
		baseband = CMBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		sum += baseband ;
		kernel[i] = baseband ;
	}
	w = decimationRatio/sum ;
	for ( i = 0; i < n; i++ ) kernel[i] = kernel[i]*w ;

	return kernel ;
}

static void updateLowpassKernel( float *kernel, float cutoff, float fs, int activeTaps, float decimationRatio )
{
	float sum, w ;
	double baseband ;
	int i, n ;
	
	n = activeTaps ;
	sum = 0 ;
	w = activeTaps*cutoff/fs ;		//  bandwidth of sinc
	
	for ( i = 0; i < n; i++ ) {
		baseband = CMBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		sum += baseband ;
		kernel[i] = baseband*0.01 ;		//  attenuate to avoid loud transcients
	}
	w = decimationRatio/sum*100 ;
	for ( i = 0; i < n; i++ ) kernel[i] = kernel[i]*w ;
}

//  return a kernel for a bandpass filter
//  use modified Blackman window to reduce DC offset
static float *bandpassKernel( float low, float high, float fs, int activeTaps )
{
	float *kernel, center, f, w, t, x ;
	double baseband, sum, m ;
	int i, n ;
	
	n = activeTaps ;
	center = ( high+low )*0.5 ;
	f = 0.5*center*n/fs ;
	w = 0.5*fabs( high-low )*n/fs ;		//  bandwidth of sinc
	
	kernel = ( float* )calloc( sizeof( float ), n ) ;

	sum = 0 ;
	for ( i = 0; i < n; i++ ) {
		t = n/2 ;
		if ( ( n&1 ) == 0 ) x = ( i+0.5 - t )/t ; else x = ( i - t )/t ;
		baseband = CMModifiedBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		m = sin( 2.0*3.14159265358979*f*x ) ; 
		sum += ( kernel[i] = baseband*m )*m ;
	}
	w = 1/sum;
	for ( i = 0; i < n; i++ ) kernel[i] *= w ;

	return kernel ;
}

static void updateBandpassKernel( float *kernel, float low, float high, float fs, int activeTaps )
{
	float center, f, w, t, x ;
	double baseband, sum, m ;
	int i, n ;
	
	n = activeTaps ;
	center = ( high+low )*0.5 ;
	f = 0.5*center*n/fs ;
	w = 0.5*fabs( high-low )*n/fs ;		//  bandwidth of sinc
	
	sum = 0 ;
	for ( i = 0; i < n; i++ ) {
		t = n/2 ;
		if ( ( n&1 ) == 0 ) x = ( i+0.5 - t )/t ; else x = ( i - t )/t ;
		baseband = CMModifiedBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		m = sin( 2.0*3.14159265358979*f*x ) ; 
		sum += ( kernel[i] = baseband*m*0.01 )*m ;		//  attenuate by 100 to avoid loud transcients
	}
	w = 1.0/sum ;
	for ( i = 0; i < n; i++ ) kernel[i] *= w ;
}

static float combCache[2048] ;
static float fCached = 0.0 ;
static int nCached = 0 ;

static float *combKernel( float center, float fs, int activeTaps, float phase )
{
	float *kernel, f, t, x ;
	double baseband, sum, m ;
	int i, n ;
	
	n = activeTaps ;
	f = 0.5*center*n/fs ;
	
	if ( n == nCached && f == fCached ) {
		//  simply return cached array
		i = sizeof( float )*n ;
		kernel = ( float* )malloc( i ) ;
		memcpy( kernel, combCache, i ) ;
		return kernel ;
	}
	
	kernel = ( float* )calloc( sizeof( float ), n ) ;
	sum = 0 ;
	for ( i = 0; i < n; i++ ) {
		t = n/2 ;
		if ( ( n&1 ) == 0 ) x = ( i+0.5 - t )/t ; else x = ( i - t )/t ;
		baseband = pow( CMHanningWindow( i, n ), 0.25 ) ;						// 0.96c
		m = sin( 2.0*3.14159265358979*f*x + phase ) ; 
		sum += ( kernel[i] = baseband*m )*m ;
	}
	m = 1/sum;
	for ( i = 0; i < n; i++ ) kernel[i] *= m ;
	
	if ( n <= 2048 ) {
		memcpy( combCache, kernel, sizeof( float )*n ) ;
		fCached = f ;
		nCached = n ;
	}

	return kernel ;
}

//  apply FIR filter for array and length of array
//  outArray size should be same size as inLength
static void performFilter( CMFIR *fir, float *inArray, int inLength, float *outArray )
{
	int n ;
	
	n = fir->activeTaps ;
	
	if ( inLength > n ) {
		//  provide FIR overlap by copying an extra set of activeTaps into the delay line 
		memcpy( &fir->delayLine[n], inArray, sizeof( float )*n ) ;
		//  filter the data in the delay line (length = taps)
		conv( &fir->delayLine[0], 1, &fir->kernel[0], 1, &outArray[0], 1, n, n ) ;
		//  filter rest of the data
		conv( &inArray[0], 1, &fir->kernel[0], 1, &outArray[n], 1, inLength-n, n ) ;
		//  copy tail of data into the front of the delay line
		memcpy( &fir->delayLine[0], &inArray[inLength-n], sizeof( float )*n ) ;
	}
	else {
		//  copy data into the delay line 
		memcpy( &fir->delayLine[n], inArray, sizeof(float)*inLength ) ;
		//  filter the data in the delay line (length = taps)
		conv( &fir->delayLine[0], 1, &fir->kernel[0], 1, &outArray[0], 1, inLength, n ) ;
		memcpy( &fir->delayLine[0], &fir->delayLine[inLength], sizeof( float )*n ) ;
	}
}

//  apply FIR interpolation for array and length of array
//  FIR is an interpolating filter, outArray size should be inLength*activeTaps
static void performInterpolation( CMFIR *fir, float *inArray, int inLength, float *outArray )
{
	float *p ;
	int i, stride, taps, n ;
	
	stride = fir->stride ;
	taps = fir->activeTaps ;
	n = stride*taps ;
	
	//  provide FIR overlap by copying an extra set of activeTaps into the delay line 
	memcpy( &fir->delayLine[taps], inArray, sizeof( float )*taps ) ;

	//  filter the data in the delay line (length = taps)
	for ( i = 0; i < stride; i++ ) {
		conv( &fir->delayLine[0], 1, &fir->kernel[stride-i-1], stride, &outArray[i], stride, taps, taps ) ;
	}
	// continue filtering with new data (length = inlength-taps)
	p = &outArray[n] ;
	for ( i = 0; i < stride; i++ ) {
		conv( &inArray[0], 1, &fir->kernel[stride-i-1], stride, &p[i], stride, inLength-taps, taps ) ;
	}
	//  copy tail into the delay line
	memcpy( &fir->delayLine[0], &inArray[inLength-taps], sizeof( float )*taps ) ;
}

//  apply FIR interpolation for array and length of array
//  FIR is a decimating filter, outArray size should be inLength/factor. 
//  Decimating factor has to divide kernel length
static void performDecimation( CMFIR *fir, float *inArray, int inLength, float *outArray )
{
	int i, factor, taps ;
	float *kernel ;
	
	factor = fir->stride ;
	taps = fir->activeTaps ;
	kernel = &fir->kernel[0] ;
	
	if ( inLength <= taps ) {
		//  provide FIR overlap by copying an extra set of activeTaps into the delay line 
		memcpy( &fir->delayLine[taps], inArray, sizeof( float )*inLength ) ;	
		for ( i = 0; i < inLength; i += factor ) conv( &fir->delayLine[i], 1, fir->kernel, 1, outArray++, 1, 1, taps ) ;
		//  copy tail into the delay line
		memcpy( &fir->delayLine[0], &fir->delayLine[inLength], sizeof( float )*taps ) ;
		return ;
	}	
	//  provide FIR overlap by copying an extra set of activeTaps into the delay line 
	memcpy( &fir->delayLine[taps], inArray, sizeof( float )*taps ) ;	
	for ( i = 0; i < taps; i += factor ) conv( &fir->delayLine[i], 1, fir->kernel, 1, outArray++, 1, 1, taps ) ;
	for ( i = 0; i < inLength-taps; i += factor ) conv( &inArray[i], 1, fir->kernel, 1, outArray++, 1, 1, taps ) ;
	//  copy tail into the delay line
	memcpy( &fir->delayLine[0], &inArray[inLength-taps], sizeof( float )*taps ) ;
}

static void performDelay( CMFIR *fir, float *inArray, int inLength, float *outArray )
{
	int n ;
	
	n = fir->activeTaps ;
	
	if ( inLength > n ) {
		//  move data in the delay line to output (length = taps)
		memcpy( &outArray[0], &fir->delayLine[0], sizeof( float )*n ) ;
		//  filter rest of the data
		memcpy( &outArray[n], &inArray[0], sizeof( float )*( inLength-n ) ) ;
		//  copy tail of data into the front of the delay line
		memcpy( &fir->delayLine[0], &inArray[inLength-n], sizeof( float )*n ) ;
	}
	else {
		//  copy data into the delay line 
		memcpy( &fir->delayLine[n], inArray, sizeof(float)*inLength ) ;
		//  move data in the delay line to output (length = taps)
		memcpy( &outArray[0], &fir->delayLine[0], sizeof( float )*n ) ;
		memcpy( &fir->delayLine[0], &fir->delayLine[inLength], sizeof( float )*n ) ;
	}
}

//  filter one sample.
float CMSimpleFilter( CMFIR *fir, float input )
{
	int taps ;
	float *kernel, *delayLine, v ;
	
	taps = fir->activeTaps ;
	kernel = &fir->kernel[0] ;
	
	if ( fir->delaylineHead >= taps ) {
		memcpy( &fir->delayLine[0], &fir->delayLine[fir->delaylineHead], sizeof( float )*taps ) ;
		fir->delaylineHead = 0 ;
	}
	delayLine = &fir->delayLine[fir->delaylineHead] ;
	//  provide FIR overlap by copying new data at the end the delay line 
	delayLine[taps] = input ;
	conv( delayLine, 1, fir->kernel, 1, &v, 1, 1, taps ) ;
	fir->delaylineHead++ ;
	return v ;
}

//  add one sample to delay line and return samply that came out.
float CMSimpleDelay( CMFIR *fir, float input )
{
	int taps ;
	float v ;
	
	taps = fir->activeTaps ;
	
	v = fir->delayLine[0] ;
	fir->delayLine[taps] = input ;
	memcpy( &fir->delayLine[0], &fir->delayLine[1], sizeof( float )*taps ) ;
	return v ;
}

//  advance filter with new samples, but do not compute output.
void CMAdvanceFilter( CMFIR *fir, float* input, int n )
{
	int taps, i, j ;
	
	taps = fir->activeTaps ;
	if ( ( fir->delaylineHead+n ) < taps ) {
		j = fir->delaylineHead+taps ;
		for ( i = 0; i < n; i++ ) fir->delayLine[i+j] = input[i] ;
		fir->delaylineHead += n ;
		return ;
	}
	for ( i = 0; i < n; i++ ) {
		if ( fir->delaylineHead >= taps ) {
			memcpy( &fir->delayLine[0], &fir->delayLine[fir->delaylineHead], sizeof( float )*taps ) ;
			fir->delaylineHead = 0 ;
		}
		fir->delayLine[fir->delaylineHead+taps] = input[i] ;
		fir->delaylineHead++ ;
	}
}

//  decimate for one sample.  Length of inArray must be decimation ratio
float CMDecimate( CMFIR *fir, float *inArray )
{
	int factor, taps ;
	float *kernel, *delayLine, v ;
	
	factor = fir->stride ;		//  factor is decimation ratio
	taps = fir->activeTaps ;
	kernel = &fir->kernel[0] ;
	
	if ( fir->delaylineHead >= taps ) {
		memcpy( &fir->delayLine[0], &fir->delayLine[fir->delaylineHead], sizeof( float )*taps ) ;
		fir->delaylineHead = 0 ;
	}
	delayLine = &fir->delayLine[fir->delaylineHead] ;
	//  provide FIR overlap by copying new data at the end the delay line 
	memcpy( &delayLine[taps], inArray, sizeof( float )*factor ) ;
	v = 0.0 ;
	conv( delayLine, 1, fir->kernel, 1, &v, 1, 1, taps ) ;

	fir->delaylineHead += factor ;
	return v ;
}

//  apply FIR filter for inArray and length of array
//  size of outArray depends of the style
void CMPerformFIR( CMFIR *fir, float *inArray, int inLength, float *outArray )
{
	switch ( fir->style ) {
	case kCMFilter:
		performFilter( fir, inArray, inLength, outArray ) ;
		break ;
	case kCMDelayLine:
		performDelay( fir, inArray, inLength, outArray ) ;
		break ;
	case kCMInterpolate:
		performInterpolation( fir, inArray, inLength, outArray ) ;
		break ;
	case kCMDecimate:
		performDecimation( fir, inArray, inLength, outArray ) ;
		break ;
	default:
		break ;
	}
}

void CMDeleteFIR( CMFIR *fir )
{
	if ( !fir ) return ;
	
	free( fir->delayLine ) ;
	free( fir->kernel ) ;
	free( fir ) ;
}

