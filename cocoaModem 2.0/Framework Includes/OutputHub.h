//
//  OutputHub.h
//  AudioInterface
//
//  Created by Kok Chen on 11/06/05
//	Ported from cocoaModem, original file dated Wed Jul 28 2004.
//

#ifndef _OUTPUTHUB_H_
	#define _OUTPUTHUB_H_

	#import <AudioInterface/AudioHub.h>
	
	@class AudioOutputPort ;
	
	@interface OutputHub : AudioHub {
	}
	
	- (AudioOutputPort*)createPort:(int)deviceNumber destination:(int)dest ;
	@end

#endif
