//
//  CoreModem.m
//  CoreModem
//
//  Created by Kok Chen on 10/26/05.
	#include "Copyright.h"

#import "CoreModem.h"
#include "CoreModemTypes.h"
#include <math.h>


@implementation CoreModem

float *mssin, *lssin, *mscos, *lscos ;

- (id)init
{
	double theta ;
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		mssin = (float*)malloc( sizeof(float)*1024 ) ;
		lssin = (float*)malloc( sizeof(float)*1024 ) ;
		mscos = (float*)malloc( sizeof(float)*1024 ) ;
		lscos = (float*)malloc( sizeof(float)*1024 ) ;
		for ( i = 0; i < 1024; i++ ) {
			theta = ( i<< 10 )*2.0*CMPi/( 262144.0 ) ;
			mssin[i] = sin( theta ) ;
			mscos[i] = cos( theta ) ;
			theta = i*2.0*CMPi/( 262144.0 ) ;
			lssin[i] = sin( theta ) ;
			lscos[i] = cos( theta ) ;
		}
	}
	return self ;
}

- (void)dealloc
{
	free( mssin ) ;
	free( lssin ) ;
	free( mscos ) ;
	free( lscos ) ;
	[ super dealloc ] ;
}


@end
