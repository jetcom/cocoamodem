//
//  LitePSKDemodulator.h
//  cocoaModem 2.0  v0.57b
//
//  Created by Kok Chen on 10/19/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VCO8k.h"
#import "LitePSKMatchedFilter.h"
#import "CMComplexFIR.h"
#import "CMVaricode.h"

//  States
#define	kDemodulatorIdle			0
#define	kDemodulatorAcquire			1
#define	kDemodulatorStartDecode		2
#define	kDemodulatorDecode			3

@class PSKBrowserHub ;

@interface LitePSKDemodulator : NSObject {
	PSKBrowserHub *hub ;
	int state ;			//  kDemodulatorIdle, etc
	float frequency ;
	
	VCO8k *vco ;
	CMComplexFIR *decimateFilter ;
	CMAnalyticBuffer *input ; 
	float decimatedI[64], decimatedQ[64] ;
	
	//  clock extraction
	CMFIR *comb ;
	float previousClockSample ;
	
	//  matched filter
	LitePSKMatchedFilter *matchedFilter ;
	
	//  decoder
	CMVaricode *varicode ;
	long varicodeCharacter ;
	int decodeOffset ;
	Boolean disabled ;
	
	//  v0.70
	int doubleByteIndex ;
	int doubleByteValue[16] ;
	
	// afc
	int cycle ;
	Boolean finishedAcquire ;
	int acquireCount ;
	float freqError, freqErrors[32] ;
	
	//  used by client (for sorting)
	int userIndex ;					//  this indexes the rowMap of PSKBrowser (maps to a NSTableView row), negative if a row has not yet been assigned
	int uniqueID ;
	int removeCount ;
	int mark ;
	
	//  debug
	float lastQuality ;
	int lastDecoded ;
}

- (id)initWithClient:(PSKBrowserHub*)client uniqueID:(int)uid ;

- (void)activateWithFrequency:(float)freq ;
- (int)setToIdle ;

- (float)frequency ;
- (void)afcToFrequency:(float)freq ;
- (int)userIndex ;
- (void)setUserIndex:(int)index ;

- (int)state ;
- (int)uniqueID ;

- (int)mark ;
- (void)setMark:(int)value ;

- (void)clearRemoveCount ;
- (int)increaseRemoveCount ;
- (void)decreaseRemovalCount:(int)amount ;
- (int)removeCount ;

- (void)decode:(float*)buffer offset:(int)index ;
- (void)receivedBit:(int)bit quality:(float)quality ;

- (Boolean)disabled ;
- (void)setDisabled:(Boolean)state ;

// debug ;
- (float)quality ;
- (int)decoded ;


@end
