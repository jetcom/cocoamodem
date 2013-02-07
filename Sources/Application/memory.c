/*
 *  memory.c
 *  cocoaModem 2.0
 *
 *  Created by Kok Chen on 9/30/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */

#include "memory.h"
#include <stdio.h>

void cmFree( void* ptr )
{
	printf( "cmFree callled -------\n" ) ;
	//  free( ptr ) ;
}
