//
//  CMFilter.m
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/28/05.
	#include "Copyright.h"

#import "CMFilter.h"


@implementation CMFilter

//  a CMPipe which is a prototype filter.

//  inputs to 
- (CMPipe*)init
{
	self = [ super init ] ;
	if ( self ) {
		userParam = 0.0 ;
		n = 0 ;
		fir = nil ;
		filter = nil ;
	}
	return self ;
}

- (float)userParam
{
	return userParam ;
}

- (void)setUserParam:(float)param
{
	userParam = param ;
}

- (void)importData:(CMPipe*)pipe
{
	CMDataStream *input ;
	
	if ( !filter ) return ;
	
	input = [ pipe stream ] ;  // use client's stream structure	
	CMPerformFIR( filter, input->array, 512, &outbuf[0] ) ;
	
	stream = *input ;
	stream.array = outbuf ;
	data = &stream ;
	[ self exportData ] ;
}



@end
