//
//  RTTYConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Mon May 17 2004.
	#include "Copyright.h"
//

#import "RTTYConfig.h"
#import "CMDSPWindow.h"
#import "Application.h"
#import "FSK.h"
#import "FSKHub.h"
#import "FSKMenu.h"
#import "Messages.h"
#import "Oscilloscope.h"
#import "ModemColor.h"
#import "Messages.h"
#import "ModemSource.h"
#import "modemTypes.h"
#import "Plist.h"
#import "PTT.h"
#import "RTTYInterface.h"
#import "RTTYModulator.h"
#import "RTTYReceiver.h"
#import "RTTYRxControl.h"
#import "RTTYTxConfig.h"
#import "TextEncoding.h"
#import "VUMeter.h"

@implementation RTTYConfig

//  RTTY Config

//  set tone pair for instrumentation
- (void)setTonePairMarker:(const CMTonePair*)tonepair
{
	//  set FSK markers
	[ oscilloscope setTonePairMarker:tonepair ] ;
}

- (void)txTonePairChanged:(RTTYRxControl*)control
{
	if ( txConfig ) [ txConfig setupTonesFrom:control lockTone:NO ] ;
}

- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control txConfig:(RTTYTxConfig*)inTxConfig
{
	modemRxControl = control ;
	configSet = *set ;
	txConfig = inTxConfig ;
		
	toneMatrix = nil ;
	transmitButton = nil ;
	timeout = nil ;
	vuMeter = [ control vuMeter ] ;
	
	overrun = [ [ NSLock alloc ] init ] ;
	[ super initializeActions ] ;

	[ vuMeter setup ] ;
	fastFileSpeed = 4 ;
	[ self setupModemSource:set->inputDevice channel:set->channel ] ;

	//  delegate to trap config panel closure
	[ window setDelegate:self ] ;
	//  start sampling later in an NSTimer driven -checkActive
	[ modemSource enableInput:YES ] ;
	
	//  v0.48 -- set up FSK interface (v0.83 not for ASCII)
	if ( [ modemObj isASCIIModem ] == NO ) {
		fsk = [ [ FSK alloc ] initWithHub:[ [ modemObj application ] fskHub ] menu:afskMenu modem:modemObj ] ;
	}
	//  capture menu changes
	if ( afskMenu ) {
		[ afskMenu setAction:@selector(afskMenuChanged) ] ;
		[ afskMenu setTarget:self ] ;
	}
	[ self setInterface:prefMatrix to:@selector(prefMatrixChanged) ] ;
}

- (RTTYTxConfig*)txConfig
{
	return txConfig ;
}

- (FSK*)fsk
{
	return fsk ;
}

//	v0.85
- (int)ook
{
	NSString *s = [ afskMenu titleOfSelectedItem ] ;
	
	if ( [ s isEqualToString:kOOKMenuTitle ] || [ s isEqualToString:kDigiKeyerOOKMenuTitle ] ) return 1 ;		//  v0.87
	return 0 ; 
}

//	v0.87
- (void)setKeyerMode
{
	NSString *menuTitle ;
	PTT *ptt ;
	int controlPort, mode ;
	
	if ( afskMenu != nil ) {
		menuTitle = [ afskMenu titleOfSelectedItem ] ;		
		// if OOK in digiKeyer, force to FSK Mode, otherwise force keyer to Digital mode if a microKeyer
		if ( fsk  ) {
			controlPort = [ fsk controlPortForName:menuTitle ] ;
			if ( controlPort > 0 ) {
				mode = [ menuTitle isEqualToString:kDigiKeyerOOKMenuTitle ] ? kMicrohamFSKRouting : kMicrohamDigitalRouting ;	//  v0.93b
				[ fsk setKeyerMode:mode controlPort:controlPort ] ;
				return ;
			}
		}
	}
	if ( txConfig ) {
		//  fsk port not found, use PTT menu instead
		ptt = [ txConfig pttObject ] ;
		if ( ptt ) [ ptt setKeyerMode:kMicrohamDigitalRouting ] ;	//  v0.93b
	}
}

- (void)afskMenuChanged
{
	//  in case it was not set, set to AFSK
	if ( [ afskMenu indexOfSelectedItem ] < 0 ) [ afskMenu selectItemAtIndex:0 ] ;
	
	preferredAFSKMenuTitle = actualAFSKMenuTitle = [ afskMenu titleOfSelectedItem ] ;
	[ (RTTY*)modemObj afskChanged:[ afskMenu indexOfSelectedItem ] config:self ] ;
	
	[ self setKeyerMode ] ;
}

//  delegate of NSMenu (afskMenu)
-(BOOL)validateMenuItem:(NSMenuItem*)item
{
	if ( fsk ) return [ fsk validateAfskMenuItem:item ] ;
	return NO ;
}

- (NSPopUpButton*)sidebandMenu
{
	return sidebandMenu ;
}

- (NSPopUpButton*)afskMenu
{
	return afskMenu ;
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
	if ( [ overrun tryLock ] ) {
		//  discard overuns
		if ( ( ( isActiveButton && !isTransmit ) || [ modemSource fileRunning ] ) && interfaceVisible ) {
			*data = *[ pipe stream ] ;
			[ self exportData ] ;
			[ vuMeter importData:pipe ] ;
		}
		if ( configOpen && oscilloscope ) {
			[ oscilloscope addData:[ pipe stream ] isBaudot:NO timebase:1 ] ;
		}
		[ overrun unlock ] ;
	}
}

//  check active button
- (Boolean)updateActiveButtonState
{
	[ super updateActiveButtonState ] ;	
	if ( modemRxControl ) {
		[ modemRxControl setTuningIndicatorState:isActiveButton ] ;
		[ modemRxControl turnOnMarkers:isActiveButton ] ;
	}
	return isActiveButton ;
}

/* local */
- (void)setupDefaultColorPreferences:(Preferences*)pref
{
	[ self set:configSet.textColor fromRed:1.0 green:0.8 blue:0.0 into:pref ] ;
	[ self set:configSet.backgroundColor fromRed:0.0 green:0.0 blue:0.0 into:pref ] ;
	[ self set:configSet.plotColor fromRed:0.0 green:1.0 blue:0.0 into:pref ] ;
}

//  preferences maintainence, called from RTTY.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	modemRxControl = control ;
	
	if( kFastPlayback ) [ pref setInt:1 forKey:kFastPlayback ] ;
	[ pref setInt:0 forKey:configSet.active ] ;

	preferredAFSKMenuTitle = actualAFSKMenuTitle = @"AFSK" ;
	if ( configSet.fskSelection ) [ pref setString:preferredAFSKMenuTitle forKey:configSet.fskSelection ] ; 
	
	[ self setupDefaultColorPreferences:pref ] ;
	[ control setupDefaultPreferences:pref config:self ] ;
	[ modemSource setupDefaultPreferences:pref ] ;
	
	if ( txConfig ) [ txConfig setupDefaultPreferences:pref rttyRxControl:control ] ;
}

- (void)updateColorsFromPreferences:(Preferences*)pref configSet:(RTTYConfigSet*)set
{
	NSColor *color, *sent, *bg, *plot ;
		
	color = [ self getColor:set->textColor from:pref ] ;
	sent = [ self getColor:set->sentColor from:pref ] ;
	bg = [ self getColor:set->backgroundColor from:pref ] ;
	plot = [ self getColor:set->plotColor from:pref ] ;		
	//  set colors
	[ textColor setColor:color ] ;
	[ backgroundColor setColor:bg ] ;
	[ plotColor setColor:plot ] ;
	[ oscilloscope setDisplayStyle:0 plotColor:plot ] ;  //  initially spectrum
	[ modemObj setTextColor:color sentColor:sent backgroundColor:bg plotColor:plot forReceiver:[ modemRxControl uniqueID ] ] ;
}

//  called from RTTY.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control 
{
	int i, count, state ;
	const char *rttyString ;
	NSButton *b ;
	NSString *s ;

	modemRxControl = control ;
	
	[ self updateColorsFromPreferences:(Preferences*)pref configSet:&configSet ] ;

	if ( ( ![ modemSource updateFromPlist:pref ] ) && ( [ activeButton state ] == NSOnState ) ) {
		[ activeButton setState:NSOffState ] ;
		//  toggle input attenuator		
		[ Messages alertWithMessageText:NSLocalizedString( @"RTTY settings needs to be reselected", nil ) informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}
	
	//  set up active button state
	state = ( [ pref intValueForKey:configSet.active ] == 1 ) ? NSOnState : NSOffState ;
	[ activeButton setState:state ] ;
	//  now reset active states if autoconnect is off
	if ( [ pref intValueForKey:kAutoConnect ] == 0 ) [ activeButton setState:NSOffState ] ;

	[ modemSource setDeviceLevel:[ modemRxControl inputAttenuator ] ] ;

	//  rtty NSMatrix checkboxes
	if ( prefMatrix ) {
		s = [ pref stringValueForKey:configSet.prefs ] ;
		count = [ prefMatrix numberOfRows ] ;
		if ( s ) {
			rttyString = [ s cStringUsingEncoding:kTextEncoding ] ;
			for ( i = 0; i < count; i++ ) {
				state = rttyString[i] ;
				if ( state == 0 ) break ;
				b = [ prefMatrix cellAtRow:i column:0 ] ;
				[ b setState:( state == '1' ) ? NSOnState : NSOffState ] ;
			}
		}
		[ modemObj setRTTYPrefs:prefMatrix channel:configSet.channel ] ;
	}
	[ modemRxControl updateFromPlist:pref config:self ] ;
	if ( txConfig ) [ txConfig updateFromPlist:pref rttyRxControl:control ] ;
	if ( fileSpeedCheckbox ) {
		state = [ pref intValueForKey:kFastPlayback ] ;
		[ fileSpeedCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
		[ self updateFileSpeed ] ;
	}
	
	if ( configSet.fskSelection ) {
		preferredAFSKMenuTitle = [ pref stringValueForKey:configSet.fskSelection ] ;

		if ( preferredAFSKMenuTitle && fsk ) {
			if ( [ fsk checkAvailability:preferredAFSKMenuTitle ] ) {
				actualAFSKMenuTitle = preferredAFSKMenuTitle ;
			}
			else {
				actualAFSKMenuTitle = @"AFSK" ;
				NSString *hdr = [ NSString stringWithFormat:@"FSK device '%s' that is use in the %s Interface is unavailable.", [ preferredAFSKMenuTitle UTF8String ], [ [ modemObj ident ] UTF8String ] ] ;
				[ Messages alertWithMessageText:hdr informativeText:NSLocalizedString( @"Reselect FSK", nil ) ] ;
			}
		}
		else {
			//  should not happen, but just in case...
			preferredAFSKMenuTitle = actualAFSKMenuTitle = @"AFSK" ;
		}
		[ afskMenu selectItemWithTitle:actualAFSKMenuTitle ] ;
		[ self afskMenuChanged ] ;
	}
	return true ;
}

- (RTTYConfigSet*)configSet
{
	return &configSet ;
}

- (void)retrieveActualColorPreferences:(Preferences*)pref
{
	[ self set:configSet.textColor fromColor:[ textColor color ] into:pref ] ;
	[ self set:configSet.backgroundColor fromColor:[ backgroundColor color ] into:pref ] ;
	[ self set:configSet.plotColor fromColor:[ plotColor color ] into:pref ] ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	int i, count ;
	char *s, str[16] ;
	NSButton *b ;
	
	modemRxControl = control ;
	prefVersion = [ pref intValueForKey:kPrefVersion ] ;

	[ self retrieveActualColorPreferences:pref ] ;
	//  rtty input prefs
	[ modemSource retrieveForPlist:pref ] ;
	if ( fileSpeedCheckbox ) [ pref setInt:( ( [ fileSpeedCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kFastPlayback ] ;
	
	if ( prefMatrix ) {
		count = [ prefMatrix numberOfRows ] ;
		s = str ;
		for ( i = 0; i < count; i++ ) {
			b = [ prefMatrix cellAtRow:i column:0 ] ;
			// for version 3 and earlier Plist, force BELL off
			if ( prefVersion <= 3 && i == 1 ) *s++ = '1' ; else *s++ = ( [ b state ] == NSOnState ) ? '1' : '0' ;
		}
		*s = 0 ;
	}
	if ( [ [ NSString stringWithCString:str encoding:kTextEncoding ] length ] == 0 ) {
		[ pref setString:@"" forKey:configSet.prefs ] ;
	}
	else {
		[ pref setString:[ NSString stringWithCString:str encoding:kTextEncoding ] forKey:configSet.prefs ] ;
	}

	//  active button states and local flag
	[ pref setInt:( [ activeButton state ] == NSOnState )? 1 : 0 forKey:configSet.active ] ;
	[ modemRxControl retrieveForPlist:pref config:self ] ;
	if ( txConfig ) [ txConfig retrieveForPlist:pref rttyRxControl:control ] ;
	
	if ( configSet.fskSelection ) [ pref setString:preferredAFSKMenuTitle forKey:configSet.fskSelection ] ;
}


// -------------------------------------------------------------------

- (void)colorChanged:(NSColorWell*)client
{
	NSColor *txColor ;
	
	txColor = ( transmitTextColor ) ? [ transmitTextColor color ] : [ textColor color ] ;
	
	[ oscilloscope setDisplayStyle:[ waveformMatrix selectedRow ] plotColor:[ plotColor color ] ] ;
	[ modemObj setTextColor:[ textColor color ] sentColor:txColor backgroundColor:[ backgroundColor color ] plotColor:[ plotColor color ] forReceiver:[ modemRxControl uniqueID ] ] ;	
}

- (void)prefMatrixChanged
{
	[ modemObj setRTTYPrefs:prefMatrix channel:configSet.channel ] ;
}

//  ------------------------ Delegates -----------------------
//  delegate for Config panel
- (BOOL)windowShouldClose:(id)sender
{
	configOpen = NO ;
	[ self updateInputSamplingState ] ;
	if ( txConfig ) [ txConfig stopSampling ] ;
	//  turn tone matrix selection to OFF
	[ toneMatrix deselectAllCells ] ;
	[ toneMatrix selectCellAtRow:0 column:0 ] ;
	toneIndex = 0 ;

	return YES ;
}

@end
