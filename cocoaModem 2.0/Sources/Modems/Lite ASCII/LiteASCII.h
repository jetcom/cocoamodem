//
//  LiteASCII.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/31/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCII.h"


@interface LiteASCII : ASCII {
	IBOutlet id txLockButton ;
	IBOutlet id oscilloscope ;
	Boolean controlWindowOpen ;
}

- (void)drawSpectrum:(CMPipe*)pipe ;
- (void)changeMarkersInSpectrum:(RTTYRxControl*)inControl ;


@end
