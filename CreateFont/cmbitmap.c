/*
 *  cmbitmap.c
 *  CreateFont
 *
 *  Created by Kok Chen on 4/17/06.
 */

#include "cmbitmap.h"

#include "HellschreiberFont.h"
#include "utils.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "cmbitmap_def.h"

void cmbitmapaa()
{
	unsigned char *s, *start ;
	HellschreiberFontHeader header ;
	int i ;
	FILE *f ;
	
	start = ( unsigned char* )malloc( 65536*sizeof( unsigned char ) ) ;
	
	//  anti-alised version
	header.version = 0 ;
	strcpy( header.name, "cm bitmap aa" ) ;
	for ( i = 0; i < 128; i++ ) header.index[i] = 0 ; // point to space character

	s = start ;
	//  space character
	s = addTallPattern( s, start, &header, ' ', 6,	cmspace ) ;

	
	s = addGrayFont( s, start, &header, 'A', 7, "000000000000", "6cdeffffff00", "ee000cc00000", "ee000cc00000", "ee000cc00000", "4cdeffffff00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'B', 7, "000000000000", "ffffffffff00", "ff00cc00ff00", "ff00cc00ff00", "cf22cc22fc00", "4cdd66ddc400", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'C', 7, "000000000000", "6cdefffec600", "ce600006ec00", "ff000000ff00", "ff000000ff00", "ff000000ff00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'D', 7, "000000000000", "ffffffffff00", "ff000000ff00", "ff000000ff00", "ce400004ec00", "6cdefffec600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'E', 6, "000000000000", "ffffffffff00", "ff00ee00ff00", "ff00ee00ff00", "ff00ee00ff00", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'F', 6, "000000000000", "ffffffffff00", "ff00ee000000", "ff00ee000000", "ff00ee000000", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'G', 7, "000000000000", "6cdefffec600", "ce400004ec00", "ff000000ff00", "ff00cc00ff00", "0000ffffc600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'H', 7, "000000000000", "ffffffffff00", "0000cc000000", "0000cc000000", "0000cc000000", "ffffffffff00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'I', 5, "000000000000", "000000000000", "ffffffffff00", "000000000000", "000000000000", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'J', 7, "000000000000", "000000fec600", "00000006ec00", "00000000ff00", "00000006ec00", "fffffffec600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'K', 7, "000000000000", "ffffffffff00", "0004ff400000", "006cffc60000", "0afc33cfa000", "ffc0000cff00", "000000000000" ) ;
	s = addFont( s, start, &header, 'L', 6, 0x000, 0xffc, 0x00c, 0x00c, 0x00c, 0x000, 0x000 ) ;	
	s = addGrayFont( s, start, &header, 'N', 7, "000000000000", "6cdeffffff00", "ce4000000000", "ff0000000000", "ce4000000000", "6cdeffffff00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'O', 7, "000000000000", "6cdeffedc600", "ce400004ec00", "ff000000ff00", "ce400004ec00", "6cdeffedc600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'P', 7, "000000000000", "ffffffffff00", "ff000cc00000", "ff000cc00000", "ce202ec00000", "4cdfdc400000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'Q', 7, "000000000000", "6cdeffedc600", "ce400004ec00", "ff0000afff00", "ce400004efe0", "6cdeffedc4aa", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'R', 7, "000000000000", "ffffffffff00", "ff000cc00000", "ff000cc00000", "ce202eeee800", "4cdfdc40cf00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'S', 7, "000000000000", "6cfff00fc600", "ff00ff00ff00", "ff00ff00ff00", "ff00ff00ff00", "6cf00fffc600", "000000000000" ) ;	
	s = addFont( s, start, &header, 'T', 7, 0x000, 0xc00, 0xc00, 0xffc, 0xc00, 0xc00, 0x000 ) ;
	s = addGrayFont( s, start, &header, 'U', 7, "000000000000", "ffffffedc600", "00000004ec00", "00000000ff00", "00000004ec00", "ffffffedc600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'V', 7, "000000000000", "fffffffffc00", "00000006df00", "000006cfa000", "0006cff40000", "ffffc6000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'X', 7, "000000000000", "fe000000ef00", "08fc22cf8000", "008ffff80000", "08fc22cf8000", "fe000000ef00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'Y', 7, "000000000000", "fffc60000000", "006cfc200000", "00008fffff00", "004cfc200000", "fffc60000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, 'Z', 7, "000000000000", "ff000008ff00", "ff0048ffff00", "ff06ff60ff00", "ffff8400ff00", "ff800000ff00", "000000000000" ) ;
	s = addWideGrayFont( s, start, &header, 'M', 9, "000000000000", "6cdeffffff00", "ec4000000000", "ec4000000000", "4adeffffff00", "ec4000000000", "ec4000000000", "6cdeffffff00", "000000000000" ) ;
	s = addWideGrayFont( s, start, &header, 'W', 9, "000000000000", "ffffffedc600", "00000004ce00", "00000004ce00", "ffffffeda400", "00000004ce00", "00000004ce00", "ffffffedc600", "000000000000" ) ;
	
	for ( i = 'a'; i <= 'z'; i++ ) header.index[i] = header.index[i-'a'+'A'] ;
	
	/* lower case */
	s = addTallPattern( s, start, &header, 'a', 8,	cma ) ;
	s = addTallPattern( s, start, &header, 'b', 7,	cmb ) ;
	s = addTallPattern( s, start, &header, 'c', 7,	cmc ) ;
	s = addTallPattern( s, start, &header, 'd', 7,	cmd ) ;
	s = addTallPattern( s, start, &header, 'e', 7,	cme ) ;
	s = addTallPattern( s, start, &header, 'f', 7,	cmf ) ;
	s = addTallPattern( s, start, &header, 'g', 7,	cmg ) ;
	s = addTallPattern( s, start, &header, 'h', 7,	cmh ) ;
	s = addTallPattern( s, start, &header, 'i', 5,	cmi ) ;
	s = addTallPattern( s, start, &header, 'j', 5,	cmj ) ;
	s = addTallPattern( s, start, &header, 'k', 7,	cmk ) ;
	s = addTallPattern( s, start, &header, 'l', 5,	cml ) ;
	s = addTallPattern( s, start, &header, 'm', 9,	cmm ) ;
	s = addTallPattern( s, start, &header, 'n', 7,	cmn ) ;
	s = addTallPattern( s, start, &header, 'o', 7,	cmo ) ;
	s = addTallPattern( s, start, &header, 'p', 7,	cmp ) ;
	s = addTallPattern( s, start, &header, 'q', 7,	cmq ) ;
	s = addTallPattern( s, start, &header, 'r', 7,	cmr ) ;
	s = addTallPattern( s, start, &header, 's', 7,	cms ) ;
	s = addTallPattern( s, start, &header, 't', 7,	cmt ) ;
	s = addTallPattern( s, start, &header, 'u', 7,	cmu ) ;
	s = addTallPattern( s, start, &header, 'v', 7,	cmv ) ;
	s = addTallPattern( s, start, &header, 'w', 9,	cmw ) ;
	s = addTallPattern( s, start, &header, 'x', 7,	cmx ) ;
	s = addTallPattern( s, start, &header, 'y', 7,	cmy ) ;
	s = addTallPattern( s, start, &header, 'z', 7,	cmz ) ;


	s = addFont( s, start, &header, '-', 7, 0x000, 0x000, 0x0c0, 0x0c0, 0x0c0, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '+', 7, 0x000, 0x000, 0x0c0, 0x3f0, 0x0c0, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '!', 5, 0x000, 0x000, 0xfcc, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '[', 5, 0x000, 0x000, 0xffc, 0xc0c, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ']', 5, 0x000, 0xc0c, 0xffc, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '|', 5, 0x000, 0x000, 0x1ffe, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '=', 7, 0x000, 0x000, 0x330, 0x330, 0x330, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '_', 7, 0x000, 0x00c, 0x00c, 0x00c, 0x00c, 0x00c, 0x000 ) ;
	s = addFont( s, start, &header, '.', 5, 0x000, 0x000, 0x00c, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ':', 5, 0x000, 0x000, 0x198, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '"', 7, 0x000, 0x000, 0xe00, 0x000, 0xe00, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '\'', 5, 0x000, 0x000, 0xe00, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '#', 7, 0x000, 0x330, 0xffc, 0x330, 0xffc, 0x330, 0x000 ) ;
	s = addFont( s, start, &header, '*', 7, 0x000, 0x000, 0x330, 0x0c0, 0x330, 0x000, 0x000 ) ;

	s = addGrayFont( s, start, &header, '/', 7, "000000000000", "0000004cff00", "00000afc6000", "000cffc00000", "06cfa0000000", "ffc400000000", "000000000000" ) ;	
	s = addGrayFont( s, start, &header, '\\', 7, "000000000000", "ffc400000000", "06cfa0000000", "000cffc00000", "00000afc6000", "0000004cff00", "000000000000" ) ;	
	s = addGrayFont( s, start, &header, '?', 7, "000000000000", "6cf000000000", "ff0000000000", "ff00ff00ff00", "ff00ff000000", "6cffc6000000", "000000000000" ) ;		
	s = addGrayFont( s, start, &header, '$', 7, "000000000000", "6cfff000ff00", "ff00ff00ff00", "ccffffffcc00", "ff00ff00ff00", "ff000fffc600", "000000000000" ) ;	
	s = addGrayFont( s, start, &header, '&', 7, "000000000000", "00006cffc600", "0000ff00ff00", "6cffff000000", "ff00ffffc600", "6cfff000ff00", "000000000000" ) ;	
	
	s = addGrayFont( s, start, &header, '0', 7, "000000000000", "6cdeffedc600", "ce400004ec00", "ff00ff00ff00", "ce400004ec00", "6cdeffedc600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '1', 6, "000000000000", "000000000000", "4ff000000000", "ffffffffff00", "000000000000", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '2', 7, "000000000000", "4ef00fffff00", "ff00ff00ff00", "ff00ff00ff00", "ff00ff00ff00", "4effc600ff00", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '3', 7, "000000000000", "4ef0004cf000", "ff000000ff00", "ff00ff00ff00", "ff00ff00ff00", "4eff88ffe400", "000000000000" ) ;	
	s = addFont( s, start, &header, '4', 7, 0x000, 0xfe0, 0x060, 0x060, 0xffc, 0x060, 0x000 ) ;
	s = addGrayFont( s, start, &header, '5', 7, "000000000000", "ffffff00fc00", "ff00ff00ff00", "ff00ff00ff00", "ce40ff04ec00", "ff006dffd600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '6', 7, "000000000000", "4cffffffd600", "ce40ff04ec00", "ff00ff00ff00", "ce40ff04ec00", "00006dffd600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '7', 7, "000000000000", "ff00004cff00", "ff0004ffa000", "ff006ff80000", "ff08ff800000", "fffd60000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '8', 7, "000000000000", "6dfd44dfd600", "ce40ff04ec00", "ff00ff00ff00", "ce40ff04ec00", "6dfd44dfd600", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '9', 7, "000000000000", "6dffd6000000", "ce40ff04ec00", "ff00ff00ff00", "ce40ff04ec00", "6dffffffc400", "000000000000" ) ;	
	s = addGrayFont( s, start, &header, '(', 6, "000000000000", "000000000000", "0adffffda000", "ce600006ec00", "000000000000", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, ')', 6, "000000000000", "000000000000", "ce600006ec00", "0adffffda000", "000000000000", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '{', 6, "000000000000", "000000000000", "0000ff000000", "08deffed8000", "ce600006ec00", "000000000000", "000000000000" ) ;
	s = addGrayFont( s, start, &header, '}', 6, "000000000000", "000000000000", "ce600006ec00", "08deffed8000", "0000ff000000", "000000000000", "000000000000" ) ;
	s = addFont( s, start, &header, ',', 6, 0x000, 0x000, 0x01e, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ';', 6, 0x000, 0x000, 0x19e, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addGrayFont( s, start, &header, '@', 7, "000000000000", "6cdeffedc600", "ff000000ff00", "ff00ff00ff00", "ff00ff00ff00", "6cddc6000000", "000000000000" ) ;
	
	s = addGrayFont( s, start, &header, '%', 7, "000000000000", "0000004cff00", "0ff00afc6000", "000cffc00000", "06cfa00ff000", "ffc400000000", "000000000000" ) ;	
	s = addFont( s, start, &header, '^', 7, 0x000, 0x300, 0x600, 0xc00, 0x600, 0x300, 0x000 ) ;
	s = addFont( s, start, &header, '~', 7, 0x000, 0x0c0, 0x180, 0x0c0, 0x060, 0x0c0, 0x000 ) ;
	s = addFont( s, start, &header, '`', 5, 0x000, 0x000, 0xc00, 0x600, 0x000, 0x000, 0x000 ) ;
	
	s = addFont( s, start, &header, '<', 6, 0x000, 0x0c0, 0x330, 0x618, 0xc0c, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '>', 6, 0x000, 0xc0c, 0x618, 0x330, 0x0c0, 0x000, 0x000 ) ;
	
	header.size = s - start ;
	header.fontData = 0 ;

	f = fopen( "cm bitmap aa.font", "wb" ) ;
	fwrite( &header, sizeof( HellschreiberFontHeader ), 1, f ) ;
	fwrite( start, s-start, 1, f ) ;
	fclose( f ) ;
	free( start ) ;
}

void cmbitmap()
{
	unsigned char *s, *start ;
	HellschreiberFontHeader header ;
	int i ;
	FILE *f ;
	
	start = ( unsigned char* )malloc( 65536*sizeof( unsigned char ) ) ;
	
	//  anti-alised version
	header.version = 0 ;
	strcpy( header.name, "cm bitmap aa" ) ;
	for ( i = 0; i < 128; i++ ) header.index[i] = 0 ; // point to space character

	s = start ;
	//  bilevel bitmap version
	
	header.version = 0 ;
	strcpy( header.name, "cm bitmap" ) ;
	for ( i = 0; i < 128; i++ ) header.index[i] = 0 ; // point to space character

	s = start ;
	//  space character
	s = addTallBilevelPattern( s, start, &header, ' ', 6,	cmspace ) ;
	
	s = addFont( s, start, &header, 'A', 7, 0x000, 0x7fc, 0xc60, 0xc60, 0xc60, 0x7fc, 0x000 ) ;
	s = addFont( s, start, &header, 'B', 7, 0x000, 0xffc, 0xccc, 0xccc, 0xccc, 0x738, 0x000 ) ;
	s = addFont( s, start, &header, 'C', 7, 0x000, 0x7f8, 0xc0c, 0xc0c, 0xc0c, 0xc0c, 0x000 ) ;
	s = addFont( s, start, &header, 'D', 7, 0x000, 0xffc, 0xc0c, 0xc0c, 0xc0c, 0x7f8, 0x000 ) ;
	s = addFont( s, start, &header, 'E', 6, 0x000, 0xffc, 0xccc, 0xccc, 0xc0c, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, 'F', 6, 0x000, 0xffc, 0xcc0, 0xcc0, 0xc00, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, 'G', 7, 0x000, 0x7f8, 0xc0c, 0xc0c, 0xccc, 0x0f8, 0x000 ) ;
	s = addFont( s, start, &header, 'H', 7, 0x000, 0xffc, 0x0c0, 0x0c0, 0x0c0, 0xffc, 0x000 ) ;
	s = addFont( s, start, &header, 'I', 5, 0x000, 0x000, 0xffc, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, 'J', 7, 0x000, 0x038, 0x00c, 0x00c, 0x00c, 0xff8, 0x000 ) ;
	s = addFont( s, start, &header, 'K', 7, 0x000, 0xffc, 0x0c0, 0x1e0, 0x738, 0xc0c, 0x000 ) ;
	s = addFont( s, start, &header, 'L', 6, 0x000, 0xffc, 0x00c, 0x00c, 0x00c, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, 'N', 7, 0x000, 0x7fc, 0xc00, 0xc00, 0xc00, 0x7fc, 0x000 ) ;
	s = addFont( s, start, &header, 'O', 7, 0x000, 0x7f8, 0xc0c, 0xc0c, 0xc0c, 0x7f8, 0x000 ) ;
	s = addFont( s, start, &header, 'P', 7, 0x000, 0xffc, 0xc60, 0xc60, 0xc60, 0x7c0, 0x000 ) ;
	s = addFont( s, start, &header, 'Q', 7, 0x000, 0x7f8, 0xc0c, 0xc1c, 0xc0e, 0x7f3, 0x000 ) ;
	s = addFont( s, start, &header, 'R', 7, 0x000, 0xffc, 0xc60, 0xc60, 0xc78, 0x7cc, 0x000 ) ;
	s = addFont( s, start, &header, 'S', 7, 0x000, 0x798, 0xccc, 0xccc, 0xccc, 0x678, 0x000 ) ;
	s = addFont( s, start, &header, 'T', 7, 0x000, 0xc00, 0xc00, 0xffc, 0xc00, 0xc00, 0x000 ) ;
	s = addFont( s, start, &header, 'U', 7, 0x000, 0xff8, 0x00c, 0x00c, 0x00c, 0xff8, 0x000 ) ;
	s = addFont( s, start, &header, 'V', 7, 0x000, 0xff8, 0x00c, 0x038, 0x0e0, 0xf80, 0x000 ) ;
	s = addFont( s, start, &header, 'X', 7, 0x000, 0xe1c, 0x330, 0x1e0, 0x330, 0xe1c, 0x000 ) ;
	s = addFont( s, start, &header, 'Y', 7, 0x000, 0xf00, 0x1c0, 0x07c, 0x1c0, 0xf00, 0x000 ) ;
	s = addFont( s, start, &header, 'Z', 7, 0x000, 0xc0c, 0xc3c, 0xccc, 0xf0c, 0xc0c, 0x000 ) ;

	s = addWideFont( s, start, &header, 'M', 9, 0x000, 0x7fc, 0xc00, 0xc00, 0x7fc, 0xc00, 0xc00, 0x7fc, 0x000 ) ;
	s = addWideFont( s, start, &header, 'W', 9, 0x000, 0xff8, 0x00c, 0x00c, 0xff8, 0x00c, 0x00c, 0xff8, 0x000 ) ;
	
	for ( i = 'a'; i <= 'z'; i++ ) header.index[i] = header.index[i-'a'+'A'] ;
	
	/* lower case */
	s = addTallBilevelPattern( s, start, &header, 'a', 8,	cma ) ;
	s = addTallBilevelPattern( s, start, &header, 'b', 7,	cmb ) ;
	s = addTallBilevelPattern( s, start, &header, 'c', 7,	cmc ) ;
	s = addTallBilevelPattern( s, start, &header, 'd', 7,	cmd ) ;
	s = addTallBilevelPattern( s, start, &header, 'e', 7,	cme ) ;
	s = addTallBilevelPattern( s, start, &header, 'f', 7,	cmf ) ;
	s = addTallBilevelPattern( s, start, &header, 'g', 7,	cmg ) ;
	s = addTallBilevelPattern( s, start, &header, 'h', 7,	cmh ) ;
	s = addTallBilevelPattern( s, start, &header, 'i', 5,	cmi ) ;
	s = addTallBilevelPattern( s, start, &header, 'j', 5,	cmj ) ;
	s = addTallBilevelPattern( s, start, &header, 'k', 7,	cmk ) ;
	s = addTallBilevelPattern( s, start, &header, 'l', 5,	cml ) ;
	s = addTallBilevelPattern( s, start, &header, 'm', 9,	cmm ) ;
	s = addTallBilevelPattern( s, start, &header, 'n', 7,	cmn ) ;
	s = addTallBilevelPattern( s, start, &header, 'o', 7,	cmo ) ;
	s = addTallBilevelPattern( s, start, &header, 'p', 7,	cmp ) ;
	s = addTallBilevelPattern( s, start, &header, 'q', 7,	cmq ) ;
	s = addTallBilevelPattern( s, start, &header, 'r', 7,	cmr ) ;
	s = addTallBilevelPattern( s, start, &header, 's', 7,	cms ) ;
	s = addTallBilevelPattern( s, start, &header, 't', 7,	cmt ) ;
	s = addTallBilevelPattern( s, start, &header, 'u', 7,	cmu ) ;
	s = addTallBilevelPattern( s, start, &header, 'v', 7,	cmv ) ;
	s = addTallBilevelPattern( s, start, &header, 'w', 9,	cmw ) ;
	s = addTallBilevelPattern( s, start, &header, 'x', 7,	cmx ) ;
	s = addTallBilevelPattern( s, start, &header, 'y', 7,	cmy ) ;
	s = addTallBilevelPattern( s, start, &header, 'z', 7,	cmz ) ;

	s = addFont( s, start, &header, '-', 7, 0x000, 0x000, 0x0c0, 0x0c0, 0x0c0, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '/', 7, 0x000, 0x01c, 0x070, 0x0c0, 0x380, 0xe00, 0x000 ) ;
	s = addFont( s, start, &header, '?', 7, 0x000, 0x600, 0xc00, 0xccc, 0xcc0, 0x780, 0x000 ) ;
	s = addFont( s, start, &header, '$', 7, 0x000, 0x78c, 0xccc, 0xffc, 0xccc, 0xc78, 0x000 ) ;
	s = addFont( s, start, &header, '!', 5, 0x000, 0x000, 0xfcc, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '&', 7, 0x000, 0x078, 0x0cc, 0x7c0, 0xcf0, 0x78c, 0x000 ) ;
	s = addFont( s, start, &header, '*', 7, 0x000, 0x000, 0x330, 0x0c0, 0x330, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '0', 7, 0x000, 0x7f8, 0xc0c, 0xccc, 0xc0c, 0x7f8, 0x000 ) ;
	s = addFont( s, start, &header, '1', 6, 0x000, 0x000, 0x600, 0xffc, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '2', 7, 0x000, 0x67c, 0xccc, 0xccc, 0xccc, 0x78c, 0x000 ) ;
	s = addFont( s, start, &header, '3', 7, 0x000, 0x618, 0xc0c, 0xccc, 0xccc, 0x738, 0x000 ) ;
	s = addFont( s, start, &header, '4', 7, 0x000, 0xfe0, 0x060, 0x060, 0xffc, 0x060, 0x000 ) ;
	s = addFont( s, start, &header, '5', 7, 0x000, 0xfcc, 0xccc, 0xccc, 0xccc, 0xc78, 0x000 ) ;
	s = addFont( s, start, &header, '6', 7, 0x000, 0x7f8, 0xccc, 0xccc, 0xccc, 0x078, 0x000 ) ;
	s = addFont( s, start, &header, '7', 7, 0x000, 0xc1c, 0xc30, 0xc60, 0xcc0, 0xf80, 0x000 ) ;
	s = addFont( s, start, &header, '8', 7, 0x000, 0x738, 0xccc, 0xccc, 0xccc, 0x738, 0x000 ) ;
	s = addFont( s, start, &header, '9', 7, 0x000, 0x780, 0xccc, 0xccc, 0xccc, 0x7f8, 0x000 ) ;

	s = addFont( s, start, &header, '\'', 5, 0x000, 0x000, 0xe00, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '\\', 7, 0x000, 0xe00, 0x380, 0x0c0, 0x070, 0x01c, 0x000 ) ;

	s = addFont( s, start, &header, '+', 7, 0x000, 0x000, 0x0c0, 0x3f0, 0x0c0, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '(', 6, 0x000, 0x000, 0x7f8, 0xc0c, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ')', 6, 0x000, 0x000, 0xc0c, 0x7f8, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '.', 5, 0x000, 0x000, 0x00c, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ',', 6, 0x000, 0x000, 0x01e, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ';', 6, 0x000, 0x000, 0x19e, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ':', 5, 0x000, 0x000, 0x198, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '"', 7, 0x000, 0x000, 0xe00, 0x000, 0xe00, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '@', 7, 0x000, 0x7f8, 0xc0c, 0xccc, 0xccc, 0x780, 0x000 ) ;
	s = addFont( s, start, &header, '#', 7, 0x000, 0x330, 0xffc, 0x330, 0xffc, 0x330, 0x000 ) ;
	s = addFont( s, start, &header, '%', 7, 0x000, 0x01c, 0x670, 0x0c0, 0x398, 0xe00, 0x000 ) ;
	s = addFont( s, start, &header, '^', 7, 0x000, 0x300, 0x600, 0xc00, 0x600, 0x300, 0x000 ) ;
	s = addFont( s, start, &header, '=', 7, 0x000, 0x000, 0x330, 0x330, 0x330, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '_', 7, 0x000, 0x00c, 0x00c, 0x00c, 0x00c, 0x00c, 0x000 ) ;
	s = addFont( s, start, &header, '[', 5, 0x000, 0x000, 0xffc, 0xc0c, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, ']', 5, 0x000, 0xc0c, 0xffc, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '{', 6, 0x000, 0x000, 0x0c0, 0x7f8, 0xc0c, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '}', 6, 0x000, 0x000, 0xc0c, 0x7f8, 0x0c0, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '|', 5, 0x000, 0x000, 0x1ffe, 0x000, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '~', 7, 0x000, 0x0c0, 0x180, 0x0c0, 0x060, 0x0c0, 0x000 ) ;
	s = addFont( s, start, &header, '`', 5, 0x000, 0x000, 0xc00, 0x600, 0x000, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '<', 6, 0x000, 0x0c0, 0x330, 0x618, 0xc0c, 0x000, 0x000 ) ;
	s = addFont( s, start, &header, '>', 6, 0x000, 0xc0c, 0x618, 0x330, 0x0c0, 0x000, 0x000 ) ;
	
	header.size = s - start ;
	header.fontData = 0 ;

	f = fopen( "cm bitmap.font", "wb" ) ;
	fwrite( &header, sizeof( HellschreiberFontHeader ), 1, f ) ;
	fwrite( start, s-start, 1, f ) ;
	fclose( f ) ;
	free( start ) ;
}
