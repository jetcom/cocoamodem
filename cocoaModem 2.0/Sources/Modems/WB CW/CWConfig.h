//
//  CWConfig.h
//  cocoaModem
//
//  Created by Kok Chen on Dec 1 06.
//

#ifndef _CWCONFIG_H_
	#define _CWCONFIG_H_

	#import "WFRTTYConfig.h"
	
	@interface  CWConfig : WFRTTYConfig {	
	}
	
	
	- (void)setCWKeyerMode:(int)tag ptt:(PTT*)ptt ;

	@end

#endif
