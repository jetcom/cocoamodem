//
//  PTTDevice.m
//  cocoaPTT
//
//  Created by Kok Chen on 4/4/06.
	#include "Copyright.h"
	

#import "PTTDevice.h"


@implementation PTTDevice

- (id)initWithDevice:(NSString*)path name:(NSString*)stream allowRead:(Boolean)allowRead
{
    struct termios options ;
	
	self = [ super init ] ;
	
	if ( self ) {
		
		name = stream ;
		if ( allowRead ) {
			fd = open( [ path UTF8String ], O_NOCTTY | O_NDELAY) ;
		}
		else {
			fd = open( [ path UTF8String ], O_WRONLY | O_NOCTTY | O_NDELAY) ;
		}
		if ( fd >= 0 ) {
			if ( fcntl( fd, F_SETFL, 0 ) >= 0 ) {
				// Get the current options and save them for later reset
				tcgetattr( fd, &originalTTYAttrs ) ;
				// Set raw input, one second timeout
				// These options are documented in the man page for termios
				// (in Terminal enter: man termios)
				options = originalTTYAttrs;
				options.c_cflag |= (CLOCAL | CREAD);
				options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
				options.c_oflag &= ~OPOST;
				options.c_cc[ VMIN ] = 0;
				options.c_cc[ VTIME ] = 10;
				// Set the options
				tcsetattr( fd, TCSANOW, &options ) ;
				return self ;
			}
		}
	}
	return nil ;
}

- (NSString*)name
{
	return name ;
}

int serialFlag( int rts ) 
{
	//  RigBlaster nomic wires OR both RTS and DTR together!
	switch ( rts ) {
	case 0:
		return TIOCM_DTR ;
	default:
	case 1:
		return TIOCM_RTS ;
	case 2:
		return ( TIOCM_RTS | TIOCM_DTR ) ;
	}
	return TIOCM_RTS ;
}

- (Boolean)setKey:(int)rts active:(Boolean)pol
{
	int bits, flag ;
	
	useRTS = rts ;
	activeHigh = pol ;
	
	if ( fd >= 0 ) {
		ioctl( fd, TIOCMGET, &bits ) ;
		flag = serialFlag( rts ) ;
		if ( activeHigh ) {
			bits |= flag ;
		}
		else {
			bits &= ~flag ;
		}
		ioctl( fd, TIOCMSET, &bits ) ;
		return YES ;
	}
	return NO ;
}

- (Boolean)setUnkey:(int)rts active:(Boolean)pol
{
	int bits, flag ;

	useRTS = rts ;
	activeHigh = pol ;

	if ( fd >= 0 ) {
		ioctl( fd, TIOCMGET, &bits ) ;
		flag = serialFlag( rts ) ;
		if ( !activeHigh ) {
			bits |= flag ;
		}
		else {
			bits &= ~flag ;
		}
		ioctl( fd, TIOCMSET, &bits ) ;
		return YES ;
	}
	return NO ;
}

- (void)close
{
	if ( fd >= 0 ) close( fd ) ;
	fd = 0 ;
}

- (void)dealloc
{
	if ( fd >= 0 ) close( fd ) ;
	[ super dealloc ] ;
}


@end
