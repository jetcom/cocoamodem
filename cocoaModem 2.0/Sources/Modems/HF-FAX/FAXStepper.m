//
//  FAXStepper.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/19/06.
	#include "Copyright.h"
	
	
#import "FAXStepper.h"

//  counts requests since mouse down
//	this allows stepping to be accelerated

@implementation FAXStepper

- (void)mouseDown:(NSEvent*)event
{
	steps = 0 ;
	[ super mouseDown:event ] ;
}

- (int)steps
{
	steps++ ;
	return steps ;
}


@end
