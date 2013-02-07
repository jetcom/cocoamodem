//
//  FSKHub.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/11/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#ifndef _FSKHUB_H_
	#define _FSKHUB_H_

	#import "PTTHub.h"
	#import "KeyerInterface.h"
	#import "MicroKeyer.h"
	#import "RTTY.h"


	#define	kDigiKeyerFSKIndex		0
	#define	kMicroKeyerFSKIndex		1

	typedef enum _FSKShiftState {
		kLTRSshift = 0,
		kFIGSshift
	} FSKShiftState ;
	
	#define	LTRSMASK	0x100 
	#define	FIGSMASK	0x200
	
	@interface FSKHub : KeyerInterface {
		//  µH Router
		Boolean fskBusy ;
		
		int currentFd ;
		FSKShiftState shift ;
		//  the following are for polling flags channel
		fd_set selectSet ;
		fd_set readSet ;
		unsigned char tempBuffer[64] ;

		int selectCount ;
		Boolean closed ;
		Boolean running ;
		RTTY *modem ;
		Boolean usos ;
		
		// ring buffer
		unsigned char fskBuffer[4096] ;							//  ascii ring buffer
		int producer, consumer ;
		int baudot[256] ;
		
		int currentBaudotCharacter ;
		Boolean robust ;										//  v0.88 USOS "compatibility mode"
		Boolean spaceFollowedFIGS ;								//  use robust mode to force compatibility of figs followed by space
		int implicitState ;
		int robustCount ;
	}
	
	- (int)currentBaudotCharacter ;								//  v0.88 feedback to aural monitor
	- (void)setRobustMode:(Boolean)state ;						//  v0.88 USOS "compatibility mode"
	
	- (void)setCurrentBaudotCharacter:(int)c ;

	- (void)closeFSKConnections ;
	
	- (void)setUSOS:(Boolean)state ;							//  v0.84
	
	//  returns port number, or 0 if not available
	- (int)digiKeyerFSKPort ;
	- (int)microKeyerFSKPort ;
	
	//  streams
	- (void)startSampling:(int)fd baudRate:(float)baudRate invert:(Boolean)invertTx stopBits:(int)stopIndex modem:(RTTY*)inModem ;
	- (void)stopSampling ;
	- (void)clearOutput ;
	
	- (void)appendASCII:(int)ascii ;
	
	@end

#endif
