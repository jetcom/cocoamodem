//
//  ModemDistributionBox.m
//  cocoaModem
//
//  Created by Kok Chen on Wed Jun 09 2004.
	#include "Copyright.h"
//

#import "ModemDistributionBox.h"


@implementation ModemDistributionBox

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		first = second = nil ;
	}
	return self ;
}

//  send audio stream to two audioPipe destinations
//  each can be nil
- (void)setFirst:(CMPipe*)p1 second:(CMPipe*)p2
{
	first =  p1 ;
	second = p2 ;
}

- (void)setFirst:(CMPipe*)p1
{
	first = p1 ;
}

- (void)setSecond:(CMPipe*)p2
{
	second = p2 ;
}

- (void)importData:(CMPipe*)pipe
{
	if ( first ) [ first importData:pipe ] ;
	if ( second ) [ second importData:pipe ] ;
}

@end
