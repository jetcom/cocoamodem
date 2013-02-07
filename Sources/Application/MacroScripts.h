//
//  MacroScripts.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/20/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface MacroScripts : NSObject {
	NSAppleScript *appleScript[6] ;
}

- (NSAppleScript*)setScriptFile:(NSString*)path index:(int)index ;
- (void)executeMacroScript:(int)index ;

@end
