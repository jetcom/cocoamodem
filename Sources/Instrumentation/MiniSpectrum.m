//
//  MiniSpectrum.m
//  cocoaModem
//
//  Created by Kok Chen on 8/7/05.
	#include "Copyright.h"
//

#import "MiniSpectrum.h"
#include "Spectrum.h"

@implementation MiniSpectrum

//  spectrum view is 620 wide x 110 tall
- (id)initWithFrame:(NSRect)frame 
{
	int i ;
	float x, y, dash[2] = { 1.0, 2.0 } ;

	self = [ super initWithFrame:frame ] ;
	if ( self ) {
		if ( spectrumScale ) [ spectrumScale release ] ;
			
		plotWidth = 620 ;
		scale = plotWidth/408 ;
		pixPerdB = 1.25 ;

		spectrumScale = [ [ NSBezierPath alloc ] init ] ;
		[ spectrumScale setLineDash:dash count:2 phase:0 ] ;
		for ( i = 5; i < 80; i += 30 ) {
			y = (int)( height - ( i*pixPerdB ) ) + 0.5 ;
			if ( y <= 0 ) break ;
			[ spectrumScale moveToPoint:NSMakePoint( 0, y ) ] ;
			[ spectrumScale lineToPoint:NSMakePoint( plotWidth, y ) ] ;
		}
		for ( i = 500; i < 3000; i += 500 ) {
			x = ( int )( ( i-400 )*plotWidth/2200.0 ) + 0.5 ;
			[ spectrumScale moveToPoint:NSMakePoint( x, 0 ) ] ;
			[ spectrumScale lineToPoint:NSMakePoint( x, height ) ] ;
		}
	}
	return self ;
}

@end
