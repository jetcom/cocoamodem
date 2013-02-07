//
//  UTC.m
//  cocoaModem
//
//  Created by Kok Chen on 11/28/04.
	#include "Copyright.h"
//

#import "UTC.h"


@implementation UTC


//  set structure to GMT time, also return tm pointer
- (struct tm*)setTime
{	
	t = time( nil ) ;
	gmttime = *gmtime( &t ) ;
	return &gmttime ;
}

//  tm pointer
- (struct tm*)utc 
{
	return &gmttime ;
}


@end
