//
//  ExchangeView.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 08 2004.
//

#ifndef _EXCHANGEVIEW_H_
	#define _EXCHANGEVIEW_H_

	#import <Cocoa/Cocoa.h>
	#include "AYTextView.h"

	@interface ExchangeView : AYTextView {
		Boolean isRightMouse ;
		Boolean isMouseClick ;
		Boolean freeze ;
	}
	
	- (Boolean)getRightMouse ;
	- (Boolean)getAndClearRightMouse ;
	- (Boolean)getMouseClick ;
	- (Boolean)getAndClearMouseClick ;
	- (Boolean)getEitherMouse ;
	
	@end

#endif
