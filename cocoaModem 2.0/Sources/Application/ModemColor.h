//
//  ModemColor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/27/05.

#ifndef _MODEMCOLOR_H_
	#define	_MODEMCOLOR_H_

	#import <Cocoa/Cocoa.h>


	@interface ModemColor : NSColorWell {
		id delegate ;
	}

	- (id)delegate ;
	- (void)setDelegate:(id)client ;
	
	// delegate
	- (void)colorChanged:(NSColorWell*)client ;

	@end

#endif
