//
//  VOXInterface.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/16/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "VOXInterface.h"


@implementation VOXInterface

- (id)initWithName:(NSString*)vname
{
	self = [ super initWithName:vname ] ;
	if ( self ) {
		hasPTT = YES ;
		type = kVOXType ;
	}
	return self ;
}

- (Boolean)connected
{
	return YES ;
}

@end
