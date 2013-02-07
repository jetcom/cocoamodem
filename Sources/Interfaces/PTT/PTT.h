//
//  PTT.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/11/06.

#import <Cocoa/Cocoa.h>
#import "DigitalInterfaces.h"
#import "PTTHub.h"

@interface PTT : NSObject {
	PTTHub *hub ;
	NSPopUpButton *menu ;
	DigitalInterface *interfaces[32] ;
	NSMutableArray *dummyInterfaces ;
}

- (id)initWithHub:(PTTHub*)inhub menu:(NSPopUpButton*)inMenu ;
- (void)executePTT:(Boolean)state ;

- (void)updateUserPTTName:(NSString*)name ;

- (void)selectItem:(NSString*)pttName ;
- (NSString*)selectedItem ;

- (Boolean)hasQCW ;
- (void)setKeyerMode:(int)mode ;		//  v0.87

- (void)applicationTerminating ;		//  v0.89

@end
