//
//  ModemSleepManager.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/10/06.
	#include "Copyright.h"
	
	
#import "ModemSleepManager.h"


@implementation ModemSleepManager

- (id)initWithApplication:(Application*)app
{
	self = [ super init ] ;
	if ( self ) {
		client = app ;
	}
	return self ;
}

- (void)allowSleep:(long)message
{
	//  allows system to sleep
	IOCancelPowerChange( powerManager,(long)message ) ;
}

- (void)aboutToSleep:(long)message
{
	//  note, we cannot cancel sleep from a here
	[ client putCodecsToSleep ] ;
	[ super aboutToSleep:message ] ;
}

- (void)wakingFromSleep
{
	//  wake up everybody that were put to sleep
	[ client wakeCodecsUp ] ;
}

@end
