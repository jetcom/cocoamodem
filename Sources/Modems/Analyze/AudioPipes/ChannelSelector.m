//
//  ChannelSelector.m
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
	#include "Copyright.h"
//

#import "ChannelSelector.h"


//  Some CMPipe data streams contains two (stereo) channel data
//  In this case, the data in the channels are arranged as vDSP style "split complex channels"
//	  i.e, left[0],left[1],...,left[n-1],right[0],right[1],...,right[n-1]
//
//	ChannelSelectorPipe is simply an audio pipe that passes the data out so that it looks like
//	either left[0],left[1],...left[n-1] or as right[0],right[1],...,right[n-1]

@implementation ChannelSelector

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		selected = 0 ;
	}
	return self ;
}

//  channel = { 0, 1 } for stereo (0 = left, 1 = right)
- (void)selectChannel:(int)channel
{
	if ( channel < 0 ) channel = 0 ; else if ( channel > 1 ) channel = 1 ;
	selected = channel ;
}

- (void)importData:(CMPipe*)pipe
{
	int offset ;
	
	*data = *[ pipe stream ] ;
	if ( selected != 0 && data->channels > 1 ) {
		offset = selected ;
		if ( offset > ( data->channels-1 ) ) offset = 0 ;
		data->array += ( data->samples*offset ) ;
	}
	[ self exportData ] ;
}

@end
