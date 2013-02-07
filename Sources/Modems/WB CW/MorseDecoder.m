//
//  MorseDecoder.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/2/06.
	#include "Copyright.h"
	
	
#import "MorseDecoder.h"
#import "CWDemodulator.h"
#import "TextEncoding.h"

@implementation MorseDecoder


typedef struct {
	int code ;
	char *seq ;
} Code ;

//  use upper ASCII for Prosigns
#define	AR		0x80
#define	AS		0x81
#define	SK		0x82
#define	NR		0x83

//  mis keys
#define	US		0xc0
#define	AME		0xc1
#define	NAME	0xc2
#define RST		0xc3
#define	WA		0xc4
#define	KN		0xc5

Code morse[] = {
	{ 'A',	".-"		},	
	{ 'B',	"-..."		},	
	{ 'C',	"-.-."		},	
	{ 'D',	"-.."		},
	{ 'E',	"."			},	
	{ 'F',	"..-."		},	
	{ 'G',	"--."		},
	{ 'H',	"...."		},
	{ 'I',	".."		},
	{ 'J',	".---"		},
	{ 'K',	"-.-"		},
	{ 'L',	".-.."		},
	{ 'M',	"--"		},
	{ 'N',	"-."		},
	{ 'O',	"---"		},
	{ 'P',	".--."		},
	{ 'Q',	"--.-"		},
	{ 'R',	".-."		},
	{ 'S',	"..."		},
	{ 'T',	"_"			},
	{ 'U',	"..-"		},
	{ 'V',	"...-"		},
	{ 'W',	".--"		},
	{ 'X',	"-..-"		},
	{ 'Y',	"-.--"		},
	{ 'Z',	"--.."		},
	{ '1',	".----"		},
	{ '2',	"..---"		},
	{ '3',	"...--"		},
	{ '4',	"....-"		},
	{ '5',	"....."		},
	{ '6',	"-...."		},
	{ '7',	"--..."		},
	{ '8',	"---.."		},
	{ '9',	"----."		},
	{ '0',	"-----"		},
	{ '.',	".-.-.-"	},
	{ ',',	"--..--"	},
	{ '?',	"..--.."	},
	{ '/',	"-..-."		},
	{ '=',	"-...-"		},
	{ '@',	".--.-."	},
	{ AR,	".-.-."		},
	{ AS,	".-..." 	},
	{ SK,	"...-.-"	},
	//  possible miskeys
	{ US,   "..-..."    },
	{ AME,  ".---."		},
	{ NAME, "-..---."	},
	{ RST,  ".-....-"	},
	{ WA,	".--.-"		},
	{ KN,	"-.--."		},
	//  possible error corrections
	{ '.',  "-.-.-"     },
	{ '3',  "..--"		},
	//{ 'ä',	".-.-"		},
	//{ 'ö',	"---."		},
	//{ 'ü',	"..--"		},
	{ 0,	""		}
} ;

static unsigned char codeTable[6561] ;				//  8 ternary digits
static Boolean extension[256] ;						//  characters that are extended by Morse.txt

static int decodeToCodeTableIndex( char* string )
{
	int i, n ;
	
	n = 0 ;
	for ( i = 0; i < 8; i++ ) {
		if ( *string == 0 ) break ;
		n = n*3 + ( ( *string++ == '.' ) ? 1 : 2 ) ;
	}
	if ( n >= 6561 ) n = 6560 ;
	return n ;
}

- (id)initWithDemodulator:(CMFSKDemodulator*)demod
{
	int i, n, index ;
	NSString *name ;
	const char *path ;
	char string[257] ;
	FILE *ext ;
	
	self = [ super initWithDemodulator:demod ] ;
	if ( self ) {	
		for ( i = 0; i < 6561; i++ ) codeTable[i] = '*' ;
		for ( i = 0; i < 256; i++ ) {
			extension[i] = NO ;
			if ( morse[i].code == 0 ) break ;
			n = decodeToCodeTableIndex( morse[i].seq ) ;
			codeTable[n] = morse[i].code ;
		}
		//  0.53e -- set up output for Morse.txt
		name = [ NSString stringWithCString:"~/Library/Application Support/cocoaModem/Morse.txt" encoding:kTextEncoding ] ;
		path = [ [ name stringByExpandingTildeInPath ] cStringUsingEncoding:kTextEncoding ] ;
		ext = fopen( path , "r" ) ;
		if ( ext ) {
			while ( 1 ) {
				index = 0 ;
				string[0] = 0 ;
				if ( fscanf( ext, "%d %s", &index, string ) == nil || index <= 0 ) break ;
				//  only allow "reasonable" encoding and strings
				n = strlen( string ) ;
				if ( index > 0 && index < 6560 && string[0] != 0 && n < 8 ) {
					//  make sure string has only . and -
					for ( i = 0; i < n; i++ ) if ( string[i] != ',' && string[i] != '-' ) break ;
					if ( i < n ) {
						//  tie code dot-dash sequence to the ascii index from Morse.txt
						n = decodeToCodeTableIndex( string ) ; 
						codeTable[n] = index ;
						extension[index] = YES ;
					}
				}
				fgets( string, 256, ext ) ;	//  skip to next line
			}
			fclose( ext ) ;
		}
	}
	return self ;
}

- (void)newCharacter:(char*)string length:(int)length wordSpacing:(int)spacing
{
	int i, d, c ;
	char *s ;
	
	if ( length > 0 ) {
		d = decodeToCodeTableIndex( string ) ;
		c = codeTable[ d ] ;
		if ( c < 0x80 ) {
			if ( c != '*' ) [ demodulator receivedCharacter:c ] ;
		}
		else {
			//  v0.53e -- extended by Morse.txt
			if ( c < 256 && extension[c] == YES ) [ demodulator receivedCharacter:c ] ;
			else {
				switch ( c ) {
				case AR:
					s = "<AR>" ;
					break ;
				case SK:
					s = "<SK>" ;
					break ;
				case AS:
					s = "<AS>" ;
					break ;
				case NR:
					s = "<NR>" ;
					break ;
					//  possible miskeys
				case US:
					s = "US" ;
					break ;
				case AME:
					s = "AME" ;
					break ;
				case NAME:
					s = "NAME" ;
					break ;
				case RST:
					s = "RST" ;
					break ;
				case WA:
					s = "WA" ;
					break ;
				case KN:
					s = "KN" ;
					break ;
				default:
					s = "<??>" ;
					break ;
				}
				for ( i = 0; i < 4; i++ ) {
					if ( !*s ) break ;
					[ demodulator receivedCharacter:*s++ ] ;
				}
			}
		}
	}
	for ( i = 0; i < spacing; i++ ) [ demodulator receivedCharacter:' ' ] ;
}

- (void)importData:(CMPipe*)pipe
{
	// data comes in from a direct call
}

@end
