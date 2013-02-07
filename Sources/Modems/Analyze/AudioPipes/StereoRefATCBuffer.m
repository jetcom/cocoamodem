//
//  StereoRefATCBuffer.m
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
	#include "Copyright.h"
//

#import "StereoRefATCBuffer.h"
#include "MultiStereoATC.h"

//  an AudioPipe which takes imported data and exporting instead to the next stage's importClockData
@implementation StereoRefATCBuffer

- (void)importData:(CMPipe*)pipe
{
	*data = *[ pipe stream ] ;
	if ( outputClient ) [ outputClient performSelector:@selector(importClockData:) withObject:self ] ;
}


@end
