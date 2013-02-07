//
//  CMBandpassFilter.h
//  Filter (CoreModem)
//
//  Created by Kok Chen on 10/24/05
//

#ifndef _CMBANDPASSFILTER_H_
	#define _CMBANDPASSFILTER_H_

	#import <Cocoa/Cocoa.h>
	#import "CMFilter.h"

	@interface CMBandpassFilter : CMFilter {
		float lowCutoff ;
		float highCutoff ;
	}

	- (id)initLowCutoff:(float)low highCutoff:(float)high length:(int)len ;
	
	- (void)setLowCutoff:(float)low highCutoff:(float)high length:(int)n ;
	- (void)updateLowCutoff:(float)low highCutoff:(float)high ;
	
	@end

#endif
