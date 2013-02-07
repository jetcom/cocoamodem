//
//  AMDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/18/07.
	#include "Copyright.h"
	
#import "AMDemodulator.h"
#include "CoreFilter.h"
#include "SynchAM.h"
#include "CMFFT.h"


@implementation AMDemodulator


- (id)init
{
	float low, high, bw ;
	ParametricRange range[5] ;
	
	self = [ super init ] ;
	if ( self ) {
		client = nil ;
		carrierFilter = CMFIRBandpassFilter( 80, 320, CMFs, 512 ) ;
		iFilter = CMFIRLowpassFilter( 50, CMFs/4, 128 ) ;
		qFilter = CMFIRLowpassFilter( 50, CMFs/4, 128 ) ;
		carrierVco = [ [ CMPCO alloc ] init ] ;
		fc = 200.0 ;
		fl = 150 ; 
		fh = 250 ;
		fd = 0.0 ;
		[ carrierVco setCarrier:fc ] ;
		cyclesSinceAdjust = 1000 ;
		excessDelta = 0 ;
		
		//  signal filters (oversampled by 2)
		low = fc+50.0 ;
		high = fc+4500.0 ;
		bw = ( high-low )*0.50 ;
		sidebandFilter = CMFIRBandpassFilter( low, high, CMFs*2, 512 ) ;
		iAudioFilter = CMFIRLowpassFilter( bw, CMFs*2, 256 ) ;
		qAudioFilter = CMFIRLowpassFilter( bw, CMFs*2, 256 ) ;
		
		outputFilter = CMFIRLowpassFilter( high*0.9-low, CMFs*2, 256 ) ;
		
		fshift = ( high+low )*0.5 ;
		downshiftVco = [ [ CMPCO alloc ] init ] ;
		[ downshiftVco setCarrier:fshift*0.5 ] ;
		
		upshiftVco = [ [ CMPCO alloc ] init ] ;
		[ upshiftVco setCarrier:( fshift-fc )*0.5 ] ;					//  downShift - upShift = carrier frequency
		
		volume = 0.01 ;
		
		range[0].low =           0.0 ; range[0].high =  150.0 ; range[0].value =    1.0 ;
		range[1].low = range[0].high ; range[1].high =  300.0 ; range[1].value =    1.0 ;
		range[2].low = range[1].high ; range[2].high =  600.0 ; range[2].value =    1.0 ;
		range[3].low = range[2].high ; range[3].high = 1200.0 ; range[3].value =    1.0 ;
		range[4].low = range[3].high ; range[4].high = 2400.0 ; range[4].value =    1.0 ;
		
		equalizer = [ [ ParametricEqualizer alloc ] init:range ranges:5 order:256 ] ;
		eqFilter = [ equalizer filter ] ;
		equalizerEnable = NO ;
	}
	return self ;
}

- (void)setClient:(SynchAM*)owner
{
	client = owner ;
}

- (float)carrier
{
	return fc ;
}

- (void)setTrack:(float)carrier low:(float)low high:(float)high
{
	fc = carrier ;
	fl = low ;
	fh = high ;	
	CMUpdateFIRBandpassFilter( carrierFilter, low-10, high+10 ) ;
}

- (void)setEqualizerEnable:(Boolean)state
{
	equalizerEnable = state ;
}

- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *data, x, demod[512], br, bq, yi[128], yq[128], mag, ft, input, freq ;
	float interpolatedBuf[1024], sidebandBuf[1024] ;
	float shiftedBufI[1024], shiftedBufQ[1024], singleSidebandBufI[1024], singleSidebandBufQ[1024], unshiftedBuf[1024], iReg[128], qReg[128], iDot, qDot ;
	CMAnalyticPair mVfo ;
	int i, j ;

	stream = [ pipe stream ] ;
	data = stream->array ;
	
	//  audio processing (upsample input to CMFs (11025)*2)
	for ( i = 0; i < 512; i++ ) {
		j = i*2 ;
		interpolatedBuf[j] = interpolatedBuf[j+1] = data[i] ;
	}	
	//  interpolation filter and remove carrier
	CMPerformFIR( sidebandFilter, interpolatedBuf, 1024, sidebandBuf ) ;
	
	//  shift passband down
	for ( i = 0; i < 1024; i++ ) {
		input = sidebandBuf[i] ;
		mVfo = [ downshiftVco nextVCOPair ] ;
		shiftedBufI[i] = mVfo.re*input ;
		shiftedBufQ[i] = mVfo.im*input ;
	}
	//  apply lowpass to extract a single sideband
	CMPerformFIR( iAudioFilter, shiftedBufI, 1024, singleSidebandBufI ) ;
	CMPerformFIR( qAudioFilter, shiftedBufQ, 1024, singleSidebandBufQ ) ;

	//  shift passband back up, and form real signal again
	for ( i = 0; i < 1024; i++ ) {
		mVfo = [ upshiftVco nextVCOPair ] ;
		unshiftedBuf[i] = mVfo.re*singleSidebandBufI[i] + mVfo.im*singleSidebandBufQ[i] ;
	}
	//  lowpass output into sidebandBuf
	CMPerformFIR( outputFilter, unshiftedBuf, 1024, sidebandBuf ) ;
	
	//  apply equalizer if needed
	if ( equalizerEnable ) {
		CMPerformFIR( eqFilter, sidebandBuf, 1024, interpolatedBuf ) ;
		data = interpolatedBuf ;
	}
	else {
		data = sidebandBuf ;
	}
	for ( i = 0; i < 512; i++ ) demod[i] = data[i*2]*volume ;

	[ client setOutput:demod samples:512 ] ;
	
	//  carrier processing	
	CMPerformFIR( carrierFilter, stream->array, 512, sidebandBuf ) ;
	
	//  mix and subsample by 8
	j = 0 ;	
	for ( i = 0; i < 512; i++ ) {
		x = sidebandBuf[i] ;
		mVfo = [ carrierVco nextVCOPair ] ;
		if ( i == j*4 ) {
			yi[j] = mVfo.re*x ;
			yq[j] = mVfo.im*x ;
			j++ ;
		}
	}
	
	// yi and yq are subsampled by 4 (128 samples)
	CMPerformFIR( iFilter, yi, 128, singleSidebandBufI ) ;
	CMPerformFIR( qFilter, yq, 128, singleSidebandBufQ ) ;
	
	//  hold off adjusting for a few cycles for VCO to settle.
	if ( cyclesSinceAdjust++ > 6 ) {

		//  track magnitude of signal
		mag = 0.00001 ;
		for ( i = 0; i < 128; i++ ) {
			br = singleSidebandBufI[i] ;
			bq = singleSidebandBufQ[i] ;
			mag += br*br + bq*bq ;
		}
		mag /= 128.0 ;
	
		//  wait for vco/sampling to settle down after each change before measuring again
		//  IIR differentiator using Al-Alaoui's 1994 algorithm
		//	http://mechatronics.ece.usu.edu/yqchen/dd/AL_Ala4.pdf
		for ( i = 18; i < 102; i++ ) {
			iReg[i] = singleSidebandBufI[i] - 0.5358*singleSidebandBufI[i+1] - 0.0718*singleSidebandBufI[i+2] ;
			qReg[i] = singleSidebandBufQ[i] - 0.5358*singleSidebandBufQ[i+1] - 0.0718*singleSidebandBufQ[i+2] ;
		}
		
		//  find average frequency in frame
		//  avergae freq deviation approx 0.00077 ticks/Hz
		freq = 0 ;
		for ( i = 20; i < 100; i++ ) {
			iDot = iReg[i+2]-iReg[i] ;
			qDot = qReg[i+2]-qReg[i] ;
			br = iReg[i+1] ;
			bq = qReg[i+1] ;
			freq += ( bq*iDot - br*qDot ) ;
		}
		freq *= 1./( 0.00077*80.0*mag ) ;
		freq += excessDelta*0.5 ;
		excessDelta = 0.75*freq ;
		
		ft = fc - freq*0.25 ;			
		if ( ft > fl && ft < fh ) {
			fc = ft ;
			[ carrierVco setCarrier:fc ] ;
			[ upshiftVco setCarrier:( fshift-fc )*0.5 ] ;							//  factor of 2 from oversampling
			cyclesSinceAdjust = ( [ client setLock:freq freq:fc ] > 1 ) ? -12 : 0 ;	// heck less often if in lock
		}
	}
}

- (void)setVolume:(float)value
{
	volume = value*2.0 ;
}

- (void)setEqualizer:(int)freq value:(float)v
{
	int index ;
	
	switch ( freq ) {
	case 300:
		index = 0 ;
		break ;
	case 600:
		index = 1 ;
		break ;
	case 1200:
		index = 2 ;
		break ;
	case 2400:
		index = 3 ;
		break ;
	case 4800:
		index = 4 ;
		break ;
	default:
		return ;
	}
	[ equalizer setRange:index to:v ] ;
}

@end
