//
//  LiteRTTY.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/2/07.
//  Copyright 2007 Kok Chen, W7AY. All rights reserved.
//

#import "LiteRTTY.h"
#import "ModemManager.h"
#import "LiteRTTYControl.h"
#import "ModemSource.h"
#import "Oscilloscope.h"
#import "Plist.h"
#import "RTTYReceiver.h"
#import "RTTYTxConfig.h"
#import "RTTYTypes.h"
#import "RTTYWaterfall.h"
#import "Transceiver.h"
#import "WFRTTYConfig.h"

@implementation LiteRTTY


- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr nib:(NSString*)nib
{
	CMTonePair tonepair ;
	float ellipseFatness = 0.9 ;
	
	RTTYConfigSet setA = { 
		LEFTCHANNEL, 
		kWFRTTYMainDevice, 
		kWFRTTYOutputDevice, 
		kWFRTTYOutputLevel, 
		kWFRTTYOutputAttenuator, 
		kWFRTTYMainTone, 
		kWFRTTYMainMark, 
		kWFRTTYMainSpace,
		kWFRTTYMainBaud,
		kWFRTTYMainControlWindow,
		kWFRTTYMainSquelch,
		kWFRTTYMainActive,
		kWFRTTYMainStopBits,
		kWFRTTYMainMode,
		kWFRTTYMainRxPolarity,
		kWFRTTYMainTxPolarity,
		kWFRTTYMainPrefs,
		kWFRTTYMainTextColor,
		kWFRTTYMainSentColor,
		kWFRTTYMainBackgroundColor,
		kWFRTTYMainPlotColor,
		kWFRTTYMainOffset,
		kWFRTTYMainFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kWFRTTYMainAuralMonitor
	} ;

	self = [ super initIntoTabView:tabview nib:nib manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		controlWindowOpen = NO ;		//  initially hide control window; this will be reset after Prefs is checked

		//  initialize txConfig before rxConfigs
		[ txConfig awakeFromModem:&setA rttyRxControl:a.control ] ;
		ptt = [ txConfig pttObject ] ;
		
		a.isAlive = YES ;
		a.control = [ [ LiteRTTYControl alloc ] initIntoView:receiverA client:self index:0 ] ;
		a.receiver = [ a.control receiver ] ;
		[ a.receiver createClickBuffer ] ;
		currentRxView = a.view = [ a.control view ] ;
		[ a.view setDelegate:self ] ;		//  text selections, etc
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:NSLocalizedString( @"Main Receiver", nil ) ] ;
		[ a.control setEllipseFatness:ellipseFatness ] ;
		[ configA awakeFromModem:&setA rttyRxControl:a.control txConfig:txConfig ] ;
		[ configA setChannel:0 ] ;
		control[0] = a.control ;
		configObj[0] = configA ;
		txLocked[0] = NO ;
		
		tonepair = [ a.control baseTonePair ] ;
		[ waterfallA setTonePairMarker:&tonepair index:0 ] ;

		// lite version's dummy B channel
		b.isAlive = NO ;
		b.control = [ [ RTTYRxControl alloc ] initIntoView:receiverB client:self index:1 ] ;
		[ [ receiverB window ] orderOut:self ] ; // v0.64c
		b.receiver = [ b.control receiver ] ;
		b.view = [ b.control view ] ;
		b.textAttribute = [ b.control textAttribute ] ;
		[ b.control setName:@"Unused Receiver" ] ;
		control[1] = b.control ;
		configObj[1] = nil ;
		txLocked[1] = NO ;

		[ configTab setDelegate:self ] ;

		//  AppleScript text callback
		[ a.receiver registerModule:[ transceiver1 receiver ] ] ;
		a.transmitModule = [ transceiver1 transmitter ] ;
		if ( !isLite ) {
			[ b.receiver registerModule:[ transceiver2 receiver ] ] ;
			b.transmitModule = [ transceiver2 transmitter ] ;
		}
		[ [ oscilloscope window ] setHidesOnDeactivate:NO ] ;
	}
	return self ;
}

//  intercept setVisible call to determine if modem is chosen
- (void)setVisibleState:(Boolean)visible
{
	[ super setVisibleState:visible ] ;
	if ( visible ) {
		if ( controlWindowOpen ) [ [ receiverA window ] orderFront:self ] ;
	}
	else {
		// hide RTTY control
		[ [ receiverA window ] orderOut:self ] ;
	}
}

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	isLite = YES ;
	[ mgr showSplash:@"Creating Lite RTTY Modem" ] ;
	return [ self initIntoTabView:tabview manager:mgr nib:@"LiteRTTY" ] ;
}

- (void)awakeFromNib
{
	[ super awakeFromNib ] ;
	
	[ self setInterface:txLockButton to:@selector(txLockChanged) ] ;

	//[ [ receiverA window ] setLevel:NSNormalWindowLevel ] ;
	//[ [ receiverA window ] setHidesOnDeactivate:YES ] ;
	
	[ [ receiverA window ] setDelegate:self ] ;
}

- (void)changeMarkersInSpectrum:(RTTYRxControl*)inControl
{
	CMTonePair tonepair = [ inControl rxTonePair ] ;
	
	[ oscilloscope setTonePairMarker:&tonepair ] ;
	[ oscilloscope selectTimeConstant:2 ] ;
}

- (void)drawSpectrum:(CMPipe*)pipe
{
	if ( [ [ oscilloscope window ] isVisible ] ) {
		[ oscilloscope addData:[ pipe stream ] isBaudot:YES timebase:0 ] ;
	}
}

- (Boolean)transmitIsLocked:(int)index
{
	Boolean txFixed ;

	if ( index == 0 ) {
		txFixed = ( [ txLockButton state ] == NSOnState ) ;
		return txFixed ;
	}
	return [ super transmitIsLocked:index ] ;
}

- (void)setTransmitLockButton:(int)index toState:(Boolean)locked
{
	if ( index == 0 ) {
		[ txLockButton setState:( locked ) ? NSOnState : NSOffState ] ;
		return ;
	}
	[ super setTransmitLockButton:index toState:locked ] ;
}


- (void)showControlWindow:(Boolean)state
{
	if ( [ [ manager nameOfSelectedTabView ] isEqualToString:@"RTTY" ] == NO ) return ;		//  v0.64c
	
	if ( state == YES ) {
		[ [ receiverA window ] orderFront:self ] ;
	}
	else {
		[ [ receiverA window ] orderOut:self ] ;
	}
	controlWindowOpen = state ;
}

- (IBAction)openControlWindow:(id)sender
{
	[ self showControlWindow:YES ] ;
}

- (IBAction)openSpectrumWindow:(id)sender ;
{
	[ [ oscilloscope window ] orderFront:self ] ;
}

- (BOOL)windowShouldClose:(id)sender
{
	if ( sender == [ receiverA window ] ) controlWindowOpen = NO ;
	return YES ;	
}

//  v0.64c show spectrum applescript
- (void)setShowSpectrum:(Boolean)state
{
	if ( state == YES ) [ [ oscilloscope window ] orderFront:self ] ; else [ [ oscilloscope window ] orderOut:self ] ;
}

//  v0.64c
- (NSAppleEventDescriptor*)spectrumPosition 
{
	NSAppleEventDescriptor *desc ;
	NSPoint point ;
	int x, y ;
	
	point = [ [ oscilloscope window ] frame ].origin ;
	x = point.x + 0.5 ;
	y = point.y + 0.5 ;
	
	desc = [ NSAppleEventDescriptor listDescriptor ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:x ] atIndex:1 ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:y ] atIndex:2 ] ;
	return desc ;
}

//  v0.64c
- (void)setSpectrumPosition:(NSAppleEventDescriptor*)point 
{
	NSAppleEventDescriptor *desc ;
	NSRect frame ;
	
	if ( [ point numberOfItems ] == 2 ) {
		frame = [ [ oscilloscope window ] frame ] ;

		desc = [ point descriptorAtIndex:1 ] ;
		frame.origin.x = [ desc int32Value ] ;
		desc = [ point descriptorAtIndex:2 ] ;
		frame.origin.y = [ desc int32Value ] ;
		[ [ oscilloscope window ] setFrame:frame display:YES ] ;
	}
}

//  v0.64c - show controls Applescript
- (void)setShowControls:(Boolean)state
{
	[ self showControlWindow:state ] ;
}

//  v0.64c
- (NSAppleEventDescriptor*)controlsPosition 
{
	NSAppleEventDescriptor *desc ;
	NSPoint point ;
	int x, y ;
	
	point = [ [ receiverA window ] frame ].origin ;
	x = point.x + 0.5 ;
	y = point.y + 0.5 ;
	
	desc = [ NSAppleEventDescriptor listDescriptor ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:x ] atIndex:1 ] ;
	[ desc insertDescriptor:[ NSAppleEventDescriptor descriptorWithInt32:y ] atIndex:2 ] ;
	return desc ;
}

//  v0.64c
- (void)setControlsPosition:(NSAppleEventDescriptor*)point 
{
	NSAppleEventDescriptor *desc ;
	NSRect frame ;
	
	if ( [ point numberOfItems ] == 2 ) {
		frame = [ [ receiverA window ] frame ] ;

		desc = [ point descriptorAtIndex:1 ] ;
		frame.origin.x = [ desc int32Value ] ;
		desc = [ point descriptorAtIndex:2 ] ;
		frame.origin.y = [ desc int32Value ] ;
		[ [ receiverA window ] setFrame:frame display:YES ] ;
	}
}

//  v0..65 -  send ^E directly only if Lite interface
- (void)enterTransmitMode:(Boolean)state
{
	if ( state != transmitState ) {
		if ( state == YES ) [ super enterTransmitMode:state ] ;
		else {
			//  enter a %[rx] character into the stream
			[ txConfig transmitCharacter:5 /* ^E */ ] ;			//  v0.56d
			[ transmitLight setBackgroundColor:[ NSColor yellowColor ] ] ;
		}
	}
}


@end
