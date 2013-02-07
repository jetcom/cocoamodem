//
//  OptionTextField.m
//  cocoaModem
//
//  Created by Kok Chen on 12/1/04.
	#include "Copyright.h"
//

#import "OptionTextField.h"

@implementation OptionTextField

//  NSTextField that traps option key changes

//  NSResponder
- (void)flagsChanged:(NSEvent*)event
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"OptionKey" object:event ] ;
	[ super flagsChanged:event ] ;
}


@end
