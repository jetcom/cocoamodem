//
//  DisplayColor.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/1/06.
	#include "Copyright.h"
	
	
#import "DisplayColor.h"

@implementation DisplayColor


//  get actual bitmap values from r, g, b values with endian swapping
//  inputs are in the range of 0 (black) to 1.0 (saturated)
//  output is either 32 bit values (millions) or 16 bit values (thousands)

+ (UInt32)millionsOfColorsFromRed:(float)r green:(float)g blue:(float)b
{
	UInt32 result ;
	
	#if __BIG_ENDIAN__
	result = ( (int)(r*255.5) << 24 ) + ( (int)(g*255.5) << 16 ) + ( (int)(b*255.5) << 8 ) + 0xff ;
	#else
	result = ( (int)(r*255.5) ) + ( (int)(g*255.5) << 8 ) + ( (int)(b*255.5) << 16 ) + 0xff000000 ;
	#endif
	
	return result ;
}



+ (UInt32)thousandsOfColorsFromRed:(float)r green:(float)g blue:(float)b
{
	UInt32 result ;
	
	#if __BIG_ENDIAN__
	result = ( (int)(r*15.5) << 12 ) + ( (int)(g*15.5) << 8 ) + ( (int)(b*15.5) << 4 ) + 0xf ;
	#else
	result = ( (int)(r*15.5) << 4 ) + ( (int)(g*15.5) ) + ( (int)(b*15.5) << 12 ) + 0xf00 ;
	#endif

	return result ;
}

@end
