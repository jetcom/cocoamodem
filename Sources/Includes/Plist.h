/*
 *  Plist.h
 *  cocoaModem
 *
 *  Created by Kok Chen on Thu May 20 2004.
 *
 */

#ifndef _PLIST_H_
	#define _PLIST_H_

	// keys
	
	#define	kPrefVersion				@"Pref version"

	#define kWindowPosition				@"MainWindowPosition"
	#define kServerWindowPosition		@"ServerWindowPosition"
	#define kTabName					@"Tab Name"
	#define kAppearancePrefs			@"Appearance Prefs"
	#define kEnableNetAudio				@"Use NetAudio"
	#define kHideWindow					@"Hide Lite window at launch"
	#define	kNoOpenRouter				@"Don't open Router"
	#define	kQuitWithAutoRouting		@"Set to Auto Routing when quit"
	
	#define	kVoiceAssist				@"Voice Assist"
	
	#define kInputName					@" Input Name"
	#define kInputSource				@" Input Source"
	#define kInputChannel				@" Input Channel"
	#define kInputSamplingRate			@" Input Sampling Rate"
	#define kOutputChannel				@" Output Channel"
	#define kOutputSamplingRate			@" Output Sampling Rate"
	#define kInputPad					@" Input Pad"
	#define kInputSlider				@" Input Slider"
	#define kOutputName					@" Output Name"
	#define kOutputSource				@" Output Source"
	#define kEqualizer					@" Equalizer"
	#define	kPTTMenu					@" PTT"
	
	#define	kModemList					@"Modems"					// string of ascii '1' and '0' that correspond to the modems in the order below)
	#define	kRTTYModemOrder				0
	#define	kWidebandRTTYModemOrder		1
	#define	kDualRTTYModemOrder			2
	#define	kPSKModemOrder				3
	#define	kMFSKModemOrder				4
	#define	kHellModemOrder				5
	#define	kSitorModemOrder			6
	#define	kFAXModemOrder				7
	#define kCWModemOrder				8
	#define kAMModemOrder				9
	#define kASCIIModemOrder			10
	
	#define	kModemsImplemented			11
	
	//	Aural Monitor
	#define kAuralMonitorLevel			@"Aural Output Sound Level"
	#define kAuralMonitorAttenuator		@"Aural Output Attenuator"
	#define kAuralMonitorBlend			@"Aural Output Blend"
	#define kAuralMonitorMute			@"Aural Output Mute"
	
	//  SoftRock
	#define	kSoftRockInputDevice		@"SoftRock Input Device"
	#define kSoftRockWindowPosition		@"SoftRock Window Position"
	#define kSoftRockWindowOpen			@"SoftRock Window Open"
	#define kSoftRockActive				@"SoftRock Active"

	// PSK
	#define	kUseUnicodeForPSK			@"Use Unicode for PSK31"
	#define kPSKInputDevice				@"PSK Input Device"
	#define kPSKOutputDevice			@"PSK Output Device"
	#define kPSKSideband				@"PSK Mode"
	#define kPSKOffset					@"PSK Offset"
	#define	kPSKBrowserWindowPosition	@"PSK Browser Window Position"
	#define	kPSKBrowserSquelch			@"PSK Browser Squelch"
	#define	kPSKAlarmString				@"PSK Alarm String"
	#define kPSKAlarmCase				@"PSK Alarm Ignore Case"

	#define kPSK1Font					@"PSK 1 Font"
	#define kPSK1FontSize				@"PSK 1 Font Size"
	#define kPSK2Font					@"PSK 2 Font"
	#define kPSK2FontSize				@"PSK 2 Font Size"
	#define kPSKTxFont					@"PSK Tx Font"
	#define kPSKTxFontSize				@"PSK Tx Font Size"
	
	#define	kPSKTextColor				@"PSK Text Color"
	#define kPSKSentColor				@"PSK Sent Color"
	#define kPSKBackgroundColor			@"PSK Background Color"
	#define kPSKPlotColor				@"PSK Plot Color"

	#define kPSKActive					@"PSK Active"
	#define kPSKOutputLevel				@"PSK Output Sound Level"
	#define kPSKOutputAttenuator		@"PSK Output Attenuator"
	#define kPSKSquelchA				@"PSK Squelch A"
	#define kPSKSquelchB				@"PSK Squelch B"
	#define	kPSKPrefs					@"PSK PSKPrefs"
	
	#define kPSKMessages				@"PSK Messages"
	#define kPSKMessageTitles			@"PSK MessageTitles"
	#define kPSKOptMessages				@"PSK Option Messages"
	#define kPSKOptMessageTitles		@"PSK Option MessageTitles"
	#define kPSKShiftMessages			@"PSK Shift Messages"
	#define kPSKShiftMessageTitles		@"PSK Shift MessageTitles"
	
	#define kPSKWaterfallNR				@"PSK Waterfall Noise Reduction"
	
	//  Hellschreiber
	#define kHellActive					@"Hell Active"
	#define kHellSideband				@"Hell Mode"
	#define kHellDiddle					@"Hell Diddle"
	#define kHellOffset					@"Hell Offset"
	#define kHellOutputLevel			@"Hell Output Sound Level"
	#define kHellOutputAttenuator		@"Hell Output Attenuator"
	
	#define kHellInputDevice			@"Hell Input Device"
	#define kHellOutputDevice			@"Hell Output Device"
	
	#define	kHellTextColor				@"Hell Text Color"
	#define kHellSentColor				@"Hell Sent Color"
	#define kHellBackgroundColor		@"Hell Background Color"
	#define kHellPlotColor				@"Hell Plot Color"
	
	#define	kHellUnalignedFont			@"Hell Unaligned Font"
	#define	kHellAlignedFont			@"Hell Aligned Font"
	#define kHellFont					@"Hell Font"						// deprecated
	#define kHellFontSize				@"Hell Font Size"					// deprecated
	#define kHellTxFont					@"Hell Tx Font"
	#define kHellTxFontSize				@"Hell Tx Font Size"
	
	#define kHellMessages				@"Hell Messages"
	#define kHellMessageTitles			@"Hell MessageTitles"
	#define kHellOptMessages			@"Hell Option Messages"
	#define kHellOptMessageTitles		@"Hell Option MessageTitles"
	#define kHellShiftMessages			@"Hell Shift Messages"
	#define kHellShiftMessageTitles		@"Hell Shift MessageTitles"
	
	//  HF-FAX
	#define kFAXActive					@"FAX Active"	
	#define kFAXInputDevice				@"FAX Input Device"
	#define kFAXPPM						@"FAX clock ppm"
	#define kFAXFolder					@"FAX Folder"
	#define kFAXDeviation				@"FAX Deviation"
	#define kFAXSize					@"FAX Size"
	
	//  Synchronous AM
	#define kSynchAMActive				@"AM Active"	
	#define kSynchAMOutputActive		@"AM Output Active"	
	#define kSynchAMInputDevice			@"AM Input Device"
	#define kSynchAMOutputDevice		@"AM Output Device"
	#define	kSynchAMOutputDest			@"AM Outpur Destination"
	#define kSynchAMOutputLevel			@"AM Output Sound Level"
	#define kSynchAMOutputAttenuator	@"AM Output Attenuator"
	#define kSynchAMVolume				@"AM Volume"
	#define kSynchAMLockRange			@"AM Lock Range"
	#define kSynchAMLockCenter			@"AM Lock Center"
	#define kSynchAMEqEnable			@"AM Eq Enable"
	#define kSynchAMEq300				@"AM Eq 300"
	#define kSynchAMEq600				@"AM Eq 600"
	#define kSynchAMEq1200				@"AM Eq 1200"
	#define kSynchAMEq2400				@"AM Eq 2400"
	#define kSynchAMEq4800				@"AM Eq 4800"
	
	//  MFSK (common to MFSK16 and other MFSKmodes)
	#define	kMFSKSelection				@"MFSK Selection"
	#define kMFSKActive					@"MFSK Active"
	#define kMFSKSideband				@"MFSK Mode"
	#define kMFSKOffset					@"MFSK Offset"
	#define kMFSKOutputLevel			@"MFSK Output Sound Level"
	#define kMFSKOutputAttenuator		@"MFSK Output Attenuator"
	
	#define kMFSKInputDevice			@"MFSK Input Device"
	#define kMFSKOutputDevice			@"MFSK Output Device"
	
	#define	kMFSKTextColor				@"MFSK Text Color"
	#define kMFSKSentColor				@"MFSK Sent Color"
	#define kMFSKBackgroundColor		@"MFSK Background Color"
	#define kMFSKPlotColor				@"MFSK Plot Color"
	
	#define kMFSKFont					@"MFSK Font"
	#define kMFSKFontSize				@"MFSK Font Size"
	#define kMFSKTxFont					@"MFSK Tx Font"
	#define kMFSKTxFontSize				@"MFSK Tx Font Size"
	
	#define kMFSKSquelch				@"MFSK Squelch"
	
	#define kMFSKMessages				@"MFSK Messages"
	#define kMFSKMessageTitles			@"MFSK MessageTitles"
	#define kMFSKOptMessages			@"MFSK Option Messages"
	#define kMFSKOptMessageTitles		@"MFSK Option MessageTitles"
	#define kMFSKShiftMessages			@"MFSK Shift Messages"
	#define kMFSKShiftMessageTitles		@"MFSK Shift MessageTitles"

	#define kMFSKTrellisDepth			@"MFSK Trellis Depth"
	#define kMFSKWaterfallNR			@"MFSK Waterfall Noise Reduction"
	
	//  Domino
	#define kDominoFont					@"Domino Font"
	#define kDominoFontSize				@"Domino Font Size"
	#define kDominoSmoothScroll			@"Domino Smooth Scroll"
	#define kDominoEchoBeacon			@"Domino Echo Beacon"
	#define kDominoRcvrEnable			@"Domino Beacon Receive Enable"
	#define kDominoSendEnable			@"Domino Beacon Send Enable"
	#define kDominoBeacon				@"Domino Beacon Message"
	
	//  Analyze
	#define kAnalyzeFont				@"Analyze Font"
	#define kAnalyzeFontSize			@"Analyze Font Size"
	
	#define kAnalyzeInputDevice			@"Analyze Input Device"
	#define kAnalyzeOutputDevice		@"Analyze Output Device"
	#define kAnalyzeMode				@"Analyze Mode"
	#define kAnalyzePrefs				@"Analyze Prefs"
	#define kAnalyzeMark				@"Analyze Mark Frequencies"
	#define kAnalyzeSpace				@"Analyze Space Frequencies"
	#define kAnalyzeBaud				@"Analyze Baud Rate"
	#define kAnalyzeTone				@"Analyze Tone Select"
	#define kAnalyzeActive				@"Analyze Active"
	#define kAnalyzeOutputLevel			@"Analyze Output Sound Level"
	#define kAnalyzeOutputAttenuator	@"Analyze Output Attenuator"
	#define kAnalyzeSquelch				@"Analyze Squelch"
	#define kAnalyzeStopBits			@"Analyze Stop Bits"
	#define kAnalyzeTextColor			@"Analyze Text Color"
	#define kAnalyzeBackgroundColor		@"Analyze Background Color"
	#define kAnalyzePlotColor			@"Analyze Plot Color"
	#define kAnalyzeSentColor			@"Analyze Sent Color"
		
	//  simple RTTY
	#define kRTTYInputDevice			@"RTTY Input Device"
	#define kRTTYOutputDevice			@"RTTY Output Device"
	#define kRTTYMode					@"RTTY Mode"
	#define kRTTYFont					@"RTTY Font"
	#define kRTTYFontSize				@"RTTY Font Size"
	#define kRTTYTxFont					@"RTTY Tx Font"
	#define kRTTYTxFontSize				@"RTTY Tx Font Size"
	
	#define kRTTYTextColor				@"RTTY Text Color"
	#define kRTTYSentColor				@"RTTY Sent Color"
	#define kRTTYBackgroundColor		@"RTTY Background Color"
	#define kRTTYPlotColor				@"RTTY Plot Color"
	
	#define kRTTYMark					@"RTTY Mark Frequencies"
	#define kRTTYSpace					@"RTTY Space Frequencies"
	#define kRTTYBaud					@"RTTY Baud Rate"
	#define kRTTYTone					@"RTTY Tone Select"
	#define	kRTTYRxPolarity				@"RTTY Rx Polarity"
	#define	kRTTYTxPolarity				@"RTTY Tx Polarity"
	#define	kRTTYFSKSelection			@"RTTY FSK Selection"
	#define	kRTTYAuralMonitor			@"RTTY Aural Monitor"
	
	#define kRTTYPrefs					@"RTTY Prefs"
	#define kRTTYActive					@"RTTY Active"
	#define kRTTYOutputLevel			@"RTTY Output Sound Level"
	#define kRTTYOutputAttenuator		@"RTTY Output Attenuator"
	#define kRTTYSquelch				@"RTTY Squelch"
		
	#define kRTTYStopBits				@"RTTY Stop Bits"
	
	#define kRTTYMessages				@"RTTY Messages"
	#define kRTTYMessageTitles			@"RTTY MessageTitles"
	#define kRTTYOptMessages			@"RTTY Option Messages"
	#define kRTTYOptMessageTitles		@"RTTY Option MessageTitles"
	#define kRTTYShiftMessages			@"RTTY Shift Messages"
	#define kRTTYShiftMessageTitles		@"RTTY Shift MessageTitles"
	
	// dual RTTY
	#define	kDualRTTYMainControlWindow	@"DualRTTY Control Window A"
	#define	kDualRTTYSubControlWindow	@"DualRTTY Control Window B"
	#define kDualRTTYMainDevice			@"DualRTTY Input Device A"
	#define kDualRTTYSubDevice			@"DualRTTY Input Device B"
	#define kDualRTTYOutputDevice		@"DualRTTY Output Device"
	#define kDualRTTYMainMode			@"DualRTTY Mode A"
	#define kDualRTTYSubMode			@"DualRTTY Mode B"
	#define kDualRTTYFontA				@"DualRTTY Font A"
	#define kDualRTTYFontSizeA			@"DualRTTY Font Size A"
	#define kDualRTTYFontB				@"DualRTTY Font B"
	#define kDualRTTYFontSizeB			@"DualRTTY Font Size B"
	#define kDualRTTYTxFont				@"DualRTTY Tx Font"
	#define kDualRTTYTxFontSize			@"DualRTTY Tx Font Size"
	
	#define kDualRTTYTransmitChannel	@"DualRTTY TransmitChannel"
	#define kDualRTTYSpectrumRange		@"DualRTTY Spectrum Range"
	#define kDualRTTYSpectrumChannel	@"DualRTTY Spectrum Channel"
	#define kDualRTTYSpectrumDecay		@"DualRTTY Spectrum Decay"
	
	#define kDualRTTYMainTextColor		@"DualRTTY Text Color 1"
	#define kDualRTTYSubTextColor		@"DualRTTY Text Color 2"
	#define kDualRTTYMainSentColor		@"DualRTTY Sent Color 1"
	#define kDualRTTYSubSentColor		@"DualRTTY Sent Color 2"
	#define kDualRTTYMainBackgroundColor	@"DualRTTY Background Color 1"
	#define kDualRTTYSubBackgroundColor		@"DualRTTY Background Color 2"
	#define kDualRTTYMainPlotColor		@"DualRTTY Plot Color 1"
	#define kDualRTTYSubPlotColor		@"DualRTTY Plot Color 2"
	
	#define kDualRTTYMainMark			@"DualRTTY Main Mark Frequencies"
	#define kDualRTTYMainSpace			@"DualRTTY Main Space Frequencies"
	#define kDualRTTYMainBaud			@"DualRTTY Main Baud Rate"
	#define kDualRTTYMainTone			@"DualRTTY Main Tone Select"
	#define	kDualRTTYMainRxPolarity		@"DualRTTY Main Rx Polarity"
	#define	kDualRTTYMainTxPolarity		@"DualRTTY Main Tx Polarity"
	#define	kDualRTTYMainFSKSelection	@"DualRTTY Main FSK Selection"
	#define	kDualRTTYMainAuralMonitor	@"DualRTTY Main Aural Monitor"

	#define kDualRTTYMainActive			@"DualRTTY Active A"
	#define kDualRTTYMainSquelch		@"DualRTTY Squelch A"
	#define kDualRTTYMainStopBits		@"DualRTTY Stop Bits A"
	#define kDualRTTYMainPrefs			@"DualRTTY Prefs A"
	
	#define kDualRTTYSubMark			@"DualRTTY Sub Mark Frequencies"
	#define kDualRTTYSubSpace			@"DualRTTY Sub Space Frequencies"
	#define kDualRTTYSubBaud			@"DualRTTY Sub Baud Rate"
	#define kDualRTTYSubTone			@"DualRTTY Sub Tone Select"
	#define	kDualRTTYSubRxPolarity		@"DualRTTY Sub Rx Polarity"
	#define	kDualRTTYSubTxPolarity		@"DualRTTY Sub Tx Polarity"
	#define kDualRTTYSubActive			@"DualRTTY Active B"
	#define kDualRTTYSubSquelch			@"DualRTTY Squelch B"
	#define kDualRTTYSubStopBits		@"DualRTTY Stop Bits B"
	#define kDualRTTYSubPrefs			@"DualRTTY Prefs B"
	#define	kDualRTTYSubFSKSelection	@"DualRTTY Sub FSK Selection"
	#define	kDualRTTYSubAuralMonitor	@"DualRTTY Sub Aural Monitor"
	
	#define kDualRTTYOutputLevel		@"DualRTTY Output Sound Level"
	#define kDualRTTYOutputAttenuator	@"DualRTTY Output Attenuator"

	//  Wideband RTTY
	#define	kWFRTTYMainControlWindow	@"WFRTTY Control Window A"
	#define	kWFRTTYSubControlWindow		@"WFRTTY Control Window B"
	#define kWFRTTYMainDevice			@"WFRTTY Input Device A"
	#define kWFRTTYSubDevice			@"WFRTTY Input Device B"
	#define kWFRTTYOutputDevice			@"WFRTTY Output Device"
	#define kWFRTTYMainMode				@"WFRTTY Mode A"
	#define kWFRTTYSubMode				@"WFRTTY Mode B"
	#define kWFRTTYFontA				@"WFRTTY Font A"
	#define kWFRTTYFontSizeA			@"WFRTTY Font Size A"
	#define kWFRTTYFontB				@"WFRTTY Font B"
	#define kWFRTTYFontSizeB			@"WFRTTY Font Size B"
	#define kWFRTTYTxFont				@"WFRTTY Tx Font"
	#define kWFRTTYTxFontSize			@"WFRTTY Tx Font Size"
	
	#define kWFRTTYTransmitChannel		@"WFRTTY TransmitChannel"
	#define kWFRTTYMainOffset			@"WFRTTY Offset A"
	#define kWFRTTYSubOffset			@"WFRTTY Offset B"
	#define	kWFRTTYLockA				@"WFRTTY Transmit Lock A"
	#define	kWFRTTYLockB				@"WFRTTY Transmit Lock B"
	
	#define kWFRTTYMainTextColor		@"WFRTTY Text Color 1"
	#define kWFRTTYSubTextColor			@"WFRTTY Text Color 2"
	#define kWFRTTYMainSentColor		@"WFRTTY Sent Color 1"
	#define kWFRTTYSubSentColor			@"WFRTTY Sent Color 2"
	#define kWFRTTYMainBackgroundColor	@"WFRTTY Background Color 1"
	#define kWFRTTYSubBackgroundColor	@"WFRTTY Background Color 2"
	#define kWFRTTYMainPlotColor		@"WFRTTY Plot Color 1"
	#define kWFRTTYSubPlotColor			@"WFRTTY Plot Color 2"
	
	#define kWFRTTYMainMark				@"WFRTTY Main Mark Frequencies"
	#define kWFRTTYMainSpace			@"WFRTTY Main Space Frequencies"
	#define kWFRTTYMainBaud				@"WFRTTY Main Baud Rate"
	#define kWFRTTYMainTone				@"WFRTTY Main Tone Select"
	#define	kWFRTTYMainRxPolarity		@"WFRTTY Main Rx Polarity"
	#define	kWFRTTYMainTxPolarity		@"WFRTTY Main Tx Polarity"
	#define kWFRTTYMainActive			@"WFRTTY Active A"
	#define kWFRTTYMainSquelch			@"WFRTTY Squelch A"
	#define kWFRTTYMainStopBits			@"WFRTTY Stop Bits A"
	#define kWFRTTYMainPrefs			@"WFRTTY Prefs A"
	#define	kWFRTTYMainFSKSelection		@"WFRTTY FSK Selection A"
	#define	kWFRTTYMainAuralMonitor		@"WFRTTY Aural Monitor A"
	
	#define kWFRTTYSubMark				@"WFRTTY Sub Mark Frequencies"
	#define kWFRTTYSubSpace				@"WFRTTY Sub Space Frequencies"
	#define kWFRTTYSubBaud				@"WFRTTY Sub Baud Rate"
	#define kWFRTTYSubTone				@"WFRTTY Sub Tone Select"
	#define	kWFRTTYSubRxPolarity		@"WFRTTY Sub Rx Polarity"
	#define	kWFRTTYSubTxPolarity		@"WFRTTY Sub Tx Polarity"
	#define kWFRTTYSubActive			@"WFRTTY Active B"
	#define kWFRTTYSubSquelch			@"WFRTTY Squelch B"
	#define kWFRTTYSubStopBits			@"WFRTTY Stop Bits B"
	#define kWFRTTYSubPrefs				@"WFRTTY Prefs B"
	#define	kWFRTTYSubFSKSelection		@"WFRTTY FSK Selection B"
	#define	kWFRTTYSubAuralMonitor		@"WFRTTY Aural Monitor B"

	#define kWFRTTYOutputLevel			@"WFRTTY Output Sound Level"
	#define kWFRTTYOutputAttenuator		@"WFRTTY Output Attenuator"
	
	#define kRTTYMainWaterfallNR		@"RTTY Waterfall Noise Reduction A"
	#define kRTTYSubWaterfallNR			@"RTTY Waterfall Noise Reduction B"

	//  ASCII
	#define	kASCIIMainControlWindow		@"ASCII Control Window A"
	#define	kASCIISubControlWindow		@"ASCII Control Window B"
	#define kASCIIMainDevice			@"ASCII Input Device A"
	#define kASCIISubDevice				@"ASCII Input Device B"
	#define kASCIIOutputDevice			@"ASCII Output Device"
	#define kASCIIMainMode				@"ASCII Mode A"
	#define kASCIISubMode				@"ASCII Mode B"
	#define kASCIIFontA					@"ASCII Font A"
	#define kASCIIFontSizeA				@"ASCII Font Size A"
	#define kASCIIFontB					@"ASCII Font B"
	#define kASCIIFontSizeB				@"ASCII Font Size B"
	#define kASCIITxFont				@"ASCII Tx Font"
	#define kASCIITxFontSize			@"ASCII Tx Font Size"
	
	#define kASCIITransmitChannel		@"ASCII TransmitChannel"
	#define kASCIIMainOffset			@"ASCII Offset A"
	#define kASCIISubOffset				@"ASCII Offset B"
	#define	kASCIILockA					@"ASCII Transmit Lock A"
	#define	kASCIILockB					@"ASCII Transmit Lock B"
	
	#define kASCIIMainTextColor			@"ASCII Text Color 1"
	#define kASCIISubTextColor			@"ASCII Text Color 2"
	#define kASCIIMainSentColor			@"ASCII Sent Color 1"
	#define kASCIISubSentColor			@"ASCII Sent Color 2"
	#define kASCIIMainBackgroundColor	@"ASCII Background Color 1"
	#define kASCIISubBackgroundColor	@"ASCII Background Color 2"
	#define kASCIIMainPlotColor			@"ASCII Plot Color 1"
	#define kASCIISubPlotColor			@"ASCII Plot Color 2"
	
	#define kASCIIMainMark				@"ASCII Main Mark Frequencies"
	#define kASCIIMainSpace				@"ASCII Main Space Frequencies"
	#define kASCIIMainBaud				@"ASCII Main Baud Rate"
	#define kASCIIMainTone				@"ASCII Main Tone Select"
	#define	kASCIIMainRxPolarity		@"ASCII Main Rx Polarity"
	#define	kASCIIMainTxPolarity		@"ASCII Main Tx Polarity"
	#define kASCIIMainActive			@"ASCII Active A"
	#define kASCIIMainSquelch			@"ASCII Squelch A"
	#define kASCIIMainStopBits			@"ASCII Stop Bits A"
	#define kASCIIMainPrefs				@"ASCII Prefs A"
	#define	kASCIIMainFSKSelection		@"ASCII FSK Selection A"
	#define	kASCIIMainAuralMonitor		@"ASCII Aural Monitor A"
	
	#define kASCIISubMark				@"ASCII Sub Mark Frequencies"
	#define kASCIISubSpace				@"ASCII Sub Space Frequencies"
	#define kASCIISubBaud				@"ASCII Sub Baud Rate"
	#define kASCIISubTone				@"ASCII Sub Tone Select"
	#define	kASCIISubRxPolarity			@"ASCII Sub Rx Polarity"
	#define	kASCIISubTxPolarity			@"ASCII Sub Tx Polarity"
	#define kASCIISubActive				@"ASCII Active B"
	#define kASCIISubSquelch			@"ASCII Squelch B"
	#define kASCIISubStopBits			@"ASCII Stop Bits B"
	#define kASCIISubPrefs				@"ASCII Prefs B"
	#define	kASCIISubFSKSelection		@"ASCII FSK Selection B"
	#define	kASCIISubAuralMonitor		@"ASCII Aural Monitor B"

	#define kASCIIOutputLevel			@"ASCII Output Sound Level"
	#define kASCIIOutputAttenuator		@"ASCII Output Attenuator"

	#define kASCIIMainWaterfallNR		@"ASCII Waterfall Noise Reduction A"
	#define kASCIISubWaterfallNR		@"ASCII Waterfall Noise Reduction B"
	#define kASCIIBitsPerCharacter		@"ASCII BitsPerCharacter"


	//  wideband CW
	#define	kWBCWMainControlWindow		@"WBCW Control Window A"
	#define	kWBCWSubControlWindow		@"WBCW Control Window B"
	#define kWBCWMainDevice				@"WBCW Input Device A"
	#define kWBCWSubDevice				@"WBCW Input Device B"
	#define kWBCWOutputDevice			@"WBCW Output Device"
	#define kWBCWMainMode				@"WBCW Mode A"
	#define kWBCWSubMode				@"WBCW Mode B"
	#define kWBCWFontA					@"WBCW Font A"
	#define kWBCWFontSizeA				@"WBCW Font Size A"
	#define kWBCWFontB					@"WBCW Font B"
	#define kWBCWFontSizeB				@"WBCW Font Size B"
	#define kWBCWTxFont					@"WBCW Tx Font"
	#define kWBCWTxFontSize				@"WBCW Tx Font Size"
	
	#define kWBCWMonitorActive			@"WBCW Monitor Active"
	#define kWBCWMonitorDevice			@"WBCW Monitor Device"
	#define kWBCWMonitorLevel			@"WBCW Monitor Sound Level"
	#define kWBCWMonitorAttenuator		@"WBCW Monitor Attenuator"
	#define kWBCWMainBandwidth			@"WBCW Main Bandwidth"
	#define kWBCWMainPitch				@"WBCW Main Pitch"
	#define kWBCWMainMonitor			@"WBCW Main Monitor"
	#define kWBCWMainChannels			@"WBCW Main Channels"
	#define kWBCWSubBandwidth			@"WBCW Sub Bandwidth"
	#define kWBCWSubPitch				@"WBCW Sub Pitch"
	#define kWBCWTransmitPitch			@"WBCW Transmit Pitch"
	#define kWBCWTransmitSidetone		@"WBCW Transmit Sidetone Enable"
	#define kWBCWSubMonitor				@"WBCW Sub Monitor"
	#define kWBCWSubChannels			@"WBCW Sub Channels"
	#define kWBCWTransmitChannels		@"WBCW Transmit Channels"
	#define	kWBCWPanoSeparation			@"WBCW Pano Separation"
	#define	kWBCWPanoBalance			@"WBCW Pano Balance"
	#define	kWBCWPanoReverse			@"WBCW Pano Reverse"
	#define	kWBCWSpeed					@"WBCW Speed"
	#define	kWBCWRisetime				@"WBCW Risetime"
	#define	kWBCWWeight					@"WBCW Weight"
	#define	kWBCWRatio					@"WBCW Ratio"
	#define	kWBCWFarnsworth				@"WBCW Farnsworth"
	#define	kWBCWSidetone				@"WBCW Sidetone"
	#define	kWBCWPTTLeadIn				@"WBCW PTT Lead in"
	#define	kWBCWPTTRelease				@"WBCW PTT Release"
	#define	kWBCWPTTRelease				@"WBCW PTT Release"
	#define	kWBCWTxSidetoneLevel		@"WBCW Tx Sidetone Level"
	#define	kWBCWMainSidetoneLevel		@"WBCW Main Sidetone Level"
	#define	kWBCWSubSidetoneLevel		@"WBCW Sub Sidetone Level"
	#define	kWBCWModulation				@"WBCW Modulation"

	#define kWBCWTransmitChannel		@"WBCW TransmitChannel"
	#define kWBCWMainOffset				@"WBCW Offset A"
	#define kWBCWSubOffset				@"WBCW Offset B"
	#define	kWBCWBreakin				@"WBCW Breakin"
	
	#define kWBCWMainTextColor			@"WBCW Text Color 1"
	#define kWBCWSubTextColor			@"WBCW Text Color 2"
	#define kWBCWMainSentColor			@"WBCW Sent Color 1"
	#define kWBCWSubSentColor			@"WBCW Sent Color 2"
	#define kWBCWMainBackgroundColor	@"WBCW Background Color 1"
	#define kWBCWSubBackgroundColor		@"WBCW Background Color 2"
	#define kWBCWMainPlotColor			@"WBCW Plot Color 1"
	#define kWBCWSubPlotColor			@"WBCW Plot Color 2"
	
	#define kWBCWMainActive				@"WBCW Active A"
	#define kWBCWMainSquelch			@"WBCW Squelch A"
	#define kWBCWMainPrefs				@"WBCW Prefs A"
	
	#define kWBCWSubActive				@"WBCW Active B"
	#define kWBCWSubSquelch				@"WBCW Squelch B"
	#define kWBCWSubPrefs				@"WBCW Prefs B"

	#define kWBCWOutputLevel			@"WBCW Output Sound Level"
	#define kWBCWOutputAttenuator		@"WBCW Output Attenuator"
	
	#define kWBCWMessages				@"WBCW Messages"
	#define kWBCWMessageTitles			@"WBCW MessageTitles"
	#define kWBCWOptMessages			@"WBCW Option Messages"
	#define kWBCWOptMessageTitles		@"WBCW Option MessageTitles"
	#define kWBCWShiftMessages			@"WBCW Shift Messages"
	#define kWBCWShiftMessageTitles		@"WBCW Shift MessageTitles"

	#define kWBCWMainWaterfallNR		@"WBCW Waterfall Noise Reduction A"
	#define kWBCWSubWaterfallNR			@"WBCW Waterfall Noise Reduction B"
	
	//  SITOR-B
	#define	kSitorMainControlWindow		@"SITOR-B Control Window A"
	#define	kSitorSubControlWindow		@"SITOR-B Control Window B"
	#define kSitorMainDevice			@"SITOR-B Input Device A"
	#define kSitorSubDevice				@"SITOR-B Input Device B"
	#define kSitorMainMode				@"SITOR-B Mode A"
	#define kSitorSubMode				@"SITOR-B Mode B"
	#define kSitorFontA					@"SITOR-B Font A"
	#define kSitorFontSizeA				@"SITOR-B Font Size A"
	#define kSitorFontB					@"SITOR-B Font B"
	#define kSitorFontSizeB				@"SITOR-B Font Size B"
	
	#define kSitorMainOffset			@"SITOR-B Offset A"
	#define kSitorSubOffset				@"SITOR-B Offset B"
	
	#define kSitorMainTextColor			@"SITOR-B Text Color 1"
	#define kSitorSubTextColor			@"SITOR-B Text Color 2"
	#define kSitorMainBackgroundColor	@"SITOR-B Background Color 1"
	#define kSitorSubBackgroundColor	@"SITOR-B Background Color 2"
	#define kSitorMainPlotColor			@"SITOR-B Plot Color 1"
	#define kSitorSubPlotColor			@"SITOR-B Plot Color 2"
	
	#define kSitorMainMark				@"SITOR-B Main Mark Frequencies"
	#define kSitorMainSpace				@"SITOR-B Main Space Frequencies"
	#define kSitorMainBaud				@"SITOR-B Main Baud Rate"
	#define kSitorMainTone				@"SITOR-B Main Tone Select"
	#define	kSitorMainRxPolarity		@"SITOR-B Main Rx Polarity"
	#define kSitorMainActive			@"SITOR-B Active A"
	#define kSitorMainSquelch			@"SITOR-B Squelch A"
	#define kSitorMainStopBits			@"SITOR-B Stop Bits A"
	#define kSitorMainPrefs				@"SITOR-B Prefs A"
	
	#define kSitorSubMark				@"SITOR-B Sub Mark Frequencies"
	#define kSitorSubSpace				@"SITOR-B Sub Space Frequencies"
	#define kSitorSubBaud				@"SITOR-B Sub Baud Rate"
	#define kSitorSubTone				@"SITOR-B Sub Tone Select"
	#define	kSitorSubRxPolarity			@"SITOR-B Sub Rx Polarity"
	#define kSitorSubActive				@"SITOR-B Active B"
	#define kSitorSubSquelch			@"SITOR-B Squelch B"
	#define kSitorSubStopBits			@"SITOR-B Stop Bits B"
	#define kSitorSubPrefs				@"SITOR-B Prefs B"

	//  common to all modes
	#define kAutoConnect				@"Device AutoConnect"
	#define	kUseNetAudio				@"NetAudio"						//  no longer used
	#define kFastPlayback				@"Fast file playback"
	#define kToolTips					@"Show ToolTips"
	#define kSlashZeros					@"Null for Zero"
	#define	kNetInputServices			@"NetAudio Input Services"		// v0.47
	#define	kNetInputAddresses			@"NetAudio Input IP"			// v0.47
	#define	kNetInputPorts				@"NetAudio Input Ports"			// v0.47
	#define	kNetInputPasswords			@"NetAudio Input Passwords"		// v0.47
	#define	kNetOutputServices			@"NetAudio Output Services"		// v0.47
	#define	kNetOutputPorts				@"NetAudio Output Ports"		// v0.47
	#define	kNetOutputPasswords			@"NetAudio Output Passwords"	// v0.47
	
	//  MacroScripts
	#define kMacroScripts				@"MacroScripts"
	
	//  userInfo
	#define kInfoName					@"Name"
	#define kInfoCall					@"Callsign"
	#define kInfoState					@"State"
	#define kInfoGridSquare				@"Grid Square"
	#define kInfoYearLic				@"Year Licensed"
	#define kInfoSection				@"ARRL Section"
	#define kInfoZone					@"CQ Zone"
	#define kInfoITU					@"ITU Zone"
	#define kInfoCountry				@"Country"
	
	#define kBragTape					@"Brag Tape"
	
	//  contestInfo
	#define kContestFontName			@"Contest Font"
	#define kContestFontSize			@"Contest Font Size"
	#define	kRecentContest				@"Recent Contest"
	#define kContestRepeat				@"Repeat Pause"
	#define	kContestRepeatMenu			@"Repeat Menu"
	#define kTempFolder					@"Temporary Folder"
	#define	kContestAllowDupe			@"Allow Contest Dupe"
	
	//  contest log
	#define kContestLogPosition			@"ContestLogPosition"
	#define kContestLogOrder			@"ContestLogOrder"
	#define kContestLogSize				@"ContestLogSize"
	#define kContestLogExtension		@"ContestLogExtension"
	
	//  Cabrillo info
	#define	kCabrilloCategory			@"Cabrillo Category"
	#define	kCabrilloBand				@"Cabrillo Band"
	#define kCabrilloNameUsed			@"Cabrillo Name Used"
	#define kCabrilloCallUsed			@"Cabrillo Call Used"
	#define kCabrilloOperators			@"Cabrillo Operators"
	#define kCabrilloClub				@"Cabrillo Club"
	#define kCabrilloName				@"Cabrillo Name"
	#define kCabrilloAddr1				@"Cabrillo Addr1"
	#define kCabrilloAddr2				@"Cabrillo Addr2"
	#define kCabrilloAddr3				@"Cabrillo Addr3"
	#define kCabrilloMail				@"Cabrillo Mail"
	#define kCabrilloSoapbox			@"Cabrillo Soapbox"
	
	//  QSO panel
	#define kQSOInterface				@"QSO Interface"
	#define kQSOScript					@"QSO Log script"
	
	//  UserPTT
	#define	kUserPTTFolder				@"User PTT Folder"
	#define	kMicroKeyerSetup1			@"microKeyer setup string"					// v0.51
	#define	kMicroKeyerSetup2			@"microKeyer setup string v2"				// v0.51
	#define	kMicroKeyerSetup3			@"microKeyer setup string v3"				// v0.68
	#define	kMicroKeyerMode				@"microKeyer digital mode in FSK only"		// v0.68
	#define	kMicroKeyerQuitScript		@"microKeyer Quit script"					// v0.66
	#define	kMicroKeyerInvert			@"microKeyer FSK invert"
	
	//  PTT -- no longer used
	#define	kUseCocoaPTT				@"PTT using cocoaPTT"
	#define kUseMLDXPTT					@"PTT using MLDX"
	#define kKeyScript					@"PTT Key script"
	#define kUnkeyScript				@"PTT Unkey script"
	
	//  macro import and exports
	#define kMessages					@"Messages"
	#define kMessageTitles				@"MessageTitles"	
	
	//  speech voices
	#define	kMainReceiverVoice			@"Voice - Main Receiver"					//  v0.96d
	#define	kSubReceiverVoice			@"Voice - Sub Receiver"						//  v0.96d
	#define	kTransmitterVoice			@"Voice - Transmitter"						//  v0.96d
	#define	kSpeechAssistVoice			@"Voice - Speech Assist"					//  v1.02d

	#define	kMainReceiverVoiceEnable	@"Voice Enable - Main Receiver"				//  v0.96d
	#define	kSubReceiverVoiceEnable		@"Voice Enable - Sub Receiver"				//  v0.96d
	#define	kTransmitterVoiceEnable		@"Voice Enable - Transmitter"				//  v0.96d

	#define	kMainReceiverVoiceVerbatim	@"Voice Verbatim - Main Receiver"			//  v0.96d
	#define	kSubReceiverVoiceVerbatim	@"Voice Verbatim - Sub Receiver"			//  v0.96d
	#define	kTransmitterVoiceVerbatim	@"Voice Verbatim - Transmitter"				//  v0.96d

	// defaults
	#define kPlistDirectory "~/Library/Preferences/"
	#define kDefaultPlist   "w7ay.cocoaModem 2.0.plist"

#endif
