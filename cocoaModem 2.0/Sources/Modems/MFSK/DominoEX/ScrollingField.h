//
//  ScrollingField.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/24/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TextFieldForScrolling.h"


@interface ScrollingField : NSView {
	TextFieldForScrolling *textField ;
	NSMutableString *stringValue ;
	NSRect originalRect ;
	float fontAdvance[256], currentFontAdvance ;
	NSGlyph glyph[256] ;
	int scrollCount ;
	int extraPause ;
	int scrollRate ;
	NSTimer *timer ;
	int currentMode ;
	NSFont *font ;
	Boolean busy ;
	
	unichar backlogString[2048] ;
	unsigned long producer, consumer ;
	
	Boolean useSmooth ;
	Boolean fast ;
}

- (void)setTextField:(NSTextField*)field ;
- (void)setBackgroundColor:(NSColor*)color ;
- (void)setTextColor:(NSColor*)color ;
- (void)setSmoothState:(NSButton*)checkbox ;
- (void)setMFSKMode:(int)mode ;

- (void)appendCharacter:(int)c draw:(Boolean)draw ;
- (void)clear ;

@end
