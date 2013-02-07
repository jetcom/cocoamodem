//
//  TextFieldForScrolling.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/24/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "TextFieldForScrolling.h"


@implementation TextFieldForScrolling

- (id)initWithCoder:(NSCoder*)decoder
{
	self = [ super initWithCoder:decoder ] ;
	if ( self ) {
		paused = NO ;
	}
	return self ;
}

- (void)setPaused:(Boolean)state
{
	paused = state ;
	//if ( paused == NO ) [ self display ] ;
}

- (void)drawRect:(NSRect)rect
{
	if ( paused ) return ;
	[ super drawRect:rect ] ;
}


@end
