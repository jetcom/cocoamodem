//
//  CMPipe.m
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/24/05.
	#include "Copyright.h"
//

#import "CMPipe.h"


@implementation CMPipe

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		outputClient = nil ;
		isPipelined = NO ;
		//data = (CMDataStream*)malloc( sizeof( CMDataStream ) ) ;
		data = &staticStream ;		//  v0.80l
		data->array = nil ;
		data->userData = 0 ;
		data->samples = data->components = 0 ;
		data->channels = 1 ;
	}
	return self ;
}

- (id)pipeWithClient:(CMPipe*)client
{
	self = [ self init ] ;
	if ( self ) {
		outputClient = client ;
	}
	return self ;
}

- (CMPipe*)client
{
	return outputClient ;
}

- (void)setClient:(CMPipe*)inClient
{
	outputClient = inClient ;
	isPipelined = NO ;
}

- (void)setPipelinedClient:(CMPipe*)inClient
{
	outputClient = inClient ;
	isPipelined = YES ;
}

- (CMDataStream*)stream
{
	return data ;
}

//  base class of AudioPipe implements a NOP pipe
//  we simply forward the data to the next stage of the pipeline
- (void)importData:(CMPipe*)pipe
{
	*data = *[ pipe stream ] ;
	[ self exportData ] ;
}

- (void)importPipelinedData:(CMPipe*)pipe
{
	*data = *[ pipe stream ] ;
	[ self exportData ] ;
}

//  call client's importData method with our data
- (void)exportData
{
	if ( outputClient ) {
		if ( isPipelined ) [ outputClient importPipelinedData:self ] ; else [ outputClient importData:self ] ;
	}
}

@end
