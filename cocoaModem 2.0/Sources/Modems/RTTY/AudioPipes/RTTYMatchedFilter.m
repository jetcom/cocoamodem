//
//  RTTYMatchedFilter.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/8/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "RTTYMatchedFilter.h"
#import "Application.h"

@implementation RTTYMatchedFilter

//	Extend CMFSKMatchedFilter to include AuralMonitor.

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
	}
	return self ;
}

//  Data comes here from the mixer as an array with four 512 float subarrays: Mark I, Mark Q, space I and Space Q, sampled at 11025 s/s.
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
	//  note that markIFilter, markQFilter, etc are decimation ploters
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
