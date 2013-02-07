//
//  RTTYModulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/31/05.
	#include "Copyright.h"
//

#import "RTTYModulator.h"
#import "RTTY.h"
#import "CoreModem.h"

//	add a second tone (for two tone testing) to CMFSKModulator
@implementation RTTYModulator

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		theta2 = 0 ;
	}
	return self ;
}

//  intercept setTonePair to save frequenceies (CMRTTY Modulator uses the DDA frequencies)
- (void)setTonePair:(const CMTonePair*)inTonePair
{
	toneFrequencies = *inTonePair ;
	[ super setTonePair:inTonePair ] ;
}

- (CMTonePair*)toneFrequencies
{
	return &toneFrequencies ;
}

//  callback target as each character is transmitted
- (void)setModemClient:(Modem*)inModem
{
	modem = inModem ;
}

//  unmap phi to zero
static int unmap( int d )
{
	if ( d == 216 || d == 175 ) return '0' ;
	d &= 0x7f ;
	return d ;
}

//  override CoreModem framework, which was 6 bits long
//  append a long mark tone (10 bits long, with no start bit)
- (void)appendLongMark
{
	producer = consumer ;
	stream[producer] = stopBit ;
	stream[producer].dda = bitDDA/10.0 ;					// v0.85b
	
	currentBitDDA = stream[producer].dda ;					// v0.85b
	bitTheta = 0 ;	
	ookAssert = 0 ;
	if ( ook == 2 ) ookAssert = !ookAssert ;				//  ook: mark

	producer = ( producer+1 )&CMSTREAMMASK ;
}

- (void)appendASCII:(int)ascii
{
	ascii = unmap( ascii ) ;			// this will unmap any phi into zero and also map '\n' into '\r'
	[ super appendASCII:ascii ] ;
}

// send transmitted character to modem to echo in the exchange view
- (void)transmittedCharacter:(int)character
{
	if ( modem && character ) {
		[ modem transmittedCharacter:character ] ;
	}
}

//  consume from the currect buffer
//  add repeats of character if there is no more bits to consume
- (void)getBufferWithRepeatFill:(float*)buf length:(int)samples
{
	int i ;
	
	for ( i = 0; i < samples; i++ ) {
		buf[i] = [ self sin:current ] ;
		//  modulation
		if ( [ self modulation:currentBitDDA ] ) {
			if ( producer == 0 ) current = tonePair.mark ;
			else {
				if ( ++consumer == producer ) consumer = 0 ; else consumer &= CMSTREAMMASK ;
				currentBitDDA = stream[consumer].dda ;
				current = ( stream[consumer].polarity == 0 ) ? tonePair.space : tonePair.mark ;
			}
		}
	}	
}

- (void)getBufferOfMarkTone:(float*)buf length:(int)samples
{
	int i ;

	for ( i = 0; i < samples; i++ ) buf[i] = [ self sin:tonePair.mark ]  ;
}

- (void)getBufferOfSpaceTone:(float*)buf length:(int)samples
{
	int i ;

	for ( i = 0; i < samples; i++ ) buf[i] = [ self sin:tonePair.space ] ;
}

- (void)getBufferOfTwoTone:(float*)buf length:(int)samples
{
	int i ;

	for ( i = 0; i < samples; i++ ) buf[i] = ( [ self sin:tonePair.space ] + [ self sin2:tonePair.mark ] )*0.5 ;
}


//  second channel
//  NOTE: delta must be less than kPeriod and greater than or equal to 0
- (float)sin2:(double)delta
{
	int t, mst, lst ;
	double th ;
	
	th = ( theta2 += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta2 = th ;
	}
	t = th ;
	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	return ( mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] )*scale ;
}


//  NOTE: delta must be less than kPeriod and greater than or equal to 0
- (float)cos2:(double)delta
{
	int t, mst, lst ;
	double th ;
	
	th = ( theta2 += delta ) ;
	if ( th > kPeriod ) {
		th -= kPeriod ;
		theta2= th ;
	}
	t = th ;
	mst = ( t >> kBits ) ;
	lst = t & kMask ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	return ( mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] )*scale ;
}

@end
