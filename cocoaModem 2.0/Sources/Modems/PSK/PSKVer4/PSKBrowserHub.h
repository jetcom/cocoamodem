//
//  PSKBrowserHub.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/26/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "PSKHub.h"
#import "LinkedArray.h"
#import "CMFFT.h"


@interface PSKBrowserHub : PSKHub {
	float liteBuffer[512*64] ;			//  mini-click buffer, used to accumulate 32,768 samples (4.096 seconds) for spectrum
	int bufferIndex ;					//  index into 64 512-sample segments of the liteBuffer
	int currentID ;
	int scanIndex ;						//  v0.97
	
	//  TableView LitePSKDemodulators
	LinkedArray *sortedDemodulators ;		
	LinkedArray *idleDemodulators ;		
	LinkedArray *removedDemodulators ;		
	NSLock *demodBusy ;	
	NSLock *pskBrowserSkipBuffer ;

	//  multi-PSK demodulators
	Boolean skipMultipleDemodulators, savedSkipMultipleDemodulators ;		//  save between visible and non-visible interface
	float squelch ;

	//  browser view
	NSTableView *table ;
	PSKBrowserTable *browserTable ;
	int refreshedRow ;
	Boolean started ;
	
	float peak[1000] ;
	float spectrum[4096] ;		//  4096 == 4000 Hz
	
	//  fft
	CMFFT *fft ;
	
	//  v0.70
	Boolean useShiftJIS ;
	unsigned char jisToUnicode[65536*2] ;
	
	NSThread *mainThread ;
	Boolean debugPrint ;
}

//  user input
- (void)squelchChanged:(NSSlider*)slider ;
- (void)openAlarm ;
- (void)testCheck ;
- (void)rescan ;

//  v0.70
- (void)setUseShiftJIS:(Boolean)state ;
- (Boolean)useShiftJIS ;
- (void)setJisToUnicodeTable:(unsigned char*)uarray ;

- (void)enableTableView ;
- (void)disableTableView ;
- (void)updateVisibleState:(Boolean)visible ;

- (void)useControlButton:(Boolean)state ;

- (void)importBuffer:(float*)buf ;
- (void)setBrowserTable:(NSTableView*)view ;
- (void)nextStationInTableView ;		//  v0.97
- (void)previousStationInTableView ;	//  v1.01c

- (void)tableViewSelectedTone:(float)tone option:(Boolean)option ;
- (void)setVFOOffset:(float)offset sideband:(Boolean)polarity ;

//  callbacks from the LitePSKDemodulator
- (void)demodulator:(LitePSKDemodulator*)demod newCharacter:(int)decoded quality:(float)quality frequency:(float)freq ;
- (void)demodulator:(LitePSKDemodulator*)demod startingAtFrequency:(float)freq ;

//  plist
- (Boolean)updateFromPlist:(Preferences*)pref ;
- (void)retrieveForPlist:(Preferences*)pref ;

@end
