//
//  KeyerInterface.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/11/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#ifndef _KEYERINTERFACE_H_
	#define _KEYERINTERFACE_H_

	#import <Cocoa/Cocoa.h>
	#import "AppleScriptSupport.h"
	#import "Router.h"
	#import "MicroKeyer.h"
	
	// base class for PTTHub.m and FSKHub.m to provide linkage to Router.m (µH Router)
	
	typedef struct {
		MicroKeyer *keyer ;
		int controlPort ;
		//  FSK
		int fskPort ;
		int flagsPort ;
		int currentBaudConstant ;
		int currentTxInvert ;
		int currentStopIndex ;		
		//  PTT
		int pttPort ;
	} MicroHamKeyerCache ;
	
	@interface KeyerInterface : AppleScriptSupport {
		//  µH Router
		MicroKeyer *selectedMicroKeyer ;
		Router *router ;
		MicroHamKeyerCache microKeyerCache[16] ;
		int activeKeyers ;
	}

	- (void)setKeyerMode:(int)mode controlPort:(int)port ;		//  v0.87

	
	void obtainRouterPorts( int *readFileDescriptor, int *writeFileDescriptor, int type, int parentReadFileDescriptor, int parentWriteFileDescriptor ) ;
	
	void obtainKeyerPortsFromKeyerID( int *readFileDescriptor, int *writeFileDescriptor, char *keyerID, int parentReadFileDescriptor, int parentWriteFileDescriptor ) ; //  v0.89

		
	@end

#endif
