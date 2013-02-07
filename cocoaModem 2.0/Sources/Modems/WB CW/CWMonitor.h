//
//  CWMonitor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/1/06.

#ifndef _CWMONITOR_H_
	#define _CWMONITOR_H_

	#import "DestClient.h"
	#import "CMPCO.h"
	#import "Preferences.h"

	@class CWReceiver ;
	@class WBCW ;
	@class AuralMonitor ;
	
	@interface CWMonitor : DestClient {
		IBOutlet id monitorControl ;				//  shared between main and sub CWConfig
		IBOutlet id monitorAttenuator ;				//	shared between main and sub CWConfig

		IBOutlet id activeButton ;	

		IBOutlet id mainChannel ;	
		IBOutlet id mainPitch ;	
		IBOutlet id subChannel ;	
		IBOutlet id subPitch ;	
		IBOutlet id txChannel ;	
		IBOutlet id txPitch ;	
		IBOutlet id txSidetoneEnable ;	

		IBOutlet id panoSeparation ;	
		IBOutlet id panoBalance ;	
		IBOutlet id panoReverseCheckbox ;	

		WBCW *modem ;
		CWReceiver *receiver[2] ;
		AuralMonitor *auralMonitor ;
		
		CMPCO *transmitSidetone ;
		//  filter for deglitching R/T transitions
		CMFIR *leftTxFilter, *rightTxFilter ;				//  v0.88  separate Rx and Tx filters
		CMFIR *leftRxFilter, *rightRxFilter ;
		
		Boolean running ;
		Boolean mute ;
		Boolean isWide[2] ;
		Boolean isPano[2] ;
		Boolean isEnabled[2], allowSidetone[2] ;
		int sideband[2] ;
		float sidetoneBuf[1024], panoBuf[512] ;
		float monitorGain[2] ;
		int mainChannels ;
		int subChannels ;
		int txChannels ;
		float separation ;
		float balance ;
		float agcGain[2] ;
		
		Boolean activeState ;
		Boolean modemVisible ;
		Boolean transmitState ;
		Boolean txSidetoneState ;
		Boolean panoReversed ;
		
		CMFIR *panoLow, *panoHigh ;
		
		int accumulatedRx, accumulatedTx ;
		float localLeftBuf[512], localRightBuf[512] ;
		int auralLockout ;
	}

	- (void)changeTransmitStateTo:(Boolean)state ;

	- (void)setupMonitor:(NSString*)deviceName modem:(WBCW*)cwModem main:(CWReceiver*)main sub:(CWReceiver*)sub ;

	- (void)enableSidetone:(Boolean)state index:(int)n ;
	- (void)enableWide:(Boolean)state index:(int)n ;
	- (void)enablePano:(Boolean)state index:(int)n ;
	- (void)setEnabled:(Boolean)state index:(int)n ;
	- (void)monitorLevel:(float)value index:(int)n ;
	- (void)sidebandChanged:(int)state index:(int)n ;
	
	- (void)setVisibleState:(Boolean)state ;
	- (void)setMute:(Boolean)state ;
	- (void)terminate ;
	
	- (void)push:(float*)inph quadrature:(float*)quad wide:(float*)wide samples:(int)n ;
	- (void)transmitted:(float*)buf samples:(int)n ;
	
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	@end

#endif
