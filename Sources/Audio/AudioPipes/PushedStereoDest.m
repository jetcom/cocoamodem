//
//  PushedStereoDest.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/1/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "PushedStereoDest.h"


@implementation PushedStereoDest

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initIntoView:(NSView*)view device:(NSString*)name level:(NSView*)level client:(DestClient*)inClient 
{
	self = [ super initIntoView:view device:name level:level client:inClient channels:2 ] ;
	
	//  use a pushed reampling pipe instead
	[ resamplingPipe setUseConstantOutputBufferSize:NO ] ;

	return self ;
}

- (int)needData:(float*)outbuf samples:(int)n channels:(int)ch
{
	if ( client ) return [ client needData:outbuf samples:n channels:ch ] ;
	
	memset( outbuf, 0, sizeof( float )*n*ch ) ;
	return n ;
}


@end
