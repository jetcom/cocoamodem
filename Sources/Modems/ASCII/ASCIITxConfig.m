//
//  ASCIITxConfig.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/30/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCIITxConfig.h"
#import "Application.h"
#import "ASCIIModulator.h"
#import "FSK.h"
#import "Messages.h"
#import "ModemDest.h"
#import "ModemEqualizer.h"
#import "Plist.h"
#import "RTTY.h"
#import "RTTYReceiver.h"
#import "RTTYRxControl.h"


@implementation ASCIITxConfig

static float stopDuration[3] = { 1.0, 1.5, 2.0 } ;


- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control
{
	rttyRxControl = nil ;
	rttyAuralMonitor = nil ;
	configSet = *set ;
	
	transmitBPF = nil ;
	fir = nil ;
	hasSetupDefaultPreferences = hasRetrieveForPlist = hasUpdateFromPlist = NO ;
	equalize = 1.0 ;
	fsk = nil ;	
	ook = 0 ;
	
	//  set output to defaults
	if ( set->outputDevice ) {
		currentLow = currentHigh = 0 ;
		afsk = [ [ ASCIIModulator alloc ] init ] ;
		[ afsk setModemClient:modemObj ] ;
				
		[ self setupModemDest:set->outputDevice controlView:soundOutputControls attenuatorView:soundOutputLevel ] ;
		[ modemDest setSoundLevelKey:set->outputLevel attenuatorKey:set->outputAttenuator ] ;
		//  color well changes
		[ self setInterface:transmitTextColor to:@selector(colorChanged) ] ;
		//  Transmit equalizer
		equalizer = [ [ ModemEqualizer alloc ] initSheetFor:set->outputDevice ] ;
	}
}

//  preferences maintainence, called from ASCII.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	if ( hasSetupDefaultPreferences ) return ;		// already done (for interfaces with multiple receivers)
	hasSetupDefaultPreferences = YES ;
	
	rttyRxControl = control ;
	
	if ( configSet.stopBits ) [ pref setFloat:2.0 forKey:configSet.stopBits ] ;
	[ self set:configSet.sentColor fromRed:0.0 green:0.8 blue:1.0 into:pref ] ;
	[ modemDest setupDefaultPreferences:pref ] ;
	if ( equalizer ) [ equalizer setupDefaultPreferences:pref ] ;
}

//  called from ASCII.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control 
{
	int index, version ;
	float stopValue ;

	if ( hasUpdateFromPlist ) return YES ;		// already done (for interfaces with multiple receivers)
	hasUpdateFromPlist = YES ;

	rttyRxControl = control ;
	
	[ self updateColorsFromPreferences:(Preferences*)pref configSet:&configSet ] ;

	if ( ![ modemDest updateFromPlist:pref ] ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"ASCII settings needs to be reselected", nil ) informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}	
	if ( equalizer ) [ equalizer updateFromPlist:pref ] ;

	//  stop bits
	if ( configSet.stopBits ) stopValue = [ pref floatValueForKey:configSet.stopBits ] ;
	version = [ pref intValueForKey:kPrefVersion ] ;
	
	// fix bug in simple RTTY (not connected) stop value
	if ( stopValue < 1.1 && version == 2 ) stopValue = 1.5 ;
	
	index = 1 ;
	if ( stopValue < 1.1 ) index = 0 ; else if ( stopValue > 1.9 ) index = 2 ;
	if ( configSet.stopBits ) {
		if ( stopBits ) [ stopBits selectCellAtRow:index column:0 ] ;
		if ( afsk ) [ afsk setStopBits:stopValue ] ;
	}
	return true ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	int index ;
	
	if ( hasRetrieveForPlist ) return ;		// already done (for interfaces with multiple receivers)
	hasRetrieveForPlist = YES ;
	
	rttyRxControl = control ;

	[ self set:configSet.sentColor fromColor:[ transmitTextColor color ] into:pref ] ;
	//  rtty output prefs
	[ modemDest retrieveForPlist:pref ] ;	
	if ( equalizer ) [ equalizer retrieveForPlist:pref ] ;
	// stop bits
	if ( stopBits ) {
		index = [ stopBits selectedRow ] ;
		[ pref setFloat:stopDuration[index] forKey:configSet.stopBits ] ;
	}
}

//  -------------- transmit stream ---------------------

- (Boolean)startTransmit
{
	CMTonePair *tonepair ;
	float midFrequency ;
	
	if ( fsk ) return [ self startFSKTransmit ] ;		// v0.50		

	//  adjust amplitude based on equalizer here
	tonepair = [ afsk toneFrequencies ] ;
	midFrequency = ( tonepair->mark + tonepair->space )*0.5 ;
	equalize = [ equalizer amplitude:midFrequency ] ;
	
	if ( !isTransmit && !configOpen ) {
		toneIndex = 0 ;
		[ modemDest stopSampling ] ;
		[ afsk appendString:"|" clearExistingCharacters:NO ] ;  //  send a long mark
		[ modemDest startSampling ] ;
		if ( transmitButton ) {
			[ transmitButton setTitle:NSLocalizedString( @"Receive", nil ) ] ;
			[ transmitButton setState:NSOnState ] ;
		}
		isTransmit = YES ;
		return YES ;
	}
	isTransmit = NO ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
	if ( transmitButton ) {
		[ transmitButton setTitle:NSLocalizedString( @"Transmit", nil ) ] ;
		[ transmitButton setState:NSOffState ] ;
	}
	if ( configOpen ) {
		[ Messages alertWithMessageText:NSLocalizedString( @"Close Config Panel", nil ) informativeText:NSLocalizedString( @"Close Config Panel and try Again", nil ) ] ;
		[ modemObj flushAndLeaveTransmit ] ;
	}
	return NO ;
}

//  v0.50
- (Boolean)stopFSKTransmit
{
	if ( isTransmit ) {
		isTransmit = NO ;
		[ fsk stopSampling ] ;
		if ( transmitButton ) {
			[ transmitButton setTitle:NSLocalizedString( @"Transmit", nil ) ] ;
			[ transmitButton setState:NSOffState ] ;
		}
		[ fsk clearOutput ] ;
		[ modemObj transmissionEnded ] ;
	}
	return NO ;
}

- (Boolean)stopTransmit
{
	if ( fsk ) return [ self stopFSKTransmit ] ;		//  v0.50
	
	if ( isTransmit ) {
		isTransmit = NO ;
		[ modemDest stopSampling ] ;
		if ( transmitButton ) {
			[ transmitButton setTitle:NSLocalizedString( @"Transmit", nil ) ] ;
			[ transmitButton setState:NSOffState ] ;
		}
		[ afsk clearOutput ] ;  //  v0.46
		[ modemObj transmissionEnded ] ;
	}
	return NO ;
}

- (void)transmitCharacter:(int)ascii
{
	if ( ascii == 0x6 ) return ;				// ignore %[tx] for now
	if ( fsk ) [ fsk appendASCII:ascii ] ; else [ afsk appendASCII:ascii ] ;		// v0.50
}

- (void)flushTransmitBuffer
{
	if ( fsk ) [ fsk clearOutput ] ; else [ afsk clearOutput ] ;					// v0.50
}

//  accepts a button
//  returns YES if RTTY modemDest is Transmiting
- (Boolean)turnOnTransmission:(Boolean)inState button:(NSButton*)button fsk:(FSK*)inFSK
{
	Boolean state ;
	int fd = 0 ;
	
	//  check if we should use FSK
	fsk = inFSK ;
	if ( fsk ) {
		//  select fsk port and check if port is good
		fd = [ fsk useSelectedPort ] ;
		if ( fd <= 0 ) fsk = nil ;
	}
	ook = 0 ;
	transmitButton = button ;
	state = ( inState ) ? [ self startTransmit ] : [ self stopTransmit ] ; 	
	return state ;
}

- (Boolean)turnOnTransmission:(Boolean)inState button:(NSButton*)button fsk:(FSK*)inFSK ook:(int)inOOK
{
	Boolean state ;
	int fd = 0 ;
	
	//  check if we should use FSK
	fsk = inFSK ;
	if ( fsk ) {
		[ fsk setUSOS:usosState ] ;													//  v0.84
		//  select fsk port and check if port is good
		fd = [ fsk useSelectedPort ] ;
		if ( fd <= 0 ) fsk = nil ;
	}
	//  v 0.85 check ook state 0 = afsk, fsk, 1, 2 = ook
	ook = inOOK ;
	transmitButton = button ;
	state = ( inState ) ? [ self startTransmit ] : [ self stopTransmit ] ; 	
	return state ;
}

/* local */
- (void)selectTestTone:(int)index
{
	if ( !toneMatrix ) return ;
	
	[ toneMatrix deselectAllCells ] ;
	[ toneMatrix selectCellAtRow:0 column:index ] ;
	if ( timeout ) {
		[ timeout invalidate ] ;
		timeout = nil ;
	}
	
	[ modemObj ptt:( index != 0 ) ] ;
	switch ( index ) {
	case 0:
		[ modemDest stopSampling ] ;
		[ self flushTransmitBuffer ] ;
		break ;
	case 4:
		toneIndex = index ;
		[ modemDest stopSampling ] ;
		[ afsk appendString:"========" clearExistingCharacters:YES ] ;
		[ modemDest startSampling ] ;
		break ;
	case 5:
		toneIndex = index ;
		[ modemDest stopSampling ] ;
		[ afsk appendString:"RYRYRYRY" clearExistingCharacters:YES ] ;
		[ modemDest startSampling ] ;
		break ;
	case 6:
		toneIndex = index ;
		[ modemDest stopSampling ] ;
		[ afsk appendString:"\nthe quick brown fox jumps over the lazy dog. 589 73 qrz" clearExistingCharacters:YES ] ;
		[ modemDest startSampling ] ;
		break ;
	default:
		toneIndex = index ;
		[ modemDest startSampling ] ;
		break ;
	}
}

//  watchdog timer, turn test tone off
- (void)timedOut:(NSTimer*)timer
{
	timeout = nil ;
	[ self selectTestTone:0 ] ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
}

- (RTTYModulator*)afskObj
{
	return afsk ;
}

- (void)stopSampling
{
	[ modemDest stopSampling ] ;
}

//  ---------------- ModemDest callbacks ---------------------

//  modemDest needs more data
- (int)needData:(float*)outbuf samples:(int)samples
{
	int i ;
	
	//  assume
	//  outputSamplingRate = 11025
	//  outputChannels = 1

	//  fetch next n bytes from the AFSK source
	
	assert( samples <= 512 ) ;
	switch ( toneIndex ) {
	case 0:
		//  normal transmission, index != 0 is for test tones
		//  fill diddles also echos character (if any) to the exchange view
		[ afsk getBufferWithDiddleFill:bpfBuf length:samples ] ;
		break ;
	case 1:
	default:
		[ afsk getBufferOfMarkTone:bpfBuf length:samples ] ;
		break ;
	case 2:
		[ afsk getBufferOfSpaceTone:bpfBuf length:samples ] ;
		break ;
	case 3:
		[ afsk getBufferOfTwoTone:bpfBuf length:samples ] ;
		break ;	
	case 4:
	case 5:
	case 6:
		[ afsk getBufferWithRepeatFill:bpfBuf length:samples ] ;
		break ;
	}
	
	//  apply bandpass filter and save into output
	CMPerformFIR( transmitBPF, bpfBuf, samples, outbuf ) ;
	
	//  v0.78 send unequalized output to auralMonitor
	if ( rttyAuralMonitor ) [ rttyAuralMonitor newBandpassFilteredData:outbuf scale:outputScale fromReceiver:NO ] ;

	if ( equalizer ) {
		for ( i = 0; i < samples; i++ ) outbuf[i] *= equalize ;
	}
	return 1 ; // output channels
}

- (void)setOutputScale:(float)value
{
	outputScale = value * [ modemObj outputBoost ] ;				//  v0.88 allow 2 dB boost
	[ afsk setOutputScale:outputScale ] ;
}

@end
