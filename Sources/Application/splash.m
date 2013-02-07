//
//  splash.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Jun 24 2004.
	#include "Copyright.h"
//

#import "splash.h"


@implementation splash

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		active = [ NSBundle loadNibNamed:@"Splash" owner:self ] ;
	}
	return self ;
}


- (void)positionWindow
{
	if ( active ) {
		[ splashScreen center ] ;
		[ splashScreen orderFront:self ] ;
		[ splashScreen setLevel:NSFloatingWindowLevel ] ;
	}
}

- (void)showMessage:(NSString*)msg
{
	if ( active ) {
		[ splashMsg setStringValue:msg ] ;
		[ splashScreen display ] ;
	}
}

- (void)remove
{
	if ( active ) {
		[ splashScreen orderBack:self ] ;
		[ splashScreen setLevel:NSNormalWindowLevel ] ;
		[ splashScreen release ] ;
	}
	active = NO ;
}

@end
