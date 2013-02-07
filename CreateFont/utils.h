/*
 *  utils.h
 *  CreateFont
 *
 *  Created by Kok Chen on 4/17/06.
 */

#include "HellschreiberFont.h"

unsigned char *addPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s ) ;
unsigned char *addBilevelPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s ) ;

unsigned char *addTallPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s ) ;
unsigned char *addTallBilevelPattern( unsigned char *p, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char **s ) ;


unsigned char *addFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, int col1, int col2, int col3, int col4, int col5, int col6, int col7 ) ;
unsigned char *addGrayFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char* col1, char* col2, char* col3, char* col4, char* col5, char* col6, char* col7 ) ;

unsigned char *addWideFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, int col1, int col2, int col3, int col4, int col5, int col6, int col7, int col8, int col9 ) ;
unsigned char *addWideGrayFont( unsigned char *s, unsigned char *start, HellschreiberFontHeader *h, int ascii, int width, char* col1, char* col2, char* col3, char* col4, char* col5, char* col6, char* col7, char* col8, char* col9 ) ;

