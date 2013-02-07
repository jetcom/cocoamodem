//
//  About.m
//  cocoaModem
//
//  Created by Kok Chen on Wed May 12 2004.
	#include "Copyright.h"
//

#import "About.h"
#include <CoreFoundation/CFPreferences.h>

@implementation About

- (id)initFromNib
{
	self = [ super init ] ;
	if ( self ) {
		[ NSBundle loadNibNamed:@"About" owner:self ] ;
	}
	return self ;
}

- (void)showPanel
{
	if ( window ) {
		[ window center ] ;
		[ window orderFront:nil ] ;
	}
}

@end
