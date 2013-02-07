//
//  PSK.h
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
//

#ifndef _PSK_H_
	#define _PSK_H_

	#import <Cocoa/Cocoa.h>
	#import "ContestInterface.h"
	#import "AYTextView.h"
	#import "CMPSKModes.h"

	@class Module ;
	@class PSKAuralMonitor ;
	@class PSKConfig ;
	@class PSKContestTxControl ;
	@class PSKControl ;
	@class PSKReceiver ;
	@class PSKTransmitControl ;
	@class SubDictionary ;
	@class Transceiver ;
	@class Waterfall ;
	
	typedef struct {
		NSButton *enableButton ;
		NSTextField *attenuationField ;
		NSMatrix *floatMatrix ;
		NSTextField *fixedFrequency ;
	} AuralAction ;
	
	@interface PSK : ContestInterface {
	
		IBOutlet id waterfall ;
		IBOutlet id transmitButton ;
		IBOutlet id squelch ;
		
		IBOutlet id rx1Group ;
		IBOutlet id rx1View ;
		IBOutlet id rx1ControlView ;
		IBOutlet id receive1View ;
		
		IBOutlet id rx2Group ;		
		IBOutlet id rx2View ;		
		IBOutlet id rx2ControlView ;	
		IBOutlet id receive2View ;
			
		IBOutlet id txControlView ;		
		IBOutlet id contestTxControlView ;		
		
		IBOutlet id inputAttenuator ;
		IBOutlet id vuMeter ;
		
		IBOutlet id shiftJISTextField ;		
				
		//  v0.78 PSKAuralMonitor
		IBOutlet id auralPanel ;
		IBOutlet id masterLevel ;
		IBOutlet id masterMute ;
		
		IBOutlet id auralRxEnable0 ;
		IBOutlet id auralAttenuatorField0 ;
		IBOutlet id auralFixedFrequency0 ;
		IBOutlet id auralFloatMatrix0 ;
		
		IBOutlet id auralRxEnable1 ;
		IBOutlet id auralAttenuatorField1 ;
		IBOutlet id auralFixedFrequency1 ;
		IBOutlet id auralFloatMatrix1 ;
		
		IBOutlet id auralTxEnable ;
		IBOutlet id auralTxAttenuatorField ;
		IBOutlet id auralTxFixedFrequency ;
		IBOutlet id auralTxFloatMatrix ;
		
		IBOutlet id auralWideEnable ;
		IBOutlet id auralWideAttenuatorField ;
		
		PSKAuralMonitor *pskAuralMonitor ;
		
		SubDictionary *auralMonitorPlist[4] ;		//  0,1 = receiver, 2 = transmitter, 3 = wideband
		AuralAction auralAction[4] ;
		
		PSKReceiver *rx1 ;
		PSKReceiver *rx2 ;
		PSKControl *rx1Control ;
		PSKControl *rx2Control ;
		PSKTransmitControl *txControl ;
		PSKContestTxControl *contestTxControl ;
		Module *transmitModule[2] ;
		int selectedTransceiver ;

		NSRect receiveFrame ;				//  frame of receive-only receiver
		NSRect transceiveFrame ;			//  frame of receive-transmit receiver

		//   active receive view (one of two exchange views)
		ExchangeView *activeReceiveView ;
		TextAttribute *activeReceiveTextAttribute ;	
		
		NSThread *thread ;
		
		//  v0.70 Shift-JIS
		unsigned char jisToUnicode[65536*2] ;
		unsigned char unicodeToJis[65536*2] ;
		//	v0.95 text insertion
		NSRange insertionRange ;
		int unmarkedTextLength ;

		//  receive and transmit
		//  int pskMode ;				//  asks receiver each time
		//  transmit
		NSLock *transmitViewLock ;
		NSTimer *transmitBufferCheck ;
		int indexOfUntransmittedText ;
		int hardLimitForBackspace ;			//  v0.66
		TextAttribute *transmitAttribute ;
		Boolean frequencyDefined ;
		// receive
		TextAttribute *receive1TextAttribute, *receive2TextAttribute ;
	}

	- (IBAction)flushTransmitStream:(id)sender ;
	- (IBAction)openTableView:(id)sender ;

	//  v0.97
	- (void)openPSKTableView:(Boolean)state ;
	- (void)nextStationInTableView ;
	
	//	v1.01c
	- (void)previousStationInTableView ;
	
	//  v0.78 aural monitor
	- (IBAction)openAuralPanel:(id)sender ;
	- (PSKAuralMonitor*)auralMonitor ;
	//  callback from demodulator to set aural frequencies
	- (void)setReceiveFrequency:(float)freq mode:(int)mode forReceiver:(int)receiver ;
	
	//  v0.70  JIS tables are created in Application.m and loaded using these teo methods
	- (void)setJisToUnicodeTable:(unsigned char*)uarray;
	- (void)setUnicodeToJisTable:(unsigned char*)uarray;

	- (PSKConfig*)configObj ;
	- (PSKReceiver*)receiver:(int)index ;
	- (void)setFrequencyDefined ;
	
	- (void)useControlButton:(Boolean)state ;
	- (void)setAFCState:(Boolean)state ;
	
	- (Boolean)checkTx ;
	- (float)transmitFrequency ;
	- (void)transceiverChanged ;
	- (Boolean)transmitting ;
	- (void)flushOutput ;
	- (void)flushAndLeaveTransmit ;
	
	//  v0.70
	- (void)setUseShiftJIS:(Boolean)state ;
	- (void)setUseRawForPSK:(Boolean)state ;
	//  v0.71
	- (void)setAllowShiftJIS:(Boolean)state ;
	
	//  callback from PSK receiver
	- (void)frequencyUpdatedTo:(float)tone receiver:(int)uniqueID ;

	//  - (void)setPSKMode:(int)mode forReceiver:(int)index ;		v0.47 removed
	- (void)selectAlternateSideband:(Boolean)state ;
	- (void)setWaterfallOffset:(float)freq sideband:(int)sideband ;
	- (void)receiveFrequency:(float)freq setBy:(int)receiver ;
	- (void)selectView ;
	
	//  callback from PSK generator
	- (void)changeTransmitStateTo:(Boolean)state ;
	
	//  ---- AppleScript support ----
	- (int)modulationCodeFor:(Transceiver*)transceiver ;
	- (void)setModulationCodeFor:(Transceiver*)transceiver to:(int)code ;
	
	//  -- the following are deprecated AppleScripts --
	- (float)getRxOffset:(int)trx ;
	- (void)setRxOffset:(int)trx freq:(float)freq ;
	- (float)getTxOffset:(int)trx ;
	- (void)setTxOffset:(int)trx freq:(float)freq ;
	- (int)getPskModulation ;
	- (void)changePskModulationTo:(int)modulation ;


	@end

#endif
