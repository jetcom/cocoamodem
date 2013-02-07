//
//  DigitalInterfaces.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/17/11.
//  Copyright 2011 Kok Chen, W7AY. All rights reserved.
//

#import "DigitalInterface.h"
#import "Config.h"
#import "Router.h"

#define	kVOXType			0
#define	kCocoaPTTType		1
#define	kMLDXType			2
#define kUserPTTType		3
#define	kMicroHAMType		4

@class MicroKeyer ;


@interface DigitalInterfaces : NSObject {
	Router *router ;
	DigitalInterface *voxInterface ;
	DigitalInterface *cocoaPTTInterface ;
	DigitalInterface *userPTTInterface ;
	DigitalInterface *mldxInterface ;
	
	int numberOfDigiKeyers ;
	int numberOfDigiKeyerIIs ;
	int numberOfMicroKeyers ;
	int numberOfCWKeyers ;
}

- (id)initWithoutRouter ;

- (DigitalInterface*)voxInterface ;
- (DigitalInterface*)cocoaPTTInterface ;
- (DigitalInterface*)userPTTInterface ;
- (DigitalInterface*)macLoggerDX ;

- (NSArray*)microHAMKeyers ;
- (Router*)router ;

- (MicroKeyer*)microKeyer ;
- (MicroKeyer*)digiKeyer ;
- (MicroKeyer*)cwKeyer ;

- (void)useDigitalModeOnlyForFSK:(Boolean)state ;
- (int)numberOfDigiKeyers ;
- (int)numberOfDigiKeyerIIs ;
- (int)numberOfMicroKeyers ;
- (int)numberOfCWKeyers ;

- (void)terminate:(Config*)config ;


@end
