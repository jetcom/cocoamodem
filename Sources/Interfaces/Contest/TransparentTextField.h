//
//  TransparentTextField.h
//  cocoaModem
//
//  Created by Kok Chen on 11/23/04.
//

#ifndef _TRANSPARENTTEXTFIELD_H_
	#define _TRANSPARENTTEXTFIELD_H_

	#import <Cocoa/Cocoa.h>
	#include "ContestTextField.h"
	#include "cocoaModemParams.h"


	@interface TransparentTextField : ContestTextField {
		float ratio ;
		int fieldType ;
		NSString *savedString ;
		Boolean ignore ;
	}
	
	- (void)moveAbove ;
	- (void)setFieldType:(int)type ;
	- (int)fieldType ;
	- (void)markAsSelected:(Boolean)state ;
	- (NSString*)clickedString ;
	
	- (void)setIgnoreFirstResponder:(Boolean)state ;

	@end
#endif
