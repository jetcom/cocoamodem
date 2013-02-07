//
//  LiteRTTYControl.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/2/07.
//  Copyright 2007 Kok Chen, W7AY. All rights reserved.
//

#import "LiteRTTYControl.h"
#import "LiteRTTY.h"
#import "RTTYReceiver.h"


@implementation LiteRTTYControl

- (id)initIntoView:(NSView*)view client:(Modem*)modem index:(int)index
{
	self = [ super init ] ;
	if ( self ) {
		if ( [ NSBundle loadNibNamed:@"LiteRTTYControl" owner:self ] ) {	
			// loadNib should have set up controlView connection
			if ( view && controlView ) {
				//  set level of NSPanel to floasting level  v0.64e
				[ [ view window ] setLevel:NSFloatingWindowLevel ] ;
				[ [ view window ] orderOut:self ] ;
				[ view addSubview:controlView ] ;
				if ( auxWindow ) [ auxWindow setTitle: (index == 0) ? NSLocalizedString( @"RTTY Receiver", nil ) : NSLocalizedString( @"Sub Receiver", nil ) ] ;
				[ self setupWithClient:modem index:index ] ;
				if ( activeIndicator ) [ activeIndicator setBackgroundColor:[ NSColor grayColor ] ] ;
				return self ;
			}
		}
	}
	return nil ;
}

//  audio source starts at config and is routed here first
//	the data is sent to the receiver and the tuning and any spectrum
- (void)importData:(CMPipe*)pipe
{
	if ( !receiver || ![ receiver enabled ] ) return ;
	
	[ super importData:pipe ] ;
	[ (LiteRTTY*)client drawSpectrum:pipe ] ;
}

//  v0.67
- (void)setTonePair:(const CMTonePair*)tonepair mask:(int)mask
{
	[ super setTonePair:tonepair mask:mask ] ;
	if ( mask & 1 ) [ (LiteRTTY*)client changeMarkersInSpectrum:self ] ;
}


@end
