//
//  SendView.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 08 2004.
//

#ifndef _SENDVIEW_H_
	#define _SENDVIEW_H_

	#import <Cocoa/Cocoa.h>
	#include "AYTextView.h"

	@interface SendView : AYTextView {
	}

	- (void)deleteFromEnd:(NSEvent*)event ;
	
	@end

#endif
