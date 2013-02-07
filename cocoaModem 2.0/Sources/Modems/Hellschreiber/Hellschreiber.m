//
//  Hellschreiber.m
//  cocoaModem
//
//  Created by Kok Chen on Wed Jul 27 2005.
	#include "Copyright.h"
//

#import "Hellschreiber.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Messages.h"
#import "Config.h"
#import "Contest.h"					// for HELLMODE
#import "ExchangeView.h"
#import "HellConfig.h"
#import "HellDisplay.h"
#import "HellMacros.h"
#import "HellReceiver.h"
#import "ModemDistributionBox.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "Module.h"
#import "Plist.h"
#import "StdManager.h"
#import "TextEncoding.h"
#import "VUMeter.h"
#import "Waterfall.h"
#import <stdlib.h>						// for malloc()
#import <string.h>						// for memset()


//  transmit light state
#define	TxOff		0
#define	TxReady		1
#define	TxWait		2
#define	TxActive	3


@implementation Hellschreiber

//  Hellschreiber : ContestInterface : MacroPanel : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	[ mgr showSplash:@"Creating Hellschreiber Modem" ] ;

	self = [ super initIntoTabView:tabview nib:@"Hellschreiber" manager:mgr ] ;
	
	if ( self ) {
		manager = mgr ;
		frequencyLocked = NO ;
	}
	return self ;
}

- (int)transmissionMode
{
	return HELLMODE ;
}

//  v0.87
- (void)switchModemIn
{
	if ( config ) [ config setKeyerMode ] ;
}

- (void)awakeFromNib
{
	NSScrollView *sview ;
	NSScroller *scroller ;
	
	ident = NSLocalizedString( @"Hellschreiber", nil ) ;

	fonts = 0 ;
	[ (HellConfig*)config awakeFromModem:self ] ;
	ptt = [ config pttObject ] ;
	alignedFont = unalignedFont = 0 ;
	modeNeedsAlignedFont = NO ;
	
	[ self awakeFromContest ] ;
	[ self initCallsign ] ;	
	[ self initColors ] ;
	[ self initMacros ] ;
	sidebandState = NO ;
	
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;

	[ waterfall awakeFromModem ] ;
	[ waterfall enableIndicator:self ] ;
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

	//  set up the scroller for the input view
	sview = (NSScrollView*)[ [ receiveView superview ] superview ] ;
	scroller = [ sview verticalScroller ] ;
	[ scroller setFloatValue:1.0 knobProportion: 0.125 ] ;
	
	[ vuMeter setup ] ;
		
	//  create receiver
	rx = [ [ HellReceiver alloc ] initFromModem:self ] ;
	[ self modeChanged ] ;
	
	[ self setInterface:slopeSlider to:@selector(slopeChanged) ] ;	
	[ self setInterface:transmitButton to:@selector(transmitButtonChanged) ] ;	
	[ self setInterface:inputAttenuator to:@selector(inputAttenuatorChanged) ] ;	
	[ self setInterface:upButton to:@selector(positionButtonPushed:) ] ;	
	[ self setInterface:downButton to:@selector(positionButtonPushed:) ] ;	
	[ self setInterface:fontMenu to:@selector(fontChanged) ] ;	
	[ self setInterface:modeMenu to:@selector(modeChanged) ] ;	
}

//  Application sends this through the ModemManager when quitting
- (void)applicationTerminating
{
	[ ptt applicationTerminating ] ;				//  v0.89
}

- (void)initMacros
{
	int i ;
	Application *application ;
	
	currentSheet = check = 0 ;
	application = [ manager appObject ] ;
	for ( i = 0; i < 3; i++ ) {
		macroSheet[i] = [ [ HellMacros alloc ] initSheet ] ;
		[ macroSheet[i] setUserInfo:[ application userInfoObject ] qso:[ (StdManager*)manager qsoObject ] modem:self canImport:YES ] ;
	}
}

- (HellConfig*)configObj
{
	return config ;
}

- (VUMeter*)vuMeter
{
	return vuMeter ;
}

//  overide base class to change AudioPipe pipeline (assume source is normalized)
//		source 
//		. self(importData)
//			. waterfall
//			. receiver
//			. VU Meter

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating Hellschreiber sound source" ] ;
	//  send data to distribution box for concurrent display on waterfall
	[ (HellConfig*)config setClient:(CMTappedPipe*)self ] ;
	[ (HellConfig*)config checkActive ] ;
}

- (CMPipe*)dataClient
{
	return self ;
}

//  process the new data buffer
- (void)importData:(CMPipe*)pipe
{
	//  send data to users
	if ( rx ) [ rx importData:pipe ] ;
	if ( waterfall ) [ waterfall importData:pipe ] ;
	if ( vuMeter ) [ vuMeter importData:pipe ] ;
}

- (Boolean)shouldEndTransmission
{
	//  first decrement transmit count
	[ self decrementTransmitCount ] ;
	return ( transmitCount <= 0 ) ;
}

//  check if capable of transmitting on waterfall
- (Boolean)checkTx
{
	return [ rx canTransmit ] ;
}

- (float)transmitFrequency
{
	return [ rx lockedFrequency ] ;
}

//  this is called from the waterfall when it is shift clicked.
- (void)turnOffReceiver:(int)ident option:(Boolean)option
{
	[ rx enableReceiver:NO ] ;
}

//  waterfall clicked
//  Note: for USB left edge is always 400 Hz no matter what the VFO offset is
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)index
{
	//  check if already in transmit mode, if so, don't change frequency
	if ( transmitState == NO ) {
		frequencyDefined = YES ;
		[ rx selectFrequency:freq fromWaterfall:acquire ] ;
		[ rx enableReceiver:YES ] ;
	}
}

//  receive frequency set not by clicking, but by direct entry
- (void)receiveFrequency:(float)freq
{
	[ self frequencyUpdatedTo:freq ] ;
	[ self clicked:freq  secondsAgo:0 option:NO fromWaterfall:NO waterfallID:0 ] ;
}

//  frequency update from HellReceiver
- (void)frequencyUpdatedTo:(float)tone
{
	[ waterfall forceToneTo:tone receiver:0 ] ;
}

- (void)setWaterfallOffset:(float)freq sideband:(int)polarity
{
	float offset ;
	
	offset = fabs( freq ) ;
	
	vfoOffset = offset ;
	sideband = polarity ;
	
	[ waterfall setOffset:freq sideband:sideband ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setString:@"none" forKey:kHellAlignedFont ] ;
	[ pref setString:@"none" forKey:kHellUnalignedFont ] ;
	
	[ pref setString:@"Verdana" forKey:kHellTxFont ] ;
	[ pref setFloat:14.0 forKey:kHellTxFontSize ] ;
	[ (HellConfig*)config setupDefaultPreferences:pref ] ;
	
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (HellMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
}

- (void)updateColorsInViews
{
	[ (HellDisplay*)receiveView updateColorsInView ] ;
}

//  column is an array of 28 half pixels
- (void)addColumn:(float*)column index:(int)index xScale:(int)scale
{
	[ receiveView addColumn:column index:index xScale:scale ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	int i ;
	
	[ super updateFromPlist:pref ] ;
	
	[ self setAlignedFont:[ pref stringValueForKey:kHellAlignedFont ] ] ;
	[ self setUnalignedFont:[ pref stringValueForKey:kHellUnalignedFont ] ] ;
	
	fontName = [ pref stringValueForKey:kHellTxFont ] ;
	fontSize = [ pref floatValueForKey:kHellTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
		
	[ manager showSplash:@"Updating Hellschreiber configurations" ] ;
	[ (HellConfig*)config updateFromPlist:pref ] ;
	
	[ manager showSplash:@"Loading Hellschreiber macros" ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) {
			[ (HellMacros*)( macroSheet[i] ) updateFromPlist:pref option:i ] ;
		}
	}
	
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;
	
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *fnt ;
	int i ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	[ super retrieveForPlist:pref ] ;
	
	//  remove deprecated keys
	[ pref removeKey:kHellFont ] ;
	[ pref removeKey:kHellFontSize ] ;
	
	//  get the current fonts
	[ pref setString:[ NSString stringWithCString:font[alignedFont]->name encoding:kTextEncoding ] forKey:kHellAlignedFont ] ;
	[ pref setString:[ NSString stringWithCString:font[unalignedFont]->name encoding:kTextEncoding ] forKey:kHellUnalignedFont ] ;

	fnt = [ transmitView font ] ;
	[ pref setString:[ fnt fontName ] forKey:kHellTxFont ] ;
	[ pref setFloat:[ fnt pointSize ] forKey:kHellTxFontSize ] ;
	
	[ (HellConfig*)config retrieveForPlist:pref ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (HellMacros*)( macroSheet[i] ) retrieveForPlist:pref option:i ] ;
	}
}

//  sideband state (set from PSKConfig's LSB/USB button)
//  NO = LSB
- (void)selectAlternateSideband:(Boolean)state
{
	sidebandState = state ;
	[ rx setSidebandState:state ] ;
	[ waterfall setSideband:(state)?1:0 ] ;
}

- (void)sendMessageImmediately
{
	[ transmitCountLock lock ] ;
	transmitCount++ ;
	[ transmitCountLock unlock ] ;
}

/* local */
//  this gets periodically called
- (void)timedOut:(NSTimer*)timer
{
	if ( charactersSinceTimerStarted == 0 ) {
		//  timed out!
		[ self changeTransmitStateTo:NO ] ;
	}
	charactersSinceTimerStarted = 0 ;
}

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
	[ transmitViewLock lock ] ;
	storage = [ transmitView textStorage ] ;
	total = [ storage length ] ;
	string = [ storage string ] ;
	
	while ( indexOfUntransmittedText < total ) {
		uch = [ string characterAtIndex:indexOfUntransmittedText++ ] ;
		[ config transmitCharacter:uch ] ;
		charactersSinceTimerStarted++ ;
	}
	[ transmitViewLock unlock ] ;
}

- (void)checkTransmitBuffer:(NSTimer*)timer
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
			[ config transmitCharacter:uch ] ;
			charactersSinceTimerStarted++ ;
		}
	}
	[ transmitViewLock unlock ] ;
}

- (Boolean)transmitting
{
	return transmitState ;
}

- (void)useSlashedZero:(Boolean)state
{
	[ super useSlashedZero:state ] ;
	// [ rx1 useSlashedZero:state ] ;
}

- (void)changeTransmitStateTo:(Boolean)state
{
	NSColor *indicatorColor ;
	
	transmitState = [ config turnOnTransmission:state button:transmitButton ] ;
	
	if ( transmitState == YES ) {
		[ self ptt:YES ] ;
		indicatorColor =  [ NSColor redColor ] ;
		[ [ transmitView window ] makeFirstResponder:transmitView ] ;
		if ( timeout ) [ timeout invalidate ] ;
		charactersSinceTimerStarted = 0 ;
		if ( [ manager useWatchdog ] ) timeout = [ NSTimer scheduledTimerWithTimeInterval:150 target:self selector:@selector(timedOut:) userInfo:self repeats:YES ] ;
		transmitBufferCheck = [ NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkTransmitBuffer:) userInfo:self repeats:YES ] ;
		//  set text color in receive view and turn on transmit
		[ NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(delayTransmit:) userInfo:self repeats:NO ] ;
	}
	else {
		[ self ptt:NO ] ;
		if ( timeout ) [ timeout invalidate ] ;
		timeout = nil ;
		if ( receiveWait ) [ receiveWait invalidate ] ;
		receiveWait = nil ;
		if ( transmitBufferCheck ) [ transmitBufferCheck invalidate ] ;
		transmitBufferCheck = nil ;
		[ transmitCountLock lock ] ;
		transmitCount = 0 ;
		[ transmitCountLock unlock ] ;
		indicatorColor = [ NSColor colorWithCalibratedWhite:0.5 alpha:1.0 ] ;
		[ self setSentColor:NO view:receiveView textAttribute:receiveTextAttribute ] ;
		[ transmitView select ] ;
	}
	[ transmitLight setBackgroundColor:indicatorColor ] ;
}

//  this overrides the method in Modem.m that is called from the app
- (void)enterTransmitMode:(Boolean)state
{
	if ( !frequencyDefined ) return ;		//  return if the waterfall has not been previously clicked
	
	if ( state != transmitState ) {
		if ( state == YES ) {
			//  immediately change state to transmit
			[ self changeTransmitStateTo:state ] ;
		}
		else {
			//  enter a %[rx] character into the stream
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
	[ config flushTransmitBuffer ] ;
}

//  this overrides the method in Modem.m
- (void)flushAndLeaveTransmit
{
	[ self flushOutput ] ;
	[ self enterTransmitMode:NO ] ;
}

- (NSSlider*)inputAttenuator:(ModemConfig*)config
{
	return inputAttenuator ;
}

- (void)transmitButtonChanged
{
	int state ;
	
	state = ( [ transmitButton state ] == NSOnState ) ;
	
	if ( state ) {
		if ( ![ config soundInputActive ] ) {
			//  check if A/D is active
			[ transmitButton setState:NSOffState ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"Sound Card not active", nil ) informativeText:NSLocalizedString( @"Select Sound Card", nil ) ] ;
			return ;
		}
		if ( ![ rx canTransmit ] ) {
			//  check if receive frequency has been selected
			[ transmitButton setState:NSOffState ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"Hellschreiber not on", nil ) informativeText:NSLocalizedString( @"Click on waterfall", nil ) ] ;
			[ self flushOutput ] ;
			return ;
		}
	}
	[ self enterTransmitMode:state ] ;
}

- (IBAction)flushTransmitStream:(id)sender
{
	[ self flushOutput ] ;
}

- (void)inputAttenuatorChanged
{
	[ [ (HellConfig*)config inputSource ] setDeviceLevel:inputAttenuator ] ;
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
		storage = [ transmitView textStorage ] ;
		total = [ storage length ] ;		
		start = original.location ;
		length = original.length ;
		
		if ( length == total && [ replace length ] == 0 && transmitState == NO ) {
			[ transmitView clearAll ] ;
			indexOfUntransmittedText = 0 ;
			return NO ;
		}
		if ( length > 0 ) {
			if ( ( start+length ) == total ) {
				//  allow deletion at end to replace umlauts, etc  v0.35
				int replacement = [ [ storage string ] characterAtIndex:total-1 ] ;
				if ( ( replacement == 168 ) ||		// opt U
				     ( replacement == 710 ) ||		// opt I
				     ( replacement == 96 )  ||		// opt `
				     ( replacement == 180 ) ||		// opt e
				     ( replacement == 732 ) ) {		// opt n
					 
					//printf( "replace by %s\n", [ replace cStringUsingEncoding:kTextEncoding ] ) ;
					return YES ;
				}
				//  deleting <length> characters from end
				if ( transmitState == YES ) {
					for ( i = 0; i < length; i++ ) [ config transmitCharacter:0x08 ] ;
					indexOfUntransmittedText -= length ;
				}
				return YES ;
			}
			if ( transmitState == YES ) {
				[ transmitView insertAtEnd:replace ] ;
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				return NO ;
			}
			//  not yet transmitted
			if ( original.location < indexOfUntransmittedText ) {
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
				return NO ;
			}
			return YES ;
		}

		//  insertion length = 0
		if ( start != total ) {
			//  inserting in the middle of the transmitView
			if ( transmitState == YES ) {
				//  always insert text at the end when in transmit state
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ transmitView insertAtEnd:replace ] ;
				return NO ;
			}
			else {
				if ( original.location < indexOfUntransmittedText ) {
					//  attempt to insert into text that has already been transmitted
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
					[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
					return NO ;
				}
				return YES ;
			}
		}
		//  inserting at the end of buffer (-checkTransmitBuffer will pick it up)
		if ( [ replace length ] != 0 ) return YES ;
	}
	return YES ;
}

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
	
	[ receiveView setTextColors:textColor transmit:sentTextColor ] ;
	[ transmitView setViewTextColor:textColor attribute:transmitTextAttribute ] ;
}

- (void)slopeChanged
{
	[ rx slopeChanged:[ slopeSlider floatValue ] ] ;
}

- (void)positionButtonPushed:(id)sender
{
	int direction ;
	
	direction = ( sender == upButton ) ? 1 : -1 ;
	[ rx positionChanged:direction ] ;
}

//  one bit per pixel fonts
- (void)setAlignedFont:(NSString*)name
{
	int i ;
	
	//  walk through all fonts to find name
	for ( i = 0; i < fonts; i++ ) {
		if ( [ name isEqualToString:[ NSString stringWithCString:font[i]->name encoding:kTextEncoding ] ] ) {
			//  found matching name, check that it is aligned font
			if ( ( font[i]->version & STEMALIGNED ) != 0 ) {
				alignedFont = i ;
				return ;
			}
			//  otherwise go find any aligned font
			break ;
		}
	}
	//  font either not found of is not an aligned font, pick the first available aligned font
	for ( i = 0; i < fonts; i++ ) {
		if ( ( font[i]->version & STEMALIGNED ) != 0 ) {
			alignedFont = i ;
			return ;
		}
	}
}

//  two bit per pixel fonts
- (void)setUnalignedFont:(NSString*)name
{
	[ fontMenu selectItemWithTitle:name ] ;
	unalignedFont = [ fontMenu indexOfSelectedItem ] ;
	if ( unalignedFont < 0 ) unalignedFont = 0 ;
	// select for use
	[ config selectFont:unalignedFont ] ;
}

- (void)addFont:(HellschreiberFontHeader*)inFont index:(int)index
{
	if ( index == 0 ) {
		fonts = 1 ;
		[ fontMenu removeAllItems ] ;
	}
	if ( ( index+1 ) > fonts ) fonts = index+1 ;
	font[index] = inFont ;
	
	[ fontMenu insertItemWithTitle:[ NSString stringWithCString:inFont->name encoding:kTextEncoding ] atIndex:index ] ;
}

// NSMenuValidation for fontMenu
-(BOOL)validateMenuItem:(NSMenuItem*)item
{
	int i ;
	
	if ( modeNeedsAlignedFont == NO ) return YES ;	//  use any font

	for ( i = 0; i < fonts; i++ ) {
		if ( [ fontMenu itemAtIndex:i ] == item ) {
			return ( ( font[i]->version & STEMALIGNED ) != 0 ) ;
		}
	}
	return YES ;
}

- (void)fontChanged
{
	int index ;
	
	index = [ fontMenu indexOfSelectedItem ] ;
	[ config selectFont:index ] ;
	if ( modeNeedsAlignedFont ) alignedFont = index ; else unalignedFont = index ;
}

- (void)modeChanged
{
	int mode ;
	
	mode = [ [ modeMenu selectedItem ] tag ] ;
	
	//  take care of fonts when mode changes
	modeNeedsAlignedFont = ( mode == HELLFM105 ) ;	
	[ fontMenu selectItemAtIndex:( modeNeedsAlignedFont ) ? alignedFont : unalignedFont ] ; 	
	[ self fontChanged ] ;
	
	[ rx setMode:mode ] ;
	[ (HellConfig*)config setMode:mode ] ;
}

//  -- AppleScript support --

- (void)setModulationCodeFor:(Transceiver*)transceiver to:(int)code
{
	int mode ;
	
	switch ( code ) {
	case 'h105':
		mode = HELLFM105 ;
		break ;
	case 'h245':
		mode = HELLFM245 ;
		break ;
	default:
	case 'Feld':
		mode = HELLFELD ;
		break ;
	}
	[ modeMenu selectItemWithTag:mode ] ;
	[ self modeChanged ] ;
}

- (int)modulationCodeFor:(Transceiver*)transceiver
{
	int mode ;
	
	mode = [ [ modeMenu selectedItem ] tag ] ;
	if ( mode == HELLFM245 ) return 'h245' ;
	if ( mode == HELLFM105 ) return 'h105' ;
	return 'Feld' ;
}

//  AppleScript support (callbacks from Modules)
- (float)frequencyFor:(Module*)module
{
	//  no RIT for now
	return [ self transmitFrequency ] ;
}

- (void)setFrequency:(float)freq module:(Module*)module
{
	//  no RIT for now
	[ self frequencyUpdatedTo:freq ] ;
	[ self clicked:freq secondsAgo:0 option:NO fromWaterfall:NO waterfallID:0 ] ;
}

//  this is called from the AppleScript module
- (void)transmitString:(const char*)s
{
	unichar uch ;
	
	while ( *s ) {
		uch = *s++ ;
		[ config transmitCharacter:uch ] ;
	}
}

@end
