//
//  RTTYWaterfall.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/23/05.
	#include "Copyright.h"


#import "RTTYWaterfall.h"

#include "RTTY.h"

@implementation RTTYWaterfall

- (void)awakeFromModem
{
	int i ;
	
	[ super awakeFromModem ] ;
	for ( i = 0; i < 4; i++ ) {
		mark[i] = space[i] = 0 ;
		markFreq[i] = 2125.0 ; 
		spaceFreq[i] = 2295.0 ;
		active[i] = NO ;
		ritOffset = ritOffsetFreq = 0 ;
		ignoreSideband = ignoreArrowKeys = NO ;
	}
	txMark = txSpace = 0 ;
	txMarkFreq = 2125.0 ; 
	txSpaceFreq = 2295.0 ;
}

//  v0.67 rewrite
//  if effective receive tones (including RIT) is different from transmit tones, then draw tow sets of markers.
- (void)drawMarkers
{
	float actualRxMark, actualRxSpace, actualTxMark, actualTxSpace, p ;
	NSColor *rxColor ;
	Boolean separateTxAndRx ;
	
	if ( !active[waterfallID] ) return ;	
	
	actualRxMark = mark[waterfallID] + ritOffset ;
	actualRxSpace = space[waterfallID] + ritOffset ;
	
	if ( txMark < 5.0 ) {
		actualTxMark = mark[waterfallID] ;
		actualTxSpace = space[waterfallID] ;
	}
	else {
		actualTxMark = txMark ;
		actualTxSpace = txSpace ;
	}
	
	separateTxAndRx = ( fabs( actualTxMark - actualRxMark ) > 1.5 ) || ( fabs( actualTxSpace - actualRxSpace ) > 1.5 ) ;
	
	rxColor = ( separateTxAndRx ) ? magenta : green ;
	
	//  draw receive frequency -- use magenta if receive != transmit
	p = actualRxMark + 0.5 ;
	if ( wideWaterfall ) {
		if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
	}
	[ self drawMarker:p width:2 color:black ] ;
	[ self drawMarker:p width:1.25 color:rxColor ] ;
	
	p = actualRxSpace + 0.5 ;
	if ( wideWaterfall ) {
		if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
	}
	[ self drawMarker:p width:2 color:black ] ;
	[ self drawMarker:p width:1.25 color:rxColor ] ;
	
	//  if receive != transmit, draw transmit frequency
	if ( separateTxAndRx ) {
		p = actualTxMark + 0.5 ;
		if ( wideWaterfall ) {
			if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
		}
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:green ] ;
		
		p = actualTxSpace + 0.5 ;
		if ( wideWaterfall ) {
			if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
		}
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1.25 color:green ] ;
	}
}

- (void)OriginaldrawMarkers
{
/*
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
		if ( wideWaterfall ) {
			if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
		}
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1 color:rxColor ] ;
		p = space[waterfallID]+0.5 ;
		if ( wideWaterfall ) {
			if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
		}
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1 color:rxColor ] ;
	}
	
	if ( separateTxAndRx ) {
		p = txMark+0.5 ;
		if ( wideWaterfall ) {
			if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
		}
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1 color:green ] ;
		
		p = txSpace+0.5 ;
		if ( wideWaterfall ) {
			if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
		}
		[ self drawMarker:p width:2 color:black ] ;
		[ self drawMarker:p width:1 color:green ] ;
	}
	else {
		if ( fabs( ritOffset ) > 1.0 ) {
			p = mark[waterfallID]+ritOffset+0.5 ;
			if ( wideWaterfall ) {
				if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
			}
			[ self drawMarker:p width:2 color:black ] ;
			[ self drawMarker:p width:1 color:magenta ] ;
			
			p = space[waterfallID]+ritOffset+0.5 ;
			if ( wideWaterfall ) {
				if ( sideband == 0 ) p = p*0.5 + width*0.5 - 3.5 ; else p = p*0.5 + 3.5 ;
			}
			[ self drawMarker:p width:2 color:black ] ;
			[ self drawMarker:p width:1 color:magenta ] ;
		}
	}
*/
}

- (void)setIgnoreSideband:(Boolean)state
{
	ignoreSideband = state ;
	if ( ignoreSideband ) sideband = 1 ;
}

- (void)setIgnoreArrowKeys:(Boolean)state
{
	ignoreArrowKeys = state ;
}

- (void)setActive:(Boolean)state index:(int)n
{
	active[n] = state ;
	[ self performSelectorOnMainThread:@selector(display) withObject:nil waitUntilDone:NO ] ;
}

- (void)setSideband:(int)which
{
	if ( !ignoreSideband ) {
		sideband = which ;
		ritOffset = 0 ;
		[ self useVFOOffset:vfoOffset ] ;
	}
}

- (void)setTonePairMarker:(const CMTonePair*)tonepair index:(int)n
{
	float mf, sf ;
	
	markFreq[n] = tonepair->mark ;
	spaceFreq[n] = tonepair->space ;
	
	ritOffset = 0 ;
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
	mark[n] = mf ;
	space[n] = sf ;
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

- (void)setRITOffset:(float)rit
{
	ritOffsetFreq = rit ;
	ritOffset = rit/hzPerPixel ;
	if ( sideband == 0 ) ritOffset = -ritOffset ;
}

- (void)arrowKeyTune:(NSNotification*)notify
{
	//  no arrow tuning
}

- (void)setOffset:(float)freq sideband:(int)inSideband
{
	sideband = inSideband ;
	[ self useVFOOffset:freq ] ;
}

- (void)useVFOOffset:(float)freq
{
	NSRect frame ;
	NSTextField *label ;
	float pixelOffset ;
	int i, fstart, nearest, actual ;
	CMTonePair tonepair ;
	
	//  If USB offset = 0, left edge is 400 Hz and right edge 2600 Hz (819 pixels)
	//  If LSB offset = 0, left edge is -2600 Hz and right edge -400 Hz
	//  If USB offset = 2000, left edge is -1600 Hz and right edge is +400 Hz
	//  If LSB offset = 2000, left edge is -400 Hz and right edge is +1600 Hz

	vfoOffset = freq ;
	nearest = ( (int)freq )/100 ;
	nearest = nearest*100 ;
	if ( ( freq - nearest ) > 50.0 ) nearest += 100 ;
	
	//  sideband: LSB = 0, USB = 1, 2.69179 Hz/pixel
	if ( sideband == 1 ) {
		//  USB
		pixelOffset = ( freq - nearest )/hzPerPixel ;
		if ( wideWaterfall ) {
			fstart = 400 ;
			for ( i = 0; i < 22; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%600 == 0 && i != 0 ) [ label setIntValue:actual ] ; else [ label setStringValue:@"" ] ;
				fstart += 200 ;
			}
		}
		else {
			fstart = 400 ;
			for ( i = 0; i < 23; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%500 == 0 && i != 0 ) [ label setIntValue:actual ] ; else [ label setStringValue:@"" ] ;
				fstart += 100 ;
			}
		}
	}
	else {
		// LSB 
		pixelOffset = -( freq - nearest )/hzPerPixel - 1 + 26 /* 778-752 */ -33 /* adjustement for wider waterfall in RTTY */;
		if ( wideWaterfall ) {
			fstart = 4800 ;
			for ( i = 0; i < 22; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%600 == 0 && i != 0 ) [ label setIntValue:-actual ] ; else [ label setStringValue:@"" ] ;
				fstart -= 200 ;
			}
		}
		else {
			fstart = 2600 ;
			for ( i = 0; i < 23; i++ ) {
				label = [ waterfallLabel cellAtRow:0 column:i ] ;
				actual = fstart - nearest ;
				if ( actual%500 == 0 && i != 0 ) [ label setIntValue:-actual ] ; else [ label setStringValue:@"" ] ;
				fstart -= 100 ;
			}
		}
	}
	frame = [ waterfallLabel frame ] ;
	frame.origin.x = pixelOffset - 15 ;
	[ waterfallLabel setFrame:frame ] ;
	[ waterfallLabel display ] ;

	frame = [ waterfallTicks frame ] ;
	frame.origin.x = pixelOffset + 1 - 37.1 + 0.5 ;
	frame.origin.x += ( sideband == 0 ) ? -1.0 : 1.0 ;
	[ waterfallTicks setFrame:frame ] ;
	[ waterfallTicks display ] ;
	
	//  update memory offsets after sidebands is set
	for ( i = 0; i < 4; i++ ) {
		tonepair.mark = markFreq[i] ;
		tonepair.space = spaceFreq[i] ;
		[ self setTonePairMarker:&tonepair index:i ] ;
	}
}

- (void)eitherMouseDown:(NSEvent*)event secondRx:(Boolean)option
{
	NSPoint location ;
	float f, g ;
	
	if ( !modem ) return ;

	location = [ self convertPoint:[ event locationInWindow ] fromView:nil ] ;

	if ( wideWaterfall ) {
		f =  firstBinFreq + ( ( sideband == 1 ) ? 2*hzPerPixel*location.x : 2*hzPerPixel*( width - location.x - 1 ) ) - 15.0 ;
	}
	else {
		f =  firstBinFreq + ( ( sideband == 1 ) ? /* USB */ hzPerPixel*location.x : /* LSB */ hzPerPixel*( width - location.x - 1 ) ) ;
	}
	g = location.y * ( 4096.0 / CMFs ) ;		//  4096 samples per scanline
	
	[ drawLock lock ] ;
	click = location.x ; 
	[ drawLock unlock ] ;
	
	if ( sideband == 0 ) f += 3.5 ;	// adjustment for cursor
	[ modem clicked:f secondsAgo:g option:option fromWaterfall:YES waterfallID:waterfallID ] ;
}

//  trap mouse and mouse with control key
- (void)mouseDown:(NSEvent*)event
{
	Boolean option ;
	unsigned int flags ;
	
	flags = [ event modifierFlags ] ;
	option = ( flags & NSControlKeyMask ) != 0 ;
	[ self eitherMouseDown:event secondRx:option ] ;
}

- (void)rightMouseDown:(NSEvent*)event
{
	[ self eitherMouseDown:event secondRx:YES ] ;
}

- (void)scrollWheel:(NSEvent*)event
{
	unsigned int flags ;
	float df, f, lower, higher ;
	Boolean option ;

	if ( modem && [ modem isActiveTab ] ) {
		df = ( [ event deltaY ] > 0 ) ? -2.0 : +2.0 ;
		flags = [ event modifierFlags ] ;
		option = ( flags & NSControlKeyMask ) != 0 ;
		
		//  base frequency
		lower = markFreq[waterfallID] ;
		higher = spaceFreq[waterfallID] ;
		if ( option ) {
			// receive
			lower += ritOffsetFreq ;
			higher += ritOffsetFreq ;
		}
		if ( lower > higher ) {
			f = lower ;
			lower = higher ;
			higher = f ;
		}
		f = ( sideband == 0 ) ? lower-df : higher+df ;
		[ modem clicked:f secondsAgo:0 option:option fromWaterfall:NO waterfallID:waterfallID ] ;
	}
}

@end
