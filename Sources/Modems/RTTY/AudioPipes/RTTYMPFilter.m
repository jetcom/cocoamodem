//
//  RTTYMPFilter.m
//  cocoaModem
//
//  Created by Kok Chen on Mon Jun 21 2004.
	#include "Copyright.h"
//

#import "RTTYMPFilter.h"
#include "CoreModemTypes.h"


@implementation RTTYMPFilter

- (id)initBitWidth:(float)w baud:(float)baudrate
{
	self = [ self init ] ;
	if ( self ) {
		width = w ;
		baud = baudrate ;
		[ self setDataRate:baud ] ;
	}
	return self ;
}

//  Matched filter for Multipath.
//  pulse width set in -initBitWidth during initialization (otherwise defaulted to 0.75 of a data bit)
- (void)setDataRate:(float)rate
{
	int n, m ;
	
	enabled = NO ;
	baud = rate ;
	n = CMFs/rate * width ; 
	m = dotPrKernelSize( n+256 ) ;
	if ( kernel ) free( kernel ) ;
	kernel = createMatchedFilterKernel( n, m ) ;
	
	markIFilter = [ self setupFilter:markIFilter length:m ] ;
	markQFilter = [ self setupFilter:markQFilter length:m ] ;
	spaceIFilter = [ self setupFilter:spaceIFilter length:m ] ;
	spaceQFilter = [ self setupFilter:spaceQFilter length:m ] ;
	enabled = YES ;	
	mux = 0 ;
}

@end
