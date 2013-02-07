//
//  DataPipe.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/3/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "DataPipe.h"


@implementation DataPipe

enum PipeLockCondition {
	kNoPipeData,
	kHasPipeData
} ;

//  NSPipe is not completely ThreadSafe (it uses autorelease objects that could be relased in different threads).  
//	DataPipe attempts to create a simple thread safe data pipeline.

- (id)init
{
	return [ self initWithCapacity:512*sizeof(float) ] ;
}

//  Sets up the capacity of the pipe.
//	Upon a read, the pipe will block if there is insufficient data.
//	Upon a write, the pipe will wait for enough capacity to write all the data (or time out after 1 second).

- (id)initWithCapacity:(int)bytesCapacity
{
	self = [ super init ] ;
	if ( self ) {
		lock = [ [ NSConditionLock alloc ] initWithCondition:kNoPipeData ] ;
		if ( bytesCapacity < 512 ) bytesCapacity = 512 ;
		capacity = bytesCapacity ;	
		data = malloc( capacity ) ;	
		bytes = 0 ;	
		eof = NO ;
		timeout = 200 ;				//  retries (200*.005 = 2 secs)
		writeRetryTime = 0.005 ;	//  5 ms
	}
	return self ;
}

- (void)dealloc
{
	eof = YES ;
	[ lock release ] ;
	free( data ) ;
	[ super dealloc ] ;
}

//  Returns the number of bytes successfully written into the pipe.
//	If enough capacity is not released within 1 second, the write returns with a count of bytes it has successfuly written
- (int)write:(void*)buffer length:(int)requestBytes
{
	int availableForWriting, written, i, originalRequest ;

	//  Loop here waiting (NSThread sleep) if needed for a pipe that has reach capacity to drain
	//  Give up after "timeout" tries (defaulted to 200 counts, or 1 second)
	written = 0 ;
	originalRequest = requestBytes ;
	for ( i = 0; i < timeout; i++ ) {
		[ lock lock ] ;	//  uncondition lock to write data in
		//  received lock, attempt to write
		availableForWriting = capacity - bytes ;
		if ( availableForWriting < requestBytes ) {
			//  capacity overflow! 
			if ( availableForWriting > 0 ) {
				//  write as much as we can...
				memcpy( &data[bytes], buffer, availableForWriting ) ;
				requestBytes -= availableForWriting ;
				bytes += availableForWriting ;
				written += availableForWriting ;
				buffer = (void*)( (char*)buffer + availableForWriting ) ;
			}
			//  ... then give the read thread a chance to read
			[ lock unlockWithCondition:kHasPipeData ] ;
			//  sleep this thread for 5 ms before resume trying to write more
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:writeRetryTime ] ] ;
		}
		else {
			memcpy( &data[bytes], buffer, requestBytes ) ;
			bytes += requestBytes ;
			[ lock unlockWithCondition:kHasPipeData ] ;
			return originalRequest ;
		}
	}
	return written ;
}

- (Boolean)eof
{
	return eof ;
}

- (void)setEOF
{
	eof = YES ;
}

//  Returns byte count or -1 if EOF
//  Return if there is no data in the pipeline
- (int)readAvailableData:(void*)indata max:(int)maxBytes
{
	int copied ;
	
	if ( eof ) return -1 ;
	if ( maxBytes == 0 ) return 0 ;
	if ( bytes <= 0 ) return 0 ;
	
	[ lock lockWhenCondition:kHasPipeData ] ;

	copied = ( bytes > maxBytes ) ? maxBytes : bytes ;
	if ( copied <= 0 ) {
		//  some inconsistent error or client error (requesting 0 bytes) occured, but assume we have no data available
		[ lock unlockWithCondition:kNoPipeData ] ;
		return 0 ;
	}
	memcpy( indata, data, copied ) ;
	bytes -= copied ;
	if ( bytes > 0 ) {
		//  move remaining data to head of data buffer
		memcpy( data, &data[copied], bytes ) ;
		[ lock unlockWithCondition:kHasPipeData ] ;
		return copied ;
	}
	[ lock unlockWithCondition:kNoPipeData ] ;
	return copied ;
}

- (int)readData:(void*)buffer length:(int)requestBytes
{	
	int originalRequest ;
	
	if ( eof ) return -1 ;
	if ( requestBytes == 0 ) return 0 ;
	if ( requestBytes > capacity ) requestBytes = capacity ;

	originalRequest = requestBytes ;
	while ( 1 ) {
		[ lock lockWhenCondition:kHasPipeData ] ;
		if ( bytes < requestBytes ) {
			if ( bytes > 0 ) {
				memcpy( buffer, data, bytes ) ;
				requestBytes -= bytes ;
				buffer += bytes ;					//  v0.62
				bytes = 0 ;
				//  v0.61 bug  buffer += requestBytes ;
			}
			//  wait for more data to be collected before returning request
			[ lock unlockWithCondition:kNoPipeData ] ;
		}
		else {
			memcpy( buffer, data, requestBytes ) ;
			bytes -= requestBytes ;
			if ( bytes > 0 ) {
				// move remaining data to head of buffer
				memcpy( data, &data[requestBytes], bytes ) ;
				[ lock unlockWithCondition:kHasPipeData ] ;
				return originalRequest ;
			}
			[ lock unlockWithCondition:kNoPipeData ] ;
			return originalRequest ;
		}
	}
}

@end
