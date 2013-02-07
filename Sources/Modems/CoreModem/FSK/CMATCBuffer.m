//
//  CMATCBuffer.m
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Sat Aug 07 2004)
	#include "Copyright.h"

#import "CMATCBuffer.h"

@implementation CMATCBuffer

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		outputClient = nil ;
		data->array = &buf[0] ;
		data->samples = 512 ;
		data->components = data->channels = 1 ;
		mux = 0 ;
	}
	return self ;
}

//  export data to scope if the tap is active
//  each call has 256 samples
- (void)atcData:(CMATCStream*)atc
{
	int i ;
	CMATCPair *pair ;
	
	if ( tapClient ) {
		pair = &atc->data[128] ;
		if ( mux == 0 ) {
			for ( i = 0; i < 256; i++ ) {
				buf[i] = ( pair->mark - pair->space )*0.6 ;
				pair++ ;
			}
			mux++ ;
		}
		else {
			mux = 0 ;
			for ( i = 256; i < 512; i++ ) {
				buf[i] = ( pair->mark - pair->space )*0.6 ;
				pair++ ;
			}			
			[ self exportData ] ;
		}
	}
}

@end
