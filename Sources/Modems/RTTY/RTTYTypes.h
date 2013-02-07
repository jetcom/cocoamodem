/*
 *  RTTYTypes.h
 *  cocoaModem 2.0
 *
 *  Created by Kok Chen on 1/6/06.
 */

#ifndef _RTTYTYPES_H_
	#define _RTTYTYPES_H_

	typedef struct {
		int channel ;					// LEFTCHANNEL
		NSString *inputDevice ;			// kRTTYInputDevice
		NSString *outputDevice ;		// kRTTYOutputDevice
		NSString *outputLevel ;			// kRTTYOutputLevel
		NSString *outputAttenuator ;	// kRTTYOutputAttenuator
		NSString *tone ;				// kRTTYTone
		NSString *mark ;				// kRTTYMark
		NSString *space ;				// kRTTYSpace
		NSString *baud ;				// kRTTYBaud
		NSString *controlWindow ;		// nil, or kDualRTTYMainControlWindow
		NSString *squelch ;				// kRTTYSquelch
		NSString *active ;				// kRTTYActive
		NSString *stopBits ;			// kRTTYStopBits
		NSString *sideband ;			// kRTTYMode
		NSString *rxPolarity ;			// kRTTYRxPolarity
		NSString *txPolarity ;			// kRTTYTxPolarity
		NSString *prefs ;				// kRTTYPrefs
		NSString *textColor ;			// kRTTYTextColor
		NSString *sentColor ;			// kRTTYSentColor
		NSString *backgroundColor ;		// kRTTYBackgroundColor		
		NSString *plotColor ;			// kRTTYPlotColor	
		NSString *vfoOffset ;			// nil, or kWFRTTYOffset
		NSString *fskSelection ;		// nil, or kRTTYFSKSelection
		Boolean  usesRTTYAuralMonitor ;
		NSString *auralMonitor ;		// nil, or name of sub dictionary
	} RTTYConfigSet ;
	
#endif

