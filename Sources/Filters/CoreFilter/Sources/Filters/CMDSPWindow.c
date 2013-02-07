//
//  CMDSPWindow.c
//  Filter (CoreModem)
//
//  Created by Kok Chen on Sun May 30 2004.
	#include "Copyright.h"

#include "CMDSPWindow.h"
#include <math.h>

#define numpi 3.14159265358979

static void fillBlackmanWindow( float *array, int n ) ;
	
//  sinc from -w.pi to w.pi
double CMSinc( int i, int n, double w )
{
	double x, t ;
	
	if ( i < 0 || i >= n ) return 0.0 ;
	t = n/2.0 ;
	if ( ( n & 1 ) == 0 ) x = ( i+0.5 - t )/t ; else x = ( i - t )/t ;
	x = x*w ;
	if ( fabs( x ) < .0001 ) return 1.0 ;
	
	return sin( numpi*x )/( numpi*x ) ;
}

double CMHammingWindow( int i, int n )
{
	float x ;
	
	if ( i < 0 || i >= n ) return 0.0 ;
	if ( ( n & 1 ) == 0 ) x = i+0.5 ; else x = i ;
	return 0.54 + 0.46*( sin( numpi*x/n ) ) ;
}

double CMHanningWindow( int i, int n )
{
	float x ;
	
	if ( i < 0 || i >= n ) return 0.0 ;
	if ( ( n & 1 ) == 0 ) x = i+0.5 ; else x = i ;
	return 0.5 + 0.5*( sin( numpi*x/n ) ) ;
}

double CMBlackmanWindow( int i, int n ) 
{
	float x ;
	
	if ( i < 0 || i >= n ) return 0.0 ;
	if ( ( n & 1 ) == 0 ) x = i+0.5 ; else x = i ;
	return ( .42 - .5*cos(2*numpi*x/n) + .08*cos( 4*numpi*x/n ) ) ;
}

//  half cycle raised sine
double CMSineWindow( int i, int n ) 
{
	float x ;
	
	if ( i < 0 || i >= n ) return 0.0 ;
	if ( ( n & 1 ) == 0 ) x = i+0.5 ; else x = i ;
	return ( sin( numpi*x/n ) ) ;
}

//  produces a slightly more symmetrcal frequency impulse than the standard Blackman
double CMModifiedBlackmanWindow( int i, int n ) 
{
	float x ;
	
	if ( i < 0 || i >= n ) return 0.0 ;
	if ( ( n & 1 ) == 0 ) x = i+0.5 ; else x = i ;
	return ( .426 - .5*cos( 2*numpi*x/n ) + .074*cos( 4*numpi*x/n ) ) ;
}

float *CMMakeSinc( int n, double w )
{
	float *p ;
	int i ;
	
	p = ( float* )malloc( sizeof( float )*n ) ;
	for ( i = 0; i < n; i++ ) p[i] = CMSinc( i, n, w ) ;
	return p ;
}

static void fillBlackmanWindow( float *p, int n )
{
	int i ;
	
	for ( i = 0; i < n; i++ ) p[i] = CMBlackmanWindow( i, n ) ;
}

static void fillModifiedBlackmanWindow( float *p, int n )
{
	int i ;
	
	for ( i = 0; i < n; i++ ) p[i] = CMModifiedBlackmanWindow( i, n ) ;
}

float *CMMakeBlackmanWindow( int n )
{
	float *p ;
	
	p = ( float* )malloc( sizeof( float )*n ) ;
	fillBlackmanWindow( p, n ) ;
	return p ;
}

float *CMMakeModifiedBlackmanWindow( int n )
{
	float *p ;
	
	p = ( float* )malloc( sizeof( float )*n ) ;
	fillModifiedBlackmanWindow( p, n ) ;
	return p ;
}

