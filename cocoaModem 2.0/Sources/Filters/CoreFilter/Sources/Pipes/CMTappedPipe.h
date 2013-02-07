//
//  CMTappedPipe.h
//   Filter (CoreModem)
//
//  Created by Kok Chen on 10/30/05.

#ifndef _CMTAPPEDPIPE_H_
	#define _CMTAPPEDPIPE_H_

	#include "CMPipe.h"
	
	@interface CMTappedPipe : CMPipe {
		CMPipe *tapClient ;
	}
	
	//  Returns the secondary CMPipe object which this CMPipe sends data to
	- (CMPipe*)tap ;

	//	Sets the the secondary CMPipe client, if any (usually used for scope taps)
	- (void)setTap:(CMPipe*)tap ;

	@end

#endif
