//
//  Module.h
//  cocoaModem
//
//  Created by Kok Chen on 9/3/05.
//

#ifndef _MODULE_H_
	#define _MODULE_H_

	#import <Cocoa/Cocoa.h>
	
	@class Modem ;
	@class Transceiver ;
	
	#define	BUFMASK	0xfff
	#define BUFSIZE	(BUFMASK+1)

	@interface Module : NSObject {
		Transceiver *parent ;
		Modem *modem ;
		Boolean isReceiver ;
		int index ;
		
		//  text buffer
		NSLock *ptr ;
		long producer, consumer ;
		char buffer[BUFSIZE] ;
	}

	- (id)initWithTransceiver:(Transceiver*)xcvr receiver:(Boolean)isReceiver index:(int)index ;
	- (Boolean)isReceiver ;
	- (Transceiver*)transceiver ;
	
	- (void)insertBuffer:(int)character ;
	- (void)setCStream:(char*)text ;
	
	//  AppleScript properties
	- (float)frequency ;
	- (void)setFrequency:(float)f ;
	- (void)setReplay:(float)timeOffset ;
	- (float)mark ;
	- (void)setMark:(float)f ;
	- (float)space ;
	- (void)setSpace:(float)f ;
	- (float)baud ;
	- (void)setBaud:(float)f ;
	- (Boolean)invert ;
	- (void)setInvert:(Boolean)state ;
	- (Boolean)breakin ;
	- (void)setBreakin:(Boolean)state ;
	
	- (NSString*)stream ;
	- (void)setStream:(NSString*)text ;
	
	- (NSString*)spectrum ;		//  v0.64c
	- (int)nextSpectrum ;		//  v0.64c
	
	//  AppleScript commands
	- (void)flushText:(NSScriptCommand*)command ;
	
	@end

#endif
