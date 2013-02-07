//
//  Transceiver.h
//  cocoaModem
//
//  Created by Kok Chen on 9/4/05.
//

#ifndef _TRANSCEIVER_H_
	#define _TRANSCEIVER_H_

	#import <Cocoa/Cocoa.h>
	
	@class Modem ;
	@class Module ;

	@interface Transceiver : NSObject {
		Modem *modem ;
		Module *transmitter ;
		Module *receiver ;
		int index ;
	}
	- (id)initWithModem:(Modem*)parent index:(int)inIndex ;
	- (Modem*)modem ;
	- (Module*)transmitter ;
	- (Module*)receiver ;
	
	//  AppleScript properties
	- (Boolean)enable ;
	- (void)setEnable:(Boolean)sense ;

	- (int)state ;
	- (void)setState:(int)code ;
	
	- (int)modulation ;
	- (void)setModulation:(int)code ;
	
	// deprecated
	- (NSString*)getStream ;
	- (void)sendStream:(char*)text ;
	
	@end

#endif
