//
//  ClickedTableView.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/7/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "ClickedTableView.h"


@implementation ClickedTableView

- (void)useControlButton:(Boolean)state
{
	option = NO ;
	optionMask = ( state ) ? NSControlKeyMask : NSAlternateKeyMask ;
}

- (void)mouseDown:(NSEvent*)event
{
	unsigned int flags ;

	flags = [ event modifierFlags ] ;
	option = ( flags & optionMask ) != 0 ;
	[ super mouseDown:event ] ;
}

- (Boolean)optionClicked
{
	return option ;
}

@end
