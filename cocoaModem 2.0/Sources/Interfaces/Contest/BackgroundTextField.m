//
//  BackgroundTextField.m
//  cocoaModem
//
//  Created by Kok Chen on 11/23/04.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "BackgroundTextField.h"


@implementation BackgroundTextField

- (void)awakeFromNib
{
	[ self setBezeled:YES ] ;
	[ self setDrawsBackground:YES ] ;
}

@end
