//
//  AYTextView.m
//  cocoaCCD
//
//  Created by Kok Chen on Sun Apr 04 2004.
//

#import "AYTextView.h"
#import "Messages.h"
#import "TextEncoding.h"


@implementation AYTextView


- (BOOL)isOpaque
{
	return YES ;
}

- (void)setTextAttributeOnMainThread
{
	[ super setFont:attribute->font ] ;
	[ super setInsertionPointColor:attribute->textColor ] ;
}

- (void)setTextAttribute:(TextAttribute*)a
{
	attribute = a ;
	[ self performSelectorOnMainThread:@selector(setTextAttributeOnMainThread) withObject:nil waitUntilDone:NO ] ;
}

//  return a dictionary with the default text attributes
- (TextAttribute*)newAttribute
{
	TextAttribute *a ;
	
	a = (TextAttribute*)malloc( sizeof( TextAttribute ) ) ;
	
	//  default font
	a->font = [ NSFont fontWithName:@"Verdana" size:14 ] ;
	if ( !a->font ) a->font = [ NSFont systemFontOfSize:14 ] ;
	[ a->font retain ] ;
	//  default text color
	a->textColor = [ [ NSColor colorWithCalibratedRed:1 green:0.8 blue:0 alpha:1 ] retain ] ;
	a->dictionary = [ @{NSForegroundColorAttributeName: a->textColor, NSFontAttributeName: a->font} retain ] ;
	return a ;
}

- (BOOL)shouldDrawInsertionPoint
{
	return hasInsertionPoint ;
}

- (void)turnOffInsertionPoint:(Boolean)state
{
	hasInsertionPoint = !state ;
}

- (void)awakeFromNib
{
	NSFontManager *fontMgr ;
	NSScrollView *scrollView ;
	
	ignoreNewline = NO ;
	viewLock = [ [ NSLock alloc ] init ] ;
	bufferLock = [ [ NSLock alloc ] init ] ;
	appendLock = [ [ NSLock alloc ] init ] ;

	fontMgr = [ NSFontManager sharedFontManager ] ;
	[ fontMgr setDelegate:self ] ;  // delegate for -changeFont
	
	[ background = [ NSColor colorWithCalibratedRed:0 green:0 blue:0 alpha:1 ] retain ] ;
	
	defaultAttribute = [ self newAttribute ] ;
	//  set colors and fonts
	[ super setBackgroundColor:background ] ;
	[ self setTextAttribute:defaultAttribute ] ;
	
	[ self setContinuousSpellCheckingEnabled:NO ] ; // turn off spell checker
	thread = [ NSThread currentThread ] ;
	
	//  get scroller
	scrollView = [ self enclosingScrollView ] ;
	scroller = nil ;
	if ( scrollView ) {
		scroller = [ scrollView verticalScroller ] ;
	}
	hasInsertionPoint = YES ;
	[ self setMenu:nil ] ;
}

- (void)setIgnoreNewline:(Boolean)state
{
	ignoreNewline = state ;
}

// set following text storage  
- (void)setTextColor:(NSColor*)inColor attribute:(TextAttribute*)a
{
	NSColor *oldColor ;
	NSDictionary *oldDictionary ;
	
	oldColor = a->textColor ;
	a->textColor = [ inColor retain ] ;
	[ oldColor release ] ;
	//  create new dictionary with new color
	oldDictionary = a->dictionary ;
	a->dictionary = [ @{NSForegroundColorAttributeName: a->textColor, NSFontAttributeName: a->font} retain ] ;
	[ oldDictionary release ] ;
	//  note:setTextAttribute also locks
	[ self setTextAttribute:a ] ;
}

- (void)setTextColorOnMainThread:(NSColor*)color
{
	[ super setTextColor:color ] ;
}

//  set entire view's text color
- (void)setViewTextColor:(NSColor*)inColor attribute:(TextAttribute*)a
{
	NSColor *oldColor ;
	NSDictionary *oldDictionary ;
	
	oldColor = a->textColor ;
	[ inColor retain ] ;
	a->textColor = inColor ;
	[ self performSelectorOnMainThread:@selector(setTextColorOnMainThread:) withObject:a->textColor waitUntilDone:NO ] ;
	[ oldColor release ] ;
	//  create new dictionary with new color
	oldDictionary = a->dictionary ;
	a->dictionary = [ @{NSForegroundColorAttributeName: a->textColor, NSFontAttributeName: a->font} retain ] ;
	[ oldDictionary release ] ;
	[ self setTextAttribute:a ] ;
}

- (void)setTextFont:(NSString*)name size:(float)size attribute:(TextAttribute*)a
{
	NSFont *newFont, *oldFont ;
	NSDictionary *oldDictionary ;
	
	newFont = [ NSFont fontWithName:name size:size ] ;
	if ( newFont ) {
		[ viewLock lock ] ;
		oldFont = a->font ;
		a->font = [ newFont retain ] ;
		[ oldFont release ] ;
		//  create new dictionary with new font
		oldDictionary = a->dictionary ;
		a->dictionary = [ @{NSForegroundColorAttributeName: a->textColor, NSFontAttributeName: a->font} retain ] ;
		[ oldDictionary release ] ;
		[ viewLock unlock ] ;
	}
	[ self setTextAttribute:a ] ;
}

- (void)setTextFont:(NSFont*)newFont attribute:(TextAttribute*)a
{
	NSFont *oldFont ;
	NSDictionary *oldDictionary ;
	
	if ( newFont ) {
		[ viewLock lock ] ;
		oldFont = a->font ;
		[ newFont retain ] ;
		a->font = newFont ;
		[ oldFont release ] ;
		//  create new dictionary with new font
		oldDictionary = a->dictionary ;
		a->dictionary = @{NSForegroundColorAttributeName: a->textColor, NSFontAttributeName: a->font} ;
		[ a->dictionary retain ] ;
		[ oldDictionary release ] ;
		[ viewLock unlock ] ;
	}
	[ self setTextAttribute:a ] ;
}

/* local */
- (void)backspace
{
	int total ;
	NSTextStorage *storage ;
	NSRange end ;
	
	storage = [ self textStorage ] ;
	total = [ storage length ] ;
	
	if ( total < 2 ) return ;
	end = NSMakeRange( total-1, 1 ) ;
	[ storage replaceCharactersInRange:end withString:@"" ] ;
}

/* local */
//  NOTE: this is performed in the main thread
//  string must be shorter than 64 characters
- (void)convertAndAppendAsUnicode:(unsigned char*)charBuffer length:(int)length
{
	int i, n, u ;
	NSAttributedString *string ;
	
	if ( length <= 0 ) return ;
	
	if ( length > 64 ) length = 64 ;
	
	if ( ( charBuffer[0] ) == 010 ) {
		[ self backspace ] ;
		return ;
	}
	n = 0 ;
	for ( i = 0; i < length; i++ ) {
		u = charBuffer[i] & 0xff ;
		if ( u < 32 && u != '\n' ) {
			//  ignore control characters
		}
		else {
			// replace 0x80 by unicode for euro symbol
			if ( ignoreNewline && u == '\n' ) {
				uni[n++] = ' ' ;
				uni[n++] = '-' ;
				uni[n++] = ' ' ;
			}
			else {
				if ( u == 0x80 ) u = 0x20ac ;		// euro symbol
				uni[n++] = u ;
			}
		}
	}
	if ( n > 0 ) {	
		string = [ [ NSAttributedString alloc ] initWithString:[ NSString stringWithCharacters:uni length:n ] attributes:attribute->dictionary ] ;
		[ self appendOnMainThread:string ] ;
	}
}

- (void)appendString:(NSString*)str
{
	int u, bufferLength ;
	unsigned char charBuffer[64] ;
	const char *s ;
	
	if ( [ bufferLock tryLock ] ) {
		s = [ str cStringUsingEncoding:kTextEncoding ] ;
		if ( s ) {
			//  ignore overruns
			bufferLength = 0 ;
			while ( *s ) {
				u = *s++ & 0xff ;
				//  check for backspaces
				if ( u == 010 ) {
					if ( bufferLength > 0 ) [ self convertAndAppendAsUnicode:charBuffer length:bufferLength ] ;
					charBuffer[0] = 010 ;
					bufferLength = 1 ;
					[ self convertAndAppendAsUnicode:charBuffer length:1 ] ;
					bufferLength = 0 ;
				}
				else {
					charBuffer[bufferLength++] = u ;
					if ( bufferLength >= 60 ) {
						[ self convertAndAppendAsUnicode:charBuffer length:bufferLength ] ;
						bufferLength = 0 ;
					}
				}
			}
		}
		//  flush string if non-zero length
		if ( bufferLength > 0 ) {
			[ self convertAndAppendAsUnicode:charBuffer length:bufferLength ] ;
		}
		[ bufferLock unlock ] ;
	}
}

//	(Private API)
//  v0.70 same as AppendString but for Unicode
- (void)appendUnicodeString:(NSString*)str
{
	if ( [ bufferLock tryLock ] ) {
		NSAttributedString *string = [ [ NSAttributedString alloc ] initWithString:str attributes:attribute->dictionary ] ;
		[ self appendOnMainThread:string ] ;		
		[ bufferLock unlock ] ;
	}
}

//  force cursor back to arrow after insertion
- (void)keyDown:(NSEvent*)event
{
	int ch ;
	
	if ( [ [ event characters ] length ] > 0 ) {	
		ch = [ [ event characters ] characterAtIndex:0 ] ;
		if ( ch == 033 ) return ;		// toss ESC
	}
	[ super keyDown:event ] ;
}

//  add a string to the ring buffer in the main thread
- (void)append:(char*)s
{
	NSString *string ;
	
	string = [ NSString stringWithCString:s encoding:kTextEncoding ] ;
	[ self performSelectorOnMainThread:@selector(appendString:) withObject:string waitUntilDone:NO ] ;
}

//	v0.70 - append Unicode character to NSTextView
- (void)appendUnicode:(unichar)c
{
	NSString *string ;
	unichar unistr[2] ;
	
	unistr[0] = c ;	
	string = [ NSString stringWithCharacters:unistr length:1 ] ;
	
	[ self performSelectorOnMainThread:@selector(appendUnicodeString:) withObject:string waitUntilDone:NO ] ;
}

- (void)setAppendLock:(Boolean)state 
{
	if ( state == YES ) [ appendLock lock ] ; else [ appendLock unlock ] ;
}
	
//  -appendOnMainThread does not use NSTextView's insert method since that requires the view to be editable 
//  -appendOnMainThread can be used with read-only (e.g., RTTY output) views
//  call -append from a secondary thread
- (void)appendOnMainThread:(NSAttributedString*)string
{
	int total, i, length ;
	NSTextStorage *storage ;
	Boolean hasNewline, endOfScroll ;
	NSString *temp ;
	
	[ appendLock lock ] ;
						
	endOfScroll = ( [ scroller floatValue ] >= 1.00 ) ;	
	storage = [ self textStorage ] ;
	total = [ storage length ] ;
	
	[ storage appendAttributedString:string ] ;

	//  check if need to scroll, inhibit if not at the end (user has moved scroller)
	if ( endOfScroll ) {
		hasNewline = NO ;
		temp = [ NSString stringWithString:[ string string ] ] ;
		length = [ temp length ] ;
		for ( i = 0; i < length; i++ ) if ( [ temp characterAtIndex:i ] == '\n' ) hasNewline = YES ;
		if ( hasNewline || ( charSinceNewline += length ) > 50 ) {
			total = [ storage length ] ;
			[ self scrollRangeToVisible:NSMakeRange( total, 0 ) ] ;
			if ( hasNewline ) charSinceNewline = 0 ;
		}
	}
	[ string release ] ;
	[ appendLock unlock ] ;
}

- (void)insertAtEnd:(NSString*)string
{
	NSRange end ;
	
	[ self insertInTextStorage:string ] ;
	end = NSMakeRange( [ [ self textStorage ] length ], 0 ) ;
	[ self scrollRangeToVisible:end ] ;
}

- (void)insertInTextStorage:(NSString*)string
{
	NSRange end ;

	end = NSMakeRange( [ [ self textStorage ] length ], 0 ) ;
	[ self setSelectedRange:end ] ;
	[ self insertText:string ] ;
}

//  scroll so the text at end is visible
- (void)scrollToEnd
{
	NSRange end ;
	int length ;
	
	if ( [ self lockFocusIfCanDraw ] ) {
		length = [ [ self textStorage ] length ] ;
		end = NSMakeRange( length, 0 ) ;
		[ self scrollRangeToVisible:end ] ;
		[ self unlockFocus ] ;
	}
}

- (void)updateDisplayOnMainThread
{
    NSRange end ;
    
	end = NSMakeRange( [ [ self textStorage] length], 0 ) ;
	[ self scrollRangeToVisible:end ] ;
}

- (void)updateDisplay
{
	[ self performSelectorOnMainThread:@selector(updateDisplayOnMainThread) withObject:nil waitUntilDone:NO ] ;
}

- (void)clearAllOnMainThread
{
	NSRange all ;

	all = NSMakeRange( 0, [ [ self textStorage ] length ] ) ;
	[ self replaceCharactersInRange:all withString:@"" ] ;
	[ self scrollRangeToVisible:NSMakeRange( 0,0 ) ] ;
}

- (void)clearAll
{
	[ self performSelectorOnMainThread:@selector(clearAllOnMainThread) withObject:nil waitUntilDone:NO ] ;
}

//  make this textview the first responder
- (void)select
{
	[ [ self window ] makeFirstResponder:self ] ;
}

- (void)drawRect:(NSRect)rect
{
	if ( thread == [ NSThread currentThread ] ) {
		//  ensure that we are called from the main thread
		[ super drawRect:rect ] ;
	}
}

//  delegate for NSFontManager
//  called when the font panel changes font for the textView
- (void)changeFont:(id)sender
{
	NSFont *font, *oldFont ;
	
	font = [ sender convertFont:attribute->font ] ;
	if ( font != attribute->font ) {
		[ font retain ] ;
		oldFont = attribute->font ;
		[ self setTextFont:font attribute:attribute ] ;
		[ oldFont release ] ;
	}
}


@end
