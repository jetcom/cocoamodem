//
//  StripPhi.h
//  cocoaModem
//
//  Created by Kok Chen on 12/5/04.
//

#ifndef _STRIPPHI_H_
	#define _STRIPPHI_H_

	#import <Cocoa/Cocoa.h>


	@interface StripPhi : NSObject {
		char buffer[128] ;
	}

	- (NSString*)asciiString:(NSString*)input ;
	- (NSString*)asciiCString:(char*)input  ;
	
	@end

#endif
