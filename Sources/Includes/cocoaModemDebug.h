/*
 *  cocoaModemDebug.h
 *  cocoaModem
 *
 *  Created by Kok Chen on Thu Jul 15 2004.
 *
 */

#include "Messages.h"

#define noDEBUG 


#ifdef DEBUG
#define debug( a )			printf( a )
#define debug2( a, b )		printf( a, b )
#define debug3( a, b, c )	printf( a, b, c )
#define debug4( a, b, c, d )	printf( a, b, c, d )
#else
#define debug( a )
#define debug2( a, b )
#define debug3( a, b, c )
#define debug4( a, b, c, d )
#endif

#define quitWithError( msg )	{ [ Messages alertWithMessageText:NSLocalizedString( @"Internal error", nil ) informativeText:msg ] ; exit( 0 ) ; }

