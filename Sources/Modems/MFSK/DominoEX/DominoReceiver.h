//
//  DominoReceiver.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/23/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "MFSKReceiver.h"


@interface DominoReceiver : MFSKReceiver {
	float actualSamplingRate ;
}

- (id)initAsMode:(int)mode ;

@end
