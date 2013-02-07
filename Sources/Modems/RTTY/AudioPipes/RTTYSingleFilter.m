//
//  RTTYSingleFilter.m
//  cocoaModem
//
//  Created by Kok Chen on Mon Jun 21 2004.
	#include "Copyright.h"
//

#import "RTTYSingleFilter.h"

@implementation RTTYSingleFilter

//  mark-only and space-only matched filters
- (id)initTone:(int)channel baud:(float)baudrate
{
	int i ;
	
	self = [ self init ] ;
	if ( self ) {
		tone = channel ;
		baud = baudrate;
		[ self setDataRate:baud ] ;
		for ( i = 0; i < 512; i++ ) demodulated[i] = 0.0 ;
	}
	return self ;
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
	if ( tone == 0 ) {
		memcpy( &markIBuffer[mux], array, n ) ;
		memcpy( &markQBuffer[mux], array+512, n ) ;
	}
	else {
		memcpy( &spaceIBuffer[mux], array+1024, n ) ;
		memcpy( &spaceQBuffer[mux], array+1536, n ) ;
	}
	mux += 512 ;
	if ( mux < 2048 ) return ;
	
	//  reach here every 2048 samples at 11025 s/s (= 186ms)
	//  match filter and decimate 2048 samples by factor of 8 to 256 output samples
	mux = 0 ;
	if ( tone == 0 ) {
		CMPerformFIR( markIFilter, markIBuffer, 2048, markIOutput ) ;
		CMPerformFIR( markQFilter, markQBuffer, 2048, markQOutput ) ;
	}
	else {
		CMPerformFIR( spaceIFilter, spaceIBuffer, 2048, spaceIOutput ) ;
		CMPerformFIR( spaceQFilter, spaceQBuffer, 2048, spaceQOutput ) ;
	}
	
	//  form split complex terms for mark and space signals
	//  256 samples every 186ms
	if ( tone == 0 ) {
		for ( i = 0; i < 256; i++ ) {
			re = markIOutput[i] ;
			im = markQOutput[i] ;
			demodulated[i] = sqrt( re*re + im*im ) ;
		}
	}
	else {
		for ( i = 0; i < 256; i++ ) {
			re = spaceIOutput[i] ;
			im = spaceQOutput[i] ;
			demodulated[i+256] = sqrt( re*re + im*im ) ;
		}
	}
	[ self exportData ] ;  // exports in 256 sample buffers
}

@end
