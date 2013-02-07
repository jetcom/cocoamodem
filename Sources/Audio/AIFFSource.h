//
//  AIFFSource.h
//  AudioInterface
//
//  Created by Kok Chen on 11/06/05

#import <Cocoa/Cocoa.h>
#include "CoreFilter.h"
#include "AudioInterfaceTypes.h"

@interface AIFFSource : CMTappedPipe {
	float storage[1024] ;	//  handle stereo 512-sample channels
	AudioSoundFile soundFile ;
}

//  sound file
- (NSString*)openSoundFileWithTypes:(NSArray*)fileType ;
- (Boolean)soundFileActive ;
- (void)stopSoundFile ;	
- (void)setFileRepeat:(Boolean)doRepeat ;
- (int)soundFileStride ;

- (float)samplingRate ;
- (void)setSamplingRate:(float)samplingRate ;

- (void)importData:(CMPipe*)pipe offset:(int)offset ;
- (Boolean)insertNextFileFrameWithOffset:(int)offset ;
- (Boolean)insertNextStereoFileFrame ;

@end
