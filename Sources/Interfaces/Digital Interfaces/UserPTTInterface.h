//
//  UserPTTInterface.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "DigitalInterfaces.h"


@interface UserPTTInterface : DigitalInterface {
	NSAppleScript *keyScript, *unkeyScript, *quitScript ;
}

- (Boolean)updateScriptsFromFolder:(NSString*)newfolder ;

@end
