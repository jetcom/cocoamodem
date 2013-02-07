//
//  StripPhi.m
//  cocoaModem
//
//  Created by Kok Chen on 12/5/04.
	#include "Copyright.h"
//

#import "StripPhi.h"
#import "cocoaModemParams.h"
#import "TextEncoding.h"

@implementation StripPhi

//  replace string with one that is normal ascii
//  client must retain if it needs to keep the string
- (NSString*)asciiString:(NSString*)input 
{
	unsigned char *s, *original ;
	char *u ;
	int t ;
	NSString *result ;
	
	s = original = ( unsigned char* )[ input cStringUsingEncoding:kTextEncoding ] ;
	assert( strlen( (char *)original ) < 127 ) ;
	while ( *s > 0 ) {
		t = *s++ & 0xff ;
		if ( t > 127 ) {
			// has Phi
			u = buffer ;
			strcpy( buffer, (char *)original ) ;
			while ( *u ) {
				t = *u & 0xff ;
				if ( t == phi || t == Phi ) *u = '0' ;
				u++ ;
			}
			result = [ NSString stringWithCString:buffer encoding:kTextEncoding ] ;
			return result ;
		}
	}
	return input ;
}

//  client must release the string!
- (NSString*)asciiCString:(char*)input 
{
	unsigned char *s ;
	char *u ;
	int t ;
	NSString *result ;
	
	s = ( unsigned char* )input ;
	while ( *s > 0 ) {
		t = *s++ & 0xff ;
		if ( t > 127 ) {
			// has Phi
			u = buffer ;
			assert( strlen( input ) < 127 ) ;
			strcpy( buffer, input ) ;
			while ( *u ) {
				t = *u & 0xff ;
				if ( t == phi || t == Phi ) *u = '0' ;
				u++ ;
			}
			result = [ [ NSString alloc ] initWithCString:buffer encoding:kTextEncoding ] ;
			return result ;
		}
	}
	return [ [ NSString alloc ] initWithCString:input encoding:kTextEncoding ] ;
}

@end
