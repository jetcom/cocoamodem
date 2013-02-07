//
//  CWReceiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/2/06.
	#include "Copyright.h"
	
#import "CWReceiver.h"
#import "CWAuralFilter.h"
#import "CWDemodulator.h"
#import "CWMonitor.h"
#import "CWRxControl.h"

//enum LockCondition {
//	kNoData,
//	kHasData
//} ;

@implementation CWReceiver

- (id)initReceiver:(int)index modem:(Modem*)modem
{
	CMTonePair defaultTones = { 1500, 0.0, 45.45 } ;
	
	self = [ super init ] ;
	if ( self ) {
		uniqueID = index ;
		receiveView = nil ;
		cwRxControl = nil;
		squelch = nil ;
		currentTonePair = defaultTones ;
		enabled = slashZero = sidebandState = NO ;
		demodulatorModeMatrix = nil ;					//  only used by RTTYReceiver
		bandwidthMatrix = nil ;							//  only used by RTTYReceiver
		appleScript = nil ;
		monitor = nil ;
		
		buffer = 0 ; 
		[ self changingStateTo:NO ] ;
		
		cwBandwidth = 100.0 ;
		cwFrequency = defaultTones.mark ;
		sidetoneFrequency = 689.0 ;
		sidetoneFilter = CMFIRBandpassFilter( sidetoneFrequency-cwBandwidth, sidetoneFrequency+cwBandwidth, CMFs, 64 ) ;
		
		vco = [ [ CMPCO alloc ] init ] ;
		[ vco setOutputScale:1.0 ] ;
		[ vco setCarrier:sidetoneFrequency ] ;
		
		//  local CMDataStream
		cmData.samplingRate = 11025.0 ;
		cmData.samples = 512 ;
		cmData.components = 1 ;
		cmData.channels = 1 ;
		data = &cmData ;
		newData = [ [ NSConditionLock alloc ] initWithCondition:kNoData ] ;
		[ NSThread detachNewThreadSelector:@selector(receiveThread:) toTarget:self withObject:self ] ;
		clickBufferLock = nil ;
		
		demodulator = [ [ CWDemodulator alloc ] initFromReceiver:self ] ;
		aural = [ [ CWAuralFilter alloc ] initFromReceiver:self ] ;
		bandpassFilter = nil ;		
		[ self updateFilters ] ;
		
		return self ;
	}
	return nil ;
}

- (void)setupReceiverChain:(ModemConfig*)config monitor:(CWMonitor*)mon
{
	monitor = mon ;
	//  decoder
	[ demodulator setupDemodulatorChain ] ;
	[ demodulator setDelegate:self ] ;	//  demodulator calls back to receivedCharacter: delegate
	//  aural
	[ aural setupDemodulatorChain ] ;
	[ aural setDelegate:self ] ;	//  demodulator calls back to receivedCharacter: delegate
}

- (void)setCWSpeed:(float)wpm limited:(Boolean)limited
{
	int n ;
	
	n = wpm + 0.5 ;
	if ( cwRxControl ) [ cwRxControl setReportedSpeed:n limited:limited] ;
}

- (void)setMonitorEnable:(Boolean)state
{
	if ( cwRxControl ) [ cwRxControl setMonitorEnableButton:state ] ;
}

- (void)changeCodeSpeedTo:(int)speed
{
	[ (CWDemodulator*)demodulator changeCodeSpeedTo:speed ] ;
}

- (void)newClick:(float)delta
{
	[ (CWDemodulator*)demodulator newClick:delta ] ;
	[ aural newClick:delta ] ;
}

- (void)setLatency:(int)value
{
	[ (CWDemodulator*)demodulator setLatency:value ] ;
}

- (void)changeSquelchTo:(float)db fastQSB:(float)fast slowQSB:(float)slow
{
	[ (CWDemodulator*)demodulator changeSquelchTo:db fastQSB:fast slowQSB:slow ] ;
}

- (void)changingStateTo:(Boolean)state
{
	//  CW receiver enable
}

- (void)received:(float*)inph quadrature:(float*)quad wide:(float*)wide samples:(int)n
{
	[ monitor push:inph quadrature:quad wide:wide samples:n ] ;		//  v0.78
}

- (void)setSidetoneFrequency:(float)freq
{
	sidetoneFrequency = freq ;
	[ self updateFilters ] ;
	[ vco setCarrier:sidetoneFrequency ] ;
}

//  called from CWMonitor when it needs another buffer for the sound device
- (void)needSidetone:(float*)outbuf inphase:(float*)inph quadrature:(float*)quad wide:(float*)wide samples:(int)n wide:(Boolean)iswide
{
	int i ;
	float x, y, intermediate[512] ;
	CMAnalyticPair pair ;
	
	if ( iswide ) {
		// wideband request
		memcpy( outbuf, wide, sizeof( float )*n ) ;
		return ;
	}
	//  narrowband request
	for ( i = 0; i < n; i++ ) {
		x = inph[ i ] ;
		y = quad[ i ] ;
		//  sidetone oscillator
		pair = [ vco nextVCOPair ] ;
		intermediate[i] = x*pair.re + y*pair.im ;
	}	
	CMPerformFIR( sidetoneFilter, intermediate, 512, outbuf ) ;
}

- (void)updateFilters
{
	float low, high ;
	
	low = sidetoneFrequency-cwBandwidth ;
	if ( low < 100 ) low = 100 ;
	high = sidetoneFrequency+cwBandwidth ;
	if ( high > 2800 ) high = 2800 ;
	CMUpdateFIRBandpassFilter( sidetoneFilter, low, high ) ;
}

- (void)rxTonePairChanged:(RTTYRxControl*)control
{
	CMTonePair tonePair ;
	
	cwRxControl = (CWRxControl*)control ;
	tonePair = [ control rxTonePair ] ;
	cwFrequency = tonePair.mark ;
	[ self updateFilters ] ;
	//  set mixer tones
	[ demodulator setTonePair:&tonePair ] ;
	[ aural setTonePair:&tonePair ] ;
}

//  set bandpass filter bandwidth for the receiver and any filters in the demodulator
- (void)setCWBandwidth:(float)bandwidth
{
	cwBandwidth = bandwidth ;
	[ self updateFilters ] ;
	if ( demodulator ) [ (CWDemodulator*)demodulator setCWBandwidth:cwBandwidth ] ;
	if ( aural ) [ aural setCWBandwidth:cwBandwidth ] ;
}

//  if the waterfall is clicked, the CWRxControl sends data here
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *array, *buf ;

	//  send data to aural filter pipeline
	[ aural importData:pipe ] ;

	//  check if we have a click buffer by looking to see if a lock exists
	if ( clickBufferLock != nil ) {
		if ( [ clickBufferLock tryLock ] ) {
			[ newData lockWhenCondition:kNoData ] ;
			//  copy data into tail of clickBuffer
			stream = [ pipe stream ] ;
			array = stream->array ;
			//  copy another 512 samples into the click buffer (memcpy has problems with auto release pools?)
			buf = clickBuffer[clickBufferProducer] ;
			clickBufferProducer = ( clickBufferProducer+1 ) & 0x1ff ; // 512 click buffers
			memcpy( buf, array, 512*sizeof( float ) ) ;
			//  run the receive thread
			cmData.userData = stream->userData ;
			cmData.sourceID = stream->sourceID ;
			// signal receiveThread of new block of data that new data has arrived
			[ newData unlockWithCondition:kHasData ] ;
			[ clickBufferLock unlock ] ;
		}
	}
	else {
		//  no click buffer -- simply use input stream
		[ demodulator importData:pipe ] ;
	}
}

@end
