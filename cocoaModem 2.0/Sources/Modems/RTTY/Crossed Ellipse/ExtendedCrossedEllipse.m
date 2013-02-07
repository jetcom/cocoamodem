//
//  ExtendedCrossedEllipse.m
//  cocoaModem
//
//  Created by Kok Chen on 8/20/05.
	#include "Copyright.h"
//

#import "ExtendedCrossedEllipse.h"
#include "CoreFilter.h"
#include "modemTypes.h"


@implementation ExtendedCrossedEllipse

//  this extends the CrossedEllipse indicator to include an FSK "spectra tune"
//  it was an integral part of CrossedEllipse.m but is stripped out to allow indicators 
//	with no spectra tune.

- (void)preSetup
{
	int i ;
	
	[ super preSetup ] ;
	fsk = nil ;
	fskColor = [ [ NSColor colorWithCalibratedRed:0.95 green:0 blue:0 alpha:1.0 ] retain ] ;

	for ( i = 0; i < 128; i++ ) avgfreq[i] = 0 ;
	spectrum = FFTSpectrum( 9, YES ) ;
}


- (void)postSetup:(int)mask r:(int)rshift g:(int)gshift b:(int)bshift a:(int)ashift
{
	int i ;
	UInt32 a, r, g, b, r0, g0, b0 ;

	//  make intensity map for FSK spectrum
	r0 = ( plotBackground >> rshift ) & mask ;
	g0 = ( plotBackground >> gshift ) & mask ;
	b0 = ( plotBackground >> bshift ) & mask ;

	a = mask <<= ashift ;
	if ( depth >= 24 ) {
		for ( i = 0; i < 256; i++ ) {
			r = i + r0 ;
			if ( r > 255 ) r = 255 ;
			r <<= rshift ;
			g = i + g0 ;
			if ( g > 255 ) g = 255 ;
			g <<= gshift ;
			b = i/2 + b0 ;
			if ( b > 255 ) b = 255 ;
			b <<= bshift ;
			intensity[i] = r + g + b + /* alpha */ a ;
		}
		for ( i = 0; i < 256; i++ ) {
			r = i/2 + r0 ;
			if ( r > 255 ) r = 255 ;
			r <<= rshift ;
			g = i/2 + g0 ;
			if ( g > 255 ) g = 255 ;
			g <<= gshift ;
			b = i/4 + b0 ;
			if ( b > 255 ) b = 255 ;
			b <<= bshift ;
			intensityFade[i] = r + g + b + /* alpha */ a ;
		}
	}
	else {
		for ( i = 0; i < 256; i++ ) {
			r = i/16 + r0 ;
			if ( r > 15 ) r = 15 ;
			r <<= rshift ;
			g = i/16 + g0 ;
			if ( g > 15 ) g = 15 ;
			g <<= gshift ;
			b = i/32 + b0 ;
			if ( b > 15 ) b = 15 ;
			b <<= bshift ;
			intensity[i] = r + g + b + /* alpha */ a ;
		}
		for ( i = 0; i < 256; i++ ) {
			r = i/32 + r0 ;
			if ( r > 15 ) r = 15 ;
			r <<= rshift ;
			g = i/32 + g0 ;
			if ( g > 15 ) g = 15 ;
			g <<= gshift ;
			b = i/64 + b0 ;
			if ( b > 15 ) b = 15 ;
			b <<= bshift ;
			intensityFade[i] = r + g + b + /* alpha */ a ;
		}
	}
}

- (void)setTonePair:(const CMTonePair*)tonepair
{
	NSBezierPath *oldfsk ;
	float avg, offset, half, mf, sf ;

	[ super setTonePair:tonepair ] ;
	
	mf = tonepair->mark ;
	sf = tonepair->space ;
	
	//  spectrum calibration
	//  128 samples == 2756 Hz, 2210 Hz is at 95.6
	avg = ( mf+sf )*0.5 ;
	offset = ( int )( ( avg-2210 )*128/2756 + 95.6 ) + 0.5 ;
	half = width/2 + 0.5 ;
	
	[ lock lock ] ;
	oldfsk = fsk ;
	fsk = [ [ NSBezierPath alloc ] init ] ;
	[ fsk moveToPoint:NSMakePoint( offset, half-scale ) ] ;
	[ fsk lineToPoint:NSMakePoint( offset, half-scale-8 ) ] ;
	if ( oldfsk ) [ oldfsk release ] ;
	[ lock unlock ] ;
}

- (void)drawObjects
{
	[ scaleColor set ] ;
	[ axis stroke ] ;
	[ fskColor set ] ;		//  not in base class
	[ fsk stroke ] ;		//  not in base class
}

//  Extended Crossed Ellipse FSK spectrum
- (void)spectrum:(CMTappedPipe*)pipe
{
	CMDataStream *stream ;
	float *data, sum, norm ;
	int i, y, offset, width2 ;
	UInt32 spec[128], specFade[128], *pix  ;
	UInt16 *spix ;
	
	stream = [ pipe stream ] ;
	data = stream->array ;
	
	CMPerformFFT( spectrum, data, freq ) ;
	
	//  512 point transform, 128 samples == 2756 Hz
	norm = 0.001 ;
	for ( i = 0; i < 128; i++ ) {
		sum = freq[i+14] ;			// 2210 Hz is at (64+38.64)-14
		freq[i] = sum ;
		if ( sum > norm ) norm = sum ;
	}
	norm = 400.0/norm ;
	for ( i = 0; i < 128; i++ ) {
		avgfreq[i] = avgfreq[i]*0.8 + freq[i]*0.2 ;
		offset = avgfreq[i]*norm ;
		if ( offset > 255 ) offset = 255 ;
		spec[i] = intensity[offset] ;
		specFade[i] = intensityFade[offset] ;
	}
	
	//  display spectrum (two scanlines of memory, top line has persistence)
	//  width is 140, so supports a 128 wide spectrum
	y = (height-8)*width + ( width/2 ) - 64 ;
	width2 = 2*width ;
	if ( depth >= 24 ) {
		pix = &pixel[y] ;
		for ( i = 0; i < 128; i++ ) {
			pix[width] = spec[i] ;
			pix[0] = pix[width2] = specFade[i] ;
			pix++ ;
		}
	}
	else {
		spix = (UInt16*)pixel ;
		spix += y ;
		for ( i = 0; i < 128; i++ ) {
			spix[width] = spec[i] ;
			spix[0] = spix[width2] = specFade[i] ;
			spix++ ;
		}
	}	
}

- (void)importDataInMainThread:(CMPipe*)pipe
{
	if ( [ lock tryLock ] ) {
		[ self importDataIIR:(CMTappedPipe*)pipe ] ;
		if ( ( ++displayMux & 3 ) == 0 ) {
			[ self spectrum:(CMTappedPipe*)pipe ] ;			//  not in base class
			[ self setNeedsDisplay:YES ] ;
			displayMux = 0 ;
		}
		[ lock unlock ] ;
	}
}

//  assume data is 11025, 1 channel
- (void)importData:(CMPipe*)pipe
{
	if ( !modem ) return ;
	[ self performSelectorOnMainThread:@selector(importDataInMainThread:) withObject:pipe waitUntilDone:NO ] ;
}

@end
