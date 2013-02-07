//
//  FSK.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/12/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "DigitalInterfaces.h"

@class RTTY ;
@class FSKHub ;

typedef struct {
	MicroKeyer *keyer ;
	int type ;
	Boolean enabled ;
} Interfaces ;

#define	kSeparatorType	0
#define	kAFSKType		1
#define	kBadType		2
#define	kFSKType		3
#define	kOOKType		4
#define	kPFSKType		5


@interface FSK : NSObject {	
	RTTY *modem ;
	NSPopUpButton *menu ;
	Interfaces interfaces[32] ;
	int types[16] ;
	FSKHub *hub ;
	int selectedPort ;
}

- (id)initWithHub:(FSKHub*)fskHub menu:(NSPopUpButton*)fskMenu modem:(RTTY*)client ;
- (BOOL)validateAfskMenuItem:(NSMenuItem*)item ;

- (int)fskPortForName:(NSString*)title ;
- (int)controlPortForName:(NSString*)title ;
- (Boolean)checkAvailability:(NSString*)title ;

- (int)selectedFSKPort ;
- (int)useSelectedPort ;

- (void)setKeyerMode:(int)mode controlPort:(int)port ;	//  v0.87
- (void)setUSOS:(Boolean)state ;						//  v0.84

//  FSK data streams
- (void)startSampling:(float)baudrate invert:(Boolean)invertTx stopBits:(int)stopIndex ;
- (void)stopSampling ;
- (void)clearOutput ;
- (void)appendASCII:(int)ascii ;

@end
