//
//  splashPanel.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/5/07.
//  Copyright 2007 Kok Chen, W7AY. All rights reserved.
//

#import "splashPanel.h"


@implementation splashPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)style backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	self = [ super initWithContentRect:contentRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:YES ] ;
	if ( self ) {
		[ self setBackgroundColor: [ NSColor whiteColor ] ] ;
		[ self setLevel:NSNormalWindowLevel ] ;
		[ self setHasShadow:YES ] ;
	}
    return self;
}

@end
