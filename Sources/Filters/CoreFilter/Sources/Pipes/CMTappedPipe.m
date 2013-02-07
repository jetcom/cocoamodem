//
//  CMTappedPipe.m
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/30/05.
	#include "Copyright.h"
	
#import "CMTappedPipe.h"


@implementation CMTappedPipe

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		 tapClient = nil ;
	}
	return self ;
}

- (CMPipe*)tap
{
	return tapClient ;
}

- (void)setTap:(CMPipe*)tap
{
	tapClient = tap ;
}

//  call client's importData method with our data
- (void)exportData
{
	[ super exportData ] ;
	if ( tapClient ) [ tapClient importData:self ] ;
}


@end
