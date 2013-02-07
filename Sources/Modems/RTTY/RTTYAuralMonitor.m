//
//  RTTYAuralMonitor.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/8/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "RTTYAuralMonitor.h"
#import "AppDelegate.h"
#import "Application.h"
#import "FSKHub.h"

@implementation RTTYAuralMonitor


static float sin32[] = {
	0.000,	0.195,	0.383,	0.556,	0.707,	0.831,	0.924,	0.981,
	1.000,	0.981,	0.924,	0.831,	0.707,	0.556,	0.383,	0.195,
	0.000, -0.195, -0.383, -0.556, -0.707, -0.831, -0.924, -0.981,
   -1.000, -0.981, -0.924, -0.831, -0.707, -0.556, -0.383, -0.195,
    0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000,  0.000 
} ;

//  v0.88c  "pitch" is between 400 and 1600
- (void)setClickPitch:(float)value
{
	int i ;
	float f, g ;
	
	f = 0.3*1000.0/( (2000.-value ) + 0.1 ) ;
	g = 2.3*f ;
	
	for ( i = 0; i < 512; i++ ) {
		clickBufferBeep[i] = ( sin( i*g )*0.4 + sin( i*g )*0.1 )*sqrt( 1 - cos( i*3.1415926/256 ) ) ; 
	}
}

//  v0.88
- (void)setPttDDA:(float)freq
{
	float period ;
	
	pttDDA = 0 ;						//  pttDDA goes from 0 to 1 (for 0 to 2.pi) for CMFs sampling rate
	period = 11025.0/freq ;
	pttMark = ( freq-85.0 )/CMFs ;
	pttSpace = ( freq+85.0 )/CMFs ;
	pttDDAdelta = pttSpace ;
	pttBitIndex = 0 ;
}

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		[ self setDDA:&receiveCarrier freq:1585.0 ] ;
		[ self setDDA:&transmitCarrier freq:1585.0 ] ;
		[ self setDDA:&receiveAuralCenter freq:1760.0 ] ;
		[ self setDDA:&transmitAuralCenter freq:1048.0 ] ;
		[ self setPttDDA:1048.0 ] ;

		demodulatorIsActive = monitorIsActive = NO ;
		rxMonitorOn = txMonitorOn = rxBackgroundOn = NO ;
		rxUseFloatingTone = txUseFloatingTone = NO ;
		rxGain = rxBaseGain = 0.25 ;
		txGain = txBaseGain = 0.05 ;
		rxBackgroundGain = rxBackgroundBaseGain = 0.05 ;
		agcVoltage = 1.0 ;
		
		//  v0.88 apply smoothing window if frames are skipped
		for ( i = 0; i < 512; i++ ) auralWindow[i] = ( 8 - cos( i*3.1415926/256 ) )*0.111 ;
		[ self setClickPitch:1000.0 ] ;			//  v0.88
		
		clickBufferActive = NO ;
		transmitEngaged = NO ;
		pttToneTimer = nil ;
		transmitType = 0 ;						//  default to AFSK transmit
		baudot = 0x1f ;							// LTRS
		pttBitIndex = pttSampleIndex = 0 ;
		emitBeep = NO ;
		clickVolume = 0 ;
		useSoftLimiting = NO ;
		
		[ self makeFilters ] ;
	}
	return self ;
}

- (void)makeFilters
{
	rxLowpassIFilter[0] = CMFIRLowpassFilter( 400.0, 11025.0, 512 ) ;
	rxLowpassQFilter[0] = CMFIRLowpassFilter( 400.0, 11025.0, 512 ) ;
	txLowpassIFilter[0] = CMFIRLowpassFilter( 400.0, 11025.0, 512 ) ;
	txLowpassQFilter[0] = CMFIRLowpassFilter( 400.0, 11025.0, 512 ) ;
}

- (void)setTonePair:(const CMTonePair*)tonepair
{
	[ self setDDA:&receiveCarrier freq:( tonepair->mark + tonepair->space )*0.5 ] ;
}

- (void)setTransmitTonePair:(const CMTonePair*)tonepair
{
	[ self setDDA:&transmitCarrier freq:( tonepair->mark + tonepair->space )*0.5 ] ;
}

//	ask auralMonitor to pull data from here
- (void)updateAuralMonitorState
{
	if ( ( muted == NO ) && ( demodulatorIsActive == YES ) ) {
		if ( monitorIsActive == NO ) [ auralMonitor addClient:self ] ;
		monitorIsActive = YES ;
	}
	else {
		if ( monitorIsActive == YES ) [ auralMonitor removeClient:self ] ;
		monitorIsActive = NO ;
	}
}

- (void)setDemodulatorActive:(Boolean)state
{
	demodulatorIsActive = state ;
	[ self updateAuralMonitorState ] ;
}

- (void)setOutputFrequency:(float)freq source:(int)source
{
	switch ( source ) {
	case AURALRECEIVE:
		[ self setDDA:&receiveAuralCenter freq:freq ] ; 
		break ;
	case AURALTRANSMIT:
		[ self setDDA:&transmitAuralCenter freq:freq ] ;
		break ;
	}
}

- (void)setFloatingTone:(Boolean)state source:(int)source
{
	switch ( source ) {
	case AURALRECEIVE:
		rxUseFloatingTone = state ;
		break ;
	case AURALTRANSMIT:
		txUseFloatingTone = state ;
		break ;
	}
}

- (void)setClickVolume:(float)value
{
	clickVolume = pow( value, 1.8 ) ;
}

- (void)setSoftLimit:(Boolean)state
{
	useSoftLimiting = state ;
}

- (void)setState:(Boolean)state source:(int)source
{
	switch ( source ) {
	case AURALRECEIVE:
		rxMonitorOn = state ; 
		break ;
	case AURALTRANSMIT:
		txMonitorOn = state ;
		break ;
	case AURALBACKGROUND:
		if ( rxBackgroundOn == NO ) memset( backgroundBuffer, 0, sizeof( float )*512 ) ;
		rxBackgroundOn = state ;
		break ;
	case AURALMASTER:
		muted = ( state == NO ) ;
		[ self updateAuralMonitorState ] ;
	}
}

//  (Private API)
- (void)setScalarGain:(float)gain source:(int)source
{
	switch ( source ) {
	case AURALRECEIVE:
		rxGain = ( rxBaseGain = gain )*masterGain ; 
		break ;
	case AURALTRANSMIT:
		txGain = ( txBaseGain = gain )*masterGain ;
		break ;
	case AURALBACKGROUND:
		rxBackgroundGain = ( rxBackgroundBaseGain = gain )*masterGain ;
		break ;
	case AURALMASTER:
		masterGain = gain ;
		rxBackgroundGain = rxBackgroundBaseGain*masterGain ;
		rxGain = rxBaseGain*masterGain ;
		txGain = txBaseGain*masterGain ;
		break ;
	}
}

- (void)setGain:(float)v source:(int)source
{
	[ self setScalarGain:v*v source:source ] ;
}

//	source: 0 = receiver, 1 = transmitter, 2 = background, 3 = master
- (void)setAttenuation:(int)db source:(int)source
{
	[ self setScalarGain:pow( 10.0, fabs( db )*(-0.05) ) source:source ] ;	//  v0.88 fabs()
}

//	(Private API)
- (void)submitBufferToAuralMonitor:(float*)si isReceiver:(Boolean)isReceiver 
{
	if ( isReceiver ) {
		[ auralMonitor addLeft:si right:nil samples:512 client:self ] ;	
	}
	else {
		[ auralMonitor addLeft:nil right:si samples:512 client:self ] ;
	}
}

//	(Private API)
- (void)newBandpassFilteredDataFromReceiver:(float*)array
{
	CMAnalyticPair vfo ;
	int i ;
	float u, v, si[512], sq[512], lpi[512], lpq[512] ;
	
	if ( rxUseFloatingTone == NO ) {
		//  narrowband - first mix down to baseband
		if ( useSoftLimiting ) {
			//  apply a maximum of 26 dB of AGC
			u = 0.01 ;
			for ( i = 0; i < 512; i++ ) {
				v = fabs( array[i] ) ;
				if ( v > u ) u = v ;
			}
			agcVoltage = agcVoltage*0.5 + 0.5*u ;
			v = rxGain*0.707/( agcVoltage + 0.001 ) ;
		}
		else v = rxGain ;	//  fixed gain

		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:&receiveCarrier ] ;
			u = array[i]*v ;
			si[i] = vfo.re*u ;
			sq[i] = vfo.im*u ;
		}

		//  lowpass the baseband signal
		CMPerformFIR( rxLowpassIFilter[0], si, 512, lpi ) ;
		CMPerformFIR( rxLowpassQFilter[0], sq, 512, lpq ) ;
		
		//  remodulate to target frequency
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:&receiveAuralCenter ] ;
			u = ( vfo.re*lpq[i] - vfo.im*lpi[i] )*2.0 ;
			si[i] = u ;
		}
	}
	else {
		if ( useSoftLimiting ) {
			//  apply a maximum of 26 dB of AGC
			u = 0.01 ;
			for ( i = 0; i < 512; i++ ) {
				v = fabs( array[i] ) ;
				if ( v > u ) u = v ;
			}
			agcVoltage = agcVoltage*0.5 + 0.5*u ;
			v = rxGain*0.707/( agcVoltage + 0.001 ) ;
		}
		else v = rxGain ;	//  fixed gain
	
		//  floating rx: just use input and apply rx gain
		for ( i = 0; i < 512; i++ ) si[i] = array[i]*v ;
	}
	
	//  merge background if on
	if ( rxBackgroundOn == YES ) for ( i = 0; i < 512; i++ ) si[i] += backgroundBuffer[i] ;

	if ( emitBeep ) {
		for ( i = 0; i < 512; i++ ) si[i] += clickBufferBeep[i]*clickVolume ;
		emitBeep = NO ;
	}

	[ self submitBufferToAuralMonitor:si isReceiver:YES ] ;		
}

//  v0.88c
- (void)emitBeep
{
	emitBeep = YES ;
}

//  v0.89
- (void)clickBufferCleared
{
	clickBufferActive = NO ;
}

//  v0.88 set from modems to indicate the click buffer is active (buffer rates higher than real time)
- (void)setClickBufferActive:(Boolean)state
{
	clickBufferActive = state ;
	if ( state == NO ) [ self emitBeep ] ;				//  v0.88c  beep when click buffer reaches real time
}

//	(Private API)
- (void)newBandpassFilteredDataFromTransmitter:(float*)array scale:(float)scale shift:(Boolean)shift
{
	CMAnalyticPair vfo ;
	int i ;
	float u, si[512], sq[512], lpi[512], lpq[512], gain ;
	
	gain = scale*txGain ;
	if ( shift == YES ) {
		//  narrow band, first mix down to baseband
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:&transmitCarrier ] ;
			u = array[i]*gain ;
			si[i] = vfo.re*u ;
			sq[i] = vfo.im*u ;
		}
		//  lowpass baseband
		CMPerformFIR( txLowpassIFilter[0], si, 512, lpi ) ;
		CMPerformFIR( txLowpassQFilter[0], sq, 512, lpq ) ;
		//  remodulate to target frequency
		for ( i = 0; i < 512; i++ ) {
			vfo = [ self updateDDA:&transmitAuralCenter ] ;
			si[i] = ( vfo.re*lpq[i] - vfo.im*lpi[i] )*2.0 ;
		}
	}
	else {
		//  floating tx: just use input and apply rx gain
		for ( i = 0; i < 512; i++ ) si[i] = array[i]*gain ;
	}
	[ self submitBufferToAuralMonitor:si isReceiver:NO ] ;		
}

//	Bandpass filtered RTTY signal (11025 s/s before mixing) arrives
- (void)newBandpassFilteredData:(float*)array scale:(float)scale fromReceiver:(Boolean)fromReceiver
{
	int i ;
	float localArray[512] ;
	
	if ( auralMonitor == nil || monitorIsActive == NO ) return ;
	
	//  v0.88 disable input to aural monitor while click buffer is active
	if ( [ self clickBufferBusy ] == YES ) {
		if ( [ self performClickBufferResampling ] == NO || rxMonitorOn == NO ) return ;
		//  inside click buffer but is the first of a series of accelerated buffers
		for ( i = 0; i < 512; i++ ) localArray[i] = array[i]*auralWindow[i] ;
		[ self newBandpassFilteredDataFromReceiver:localArray ] ;		//  v0.88 for new
		return ;
	}
	
	//  sanity check for internal PTT tone
	if ( transmitEngaged == NO && pttToneTimer != nil ) {
		[ pttToneTimer invalidate ] ;
		[ pttToneTimer release ] ;
		pttToneTimer = nil ;
	}
		
	if ( fromReceiver == YES ) {
		//  check if receiver enabled
		//  v0.89 need wideband also
		if ( ( rxMonitorOn == YES || rxBackgroundOn == YES ) && transmitEngaged == NO ) {
			[ self newBandpassFilteredDataFromReceiver:array ] ;
		}
		return ;
	}
	//  check if transmitter is enabled and if artificial tones is not seelcted
	if ( txMonitorOn == YES && transmitEngaged == YES ) {
		if ( transmitType == 0 ) {
			//  is AFSK transmitter
			[ self newBandpassFilteredDataFromTransmitter:array scale:1.0/( scale + 0.01 ) shift:!txUseFloatingTone ] ;
		}
	}
}

//  v0.88 Generate audio FSK transmit tones for FSK mode
- (void)pttToneTimerProc:(NSTimer*)timer
{
	float tone[512], pttGain ;
	int i, n ;
	
	if ( transmitEngaged == NO || transmitType == 0 ) return ;
	
	pttGain = txGain*2.2 ;
	
	for ( i = 0; i < 512; i++ ) {
		pttSampleIndex++ ;
		if ( pttSampleIndex >= 242 ) {
			//  Baudot bit boundary for 45.56 baud at 11025 samples/second
			pttSampleIndex = 0 ;
			pttBitIndex++ ;
			if ( pttBitIndex < 0 || pttBitIndex > 7 ) pttBitIndex = 0 ;
		
			if ( pttBitIndex == 0 ) {
				//  fetch (roughly) the most recently sent Baudot character
				baudot = [ [ [ [ NSApp delegate ] application ] fskHub ] currentBaudotCharacter ] ;
			}
			else if ( pttBitIndex >= 4 ) baudot >>= 1 ;
			
			//  Bits 0 and 1 and random data bit is a mark.  bit 2 is a space.
			pttDDAdelta = ( pttBitIndex == 0 || pttBitIndex == 1 || ( pttBitIndex != 2 && ( baudot & 1 ) == 1 ) ) ? pttMark : pttSpace ;
		}
		//  sine wave dda
		pttDDA += pttDDAdelta ;
		if ( pttDDA > 1.0 ) pttDDA -= 1.0 ;
		n = pttDDA * 32 ;
		tone[i] = pttGain*sin32[n] ;
	}
	//  send PTT tone samples
	[ self newBandpassFilteredDataFromTransmitter:tone scale:1.0 shift:NO ] ;
}

//  The artificial AFSK signal is genearted by a NSTimer loop
//	The NSTimer is run on a spearate (not main) thread so that button pushes do not affect the tarnsmit aural tones.
-(void)startGeneratorInSeparateThread
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	NSRunLoop *runLoop = [ NSRunLoop currentRunLoop ] ;
	
	pttToneTimer = [ NSTimer scheduledTimerWithTimeInterval:512.0/11025.0 target:self selector:@selector(pttToneTimerProc:) userInfo:self repeats:YES ] ;
	[ pttToneTimer retain ] ;	// keep timer thread alive
	[ runLoop run ] ;
	[ pool release ] ;
}

//	v0.88
//  transmitType = 0:AFSK, 1:FSK, 2:OOK
- (void)setTransmitState:(Boolean)state transmitType:(int)type
{
	transmitEngaged = state ;
	transmitType = type ;
	
	
	if ( transmitType == 0 && pttToneTimer != nil ) {
		//  sanity check
		[ pttToneTimer invalidate ] ;
		[ pttToneTimer release ] ;
		pttToneTimer = nil ;
	}
	if ( state == YES ) {
	
		if ( transmitType == 1 || transmitType == 2 ) {
			//  initialize FSK and OOK aural monitor to LTRS character (diddle)
			[ [ [ [ NSApp delegate ] application ] fskHub ] setCurrentBaudotCharacter:0x1f ] ;
		}
		if ( transmitType != 0 && txMonitorOn == YES && pttToneTimer == nil ) {
			//  generate tone
			pttBitIndex = pttSampleIndex = 0 ;
			pttDDAdelta = pttMark ;
			baudot = 0xff ;
			//  start timer in separate thread
			[ NSThread detachNewThreadSelector:@selector(startGeneratorInSeparateThread) toTarget:self withObject:nil ] ;
		}
	}
	else {
		if ( pttToneTimer != nil ) {
			[ pttToneTimer invalidate ] ;
			[ pttToneTimer release ] ;
			pttToneTimer = nil ;
		}
	}
}

//	Non-bandpass filtered RTTY signal (11025 s/s before BPF) arrives.
//	Since sampling rates are commensurate (the broadband data is in sync with the narrowband data.
//	Simply copy the gain adjusted data into a buffer that will later be merged.
- (void)newWidebandData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *array ;
	int i ;
	
	
	//  v0.89
	//if ( rxBackgroundOn == NO || rxMonitorOn == NO || auralMonitor == nil || monitorIsActive == NO ) return ;
	if ( rxBackgroundOn == NO || auralMonitor == nil || monitorIsActive == NO ) return ;

	
	//  v0.88
	if ( [ self clickBufferBusy ] == YES ) return ;

	stream = [ pipe stream ] ;
	array = stream->array ;
	for ( i = 0; i < 512; i++ ) backgroundBuffer[i] = array[i]*rxBackgroundGain ;
}

//  same as above but with floating point buffer
- (void)newWidebandBuffer:(float*)array
{
	int i ;

	//  v0.89
	if ( rxBackgroundOn == NO || auralMonitor == nil || monitorIsActive == NO ) return ;
	
	for ( i = 0; i < 512; i++ ) backgroundBuffer[i] = array[i]*rxBackgroundGain ;
}

@end
