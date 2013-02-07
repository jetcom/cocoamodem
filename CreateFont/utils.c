/*
 *  utils.c
 *  CreateFont
 *
 *  Created by Kok Chen on 4/17/06.
 */

#include "utils.h"
#include <string.h>
#include <stdio.h>

static unsigned char *expandBitToByte( unsigned char *s, int col )
{
	int i ;
	unsigned char pat[2] = { 0, 255 } ;
	
	for ( i = 0; i < 14; i++ ) {
		*s++ = pat[ ( col & 0x1 ) ] ;
		col >>= 1 ;
	}
	for ( ; i < 16; i++ ) *s++ = 0 ;
	return s ;
}

static unsigned char hex2gray( int h )
{
	h &= 0xff ;
	if ( h >= '0' && h <= '9' ) return ( ( h-'0')*255 )/15 ;
	else {
		if ( h >= 'a' && h <= 'f' ) return ( ( h - 'a' + 10 )*255 )/15 ;
		else {
			printf( "bad hex %c\n", h ) ;
			return 0 ;
		}
	}
}

static unsigned char *expandStringToByte( unsigned char *s, char *col )
{
	int i, j, height ;
	
	height = strlen( col ) ;
	
	for ( i = 0; i < 14; i++ ) {
		j = height-1-i ;
		if ( j < 0 ) *s++ = 0 ;
		else {
			*s++ = hex2gray( col[j] ) ;
		}
	}
	for ( ; i < 16; i++ ) *s++ = 0 ;
	return s ;
}

unsigned char *addFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, int col1, int col2, int col3, int col4, int col5, int col6, int col7 )
{

	h->index[ascii&0x1ff] = s-start ;

	*s++ = ascii ;
	*s++ = width-1 ;
	s = expandBitToByte( s, col1 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col2 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col3 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col4 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col5 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col6 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col7 ) ;
	return s ;
}

unsigned char *addGrayFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char* col1, char* col2, char* col3, char* col4, char* col5, char* col6, char* col7 )
{

	h->index[ascii&0x1ff] = s-start ;

	*s++ = ascii ;
	*s++ = width-1 ;
	s = expandStringToByte( s, col1 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col2 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col3 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col4 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col5 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col6 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col7 ) ;
	return s ;
}

unsigned char *addWideFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, int col1, int col2, int col3, int col4, int col5, int col6, int col7, int col8, int col9 )
{
	h->index[ascii&0x1ff] = s-start ;

	*s++ = ascii ;
	*s++ = width-1 ;
	s = expandBitToByte( s, col1 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col2 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col3 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col4 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col5 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col6 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col7 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col8 ) ;
	if ( --width <= 0 ) return s ;
	s = expandBitToByte( s, col9 ) ;
	return s ;
}

unsigned char *addWideGrayFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char* col1, char* col2, char* col3, char* col4, char* col5, char* col6, char* col7, char* col8, char* col9 )
{

	h->index[ascii&0x1ff] = s-start ;

	*s++ = ascii ;
	*s++ = width-1 ;
	s = expandStringToByte( s, col1 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col2 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col3 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col4 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col5 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col6 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col7 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col8 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col9 ) ;
	return s ;
}

static unsigned char *addWiderGrayFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char* col1, char* col2, char* col3, char* col4, char* col5, char* col6, char* col7, char* col8, char* col9, char* col10, char* col11, char* col12, char* col13, char* col14, char* col15, char* col16, char* col17, char* col18 )
{

	h->index[ascii&0x1ff] = s-start ;

	*s++ = ascii ;
	*s++ = width-1 ;
	s = expandStringToByte( s, col1 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col2 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col3 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col4 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col5 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col6 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col7 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col8 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col9 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col10 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col11 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col12 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col13 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col14 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col15 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col16 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col17 ) ;
	if ( --width <= 0 ) return s ;
	s = expandStringToByte( s, col18 ) ;
	return s ;
}

static int grayCode( int v ) 
{
	v &= 0x7f ;
	
	if ( v == ' ' || v == '.' ) return '0' ;
	if ( v == 'O' ) return 'f' ;
	if ( v == '*' ) return 'b' ;
	if ( v == 'o' ) return '9' ;
	if ( v == '+' ) return '6' ;
	return 'f' ;
}

static int bilevelCode( int v ) 
{
	v &= 0x7f ;
	
	if ( v == ' ' || v == '.' ) return '0' ;
	if ( v == 'O' ) return 'f' ;
	if ( v == '*' ) return 'f' ;
	if ( v == 'o' ) return 'f' ;
	if ( v == '+' ) return '0' ;
	return 'f' ;
}

unsigned char *addPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s )
{
	char r[18][13], *t ;
	int i, j, v ;
	
	for ( i = 0; i < 18; i++ ) r[i][12] = 0 ; 
	
	for ( j = 0; j < 18; j++ ) {
		for ( i = 0; i < 6; i++ ) {
			t = s[i] ;
			v = grayCode( t[j] ) ; 
			r[j][i*2] = r[j][i*2+1] = v ;
		}
	}
	//  output the columns
	return addWiderGrayFont( p, start, h,  ascii, width, &r[0][0], &r[1][0], &r[2][0], &r[3][0], &r[4][0], &r[5][0], &r[6][0], &r[7][0], &r[8][0], &r[9][0], &r[10][0], &r[11][0], &r[12][0], &r[13][0], &r[14][0], &r[15][0], &r[16][0], &r[17][0] ) ;
}

unsigned char *addBilevelPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s )
{
	char r[18][13], *t ;
	int i, j, v ;

	for ( i = 0; i < 18; i++ ) r[i][12] = 0 ; 
	
	for ( j = 0; j < 18; j++ ) {
		for ( i = 0; i < 6; i++ ) {
			t = s[i] ;
			v = bilevelCode( t[j] ) ; 
			r[j][i*2] = r[j][i*2+1] = v ;
		}
	}
	//  output the columns
	return addWiderGrayFont( p, start, h,  ascii, width, &r[0][0], &r[1][0], &r[2][0], &r[3][0], &r[4][0], &r[5][0], &r[6][0], &r[7][0], &r[8][0], &r[9][0], &r[10][0], &r[11][0], &r[12][0], &r[13][0], &r[14][0], &r[15][0], &r[16][0], &r[17][0] ) ;
}


unsigned char *addTallPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s )
{
	char r[18][13], *t ;
	int i, j, v ;
	
	for ( i = 0; i < 18; i++ ) r[i][12] = 0 ; 
	
	for ( j = 0; j < 18; j++ ) {
		for ( i = 0; i < 12; i++ ) {
			t = s[i] ;
			v = grayCode( t[j] ) ; 
			r[j][i] = v ;
		}
	}
	//  output the columns
	return addWiderGrayFont( p, start, h,  ascii, width, &r[0][0], &r[1][0], &r[2][0], &r[3][0], &r[4][0], &r[5][0], &r[6][0], &r[7][0], &r[8][0], &r[9][0], &r[10][0], &r[11][0], &r[12][0], &r[13][0], &r[14][0], &r[15][0], &r[16][0], &r[17][0] ) ;
}

unsigned char *addTallBilevelPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s )
{
	char r[18][13], *t ;
	int i, j, v ;

	for ( i = 0; i < 18; i++ ) r[i][12] = 0 ; 
	
	for ( j = 0; j < 18; j++ ) {
		for ( i = 0; i < 12; i++ ) {
			t = s[i] ;
			v = bilevelCode( t[j] ) ; 
			r[j][i] = v ;
		}
	}
	//  output the columns
	return addWiderGrayFont( p, start, h,  ascii, width, &r[0][0], &r[1][0], &r[2][0], &r[3][0], &r[4][0], &r[5][0], &r[6][0], &r[7][0], &r[8][0], &r[9][0], &r[10][0], &r[11][0], &r[12][0], &r[13][0], &r[14][0], &r[15][0], &r[16][0], &r[17][0] ) ;
}


