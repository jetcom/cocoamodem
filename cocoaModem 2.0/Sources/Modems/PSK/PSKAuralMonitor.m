//
//  PSKAuralMonitor.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/11/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "PSKAuralMonitor.h"


@implementation PSKAuralMonitor


//	(Private API)
- (void)setCenterFrequencyAndDDA:(float)freq channel:(int)channel
{
	AuralChannel *p ;
	
	p = &trxChannel[channel] ;
	p->centerFrequency = freq ;
	if ( freq > 10 ) [ self setDDA:&p->carrier freq:freq ] ; 
}

//	(Private API)
- (void)setFixedFrequencyAndDDA:(float)freq channel:(int)channel
{
	AuralChannel *p ;
	
	p = &trxChannel[channel] ;
	p->fixedFrequency = freq ;
	if ( freq > 10 ) [ self setDDA:&p->outputTone freq:freq ] ; 
}



//	(Private API)
- (void)initChannel:(int)channel atten:(float)attenuation hasNarrow:(Boolean)hasNarrow
{
	AuralChannel *p ;
	
	p = &trxChannel[channel] ;
	p->enabled = NO ;			//  enabled in UI
	p->active = NO ;			//  selected in waterfall
	p->isFloating = YES ;		//  no need to shift input frequency
	
	if ( hasNarrow ) {
		[ self setCenterFrequencyAndDDA:1000 channel:channel ] ;
		[ self setFixedFrequencyAndDDA:800 channel:channel ] ;
		p->bandwidth = 15 ;
		p->bandpassFilter = CMFIRBandpassFilter( 1000-15, 1000+15, 11025.0, 512 ) ;
	}
	else {
		p->centerFrequency = p->fixedFrequency = 0 ;
		p->bandwidth = 0 ;
		p->bandpassFilter = nil ;
	}
}

//	(Private API)
- (void)makeLowpassFilters
{
	int i ;
	
	//  lowpass filters to pass up to PSK125	
	for ( i = 0; i < 2; i++ ) {
		rxLowpassIFilter[i] = CMFIRLowpassFilter( 200.0, 11025.0, 512 ) ;
		rxLowpassQFilter[i] = CMFIRLowpassFilter( 200.0, 11025.0, 512 ) ;
		txLowpassIFilter[i] = CMFIRLowpassFilter( 200.0, 11025.0, 512 ) ;
		txLowpassQFilter[i] = CMFIRLowpassFilter( 200.0, 11025.0, 512 ) ;
	}
}

- (id)init
{	
	self = [ super init ] ;
	if ( self ) {
		pskSampling = NO ;
		transmitChannel = 0 ;
		[ self initChannel:0 atten:0 hasNarrow:YES ] ;	//  rx0
		[ self initChannel:1 atten:0 hasNarrow:YES ] ;	//  rx1
		[ self initChannel:2 atten:6 hasNarrow:YES ] ;	//  tx0 & tx1
		[ self initChannel:3 atten:10 hasNarrow:NO ] ;	//  wideband
		[ self makeLowpassFilters ] ;
	}
	return self ;
}

//	(Private API)
- (void)mixAuralChannel:(AuralChannel*)p from:(float*)array into:(float*)outbuf
{
	CMDDA *q ;
	CMAnalyticPair vfo ;
	int i ;
	float gain, u, filtered[512], si[512], sq[512], lpi[512], lpq[512] ;
	
	gain = p->gain*masterGain ;
	CMPerformFIR( p->bandpassFilter, array, 512, filtered ) ;
	if ( p->isFloating ) {
		//  floating tone, simply mix bandpass output to aural output
		for ( i = 0; i < 512; i++ ) outbuf[i] += filtered[i]*gain ;
	}
	else {
		//  fixed tone, translate tone
		q = &p->carrier ;
		//  first mix down to baseband (si,sq)
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:q ] ;
			u = filtered[i] ;
			si[i] = vfo.re*u ;
			sq[i] = vfo.im*u ;
		}
		//  lowpass the baseband signal into (lpi,lpq)
		CMPerformFIR( rxLowpassIFilter[0], si, 512, lpi ) ;
		CMPerformFIR( rxLowpassQFilter[0], sq, 512, lpq ) ;
		//  remodulate to target frequency and mix into aural output
		q = &p->outputTone ;
		gain *= 2 ;
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:q ] ;
			outbuf[i] += ( vfo.re*lpq[i] - vfo.im*lpi[i] )*gain ;
		}
	}
}

//	(Private API)
- (void)setAuralChannel:(AuralChannel*)p usingMixer:(AuralChannel*)r from:(float*)array into:(float*)outbuf
{
	CMDDA *q ;
	CMAnalyticPair vfo ;
	int i ;
	float gain, u, filtered[512], si[512], sq[512], lpi[512], lpq[512] ;
	
	gain = p->gain*masterGain ;
	CMPerformFIR( r->bandpassFilter, array, 512, filtered ) ;
	if ( p->isFloating ) {
		//  floating tone, simply mix bandpass output to aural output
		for ( i = 0; i < 512; i++ ) outbuf[i] = filtered[i]*gain ;
	}
	else {
		//  fixed tone, translate tone
		q = &r->carrier ;
		//  first mix down to baseband (si,sq)
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:q ] ;
			u = filtered[i] ;
			si[i] = vfo.re*u ;
			sq[i] = vfo.im*u ;
		}
		//  lowpass the baseband signal into (lpi,lpq)
		CMPerformFIR( rxLowpassIFilter[0], si, 512, lpi ) ;
		CMPerformFIR( rxLowpassQFilter[0], sq, 512, lpq ) ;
		//  remodulate to target frequency and mix into aural output
		q = &p->outputTone ;
		gain *= 2 ;
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:q ] ;
			outbuf[i] = ( vfo.re*lpq[i] - vfo.im*lpi[i] )*gain ;
		}
	}
}

//	data at 11025 s/s arrives here
- (void)importWidebandData:(CMPipe*)pipe 
{
	float gain, *array, outbuf[512] ;
	int i ;
	CMDataStream *stream ;
	AuralChannel *p ;
	
	if ( pskSampling == NO ) return ;
	
	//  input wideband stream
	stream = [ pipe stream ] ;
	array = stream->array ;

	//  acumulate components into output buffer
	//  Start by initializing the output buffer with the wideband buffer, or clear the output buffer
	p = &trxChannel[3] ;
	if ( p->enabled ) {
		gain = p->gain*masterGain ;
		for ( i = 0; i < 512; i++ ) outbuf[i] = array[i]*gain ;
	}
	else memset( outbuf, 0, 512*sizeof( float ) ) ;
	
	//  rx1
	p = &trxChannel[0] ;
	if ( p->enabled && p->active ) [ self mixAuralChannel:p from:array into:outbuf ] ;
	//  rx2
	p = &trxChannel[1] ;
	if ( p->enabled && p->active ) [ self mixAuralChannel:p from:array into:outbuf ] ;

	[ auralMonitor addLeft:outbuf right:nil samples:512 client:self ] ;
}

//	data at 11025 s/s arrives here
- (void)importTransmitData:(float*)array 
{
	AuralChannel *p ;
	float outbuf[512] ;
	
	if ( pskSampling == NO ) return ;
	
	p = &trxChannel[2] ;
	if ( p->enabled && p->active ) {
		//  input wideband stream
		[ self setAuralChannel:p usingMixer:&trxChannel[transmitChannel] from:array into:outbuf ] ;
		[ auralMonitor addLeft:nil right:outbuf samples:512 client:self ] ;
	}
}

- (void)transmitOnReceiver:(int)n
{
	transmitChannel = n & 1 ;
}

//	(Private PI)
- (Boolean)shouldBeSampling
{
	int i ;

	if ( demodulatorIsActive == NO || muted == YES ) return NO ;	//  unqualified NO if muted or interface not visible
	//  otherwise check wideband (can be on even when not clicked)
	if ( trxChannel[3].enabled == YES  ) return YES ;
	
	//  now check if a channel is enabled and clicked
	for ( i = 0; i < 3; i++ ) {
		if ( trxChannel[i].enabled == YES && trxChannel[i].active == YES ) return YES ;
	}
	return NO ;
}

//	(Private API)
- (void)updateSamplingState
{
	Boolean wasSampling, isSampling ;
	
	wasSampling = pskSampling ;
	
	isSampling = [ self shouldBeSampling ] ;
	if ( wasSampling != isSampling ) {
		if ( isSampling == YES ) [ auralMonitor addClient:self ] ; else [ auralMonitor removeClient:self ] ;
		pskSampling = isSampling ;
	}
}

- (void)setMute:(Boolean)state
{
	muted = state ;
	[ self updateSamplingState ] ;
}

- (void)setMasterGain:(float)value
{
	masterGain = value*value ;
}

- (void)setModemActive:(Boolean)state
{
	demodulatorIsActive = state ;
	[ self updateSamplingState ] ;
}

//	channel: 0, 1 = receivers, 2 = transmitter
- (void)setFloating:(Boolean)state forChannel:(int)channel 
{
	if ( channel == 0 || channel == 1 || channel == 2 ) {
		trxChannel[ channel ].isFloating = state ;
	}
}

//	channel: 0, 1 = receivers, 2 = transmitter
- (void)setFixedFrequency:(float)freq forChannel:(int)channel 
{
	if ( channel == 0 || channel == 1 || channel == 2 ) {
		[ self setFixedFrequencyAndDDA:freq channel:channel ] ;
	}
}

//	channel: 0, 1 = receivers, 2 = transmitter, 3 = wideband
- (void)setEnable:(Boolean)state channel:(int)channel ;
{
	if ( channel >= 0 && channel <= 3 ) {
		trxChannel[ channel ].enabled = state ;
		[ self updateSamplingState ] ;
	}
}

//  (Private API)
- (void)setScalarGain:(float)scalar channel:(int)channel ;
{
	if ( channel >= 0 && channel <= 3 ) {
		trxChannel[ channel ].gain = scalar ;
	}
}

//	channel: 0 = receiver, 1 = transmitter, 2 = background, 3 = master
- (void)setAttenuation:(float)db channel:(int)channel
{
	[ self setScalarGain:pow( 10.0, fabs( db )*(-0.05) ) channel:channel ] ;		//  v0.88 fabs()
}

//	set frequency and activate
- (void)setCenterFrequency:(float)freq bandwidth:(float)bandwidth channel:(int)channel
{
	AuralChannel *p ;

	p = &trxChannel[channel] ;
	if ( p->centerFrequency != freq || p->bandwidth != bandwidth ) {
		CMUpdateFIRBandpassFilter( trxChannel[channel].bandpassFilter, freq-bandwidth, freq+bandwidth ) ;
		[ self setCenterFrequencyAndDDA:freq channel:channel ] ;
		p->bandwidth = bandwidth ;
	}
	trxChannel[channel].active = YES ;
	trxChannel[2].active = YES ;			//  also make tx active
	[ self updateSamplingState ] ;
}

- (void)disactivateChannel:(int)channel
{
	if ( channel == 0 || channel == 1 || channel == 2 ) {
		trxChannel[ channel ].active = NO ;
		trxChannel[2].active = ( trxChannel[0].active && trxChannel[1].active  ) ;	//  update tx active
		[ self updateSamplingState ] ;
	}
}


@end
