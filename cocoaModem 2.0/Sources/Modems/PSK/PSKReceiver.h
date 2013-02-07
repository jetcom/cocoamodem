//
//  PSKReceiver.h
//  cocoaModem
//
//  Created by Kok Chen on Thu Sep 02 2004.
//

#ifndef _PSKRECEIVER_H_
	#define _PSKRECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#import "CoreModem.h"

	@class ExchangeView ;
	@class Modem ;
	@class Module ;
	@class Preferences ;
	@class PSK ;
	@class PSKAuralMonitor ;
	@class PSKBrowserHub ;
	@class PSKControl ;
	@class PSKMonitor ;
	@class PSKHub ;
	@class Waterfall ;
	
	
	@interface PSKReceiver : CMPipe {
		IBOutlet id controlView ;			//  receiver controls
		IBOutlet id freqIndicator ;			
		IBOutlet id phaseIndicator ;			
		IBOutlet id rxFrequencyField ;			
		IBOutlet id txFrequencyField ;			
		IBOutlet id IMDField ;		
		IBOutlet id transmitLight ;	
		
		IBOutlet id browserTable ;
		IBOutlet id browserSquelch ;
		PSKHub *pskHub ;
		PSKBrowserHub *pskBrowserHub ;
			
		Modem *client ;
		int uniqueID ;
		NSLock *lock ;
		PSKMonitor *monitor ;
		
		Boolean extendedASCII ;
		
		int squelchHold ;
		float *clickBuffer[512] ;
		int clickBufferProducer, clickBufferConsumer ;
		NSLock *clickBufferLock ;
		NSLock *overrunLock ;
		NSConditionLock *newData ;
		
		CMDataStream cmData ;
		//  user controls
		PSKControl *control ;
		
		//  textview
		ExchangeView *receiveView ;
		Module *appleScript ;
		
		float vfoOffset ;
		Boolean sideband ;					// NO == LSB
		float displayedRxFrequency ;
		float displayedTxFrequency ;
		float currentFrequency ;
		
		Boolean transferToTransmitFreq ;
		
		float baseIh[512], baseQh[512] ;
		
		int mux ;
		Boolean slashZero ;
		
		//  Shift-JIS
		unsigned char jisToUnicode[65536*2] ;
		unsigned char unicodeToJis[65536*2] ;		
		Boolean useShiftJIS ;
		Boolean useRawOutput ;
		int doubleByteIndex ;
		int doubleByteValue[16] ;
		int lastASCII ;					//  use to detect \r\n and \n\r
		
		//  transmitter
		float transmitFrequency ;
		NSColor *txOff, *txReady1, *txReady0, *txWait, *txActive ;
		int indicatorState ;

		//  autorelease management
		NSAutoreleasePool *delayedRelease ;
	}
	
	- (IBAction)browserSquelchChanged:(id)sender ;
	- (IBAction)browserSquelchRescan:(id)sender ;
	- (IBAction)browserSetAlarm:(id)sender ;
	- (IBAction)testCheck:(id)sender ;
	
	- (void)useControlButton:(Boolean)state ;
	- (void)updateVisibleState:(Boolean)visible ;

	- (PSK*)controlModem ;
	- (void)enableTableView:(Boolean)state ;		//  v0.97
	- (void)nextStationInTableView ;				//  v0.97
	- (void)previousStationInTableView ;			//  v1.01c
	- (void)setFrequencyDefined ;
	
	- (void)receivedCharacter:(int)c spectrum:(float*)spectrum quality:(float)quality ;		//  v0.57 replaced the -receivedCharacter:spectrum: call
	
	- (id)initIntoView:(NSView*)view client:(Modem*)modem index:(int)index ;
	- (void)setExchangeView:(ExchangeView*)eview ;
	- (void)setPSKControl:(PSKControl*)inControl ;
	
	- (void)clearClickBuffer ;										//  v0.89
	- (void)setTransmitFrequencyToTone:(float)tone ;
	
	//  receive and transmit
	- (void)setPSKMode:(int)mode ;
	
	//  v0.70 Shift-JIS (for xcvr1 only)
	- (void)setUseShiftJIS:(Boolean)state ;		
	- (void)setUseRawForPSK:(Boolean)state ;
	- (Boolean)useShiftJIS ;		
	- (void)setJisToUnicodeTable:(unsigned char*)uarray ;
	- (void)setUnicodeToJisTable:(unsigned char*)uarray ;

	
	//  CMPSKDemodulator interface
	- (void)enableReceiver:(Boolean)state ;
	- (Boolean)isEnabled ;
	- (void)selectFrequency:(float)freq secondsAgo:(float)secs fromWaterfall:(Boolean)fromWaterfall ;
	- (void)setTimeOffset:(float)history ;   // v0.64e
	
	//  receive
	- (void)setVFOOffset:(float)offset sideband:(Boolean)sideband ;
	- (void)updateReceiveFrequencyDisplay:(float)freq ;
	- (void)registerModule:(Module*)module ;
	
	//  transmit
	- (void)updateTransmitFrequencyDisplay:(float)freq ;
	- (void)vcoChangedTo:(float)freq ;
	- (void)setTransmitFrequencyToReceiveFrequency ;
	- (float)currentTransmitFrequency ;
	- (void)setTransmitLightState:(int)txState ;
	- (Boolean)canTransmit ;
	
	- (void)useSlashedZero:(Boolean)state ;
	
	//  frequencies offset by rig offset
	- (float)rxOffset ;
	- (float)txOffset ;
	- (void)setAndDisplayRxOffset:(float)freq ;
	- (void)setAndDisplayTxOffset:(float)freq ;
	
	//  frequencies are actual tone frequencies
	- (float)rxTone ;
	- (float)txTone ;
	- (void)setAndDisplayRxTone:(float)tone ;
	- (void)setTimeOffset:(float)timeOffset ;
	- (void)setAndDisplayTxTone:(float)tone ;

	//  Monitor scope
	- (void)showScope ;
	- (void)hideScopeOnDeactivation:(Boolean)hide ;
	
	// delegate to PSKDemodulator
	- (void)updateIMD:(float)imd snr:(float)snr ;
	
	// plist (browser window)
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	//  transmit light state
	#define	TxOff		0
	#define	TxReady		1
	#define	TxWait		2
	#define	TxActive	3

	@end

#endif
