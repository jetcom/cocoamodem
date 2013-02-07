//
//  ContestTextField.m
//  cocoaModem
//
//  Created by Kok Chen on 11/17/04.
//

#import "ContestTextField.h"


@implementation ContestTextField

- (void)awakeFromNib
{
	editor = [ [ self window ] fieldEditor:YES forObject:self ] ;
	//  accepts fontChanges messages here
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(setContestFont:) name:@"ContestFont" object:nil ] ;
}

- (Boolean)sameFont:(NSString*)name asBase:(NSString*)base
{
	int length ;
	
	if ( [ name isEqualToString:base ] ) return YES ;
	length = [ base length ] ;
	if ( [ name length ] < length ) return NO ;
	return ( [ [ name substringToIndex:length ] isEqualToString:base ] ) ;
}

static float lucidaGrandeOffset[] = { 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, 0, 1, 1, -1, -1, -1, -1 } ;
static float verdanaOffset[] = { 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 1, -2, -3, -4, -5, -6, -7, -8 } ;
static float tektonOffset[] = { 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 2, 1, 1, 2, -1, 0, 0 } ;
static float monacoOffset[] = { 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 2, 2, 1, -4, -4, -4, -5, -7, -8, -8 } ;

//  NSNotification with name "ContestFont" is sent when font changes
- (void)setContestFont:(NSNotification*)notify
{
	NSFont *font ;
	NSString *name ;
	int index ;
	float y, size, matrix[6] = { 0, 0, 0, 0, 0, 0 } ;
	
	font = [ notify object ] ;
	size = [ font pointSize ] ;
	name = [ font fontName ] ;

	y = 0 ;
	index = size+0.5 ;
	if ( index > 20 ) index = 20 ;
	
	if ( [ self sameFont:name asBase:@"LucidaGrande" ] ) y = lucidaGrandeOffset[index] ;
	else if ( [ self sameFont:name asBase:@"Verdana" ] ) y = verdanaOffset[index] ;
	else if ( [ self sameFont:name asBase:@"Tekton" ] ) y = tektonOffset[index] ;
	else if ( [ self sameFont:name asBase:@"Monaco" ] ) y = monacoOffset[index] ;
	else y = verdanaOffset[index] ;

	matrix[0] = matrix[3] = size ;	
	matrix[5] = y-2 ;
	
	[ self setFont: [ NSFont fontWithName:[ font fontName ] matrix:matrix ] ] ;

	//  redraw
	[ self setStringValue:[ self stringValue ] ] ;
}


@end
