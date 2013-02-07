//
//  SleepManager.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/10/06.

#ifndef _SLEEPMANAGER_H_
	#define	_SLEEPMANAGER_H_

	#import <Cocoa/Cocoa.h>
	#include "ModemManager.h"


	@interface SleepManager : NSObject {
		io_connect_t powerManager ;
		IONotificationPortRef notifyPort ;
		io_object_t	notifier ;
	}
	
	void powerManagerCallback( void *refcon, io_service_t service, natural_t messageType, void *message ) ;
	
	- (void)aboutToSleep:(long)message ;
	- (void)allowSleep:(long)message ;
	- (void)wakingFromSleep ;

	
	@end

#endif
