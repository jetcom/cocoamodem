//
//  AMWaterfall.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/18/07.

#ifndef _AMWATERFALL_H_
	#define _AMWATERFALL_H_


	#include "Waterfall.h"

	@interface AMWaterfall : Waterfall {
		float fc ;
		float fl ;
		float fh ;
	}
	
	- (void)setTrack:(float)center low:(float)low high:(float)high ;
	- (void)setTrack:(float)center ;
	
	@end

#endif
