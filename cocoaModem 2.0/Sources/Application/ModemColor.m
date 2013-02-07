//
//  ModemColor.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/27/05.
	#include "Copyright.h"
//

#import "ModemColor.h"


@implementation ModemColor

- (void)awakeFromNib
{
	delegate = nil ;
}

//  prototype for delegate
- (void)colorChanged:(NSColorWell*)client
{
}

- (void)setColor:(NSColor*)color
{
	[ super setColor:[ color colorUsingColorSpace:[ NSColorSpace deviceRGBColorSpace ] ] ] ;
	if ( delegate && [ delegate respondsToSelector:@selector(colorChanged:) ] ) [ delegate colorChanged:self ] ;
}

- (id)delegate
{
	return delegate ;
}

- (void)setDelegate:(id)client
{
	delegate = client ;
}

@end
