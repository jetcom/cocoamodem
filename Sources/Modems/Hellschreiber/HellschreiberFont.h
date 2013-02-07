//
//  HellschreiberFont.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/29/06.
	#include "Copyright.h"

#ifndef _HELLSCHREIBERFONT_H_
	#define _HELLSCHREIBERFONT_H_
		
	typedef struct {
		short version ;
		short size ;
		char name[32] ;
		short index[128] ;
		unsigned char *fontData ;
	} HellschreiberFontHeader ;
	
	//  version 0: 7 bit tall character (including blank rows)
	//
	// Each bitmap table enty starts with a byte that is the ASCII equivalent character,
	// the next byte defines number of columns of the character.
	// The following bytes (16 per column) define the half-pixels of each column, one byte per pixel, 
	// LSB at the bottom.  0 is background, 0xff is full intensity foreground.
	
	HellschreiberFontHeader* MakeHellFont(const char *filename ) ;
	
	//  Version flags
	#define	STEMALIGNED	0x8000
	
#endif
