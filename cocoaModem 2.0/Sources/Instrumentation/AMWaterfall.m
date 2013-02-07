//
//  AMWaterfall.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/18/07.
	#include "Copyright.h"
	
	
#import "AMWaterfall.h"
#include "CoreFilter.h"

@implementation AMWaterfall

- (void)awakeFromModem
{
	[ super awakeFromModem ] ;
	noiseReduction = NO ;
	startingBin = 100.0/2.69179 - 8 ;
	fc = 200.0 ;
	fl = 100.0 ;
	fh = 300.0 ;
}

- (void)drawShortMarker:(float)p width:(float)lineWidth color:(NSColor*)color
{
	NSBezierPath *line ;

	line = [ NSBezierPath bezierPath ] ;
	[ line setLineWidth:lineWidth ] ;
	[ line moveToPoint:NSMakePoint( p, 0 ) ] ;
	[ line lineToPoint:NSMakePoint( p, 4 ) ] ;
	[ color set ] ;
	[ line stroke ] ;
}

- (void)drawMarkers
{
	float p ;

	p = (int)( fh/5.38 - 15 ) + 0.5 ;
	[ self drawMarker:p width:2 color:black ] ;
	[ self drawMarker:p width:1 color:green ] ;
	p = (int)( fl/5.38 - 14 ) - 0.5 ;
	[ self drawMarker:p width:2 color:black ] ;
	[ self drawMarker:p width:1 color:green ] ;
	p = (int)( fc/5.38 - 14 ) ;
	[ self drawShortMarker:p width:5 color:green ] ;
}

- (void)setTrack:(float)center low:(float)low high:(float)high
{
	fc = center ;
	fl = low ;
	fh = high ;
}

- (void)setTrack:(float)center
{
	fc = center ;
}

- (void)importAndDisplayInMainThread:(CMPipe*)pipe
{
	CMDataStream *stream ;
	char *src ;
	UInt32 *line ;
	UInt16 *sline ;
	float *data, *startBin ;
	int i, limit ;

	//  ignore data overruns
	if ( [ drawLock tryLock ] ) {

		stream = [ pipe stream ] ;
		data = stream->array ;

		//  copy new buffer (512) into fft buffer (4096)
		limit = 4096 - stream->samples ;
		if ( mux > limit ) mux = limit ;
		memcpy( &timeSample[mux], data, stream->samples*sizeof(float) ) ;
		mux += stream->samples ;

		if ( mux >= 4096 ) {
			mux = 0 ;
			CMPerformFFT( spectrum, timeSample, freqBin ) ;
			
			//  scroll waterfall up
			src = ( ( char* )pixel ) + rowBytes ;
			memcpy( pixel, src, rowBytes*( height-5 ) ) ;
			//  5.38 Hz per pixel
			if ( depth >= 24 ) {
				line = (UInt32*)( ( ( char* )pixel ) + rowBytes*( height-5 ) ) ;
				startBin = &freqBin[startingBin] ;
				for ( i = 0; i < width; i++ ) line[i] = [ self plotIntensity:( startBin[i*2]+startBin[i*2+1] )*0.5 ] ;
			}
			else {
				sline = (UInt16*)( ( ( char* )pixel ) + rowBytes*( height-5 ) ) ;
				startBin = &freqBin[startingBin] ;
				for ( i = 0; i < width; i++ ) sline[i] = [ self plotIntensity:( startBin[i*2]+startBin[i*2+1] )*0.5 ] ;
			}
			[ self performSelectorOnMainThread:@selector(displayInMainThread) withObject:pipe waitUntilDone:NO ] ; 
		}
		[ drawLock unlock ] ;
	}
}

//  v0.76 added simple importData back here
- (void)importData:(CMPipe*)pipe
{
	if ( !modem ) return ;
	[ self importAndDisplayInMainThread:pipe ] ;
}

- (void)setOffset:(float)freq sideband:(int)inSideband
{
	NSRect frame ;
	NSTextField *label ;
	float pixelOffset ;
	int i, fstart, nearest, actual ;
	
	//  Left edge is 100 Hz and right edge 4145 Hz (752 pixels at 5.38 Hz per pixel)

	vfoOffset = freq ;
	nearest = ( (int)freq )/100 ;
	nearest = nearest*100 ;
	if ( ( freq - nearest ) > 50.0 ) nearest += 100 ;
	
	pixelOffset = ( freq - nearest )/( hzPerPixel*2 ) ;
	fstart = 100 ;
	for ( i = 0; i < 21; i++ ) {
		label = [ waterfallLabel cellAtRow:0 column:i ] ;
		actual = fstart - nearest ;
		if ( ( actual-100 )%400 == 0 && actual > 100 ) [ label setIntValue:actual ] ; else [ label setStringValue:@"" ] ;
		fstart += 200 ;
	}

	frame = [ waterfallLabel frame ] ;
	frame.origin.x = pixelOffset - 15 ;
	[ waterfallLabel setFrame:frame ] ;
	[ waterfallLabel display ] ;

	frame = [ waterfallTicks frame ] ;
	frame.origin.x = pixelOffset + 1 - 37.1 + 0.5 ;
	[ waterfallTicks setFrame:frame ] ;
	[ waterfallTicks display ] ;
}

@end
