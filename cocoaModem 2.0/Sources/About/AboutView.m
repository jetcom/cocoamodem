//
//  AboutView.m
//  cocoaModem
//
//  Created by Kok Chen on Mon May 17 2004.
	#include "Copyright.h"
//

#import "AboutView.h"
#import "TextEncoding.h"


@implementation AboutView

- (void)drawRect:(NSRect)rect 
{
	NSBezierPath *background ;
	NSString *version ;
	
	if ( [ self lockFocusIfCanDraw ] ) {
		[ [ NSColor whiteColor ] set ] ;
		background = [ NSBezierPath bezierPathWithRect:[ self bounds ] ] ;
		[ background fill ] ;
		[ self unlockFocus ] ;
	}

	[ super drawRect:rect ] ;
	
	if ( [ self lockFocusIfCanDraw ] ) {
		//  set version string in About panel
		version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
		if ( version ) {
			[ versionString setStringValue:[ NSString stringWithFormat:@"Version %s", [ version cStringUsingEncoding:kTextEncoding ] ] ] ;
		}
		[ self unlockFocus ] ;
	}
}

@end
