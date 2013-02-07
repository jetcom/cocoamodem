//
//  AYTextView.h
//  cocoaCCD
//
//  Created by Kok Chen on Sun Apr 04 2004.
//

#ifndef _AYTEXTVIEW_H_
    #define _AYTEXTVIEW_H_
    
    #import <Cocoa/Cocoa.h>
	
	#define	TEXTRINGMASK	0x3ff
	
	typedef struct {
		NSFont *font ;
		NSColor *textColor ;
		NSDictionary *dictionary ;
	} TextAttribute ;
    
	@interface AYTextView : NSTextView {
        Boolean initialized ;
		Boolean hasInsertionPoint ;
		NSColor *background ;
		NSThread *thread ;
		NSScroller *scroller ;
		int charSinceNewline ;
		//  font attributes
		TextAttribute *attribute ;
		TextAttribute *defaultAttribute ;

		NSLock *bufferLock, *viewLock ;
		NSLock *appendLock ;
		unichar uni[256] ;
		
		Boolean ignoreNewline ;
    }
	
    - (void)updateDisplay ;
	- (void)setIgnoreNewline:(Boolean)state ;
	
	- (void)setTextFont:(NSString*)name size:(float)size attribute:(TextAttribute*)a ;
	- (void)setTextFont:(NSFont*)newFont attribute:(TextAttribute*)a ;
	
	- (void)setTextColor:(NSColor*)txColor attribute:(TextAttribute*)a ;
	- (void)setViewTextColor:(NSColor*)inColor attribute:(TextAttribute*)a ;
	- (void)setTextAttribute:(TextAttribute*)a ;
	- (TextAttribute*)newAttribute ;
	
	- (void)turnOffInsertionPoint:(Boolean)state ;
	
	- (void)append:(char*)s ;
	- (void)appendUnicode:(unichar)c ;		//  v0.70
	- (void)appendOnMainThread:(NSAttributedString*)string ;
	- (void)setAppendLock:(Boolean)state ;
	
	- (void)insertAtEnd:(NSString*)string ;
	- (void)insertInTextStorage:(NSString*)string ;
	- (void)clearAll ;
	- (void)select ;
	- (void)scrollToEnd ;

    @end

#endif
