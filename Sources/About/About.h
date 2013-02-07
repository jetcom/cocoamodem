//
//  About.h
//  cocoaCCD
//
//  Created by Kok Chen on Wed May 12 2004.
//

#ifndef _ABOUT_H_
	#define _ABOUT_H_

	#import <Cocoa/Cocoa.h>

	@interface About : NSObject {
		IBOutlet id window ;
	}

	- (id)initFromNib ;
	- (void)showPanel ;
	
	@end

#endif
