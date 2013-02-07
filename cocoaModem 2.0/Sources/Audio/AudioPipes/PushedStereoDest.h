//
//  PushedStereoDest.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/1/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ModemDest.h"


@interface PushedStereoDest : ModemDest {
}

- (id)initIntoView:(NSView*)view device:(NSString*)name level:(NSView*)level client:(DestClient*)inClient ;

@end
