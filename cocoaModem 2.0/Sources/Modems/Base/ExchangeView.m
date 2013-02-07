//
//  ExchangeView.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 08 2004.
	#include "Copyright.h"
//

#import "ExchangeView.h"
#include "Messages.h"


@implementation ExchangeView

- (void)viewDidMoveToWindow
{
	NSScrollView *scrollView ;
	
	[ self turnOffInsertionPoint:YES ] ;
	scrollView = [ self enclosingScrollView ] ;
	if ( scrollView ) {
		//  use arrow cursor for this view
		[ scrollView setDocumentCursor:[ NSCursor arrowCursor ] ] ;
	}
}

- (void)keyDown:(NSEvent*)event
{
	int ch ;
	
	if ( [ [ event characters ] length ] == 0 ) {			// v0.35
		[ super keyDown:event ] ;
		return ;
	}
	
	ch = [ [ event characters ] characterAtIndex:0 ] ;
	
	switch ( ch ) {
	case 0x7f:
		// delete selection
		[ self replaceCharactersInRange:[ self selectedRange ] withString:@"" ] ;
		break ;
	default:
		[ super keyDown:event ] ;
	}
}

//  AYTextView which manipulates callsigns, etc
//  cmd-C   enter callign into QSO object

//  -appendOnMainThread does not use NSTextView's insert method since that requires the view to be editable 
//  -appendOnMainThread can be used with read-only (e.g., RTTY output) views
//  call -append from a secondary thread
- (void)appendOnMainThread:(NSAttributedString*)string
{
	int total, length ;
	NSTextStorage *storage ;
    NSRange selected ;
	Boolean endOfScroll ;
	NSString *temp ;
	
	[ appendLock lock ] ;				// for contest clicking
	
	endOfScroll = ( [ scroller floatValue ] >= 1.0 ) ;
	//  place string into text storage of view
	storage = [ self textStorage ] ;
	total = [ storage length ] ;
	temp = [ string string ] ;
	
	length = [ temp length ] ;
	[ storage appendAttributedString:string ] ;
	
	//  move selection range away from the end
	selected = [ self selectedRange ] ;
	if ( selected.location == ( total+length ) ) {
		[ self setSelectedRange:NSMakeRange( 0, 0 ) ] ;
	}
	//  if we were at the end of the scroll bar, maintain scrolled position
	if ( endOfScroll ) {
		total = [ storage length ] ;
		[ self scrollRangeToVisible:NSMakeRange( total, 0 ) ] ;
	}
	[ string release ] ;
	
	[ appendLock unlock ] ;	
}

- (Boolean)getRightMouse
{
	return isRightMouse ;
}

//  read and clear right mouse flag
- (Boolean)getAndClearRightMouse
{
	Boolean wasRightMouse ;
	
	wasRightMouse = isRightMouse ;
	isRightMouse = NO ;
	return wasRightMouse ;
}

- (Boolean)getAndClearMouseClick
{
	Boolean wasMouse ;
	
	wasMouse = isMouseClick ;
	isMouseClick = NO ;
	return wasMouse ;
}

- (Boolean)getMouseClick
{
	return isMouseClick ;
}

- (Boolean)getEitherMouse
{
	return ( isRightMouse || isMouseClick ) ;
}

//  force cursor to arrow when scrolling
- (void)resetCursorRects
{
	[ self addCursorRect:[ self visibleRect ] cursor:[ NSCursor arrowCursor ] ] ;
}

- (void)mouseDown:(NSEvent*)event
{	
	isMouseClick = YES ;
	isRightMouse = ( [ event modifierFlags ] & NSControlKeyMask ) != 0 ;
	if ( isRightMouse ) {
		//  process control click as a right mouse click
		[ super mouseDown:event ] ;
		return ;
	}
	[ super mouseDown:event ] ;
	[ [ NSCursor arrowCursor ] set ] ;
}

//  return nil so it does not show on control click
- (NSMenu*)menuForEvent:(NSEvent*)event
{
	[ super menuForEvent:event ] ;	// do whatever NSTextView needs
	return nil ;					//  but returns nil so no menu pops up
}

//	v0.89 --  freeze click
- (void)awakeFromNib
{
	[ super awakeFromNib ] ;
	freeze = NO ;
	isRightMouse = NO ;
	isMouseClick = NO ;
}

//  v0.89 -- freeze click
- (void)drawRect:(NSRect)dirtyRect
{
	if ( freeze ) return ;
	[ super drawRect:dirtyRect ] ;
}

//	v0.89 -- freeze click
//  capture a control mouse down
//	The control click is used to freeze the input
- (void)rightMouseDown:(NSEvent*)event
{	
	freeze = YES ;
}

//	v0.89 --  freeze click
//  captures a control mouse up
//	it is first used to generate a fake right mouseDown (to do the actual callsign capture)
//	then finally unfreeze the view and send the actual mouse up.
- (void)rightMouseUp:(NSEvent*)event
{
	NSEvent *down ;
	
	isRightMouse = YES ;
	isMouseClick = YES ;
		
	down = [ NSEvent mouseEventWithType:NSRightMouseDown 
				location:[ event locationInWindow ] 
				modifierFlags:[ event modifierFlags ]
				timestamp:[ event timestamp ] 
				windowNumber:[ event windowNumber ] 
				context:[ event context ]
				eventNumber:[ event eventNumber ]
				clickCount:[ event clickCount ] 
				pressure:[ event pressure ] ] ;
	
	[ super rightMouseDown:down ] ;
	

	freeze = NO ;	
	[ super rightMouseUp:event ] ;
}



//  return proposed range for right and control clicks (this keeps the range at zero length)
- (NSRange)selectionRangeForProposedRange:(NSRange)proposedSelRange granularity:(NSSelectionGranularity)granularity
{
	if ( isRightMouse ) {
		return proposedSelRange ;
	}
	return [ super selectionRangeForProposedRange:proposedSelRange granularity:granularity ] ;
}

//  NSResponder
- (void)flagsChanged:(NSEvent*)event
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"OptionKey" object:event ] ;
	[ super flagsChanged:event ] ;
}

//   NSResponder - catches command 1 through = keys
- (BOOL)performKeyEquivalent:(NSEvent*)event
{
	int n ;
	
	if ( [ [ event characters ] length ] == 0 ) return NO ; // v0.35
	
	n = [ [ event charactersIgnoringModifiers ] characterAtIndex:0 ] ;
	
	switch ( n ) {
	case NSUpArrowFunctionKey:
	case NSDownArrowFunctionKey:
	case NSLeftArrowFunctionKey:
	case NSRightArrowFunctionKey:
		if ( [ event modifierFlags ] & NSCommandKeyMask ) {
			//  respond only if command key is down
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"ArrowKey" object:event ] ;
			return YES ;
		}
		//  do nothing otherwise
		return NO ;
	default:
		if ( ( n >= '0' && n <= '9' ) || n == '-' || n == '=' ) {
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"MacroKeyboardShortcut" object:event ] ;
			return YES ;
		}
		break ;
	}
	return NO ;
}

@end
