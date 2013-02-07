//
//  MorseDecoder.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/2/06.


#ifndef _MORESEDECODER_H_
	#define _MORESEDECODER_H_

	#import "CMBaudotDecoder.h"


	@interface MorseDecoder : CMBaudotDecoder {
	}

	- (void)newCharacter:(char*)string length:(int)length wordSpacing:(int)spacing ;

	@end

#endif
