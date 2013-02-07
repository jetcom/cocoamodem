//
//  Module.m
//  cocoaModem
//
//  Created by Kok Chen on 9/3/05.
	#include "Copyright.h"
//

#import "Module.h"
#import "Modem.h"
#import "TextEncoding.h"
#import "Transceiver.h"


@implementation Module

//  Implements AppleScript "module" class.

- (id)initWithTransceiver:(Transceiver*)xcvr receiver:(Boolean)kind index:(int)inIndex
{
	self = [ super init ] ;
	if ( self ) {
		index = inIndex ;
		parent = xcvr ;
		isReceiver = kind ;
		modem = [ parent modem ] ;
		producer = consumer = 0 ;
		ptr = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

- (Boolean)isReceiver
{
	return isReceiver ;
}

- (Transceiver*)transceiver
{
	return parent ;
}

- (void)insertBuffer:(int)character
{
	int bIndex ;
	
	[ ptr lock ] ;
	bIndex = producer & BUFMASK ;
	buffer[bIndex] = character ;
	producer++ ;
	[ ptr unlock ] ;
}

- (float)frequency
{
	return [ modem frequencyFor:self ] ;
}

- (void)setFrequency:(float)f
{
	[ modem setFrequency:f module:self ] ;
}

- (void)setReplay:(float)timeOffset
{
	if ( isReceiver ) [ modem setTimeOffset:timeOffset index:index ] ;
}

- (float)mark
{
	return [ modem markFor:self ] ;
}

- (void)setMark:(float)f
{
	[ modem setMark:f module:self ] ;
}

- (float)space
{
	return [ modem spaceFor:self ] ;
}

- (void)setSpace:(float)f
{
	[ modem setSpace:f module:self ] ;
}

- (float)baud
{
	return [ modem baudFor:self ] ;
}

- (void)setBaud:(float)f
{
	[ modem setBaud:f module:self ] ;
}

- (Boolean)invert
{
	return [ modem invertFor:self ] ;
}

- (void)setInvert:(Boolean)state
{
	[ modem setInvert:state module:self ] ;
}

- (Boolean)breakin
{
	return [ modem breakinFor:self ] ;
}

- (void)setBreakin:(Boolean)state
{
	[ modem setBreakin:state module:self ] ;
}

- (NSString*)stream
{
	int count, i, ch ;
	char string[17], *s ;
	
	//  quick check, without needing lock
	if ( producer == consumer ) return @"" ;
	
	[ ptr lock ] ;
	if ( producer == consumer ) return @"" ;
	count = producer - consumer ;
	[ ptr unlock ] ;
	if ( count > 16 ) count = 16 ;
	s = string ;
	for ( i = 0; i < count; i++ ) {
		ch = buffer[ (consumer++)&BUFMASK ] & 0xff ;	//  mask to 8 bit ASCII
		if ( ch != 0 ) *s++ = ch ;
	}
	*s++ = 0 ;
	if ( strlen( string ) == 0 ) return @"" ;
	
	return [ NSString stringWithCString:string encoding:kTextEncoding ] ;
}

- (void)setCStream:(char*)text
{
	if ( isReceiver ) return ;
	[ modem transmitString:text ] ;
}

- (void)setStream:(NSString*)text
{
	[ self setCStream:(char*)[ text cStringUsingEncoding:kTextEncoding ] ] ;
}

- (void)flushText:(NSScriptCommand*)command
{
	if ( isReceiver ) {
		[ modem flushClickBuffer ] ;
		[ ptr lock ] ;
		producer = consumer = 0 ;
		[ ptr unlock ] ;
		return ;
	}
	[ modem flushAndLeaveTransmit ] ;
}

//  we should get one buffer every 371.5 msec
//  returns 1024 bytes (0-2756.25 Hz) or empty string if there is no data
//	each byte represents pow( v, 0.25 )*5.52 (i.e., scaled square root of power).
//	the value is 200 near full scale input,
//	84 at -15 dB and 35.55 at -30 dB (i.e., about 30 dB per 5.62x)

- (NSString*)spectrum
{
	float *array ;
	unsigned char buf[1025], p ;
	int i ;
	
	if ( !isReceiver ) return @"" ;

	array = [ modem waterfallBuffer:index ] ;
	if ( array == nil ) return @"" ;
	
	for ( i = 0; i < 1024; i++ ) {
		p = pow( array[i], 0.25 )*5.52+ 0.5 ;
		if ( p <= 1 ) p = 1 ; else if ( p >= 254 ) p = 254 ;
		buf[i] = p ;
	}
	buf[1024] = 0 ;
	return [ NSString stringWithCString:(char*)buf encoding:NSISOLatin1StringEncoding ] ;
}

- (int)nextSpectrum
{
	if ( !isReceiver ) return 1000000 ;
	return [ modem nextWaterfallScanline ] ;
}

@end
