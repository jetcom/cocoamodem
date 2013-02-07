//
//  NamedFIFO.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/15/06.
	#include "Copyright.h"
	
	
#import "NamedFIFO.h"


//  implementation of a Unix named FIFO for doing read() and write() operations

@implementation NamedFIFO

- (id)initWithPipeName:(const char*)fifoName
{
	int n ;
	
	self = [ super init ] ;
	if ( self ) {
	
		n = strlen( fifoName ) ;
		name = (char*)malloc( n+32 ) ;
		if ( name ) {
			strcpy( name, fifoName ) ;
			strcat( name, "-XXXXXX" ) ;
			mktemp( name ) ;
			inputFileDescriptor = outputFileDescriptor = 0 ;
			//  now create the pipe
			if ( mknod( name, S_IFIFO | 0600, 0 ) == 0 ) {
				//  now open for read and write
				inputFileDescriptor = open( name, O_RDWR ) ;			
				if ( inputFileDescriptor > 0 ) {
					ioctl( inputFileDescriptor, O_RDONLY, 0 ) ; //  change to read-only
					outputFileDescriptor = open( name, O_RDWR | O_NONBLOCK ) ;
				}
			}
		}
	}
	return self ;
}

- (void)dealloc
{
	if ( name ) {
		unlink( name ) ;
		free( name ) ;
	}
	[ super dealloc ] ;
}

- (void)stopPipe
{
	if ( name ) {
		if ( outputFileDescriptor > 0 ) close( outputFileDescriptor ) ;
	}
}

- (int)inputFileDescriptor
{
	return inputFileDescriptor ;
}

- (int)outputFileDescriptor
{
	return outputFileDescriptor ;
}

@end
