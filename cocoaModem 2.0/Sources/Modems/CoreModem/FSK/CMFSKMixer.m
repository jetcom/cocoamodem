//
//  CMFSKMixer.m
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Wed Jun 09 2004)
	#include "Copyright.h"

#import "CMFSKMixer.h"
#import "CoreModem.h"
#import "CoreModemTypes.h"
#import "ModemConfig.h"
#include <math.h>

@implementation CMFSKMixer

- (id)init
{
	CMTonePair tonepair = { 2125.0, 2295.0, 45.45 } ;
	
	self = [ super init ] ;
	if ( self ) {
		demodulator = nil ;
		auralMonitor = nil ;
		//  set up CMDataStream
		data = &mixerStream ;
		mixerStream.array = &analyticSignal[0] ;
		mixerStream.samplingRate = CMFs ;
		mixerStream.samples = 512 ;
		mixerStream.components = mixerStream.channels = 1 ;		
		[ self setTonePair:&tonepair ] ;
	}
	return self ;
}

//  theta is scaled so that a 0 represents 0 degrees and a full 16 bit number represents 2.pi degrees
- (void)setDDA:(CMDDA*)dda freq:(float)freq
{
	dda->freq = freq ;
	dda->deltaTheta = ( 262144.0 )*freq/CMFs ;
	dda->theta = 0.0 ;
	dda->cost = 1.0 ;
	dda->sint = 0.0 ;
}

//  update sine and cosine to the next time sample
//  return sine
static CMAnalyticPair update( CMDDA* dda )
{
	int t, mst, lst ;
	double th ;
	CMAnalyticPair p ;
	
	th = ( dda->theta += dda->deltaTheta ) ;
	if ( th > 262144.0 ) {
		th -= 262144.0 ;
		dda->theta = th ;
	}
	t = th ;
	mst = ( t >> 10 ) ;
	lst = t & 0x3ff ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	//dda->sint = mssin[mst]*lscos[lst] + mscos[mst]*lssin[lst] ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	//dda->cost = mscos[mst]*lscos[lst] - mssin[mst]*lssin[lst] ;

	//  v0.76 performance tune
	double sina = mssin[mst] ;
	double cosa = mscos[mst] ;
	double sinb = lssin[lst] ;
	double cosb = lscos[lst] ;
	//  sin(a+b) = sin(a)cos(b) + cos(a)sin(b)
	dda->sint = sina*cosb + cosa*sinb ;
	//  cos(a+b) = cos(a)cos(b) - sin(a)sin(b)
	dda->cost = cosa*cosb - sina*sinb ;
	
	p.re = dda->cost ;
	p.im = dda->sint ;
	return ( p ) ;
}

- (void)setTonePair:(const CMTonePair*)tonepair
{
	[ self setDDA:&mark freq:tonepair->mark ] ;
	[ self setDDA:&space freq:tonepair->space ] ;
}

- (void)setDemodulator:(CMFSKDemodulator*)client 
{
	demodulator = client ;
}

//  v0.88d
- (void)setConfig:(ModemConfig*)cfg
{
	config = cfg ;
}

- (void)setAuralMonitor:(RTTYAuralMonitor*)mon
{
	auralMonitor = mon ;
}

//  bandpass filtered data arrives here and is sent to the matched filter as I/Q baseband data.
- (void)importData:(CMPipe*)pipe
{
	int i ;
	float x, *array, mag ;
	CMAnalyticPair mVfo ;
	CMDataStream *stream ;
	
	stream = [ pipe stream ] ;
	mixerStream.sourceID = stream->sourceID ;
	array = stream->array ;
	
	mag = 0 ;
	//  form split complex terms for mark and space signals
	for ( i = 0; i < 512; i++ ) {
		x = array[i] ;
		mVfo = update( &mark ) ;
		analyticSignal[i] = x*mVfo.re ;
		analyticSignal[i+512] = x*mVfo.im ;
		mVfo = update( &space ) ;
		analyticSignal[i+1024] = x*mVfo.re ;
		analyticSignal[i+1536] = x*mVfo.im ;
		
		// v0.88d AGC test
		x = fabs( x ) ;
		if ( x > mag ) mag = x ; ;
	}
	[ self exportData ] ;
	
	/*
	// v0.88d AGC -- "good place" is between 0.5 (with 6 dB headroom) and 0.35 (dynamic range of soundcard minus 9 dB)
	if ( mag > 0.5 || mag < 0.35 ) {
		[ config processAGC:mag ] ;
	}
	*/
}

@end
