//
//  RTTYRoundupMults.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/26/05.
	#include "Copyright.h"
	
	
#import "RTTYRoundupMults.h"
#import "Contest.h"
#import "RTTYRoundup.h"
#import "TextEncoding.h"


@implementation RTTYRoundupMults

- (void)awakeFromNib
{
	

	workedColor = [ [ NSColor colorWithCalibratedRed:0 green:0.7 blue:0 alpha:0.9 ] retain ] ;
}

/* local */
- (NSWindow*)stateMultWindow
{
	NSTextFieldCell *cell ;
	
	cell = [ rrMults cellAtRow:0 column:0 ] ;
	return [ [ cell controlView ] window ] ;
}

- (void)workedAllVE:(NSColor*)color
{
	[ veArea setTextColor:color ] ;
}

- (void)workedAllArea:(int)area color:(NSColor*)color
{
	NSTextFieldCell *cell ;

	area-- ;
	if ( area < 0 ) area = 9 ;
	cell = [ callAreas cellAtRow:area column:0 ] ;
	[ cell setTextColor:color ] ;
}

- (void)updateCallArea:(int)area statelist:(StateList*)rawStateList
{
	int i, j ;
	
	if ( area > 20 ) {
		for ( i = 0; i < 64; i++ ) {
			if ( *rawStateList[i].abbrev == '*' ) break ;
			j = rawStateList[i].area ;
			if ( j > 20 && rawStateList[i].worked == 0 ) return ;
		}
		[ self workedAllVE:workedColor ] ;
		return ;
	}
	
	for ( i = 0; i < 64; i++ ) {
		if ( *rawStateList[i].abbrev == '*' ) break ;
		j = rawStateList[i].area ;
		if ( j == area && rawStateList[i].worked == 0 ) return ;
	}
	[ self workedAllArea:area color:workedColor ] ;
}

/* local */
- (void)colorRow:(int)row column:(int)column color:(NSColor*)color string:(NSString*)string
{
	NSTextFieldCell *cell ;

	cell = [ rrMults cellAtRow:row column:column ] ;
	[ cell setTextColor:color ] ;
	if ( string ) [ cell setStringValue:string ] ;
}

- (void)updateMult:(ContestQSO*)p statelist:(StateList*)rawStateList
{
	int i ;

	for ( i = 0; i < 64; i++ ) {
		if ( *rawStateList[i].abbrev == '*' ) break ;
		if ( strcmp( rawStateList[i].abbrev, p->exchange ) == 0 ) {
			rawStateList[i].worked++ ;
			if ( rawStateList[i].worked == 1 ) {
				[ self colorRow:rawStateList[i].y column:rawStateList[i].x color:workedColor string:nil ] ;
				[ self updateCallArea:rawStateList[i].area statelist:rawStateList ] ;
			}
			return ;
		}
	}
}

- (void)showWindow:(StateList*)rawStateList
{
	int i ;
	NSWindow *window ;
	
	for ( i = 0; i < 64; i++ ) {
		if ( *rawStateList[i].abbrev == '*' ) break ;
		[ self colorRow:rawStateList[i].y column:rawStateList[i].x color:( rawStateList[i].worked )?workedColor:[ NSColor blackColor ] string:[ NSString stringWithCString:rawStateList[i].abbrev encoding:kTextEncoding ] ] ;
	}
	for ( i = 0; i < 10; i++ ) [ self updateCallArea:i statelist:rawStateList ] ;
	[ self updateCallArea:21 statelist:rawStateList ] ;
	
	window = [ self stateMultWindow ] ;
	if ( window ) {
		[ (NSPanel*)window setFloatingPanel:NO ] ;
		[ window orderFront:self ] ; 
	}
}

@end
