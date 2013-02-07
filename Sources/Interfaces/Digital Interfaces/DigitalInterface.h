//
//  DigitalInterface.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/16/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppleScriptSupport.h"

@interface DigitalInterface : AppleScriptSupport {
	NSString *name ;
	Boolean hasPTT ;
	Boolean connected ;
	int type ;
}

- (id)initWithName:(NSString*)vname ;
- (NSString*)name ;
- (int)type ;
- (Boolean)connected ;

- (Boolean)hasPTT ;
- (void)setPTTState:(Boolean)state ;

- (Boolean)hasFSK ;
- (Boolean)hasOOK ;

- (void)closeConnection ;


@end
