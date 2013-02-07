//
//  microKEYER.m
//  cocoaPTT
//
//  Created by Kok Chen on 4/4/06.
	#include "Copyright.h"
	

#import "microKEYER.h"


@implementation MK


// the control byte is the second frame of a sequence, so we need to send a nop frame first
- (void)sendControlByte:(int)cmd
{
	unsigned char nop[] = { 0x00, 0x80, 0x80, 0x80 } ;
	
	write( fd, nop, 4 ) ;
	nop[0] = ( ( cmd & 0x80 ) ? 0x41 : 0x40 ) ;					// sequence flag and MSB of data
	nop[3] = cmd | 0x80 ;										// 7 bit data witm MSB set
	write( fd, nop, 4 ) ;
}

- (void)sendControl:(unsigned char*)array length:(int)n
{
	int i ;
	for ( i = 0; i < n; i++ ) [ self sendControlByte:array[i] ] ;
}

//  flag byte is the last byte of a radio frame
- (void)sendFlagsToRadio:(int)flags
{
	unsigned char nop[] = { 0x28, 0x80, 0x80, 0x80 } ;
	
	if ( flags & 0x80 ) nop[0] |= 1 ;
	nop[3] |= ( flags & 0xff ) ;
	write( fd, nop, 4 ) ;
}

- (int)readControl:(unsigned char*)buf channel:(unsigned char*)ch maxlength:(int)length
{
	int i, status, channel ;
	unsigned char rbuf[4] ;
	
	i = 0 ;
	while ( 1 ) {
		status = read( fd, rbuf, 4 ) ;
		if ( status != 4 ) break ;
		channel = rbuf[0] & 0xfe ;
		if ( 1 || channel == 0x40 ) {
			ch[i] = channel ;
			buf[i++] = ( rbuf[3] & 0x7f ) | ( ( rbuf[0] & 1 ) ? 0x80 : 0 ) ;
			if ( i >= length ) break ;
		}
	}
	return i ;
}

- (void)transmitByte:(int)v
{
	unsigned char buf[1] ;
	
	buf[0] = v ;
	write( fd, buf, 1 ) ;
	usleep( 1000 ) ;
}

- (void)downloadTest
{
	unsigned char reset[2] = { 0x06, 0x86 }, buf[19], channel[19] ;
	int count ;
	
	//  reset device, this makes the bootloader wait for the 0x42 command
	[ self sendControl:reset length:2 ] ;
	usleep( 200000 ) ;
	//  read reply
	count = [ self readControl:buf channel:channel maxlength:19 ] ;	
	if ( count == 2 && buf[0] == reset[0] && buf[1] == reset[1] ) {
		// device is reset, waits for the start of download sequence
		[ self transmitByte:0x42 ] ;		// start bootloader
		count = read( fd, buf, 1 ) ;		// get reply, expect 0x01 (started)
		if ( count > 0 && buf[0] == 1 ) {
			// bootloader started
			[ self transmitByte:0x43 ] ;		// get version
			count = read( fd, buf, 9 ) ;		// get reply, expect 0x02 and 8 data bytes
			if ( count == 9 && buf[0] == 2 ) {
				//  received version info
				printf( "version: bootloader %d.%d product 0x%02x hardware %d mech %d\n", buf[2]&0x7f, buf[1]&0x7f, buf[3]&0x7f, buf[4]&0x7f, buf[5]&0x7f ) ; 
			}
		}
	}
	
}


- (void)getVersion
{
	unsigned char vers[2] = { 0x05, 0x85 }, buf[40], channel[40] ;
	int i, count ;
	
	//  reset device, this makes the bootloader wait for the 0x42 command
	[ self sendControl:vers length:2 ] ;
	usleep( 200000 ) ;
	//  read reply
	count = [ self readControl:buf channel:channel maxlength:40 ] ;	
	for ( i = 1; i < count; i += 2 ) printf( "%02x ", buf[i] ) ;
	printf( "\n" ) ;
}

- (id)initWithDevice:(NSString*)path name:(NSString*)stream
{
    struct termios options ;
	
	self = [ super init ] ;
	
	if ( self ) {
		name = stream ;
		radioFlags = 0 ;
		fd = open( [ path UTF8String ], O_WRONLY | O_NOCTTY | O_NDELAY) ;
		if ( fd >= 0 ) {
		
			if ( fcntl( fd, F_SETFL, 0 ) >= 0 ) {
				// Get the current options and save them for later reset
				tcgetattr( fd, &originalTTYAttrs ) ;
				// These options are documented in the man page for termios
				// (in Terminal enter: man termios)
				options = originalTTYAttrs ;
				// set device to 230400 baud, 8 bits no parity,one stop
				cfsetispeed( &options, B230400 ) ;
				cfsetospeed( &options, B230400 ) ;
				options.c_cflag = (CS8) | (CREAD) | (CLOCAL) ;
				// Set raw input, one second timeout
				options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
				options.c_oflag &= ~OPOST;
				options.c_cc[ VMIN ] = 0;
				options.c_cc[ VTIME ] = 10;
				// Set the options
				tcsetattr( fd, TCSANOW, &options ) ;
				
				tcgetattr( fd, &originalTTYAttrs ) ;
				
				//[ self downloadTest ] ;
				[ self getVersion ] ;
				return self ;
			}
		}
	}
	return nil ;
}


- (Boolean)setKey:(Boolean)rts active:(Boolean)pol
{
	radioFlags |= 0x4 ;				//  PTT flag
	[ self sendFlagsToRadio:radioFlags ] ;
	return YES ;
}

- (Boolean)setUnkey:(Boolean)rts active:(Boolean)pol
{
	radioFlags &= ~( 0x4 ) ;		//  PTT flag
	[ self sendFlagsToRadio:radioFlags ] ;
	return YES ;
}

@end
