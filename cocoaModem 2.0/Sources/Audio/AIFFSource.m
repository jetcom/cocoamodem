//
//  AIFFSource.m
//  AudioInterface
//
//  Created by Kok Chen on 11/06/05
//	Ported from cocoaModem; file originally dated 1/21/05.
	#include "Copyright.h"
//

#import "AIFFSource.h"

@implementation AIFFSource

//  Allows data to be inserted from an AIFF or WAV file instead of the usual stream.
//  data is imported into AIFFSource through three means
//
//  -insertNextFileFrameWithOffset		: send next frame from file (with mono channel offset)
//  -insertNextStereoFileFrame			: send next stereo file frame to destination
//  -importData							: relays stream data to destination if file not active
//  
//  destination is an CMPipe

- (id)pipeWithClient:(CMPipe*)inClient
{
	self = [ super pipeWithClient:inClient ] ;
	if ( self ) {
		data->samplingRate = 11025.0 ;
		data->array = &storage[0] ;
		data->components = 1 ;
		data->channels = 1 ;
		// soundFile
		soundFile.ID = 0 ;
		soundFile.active = NO ;
		soundFile.repeatFile = YES ;
		soundFile.stride = 1 ;
	}
	return self ;
}

- (float)samplingRate
{
	return soundFile.basicDescription.mSampleRate ;
}

- (void)setSamplingRate:(float)samplingRate
{
	data->samplingRate = samplingRate ;
}

- (void)setFileRepeat:(Boolean)doRepeat
{
	soundFile.repeatFile = doRepeat ;
}

- (int)soundFileStride
{
	return soundFile.stride ;
}

- (Boolean)soundFileActive
{
	return soundFile.active ;
}

- (void)stopSoundFile
{
	soundFile.active = NO ;
	if ( soundFile.ID ) AudioFileClose( soundFile.ID ) ;
	soundFile.ID = 0 ;
}

//  fill in AudioStramBasicProperty, etc
static void GetSoundFileProperty( AudioSoundFile *s )
{
	UInt32 size ;
	OSErr err ;
	AudioStreamBasicDescription *b ;

	size = 4 ;
	AudioFileGetProperty( s->ID, kAudioFilePropertyFileFormat, &size, &s->fileFormat ) ;
	size = 8 ;
	AudioFileGetProperty( s->ID, kAudioFilePropertyAudioDataByteCount, &size, &s->bytes ) ;
	size = sizeof( AudioStreamBasicDescription ) ;
	b = &s->basicDescription ;
	err = AudioFileGetProperty( s->ID, kAudioFilePropertyDataFormat, &size, b ) ;
		
	if ( err == noErr ) {
		s->sampleSize = b->mBytesPerFrame/b->mChannelsPerFrame ;
		s->stride = b->mBytesPerFrame/s->sampleSize ;
		s->samples = s->bytes/( s->stride*s->sampleSize ) ;
		s->isBigEndian = ( b->mFormatFlags & kLinearPCMFormatFlagIsBigEndian ) != 0 ;
		s->isSigned = ( b->mFormatFlags & kLinearPCMFormatFlagIsSignedInteger ) != 0 ;
	}
}

//  return nil if user aborted, else path string
- (NSString*)openSoundFileWithTypes:(NSArray*)fileTypes
{
	NSOpenPanel *open ;
	NSString *path ;
	FSRef ref ;
	int result ;
	OSErr err ;

	if ( soundFile.active ) [ self stopSoundFile ] ;

	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
	
	result = [ open runModalForDirectory:nil file:nil types:fileTypes ] ;
	if ( result == NSOKButton ) {
		path = [ [ open filenames ] objectAtIndex:0 ] ;
		//  now make an FSref
		if ( FSPathMakeRef ( (unsigned char*)[ path fileSystemRepresentation ], &ref, nil ) == noErr ) {
			err = AudioFileOpen( &ref, fsRdWrPerm, 0, &soundFile.ID ) ;
			if ( err == noErr ) {
				GetSoundFileProperty( &soundFile ) ;
				soundFile.currentSample = 0 ;
				soundFile.active = YES ;
			}
		}
		return path ;
	}
	return nil ;
}

/* local */
- (void)fetchDataFromFile:(AudioSoundFile*)s channel:(int)offset bufferOffset:(int)bufferOffset
{
	int i, w, stride, skip ;
	short *u, t ;
	char *b ;
	unsigned char *c ;
	unsigned short *v ;
	float gain, *buffer ;
	
	stride = s->stride ;
	buffer = &storage[bufferOffset] ;
	
	if ( s->sampleSize == 1 ) {  /* 8-bit data */
		gain = 1./128.0 ;
		if ( s->isSigned ) {
			b = s->buf.b + offset ;
			for ( i = 0; i < 512; i++ ) {
				buffer[i] = *b*gain ;
				b += stride ;
			}
		}
		else {
			c = ( unsigned char*)( s->buf.b + offset ) ;
			for ( i = 0; i < 512; i++ ) {
				buffer[i] = *c*gain - 1.0 ;
				c += stride ;
			}
		}
	}
	else {	/* 16-bit data, sampleSize > 1 */
		gain = 1.0/32768.0 ;
		
		#if __BIG_ENDIAN__
		if ( s->isBigEndian ) {
			if ( s->isSigned ) {
				u = s->buf.u + offset ;
				for ( i = 0; i < 512; i++ ) {
					buffer[i] = *u*gain ;
					u += stride ;
				}
			}
			else {
				v = (unsigned short *)( s->buf.u + offset ) ;
				for ( i = 0; i < 512; i++ ) {
					buffer[i] = *v*gain - 1.0 ;
					v += stride ;
				}
			}
		}
		else {
			skip = stride*2 ;
			if ( s->isSigned ) {
				c = ( unsigned char* )s->buf.b + offset*2 ;
				for ( i = 0; i < 512; i++ ) {
					//  swap for little endian
					t = c[0] | ( c[1] << 8 ) ;
					buffer[i] = t*gain ;
					c += skip ;
				}
			}
			else {
				c = ( unsigned char* )s->buf.b + offset*2 ;
				for ( i = 0; i < 512; i++ ) {
					//  swap for little endian
					w = c[0] | ( c[1] << 8 ) ;
					buffer[i] = w*gain - 1.0 ;
					c += skip ;
				}
			}
		}
		#else /*LITTLE_ENDIAN */

		if ( !s->isBigEndian ) {
			if ( s->isSigned ) {
				u = s->buf.u + offset ;
				for ( i = 0; i < 512; i++ ) {
					buffer[i] = *u*gain ;
					u += stride ;
				}
			}
			else {
				v = (unsigned short *)( s->buf.u + offset ) ;
				for ( i = 0; i < 512; i++ ) {
					buffer[i] = *v*gain - 1.0 ;
					v += stride ;
				}
			}
		}
		else {
			skip = stride*2 ;
			if ( s->isSigned ) {
				c = ( unsigned char* )s->buf.b + offset*2 ;
				for ( i = 0; i < 512; i++ ) {
					//  swap for little endian
					t = ( c[0] << 8 ) | c[1] ;
					buffer[i] = t*gain ;
					c += skip ;
				}
			}
			else {
				c = ( unsigned char* )s->buf.b + offset*2 ;
				for ( i = 0; i < 512; i++ ) {
					//  swap for little endian
					w = ( c[0] << 8 ) | c[1] ;
					buffer[i] = w*gain - 1.0 ;
					c += skip ;
				}
			}
		}
		#endif
	}
}

//  fetch next 512 samples from AudioSoundFile and insert into CMPipe
//  return true if ended
- (Boolean)insertNextFileFrameWithOffset:(int)offset
{
	int status ;
	UInt32 bytes ;

	if ( ( soundFile.currentSample+512 ) > soundFile.samples ) {
		// EOF reached
		if ( !soundFile.repeatFile ) {
			AudioFileClose( soundFile.ID ) ;
			return YES ;
		}
		//  repeat file at beginning
		soundFile.currentSample = 0 ;
	}
	bytes =soundFile.stride*soundFile.sampleSize*512 ;	
	status = AudioFileReadBytes( soundFile.ID, YES, soundFile.currentSample*soundFile.sampleSize, &bytes, soundFile.buf.u ) ;
	if ( status != 0 ) return YES ;

	//  extract data and send to client 
	[ self fetchDataFromFile:&soundFile channel:offset bufferOffset:0 ] ;
	soundFile.currentSample += soundFile.stride*512 ;
	data->array = &storage[0] ;
	data->samples = 512 ;
	data->channels = 1 ;
	[ self exportData ] ;
	return NO ;
}
	
//  fetch next 512 stereo samples from AudioSoundFile and insert into CMPipe
//  truncate and return true if end reached
- (Boolean)insertNextStereoFileFrame
{
	int status ;
	UInt32 bytes ;

	bytes = soundFile.stride*soundFile.sampleSize*512 ;	
	if ( ( soundFile.currentSample+512 ) > soundFile.samples ) {
		// EOF reached
		if ( !soundFile.repeatFile ) {
			[ self stopSoundFile ] ;
			return YES ;
		}
		//  repeat file
		soundFile.currentSample = 0 ;
	}
	status = AudioFileReadBytes( soundFile.ID, YES, soundFile.currentSample*soundFile.sampleSize, &bytes, soundFile.buf.u ) ;
	if ( status != 0 ) return YES ;
	
	//  extract and create "split complex" data and export to client 
	[ self fetchDataFromFile:&soundFile channel:0 bufferOffset:0 ] ;
	if ( soundFile.stride == 1 ) {
		//  file is mono, duplicate the same mono channel of file into the output right channel
		[ self fetchDataFromFile:&soundFile channel:0 bufferOffset:512 ] ;
	}
	else {
		//  file has more than one channel, fetch from second channel
		[ self fetchDataFromFile:&soundFile channel:1 bufferOffset:512 ] ;
	}
	soundFile.currentSample += soundFile.stride*512 ;
	data->array = &storage[0] ;
	data->samples = 512 ;
	data->channels = 2 ; // "split complex" channels
	[ self exportData ] ;
	return NO ;
}

//  export imported data, but offsetting to the appropiate channel if it exist
- (void)importData:(CMPipe*)inpipe offset:(int)offset
{
	if ( soundFile.active ) return ;
	
	*data = *[ inpipe stream ] ;

	if ( offset < 2 ) {
		if ( data->channels != 1 ) {
			data->channels = 1 ;
			if ( offset != 0 ) data->array += data->samples ;
		}
	}
	[ self exportData ] ;
}

@end
