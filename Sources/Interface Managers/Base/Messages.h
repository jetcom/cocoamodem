//
//  Messages.h
//  cocoaModem
//
//  Created by Kok Chen on Tue Jun 08 2004.
//

#import <Cocoa/Cocoa.h>
#import "AYTextView.h"
#import "TextEncoding.h"

@interface Messages : NSObject {
	IBOutlet id contentView ;
	NSDate *sessionStartDate ;

	NSTabView *controllingTabView ;
	NSTabViewItem *logTabItem ;
	TextAttribute *textAttribute ;
	NSTextView *logView ;
	
	NSMutableString *bufferedString ;
}

- (id)initIntoView:(NSTextView*)view ;

- (void)awakeFromApplication ;

+ (void)logMessage:(char*)format,... ;
+ (int)alertWithMessageText:(NSString*)msg informativeText:(NSString*)info ;
+ (void)appleScriptError:(NSDictionary*)dict script:(const char*)from ;
+ (void)alertWithHiraganaError ;

- (id)initIntoTabView:(NSTabView*)tabview ;
//- (void)msg:(char*)format,... ;
- (void)msg:(char*)format ;
- (void)show ;

@end
