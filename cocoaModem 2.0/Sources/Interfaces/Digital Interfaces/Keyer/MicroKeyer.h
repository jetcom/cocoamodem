//
//  MicroKeyer.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/1/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "DigitalInterfaces.h"


@interface MicroKeyer : DigitalInterface {
	char keyerID[16] ;
	int pttWriteDescriptor ;
	int controlWriteDescriptor ;
	int	readFileDescriptor, writeFileDescriptor ;
	int fskWriteDescriptor ;
	int flagsReadDescriptor ;
	Boolean newStyle ;
	Boolean useDigitalModeForFSK ;
}

- (id)initWithKeyerID:(char*)kid ;
- (id)initWithReadFileDescriptor:(int)keyerReadFileDescriptor writeFileDescriptor:(int)keyerWriteFileDescriptor serialNumber:(char*)dummySerial ;

- (int)flagsReadDescriptor ;
- (int)fskWriteDescriptor ;
- (int)controlWriteDescriptor ;
- (int)pttWriteDescriptor ;

- (char*)keyerID ;
- (NSString*)keyerTypeString ;

- (void)setKeyerMode:(int)mode ;
- (void)useDigitalModeForFSK:(Boolean)state ;
- (Boolean)hasQCW ;

- (void)selectForFSK ;

- (Boolean)isMicroKeyer ;
- (Boolean)isMicroKeyerI ;
- (Boolean)isMicroKeyerII ;
- (Boolean)isDigiKeyer ;
- (Boolean)isDigiKeyerI ;
- (Boolean)isDigiKeyerII ;
- (Boolean)isCWKeyer ;


@end
