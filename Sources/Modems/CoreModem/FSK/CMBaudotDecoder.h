//
//  CMBaudotDecoder.h
//  CoreModem
//
//  Created by Kok Chen on 10/24/05.
//	(ported from cocoaModem, original file dated 2/4/05)
//

#ifndef _BAUDOTDECODER_H_
	#define _BAUDOTDECODER_H_

	#import <Cocoa/Cocoa.h>
	#include "CMPipe.h"
	
	@class CMFSKDemodulator ;

	@interface CMBaudotDecoder : CMPipe {
		CMFSKDemodulator *demodulator ;
		//  decoder states
		Boolean bell ;
		Boolean cr ;
		Boolean lf ;
		Boolean usos ;
		char *encoding ;
	}
	
	- (id)initWithDemodulator:(CMFSKDemodulator*)rx ;
	- (void)setUSOS:(Boolean)state ;
	- (void)setBell:(Boolean)state ;
	- (void)setLTRS ;

	@end

#endif
