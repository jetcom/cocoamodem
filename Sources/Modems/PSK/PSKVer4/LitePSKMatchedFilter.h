//
//  LitePSKMatchedFilter.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/19/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PSKMatchedFilter.h"

@class LitePSKDemodulator ;

@interface LitePSKMatchedFilter : PSKMatchedFilter {
	LitePSKDemodulator *demodulator ;
	Boolean printEnable ;
}

- (id)initWithClient:(LitePSKDemodulator*)client ;
- (void)setPrintEnable:(Boolean)state ;

@end
