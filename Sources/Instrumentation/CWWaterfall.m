//
//  CWWaterfall.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/1/06.
	#include "Copyright.h"
	
	
#import "CWWaterfall.h"
#include "WBCW.h"

@implementation CWWaterfall

- (void)drawMarkers
{
	float p, diff ;
	NSColor *rxColor ;
	Boolean separateTxAndRx ;
	
	if ( !active[waterfallID] ) return ;	
	
	diff = fabs( txMark - mark[waterfallID] ) ;
	separateTxAndRx = ( txMark > 5.0 ) ;
	if ( separateTxAndRx ) {
		rxColor = magenta ;
	}
	else {
		rxColor = green ;
		diff = 0 ;
	}	
	rxColor = ( separateTxAndRx ) ? magenta : green ;
	
	if ( !separateTxAndRx || diff > 2.0 ) {	
		p = mark[waterfallID]+0.5 ;
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:rxColor ] ;
	}
	
	if ( separateTxAndRx ) {
		p = txMark+0.5 ;
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:green ] ;
	}
	else {
		if ( fabs( ritOffset ) > 1.0 ) {
			p = mark[waterfallID]+ritOffset+0.5 ;
			[ self drawMarker:p width:2 color:black ] ;
			[ self drawMarker:p width:1.25 color:magenta ] ;
		}
	}
}

- (void)setTransmitTonePairMarker:(const CMTonePair*)tonepair index:(int)n
{
	float mf, sf ;
	
	txMarkFreq = tonepair->mark ;
	txSpaceFreq = tonepair->space ;
	
	if ( txMarkFreq < 5 ) {
		// lock tx to rx markers
		txMark = txSpace = 0 ;
		return ;
	}
	
	mf = ( tonepair->mark - firstBinFreq )/hzPerPixel ;
	sf = ( tonepair->space - firstBinFreq )/hzPerPixel ;
	if ( sideband == 0 ) {
		mf = width - mf - 0.5 ;
		sf = width - sf - 0.5 ;
	}
	else {
		mf -= 0.5 ;
		sf -= 0.5 ;
	}
	txMark = mf ;
	txSpace = sf ;
}


- (void)eitherMouseDown:(NSEvent*)event secondRx:(Boolean)option
{
	Boolean shift ;
	NSPoint location ;
	unsigned int flags ;
	float f, g ;
	
	if ( !modem ) return ;

	flags = [ event modifierFlags ] ;
	shift = ( flags & NSShiftKeyMask ) != 0 ;
	
	if ( shift ) {
		[ drawLock lock ] ;
		if ( !option ) click = 0 ; else optionClick = 0 ;
		[ drawLock unlock ] ;
		f = offset = 0 ;
		if ( modem ) [ modem turnOffReceiver:waterfallID option:option ] ;
		return ;
	}

	location = [ self convertPoint:[ event locationInWindow ] fromView:nil ] ;
	f =  firstBinFreq + ( ( sideband == 1 ) ? /* USB */ hzPerPixel*location.x : /* LSB */ hzPerPixel*( width - location.x - 1 ) ) ;
	g = location.y * ( 4096.0 / CMFs ) ;		//  4096 samples per scanline
	
	[ drawLock lock ] ;
	click = location.x ; 
	[ drawLock unlock ] ;
	
	if ( sideband == 0 ) f += 3.5 ;	// adjustment for cursor
	[ modem clicked:f secondsAgo:g option:option fromWaterfall:YES waterfallID:waterfallID ] ;
}

- (void)scrollWheel:(NSEvent*)event
{
	unsigned int flags ;
	float df, f, freq ;
	Boolean option ;

	if ( modem && [ modem isActiveTab ] ) {
		df = ( [ event deltaY ] > 0 ) ? -2.0 : +2.0 ;
		flags = [ event modifierFlags ] ;
		option = ( flags & NSControlKeyMask ) != 0 ;
		
		//  base frequency
		freq = markFreq[waterfallID] ;
		if ( option ) {
			// receive
			freq += ritOffsetFreq ;
		}
		f = ( sideband == 0 ) ? freq-df : freq+df ;
		[ modem clicked:f secondsAgo:0 option:option fromWaterfall:NO waterfallID:waterfallID ] ;
	}
}


@end
