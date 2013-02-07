//
//  PSKHub.h
//  cocoaModem 2.0  v0.57b
//
//  Created by Kok Chen on 10/18/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DataPipe.h"
#import "PSKDemodulator.h"
#import "PSKBrowserTable.h"
#import "LitePSKDemodulator.h"
#import <AudioToolbox/AudioConverter.h>

@class PSK ;
@class PSKAuralMonitor ;
@class PSKReceiver ;

//enum HubLockCondition {
//	kNoHubData,
//	kHasHubData
//} ;

@interface PSKHub : NSObject {
	Boolean hasBrowser ;
	PSKDemodulator *mainDemodulator ;
	PSKReceiver *receiver ;
	DataPipe *dataPipe ;
	NSLock *poolBusy ;	
	NSLock *pskDemodulatorLock ;		//  v0.66
		
	//  resampler
	AudioConverterRef rateConverter ;
	
	//  states
	Boolean enabled ;
	float audioStream[512] ;
}

- (id)initHub ;
- (void)setDelegate:(PSKReceiver*)who ;
- (void)setPSKModem:(PSK*)modem index:(int)index ;
- (void)importData:(CMPipe*)pipe ;

- (Boolean)isEnabled ;
- (void)setupResampler ;
- (void)sendBufferToDemodulators:(float*)buffer samples:(int)samples ;

- (Boolean)demodulatorEnabled ;
- (void)enableReceiver:(Boolean)state ;
- (void)setReceiveFrequency:(float)tone ;
- (void)setPSKMode:(int)mode ;
- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall ;
- (float)receiveFrequency ;


@end
