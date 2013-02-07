//
//  splash.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Jun 24 2004.
//

#ifndef _SPLASH_H_
	#define _SPLASH_H_

	#import <Cocoa/Cocoa.h>

	@interface splash : NSObject {
		IBOutlet id splashScreen ;
		IBOutlet id splashMsg ;
		Boolean active ;
	}

	- (void)positionWindow ;
	- (void)showMessage:(NSString*)msg ;
	- (void)remove ;
	
	@end

#endif
