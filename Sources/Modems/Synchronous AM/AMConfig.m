//
//  AMConfig.m
//  cocoaModem
//
//  Created by Kok Chen on Jan 17 2007.
	#include "Copyright.h"
//

#import "AMConfig.h"
#import "Application.h"
#import "AuralMonitor.h"
#import "Messages.h"
#import "ModemSource.h"
#import "Oscilloscope.h"
#import "Plist.h"
#import "SynchAM.h"
#import "VUMeter.h"
#import "CMPCO.h"
#import "CMDSPWindow.h"

@implementation AMConfig

//  Synch-AM Config

- (void)awakeFromModem:(SynchAM*)modem
{
	int i ;
	
	soundFileRunning = outputRunning = NO ;
	outbufLock = [ [ NSLock alloc ] init ] ;
	for ( i = 0; i < 1024; i++ ) outputBuffer[i] = 0.0 ;
	vuMeter = [ modem vuMeter ] ;
	
	[ super initializeActions ] ;
	[ vuMeter setup ] ;
	fastFileSpeed = 10 ;
	
	[ self setupModemSource:kSynchAMInputDevice channel:LEFTCHANNEL ] ;

	//  delegate to trap config panel closure
	[ window setDelegate:self ] ;
	
	//  start sampling later in an NSTimer driven -checkActive
	[ modemSource enableInput:YES ] ;		
}

- (void)setOutputScale:(float)v
{
	[ (SynchAM*)modemObj setOutputScale:v ] ;
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

- (int)needData:(float*)outbuf samples:(int)n
{
	NSLog( @"AMConfig: needData should not be called" ) ;
	return 1 ;
}

- (void)setOutput:(float*)array samples:(int)n
{	
	if ( n != 512 ) {
		[ auralMonitor addLeft:nil right:nil samples:512 client:self ] ;
		return ;
	}
	
	[ outbufLock lock ] ;
	[ auralMonitor addLeft:array right:array samples:512 client:self ] ;
	[ outbufLock unlock ] ;
}

- (void)setSideband:(int)index
{
	//  not used
}

- (void)updateAuralMonitorState
{
	if ( !auralMonitor ) {
		auralMonitor = [ [ NSApp delegate ] auralMonitor ] ;
		if ( auralMonitor == nil ) return ;
	}

	if ( interfaceVisible == YES ) {
		if ( outputRunning ) return ;
		outputRunning = YES ;
		[ auralMonitor addClient:self ] ;
		
	}
	else {
		if ( !outputRunning ) return ;
		outputRunning = NO ;
		[ auralMonitor removeClient:self ] ;
	}
}

- (IBAction)openAuralMonitor:(id)sender
{
	if ( auralMonitor ) [ auralMonitor showWindow ] ;
}

- (void)updateVisibleState:(Boolean)state
{
	interfaceVisible = state ;
	//  now check if we need to turn on/off actual sampling
	[ self updateInputSamplingState ] ;
	[ self updateAuralMonitorState ] ;
}

- (void)setupModemDest:(NSString*)outputDevice controlView:(NSView*)controlView attenuatorView:(NSView*)levelView
{	
}

//  preferences maintainence, called from Hellschreiber.m
//  setup default preferences (keys are found in Plist.h)
- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ modemSource setupDefaultPreferences:pref ] ;
}

//  called from SyncAM.m
//  update all parameters from the plist (called after fetchPlist)
- (Boolean)updateFromPlist:(Preferences*)pref
{
	int state ;
	NSString *selStr ;
	
	//  set up active button states and set the button states
	//  later, a Timer would activate to obey these buttons
	
	[ activeButton setState:( [ pref intValueForKey:kSynchAMActive ] == 1 ) ? NSOnState : NSOffState ] ;
	
	//  now reset active states if autoconnect is off
	if ( [ pref intValueForKey:kAutoConnect ] == 0 ) {
		[ activeButton setState:NSOffState ] ;
	}
	
	if (  ![ modemSource updateFromPlist:pref ] && ( [ activeButton state ] == NSOnState ) ) {
		[ activeButton setState:NSOffState ] ;
		selStr = [ @"Synch AM: " stringByAppendingString:NSLocalizedString( @"Select Sound Card", nil ) ] ;
		[ Messages alertWithMessageText:selStr informativeText:NSLocalizedString( @"Device removed", nil ) ] ;
	}
	[ modemSource setDeviceLevel:[ (SynchAM*)modemObj inputAttenuator:self ] ] ;
		
	[ (SynchAM*)modemObj setWaterfallOffset:0.0 sideband:1 ] ;		//  this updates the labels of the waterfall
	
	state = [ pref intValueForKey:kFastPlayback ] ;
	[ fileSpeedCheckbox setState:( state ) ? NSOnState : NSOffState ] ;
	
	//  always fast file speed
	[ fileSpeedCheckbox setState:NSOnState ] ;
	[ self updateFileSpeed ] ;

	return true ;
}

//  update preference dictionary for writing back into the plist file
- (void)retrieveForPlist:(Preferences*)pref
{
	//  Sync AM input prefs
	[ modemSource retrieveForPlist:pref ] ;
	[ pref setInt:( ( [ fileSpeedCheckbox state ] == NSOnState ) ? 1 : 0 ) forKey:kFastPlayback ] ;
	
	//  active button states and local flag
	[ pref setInt:( [ activeButton state ] == NSOnState )? 1 : 0 forKey:kSynchAMActive ] ;
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

- (void)applicationTerminating
{
	//  sound card termination now handled by AudioManager.m
	//if ( modemSource ) [ modemSource applicationTerminating ] ;
	//if ( auralMonitor ) [ auralMonitor removeClient:self ] ;
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
