//
//  UpperFormatter.m
//  Contest
//
//  Created by Kok Chen on Wed Dec 11 2002.
	#include "Copyright.h"
//

#import "UpperFormatter.h"
#import "cocoaModemParams.h"
#import "TextEncoding.h"

//  Uppercase formatter for NSTextField
//  control-drag formatter of NSTextField's to instance of this class in Interface Builder
//  or use setFormatter: for NSTextField

@implementation UpperFormatter

void getUppercase( char *result, char *string )
{
	int v ;
	
	while ( *string ) {
		v = *string++ ;
		if ( v == phi || v == Phi ) v = 0 ;
		if ( v >= 'a' && v <= 'z' ) v += 'A' - 'a' ;
		*result++ = v ;
	}
	*result = 0 ;
}

//  substitute with upper cased characters, range positions remain the same
- (BOOL)isPartialStringValid:(NSString **)partialStringPtr proposedSelectedRange:(NSRangePointer)proposedSelRangePtr originalString:(NSString *)origString originalSelectedRange:(NSRange)origSelRange errorDescription:(NSString **)error
{
	char u[64], *s ;
	
	if ( partialStringPtr == nil || *partialStringPtr == nil ) {
		return NO ;
	}
	s = ( char* )[ *partialStringPtr cStringUsingEncoding:kTextEncoding ] ;
	if ( s == nil || strlen( s ) > 60 ) {
		//  invalid string for this formatter
		return [ super isPartialStringValid:partialStringPtr proposedSelectedRange:proposedSelRangePtr originalString:origString originalSelectedRange:origSelRange errorDescription:error ] ;
	}
	getUppercase( u, s ) ;
	*partialStringPtr = [ NSString stringWithCString:u encoding:kTextEncoding ] ;
    return NO ;
}

//  return current string as is in objectValue
- (BOOL)getObjectValue:(id *)obj forString:(NSString *)string errorDescription:(NSString **)error
{
    *obj = [ NSString stringWithString:string ] ;
    return YES ;
}


//  return the string that is obtained from -getObjectValue.
//  this is the final string that is accepted by NSTextField
- (NSString *)stringForObjectValue:(id)obj
{
    return obj ;
}
@end
