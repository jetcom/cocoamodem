//
//  ModemSleepManager.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/10/06.

#ifndef _MODEMSLEEPMANAGER_H_
	#define _MODEMSLEEPMANAGER_H_

	#include "SleepManager.h"
	#include "Application.h"

	@interface ModemSleepManager : SleepManager {
		Application *client ;		
	}

	- (id)initWithApplication:(Application*)app ;
	
	@end
	
#endif

