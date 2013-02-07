//
//  FAXConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Mar 6 2006.
	#include "Copyright.h"
//

#import "FAXConfig.h"
#include "Application.h"
#include "FAX.h"
#include "FAXDisplay.h"
#include "Messages.h"
#include "ModemSource.h"
#include "Oscilloscope.h"
#include "Plist.h"
#include "VUMeter.h"
#include "CMPCO.h"
#include "CMDSPWindow.h"

@implementation FAXConfig

//  HF-FAX Config

- (void)awakeFromModem:(FAX*)modem
{
	soundFileRunning = NO ;
	vuMeter = [ modem vuMeter ] ;
	
	[ super initializeActions ] ;
	
	[ vuMeter setup ] ;
	fastFileSpeed = 10 ;
	[ self setupModemSource:kFAXInputDevice channel:LEFTCHANNEL ] ;
	
	[ self setInterface:deviationCheckbox to:@selector(deviationChanged) ] ;
	
	//  delegate to trap config panel closure
	[ window setDelegate:self ] ;
	
	//  start sampling later in an NSTimer driven -checkActive
	[ modemSource enableInput:YES ] ;		
}

//	v0.73
- (void)deviationChanged
{
	[ [ (FAX*)modemObj faxView ] setDeviation: ( [ deviationCheckbox state ] == NSOnState )? 1 : 0 ] ;
}

- (NSPopUpButton*)sidebandMenu
{
	return sidebandMenu ;
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
	if ( ( ( isActiveButton && !isTransmit ) || [ modemSource fileRunning ] ) && interfaceVisible ) {
		*data = *[ pipe stream ] ;
		[ self exportData ] ;
		[ vuMeter importData:pipe ] ;
	}
	if ( configOpen && oscilloscope ) {
		[ oscilloscope addData:[ pipe stream ] isBaudot:NO timebase:1 ] ;
	}
}

//  0 - LSB
//  1 - USB
- (void)setSideband:(int)index
{
}

//  preferences maintainence, called from Hellschreiber.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setInt:0 forKey:kFAXActive ] ;
	[ pref setInt:0 forKey:kFAXDeviation ] ;			//  v0.73
	[ pref setInt:1 forKey:kFastPlayback ] ;
	[ pref setInt:0 forKey:kFAXPPM ] ;
	[ pref setString:@"" forKey:kFAXFolder ] ;

	[ modemSource setupDefaultPreferences:pref ] ;
}

//  called from FAX.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref
{
	int state ;
	FAXDisplay *faxView ;
	
	//  set up active button states and set the button states
	//  later, a Timer would activate to obey these buttons
	[ activeButton setState:( [ pref intValueForKey:kFAXActive ] == 1 ) ? NSOnState : NSOffState ] ;
	faxView = [ (FAX*)modemObj faxView ]  ;
	[ faxView setPPM:(float)[ pref intValueForKey:kFAXPPM ] ] ;
	[ faxView setFolder: [ pref stringValueForKey:kFAXFolder ] ] ;
	
	//  now reset active states if autoconnect is off
	if ( [ pref intValueForKey:kAutoConnect ] == 0 ) [ activeButton setState:NSOffState ] ;
	
	if (  ![ modemSource updateFromPlist:pref ] && ( [ activeButton state ] == NSOnState ) ) {
		[ activeButton setState:NSOffState ] ;
		//  toggle input attenuator	
		NSString *selStr = [ @"HF Fax: " stringByAppendingString:NSLocalizedString( @"Select Sound Card", nil ) ] ;	
		[ Messages alertWithMessageText:selStr informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}
	
	[ modemSource setDeviceLevel:[ (FAX*)modemObj inputAttenuator:self ] ] ;
	
	[ modemObj setWaterfallOffset:0.0 sideband:1 ] ;		//  this updates the labels of the waterfall
	
	state = [ pref intValueForKey:kFastPlayback ] ;
	[ fileSpeedCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
	
	state = [ pref intValueForKey:kFAXDeviation ] ;
	[ deviationCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
	[ faxView setDeviation:state ] ;

	//  always fast file speed
	[ fileSpeedCheckbox setState:NSOnState ] ;
	[ self updateFileSpeed ] ;

	return true ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref
{
	int ppm ;
	FAXDisplay *faxView ;
	
	//  FAX input prefs
	[ modemSource retrieveForPlist:pref ] ;
	[ pref setInt:( ( [ fileSpeedCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kFastPlayback ] ;
	
	faxView = [ (FAX*)modemObj faxView ] ;
	ppm = [ faxView ppm ] ;
	[ pref setInt:ppm forKey:kFAXPPM ] ;
	[ pref setString:[ faxView folder ] forKey:kFAXFolder ] ;
	
	//  active button states and local flag
	[ pref setInt:( [ activeButton state ] == NSOnState )? 1 : 0 forKey:kFAXActive ] ;
	
	[ pref setInt:( [ deviationCheckbox state ] == NSOnState )? 1 : 0 forKey:kFAXDeviation ] ;
}

//  called from ModemSource when file starts
- (void)soundFileStarting:(NSString*)filename
{
	soundFileRunning = YES ;
}

//  called from ModemSource when file stopped
- (void)soundFileStopped
{
	soundFileRunning = NO ;
}

//  ------------------------ Delegates -----------------------
//  delegate for Config panel
- (BOOL)windowShouldClose:(id)sender
{
	configOpen = NO ;
	[ self updateInputSamplingState ] ;

	return YES ;
}


@end
