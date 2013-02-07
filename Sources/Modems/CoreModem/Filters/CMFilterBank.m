//
//  CMFilterBank.m
//  CoreModem
//
//  Created by Kok Chen on 10/25/05.
	#include "Copyright.h"

#import "CMFilterBank.h"


@implementation CMFilterBank

//  a CMPipe which contains an output buffer and multiple input filters

//  inputs to 
- (CMPipe*)init
{
	self = [ super init ] ;
	if ( self ) {
		filters = 0 ;
		selectedFilter = nil ;
	}
	return self ;
}

- (int)filters
{
	return filters ;
}

- (void)selectFilter:(int)index
{
	if ( index >= filters ) return ;
	selectedFilter = filter[index] ;
}

- (void)installFilter:(CMPipe*)f
{
	if ( filters == 0 ) selectedFilter = f ;
	if ( filters > 31 ) return ;
	
	filter[ filters++] = f ;
	//  send filter output to our pipelined buffer
	[ f setPipelinedClient:self ] ;
}

//  input is sent here and routed to the selected filter
//  each filter is set up (in newFilter) to pass data back to CMFilterBank through our -importPipelinedData: 
- (void)importData:(CMPipe*)pipe
{
	//  send input to the selected filter
	if ( selectedFilter ) [ selectedFilter importData:pipe ] ;
}

@end
