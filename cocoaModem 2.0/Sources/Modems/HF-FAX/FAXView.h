//
//  FAXView.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/27/06.

#ifndef _FAXVIEW_H_
	#define _FAXVIEW_H_

	#import <Cocoa/Cocoa.h>
	#import "FAXFrame.h"
	

	@interface FAXView : NSImageView {
		FAXFrame *faxFrame ;
		
		NSLock *dumpLock ;
		NSString *dumpName ;
		BackingFrame *dumpBackingFrame ;
		float ppm ;					//  A/D clock adjustment
 	}
	
	- (void)vmUse:(char*)title ;	//  testing use
	- (int)physicalMemory ;			//  testing use
	
	- (void)swapImageRep ;
	- (void)setPPM:(float)value ;
	- (float)ppm ;
	
	@end


#endif
