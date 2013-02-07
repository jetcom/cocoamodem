//
//  CMFSKMatchedFilter.m
//  coreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Sun Jun 13 2004)
	#include "Copyright.h"

#import "CMFSKMatchedFilter.h"
#include "CMDSPWindow.h"
#include "CMFIR.h"
#include "CoreModemTypes.h"
#include <vecLib/vDSP.h>

//  RTTY Matched filter takes in I and Q split complex channels of data (4 separate streams of 512 samples each)
//  output is devimated by 8 to Fs/8

@implementation CMFSKMatchedFilter

- (id)initDefaultFilterWithBaudRate:(float)baudrate
{
	self = [ self init ] ;
	if ( self ) {
		baud = baudrate ;
		[ self setDataRate:baud ] ;
	}
	return self ;
}

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		//  set up CMDataStream
		data = &mfStream ;
		mfStream.array = &demodulated[0] ;
		mfStream.samplingRate = CMFs/8 ;
		mfStream.samples = 256 ;
		mfStream.components = 1 ;
		mfStream.channels = 2 ;
		kernel = nil ;
		enabled = NO ;
		mux = 0 ;
		markIFilter = markQFilter = spaceIFilter = spaceQFilter = nil ;
		width = 1.0 ;
	}
	return self ;
}

- (CMFIR*)setupFilter:(CMFIR*)filter length:(int)m
{
	if ( filter ) CMDeleteFIR( filter ) ;
	return CMFIRDecimate( 8, kernel, m ) ;
}

//  find next larger integer that matches criteria for vDSP dot products
int dotPrKernelSize( int n )
{
	if ( n < 32 ) n = 32 ;
	return ( ( n+1 )/2 )*2 ;
}

//  n = bit width, m = result matched filter width (including LPF)
float *createExtendedMatchedFilterKernel( int n, int m, float cutoff, int extn )
{
	CMFIR *lowpass ;
	float *kernel, *matched, sum ;
	int i ;
	
	//  integrate and dump filter
	matched = ( float* )malloc( sizeof( float )*( m+extn*2 ) ) ;
	for ( i = 0; i < extn*2; i++ ) matched[i] = 0.0 ;
	for ( ; i < n+extn*2; i++ ) matched[i] = 1.0 ;
	for ( ; i < m+extn*2; i++ ) matched[i] = 0 ;

	//  create a windowed lowpass filter of length EXTN	
	lowpass = CMFIRLowpassFilter( cutoff, CMFs, extn*2 ) ;	
	
	//  convolve matched filter with the lowpass filter
	kernel = ( float* )calloc( sizeof( float ), m ) ;
	conv( matched, 1, lowpass->kernel, 1 /*symmetrical lpf*/, kernel, 1, m, extn*2 ) ;
	sum = 0.0 ;
	for ( i = 0; i < m; i++ ) sum += kernel[i] ;
	sum *= 0.25 ;
	for ( i = 0; i < m; i++ ) kernel[i] /= sum ;
	
	CMDeleteFIR( lowpass ) ;
	free( matched ) ;
	return kernel ;
}

//  n = bit width, m = result matched filter width (including LPF)
float *createMatchedFilterKernel( int n, int m )
{
	return createExtendedMatchedFilterKernel( n, m, 110.0, 512 ) ;
}

#define	EXTN 256

- (void)setDataRate:(float)rate lowpass:(float)cutoff 
{
	int n, m ;
	float *oldkernel ;
	
	enabled = NO ;
	baud = rate ;
	n = CMFs/rate*width ;
	m = n+2*EXTN ;					//  the EXTN takes care of the LPF extension to the matched filter
	//  make m divisible by 16
	m = ( ( m+15 )/16 ) * 16 ;	

	oldkernel = kernel ;
	kernel = createExtendedMatchedFilterKernel( n, m, cutoff, EXTN ) ;
	if ( oldkernel ) free( oldkernel ) ;

	markIFilter = [ self setupFilter:markIFilter length:m ] ;
	markQFilter = [ self setupFilter:markQFilter length:m ] ;
	spaceIFilter = [ self setupFilter:spaceIFilter length:m ] ;
	spaceQFilter = [ self setupFilter:spaceQFilter length:m ] ;
	enabled = YES ;	
	mux = 0 ;
}

- (void)setDataRate:(float)rate
{
	[ self setDataRate:rate lowpass:110.0 ] ;
}

- (void)importData:(CMPipe*)pipe
{
	int i, n ;
	float *array, re, im ;
	CMDataStream *stream ;
	
	if ( !enabled ) return ;
	
	//  accumulate data streams into buffers of 2048 samples
	stream = [ pipe stream ] ;
	mfStream.sourceID = stream->sourceID ;
	array = stream->array ;
	n = sizeof( float )*512 ;
	
	memcpy( &markIBuffer[mux], array, n ) ;
	memcpy( &markQBuffer[mux], array+512, n ) ;
	memcpy( &spaceIBuffer[mux], array+1024, n ) ;
	memcpy( &spaceQBuffer[mux], array+1536, n ) ;
	mux += 512 ;
	if ( mux < 2048 ) return ;
	
	//  reach here every 2048 samples at 11025 s/s (= 186ms)
	//  match filter and decimate 2048 samples by factor of 8 to 256 output samples
	mux = 0 ;
	CMPerformFIR( markIFilter, markIBuffer, 2048, markIOutput ) ;
	CMPerformFIR( markQFilter, markQBuffer, 2048, markQOutput ) ;
	CMPerformFIR( spaceIFilter, spaceIBuffer, 2048, spaceIOutput ) ;
	CMPerformFIR( spaceQFilter, spaceQBuffer, 2048, spaceQOutput ) ;
	
	//  form split complex terms for mark and space signals
	//  256 samples every 186ms
	for ( i = 0; i < 256; i++ ) {
		re = markIOutput[i] ;
		im = markQOutput[i] ;
		demodulated[i] = sqrt( re*re + im*im )*2.5 ;			//  v0.76 added factor of 2.5 for RTTYMonitor
		re = spaceIOutput[i] ;
		im = spaceQOutput[i] ;
		demodulated[i+256] = sqrt( re*re + im*im )*2.5 ;
	}
	[ self exportData ] ;  // exports in 256 sample buffers
}

@end
