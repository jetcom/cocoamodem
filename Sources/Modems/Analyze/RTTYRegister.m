//
//  RTTYRegister.m
//  cocoaModem
//
//  Created by Kok Chen on 3/9/05.
	#include "Copyright.h"
//

#import "RTTYRegister.h"
#include "CoreModemTypes.h"

@implementation RTTYRegister

#define INTSCALE	100000.0

//  assume data rate is at 11.025/8 (Fs/8) (about 30.32 samples per Baudot bit)
//  (approximately 6 characters/second)

//  data is entered into a 2048 element rig buffer.
//  data is fetched from outPointer and entered at inPointer

//  called before the start of a stream
- (void)initBuffers
{
	int i ;
	
	for ( i = 0; i < 255; i++ ) maxRegister[i] = 1 ;
	maxRegister[255] = accumMax = .01 ;
	smoothedMax = 0.001 ;
	
	for ( i = 0; i < RINGSIZE; i++ ) {
		array[i] = 0.0 ;
		agc[i] = 0.01 ;
		sync[i] = 0.0 ;
	}
	outPointer = inPointer = 0 ;
}

- (id)initWithBitPeriod:(float)milliseconds
{
	id ptr ;
	float pos ;
	int i, last ;
	
	ptr = [ self init ] ;
	if ( ptr ) {
		samplesPerBit = milliseconds*( CMFs/8 )*.001 ;
		//  word offsets, set to 1.5 stop bits, wrapped around ring buffer size
		samplesPerWord = samplesPerBit*7.5 ;
		
		for ( i = 0; i < 32; i++ ) {
			wordOffset[i] = ( (int)( samplesPerWord*(i-16) ) + RINGSIZE ) & RINGMASK ;	// 1.5 stop bits
		}
		
		//  first bitOffset is at the 1.5 stop bit location (1/2 bit offset)
		//  subsequent indexes are spaced at 1 bit time apart
		//  last position is again 0.5 bit time away for trailing 1.5 stop bit
		//  i.e., index 0,1 = stop, index 2 = start, index 3 = LSB, ... index 7 = MSB, index 8,9 = stop
		pos = samplesPerBit*0.5 ;
		bitCenter[0] = 0 ;
		for ( i = 1; i < 9; i++ ) {
			bitCenter[i] = (int)( pos + 0.5 ) ;
			pos += samplesPerBit ;
		}
		pos -= samplesPerBit*0.5 ;
		bitCenter[i] = last = (int)( pos + 0.5 ) ;
		last += (int)( samplesPerBit*0.5 ) ;
		//  referenced to the end of a Baudot character, i.e., bitCenter[i] are all negative
		for ( i = 0; i < 10; i++ ) bitCenter[i] -= last ;
		
		[ self initBuffers ] ;
	}
	return ptr ;
}

//  number of characters available between input pointer and output pointer
- (float)charactersAvailable
{
	if ( inPointer > outPointer ) return ( inPointer - outPointer )/samplesPerWord ;
	return ( inPointer + RINGSIZE - outPointer )/samplesPerWord ;
}

- (void)getBuffer:(float*)buf offset:(int)offset stride:(int)stride
{
	int i, j, k ;
	
	k = offset + outPointer ;
	for ( i = 0, j = 0; i < 256; i++, k++ ) {
		buf[j] = array[k&RINGMASK] ;
		j += stride ;
	}
}

- (void)getCompensatedBuffer:(float*)buf offset:(int)offset stride:(int)stride
{
	int i, j, k ;
	
	k = offset + outPointer ;
	for ( i = 0, j = 0; i < 256; i++, k++ ) {
		k &= RINGMASK ;
		buf[j] = array[k] - agc[k] ;
		j += stride ;
	}
}

//  bit -3  previous 1.5 stop bit
//  bit -2	previous stop bit
//  bit -1  current start bit
//  bit 0 thru 4 LSB through MSB of Baudot
//  bit 5 current stop bit
//  bit 6 current 1.5 stop bit

- (float)sample:(int)bit
{
	return [ self sample:bit word:0 offset:0 ] ;
}

//  word is 0 for current word, -1 for previous word, -2 for word 2 characters ago, etc
//  word must be no smaller than -16 and no greater than +16
- (float)sample:(int)bit word:(int)word offset:(int)offset
{
	offset += wordOffset[word+16] ;
	return [ self sample:bit offset:offset ] ;
}

- (float)sample:(int)bit offset:(int)offset
{
	int i ;
	
	bit += 3 ;
	if ( bit < 0 || bit > 9 ) return 0.0 ;
		
	i = ( bitCenter[bit] + outPointer + offset ) & RINGMASK ;
	return array[i] ;
}

//  max over current 8 Baudot start/stop and data bits starting at current data offset
//  0 offset is the center of the first preceeding stop bit
- (float)agc
{
	return agc[outPointer] ;
}

- (float)agcForWord:(int)word
{
	int i ;

	i = ( outPointer + wordOffset[word+16] ) & RINGMASK ;
	return agc[i] ;
}

- (float)agcAtOffset:(int)offset
{
	int i ;

	i = ( outPointer + offset + RINGSIZE ) & RINGMASK ;
	return agc[i] ;
}

//  delay = -320 : from optimization on 0dB selective fade file
- (void)addSample:(float)data
{
	int i, d, old, maxPtr ;
	
	//  update the data and agc registers (2048 samples)
	array[inPointer] = data ;
	sync[inPointer] = 0 ; // @@@
	agc[( inPointer+(RINGSIZE-320) )&RINGMASK] =  smoothedMax*0.5 ;

	//  find max over the previous 256 samples
	maxPtr = (inPointer)&0xff ;
	old = maxRegister[maxPtr] ;
	d = (int)( data*INTSCALE ) ;
	if ( d < 0 ) d = 0 ;
	maxRegister[maxPtr] = d ;
	
	//  smooth max
	smoothedMax = smoothedMax*0.95 + accumMax*0.05/INTSCALE ;
		
	//  update max over register
	if ( d >= accumMax ) accumMax = d ;
	else {
		if ( old >= accumMax ) {
			//  largest agc voltage removed, need to update max agc with a full search
			accumMax = maxRegister[0] ;
			for ( i = 1; i < 256; i++ ) {
				if ( maxRegister[i] > accumMax ) accumMax = maxRegister[i] ;
			}
		}
	}
	//  wrap pointer around
	inPointer = ( inPointer+1 )&RINGMASK ;
}

- (void)addSamples:(int)size array:(float*)data
{
	int i ;
	
	for ( i = 0; i < size; i++ ) [ self addSample:data[i] ] ;
}

- (void)advance
{
	outPointer = ( outPointer+1 )&RINGMASK ;
}

//  in to out delay
- (int)delay
{
	return ( inPointer - outPointer + RINGSIZE )&RINGMASK ;
}



@end
