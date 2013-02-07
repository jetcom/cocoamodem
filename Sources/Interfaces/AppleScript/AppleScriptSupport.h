//
//  AppleScriptSupport.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface AppleScriptSupport : NSObject {
	NSString *scriptFolder ;
	Boolean scriptsLoaded ;
}

- (NSAppleScript*)executeScript:(NSAppleScript*)script withError:(const char*)msg ;

- (NSAppleScript*)executeScript:(NSAppleScript*)script withError:(const char*)msg ;
- (NSAppleScript*)executeScript:(NSAppleScript*)script reply:(NSAppleEventDescriptor**)eventDescriptor withError:(const char*)msg ;
- (NSAppleScript*)loadScriptFor:(NSString*)scptFile ;	
- (NSAppleScript*)loadScriptForPath:(NSString*)scptFile ;	

- (Boolean)updateScriptsFromFolder:(NSString*)newfolder ;
- (NSString*)folderName ;

@end
