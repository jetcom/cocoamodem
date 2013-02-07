//
//  SITORReceiver.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/6/06.
	#include "Copyright.h"

#import "SITORReceiver.h"
#import "Modem.h"
#import "RTTYSingleFilter.h"
#import "RTTYMPFilter.h"
#import "SITORDemodulator.h"
#import "SITORRxControl.h"

@implementation SITORReceiver

- (id)initReceiver:(int)index modem:(Modem*)modem
{
	CMTonePair defaultTones = { 2125.0, 2295.0, 100.0 } ;
	CMFSKMatchedFilter *mf ;
	float baudrate ;
	
	self = [ super initSuperReceiver:index ] ;
	if ( self ) {
		uniqueID = index ;
		app = [ modem application ] ;		//  v0.96d
		receiveView = nil ;
		squelch = nil ;
		currentTonePair = defaultTones ;
		enabled = slashZero = sidebandState = NO ;
		appleScript = nil ;
		usos = YES ;
		
		demodulator = [ [ SITORDemodulator alloc ] initFromReceiver:self ] ;		//  v0.79 bugfix -- was calling init instead of initFromReceiver
		
		bandpassFilter = [ [ CMFilterBank alloc ] init ] ;
		matchedFilter = [ [ CMFilterBank alloc ] init ] ;
		
		// create bandpass filter bank
		bpf[0] = [ demodulator makeFilter:300.0 ] ;
		bpf[1] = [ demodulator makeFilter:425.0 ] ;
		bpf[2] = [ demodulator makeFilter:600.0 ] ;
		bpf[3] = [ demodulator makeFilter:725.0 ] ;
		bpf[4] = [ demodulator makeFilter:1000.0 ] ;
		[ bandpassFilter installFilter:bpf[0] ] ;
		[ bandpassFilter installFilter:bpf[1] ] ;
		[ bandpassFilter installFilter:bpf[2] ] ;
		[ bandpassFilter installFilter:bpf[3] ] ;
		[ bandpassFilter installFilter:bpf[4] ] ;
		[ bandpassFilter selectFilter:1 ] ;
		[ demodulator useBandpassFilter:bandpassFilter ] ;
		
		//  create matched filter bank
		baudrate = 100.0 ;		
		mf = [ [ RTTYSingleFilter alloc ] initTone:0 baud:baudrate ] ;
		[ mf setDataRate:baudrate ] ;
		[ matchedFilter installFilter:mf ] ;				//  Mark-only
		
		mf = [ [ RTTYSingleFilter alloc ] initTone:1 baud:baudrate ] ;
		[ mf setDataRate:baudrate ] ;
		[ matchedFilter installFilter:mf ] ;				//  Space-only
		
		mf = [ [ RTTYMPFilter alloc ] initBitWidth:0.35 baud:baudrate ] ;
		[ mf setDataRate:baudrate ] ;
		[ matchedFilter installFilter:mf ] ;				//  MP+
		
		mf = [ [ RTTYMPFilter alloc ] initBitWidth:0.70 baud:baudrate ] ;
		[ mf setDataRate:baudrate ] ;
		[ matchedFilter installFilter:mf ] ;				//  MP-
		
		mf = [ [ CMFSKMatchedFilter alloc ] initDefaultFilterWithBaudRate:baudrate ] ;
		[ mf setDataRate:baudrate ] ;
		[ matchedFilter installFilter:mf ] ;				//  MS
		
		[ matchedFilter selectFilter:4 ] ;
		[ demodulator useMatchedFilter:matchedFilter ] ;
		
		return self ;
	}
	return nil ;
}

- (void)setControl:(SITORRxControl*)control
{
	if ( demodulator ) [ (SITORDemodulator*)demodulator setControl:control ] ;
}

// test
- (void)setSquelchValue:(float)value
{
	if ( squelch ) {
		[ squelch setFloatValue:value ] ;
		[ demodulator setSquelch:value ] ;
	}
}

@end
