//
//  DestClient.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/1/06.
	#include "Copyright.h"
	
	
#import "DestClient.h"
#include "ModemDest.h"

@implementation DestClient


- (int)needData:(float*)outbuf samples:(int)n
{
	// override from ModemConfig.m
	return 0 ;
}

- (void)setOutputScale:(float)value
{
	// override from ModemConfig.m
}

@end
