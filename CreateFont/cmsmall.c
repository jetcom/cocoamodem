/*
 *  cmsmall.c
 *  CreateFont
 *
 *  Created by Kok Chen on 4/17/06.
 */

#include "cmsmall.h"
#include "HellschreiberFont.h"
#include "utils.h"
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "cmsmall_def.h"

void cmsmall()
{
	unsigned char *s, *start ;
	HellschreiberFontHeader header ;
	int i ;
	FILE *f ;

	start = ( unsigned char* )malloc( 65536*sizeof( unsigned char ) ) ;
	
	//  bilevel pixel aligned bitmap version
	
	header.version = 0 | STEMALIGNED ;
	strcpy( header.name, "cm small" ) ;
	for ( i = 0; i < 128; i++ ) header.index[i] = 0 ; // point to space character

	s = start ;
	//  space character
	s = addBilevelPattern( s, start, &header, ' ', 6,	newspace ) ;
	s = addBilevelPattern( s, start, &header, 'A', 7,	newA ) ;
	s = addBilevelPattern( s, start, &header, 'B', 7,	newB ) ;
	s = addBilevelPattern( s, start, &header, 'C', 7,	newC ) ;
	s = addBilevelPattern( s, start, &header, 'D', 7,	newD ) ;
	s = addBilevelPattern( s, start, &header, 'E', 7,	newE ) ;
	s = addBilevelPattern( s, start, &header, 'F', 7,	newF ) ;
	s = addBilevelPattern( s, start, &header, 'G', 7,	newG ) ;
	s = addBilevelPattern( s, start, &header, 'H', 7,	newH ) ;
	s = addBilevelPattern( s, start, &header, 'I', 5,	newI ) ;
	s = addBilevelPattern( s, start, &header, 'J', 7,	newJ ) ;
	s = addBilevelPattern( s, start, &header, 'K', 7,	newK ) ;
	s = addBilevelPattern( s, start, &header, 'L', 7,	newL ) ;
	s = addBilevelPattern( s, start, &header, 'M', 9,	newM ) ;
	s = addBilevelPattern( s, start, &header, 'N', 7,	newN ) ;
	s = addBilevelPattern( s, start, &header, 'O', 7,	newO ) ;
	s = addBilevelPattern( s, start, &header, 'P', 7,	newP ) ;
	s = addBilevelPattern( s, start, &header, 'Q', 7,	newQ ) ;
	s = addBilevelPattern( s, start, &header, 'R', 7,	newR ) ;
	s = addBilevelPattern( s, start, &header, 'S', 7,	newS ) ;
	s = addBilevelPattern( s, start, &header, 'T', 7,	newT ) ;
	s = addBilevelPattern( s, start, &header, 'U', 7,	newU ) ;
	s = addBilevelPattern( s, start, &header, 'V', 7,	newV ) ;
	s = addBilevelPattern( s, start, &header, 'W', 9,	newW ) ;
	s = addBilevelPattern( s, start, &header, 'X', 7,	newX ) ;
	s = addBilevelPattern( s, start, &header, 'Y', 7,	newY ) ;
	s = addBilevelPattern( s, start, &header, 'Z', 7,	newZ ) ;
	
	//  copy upper ase into lower case to make sure we don;t miss an empty slot
	for ( i = 'a'; i <= 'z'; i++ ) header.index[i] = header.index[i-'a'+'A'] ;
	
	/* lower case */
	s = addBilevelPattern( s, start, &header, 'a', 8,	newa ) ;
	s = addBilevelPattern( s, start, &header, 'b', 7,	newb ) ;
	s = addBilevelPattern( s, start, &header, 'c', 7,	newc ) ;
	s = addBilevelPattern( s, start, &header, 'd', 7,	newd ) ;
	s = addBilevelPattern( s, start, &header, 'e', 7,	newe ) ;
	s = addBilevelPattern( s, start, &header, 'f', 7,	newf ) ;
	s = addBilevelPattern( s, start, &header, 'g', 7,	newg ) ;
	s = addBilevelPattern( s, start, &header, 'h', 7,	newh ) ;
	s = addBilevelPattern( s, start, &header, 'i', 5,	newi ) ;
	s = addBilevelPattern( s, start, &header, 'j', 5,	newj ) ;
	s = addBilevelPattern( s, start, &header, 'k', 7,	newk ) ;
	s = addBilevelPattern( s, start, &header, 'l', 5,	newl ) ;
	s = addBilevelPattern( s, start, &header, 'm', 9,	newm ) ;
	s = addBilevelPattern( s, start, &header, 'n', 7,	newn ) ;
	s = addBilevelPattern( s, start, &header, 'o', 7,	newo ) ;
	s = addBilevelPattern( s, start, &header, 'p', 7,	newp ) ;
	s = addBilevelPattern( s, start, &header, 'q', 7,	newq ) ;
	s = addBilevelPattern( s, start, &header, 'r', 7,	newr ) ;
	s = addBilevelPattern( s, start, &header, 's', 7,	news ) ;
	s = addBilevelPattern( s, start, &header, 't', 7,	newt ) ;
	s = addBilevelPattern( s, start, &header, 'u', 7,	newu ) ;
	s = addBilevelPattern( s, start, &header, 'v', 7,	newv ) ;
	s = addBilevelPattern( s, start, &header, 'w', 9,	neww ) ;
	s = addBilevelPattern( s, start, &header, 'x', 7,	newx ) ;
	s = addBilevelPattern( s, start, &header, 'y', 7,	newy ) ;
	s = addBilevelPattern( s, start, &header, 'z', 7,	newz ) ;
	
	s = addBilevelPattern( s, start, &header, '0', 7,	new0 ) ;
	s = addBilevelPattern( s, start, &header, '1', 5,	new1 ) ;
	s = addBilevelPattern( s, start, &header, '2', 7,	new2 ) ;
	s = addBilevelPattern( s, start, &header, '3', 7,	new3 ) ;
	s = addBilevelPattern( s, start, &header, '4', 8,	new4 ) ;
	s = addBilevelPattern( s, start, &header, '5', 7,	new5 ) ;
	s = addBilevelPattern( s, start, &header, '6', 7,	new6 ) ;
	s = addBilevelPattern( s, start, &header, '7', 7,	new7 ) ;
	s = addBilevelPattern( s, start, &header, '8', 7,	new8 ) ;
	s = addBilevelPattern( s, start, &header, '9', 7,	new9 ) ;
	
	s = addBilevelPattern( s, start, &header, '+', 7,	newplus ) ;
	s = addBilevelPattern( s, start, &header, '-', 7,	newminus ) ;
	s = addBilevelPattern( s, start, &header, '!', 5,	newbang ) ;
	s = addBilevelPattern( s, start, &header, '<', 6,	newless ) ;
	s = addBilevelPattern( s, start, &header, '>', 6,	newgreater ) ;
	s = addBilevelPattern( s, start, &header, '[', 6,	newlbrack ) ;
	s = addBilevelPattern( s, start, &header, ']', 6,	newrbrack ) ;
	s = addBilevelPattern( s, start, &header, '|', 5,	newbar ) ;
	s = addBilevelPattern( s, start, &header, '=', 7,	newequal ) ;
	s = addBilevelPattern( s, start, &header, '_', 7,	newunderscore ) ;
	s = addBilevelPattern( s, start, &header, '.', 5,	newperiod ) ;
	s = addBilevelPattern( s, start, &header, ':', 5,	newcolon ) ;
	s = addBilevelPattern( s, start, &header, ',', 6,	newsemicolon ) ;
	s = addBilevelPattern( s, start, &header, ',', 6,	newcomma ) ;
	s = addBilevelPattern( s, start, &header, '\'', 5,	newquote ) ;
	s = addBilevelPattern( s, start, &header, '"', 7,	newdquote ) ;
	s = addBilevelPattern( s, start, &header, '#', 7,	newpound ) ;
	s = addBilevelPattern( s, start, &header, '*', 7,	newstar ) ;
	s = addBilevelPattern( s, start, &header, '?', 7,	newquestion ) ;
	s = addBilevelPattern( s, start, &header, '&', 7,	newampersand ) ;
	s = addBilevelPattern( s, start, &header, '$', 7,	newdollar ) ;
	s = addBilevelPattern( s, start, &header, '/', 7,	newslash ) ;
	s = addBilevelPattern( s, start, &header, '%', 7,	newpercent ) ;
	s = addBilevelPattern( s, start, &header, '\\', 7,	newbackslash ) ;	
	s = addBilevelPattern( s, start, &header, '(', 6,	newlparen ) ;
	s = addBilevelPattern( s, start, &header, ')', 6,	newrparen ) ;
	s = addBilevelPattern( s, start, &header, '{', 6,	newlbrace ) ;
	s = addBilevelPattern( s, start, &header, '}', 6,	newrbrace ) ;
	s = addBilevelPattern( s, start, &header, '@', 8,	newat ) ;
	s = addBilevelPattern( s, start, &header, '`', 5,	newtilde ) ;
	s = addBilevelPattern( s, start, &header, '^', 7,	newhat ) ;
	s = addBilevelPattern( s, start, &header, '~', 7,	newsquiggle ) ;
	
	header.size = s - start ;
	header.fontData = 0 ;

	f = fopen( "cm small.font", "wb" ) ;
	fwrite( &header, sizeof( HellschreiberFontHeader ), 1, f ) ;
	fwrite( start, s-start, 1, f ) ;
	fclose( f ) ;
	free( start ) ;
}

void cmsmallaa()
{
	unsigned char *s, *start ;
	HellschreiberFontHeader header ;
	int i ;
	FILE *f ;
	
	start = ( unsigned char* )malloc( 65536*sizeof( unsigned char ) ) ;
	
	//  pixel aligned anti-aliased bitmap version
	
	header.version = 0 | STEMALIGNED ;
	strcpy( header.name, "cm small aa" ) ;
	for ( i = 0; i < 128; i++ ) header.index[i] = 0 ; // point to space character

	s = start ;
	//  space character
	s = addPattern( s, start, &header, ' ', 6, newspace ) ;
	s = addPattern( s, start, &header, 'A', 7,	newA ) ;
	s = addPattern( s, start, &header, 'B', 7,	newB ) ;
	s = addPattern( s, start, &header, 'C', 7,	newC ) ;
	s = addPattern( s, start, &header, 'D', 7,	newD ) ;
	s = addPattern( s, start, &header, 'E', 7,	newE ) ;
	s = addPattern( s, start, &header, 'F', 7,	newF ) ;
	s = addPattern( s, start, &header, 'G', 7,	newG ) ;
	s = addPattern( s, start, &header, 'H', 7,	newH ) ;
	s = addPattern( s, start, &header, 'I', 5,	newI ) ;
	s = addPattern( s, start, &header, 'J', 7,	newJ ) ;
	s = addPattern( s, start, &header, 'K', 7,	newK ) ;
	s = addPattern( s, start, &header, 'L', 7,	newL ) ;
	s = addPattern( s, start, &header, 'M', 9,	newM ) ;
	s = addPattern( s, start, &header, 'N', 7,	newN ) ;
	s = addPattern( s, start, &header, 'O', 7,	newO ) ;
	s = addPattern( s, start, &header, 'P', 7,	newP ) ;
	s = addPattern( s, start, &header, 'Q', 7,	newQ ) ;
	s = addPattern( s, start, &header, 'R', 7,	newR ) ;
	s = addPattern( s, start, &header, 'S', 7,	newS ) ;
	s = addPattern( s, start, &header, 'T', 7,	newT ) ;
	s = addPattern( s, start, &header, 'U', 7,	newU ) ;
	s = addPattern( s, start, &header, 'V', 7,	newV ) ;
	s = addPattern( s, start, &header, 'W', 9,	newW ) ;
	s = addPattern( s, start, &header, 'X', 7,	newX ) ;
	s = addPattern( s, start, &header, 'Y', 7,	newY ) ;
	s = addPattern( s, start, &header, 'Z', 7,	newZ ) ;

	//  copy upper ase into lower case to make sure we don;t miss an empty slot
	for ( i = 'a'; i <= 'z'; i++ ) header.index[i] = header.index[i-'a'+'A'] ;
	
	/* lower case */
	s = addPattern( s, start, &header, 'a', 8,	newa ) ;
	s = addPattern( s, start, &header, 'b', 7,	newb ) ;
	s = addPattern( s, start, &header, 'c', 7,	newc ) ;
	s = addPattern( s, start, &header, 'd', 7,	newd ) ;
	s = addPattern( s, start, &header, 'e', 7,	newe ) ;
	s = addPattern( s, start, &header, 'f', 7,	newf ) ;
	s = addPattern( s, start, &header, 'g', 7,	newg ) ;
	s = addPattern( s, start, &header, 'h', 7,	newh ) ;
	s = addPattern( s, start, &header, 'i', 5,	newi ) ;
	s = addPattern( s, start, &header, 'j', 5,	newj ) ;
	s = addPattern( s, start, &header, 'k', 7,	newk ) ;
	s = addPattern( s, start, &header, 'l', 5,	newl ) ;
	s = addPattern( s, start, &header, 'm', 9,	newm ) ;
	s = addPattern( s, start, &header, 'n', 7,	newn ) ;
	s = addPattern( s, start, &header, 'o', 7,	newo ) ;
	s = addPattern( s, start, &header, 'p', 7,	newp ) ;
	s = addPattern( s, start, &header, 'q', 7,	newq ) ;
	s = addPattern( s, start, &header, 'r', 7,	newr ) ;
	s = addPattern( s, start, &header, 's', 7,	news ) ;
	s = addPattern( s, start, &header, 't', 7,	newt ) ;
	s = addPattern( s, start, &header, 'u', 7,	newu ) ;
	s = addPattern( s, start, &header, 'v', 7,	newv ) ;
	s = addPattern( s, start, &header, 'w', 9,	neww ) ;
	s = addPattern( s, start, &header, 'x', 7,	newx ) ;
	s = addPattern( s, start, &header, 'y', 7,	newy ) ;
	s = addPattern( s, start, &header, 'z', 7,	newz ) ;
	
	s = addPattern( s, start, &header, '0', 7,	new0 ) ;
	s = addPattern( s, start, &header, '1', 5,	new1 ) ;
	s = addPattern( s, start, &header, '2', 7,	new2 ) ;
	s = addPattern( s, start, &header, '3', 7,	new3 ) ;
	s = addPattern( s, start, &header, '4', 8,	new4 ) ;
	s = addPattern( s, start, &header, '5', 7,	new5 ) ;
	s = addPattern( s, start, &header, '6', 7,	new6 ) ;
	s = addPattern( s, start, &header, '7', 7,	new7 ) ;
	s = addPattern( s, start, &header, '8', 7,	new8 ) ;
	s = addPattern( s, start, &header, '9', 7,	new9 ) ;
	
	s = addPattern( s, start, &header, '+', 7,	newplus ) ;
	s = addPattern( s, start, &header, '-', 7,	newminus ) ;
	s = addPattern( s, start, &header, '!', 5,	newbang ) ;
	s = addPattern( s, start, &header, '<', 6,	newless ) ;
	s = addPattern( s, start, &header, '>', 6,	newgreater ) ;
	s = addPattern( s, start, &header, '[', 6,	newlbrack ) ;
	s = addPattern( s, start, &header, ']', 6,	newrbrack ) ;
	s = addPattern( s, start, &header, '|', 5,	newbar ) ;
	s = addPattern( s, start, &header, '=', 7,	newequal ) ;
	s = addPattern( s, start, &header, '_', 7,	newunderscore ) ;
	s = addPattern( s, start, &header, '.', 5,	newperiod ) ;
	s = addPattern( s, start, &header, ':', 5,	newcolon ) ;
	s = addPattern( s, start, &header, ',', 6,	newsemicolon ) ;
	s = addPattern( s, start, &header, ',', 6,	newcomma ) ;
	s = addPattern( s, start, &header, '\'', 5,	newquote ) ;
	s = addPattern( s, start, &header, '"', 7,	newdquote ) ;
	s = addPattern( s, start, &header, '#', 7,	newpound ) ;
	s = addPattern( s, start, &header, '*', 7,	newstar ) ;
	s = addPattern( s, start, &header, '?', 7,	newquestion ) ;
	s = addPattern( s, start, &header, '&', 7,	newampersand ) ;
	s = addPattern( s, start, &header, '$', 7,	newdollar ) ;
	s = addPattern( s, start, &header, '/', 7,	newslash ) ;
	s = addPattern( s, start, &header, '%', 7,	newpercent ) ;
	s = addPattern( s, start, &header, '\\', 7,	newbackslash ) ;	
	s = addPattern( s, start, &header, '(', 6,	newlparen ) ;
	s = addPattern( s, start, &header, ')', 6,	newrparen ) ;
	s = addPattern( s, start, &header, '{', 6,	newlbrace ) ;
	s = addPattern( s, start, &header, '}', 6,	newrbrace ) ;
	s = addPattern( s, start, &header, '@', 8,	newat ) ;
	s = addPattern( s, start, &header, '`', 5,	newtilde ) ;
	s = addPattern( s, start, &header, '^', 7,	newhat ) ;
	s = addPattern( s, start, &header, '~', 7,	newsquiggle ) ;
	
	header.size = s - start ;
	header.fontData = 0 ;

	f = fopen( "cm small aa.font", "wb" ) ;
	fwrite( &header, sizeof( HellschreiberFontHeader ), 1, f ) ;
	fwrite( start, s-start, 1, f ) ;
	fclose( f ) ;
	free( start ) ;
}
