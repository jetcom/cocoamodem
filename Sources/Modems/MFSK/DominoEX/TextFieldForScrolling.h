//
//  TextFieldForScrolling.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/24/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface TextFieldForScrolling : NSTextField {
	Boolean paused ;
}

- (void)setPaused:(Boolean)state ;

@end
