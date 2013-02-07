//
//  CWMixer.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/3/06.
	#include "Copyright.h"
	
	
#import "CWMixer.h"
#import "CWReceiver.h"

@implementation CWMixer

extern float *mssin, *lssin, *mscos, *lscos ;

- (id)init
{
	CMTonePair tonepair = { 1500.0, 0.0, 45.45 } ;
	
	self = [ super init ] ;
	if ( self ) {
		receiver = nil ;
		isAural = NO ;
		//  set up CMDataStream
		data = &mixerStream ;
		mixerStream.array = &analyticSignal[0] ;
		mixerStream.samplingRate = CMFs ;
		mixerStream.samples = 512 ;
		mixerStream.components = mixerStream.channels = 1 ;		
		[ self setTonePair:&tonepair ] ;
		
		iFilter256 = CMFIRLowpassFilter( 300, CMFs, 256 ) ;
		qFilter256 = CMFIRLowpassFilter( 300, CMFs, 256 ) ;
		
		iFilter512 = CMFIRLowpassFilter( 300, CMFs, 512 ) ;
		qFilter512 = CMFIRLowpassFilter( 300, CMFs, 512 ) ;
		
		iFilter768 = CMFIRLowpassFilter( 300, CMFs, 768 ) ;
		qFilter768 = CMFIRLowpassFilter( 300, CMFs, 768 ) ;
		
		iFilter1024 = CMFIRLowpassFilter( 300, CMFs, 1500 ) ;
		qFilter1024 = CMFIRLowpassFilter( 300, CMFs, 1500 ) ;
		
		iFilter = iFilter256 ;
		qFilter = qFilter256 ;
		
	}
	return self ;
}

- (void)setReceiver:(CWReceiver*)cwReceiver
{
	receiver = cwReceiver ;
}

- (void)setAural:(Boolean)state
{
	isAural = state ;
}

- (void)setCWBandwidth:(float)halfwidth
{
	if ( halfwidth > 149 ) {
		//  bandwidth >= 300 Hz (300, 350, 400, 500)
		iFilter = iFilter256 ;
		qFilter = qFilter256 ;
	}
	else {
		if ( halfwidth > 76 ) {
			// bandwidth 153 Hz - 299 Hz (200, 250)
			iFilter = iFilter512 ;
			qFilter = qFilter512 ;
		}
		else {
			if ( halfwidth > 41 ) {
				// bandwidth 82 Hz to 152 Hz (100, 150)
				iFilter = iFilter768 ;
				qFilter = qFilter768 ;
			}
			else {
				//  bandwidth 81 Hz and below (30, 60)
				//  (halfwidth (lowpass) <= 41 Hz)
				iFilter = iFilter1024 ;
				qFilter = qFilter1024 ;
			}
		}
	}
	CMUpdateFIRLowpassFilter( iFilter, halfwidth ) ;
	CMUpdateFIRLowpassFilter( qFilter, halfwidth ) ;
}

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

- (void)setDDA:(CMDDA*)dda freq:(float)freq
{
	dda->freq = freq ;
	dda->deltaTheta = ( 262144.0 )*freq/CMFs ;
	dda->theta = 0.0 ;
	dda->cost = 1.0 ;
	dda->sint = 0.0 ;
}

- (void)setTonePair:(const CMTonePair*)tonepair
{
	[ self setDDA:&mark freq:tonepair->mark ] ;
}

- (void)importData:(CMPipe*)pipe
{
	int i ;
	float x, *array ;
	CMAnalyticPair mVfo ;
	CMDataStream *stream ;
	
	stream = [ pipe stream ] ;
	mixerStream.sourceID = stream->sourceID ;
	array = stream->array ;
	
	//  form split complex terms for mark and space signals
	for ( i = 0; i < 512; i++ ) {
		x = array[i] ;
		mVfo = update( &mark ) ;
		analyticSignal[i] = x*mVfo.re ;
		analyticSignal[i+512] = x*mVfo.im ;
	}	
	CMPerformFIR( iFilter, analyticSignal, 512, iIF ) ;
	CMPerformFIR( qFilter, analyticSignal+512, 512, qIF ) ;
	
	if ( isAural ) {
		//  send to aural monitor
		if ( receiver ) [ receiver received:iIF quadrature:qIF wide:array samples:512 ] ;
		return ;
	}
	//  otherwise, pass mixer output to demodulator chain
	[ self exportData ] ;
}

@end
