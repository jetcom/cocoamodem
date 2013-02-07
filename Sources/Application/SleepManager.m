//
//  SleepManager.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/10/06.
	#include "Copyright.h"

#import "SleepManager.h"
#import <IOKit/IOMessage.h>


@implementation SleepManager

//  Base class for a generic power manager
//  Subclasses can override the messages -aboutToSleep: -allowSleep: and wakingFromSleep

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		//  accepts sleep and wakeup notifications from the power manager
		powerManager = IORegisterForSystemPower( self, &notifyPort, powerManagerCallback, &notifier ) ;
		if ( powerManager ) {
			CFRunLoopAddSource( CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPort), kCFRunLoopCommonModes ) ;
		}
	}
	return self ;
}

- (void)dealloc
{
	if ( powerManager ) {
		CFRunLoopRemoveSource( CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notifyPort), kCFRunLoopCommonModes ) ;
		IODeregisterForSystemPower( &notifier ) ;
		IOServiceClose( powerManager ) ;
		IONotificationPortDestroy( notifyPort ) ;
	}
	[ super dealloc ] ;
}

void powerManagerCallback( void *refcon, io_service_t service, natural_t messageType, void *message )
{
	SleepManager *ourself = (SleepManager*)refcon ;
	
	switch ( messageType ) {
	case kIOMessageSystemWillSleep:
		[ ourself aboutToSleep:(long)message ] ;
		break;
	case kIOMessageCanSystemSleep:
		[ ourself allowSleep:(long)message ] ;
		break;
	case kIOMessageSystemHasPoweredOn:
		[ ourself wakingFromSleep ] ;
		break;
    }
}

//  -------------------------------------------------------------------------
//  Local PowerManager support (for sleep and wakeups)
//	Override these in subclasses to do something useful

- (void)aboutToSleep:(long)message
{
	//  sleep any task that need to nap and sends allows power change
	IOAllowPowerChange( powerManager,(long)message ) ;
}

- (void)allowSleep:(long)message
{
	//  allows system to sleep
	IOAllowPowerChange( powerManager,(long)message ) ;
}

- (void)wakingFromSleep
{
	//  wake up tasks that were put to sleep
}


@end
