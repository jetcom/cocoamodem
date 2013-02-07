//
//  FAX.m
//  cocoaModem
//
//  Created by Kok Chen on Mar 6 2006.
	#include "Copyright.h"
//

#import "FAX.h"
#include "Application.h"
#include "cocoaModemParams.h"
#include "Messages.h"
#include "Config.h"
#include "ExchangeView.h"
#include "FAXConfig.h"
#include "FAXDisplay.h"
#include "FAXReceiver.h"
#include "ModemDistributionBox.h"
#include "ModemManager.h"
#include "ModemSource.h"
#include "Plist.h"
#include "StdManager.h"
#include "VUMeter.h"
#include "Waterfall.h"
#include <stdlib.h>						// for malloc()
#include <string.h>						// for memset()


@implementation FAX

//  FAX : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	[ mgr showSplash:@"Creating FAX Modem" ] ;

	self = [ super initIntoTabView:tabview nib:@"HF-FAX" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
	}
	return self ;
}

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)awakeFromNib
{
	NSScrollView *sview ;
	NSScroller *scroller ;
	
	ident = NSLocalizedString( @"HF-FAX", nil ) ;

	[ (FAXConfig*)config awakeFromModem:self ] ;
	sidebandState = NO ;
	[ waterfall awakeFromModem ] ;
	[ waterfall enableIndicator:self ] ;
	//  set up the scroller for the input view
	sview = (NSScrollView*)[ [ receiveView superview ] superview ] ;
	scroller = [ sview verticalScroller ] ;
	[ scroller setFloatValue:1.0 knobProportion: 0.125 ] ;
	
	[ vuMeter setup ] ;
	rx = nil ;
	
	[ [ (FAXConfig*)config inputSource ] registerDeviceSlider:inputAttenuator ] ;	//  v0.80
	
	[ self setInterface:bandwidthMenu to:@selector(bandwidthChanged) ] ;
	[ self setInterface:inputAttenuator to:@selector(inputAttenuatorChanged) ] ;	//  v0.80 was missing earlier
}

//  v0.87
- (void)switchModemIn
{
	//  do nothing in receive only interface
}

- (void)inputAttenuatorChanged
{
	[ [ (FAXConfig*)config inputSource ] setDeviceLevel:inputAttenuator ] ;
}

- (void)setVisibleState:(Boolean)visible
{
	if ( visible ) {
		//  start the FAXDisplay (which should create the bitmap if it does not already exist)
		[ (FAXDisplay*)receiveView start ] ;
		//  initialize receiver if this is the first time we are made visible
		if ( !rx ) {
			//  create receiver
			rx = [ [ FAXReceiver alloc ] initFromModem:self ] ;
			[ rx enableReceiver:YES ] ;	
		}
	}
	[ super setVisibleState:visible ] ;
}

- (FAXConfig*)configObj
{
	return config ;
}

- (VUMeter*)vuMeter
{
	return vuMeter ;
}

- (FAXDisplay*)faxView
{
	return receiveView ;
}

//  overide base class to change AudioPipe pipeline (assume source is normalized)
//		source 
//		. self(importData)
//			. waterfall
//			. receiver
//			. VU Meter

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating HF-FAX sound source" ] ;
	//  send codec data here
	[ (FAXConfig*)config setClient:(CMTappedPipe*)self ] ;
	[ (FAXConfig*)config checkActive ] ;
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

//  waterfall clicked
//  Note: for USB left edge is always 400 Hz no matter what the VFO offset is
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)acquire waterfallID:(int)index
{
	[ rx selectFrequency:freq fromWaterfall:acquire ] ;
	[ rx enableReceiver:YES ] ;
}

//  receive frequency set not by clicking, but by direct entry
- (void)receiveFrequency:(float)freq
{
	[ self frequencyUpdatedTo:freq ] ;
	[ self clicked:freq secondsAgo:0 option:NO fromWaterfall:NO waterfallID:0 ] ;
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
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setInt:0 forKey:kFAXActive ] ;
	[ pref setInt:0 forKey:kFAXSize ] ;

	[ (FAXConfig*)config setupDefaultPreferences:pref ] ;
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	[ super updateFromPlist:pref ] ;
	
	[ manager showSplash:@"Updating HF-FAX configurations" ] ;
	[ (FAXConfig*)config updateFromPlist:pref ] ;
	//  v0.80 registers with ModemSource and setup half/full button
	[ self inputAttenuatorChanged ] ;				
	[ [ self faxView ] setupScale:[ pref intValueForKey:kFAXSize ] ] ;
	
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	[ super retrieveForPlist:pref ] ;
	[ (FAXConfig*)config retrieveForPlist:pref ] ;
	[ pref setInt:( [ [ self faxView ] scaleIsFullSize ] ? 1 : 0 ) forKey:kFAXSize ] ;	// v0.80
}

//  sideband state (set from PSKConfig's LSB/USB button)
//  NO = LSB
- (void)selectAlternateSideband:(Boolean)state
{
	sidebandState = state ;
	[ waterfall setSideband:(state)?1:0 ] ;
}

- (IBAction)waterfallRangeChanged:(id)sender
{
	[ waterfall setDynamicRange:[ sender floatValue ] ] ;
}

- (void)bandwidthChanged
{
	if ( rx ) [ rx changeBandwidthTo:[ bandwidthMenu indexOfSelectedItem ] ] ;
}

@end
