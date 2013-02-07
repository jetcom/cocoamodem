//
//  PTTHub.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/11/06.

#ifndef _PTTHUB_H_
	#define _PTTHUB_H_

	#import <Cocoa/Cocoa.h>
	#import "KeyerInterface.h"
	#import "DigitalInterfaces.h"
	
	#define	kVOXIndex			kVOXType
	#define	kCocoaPTTIndex		kCocoaPTTType
	#define	kMLDXIndex			kMLDXType
	#define kUserPTTIndex		kUserPTTType
	
	//#define	kDigiKeyerIndex		4
	//#define	kMicroKeyerIndex	5
	//#define	kCWKeyerIndex		6
	
	#define	kMicroKeyerGroup	4				//  v0.89		all microKeyers are now here

	// ---------------------------
	#define	kPTTItems			16				//  v0.89		allow 12 (!) microKeyers
		
	@class PTT ;
	@class Application ;
	

	@interface PTTHub : KeyerInterface {
		
		PTT *client[64] ;
		int clients ;
		
		Boolean exist[kPTTItems] ;
		Boolean missingAlertMessage[kPTTItems] ;
		Boolean pttEngaged ;
		
		Application *application ;
		DigitalInterfaces *digitalInterfaces ;
	}

	- (void)registerPTT:(PTT*)ptt ;
	
	- (void)microKeyerSetupArray:(int*)array count:(int)count useDigitalModeOnlyForFSK:(Boolean)state ;
	
	- (void)updateUserPTTScripts:(NSString*)newFolder ;
	
	- (void)missingPTT:(int)index name:(NSString*)name ;
	
	void sigpipe( int sigraised ) ;
	
	@end

#endif
