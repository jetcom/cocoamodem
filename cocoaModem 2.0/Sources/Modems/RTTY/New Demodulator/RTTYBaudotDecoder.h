//
//  RTTYBaudotDecoder.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/21/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "CMBaudotDecoder.h"


@interface RTTYBaudotDecoder : CMBaudotDecoder {
	Boolean printControl ;
}

- (void)setPrintControl:(Boolean)state ;

@end
