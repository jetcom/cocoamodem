//
//  RTTYRxControl.h
//  cocoaModem
//
//  Created by Kok Chen on 1/24/05.
//

#ifndef _RTTYRXCONTROL_H_
	#define _RTTYRXCONTROL_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "CoreModemTypes.h"
	#include "AYTextView.h"
	
	@class ExchangeView ;
	@class Modem ;
	@class ModemConfig ;
	@class Preferences ;
	@class RTTY ;
	@class RTTYConfig ;
	@class RTTYModulator ;
	@class RTTYMonitor ;
	@class RTTYReceiver ;
	@class RTTYWaterfall ;
	@class Spectrum ;
	@class SubDictionary ;
	@class VUMeter ;
	
	@interface RTTYRxControl : CMTappedPipe {
		IBOutlet id controlView ;
		IBOutlet id tuningView ;
		IBOutlet id exchangeView ;
		IBOutlet id receiverName ;
		
		//  objects in aux window
		IBOutlet id auxWindow ;
		IBOutlet id squelchSlider ;
		IBOutlet id bandwidthMatrix ;
		IBOutlet id demodulatorModeMatrix ;
		IBOutlet id printControlCheckbox ;
		IBOutlet id auralLevelSlider ;
		IBOutlet id auralMonitorMute ;
		
		//  Aural Monitor Panel
		IBOutlet id monitorSheet ;
		
		IBOutlet id rxMonitorCheckbox ;
		IBOutlet id rxFixedRadioButton ;
		IBOutlet id rxMonitorFrequencyField ;
		IBOutlet id rxMonitorAttenuationField ;
		IBOutlet id rxMonitorBackgroundCheckbox ;
		IBOutlet id rxMonitorBackgroundAttenuator ;

		IBOutlet id rxMonitorClickVolumeSlider ;
		IBOutlet id rxMonitorClickPitchSlider ;
		IBOutlet id rxMonitorSoftLimitCheckbox ;
		
		IBOutlet id txMonitorCheckbox ;
		IBOutlet id txFixedRadioButton ;
		IBOutlet id txMonitorFrequencyField ;
		IBOutlet id txMonitorAttenuationField ;
		
		//  RTTY tones
		NSPopUpButton *sidebandMenu ;				//  interface in RTTYConfig
		IBOutlet id rxPolarityButton ;
		IBOutlet id txPolarityButton ;

		IBOutlet id markFreq ;
		IBOutlet id shiftField ;
		IBOutlet id baudRateBox ;
		IBOutlet id memorySelectMenu ;
		
		//  input controls
		IBOutlet id activeIndicator ;
		IBOutlet id inputAttenuator ;
		IBOutlet id vuMeter ;
		
		//  tones
		CMTonePair tonePair ;						// mark is always the lower tone (call adjustTone to get correct polarity)
		CMTonePair transmitTonePair ;				//  v0.67
		CMTonePair memory[4] ;
		int selectedTone ;
		int sideband ;								// 0 = LSB, 1 = USB
		int	rxPolarity ;							// 0 = normal, 1 = reverse
		int	txPolarity ;
		float vfoOffset ;
		float ritOffset ;
		Boolean txLocked ;
		
		RTTYMonitor *monitor ;
		Boolean activeTransmitter ;
		
		int uniqueID ;
		RTTY *client ;
		RTTYReceiver *receiver ;
		ModemConfig *config ;
		Spectrum *spectrumView ;
		RTTYWaterfall *waterfall ;

		SubDictionary *auralMonitorPlist ;
		
		TextAttribute *receiveTextAttribute ; 
	}
	
	- (IBAction)auxButtonPushed:(id)sender ;
	- (IBAction)tonePairStore:(id)sender ;
	- (IBAction)openAuralSheet:(id)sender ;
	- (IBAction)closeAuralSheet:(id)sender ;
	- (IBAction)openAuralMonitor:(id)sender ;
	
	- (void)setInterface:(NSControl*)object to:(SEL)selector ;
	
	//  tone pair controls
	- (CMTonePair)baseTonePair ;
	- (CMTonePair)rxTonePair ;
	- (CMTonePair)txTonePair ;
	- (CMTonePair)lockedTxTonePair ;
	- (float)cwTone ;

	- (void)setTonePair:(const CMTonePair*)tonepair mask:(int)mask ;
	- (void)setTonePair:(const CMTonePair*)tonepair ;
	- (int)sideband ;
	- (void)setRIT:(float)value ;
	- (void)setTransmitLock:(Boolean)state ;
	- (void)transmitterTonePairChangedTo:(CMTonePair*)pair ;	//  v0.78

	- (void)setEllipseFatness:(float)value ;

	- (void)fetchTonePairFromMemory ;
	- (void)updateTonePairInformation ;
	- (void)setBaudRateField:(float)rate ;
		
	- (id)initIntoView:(NSView*)view client:(Modem*)modem index:(int)index ;
	- (void)setupWithClient:(Modem*)modem index:(int)index ;
	- (void)setupDefaultFilters ;
	- (void)setupRTTYReceiver ;

	- (void)setName:(NSString*)name ;
	- (void)setSpectrumView:(Spectrum*)view ;
	- (void)setWaterfall:(RTTYWaterfall*)view ;
	- (void)setWaterfallOffset:(float)offset ;
	- (void)setPlotColor:(NSColor*)color ;
	
	- (void)showMonitor ;
	
	- (RTTYReceiver*)receiver ;
	- (ExchangeView*)view ;
	- (TextAttribute*)textAttribute ;
	- (NSSlider*)inputAttenuator ;
	- (VUMeter*)vuMeter ;
	- (int)uniqueID ;
	
	- (void)setTuningIndicatorState:(Boolean)active ;
	- (void)turnOnMarkers:(Boolean)active ;
	- (void)useAsTransmitTonePair:(Boolean)state ;
	
	//  AppleScript support
	- (float)markFrequency ;
	- (void)setMarkFrequency:(float)f ;
	- (float)spaceFrequency ;
	- (void)setSpaceFrequency:(float)f ;
	- (float)baudRate ;
	- (float)actualBaudRate ;						//  v0.50
	- (void)setBaudRate:(float)rate ;
	- (Boolean)invertStateForReceiver ;
	- (void)setInvertStateForReceiver:(Boolean)state ;
	- (Boolean)invertStateForTransmitter ;
	- (void)setInvertStateForTransmitter:(Boolean)state ;
	- (Boolean)breakinStateForTransmitter ;
	- (void)setBreakinStateForTransmitter:(Boolean)state ;
	
	//  v0.67 (separate info for receive and transmit
	- (float)markFrequencyForMask:(int)mask ;
	- (void)setMarkFrequency:(float)f mask:(int)mask;
	- (float)spaceFrequencyForMask:(int)mask ;
	- (void)setSpaceFrequency:(float)f mask:(int)mask;

	//  RTTY Monitor
	- (void)hideMonitorOnDeactivation:(Boolean)hide ;
	
	//  preferences
	
	- (void)setupBasicDefaultPreferences:(Preferences*)pref config:(ModemConfig*)cfg ;
	- (void)updateBasicFromPlist:(Preferences*)pref config:(ModemConfig*)cfg  ;
	- (void)retrieveBasicForPlist:(Preferences*)pref config:(ModemConfig*)config ; 

	- (void)setupDefaultPreferences:(Preferences*)pref config:(ModemConfig*)config ;
	- (void)updateFromPlist:(Preferences*)pref config:(ModemConfig*)config ;
	- (void)retrieveForPlist:(Preferences*)pref config:(ModemConfig*)config ;


	@end

#endif
