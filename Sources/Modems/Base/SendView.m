//
//  SendView.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 08 2004.
	#include "Copyright.h"
//

#import "SendView.h"


@implementation SendView

//  TextViews for transmitViews

- (NSArray*)readablePasteboardTypes
{
	//  allow only plain text
	return @[[ NSString stringWithString:@"NSStringPboardType" ]] ;
}

- (void)viewDidMoveToWindow
{
	NSScrollView *scrollView ;
	
	scrollView = [ self enclosingScrollView ] ;
	if ( scrollView ) {
		//  use arrow cursor for this view
		[ scrollView setDocumentCursor:[ NSCursor arrowCursor ] ] ;
	}
}

- (void)insertCompletion:(NSString *)word forPartialWordRange:(NSRange)charRange movement:(int)movement isFinal:(BOOL)flag
{
	NSString *remainder ;
	
	if ( flag ) {
		//  get part of string not yet transmitted, and insert
		remainder = [ [ word substringFromIndex:charRange.length ] retain ] ;
		[ self insertText:remainder ] ;
		[ remainder release ] ;
	}
}

//  force cursor to arrow when scrolling
- (void)resetCursorRects
{
	[ self addCursorRect:[ self visibleRect ] cursor:[ NSCursor arrowCursor ] ] ;
}

- (void)mouseDown:(NSEvent*)event
{
	[ super mouseDown:event ] ;
	[ [ NSCursor arrowCursor ] set ] ;
}

//  delete character if at end
//  DeleteView overides this
- (void)deleteFromEnd:(NSEvent*)event
{
}

//  force cursor back to arrow after insertion
- (void)keyDown:(NSEvent*)event
{
	[ super keyDown:event ] ;
	[ [ NSCursor arrowCursor ] set ] ;
}

//  NSResponder
- (void)flagsChanged:(NSEvent*)event
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"OptionKey" object:event ] ;
	[ super flagsChanged:event ] ;
}

//   NSResponder
- (BOOL)performKeyEquivalent:(NSEvent*)event
{
	int n ;
	
	if ( [ [ event characters ] length ] == 0 ) return NO ;
	n = [ [ event charactersIgnoringModifiers ] characterAtIndex:0 ] ;
	if ( ( n >= '0' && n <= '9' ) || n == '-' || n == '=' ) {
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"MacroKeyboardShortcut" object:event ] ;
		return YES ;
	}
	return NO ;
}

//	v 0.70 -- (Delegate of SendView implements this method)
- (void)insertedText:(id)string
{
}

//	v 0.70 -- Kotoeri text collected and inserted as a word here
- (void)insertText:(id)string
{
	id delegate ;
	
	[ super insertText:string ] ;
	delegate = [ self delegate ] ;
	if ( delegate && [ delegate respondsToSelector:@selector(insertedText:) ] ) [ delegate insertedText:string ] ;
}

@end
