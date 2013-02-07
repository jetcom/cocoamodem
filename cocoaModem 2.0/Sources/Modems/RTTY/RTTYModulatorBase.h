//
//  RTTYModulatorBase.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/21/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "CMFSKModulator.h"

#define	ookMark				(2500*kPeriod/CMFs)


@interface RTTYModulatorBase : CMFSKModulator {
	int ook ;									//  v0.85
	Boolean ookAssert ;
		
	int currentBaudotCharacter ;				//  v0.88
}

- (void)initSetup ;
	
- (void)setOOK:(int)ookState invert:(Boolean)invertState ;			//  v0.85

@end
