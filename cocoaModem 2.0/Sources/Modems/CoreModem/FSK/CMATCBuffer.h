//
//  CMATCBuffer.h
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Sat Aug 07 2004)
//

#ifndef _CMATCBUFFER_H_
	#define _CMATCBUFFER_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "CMATCTypes.h"
	

	@interface CMATCBuffer : CMTappedPipe {
		float buf[512] ;
		int mux ;
	}

	- (void)atcData:(CMATCStream*)data ;
	
	@end

#endif
