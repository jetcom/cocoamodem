
//  HellschreiberFont.c
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/31/06.
	#include "Copyright.h"
	
#include "HellschreiberFont.h"
#include <stdio.h>
#include <stdlib.h>
#include <netinet/in.h>

HellschreiberFontHeader* MakeHellFont(const char *filename )
{
	FILE *f ;
	HellschreiberFontHeader *header ;
	unsigned char *fontData ;
	int i ;

	f = fopen( filename, "rb" ) ;
	if ( !f ) return (HellschreiberFontHeader*)0 ;
	
	header = ( HellschreiberFontHeader* )malloc( sizeof( HellschreiberFontHeader ) ) ;
	
	fread( header, sizeof( HellschreiberFontHeader ), 1, f ) ;
	
	header->version = ntohs( header->version ) ;
	header->size = ntohs( header->size ) ;
	for ( i = 0; i < 128; i++ ) header->index[i] = ntohs( header->index[i] ) ;
	
	fontData = (unsigned char*)malloc( header->size ) ;
	fread( fontData, 1, header->size, f ) ;
	fclose( f ) ;
	
	header->fontData = fontData ;
	return header ;
}