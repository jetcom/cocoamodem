/*
 *  Clears.c
 *  cocoaModem 2.0
 *
 *  Created by Kok Chen on 12/10/06.
 */

#include "Clears.h"

void clearLong( long *p, int length )
{
	int i ;
	
	for ( i = 0; i < length; i++ ) *p++ = 0 ;
}

void clearInt( int *p, int length )
{
	int i ;
	
	for ( i = 0; i < length; i++ ) *p++ = 0 ;
}

void clearFloat( float *p, int length )
{
	int i ;
	
	for ( i = 0; i < length; i++ ) *p++ = 0.0 ;
}

void clearChar( char *p, int length )
{
	int i ;
	
	for ( i = 0; i < length; i++ ) *p++ = 0 ;
}
