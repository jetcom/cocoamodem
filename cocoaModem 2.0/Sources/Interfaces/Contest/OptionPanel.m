//
//  OptionPanel.m
//  cocoaModem
//
//  Created by Kok Chen on 10/15/04.
	#include "Copyright.h"
//

#import "OptionPanel.h"


/*
 *	Informs application of option key changes
 */

@implementation OptionPanel

//  NSResponder
- (void)flagsChanged:(NSEvent*)event
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"OptionKey" object:event ] ;
	[ super flagsChanged:event ] ;
}

@end
