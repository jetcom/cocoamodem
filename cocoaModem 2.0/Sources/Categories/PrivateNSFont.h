//
//  PrivateNSFont.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/25/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//	NSFont Category
//	Provides interface to NSFont's private API (_defaultGlyphForChar:)

@interface NSFont (PrivateNSFont)

- (NSGlyph)_defaultGlyphForChar:(unichar)c ;

@end
