//
//  TransparentTextField.m
//  cocoaModem
//
//  Created by Kok Chen on 11/23/04.
	#include "Copyright.h"
//

#import "TransparentTextField.h"


@implementation TransparentTextField


//  transparent text field for use over a watermark (e.g., DUPE warning)
- (void)awakeFromNib
{
	//  accepts fontChanges messages here
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(setContestFont:) name:@"ContestFont" object:nil ] ;
	
	fieldType = 0 ;
	savedString = @"" ;
	ignore = NO ;
	[ self setBezeled:NO ] ;
	[ self setBordered:NO ] ;			// cocoa screws up vertical positioning if transnsprent view is not bordered
	[ self setDrawsBackground:NO ] ;
}

//  kCallsignTextField, kExchangeTextField
- (void)setFieldType:(int)type
{
	fieldType = type ;
}

- (int)fieldType
{
	return fieldType ;
}

- (void)markAsSelected:(Boolean)state
{
	[ self setBordered:state ] ;
}

- (NSString*)clickedString
{
	return savedString ;
}

- (void)setIgnoreFirstResponder:(Boolean)state
{
	ignore = state ;
}

//  clear savedString if the field is manually edited
- (BOOL)textShouldEndEditing:(NSText *)textObject
{
	savedString = @"" ;
	return [ super textShouldEndEditing:textObject ] ;
}

- (BOOL)acceptsFirstResponder
{
	return !ignore ;
}

//  save string in clicked string
//  any non zero length string here would cause a click/control click to cause an IBAction
- (BOOL)becomeFirstResponder
{
	savedString = [ self stringValue ] ;
	if ( ignore ) {
		ignore = NO ;
		return YES ;
	}
	if ( [ super becomeFirstResponder ] ) {
		//  inform Contest object that a new field is selected
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SelectNewField" object:self ] ;
		return YES ;
	}
	return NO ;
}

- (void)moveAbove
{
	NSView *view ;
	
	view = [ self superview ] ;
	[ self retain ] ;
	[ self removeFromSuperview ] ;
	[ view addSubview:self positioned:NSWindowAbove relativeTo:nil ] ;
	[ self release ] ;  // addSubview should do one retain
}

static float lucidaGrandeOffset[] = { 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 1, 0, 1, 1, -1, -1, -1, -1 } ;
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
	
	//  do some centering adjustments for Panther
	y = 0 ;
	index = size+0.5 ;
	if ( index > 20 ) index = 20 ;
	
	if ( [ self sameFont:name asBase:@"LucidaGrande" ] ) y = lucidaGrandeOffset[index] ;
	else if ( [ self sameFont:name asBase:@"Verdana" ] ) y = verdanaOffset[index] ;
	else if ( [ self sameFont:name asBase:@"Tekton" ] ) y = tektonOffset[index] ;
	else if ( [ self sameFont:name asBase:@"Monaco" ] ) y = monacoOffset[index] ;
	else y = verdanaOffset[index] ;

	matrix[0] = matrix[3] = size ;	
	matrix[5] = y ;
	
	[ self setFont:[ NSFont fontWithName:[ font fontName ] matrix:matrix ] ] ;

	//  redraw
	[ self setStringValue:[ self stringValue ] ] ;
}

@end
