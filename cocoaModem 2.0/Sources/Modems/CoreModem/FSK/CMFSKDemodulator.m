//
//  CMFSKDemodulator.m
//  CoreModem
//
//  Created by Kok Chen on 10/24/05.
	#include "Copyright.h"

#import "CMFSKDemodulator.h"
#import "CMATC.h"
#import "CMBaudotDecoder.h"
#import "RTTYAuralMonitor.h"
#import "RTTYMixer.h"
#import "RTTYReceiver.h"
#import "CMFSKMatchedFilter.h"
#import "CMFSKTypes.h"

@implementation CMFSKDemodulator


//  Initialize default filters
- (void)initPipelineStages:(CMTonePair*)pair decoder:(CMBaudotDecoder*)decoder atc:(CMPipe*)atc bandwidth:(float)bandwidth
{
	CMFSKPipeline *p ;
	CMFSKMatchedFilter *matchedFilter ;
	
	isRTTY = YES ;
	tonePair = *pair ;
	p = (CMFSKPipeline*)( pipeline = ( void* )malloc( sizeof( CMFSKPipeline ) ) ) ;
	
	// -- bandpass filter
	p->bandpassFilter = p->originalBandpassFilter = [ self makeFilter:bandwidth ] ;
	
	// -- matched filter, change baud rate to match tone pair
	matchedFilter = [ [ CMFSKMatchedFilter alloc ] initDefaultFilterWithBaudRate:tonePair.baud ] ;
	[ matchedFilter setDataRate:tonePair.baud ] ;
	p->matchedFilter = p->originalMatchedFilter = matchedFilter ;
	
	//  -- RTTY mixer
	p->mixer = [ [ RTTYMixer alloc ] init ] ;
	[ p->mixer setTonePair:&tonePair ] ;
	[ p->mixer setDemodulator:self ] ;				//  v0.78
	[ p->mixer setAuralMonitor: [ receiver rttyAuralMonitor ] ] ;
	//  -- adaptive thresholder
	p->atc = (CMATC*)atc ;	
	[ p->atc setInvert:sidebandState ] ;
	[ p->atc setBitSamplingFromBaudRate:tonePair.baud ] ;
	
	//  -- Baudot decoder, sends data back to -receivedCharacter: of self
	p->decoder = decoder ;
}

- (id)initFromReceiver:(RTTYReceiver*)rcvr
{
	CMTonePair defaultTonePair = { 2125.0, 2295.0, 45.45 } ;
	CMBaudotDecoder *decoder ;
	CMATC *atc ;

	self = [ super init ] ;
	if ( self ) {
		isRTTY = YES ;
		delegate = nil ;
		receiver = rcvr ;
		decoder = [ [ CMBaudotDecoder alloc ] initWithDemodulator:self ] ;
		atc = [ [ CMATC alloc ] init ] ;
		[ self initPipelineStages:&defaultTonePair decoder:decoder atc:atc bandwidth:306.35 ] ;
	}
	return self ;
}

- (id)initSuper
{
	self = [ super init ] ;
	return self ;
}

- (void)dealloc
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;
	
	[ self setClient:nil ] ;
	[ p->decoder release ] ;
	[ p->atc release ] ;
	[ p->mixer release ] ;
	if ( p->bandpassFilter == p->originalBandpassFilter ) [ p->bandpassFilter release ] ;
	if ( p->matchedFilter == p->originalMatchedFilter ) [ p->matchedFilter release ] ;
	free( pipeline ) ;
	[ super dealloc ] ;
}

- (RTTYReceiver*)receiver
{
	return receiver ;
}

- (Boolean)isRTTY
{
	return isRTTY ;
}

- (CMFSKMixer*)mixer
{
	return ( (CMFSKPipeline*)pipeline )->mixer ;
}

- (void)makeDemodulatorActive:(Boolean)state
{
	if ( isRTTY && receiver != nil ) [ [ receiver rttyAuralMonitor ] setDemodulatorActive:state ] ;
}

- (void)replaceDecoderWith:(CMBaudotDecoder*)decoder
{
	if ( decoder ) {
		CMFSKPipeline *p = (CMFSKPipeline*)pipeline ;
		if ( p->decoder ) [ p->decoder release ] ;
		p->decoder = decoder ;
	}
}

//  overide base class to change AudioPipe pipeline (assume source is normalized baud rate)
//		self (importData:)
//		. bandpassFilter
//		. mixer
//		. matchedFilter
//		. ATC
//		. BaudotDecoder
//		. self (receivedCharacter:)

- (void)setupDemodulatorChain
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;

	//  connect AudioPipes
	[ p->atc setClient:p->decoder ] ;
	[ p->matchedFilter setClient:p->atc ] ;
	[ p->mixer setClient:p->matchedFilter ] ;
	[ p->bandpassFilter setClient:p->mixer ] ;
	[ self setClient:p->bandpassFilter ] ;			//  importData is exported to bandpassFilter by base class
}

//  v0.88d
- (void)setConfig:(ModemConfig*)config
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline ;
	[ p->mixer setConfig:config ] ;
}

- (void)setBitsPerCharacter:(int)bits
{
	[ ( (CMFSKPipeline*)pipeline )->atc setBitsPerCharacter:bits ] ;
}

- (void)importData:(CMPipe*)pipe
{	
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;
	
	//  send data through the processing chain starting at the bandpass filter
	if ( p->bandpassFilter ) [ p->bandpassFilter importData:pipe ] ;
}

//  v0.76 tap client (used by RTTYMonitor) is now the matched filter output
- (void)setTap:(CMPipe*)tap
{
	[ ( (CMFSKPipeline*)pipeline )->matchedFilter setTap:tap ] ;
}

//  NOTE: this is no longer called
- (void)exportData
{
	if ( outputClient ) {
		if ( isPipelined ) [ outputClient importPipelinedData:self ] ; else [ outputClient importData:self ] ;
	}
}

//  return a CMBandpassFilter that has passband centered around the current mark and space carriers.
- (CMBandpassFilter*)makeFilter:(float)width
{
	float lower, upper, delta, shift ;
	CMBandpassFilter *f ;
	
	if ( tonePair.mark < tonePair.space ) {
		lower = tonePair.mark ;
		upper = tonePair.space ;
	}
	else {
		lower = tonePair.space ;
		upper = tonePair.mark ;
	}
	shift = upper - lower ;
	delta = ( width - shift )*0.5 ;
	if ( delta < 0.0 ) delta = 0.0 ;
	
	f = [ [ CMBandpassFilter alloc ] initLowCutoff:lower-delta highCutoff:upper+delta length:256 ] ;
	[ f setUserParam:delta ] ;
	return f ;
}

//  retrieves userParam from bandpass filter and update passband based on current mark and space
- (void)updateFilter:(CMBandpassFilter*)f
{
	float lower, upper, delta ;
	
	if ( tonePair.mark < tonePair.space ) {
		lower = tonePair.mark ;
		upper = tonePair.space ;
	}
	else {
		lower = tonePair.space ;
		upper = tonePair.mark ;
	}
	delta = [ f userParam ] ;
	if ( delta < 0.0 ) delta = 0.0 ;
	[ f updateLowCutoff:lower-delta highCutoff:upper+delta ] ;
}

- (void)setDelegate:(id)inDelegate
{
	delegate = inDelegate ;
}

- (id)delegate
{
	return delegate ;
}

//  called from Baudot decoder when a new character is decoded
- (void)receivedCharacter:(int)c
{
	if ( delegate && [ delegate respondsToSelector:@selector(receivedCharacter:) ] ) [ delegate receivedCharacter:c ] ;
}

- (void)useMatchedFilter:(CMPipe*)mf
{
	CMPipe *old ;
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;
	
	if ( p->matchedFilter == mf ) return ;
	old = p->matchedFilter ;
	[ mf setClient:p->atc ] ;
	[ p->mixer setClient:mf ] ;
	p->matchedFilter = (CMFSKMatchedFilter*)mf ;
	[ old release ] ;
}

- (void)useBandpassFilter:(CMPipe*)bpf
{
	CMPipe *old ;
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;
	
	if ( p == nil || p->bandpassFilter == bpf ) return ;
	old = p->bandpassFilter ;
	[ bpf setClient:p->mixer ] ;
	[ self setClient:bpf ] ;
	p->bandpassFilter = (CMBandpassFilter*)bpf ;
	[ old release ] ;
}

//  set up the tone pair and baud rate parameters of the demodulator
- (void)setTonePair:(const CMTonePair*)inTonePair
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;
	
	tonePair = *inTonePair ;
	if ( p->mixer ) [ p->mixer setTonePair:&tonePair ] ;
	if ( p->atc ) [ p->atc setBitSamplingFromBaudRate:tonePair.baud ] ;
}

- (void)setEqualizer:(int)index
{
	if ( ( (CMFSKPipeline*)pipeline )->atc ) [ ( (CMFSKPipeline*)pipeline )->atc setEqualize:index ] ;
}

//  unshift-on-space, pass it on to the Baudot decoder
- (void)setUSOS:(Boolean)state
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;

	if ( p != nil ) [ p->decoder setUSOS:state ] ;
}

- (void)setBell:(Boolean)state
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;

	if ( p != nil ) [ p->decoder setBell:state ] ;
}

- (void)setLTRS:(Boolean)state
{
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline ;
	
	if ( p->decoder ) [ p->decoder setLTRS ] ;
}

- (void)setSquelch:(float)value
{
	if ( ( (CMFSKPipeline*)pipeline )->atc ) [ ( (CMFSKPipeline*)pipeline )->atc setSquelch:value ] ;
}

- (CMPipe*)baudotWaveform
{
	return ( (CMFSKPipeline*)pipeline )->atc ;
}

- (CMPipe*)atcWaveform
{
	return [ ( (CMFSKPipeline*)pipeline )->atc atcWaveformBuffer ] ;
}
	
@end
