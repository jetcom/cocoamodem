//
//  RTTYStereoRxControl.m
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
	#include "Copyright.h"
//

#import "RTTYStereoRxControl.h"
#include "Analyze.h"
#include "ChannelSelector.h"
#include "RTTYConfig.h"
#include "RTTYStereoReceiver.h"

@implementation RTTYStereoRxControl

/* local */
- (void)updateChannels
{
	ChannelSelector *refPipe ;
	
	[ (RTTYStereoReceiver*)receiver setReference:[ refChannelMenu indexOfSelectedItem ] dut:[ dutChannelMenu indexOfSelectedItem ] ] ;
	refPipe = [ (RTTYStereoReceiver*)receiver refPipe ] ;
	[ refPipe setTap:(CMTappedPipe*)tuningView ] ;
}

- (void)setupRTTYReceiver
{
	ChannelSelector *refPipe ;
	
	[ (RTTYStereoReceiver*)receiver setupReceiverChain:[ config inputSource ] config:(AnalyzeConfig*)config ] ;
	refPipe = [ (RTTYStereoReceiver*)receiver refPipe ] ;
	[ refPipe setTap:(CMTappedPipe*)tuningView ] ;
}

- (void)setupDefaultFilters
{
	[ super setupDefaultFilters ] ;
	memory[2].mark = 1615 ;  memory[2].space = 1785 ;
	memory[3].mark = 1000 ;  memory[3].space = 830 ;
}

- (void)setupWithClient:(Modem*)modem index:(int)index
{
	uniqueID = index ;
	client = (RTTY*)modem ;
	
	[ self setupDefaultFilters ] ;
	config = [ modem configObj:index ] ;
	receiver = [ [ RTTYStereoReceiver alloc ] initReceiver:index ] ;
	//  set up receiver connections
	[ self updateChannels ] ;
	[ receiver setSquelch:squelchSlider ] ;
	[ receiver setReceiveView:exchangeView ] ;
	[ receiver setDemodulatorModeMatrix:demodulatorModeMatrix ] ;
	[ receiver setBandwidthMatrix:bandwidthMatrix ] ;
}

- (IBAction)channelMenuChanged:(id)sender 
{
	[ self updateChannels ] ;
}

@end
