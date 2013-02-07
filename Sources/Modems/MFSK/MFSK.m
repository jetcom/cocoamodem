//
//  MFSK.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/15/06.
	#include "Copyright.h"
	
#import "MFSK.h"
#import "Application.h"
#import "cocoaModemParams.h"
#import "DominoModulator.h"
#import "DominoReceiver.h"
#import "DominoHalfRateReceiver.h"
#import "Messages.h"
#import "MFSK16Modulator.h"
#import "MFSK16Receiver.h"
#import "MFSKConfig.h"
#import "MFSKDemodulator.h"
#import "MFSKMacros.h"
#import "MFSKModes.h"
#import "MFSKWaterfall.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Module.h"
#import "NoiseUtils.h"
#import "Plist.h"
#import "Stdmanager.h"
#import "TextEncoding.h"
#import "Transceiver.h"
#import "VUMeter.h"
#import "ScrollingField.h"

@implementation MFSK

//  v0.87
- (void)switchModemIn
{
	if ( config ) [ config setKeyerMode ] ;
}

- (void)setFEC
{
	int fecMode ;
	Boolean useFEC ;
	
	fecMode = [ [ dominoFECMenu selectedItem ] tag ] ;
	useFEC = ( fecMode >= 4 ) ;
	
	[ demodulator setUseFEC:useFEC ] ;
	[ dominoModulator setUseFEC:useFEC ] ;
	if ( useFEC ) {
		[ demodulator setInterleaverStages:fecMode ] ;
		[ dominoModulator setInterleaverStages:fecMode ] ;
	}
}

//	Set MFSK mode to tag of the mode popup menu's selected item.
- (void)setMFSKMode
{
	MFSKReceiver *oldReceiver, *newReceiver ;
	int bins, interface, baudRatio ;
	float spread, binWidth ;
	Boolean wasActive ;
	
	oldReceiver = receiver ;
	mfskMode = [ [ mfskModeMenu selectedItem ] tag ] % 32 ;
	[ dominoReceiveBox setMFSKMode:mfskMode ] ;					//  change smooth scrolling rate
	
	//  pc = 100
	bins = 18 ;
	interface = 1 ;

	switch ( mfskMode ) {
	case MFSK16:
	default:
		newReceiver = mfsk16Receiver ;
		modulator = mfsk16Modulator ;
		bins = 16 ;
		interface = 0 ;
		spread = 16*15.625 ;
		break ;
	case DOMINOEX4:
		newReceiver = domino4Receiver ;
		modulator = dominoModulator ;
		binWidth = 7.8125 ;
		baudRatio = 2 ;
		break ;
	case DOMINOEX5:
		newReceiver = domino5Receiver ;	
		modulator = dominoModulator ;
		binWidth = 10.7666 ;
		baudRatio = 2 ;
		break ;
	case DOMINOEX8:
		newReceiver = domino8Receiver ;	
		modulator = dominoModulator ;
		binWidth = 15.625 ;	
		baudRatio = 2 ;
		break ;
	case DOMINOEX11:
		newReceiver = domino11Receiver ;	
		modulator = dominoModulator ;
		binWidth = 10.7666 ;	
		baudRatio = 1 ;
		break ;
	case DOMINOEX16:
		newReceiver = domino16Receiver ;	
		modulator = dominoModulator ;
		binWidth = 15.625 ;	
		baudRatio = 1 ;
		break ;
	case DOMINOEX22:
		newReceiver = domino22Receiver ;	
		modulator = dominoModulator ;
		binWidth = 10.766*2 ;	
		baudRatio = 1 ;
		break ;
	}
		
	if ( modulator == dominoModulator ) {
		spread = 18*binWidth ;
		[ (DominoModulator*)modulator setBinWidth:binWidth baudRatio:baudRatio ] ;
	}
	
	//  PC = 468 (PPC), 513 (Intel)
	//  select between MFSK16 and DominoEX (secondary messages, etc) GUI
	[ exchangeTabView selectTabViewItemAtIndex:interface ] ;		

	//  set up indicators
	[ mfskIndicatorLabel setBins:bins ] ;
	[ waterfall setSpread:spread ] ;

	//  v0.74 removed: demodulator = [ oldReceiver demodulator ] ;
	
	if ( newReceiver != oldReceiver ) {
		wasActive = active ;
		if ( receiver != nil ) {
			//  pc = 588
			[ self turnOffReceiver:0 option:NO ] ;
			//  pc = 600, 694 (Intel)
			[ self enableModem:NO ] ;
		}
		//  pc = 624
		//  clear DominoEX receive beacon if mode changed
		if ( oldReceiver != nil ) [ dominoReceiveBox clear ] ;
		//  finally, perform the switch
		receiver = newReceiver ;
		
		//  pc = 660
		[ self enableModem:wasActive ] ;
		demodulator = [ receiver demodulator ] ;
		[ demodulator updateRxFreqLabelAndField:0 ] ;	
		[ demodulator setFreqIndicator:mfskIndicator label:mfskIndicatorLabel ] ;
		if ( modulator == dominoModulator ) [ self setFEC ] ;
		[ demodulator setModem:self ] ;
	}
	//  select AFC/Tx Track tab view and set modem
	if ( interface == 0 ) {
		[ afcTabView selectFirstTabViewItem:self ] ; 
		[ demodulator setAFCState:[ afcSlider intValue ] ] ;
	}
	else {
		[ afcTabView  selectLastTabViewItem:self ] ;
		[ demodulator setAFCState:[ txTrackSlider intValue ] ] ;
	}
}

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	[ mgr showSplash:@"Creating MFSK16 and DominoEX Modems" ] ;
			
	self = [ super initIntoTabView:tabview nib:@"MFSK" manager:mgr ] ;
	if ( self ) {
	
		manager = mgr ;
		transceivers = 1 ;
		enabled = NO ;
		displayedFrequency = clickedFrequency = 0.0 ;
		displayedRxFrequency = displayedTxFrequency = -1 ;
		
		receiver = nil ;
		mfsk16Receiver = [ [ MFSK16Receiver alloc ] init ] ;
		domino4Receiver = [ [ DominoHalfRateReceiver alloc ] initAsMode:DOMINOEX4 ] ;
		domino8Receiver = [ [ DominoHalfRateReceiver alloc ] initAsMode:DOMINOEX8 ] ;
		domino16Receiver = [ [ DominoReceiver alloc ] initAsMode:DOMINOEX16 ] ;
		domino5Receiver = [ [ DominoHalfRateReceiver alloc ] initAsMode:DOMINOEX5 ] ;
		domino11Receiver = [ [ DominoReceiver alloc ] initAsMode:DOMINOEX11 ] ;
		domino22Receiver = [ [ DominoReceiver alloc ] initAsMode:DOMINOEX22 ] ;
		
		modulator = nil ;
		mfsk16Modulator = [ [ MFSK16Modulator alloc ] init ] ;
		[ mfsk16Modulator setModemClient:self ] ;		
		dominoModulator = [ [ DominoModulator alloc ] init ] ;
		[ dominoModulator setModemClient:self ] ;
		
		[ mfskModeMenu selectItemWithTag:DOMINOEX11 ] ;
		//	[ self setMFSKMode ] ;
	}
	return self ;
}

- (void)awakeFromNib
{
	ident = NSLocalizedString( @"MFSK", nil ) ;

	[ (MFSKConfig*)config awakeFromModem:self ] ;
	ptt = [ config pttObject ] ;
	
	[ self awakeFromContest ] ;
	[ self initCallsign ] ;	
	[ self initColors ] ;
	[ self initMacros ] ;
	sidebandState = NO ;
	sideband = 1 ;		//  default to USB
	
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;
	
	[ waterfall awakeFromModem ] ;
	[ waterfall enableIndicator:self ] ;
	[ waterfall setScrollWheelRate:0.5 ] ;
	
	//	0.75 moved here
	[ self setMFSKMode ] ;
	
	//  prefs
	charactersSinceTimerStarted = 0 ;
	timeout = nil ;
	transmitBufferCheck = nil ;
	thread = [ NSThread currentThread ] ;
	frequencyDefined = NO ;
	
	//  transmit view 
	indexOfUntransmittedText = 0 ;
	transmitState = sentColor = NO ;
	transmitCount = 0 ;
	transmitCountLock = [ [ NSLock alloc ] init ] ;
	transmitViewLock = [ [ NSLock alloc ] init ] ;
	transmitTextAttribute = [ transmitView newAttribute ] ;
	[ transmitView setDelegate:self ] ;
	//  receive view
	receiveTextAttribute = [ receiveView newAttribute ] ;
	[ receiveView setDelegate:self ] ;		//  delegate for callsign clicks
	[ transmitView setDelegate:self ] ;		//  capture backspace
	
	//	DominoEX secondary text
	[ dominoReceiveBox setTextField:dominoReceiveTextField ] ;
	[ dominoSmoothScrollCheckbox setAction:@selector(setSmoothState:) ] ;
	[ dominoSmoothScrollCheckbox setTarget:dominoReceiveBox ] ;

	[ vuMeter setup ] ;
	
	[ self setInterface:transmitButton to:@selector(transmitButtonChanged) ] ;	
	[ self setInterface:inputAttenuator to:@selector(inputAttenuatorChanged) ] ;	
	[ self setInterface:softDecodeCheckbox to:@selector(softDecodeChanged) ] ;	
	[ self setInterface:afcSlider to:@selector(afcSliderChanged:) ] ;	
	[ self setInterface:txTrackSlider to:@selector(afcSliderChanged:) ] ;	
	[ self setInterface:latencySlider to:@selector(latencySliderChanged) ] ;	
	[ self setInterface:squelchSlider to:@selector(squelchSliderChanged) ] ;	
	[ self setInterface:txTransferButton to:@selector(setTxFrequencyFromRxFrequency) ] ;	
	[ self setInterface:mfskModeMenu to:@selector(setMFSKMode) ] ;									// v0.73
	[ self setInterface:dominoFECMenu to:@selector(setFEC) ] ;										// v0.73
	[ self setInterface:dominoSmoothScrollCheckbox to:@selector(setDominoReceiveBeaconState) ] ;	// v0.73
	[ self setInterface:dominoBeaconEchoCheckbox to:@selector(setDominoReceiveBeaconState) ] ;		// v0.73

	[ self setInterface:dominoSendCheckbox to:@selector(dominoTransmitBeaconChanged) ] ;			// v0.73
	[ self setInterface:dominoSendField to:@selector(dominoTransmitBeaconChanged) ] ;				// v0.73
	
	[ self setInterface:rxFreqField to:@selector( rxFieldChanged ) ] ;
}

- (MFSKDemodulator*)demodulator
{
	return demodulator ;
}

- (MFSKReceiver*)receiver
{
	return receiver ;
}

//	v0.73
- (void)setDominoReceiveBeaconState
{
	[ dominoReceiveBox setSmoothState:dominoSmoothScrollCheckbox ] ;
	echoBeacon = ( [ dominoBeaconEchoCheckbox state ] != NSOffState ) ;
}

//	v0.73
- (void)dominoTransmitBeaconChanged
{
	NSString *string ;
	
	string = [ dominoSendField stringValue ] ;
	
	if ( [ dominoSendCheckbox state ] == NSOffState || [ string length ] == 0 ) {
		[ (DominoModulator*)dominoModulator setBeacon:"" ] ;
		return ;
	}
	[ (DominoModulator*)dominoModulator setBeacon:(char*)[ string cStringUsingEncoding:NSISOLatin1StringEncoding ] ] ;
}

//  define ourself as the recipient of audio data
- (CMPipe*)dataClient
{
	return self ;
}

- (void)initMacros
{
	int i ;
	Application *application ;
	
	currentSheet = check = 0 ;
	application = [ manager appObject ] ;
	for ( i = 0; i < 3; i++ ) {
		macroSheet[i] = [ [ MFSKMacros alloc ] initSheet ] ;
		[ macroSheet[i] setUserInfo:[ application userInfoObject ] qso:[ (StdManager*)manager qsoObject ] modem:self canImport:YES ] ;
	}
}

//  overide base class to change AudioPipe pipeline (assume source is normalized)
//		source 
//		. self(importData)
//			. receiver
//				. waterfall
//				. VU Meter

- (void)updateSourceFromConfigInfo
{
	//  send data to distribution box for concurrent display on waterfall
	[ (MFSKConfig*)config setClient:(CMTappedPipe*)self ] ;
	[ (MFSKConfig*)config checkActive ] ;
}

//  process the new data buffer
- (void)importData:(CMPipe*)pipe
{
	#ifdef NOISETEST
	CMDataStream *stream ;
	float *array, sigma, ebNo ;
	int i ;

	//  for test file, carrier power = .03
	//  for sd = 1.0, noise power = .000178 ;
	//  CNdR = 22.26 dB (noise in 1 Hz)
	//  ----------------------------------------------
	//  Eb/No = ( 22.26 - 15 ) = 7.26 dB for sd = 1.0.
	//  ----------------------------------------------
	//  hard decoder copied to about 6.4 dB Eb/No
	//  soft decoder copied to about 5.4 dB Eb/No
	stream = [ pipe stream ] ;
	array = stream->array ;
	ebNo = 6.0 ;
	sigma = pow( 1.12203, 7.26-ebNo ) ;  //  sigma = 2 for 1.2203 ^ 6.02
	for ( i = 0; i < 512; i++ ) array[i] = ( array[i] + gaussianNoise( sigma ) ) *0.2 ;
	#endif
	
	if ( receiver && enabled ) [ receiver importData:pipe ] ;
	//  send data to other data clients
	if ( waterfall ) [ waterfall importData:pipe ] ;
	if ( vuMeter ) [ vuMeter importData:pipe ] ;
}

- (VUMeter*)vuMeter
{
	return vuMeter ;
}

- (void)setOutputScale:(float)value
{
	[ modulator setOutputScale:value ] ;
}

- (float)audioToneFromFreqReadout:(float)freq
{
	return ( sideband ) ? ( freq + vfoOffset ) : ( vfoOffset - freq ) ;
}

- (float)freqReadoutFromAudioTone:(float)tone
{
	return ( ( sideband ) ? tone-vfoOffset : vfoOffset-tone ) ;
}

//	v0.73
- (void)rxFieldChanged
{
	float freq ;
	
	freq = [ self audioToneFromFreqReadout:[ rxFreqField floatValue ] ] ;
	
	enabled = YES ;
	clickedFrequency = freq ;
	[ self setRxFrequency:freq ] ;
	[ receiver selectFrequency:freq fromWaterfall:NO ] ;
	[ receiver clicked:0.0 ] ;

}

//	v0.73
//	Modulator gets its transmit tone from here
- (float)transmitFrequency
{
	return [ self audioToneFromFreqReadout:[ txFreqField floatValue ] ] ;
}

//	v0.73
//	receive physical audio tone
- (float)receiveFrequency
{
	return [ self audioToneFromFreqReadout:[ rxFreqField floatValue ] ] ;
}

//	v0.73
- (void)setRxFrequency:(float)audioTone
{
	NSString *freqString ;
	float readout ;
	NSSlider *slider ;
	
	displayedFrequency = audioTone ;
	[ waterfall forceToneTo:audioTone receiver:0 ] ;
	if ( audioTone < 10 ) {
		[ rxFreqField setStringValue:@"" ] ;
		return ;
	}
	readout = [ self freqReadoutFromAudioTone:audioTone ] ;
	
	if ( readout != displayedRxFrequency ) {
		displayedRxFrequency = readout ;
		freqString = [ NSString stringWithFormat:@"%.1f", readout ] ;
		[ rxFreqField setStringValue:freqString ] ;
		//  if AFC turned on, set the tx frequency field also
		slider = ( mfskMode == 0 ) ? afcSlider : txTrackSlider ;
		if ( [ slider intValue ] == 1 ) [ txFreqField setStringValue:freqString ] ;
	}
}

- (void)setTxFrequency:(float)audioTone
{
	NSString *freqString ;
	float readout ;

	if ( audioTone < 10 ) {
		[ txFreqField setStringValue:@"" ] ;
		return ;
	}
	
	readout = [ self freqReadoutFromAudioTone:audioTone ] ;

	if ( readout != displayedTxFrequency ) {
		displayedTxFrequency = readout ;
		freqString = [ NSString stringWithFormat:@"%.1f", readout ] ;
		[ txFreqField setStringValue:freqString ] ;
	}
}

//  called from MFSK16 demodulator when locked
- (void)applyRxFreqOffset:(float)offset
{
	float freq ;
	
	//  v0.33 apply opposite correction if sideband is LSB (0)
	freq = clickedFrequency + offset * ( (sideband == 0 ) ? -1 : 1 ) ;
	if ( fabs( displayedFrequency-freq ) < 0.1 ) return ;
	[ self setRxFrequency:freq ] ;
}

- (void)turnOffReceiver:(int)channel option:(Boolean)option
{
	if ( transmitState == YES ) {
		//  make sure transmitter is off first!
		[ self changeTransmitStateTo:NO ] ;
		usleep( 100000 ) ;
	}
	enabled = NO ;
	[ self setRxFrequency:0 ] ;
	[ self setTxFrequency:0 ] ;
	if ( mfskIndicator ) [ mfskIndicator clear ] ;
	if ( mfskIndicatorLabel ) [ mfskIndicatorLabel clear ] ;
}

- (void)setTxFrequencyFromRxFrequency
{
	[ self setTxFrequency:[ self receiveFrequency ] ] ;
}

- (Boolean)checkIfCanTransmit
{
	return ( [ self transmitFrequency ] > 100 ) ;
}

- (void)flushOutput
{
	[ transmitCountLock lock ] ;
	transmitCount = 0 ;
	[ transmitCountLock unlock ] ;
	//  now flush whatever is in the modulator pipeline
	[ modulator flushOutput ] ;
}

//  this overrides the method in Modem.m
- (void)flushAndLeaveTransmit
{
	[ self flushOutput ] ;
	[ self enterTransmitMode:NO ] ;
}

//	Actual tone frequency (independent of USB/LSB/offset)
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)index
{
	if ( ![ config soundInputActive ] ) {
		//  check if A/D is active
		[ waterfall clearMarkers ] ;
		[ Messages alertWithMessageText:NSLocalizedString( @"Sound Card not active", nil ) informativeText:NSLocalizedString( @"Select Sound Card", nil ) ] ;
		return ;
	}
	enabled = YES ;
	[ self setRxFrequency:freq ] ;
	clickedFrequency = freq ;
	if ( acquire ) [ self setTxFrequency:freq ] ;
	[ receiver selectFrequency:freq fromWaterfall:acquire ] ;
	[ receiver clicked:secs ] ;
}

//  v0.73
- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor
{
	[ textColor release ] ;
	textColor = [ inTextColor retain ] ;

	[ sentTextColor release ] ;
	sentTextColor = [ sentTColor retain ] ;
	
	[ backgroundColor release ] ;
	backgroundColor = [ bgColor retain ] ;
	
	[ plotColor release ] ;
	plotColor = [ pColor retain ] ;
	
	[ receiveView setBackgroundColor:backgroundColor ] ;
	[ transmitView setBackgroundColor:backgroundColor ] ;
	[ dominoReceiveView setBackgroundColor:backgroundColor ] ;
	[ dominoReceiveBox setBackgroundColor:backgroundColor ] ;
	[ dominoSendField setBackgroundColor:backgroundColor ] ;
	
	[ receiveView setTextColor:textColor attribute:receiveTextAttribute ] ;
	[ transmitView setViewTextColor:textColor attribute:transmitTextAttribute ] ;
	[ dominoReceiveView setTextColor:textColor attribute:receiveTextAttribute ] ;
	[ dominoReceiveBox setTextColor:textColor ] ;
	[ dominoSendField setTextColor:textColor ] ;
}

- (void)displayCharacter:(int)c
{
	char buffer[2] ;
	
	//  send character
	buffer[0] = c ;
	buffer[1] = 0 ;
	[ receiveView append:buffer ] ;
	[ [ manager appObject ] addToVoice:c channel:1 ] ;		//  0.96d
	
	//  applescript
	[ [ transceiver1 receiver ] insertBuffer:c ] ;
}

//	v0.73  DominoEX primary output
- (void)displayPrimary:(int)c
{
	char buffer[2] ;
	
	//  send character to Domino tab's exchangeView
	buffer[0] = c ;
	buffer[1] = 0 ;
	[ dominoReceiveView append:buffer ] ;
	[ [ manager appObject ] addToVoice:c channel:1 ] ;		//  0.96d
	//  applescript
	[ [ transceiver1 receiver ] insertBuffer:c ] ;
}

//  v0.73
//  if negative, clear the box
- (void)displaySecondary:(int)c
{
	if ( c < 0 ) [ dominoReceiveBox clear ] ; 
	else {
		[ dominoReceiveBox appendCharacter:c draw:[ dominoReceiveCheckbox state ] == NSOnState ] ;
	}
}

//  sideband state (set from PSKConfig's LSB/USB button)
//  NO = LSB
- (void)selectAlternateSideband:(Boolean)state
{
	int sb ;
	
	sb = ( state ) ? 1 : 0 ;
	[ waterfall setSideband:sb ] ;
	[ receiver setSidebandState:state ] ;
	[ domino4Receiver setSidebandState:state ] ;
	[ domino5Receiver setSidebandState:state ] ;
	[ domino8Receiver setSidebandState:state ] ;
	[ domino11Receiver setSidebandState:state ] ;
	[ domino16Receiver setSidebandState:state ] ;
	[ domino22Receiver setSidebandState:state ] ;
	[ modulator setSidebandState:state ] ;
	[ dominoModulator setSidebandState:state ] ;
}

- (void)setWaterfallOffset:(float)freq sideband:(int)polarity
{
	float offset ;
	
	offset = fabs( freq ) ;
	
	vfoOffset = offset ;
	sideband = polarity ;
	
	[ waterfall setOffset:freq sideband:sideband ] ;
}

//  this gets periodically called to check for inactivity
/* local */ - (void)timedOut:(NSTimer*)timer
{
	if ( charactersSinceTimerStarted == 0 ) {
		//  timed out!
		[ self changeTransmitStateTo:NO ] ;
	}
	charactersSinceTimerStarted = 0 ;
}

/* local */ - (void)sendTextStorage
{
	int total ;
	unichar uch ;
	NSString *string ;
	NSTextStorage *storage ;

	[ transmitViewLock lock ] ;
	storage = [ transmitView textStorage ] ;
	total = [ storage length ] ;
	if ( indexOfUntransmittedText < total ) {
		string = [ storage string ] ;
		while ( indexOfUntransmittedText < total ) {
			uch = [ string characterAtIndex:indexOfUntransmittedText++ ] ;
			[ modulator appendASCII:(int)uch ] ;
			charactersSinceTimerStarted++ ;
		}
	}
	[ transmitViewLock unlock ] ;
}

//  this gets periodically called to check transmit buffer activity
/* local */ - (void)checkTransmitBuffer:(NSTimer*)timer
{
	[ self sendTextStorage ] ;
}

//  allow receive data to flush through the pipeline before changing text color
//  and sending transmit buffer
- (void)delayTransmit:(NSTimer*)timer
{
	[ transmitView select ] ;
	//  send any test that has been buffered up
	[ self sendTextStorage ] ;
}

//  execute string
- (void)executeMacroString:(NSString*)macro
{
	if ( macro ) [ transmitView insertAtEnd:macro ] ;
	
	if ( transmitCount > 0 ) {
		//  keep transmit on if needed
		if ( transmitState == NO ) [ self changeTransmitStateTo:YES ] ;
	}
}

//  for %[tx] and %[rx] macros
- (void)sendMessageImmediately
{
	[ transmitCountLock lock ] ;
	transmitCount++ ;
	[ transmitCountLock unlock ] ;
}

//  state = 0 : gray
//  state = 1 : red
//  state = 2 : yellow
- (void)changeTransmitLight:(int)state
{
	NSColor *indicatorColor ;
	
	switch ( state ) {
	case 0:
	default:
		indicatorColor = [ NSColor colorWithCalibratedWhite:0.5 alpha:1.0 ] ;
		break ;
	case 1:
		indicatorColor =  [ NSColor redColor ] ;
		break ;
	case 2:
		indicatorColor =  [ NSColor yellowColor ] ;
		break ;
	}
	[ transmitLight setBackgroundColor:indicatorColor ] ;
}

- (void)changeTransmitStateTo:(Boolean)state
{
	transmitState = [ config turnOnTransmission:state button:transmitButton modulator:modulator ] ;
	
	if ( transmitState == YES ) {
		[ self ptt:YES ] ;
		[ self changeTransmitLight:1 ] ;
		[ [ transmitView window ] makeFirstResponder:transmitView ] ;
		if ( timeout ) [ timeout invalidate ] ;
		charactersSinceTimerStarted = 0 ;
		//  prepare modulator
		[ modulator resetModulator ] ;
		if ( [ manager useWatchdog ] ) timeout = [ NSTimer scheduledTimerWithTimeInterval:150 target:self selector:@selector(timedOut:) userInfo:self repeats:YES ] ;
		transmitBufferCheck = [ NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkTransmitBuffer:) userInfo:self repeats:YES ] ;
		//  set text color in receive view and turn on transmit
		[ NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(delayTransmit:) userInfo:self repeats:NO ] ;
	}
	else {
		[ self ptt:NO ] ;
		[ self changeTransmitLight:0 ] ;
		if ( timeout ) [ timeout invalidate ] ;
		timeout = nil ;
		if ( transmitBufferCheck ) [ transmitBufferCheck invalidate ] ;
		transmitBufferCheck = nil ;
		[ transmitCountLock lock ] ;
		transmitCount = 0 ;
		[ transmitCountLock unlock ] ;
		[ self setSentColor:NO view:receiveView textAttribute:receiveTextAttribute ] ;
		[ transmitView select ] ;
	}
}

//	(Private API)
- (void)transmittedCharacter:(int)c channel:(int)channel
{
	char buffer[2] ;
	
	if ( c <= 26 ) {
		//  control character in stream
		switch ( c + 'a' - 1 ) {
		case 'z':
			//  end of macro transmitCount balance
			[ transmitCountLock lock ] ;
			if ( transmitCount > 0 ) transmitCount-- ;
			[ transmitCountLock unlock ] ;
			return ;
		default:
			//  for carriage return, newline, etc
			break ;
		}
	}
	else {
		[ self setSentColor:YES view:receiveView textAttribute:receiveTextAttribute ] ;
		if ( c == '0' && slashZero ) c = Phi ;
	}
	//  send character
	buffer[0] = c ;
	buffer[1] = 0 ;
	switch ( channel ) {
	default:
	case 0:
		[ receiveView append:buffer ] ;
		break ;
	case 1:
		[ dominoReceiveView append:buffer ] ;
		break ;
	}
	[ [ manager appObject ] addToVoice:c channel:0 ] ;		//  0.96d
	//  applescript
	[ [ transceiver1 transmitter ] insertBuffer:c ] ;
	[ transmitView select ] ;
}

//	Echo to MFSK16 ReceiveView
- (void)transmittedCharacter:(int)c
{
	[ self transmittedCharacter:c channel:0 ] ;
}

//	Echo to DominoEX ReceiveView
- (void)transmittedPrimaryCharacter:(int)c
{
	[ self transmittedCharacter:c channel:1 ] ;
}

//	Echo to DominoEX beacon
- (void)transmittedSecondaryCharacter:(int)c
{
	if ( echoBeacon ) [ self displaySecondary:c ] ;
}

//  called from local object or from StdManager (main menu)
- (void)enterTransmitMode:(Boolean)state
{
	if ( state ) {
		if ( ![ config soundInputActive ] ) {
			//  check if A/D is active
			[ transmitButton setState:NSOffState ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"Sound Card not active", nil ) informativeText:NSLocalizedString( @"Select Sound Card", nil ) ] ;
			return ;
		}
		if ( [ self transmitFrequency ] < 10.0 ) {
			//  check if frequency has been selected in waterfall
			[ transmitButton setState:NSOffState ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"Frequency not selected", nil ) informativeText:NSLocalizedString( @"Frequency not set", nil ) ] ;
			return ;
		}
	}
	if ( state != transmitState ) {
		if ( state == YES ) {
			//  immediately change state to transmit
			[ self changeTransmitStateTo:state ] ;
		}
		else {
			//  enter a %[rx] character into the stream
			[ transmitView insertInTextStorage:[ NSString stringWithFormat:@"%c", 5 /*^E*/ ] ] ;
		}
	}
}

//  Application sends this through the ModemManager when quitting
- (void)applicationTerminating
{
	[ ptt applicationTerminating ] ;				//  v0.89
}

- (void)transmitButtonChanged
{
	int state ;
	
	state = ( [ transmitButton state ] == NSOnState ) ;
	[ self enterTransmitMode:state ] ;
}

- (void)inputAttenuatorChanged
{
	[ [ (MFSKConfig*)config inputSource ] setDeviceLevel:inputAttenuator ] ;
}

//  v0.33
- (NSSlider*)inputAttenuator:(ModemConfig*)config
{
	return inputAttenuator ;
}

- (void)softDecodeChanged
{
	[ demodulator setSoftDecodeState:( [ softDecodeCheckbox state ] == NSOnState ) ] ;
}

- (void)afcSliderChanged:sender
{
	[ demodulator setAFCState:[ sender intValue ] ] ;
}

- (void)latencySliderChanged
{
	[ demodulator setTrellisDepth:[ latencySlider intValue ] ] ;
}

//  CNR thresolds for squelch
//  CNR of 1.5 (Eb/No approx 7 dB) prints barely OK in AWGN.
static float kMFSKSquelchThreshold[] = { 24.0, 12.0, 6.0, 3.0, 1.5, 0.0001 } ;

- (void)squelchSliderChanged
{
	int index ;
	
	index = [ squelchSlider intValue ] ;
	if ( index <= 0 ) index = 0 ; else if ( index > 5 ) index = 5 ;
	[ demodulator setSquelchThreshold:kMFSKSquelchThreshold[index] ] ;
}

- (void)enableModem:(Boolean)inActive
{
	active = inActive ;
	[ receiver enableReceiver:active ] ;
}

- (IBAction)waterfallRangeChanged:(id)sender
{
	[ waterfall setDynamicRange:[ sender floatValue ] ] ;
}

- (IBAction)flushTransmitStream:(id)sender
{
	//[ modulator flushOutput ] ;				//  v0.85
	[ self flushOutput ] ;						//  v0.85
}

//  --- preferences ---

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kMFSKFont ] ;
	[ pref setFloat:18.0 forKey:kMFSKFontSize ] ;
	[ pref setString:@"Verdana" forKey:kMFSKTxFont ] ;
	[ pref setFloat:14.0 forKey:kMFSKTxFontSize ] ;
	
	//  v0.73
	[ pref setString:@"Verdana" forKey:kDominoFont ] ;
	[ pref setFloat:18.0 forKey:kDominoFontSize ] ;
	[ pref setInt:1 forKey:kDominoSmoothScroll ] ;
	[ pref setInt:1 forKey:kDominoEchoBeacon ] ;	
	[ pref setInt:1 forKey:kDominoRcvrEnable ] ;
	[ pref setInt:1 forKey:kDominoSendEnable ] ;
	[ pref setString:@"" forKey:kDominoBeacon ] ;
	[ pref setInt:1 forKey:kMFSKWaterfallNR ] ;

	[ pref setInt:11 forKey:kMFSKSelection ] ;			//  0 = MFSK16, 11 = DominoEX11, 16 = DOminoEX16, etc
	
	[ (MFSKConfig*)config setupDefaultPreferences:pref ] ;
	
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (MFSKMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
	//  set default Trellis depth
	[ pref setInt:45 forKey:kMFSKTrellisDepth ] ;
	[ pref setInt:4 forKey:kMFSKSquelch ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName, *beaconString ;
	float fontSize ;
	int i, tag ;
	
	[ super updateFromPlist:pref ] ;
	
	fontName = [ pref stringValueForKey:kMFSKFont ] ;
	fontSize = [ pref floatValueForKey:kMFSKFontSize ] ;
	[ receiveView setTextFont:fontName size:fontSize attribute:receiveTextAttribute ] ;
	
	fontName = [ pref stringValueForKey:kMFSKTxFont ] ;
	fontSize = [ pref floatValueForKey:kMFSKTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	fontName = [ pref stringValueForKey:kDominoFont ] ;
	fontSize = [ pref floatValueForKey:kDominoFontSize ] ;
	[ dominoReceiveView setTextFont:fontName size:fontSize attribute:receiveTextAttribute ] ;
    
	[ manager showSplash:@"Updating MFSK configurations" ] ;
	[ (MFSKConfig*)config updateFromPlist:pref ] ;
	
	i = [ pref intValueForKey:kMFSKSquelch ] ;
	[ squelchSlider setIntValue:i ] ;
	[ self squelchSliderChanged ] ;
	
	[ manager showSplash:@"Loading MFSK macros" ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) {
			[ (MFSKMacros*)( macroSheet[i] ) updateFromPlist:pref option:i ] ;
		}
	}
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;
	
	//  v0.73	
	[ dominoSmoothScrollCheckbox setState:( [ pref intValueForKey:kDominoSmoothScroll ] != 0 ) ? NSOnState : NSOffState ] ;	
	[ dominoBeaconEchoCheckbox setState:( [ pref intValueForKey:kDominoEchoBeacon ] != 0 ) ? NSOnState : NSOffState ] ;
	[ self setDominoReceiveBeaconState ] ;
	[ dominoReceiveCheckbox setState:( [ pref intValueForKey:kDominoRcvrEnable ] != 0 ) ? NSOnState : NSOffState ] ;
	[ dominoSendCheckbox setState:( [ pref intValueForKey:kDominoSendEnable ] != 0 ) ? NSOnState : NSOffState ] ;
	beaconString = [ pref stringValueForKey:kDominoBeacon ] ;
	if ( beaconString == nil ) [ dominoSendField setStringValue:@"" ] ; else [ dominoSendField setStringValue:beaconString ] ;
	[ self dominoTransmitBeaconChanged ] ;
	[ waterfall setNoiseReductionState:[ pref intValueForKey:kMFSKWaterfallNR ] ] ;

	tag = [ pref intValueForKey:kMFSKSelection ] ;
	[ mfskModeMenu selectItemWithTag:tag ] ;
	if ( [ mfskModeMenu indexOfSelectedItem ] < 0 ) [ mfskModeMenu selectItemAtIndex:0 ] ;
	[ self setMFSKMode ] ;
	
	//  decoder parameters 
	//  NOTE: Trellis dept can be changed by modifying the Plist file
	[ demodulator setTrellisDepth:[ pref intValueForKey:kMFSKTrellisDepth ] ] ;
	
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	int i ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	[ super retrieveForPlist:pref ] ;
	
	font = [ receiveView font ] ;
	[ pref setString:[ font fontName ] forKey:kMFSKFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kMFSKFontSize ] ;
	font = [ transmitView font ] ;
	[ pref setString:[ font fontName ] forKey:kMFSKTxFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kMFSKTxFontSize ] ;
	
	font = [ dominoReceiveView font ] ;
	[ pref setString:[ font fontName ] forKey:kDominoFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kDominoFontSize ] ;

	i = [ squelchSlider intValue ] ;
	[ pref setInt:i forKey:kMFSKSquelch ] ;
	
	[ pref setInt:( ( [ dominoSmoothScrollCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kDominoSmoothScroll ] ; 
	[ pref setInt:( ( [ dominoReceiveCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kDominoRcvrEnable ] ;
	[ pref setInt:( ( [ dominoBeaconEchoCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kDominoEchoBeacon] ;
	[ pref setInt:( ( [ dominoSendCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kDominoSendEnable ] ;
	[ pref setString:[ dominoSendField stringValue ] forKey:kDominoBeacon ] ;
	[ pref setInt:[ waterfall noiseReductionState ] forKey:kMFSKWaterfallNR ] ;

	i = [ [ mfskModeMenu selectedItem ] tag ] ;
	[ pref setInt:i forKey:kMFSKSelection ] ;	
	
	[ (MFSKConfig*)config retrieveForPlist:pref ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (MFSKMacros*)( macroSheet[i] ) retrieveForPlist:pref option:i ] ;
	}
}

//  delegates
- (void)textViewDidChangeSelection:(NSNotification*)notify
{
	id obj ;
	
	obj = [ notify object ] ;
	if ( obj == receiveView ) {
		[ self captureSelection:obj ] ;
	}
	[ self callsignClickSuccessful:enableClick ] ;
}

//  Delegate of receiveView and transmitView
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)original replacementString:(NSString *)replace
{
	int start, total, length, i ;
	NSTextStorage *storage ;
	char *s, replacement[33] ;
	Boolean hasZero ;
	
	if ( textView == receiveView ) {
		if ( [ replace length ] != 0 ) {
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"text is write only", nil ) informativeText:NSLocalizedString( @"cannot insert text", nil ) ] ;
			return NO ;
		}
		return YES ;
	}
	if ( textView == transmitView ) {
		if ( slashZero ) {
			s = ( char* )[ replace cStringUsingEncoding:kTextEncoding ] ;
			if ( s == nil ) {
				[ Messages alertWithHiraganaError ] ;
				return NO ;
			}
			hasZero = NO ;
			while ( *s ) if ( *s++ == '0' ) hasZero = YES ;
			if ( hasZero ) {
				s = ( char* )[ replace cStringUsingEncoding:kTextEncoding ] ;
				length = strlen( s ) ;
				if ( length < 32 ) {
					strcpy( replacement, s ) ;
					s = replacement ;
					while ( *s ) {
						if ( *s == '0' ) *s = Phi ;
						s++ ;
					}
					//  replace zeros with phi and try again
					[ transmitView replaceCharactersInRange:original withString:[ NSString stringWithCString:replacement encoding:kTextEncoding ] ] ;
					return NO ;
				}
			}
		}
		[ transmitViewLock lock ] ;					//  v0.64
		storage = [ transmitView textStorage ] ;
		total = [ storage length ] ;		
		start = original.location ;
		length = original.length ;
		
		if ( length == total && [ replace length ] == 0 && transmitState == NO ) {
			[ transmitView clearAll ] ;
			indexOfUntransmittedText = 0 ;
			[ transmitViewLock unlock ] ;	
			return NO ;
		}
		if ( length > 0 ) {
			if ( ( start+length ) == total ) {
				//  deleting <length> characters from end
				if ( transmitState == YES ) {
					for ( i = 0; i < length; i++ ) [ modulator appendASCII:0x08 ] ;
					indexOfUntransmittedText -= length ;
				}
				[ transmitViewLock unlock ] ;	
				return YES ;
			}
			if ( transmitState == YES ) {
				[ transmitView insertAtEnd:replace ] ;
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ transmitViewLock unlock ] ;	
				return NO ;
			}
			//  not yet transmitted
			if ( original.location < indexOfUntransmittedText ) {
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
				[ transmitViewLock unlock ] ;	
				return NO ;
			}
			[ transmitViewLock unlock ] ;	
			return YES ;
		}

		//  insertion length = 0
		if ( start != total ) {
			//  inserting in the middle of the transmitView
			if ( transmitState == YES ) {
				//  always insert text at the end when in transmit state
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ transmitView insertAtEnd:replace ] ;
				[ transmitViewLock unlock ] ;	
				return NO ;
			}
			else {
				if ( original.location < indexOfUntransmittedText ) {
					//  attempt to insert into text that has already been transmitted
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
					[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
					[ transmitViewLock unlock ] ;	
					return NO ;
				}
				[ transmitViewLock unlock ] ;	
				return YES ;
			}
		}
		//  inserting at the end of buffer (-checkTransmitBuffer will pick it up)
		if ( [ replace length ] != 0 ) {
			[ transmitViewLock unlock ] ;	
			return YES ;
		}
	}
	[ transmitViewLock unlock ] ;	
	return YES ;
}

//  -- AppleScript support --

- (void)setModulationCodeFor:(Transceiver*)transceiver to:(int)code
{
	int menuTag ;
	
	switch ( code ) {
	default:
	case 'mf16':
		menuTag = MFSK16 ;
		break ;
	}
	//[ modeMenu selectItemWithTag:menuTag ] ;
	//[ self modeChanged ] ;
}

- (int)modulationCodeFor:(Transceiver*)transceiver
{
	//int mode ;
	
	//mode = [ [ modeMenu selectedItem ] tag ] ;
	//if ( menuTag == MFSK16 ) return 'mf16' ;
	return 'mf16' ;
}

//  AppleScript support (callbacks from Modules)
- (float)frequencyFor:(Module*)module
{
	if ( [ module isReceiver ] ) return [ self receiveFrequency ] ;
	return [ self transmitFrequency ] ;
}

- (void)setFrequency:(float)freq module:(Module*)module
{
	if ( [ module isReceiver ] ) {
		[ self setRxFrequency:freq ] ;
		enabled = YES ;
		[ receiver selectFrequency:freq fromWaterfall:YES ] ;		//  mimic a click to the receiver
		clickedFrequency = freq ;
		[ receiver clicked:0 ] ;
	}
	else {
		[ self setTxFrequency:freq ] ;
	}
}

//  this is called from the AppleScript module
- (void)transmitString:(const char*)s
{
	unichar uch ;
	
	while ( *s ) {
		uch = *s++ ;
		[ modulator appendASCII:(int)uch ] ;
	}
}

- (void)setInvert:(Boolean)state module:(Module*)module 
{
	// do nothing in MFSK
}

- (Boolean)invertFor:(Module*)module
{
	return NO ;
}

//	v0.96c
- (void)selectView:(int)index
{
	NSView *pview ;
	Boolean state ;
		
	pview = nil ;
	switch ( index ) {
	case 1:
		pview = ( mfskMode == MFSK16 ) ? receiveView : dominoReceiveView ;
		break ;
	case 0:
		pview = transmitView ;
		break ;
	}
	if ( pview ) state = [ [ pview window ] makeFirstResponder:pview ] ;
}

//  directly open sound file (Shift-Cmd-F)
- (IBAction)openFile:(id)sender
{
	[ config directOpenSoundFile ] ;
}

@end
