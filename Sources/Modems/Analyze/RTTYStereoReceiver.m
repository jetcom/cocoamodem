//
//  RTTYStereoReceiver.m
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
	#include "Copyright.h"
//

#import "RTTYStereoReceiver.h"
#include "CoreFilter.h"
#include "CMFSKMixer.h"
#include "CMRTTYMatchedFilter.h"
#include "AnalyzeConfig.h"
#include "ChannelSelector.h"
#include "CrossedEllipse.h"
#include "ModemConfig.h"
#include "ModemSource.h"
#include "CMATC.h"
#include "MultiStereoATC.h"
#include "StereoRefATCBuffer.h"
#include "RTTYMPFilter.h"
#include "RTTYSingleFilter.h"
#include "Spectrum.h"


@implementation RTTYStereoReceiver

- (id)initReceiver:(int)index
{
	self = [ super initReceiver:index ] ;
	if ( self ) {
		scope = nil ;
		reference = 0 ;	/* left */
		dut = 1 ;		/* right */		
		refPipe = dutPipe = nil ;
		sidebandState = NO ;
		modemSource = nil ;
		// create bandpass filters
		refFilter = [ [ CMBandpassFilter alloc ] initLowCutoff:2040 highCutoff:2380 length:256 ] ;
		
		dutFilter[0] = [ [ CMBandpassFilter alloc ] initLowCutoff:2090 highCutoff:2330 length:256 ] ;
		dutFilter[1] = [ [ CMBandpassFilter alloc ] initLowCutoff:2040 highCutoff:2380 length:256 ] ;
		dutFilter[2] = [ [ CMBandpassFilter alloc ] initLowCutoff:1970 highCutoff:2450 length:256 ] ;
		dutFilter[3] = [ [ CMBandpassFilter alloc ] initLowCutoff:1920 highCutoff:2500 length:128 ] ;
		dutFilter[4] = [ [ CMBandpassFilter alloc ] initLowCutoff:500 highCutoff:2500 length:128 ] ;

		return self ;
	}
	return nil ;
}

- (void)setReference:(int)refChannel dut:(int)dutChannel
{
	reference = refChannel ;
	[ refPipe selectChannel:reference ] ;
	//  crossed ellipse is tapped from refPipe

	dut = dutChannel ;
	[ dutPipe selectChannel:dut ] ;
	[ dutPipe setTap:nil ] ;
}

- (void)setScope:(AnalyzeScope*)ascope
{
	scope = ascope ;
	if ( stereoATC ) [ stereoATC setScope:scope ] ;
}

/* local */
//  set up filter cutoffs given current mark and space frequencies
- (void)setFilterCutoffs
{
	float low, high ;
	
	if ( currentTonePair.space < currentTonePair.mark ) {
		low = currentTonePair.space ;
		high = currentTonePair.mark ;
	}
	else {
		low = currentTonePair.mark ;
		high = currentTonePair.space ;
	}
	//  reference filter has nominal bandwidth
	[ (CMBandpassFilter*)( refFilter ) updateLowCutoff:low-85 highCutoff:high+85 ] ;

	[ (CMBandpassFilter*)( dutFilter[0] ) updateLowCutoff:low-35 highCutoff:high+35 ] ;
	[ (CMBandpassFilter*)( dutFilter[1] ) updateLowCutoff:low-85 highCutoff:high+85 ] ;
	[ (CMBandpassFilter*)( dutFilter[2] ) updateLowCutoff:low-155 highCutoff:high+155 ] ;
	[ (CMBandpassFilter*)( dutFilter[3] ) updateLowCutoff:low-205 highCutoff:high+205 ] ;
}

//  overide base class to change AudioPipe pipeline (assume source is normalized)
//		source 
//		self
//		. ChannelSelectorPipe	. crossed ellipse
//		. BPF[5]
//		. bpfBuffer
//		. CMFSKMixer
//		. ( matchedFilter, mpFilter, heavyMPFilter )
//		. demodBuffer
//		. CMATC
//		. CMBaudotDecoder(importData)  

- (void)setupReceiverChain:(ModemSource*)source config:(AnalyzeConfig*)config
{
	int i ;
	
	modemSource = source ;
	[ source setFileRepeat:NO ] ;
	
	//  create two AudioPipes
	//  these will really just be to switch the selected data streams to the BPFs
	
	//  pipeline for reference signal
	refPipe = [ [ ChannelSelector alloc ] pipeWithClient:refFilter ] ;
	[ refPipe selectChannel:reference ] ;
	refMixer = [ [ CMFSKMixer alloc ] init ] ;
	refDemod = [ [ CMRTTYMatchedFilter alloc ] initWithDefaultFilter ] ;  //  MS
	refATCBuffer = [ [ StereoRefATCBuffer alloc ] init ] ;
	stereoATC = [ [ MultiStereoATC alloc ] init ] ;
	[ stereoATC setInvert:sidebandState ] ;
	[ stereoATC setConfigClient:config ] ;
	if ( scope ) [ stereoATC setScope:scope ] ;

	[ refFilter setClient:refMixer ] ;
	[ refMixer setTonePair:&currentTonePair ] ;
	[ refMixer setClient:refDemod ] ;
	[ refDemod setClient:refATCBuffer ] ;
	[ refATCBuffer setClient:stereoATC ] ;		//  refATCBuffer calls importClockData
	
	//  pipeline for device under test
	dutPipe = [ [ ChannelSelector alloc ] pipeWithClient:dutFilter[1] ] ;
	[ dutPipe selectChannel:dut ] ;

	//  set up the AudioPipe pipeline
	mixer = [ [ CMFSKMixer alloc ] init ] ;
	[ mixer setTonePair:&currentTonePair ] ;
	
	selectedDUTFilter = dutFilter[1] ;
	[ self setFilterCutoffs ] ;
	
	//  create demodulators
	demod[0] = [ [ RTTYSingleFilter alloc ] initTone:0 ] ;				//  Mark-only
	demod[1] = [ [ RTTYSingleFilter alloc ] initTone:1 ] ;				//  Space-only
	demod[2] = [ [ RTTYMPFilter alloc ] initBitWidth:0.35 ] ;			//  MP+
	demod[3] = [ [ RTTYMPFilter alloc ] initBitWidth:0.70 ] ;			//  MP-
	demod[4] = [ [ CMRTTYMatchedFilter alloc ] initWithDefaultFilter ] ;  //  MS
	//  buffers
	bpfBuffer = [ [ CMTappedPipe alloc ] init ] ;
	demodBuffer = [ [ CMTappedPipe alloc ] init ] ;
	
	//  connect AudioPipes
	//  the audio pipeline starts at the source (the "input" ModemConfig)
	//  importData of the RTTYReceiver (self) will relay the data to various clients
	[ config setClient:self ] ;
	
	//  use BPF 1 (normal) as default bandpass
	[ self selectBandwidth:1 ] ;
	//  connect all BPF outputs to the bpfBuffer
	for ( i = 0; i < 5; i++ ) [ dutFilter[i] setClient:bpfBuffer ] ;
	[ bpfBuffer setClient:mixer ] ;

	//  create the different demodulators, hook all their outputs to the demodBuffer
	//  select demodulator 4 as the defualt demodulator
	[ self selectDemodulator:4 ] ;
	for ( i = 0; i < 5; i++ ) [ demod[i] setClient:demodBuffer ] ;
	[ demodBuffer setClient:stereoATC ] ;
		
	//  MultiATC produces Baudot, but it also has a couple of other outlets for RTTY Monitor probes
	[ stereoATC setClient:(CMTappedPipe*)decoder ] ;
}

- (ChannelSelector*)refPipe 
{
	return refPipe ;
}

//  select an input BPF
- (void)selectBandwidth:(int)index
{
	if ( bandwidthMatrix ) {
		[ bandwidthMatrix deselectAllCells ] ;
		[ bandwidthMatrix selectCellAtRow:0 column:index ] ;
		if ( index < 0 || index > 4 ) index = 1 ;
		selectedDUTFilter = dutFilter[index] ;
	}
	else {
		selectedDUTFilter = dutFilter[1] ;  //  nominal filter
	}
	[ dutPipe setClient:selectedDUTFilter ] ;
}

- (void)importData:(CMPipe*)pipe
{
	if ( !enabled ) return ;
	
	//  send data through the receiver processing chain
	if ( dutPipe ) [ dutPipe importData:pipe ] ;	// data ends up at importData of MultiStereoATC
	if ( refPipe ) [ refPipe importData:pipe ] ;	// data ends up at importClockData of MultiStereoATC
}

- (void)setFileRepeat:(Boolean)state
{
	[ modemSource setFileRepeat:state ] ;
}

@end
