//
//  DisplayColor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/1/06.

#ifndef _DISPLAYCOLOR_H_
	#define _DISPLAYCOLOR_H_

	#import <Cocoa/Cocoa.h>

	@interface DisplayColor : NSObject {
	}
	
	+ (UInt32)millionsOfColorsFromRed:(float)r green:(float)g blue:(float)b ;
	+ (UInt32)thousandsOfColorsFromRed:(float)r green:(float)g blue:(float)b ;
	

	@end
#endif
