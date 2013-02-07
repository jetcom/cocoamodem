//
//  RTTYInterface.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/17/05.
	#include "Copyright.h"
	
#import "RTTYInterface.h"
#import "Application.h"
#import "cocoaModemParams.h"
#import "ContestBar.h"
#import "ContestManager.h"
#import "ExchangeView.h"
#import "FSK.h"
#import "Messages.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Module.h"
#import "RTTYAuralMonitor.h"
#import "RTTYConfig.h"
#import "RTTYModulator.h"
#import "RTTYReceiver.h"
#import "RTTYRxControl.h"
#import "RTTYTxConfig.h"
#import "TextEncoding.h"


@implementation RTTYInterface

//  Base RTTY modem, the single and dual RTTY implementations are sub-classed from this
//  The RTTYInterface has two RTTYTransceivers.  In the case of single RTTY, only the a RTTYTransceiver is marked isAlive.

//	(RTTYInterface : ContestInterface : MacroInterface : Modem)

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	self = [ super initIntoTabView:tabview nib:@"RTTY" manager:mgr ] ;
	if ( self ) {
		isASCIIModem = NO ;
		bitsPerCharacter = 5 ;
		transmitViewLock = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

//  v0.83
- (Boolean)isASCIIModem
{
	return isASCIIModem ;
}

//  v0.83
- (int)bitsPerCharacter
{
	return bitsPerCharacter ;
}

//  NSMatrix of NSButtons from Preferences
- (void)setRTTYPrefs:(NSMatrix*)rttyPrefs channel:(int)channel
{
	int i, count, state ;
	NSButton *button ;
	RTTYReceiver *rx ;
	
	rx = ( channel == 0 ) ? a.receiver : b.receiver ;
	count = [ rttyPrefs numberOfRows ] ;
	if ( count > 1 ) {
		for ( i = 0; i < count; i++ ) {
			button = [ rttyPrefs cellAtRow:i column:0 ] ;
			state = [ button state ] ;
			if ( state == NSOnState ) {
				switch ( i ) {
				case 0:
					//  Unshift On Space
					usos = YES ;
					if ( channel == 0 ) [ txConfig setUSOS:YES ] ;						//  v0.84
					[ rx setUSOS:usos ] ;
					break ;
				case 1:
					//  Disable Baudot BELL
					bell = NO ;
					[ rx setBell:bell ] ;
					break ;
				case 2:
					robust = YES ;
					if ( channel == 0 ) [ [ txConfig afskObj ] setRobustMode:robust ] ;
					break ;
				}
			}
			else {
				switch ( i ) {
				case 0:
					//  Unshift On Space
					usos = NO ;
					if ( channel == 0 ) [ txConfig setUSOS:NO ] ;
					[ rx setUSOS:usos ] ;
					break ;
				case 1:
					//  Don't disable Baudot BELL
					bell = YES ;
					[ rx setBell:bell ] ;
					break ;
				case 2:
					robust = NO ;
					if ( channel == 0 ) [ [ txConfig afskObj ] setRobustMode:robust ] ;
					break ;
				}
			}
		}
	}
	else {
		//  v0.83 -- ASCII RTTY
		usos = NO ;
		button = [ rttyPrefs cellAtRow:0 column:0 ] ;
		state = [ button state ] ;
		if ( state == NSOnState ) {
			//  Disable Baudot BELL
			bell = NO ;
			[ rx setBell:bell ] ;
		}
		else {
			//  Don't disable Baudot BELL
			bell = YES ;
			[ rx setBell:bell ] ;
		}
	}
}

- (void)updateMacroButtons
{
	[ manager updateRTTYMacroButtons ] ;		// this will cause both RTTY and DualRTTY buutons to be updated
}

- (void)insertTransmittedCharacter:(int)c
{
	char buffer[2] ;
	
	buffer[0] = c ;
	buffer[1] = 0 ;
	[ currentRxView append:buffer ] ;
	[ [ manager appObject ] addToVoice:c channel:0 ] ;		//  v0.96d	voice synthesizer
	if ( transmitChannel == 0 ) [ a.transmitModule insertBuffer:c ] ; else [ b.transmitModule insertBuffer:c ] ;
}

//  callback from AFSK generator
- (void)transmittedCharacter:(int)c
{
	if ( c <= 26 ) {
		//  control character in stream
		switch ( c + 'a' - 1 ) {
		case 'e':
			[ transmitCountLock lock ] ;
			transmitCount-- ;
			[ transmitCountLock unlock ] ;
			if ( transmitCount <= 0 ) {
				[ self changeTransmitStateTo:NO ] ;
				[ transmitCountLock lock ] ;
				transmitCount = 0 ;
				[ transmitCountLock unlock ] ;
			}
			//  is also end of macro
			break ;
		case 'z':
			//  end of macro transmitCount balance
			[ transmitCountLock lock ] ;
			if ( transmitCount > 0 ) transmitCount-- ;
			[ transmitCountLock unlock ] ;
			break ;
		default:
			//  for carriage return, newline, etc
			[ self insertTransmittedCharacter:c ] ;
			[ transmitView select ] ;
			break ;
		}
	}
	else {
		[ self setSentColor:YES ] ;
		if ( c == '0' && slashZero ) c = Phi ;
		[ self insertTransmittedCharacter:c ] ;
		[ transmitView select ] ;
	}
}

/* local */
//  this gets periodically called when transmitting
- (void)timedOut:(NSTimer*)timer
{
	if ( charactersSinceTimerStarted == 0 ) {
		//  timed out!		
		[ Messages logMessage:"watchdog timer timed out " ] ;	// v0.65
		[ self changeTransmitStateTo:NO ] ;
	}
	charactersSinceTimerStarted = 0 ;
}

/* local */
//  allow receive data to flush through the pipeline before changing text color
//  and sending transmit buffer
- (void)delayTransmit:(NSTimer*)timer
{
	int total ;
	unichar uch ;
	NSString *string ;
	NSTextStorage *storage ;
	
	[ transmitView select ] ;
	//  send any pending storage
	//[ transmitViewLock lock ] ;		v0.64b

	storage = [ transmitView textStorage ] ;
	if ( storage ) {							//  sanity check v0.64c
		total = [ storage length ] ;
		if ( total > 0 ) {		//  sanity check  v0.64c
			if ( indexOfUntransmittedText < 0 ) {
				indexOfUntransmittedText = total ;		//  sanity check v0.64c
			}
			
			if ( indexOfUntransmittedText < total ) {
			
				string = [ storage string ] ;	
				while ( indexOfUntransmittedText < total ) {
					uch = [ string characterAtIndex:indexOfUntransmittedText++ ] ;
					[ txConfig transmitCharacter:uch ] ;
					charactersSinceTimerStarted++ ;
				}
			}
		}
	}
	//[ transmitViewLock unlock ] ;		v0.64b
	[ self clearTuningIndicators ] ;
	transmitBufferCheck = [ NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkTransmitBuffer:) userInfo:self repeats:YES ] ;		//  v0.65
}

// v0.65 -- defer transmit cancel until the text view has finished
- (void)delayTransmitCancel:(NSTimer*)timer
{
	NSColor *indicatorColor ;
	
	if ( transmitBufferCheck ) [ transmitBufferCheck invalidate ] ;
	transmitBufferCheck = nil ;
	[ self ptt:NO ] ;
	[ transmitCountLock lock ] ;
	transmitCount = 0 ;
	[ transmitCountLock unlock ] ;
	indicatorColor = [ NSColor colorWithCalibratedWhite:0.5 alpha:1.0 ] ;
	[ self setSentColor:NO ] ;
	[ transmitView select ] ;
	[ a.receiver enableReceiver:YES ] ;
	if ( b.isAlive ) [ b.receiver enableReceiver:YES ] ;
	[ transmitLight setBackgroundColor:indicatorColor ] ;
}

/* local */
- (void)checkTransmitBuffer:(NSTimer*)timer
{
	int total ;
	unichar uch ;
	NSString *string ;
	NSTextStorage *storage ;

	//[ transmitViewLock lock ] ;		v0.64b
	storage = [ transmitView textStorage ] ;
	if ( storage != nil ) { 		//  sanity check v0.64c
		total = [ storage length ] ;
		if ( total > 0 ) {			//  sanity check v0.64c
			if ( indexOfUntransmittedText < 0 ) indexOfUntransmittedText = total ;		//  sanity check v0.64c
			if ( indexOfUntransmittedText < total ) {
				string = [ storage string ] ;		
				while ( indexOfUntransmittedText < total ) {
					uch = [ string characterAtIndex:indexOfUntransmittedText++ ] ;
					[ txConfig transmitCharacter:uch ] ;
					charactersSinceTimerStarted++ ;
				}
			}
		}
	}
	//[ transmitViewLock unlock ] ;		v0.64b
}

//  select an input BPF
- (void)selectBandwidth:(int)index
{
	[ a.receiver selectBandwidth:index ] ;
	if ( b.isAlive ) [ b.receiver selectBandwidth:index ] ;
}

//  v0.87
- (void)switchModemIn
{
	if ( config ) [ config setKeyerMode ] ;
}

//  select a Demodulator
- (void)selectDemodulator:(int)index
{
	[ a.receiver selectDemodulator:index ] ;
	if ( b.isAlive ) [ b.receiver selectDemodulator:index ] ;
}

- (void)clearTuningIndicators
{
	[ a.control setTuningIndicatorState:NO ] ;
	if ( b.isAlive ) [ b.control setTuningIndicatorState:NO ] ;
}

- (IBAction)demodulatorModeChanged:(id)sender
{
	[ self selectDemodulator:[ sender selectedColumn ] ] ;
}

- (void)enableModem:(Boolean)active
{
	[ a.receiver enableReceiver:active ] ;
	if ( b.isAlive ) [ b.receiver enableReceiver:active ] ;
	
	if ( active == YES ) {
		if ( contestManager ) {
			[ contestManager setActiveContestInterface:self ] ;
		}
		//  setup repeating macro bar
		if ( contestBar ) {
			//[ contestBar setModem:self ] ;
			alwaysAllowMacro = 1 ;															//  v0.33
			[ contestBar setModem:(ContestInterface*)[ manager currentModem ] ] ;			//  v0.33
			[ self updateContestMacroButtons ] ;
		}
	}
}

- (void)setVisibleState:(Boolean)visible
{
	[ config updateVisibleState:visible ] ;
	[ super setVisibleState:visible ] ;			// v0.33 bug
}

//  overrides the one in modem.m so we can also inform the RTTYReceiver
- (void)useSlashedZero:(Boolean)state
{
	slashZero = state ;
	[ a.receiver setSlashZero:slashZero ] ;	
	if ( b.isAlive ) [ b.receiver setSlashZero:slashZero ] ;	
}

//  override by subclasses that need it
- (void)tonePairChanged:(RTTYRxControl*)control
{
}


//  v0.65 -- move this to the main thread so that the cancel timer is done from the main run loop
- (void)finishTransmitStateChange
{
	NSColor *indicatorColor ;

	if ( transmitState == YES ) {
		[ self ptt:YES ] ;
		indicatorColor =  [ NSColor redColor ] ;
		[ [ transmitView window ] makeFirstResponder:transmitView ] ;
		if ( timeout ) [ timeout invalidate ] ;
		charactersSinceTimerStarted = 0 ;
		if ( [ manager useWatchdog ] ) timeout = [ NSTimer scheduledTimerWithTimeInterval:150 target:self selector:@selector(timedOut:) userInfo:self repeats:YES ] ;
		transmitBufferCheck = nil ;
		[ a.receiver enableReceiver:NO ] ;
		if ( b.isAlive ) [ b.receiver enableReceiver:NO ] ;
		//[ self setSentColor:YES ] ;
		//  set text color in receive view and turn on transmit (v0.65 delay changed from 0.5 to 0.3 sec)
		[ NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(delayTransmit:) userInfo:self repeats:NO ] ;
		[ transmitLight setBackgroundColor:indicatorColor ] ;
		
		[ self flushClickBuffer ] ;			//  v0.89
	}
	else {
		if ( timeout ) [ timeout invalidate ] ;
		timeout = nil ;
		//  v0.65  defer transmit cancel
		[ NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(delayTransmitCancel:) userInfo:self repeats:NO ] ;
	}
}

- (int)ook:(RTTYConfig*)configr
{
	return [ configr ook ] ;
}

//  v0.88b
- (void)changeAuralTransmitStateTo:(Boolean)state
{
	FSK *fsk ;
	int ook, transmitType ;
	
	fsk = [ config fsk ] ;
	ook = [ self ook:config ] ;

	//  transmitType = 0:AFSK, 1:FSK, 2:OOK
	if ( ook != 0 ) transmitType = 2 ;
	else {
		if ( fsk == nil ) transmitType = 0 ; else transmitType = ( [ fsk useSelectedPort ] <= 0 ) ? 0 : 1 ;
	}
	[ [ a.receiver rttyAuralMonitor ] setTransmitState:state transmitType:transmitType ] ;							//  v0.88b
	transmitState = [ txConfig turnOnTransmission:state button:transmitButton fsk:fsk ook:[ self ook:config ] ] ;	//  v0.85
	
	//  v0.65 switch to main thread so the timers can fire from the main run loop
	[ self performSelectorOnMainThread:@selector(finishTransmitStateChange) withObject:nil waitUntilDone:YES ] ;
}

- (void)changeTransmitStateTo:(Boolean)state
{
	FSK *fsk ;
	
	fsk = [ config fsk ] ;
	
	transmitState = [ txConfig turnOnTransmission:state button:transmitButton fsk:fsk ook:[ self ook:config ] ] ;	//  v0.85
	
	//  v0.65 switch to main thread so the timers can fire from the main run loop
	[ self performSelectorOnMainThread:@selector(finishTransmitStateChange) withObject:nil waitUntilDone:YES ] ;
}

//  this overrides the method in Modem.m that is called from the app
- (void)enterTransmitMode:(Boolean)state
{
	if ( state != transmitState ) {
		if ( state == YES ) {
			//  immediately change state to transmit
			[ self changeTransmitStateTo:state ] ;
		}
		else {
			[ transmitView insertInTextStorage:[ NSString stringWithFormat:@"%c", 5 /*^E*/ ] ] ;
			[ transmitLight setBackgroundColor:[ NSColor yellowColor ] ] ;
		}
	}
}

- (void)flushOutput
{
	[ transmitCountLock lock ] ;
	transmitCount = 0 ;
	[ transmitCountLock unlock ] ;
	//  flush transmit view also
	indexOfUntransmittedText = [ [ transmitView textStorage ] length ] ;		
	//  now flush whatever is in the afsk bit buffer
	[ txConfig flushTransmitBuffer ] ;
}

//  this overrides the method in Modem.m that is called from the app
- (void)flushAndLeaveTransmit
{
	[ self flushOutput ] ;
	[ self changeTransmitStateTo:NO ] ;
}

- (void)sendMessageImmediately
{
	[ transmitCountLock lock ] ;
	transmitCount++ ;
	[ transmitCountLock unlock ] ;
}

//  return the transceiver that is assigned as the active transmitter
- (RTTYTransceiver*)transmittingTransceiver
{
	return ( transmitChannel == 0 ) ? &a : &b ;
}

- (void)transmitButtonChanged
{
	int state ;
	
	state = ( [ transmitButton state ] == NSOnState ) ;

	if ( state == NO ) {
		//  enter a %[rx] character into the stream
		[ transmitView insertAtEnd:[ NSString stringWithFormat:@"%c", 5 /*^E*/ ] ] ;
		[ transmitLight setBackgroundColor:[ NSColor yellowColor ] ] ;
	}
	else {
		[ self changeTransmitStateTo:state ] ; 
	}
}

- (void)transmitString:(const char*)s
{
	unichar uch ;
	
	while ( *s ) {
		uch = *s++ ;
		[ txConfig transmitCharacter:uch ] ;
	}
}

//  in contest interface
- (IBAction)flushContestBuffer:(id)sender
{
	[ self flushAndLeaveTransmit ] ;
	[ contestBar cancel ] ;
}

- (IBAction)flushTransmitStream:(id)sender
{
	[ self flushOutput ] ;
}

//  Delegate of receiveView and transmitView
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)original replacementString:(NSString *)replace
{
	int start, total, length ;
	NSTextStorage *storage ;
	char *s, replacement[33] ;
	Boolean hasZero ;
	
	if ( [ replace length ] == 0 && transmitState == YES ) return NO ;			//  v0.56 allow editing if not in transmit mode
	
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
		
		[ transmitViewLock lock ] ;				// removed in 0.64, added back in v0.65
			
		storage = [ transmitView textStorage ] ;
		
		if ( storage != nil ) {				//  sanity check v0.64c
			total = [ storage length ] ;		
			start = original.location ;
			length = [ [ storage attributedSubstringFromRange:original ] length ] ;				//  v0.65 - get length instaed of byte count in attributed string
			if ( length == total && [ replace length ] == 0 && transmitState == NO ) {
				[ transmitView clearAll ] ;
				indexOfUntransmittedText = 0 ;
				[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
				return NO ;
			}
			if ( length > 0 ) {
				if ( ( start+length ) == total ) {
					if ( ( total-length ) < indexOfUntransmittedText ) {			//  deleting pass the transmitted text v0.65
						NSBeep() ;
						[ transmitViewLock unlock ] ;					// 0.66
						return NO ;
					}
					[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
					return YES ;
				}
				if ( transmitState == YES ) {
					[ transmitView insertAtEnd:replace ] ;
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
					[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
					return NO ;
				}
				//  not yet transmitted
				if ( original.location < indexOfUntransmittedText ) {
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
					[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
					[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
					return NO ;
				}
				[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
				return YES ;
			}
			//  insertion length = 0
			if ( start != total ) {
				//  inserting in the middle of the transmitView
				if ( transmitState == YES ) {
					//  always insert text at the end when in transmit state
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
					[ transmitView insertAtEnd:replace ] ;
					[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
					return NO ;
				}
				else {
					if ( original.location < indexOfUntransmittedText ) {
						//  attempt to insert into text that has already been transmitted
						[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
						[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
						[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
						return NO ;
					}
					[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
					return YES ;
				}
			}
			//  inserting at the end of buffer (-checkTransmitBuffer will pick it up)
			if ( [ replace length ] != 0 ) {
				[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
				return YES ;
			}
		}
	}
	[ transmitViewLock unlock ] ;		//  removed 0.64, added back 0.65
	return YES ;
}

//  handle callsign clicks
- (NSRange)textView:(NSTextView*)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{
	NSRange range ;
	
	enableClick = NO ;
	if ( textView == a.view || textView == b.view ) {
	
		//  cancel transmission if there is a repeating macro
		if ( contestBar && alwaysAllowMacro <= 0 ) [ contestBar cancelIfRepeatingIsActive ] ;		// v0.25, v0.33 for first CW repeat macro
		if ( alwaysAllowMacro > 0 ) alwaysAllowMacro-- ;

		if ( [ textView respondsToSelector:@selector(getRightMouse) ] && [ (ExchangeView*)textView getRightMouse ] ) { // v0.32
			//  right clicked (contest QSO)
			if ( newSelectedCharRange.length == 0 ) {
				if ( [ textView lockFocusIfCanDraw ] ) {
					//  capture callsign can disable click so -textViewDidChangeSelection can ignore the click
					range = [ self captureCallsign:textView willChangeSelectionFromCharacterRange:oldSelectedCharRange toCharacterRange:newSelectedCharRange ] ;
					enableClick = ( oldSelectedCharRange.location != range.location ) ;
					[ textView unlockFocus ] ;
					return range ;
				}
				return newSelectedCharRange ;
			}
		}
	}
	return newSelectedCharRange ;
}

//  v0.32
- (void)textViewDidChangeSelection:(NSNotification*)notify
{
	id obj ;
	
	obj = [ notify object ] ;
	if ( obj == a.view || obj == b.view ) {
		[ self captureSelection:obj ] ;
	}
	if ( [ contestBar textInsertedFromRepeat ] ) return ;		//  v0.33
	[ self callsignClickSuccessful:enableClick ] ; 
}


- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ super setupDefaultPreferences:pref ] ;
	// microKeyerSetupField = [ (Config*)pref microKeyerSetupField ] ; v0.89
}

- (NSTextField*)microKeyerSetupField
{
	return microKeyerSetupField ;
}

// --- AppleScript support ---

- (float)frequencyFor:(Module*)module
{
	return [ self markFor:module ] ;
}

- (RTTYTransceiver*)transceiverForModule:(Module*)module
{
	Transceiver *transceiver ;
	RTTYTransceiver *client ;
	
	client = &a ;
	if ( b.isAlive ) {
		transceiver = [ module transceiver ] ;
		if ( transceiver == transceiver2 ) client = &b ;
	}
	return client ;
}

//  local
- (void)setFrequency:(float)freq module:(Module*)module 
{
	[ self setMark:freq module:module ] ;
}

- (float)markFor:(Module*)module
{
	RTTYTransceiver *client ;
	
	client = [ self transceiverForModule:module ] ;
	if ( [ module isReceiver ] ) {
		// receiver tones
		return [ client->control markFrequencyForMask:1 ] ;
	}
	//  transmitter mark tone (single RTTY)
	return [ client->control markFrequencyForMask:2 ] ;
}

- (void)setMark:(float)freq module:(Module*)module
{
	RTTYTransceiver *client ;
	
	client = [ self transceiverForModule:module ] ;
	if ( [ module isReceiver ] ) {
		float originalTransmitMark = [ client->control markFrequencyForMask:2 ] ;
		float originalTransmitSpace = [ client->control spaceFrequencyForMask:2 ] ;
		float originalReceiveSpace = [ client->control spaceFrequencyForMask:1 ] ;
				
		//  receiver mark tone
		[ client->control setMarkFrequency:freq mask:1 ] ;
		//  tones before change
		[ client->control setSpaceFrequency:originalReceiveSpace mask:1 ] ;
		[ client->control setMarkFrequency:originalTransmitMark mask:2 ] ;
		[ client->control setSpaceFrequency:originalTransmitSpace mask:2 ] ;
	}
	else {
		//  transmitter mark tone
		[ client->control setMarkFrequency:freq mask:2 ] ;
	}
}

- (float)spaceFor:(Module*)module
{	
	RTTYTransceiver *client ;
	
	client = [ self transceiverForModule:module ] ;
	if ( [ module isReceiver ] ) {
		// receiver tones
		return [ client->control spaceFrequencyForMask:1 ] ;
	}
	//  transmitter space tone
	return [ client->control spaceFrequencyForMask:2 ] ;
}

- (void)setSpace:(float)freq module:(Module*)module
{
	RTTYTransceiver *client ;
	
	client = [ self transceiverForModule:module ] ;
	if ( [ module isReceiver ] ) {
		float originalTransmitMark = [ client->control markFrequencyForMask:2 ] ;
		float originalTransmitSpace = [ client->control spaceFrequencyForMask:2 ] ;
		float originalReceiveMark = [ client->control markFrequencyForMask:1 ] ;

		//  receiver space tone
		[ client->control setSpaceFrequency:freq mask:1 ] ;
		//  tones before change
		[ client->control setMarkFrequency:originalReceiveMark mask:1 ] ;
		[ client->control setMarkFrequency:originalTransmitMark mask:2 ] ;
		[ client->control setSpaceFrequency:originalTransmitSpace mask:2 ] ;
	}
	else {
		//  transmitter space tone
		[ client->control setSpaceFrequency:freq mask:2 ] ;
	}
}

- (void)afskChanged:(int)index config:(RTTYConfig*)cfg
{
	//  override by wideband RTTY
}

- (float)baudFor:(Module*)module
{
	Transceiver *transceiver ;
	
	if ( b.isAlive ) {
		transceiver = [ module transceiver ] ;
		if ( transceiver == transceiver2 ) return [ b.control baudRate ] ;
	}
	return [ a.control baudRate ] ;
}

- (void)setBaud:(float)rate module:(Module*)module
{
	Transceiver *transceiver ;
	
	if ( b.isAlive ) {
		transceiver = [ module transceiver ] ;
		if ( transceiver == transceiver2 ) {
			[ b.control setBaudRate:rate ] ; 
			return ;
		}
	}
	[ a.control setBaudRate:rate ] ;
}

- (Boolean)invertFor:(Module*)module
{
	RTTYTransceiver *client ;
	
	client = [ self transceiverForModule:module ] ;
	if ( [ module isReceiver ] ) {
		// receiver tones
		return [ client->control invertStateForReceiver ] ;
	}
	//  transmitter tone invert state
	return [ client->control invertStateForTransmitter ] ;
}

- (void)setInvert:(Boolean)state module:(Module*)module 
{
	RTTYTransceiver *client ;
	
	client = [ self transceiverForModule:module ] ;
	if ( [ module isReceiver ] ) {
		[ client->control setInvertStateForReceiver:state ] ;
		return ;
	}
	//  transmitter tone invert state
	[ client->control setInvertStateForTransmitter:state ] ;
}

//  Application sends this through the ModemManager when quitting
- (void)applicationTerminating
{
	[ ptt applicationTerminating ] ;				//  v0.89
}

//  applescript support

//  v0.56
- (int)selectedTransceiver
{
	return transmitChannel+1 ;
}

@end
