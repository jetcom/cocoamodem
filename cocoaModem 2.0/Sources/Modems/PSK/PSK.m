//
//  PSK.m
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
	#include "Copyright.h"
//

#import "PSK.h"
#import "AppDelegate.h"
#import "Application.h"
#import "AYTextView.h"
#import "cocoaModemParams.h"
#import "Messages.h"
#import "Config.h"
#import "Contest.h"					// for PSKMODE
#import "ContestBar.h"
#import "ExchangeView.h"
#import "ModemDistributionBox.h"
#import "ModemManager.h"
#import "ModemSource.h"
#import "modemTypes.h"
#import "Module.h"
#import "Plist.h"
#import "PSKAuralMonitor.h"
#import "PSKConfig.h"
#import "PSKContestTxControl.h"
#import "PSKControl.h"
#import "PSKMacros.h"
#import "PSKReceiver.h"
#import "PSKTransmitControl.h"
#import "StdManager.h"
#import "SubDictionary.h"
#import "TextEncoding.h"
#import "Transceiver.h"
#import "VUMeter.h"
#import "Waterfall.h"

//	PSK Aural Monitor keys
#define	kAuralMonitor0				@"PSK Aural Monitor for xcvr 0"
#define	kAuralMonitor1				@"PSK Aural Monitor for xcvr 1"
#define	kAuralTransmitter			@"PSK Aural Monitor for transmit"
#define	kAuralWideband				@"PSK Aural Monitor for wideband"
#define	kMasterVolume				@"PSK Aural Master Volume"
#define	kMasterMute					@"PSK Aural Master Mute"

//	Individual aural channels (kAuralMonitor0, transmitter, etc)
#define	kMonitorEnable				@"Enable"
#define	kMonitorAttenuator			@"Attenuator"
#define	kMonitorFixSelect			@"Fix Selection"
#define	kMonitorFrequency			@"Fix Frequency"

@implementation PSK

//  PSK : ContestInterface : MacroPanel : Modem : NSObject

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	[ mgr showSplash:@"Creating PSK Modem" ] ;
			
	self = [ super initIntoTabView:tabview nib:@"PSK" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		transceivers = 2 ;		
		//  v0.78
		pskAuralMonitor = [ [ PSKAuralMonitor alloc ] init ] ;
		//	v0.95
		unmarkedTextLength = 0 ;
		insertionRange = NSMakeRange( 0, 0 ) ;
	}
	return self ;
}

- (void)setJisToUnicodeTable:(unsigned char*)uarray
{
}

//	v0.70  JIS/Unicode tables are created by the Application.m
- (void)setUnicodeToJisTable:(unsigned char*)uarray
{
}

//  v0.71
- (void)setAllowShiftJIS:(Boolean)state
{
	[ manager setAllowShiftJISForPSK:state ] ;
}

//  v0.87
- (void)switchModemIn
{
	if ( config ) [ config setKeyerMode ] ;
}

- (int)transmissionMode
{
	return PSKMODE ;
}

- (int)currentPSKMode
{
	PSKControl *rx ;
	
	rx = ( selectedTransceiver == 0 ) ? rx1Control : rx2Control ;
	return [ rx pskMode ] ;
}

- (PSKAuralMonitor*)auralMonitor
{
	return pskAuralMonitor ;
}

- (void)awakeFromNib
{
	AuralAction *a ;
	int i ;
	
	ident = NSLocalizedString( @"PSK", nil ) ;
	
	//	v0.78  moved here
	//	v0.70  JIS/Unicode tables are created by the Application.m
	memcpy( jisToUnicode, [ [ self application ] jisToUnicodeTable ], 65536*2 ) ;
	memcpy( unicodeToJis, [ [ self application ] unicodeToJisTable ], 65536*2 ) ;

	[ modemTabItem setLabel:ident ] ;

	[ (PSKConfig*)config awakeFromModem:self ] ;
	ptt = [ config pttObject ] ;
	
	[ self awakeFromContest ] ;
	[ self initCallsign ] ;	
	[ self initColors ] ;
	[ self initMacros ] ;
	
	//  actions
	[ self setInterface:transmitButton to:@selector(transmitButtonChanged) ] ;	
	[ self setInterface:squelch to:@selector(squelchChanged) ] ;	
	[ self setInterface:inputAttenuator to:@selector(inputAttenuatorChanged) ] ;
	//	aural monitor actions
	[ self setInterface:masterLevel to:@selector(masterLevelChanged) ] ;	
	[ self setInterface:masterMute to:@selector(masterMuteChanged) ] ;
	
	//  rx0
	a = &auralAction[0] ;
	a->enableButton = auralRxEnable0 ;
	a->attenuationField = auralAttenuatorField0 ;
	a->floatMatrix = auralFloatMatrix0 ;
	a->fixedFrequency = auralFixedFrequency0 ;
	//  rx1
	a = &auralAction[1] ;
	a->enableButton = auralRxEnable1 ;
	a->attenuationField = auralAttenuatorField1 ;
	a->floatMatrix = auralFloatMatrix1 ;
	a->fixedFrequency = auralFixedFrequency1 ;
	//  tx
	a = &auralAction[2] ;
	a->enableButton = auralTxEnable ;
	a->attenuationField = auralTxAttenuatorField ;
	a->floatMatrix = auralTxFloatMatrix ;
	a->fixedFrequency = auralTxFixedFrequency ;
	//  wideband
	a = &auralAction[3] ;
	a->enableButton = auralWideEnable ;
	a->attenuationField = auralWideAttenuatorField ;
	a->floatMatrix = nil ;
	a->fixedFrequency = nil ;

	//  rx, tx and wide actions
	for ( i = 0; i < 4; i++ ) {
		a = &auralAction[i] ;
		[ self setInterface:a->enableButton to:@selector(enableChanged:) ] ;	
		[ self setInterface:a->attenuationField to:@selector(attenuatorChanged:) ] ;
	}
	//  rx and tx actions
	for ( i = 0; i < 3; i++ ) {
		a = &auralAction[i] ;
		[ self setInterface:a->floatMatrix to:@selector(floatMatrixChanged:) ] ;	
		[ self setInterface:a->fixedFrequency to:@selector(fixedFrequencyChanged:) ] ;
	}
	
	//  use QSO transmitview
	[ contestTab selectTabViewItemAtIndex:0 ] ;

	receiveFrame = [ rx2Group frame ] ;
	transceiveFrame = [ rx1Group frame ] ;

	[ waterfall awakeFromModem ] ;
	[ waterfall enableIndicator:self ] ;
	[ waterfall setFFTDelegate:self ] ;
	//  prefs
	charactersSinceTimerStarted = 0 ;
	timeout = nil ;
	transmitBufferCheck = nil ;
	thread = [ NSThread currentThread ] ;
	frequencyDefined = NO ;
	
	// pskMode = kBPSK31 ;	 changed to dynamic query v0.47
	
	//  transmit view 
	indexOfUntransmittedText = 0 ;
	hardLimitForBackspace = 0 ;					// v0.66
	transmitState = sentColor = NO ;
	transmitCount = 0 ;
	transmitCountLock = [ [ NSLock alloc ] init ] ;
	transmitViewLock = [ [ NSLock alloc ] init ] ;
	transmitTextAttribute = [ transmitView newAttribute ] ;
	selectedTransceiver = 0 ;
	[ transmitView setDelegate:self ] ;
	
	//  receive view
	if ( receiveView ) /* not actually used */ receiveTextAttribute = [ receiveView newAttribute ] ;
	
	if ( receive1View ) {
		receive1TextAttribute = [ receive1View newAttribute ] ;
		[ receive1View setDelegate:self ] ;		//  delegate for callsign clicks
	}
	if ( receive2View ) {
		receive2TextAttribute = [ receive2View newAttribute ] ;
		[ receive2View setDelegate:self ] ;		//  delegate for callsign clicks
	}
	
	//  default receive view
	activeReceiveView = receive1View ;
	activeReceiveTextAttribute = receive1TextAttribute ;
	
	//  create the two receivers
	if ( rx1View ) {
		rx1 = [ [ PSKReceiver alloc ] initIntoView:rx1View client:self index:0 ] ;
		rx1Control = [ [ PSKControl alloc ] initIntoView:rx1ControlView client:self index:0 ] ;
		[ rx1Control setPSKReceiver:rx1 ] ;
		[ rx1 setExchangeView:receive1View ] ;
		[ rx1 setPSKControl:rx1Control ] ;
		[ rx1 setTransmitLightState:TxReady ] ;	
		[ rx1 registerModule:[ transceiver1 receiver ] ] ;
		[ rx1 setJisToUnicodeTable:jisToUnicode ] ;										//  v0.95 moved here, copy to xcvr1
		[ rx1 setUnicodeToJisTable:unicodeToJis ] ;										//  v0.95 moved here, copy to xcvr1
		transmitModule[0] = [ transceiver1 transmitter ] ;
	}
	if ( rx2View ) {
		rx2 = [ [ PSKReceiver alloc ] initIntoView:rx2View client:self index:1 ] ;
		rx2Control = [ [ PSKControl alloc ] initIntoView:rx2ControlView client:self index:1 ] ;
		[ rx2Control setPSKReceiver:rx2 ] ;
		[ rx2 setExchangeView:receive2View ] ;
		[ rx2 setPSKControl:rx2Control ] ;
		[ rx2 setTransmitLightState:TxOff ] ;		
		[ rx2 registerModule:[ transceiver2 receiver ] ] ;	
		transmitModule[1] = [ transceiver2 transmitter ] ;
	}
	txControl = [ [ PSKTransmitControl alloc ] initIntoView:txControlView client:self ] ;
	contestTxControl = [ [ PSKContestTxControl alloc ] initIntoView:contestTxControlView client:self ] ;
	
	[ vuMeter setup ] ;
}

- (void)initMacros
{
	int i ;
	Application *application ;
	
	currentSheet = check = 0 ;
	application = [ manager appObject ] ;
	for ( i = 0; i < 3; i++ ) {
		macroSheet[i] = [ [ PSKMacros alloc ] initSheet ] ;
		[ macroSheet[i] setUserInfo:[ application userInfoObject ] qso:[ (StdManager*)manager qsoObject ] modem:self canImport:YES ] ;
	}
}

//	v1.02b
- (void)directSetFrequency:(float)freq
{
	[ rx1 setAndDisplayRxTone:freq ] ;
	[ rx1 setAndDisplayTxTone:freq ] ;
}

//	v1.02b
- (float)selectedFrequency
{
	return [ rx1 rxTone ] ;
}

- (PSKConfig*)configObj
{
	return config ;
}

- (void)updateSourceFromConfigInfo
{
	[ manager showSplash:@"Updating PSK sound source" ] ;
	//  send data back here from config where it all starts
	//	from here it goes to the two receivers and the waterfall
	[ (PSKConfig*)config setClient:self ] ;	
	//  set up squelch
	if ( squelch ) {
		[ squelch setFloatValue:0.6 ] ;
	}
	//  turn on if it is on in Plist
	[ config checkActive ] ;
}

- (CMPipe*)dataClient
{
	return self ;
}

//  v0.78 PSKAuralMonitor
- (IBAction)openAuralPanel:(id)sender
{
	[ auralPanel makeKeyAndOrderFront:self ] ;
}

- (void)masterLevelChanged
{
	if ( pskAuralMonitor == nil ) return ;	
	[ pskAuralMonitor setMasterGain:[ masterLevel floatValue ] ] ;
}

- (void)masterMuteChanged
{
	if ( pskAuralMonitor ) [ pskAuralMonitor setMute:( [ masterMute state ] == NSOnState ) ] ;
}

- (void)enableChanged:(id)sender
{
	int i ;
	
	if ( pskAuralMonitor == nil ) return ;

	for ( i = 0; i < 4; i++ ) {
		if ( auralAction[i].enableButton == sender ) {
			[ pskAuralMonitor setEnable:( [ sender state ] == NSOnState ) channel:i ] ;
			return ;
		}
	}
}

- (void)attenuatorChanged:(id)sender
{
	int i ;
	
	if ( pskAuralMonitor == nil ) return ;

	for ( i = 0; i < 4; i++ ) {
		if ( auralAction[i].attenuationField == sender ) {
			[ pskAuralMonitor setAttenuation:[ sender floatValue ] channel:i ] ;
			return ;
		}
	}
}

- (void)floatMatrixChanged:(id)sender
{
	int i, n ;
	
	if ( pskAuralMonitor == nil ) return ;

	for ( i = 0; i < 3; i++ ) {
		if ( auralAction[i].floatMatrix == sender ) {
			n = [ sender selectedRow ] ;
			[ pskAuralMonitor setFloating:( n == 0 ) forChannel:i ] ;
			return ;
		}
	}
}

- (void)fixedFrequencyChanged:(id)sender
{
	int i ;
	
	if ( pskAuralMonitor == nil ) return ;

	for ( i = 0; i < 4; i++ ) {
		if ( auralAction[i].fixedFrequency == sender ) {
			[ pskAuralMonitor setFixedFrequency:[ sender floatValue ] forChannel:i ] ;
			return ;
		}
	}
}

//	Callback from a PSKReceiver when the mode (PSK31/63/125) changes or PSK center frequency changes
//	NOTE: "mode" is the decimation factor in the PSKReceiver, and determins the PSK mode
- (void)setReceiveFrequency:(float)freq mode:(int)mode forReceiver:(int)receiver
{
	float bw ;
	
	switch ( mode ) {
	case 32:
	default:
		bw = 15 ;
		break ;
	case 64:
		bw = 30 ;
		break ;
	case 128:
		bw = 60 ;
		break ;
	}
	if ( receiver == 0 || receiver == 1 ) {
		[ pskAuralMonitor setCenterFrequency:freq bandwidth:bw channel:receiver ] ;
		[ [ [ NSApp delegate ] application ] setDirectFrequencyFieldTo:freq ] ;
	}
}

//	Audio Data arrves here and sent to the tweo receivers (and waterfall and VUMeter)
- (void)importData:(CMPipe*)pipe
{
	if ( ![ manager modemIsVisible:self ] ) return ;
	
	if ( rx1 ) [ rx1 importData:pipe ] ;
	if ( rx2 ) [ rx2 importData:pipe ] ;
	
	if ( pskAuralMonitor != nil ) [ pskAuralMonitor importWidebandData:pipe ] ;

	if ( waterfall ) [ waterfall importData:pipe ] ;
	if ( vuMeter ) [ vuMeter importData:pipe ] ;
}

- (Boolean)shouldEndTransmission
{
	//  first decrement transmit count
	[ self decrementTransmitCount ] ;
	return ( transmitCount <= 0 ) ;
}

//	v0.70 Shift-JIS double byte support
//  echo callback from APSK generator
- (void)transmittedCharacter:(int)c
{
	char buffer[2] ;
	unichar uch ;
	Boolean isShiftJISCharacter ;
	
	[ self setSentColor:YES view:activeReceiveView textAttribute:activeReceiveTextAttribute ] ;

	if ( c <= 26 ) {
		//  control character in stream
		switch ( c + 'a' - 1 ) {
		case 'z':
			//  end of macro transmitCount balance
			[ transmitCountLock lock ] ;
			if ( transmitCount > 0 ) transmitCount-- ;
			[ transmitCountLock unlock ] ;
			return ;
		default:
			//  for carriage return, newline, etc
			break ;
		}
	}
	
	Boolean useShiftJIS = NO ;
	int vfo = [ txControl selectedTransceiver ] ;
	if ( vfo == 0 ) useShiftJIS = [ rx1 useShiftJIS ] ;
	
	if ( c >= 0x100 && useShiftJIS ) {
		//  validate that it is Shift-JIS
		isShiftJISCharacter = YES ;
		if ( !( c >= 0x8100 && c <= 0x84ff ) ) {
			if ( !( c >= 0x8700 && c <= 0x9fff ) ) {
				if ( !( c >= 0xe000 && c <= 0xeaff ) ) {
					if ( !( c >= 0xed00 && c <= 0xeeff ) ) isShiftJISCharacter = NO ;
				}
			}
		}
		if ( isShiftJISCharacter == YES ) {
			//  Got double byte character that is in Shift-JIS range, convert it to Unicode
			//	Ignore if outside Shift-JIS range
			uch = jisToUnicode[c*2]*256 + jisToUnicode[c*2 + 1 ] ;
			
			printf( "transmitted 0x%x => uch %d\n", c, uch ) ;
			
			//  send character
			[ activeReceiveView appendUnicode:uch ] ;
			[ transmitModule[selectedTransceiver] insertBuffer:uch ] ;
			[ transmitView select ] ;
		}
		return ;
	}

	//  not in Shift-JIS mode
	if ( c > 256 ) c = '.' ;			//  sanity check
	if ( c == '0' && slashZero ) c = Phi ;

	//  send character
	buffer[0] = c ;
	buffer[1] = 0 ;
	[ activeReceiveView append:buffer ] ;
	[ transmitModule[selectedTransceiver] insertBuffer:c ] ;
	[ transmitView select ] ;
}

//  selected transceiver from normal or contest interface
- (int)selectedReceiver
{
	PSKTransmitControl *control ;
	
	control = ( inContestMode ) ? contestTxControl : txControl ;
	selectedTransceiver = [ control selectedTransceiver ] ;
	return selectedTransceiver ;
}

//  check if selected receiver is on
- (Boolean)checkTx
{
	int xcvr ;
	Boolean isEnabled ;
	
	xcvr = [ self selectedReceiver ] ;
	isEnabled = ( ( xcvr == 0 ) ? [ rx1 isEnabled ] : [ rx2 isEnabled ] ) ;

	return isEnabled ;
}

- (void)transceiverChanged
{
	int xcvr ;
	NSBox *receiveBox, *transceiveBox ;
	
	xcvr = [ self selectedReceiver ] ;
	if ( xcvr == 0 ) {
		//  receiverA = transceive
		[ rx2 setTransmitLightState:TxOff ] ;
		[ rx1 setTransmitLightState:TxReady ] ;
		transceiveBox = rx1Group ;
		receiveBox = rx2Group ;
	}
	else {
		//  receiverB = transceive
		[ rx1 setTransmitLightState:TxOff ] ;
		[ rx2 setTransmitLightState:TxReady ] ;
		transceiveBox = rx2Group ;
		receiveBox = rx1Group ;
	}
	[ transceiveBox setFrame:transceiveFrame ] ;
	[ receiveBox setFrame:receiveFrame ] ;
	[ rx1Group setNeedsDisplay:YES ] ;
	[ rx2Group setNeedsDisplay:YES ] ;
}

- (float)transmitFrequency
{
	int xcvr ;
	float freq ;

	xcvr = [ self selectedReceiver ] ;
	freq = ( ( xcvr == 0 ) ? [ rx1 currentTransmitFrequency ] : [ rx2 currentTransmitFrequency ] ) ;
	return freq ;
}

//  waterfall clicked
//  Note: for USB left edge is always 400 Hz no matter what the VFO offset is
- (void)clicked:(float)freq secondsAgo:(float)secs option:(Boolean)option fromWaterfall:(Boolean)fromWaterfall waterfallID:(int)index
{
	frequencyDefined = YES ;
	
	//  check if already in transmit mode, if so, don't change frequency
	if ( transmitState == NO ) {
		if ( !option ) {
			[ rx1 enableReceiver:YES ] ;
			[ rx1 selectFrequency:freq  secondsAgo:secs fromWaterfall:fromWaterfall ] ;
			[ receive1View scrollToEnd ] ;
		}
		else {
			[ rx2 enableReceiver:YES ] ;
			[ rx2 selectFrequency:freq  secondsAgo:secs fromWaterfall:fromWaterfall  ] ;
			[ receive2View scrollToEnd ] ;
		}
	}
}

//  turn off one of the receivers
- (void)turnOffReceiver:(int)ident option:(Boolean)option
{
	if ( pskAuralMonitor != nil ) [ pskAuralMonitor disactivateChannel:( option == YES ) ? 1 : 0 ] ;	//  v0.78
	if ( !option ) [ rx1 enableReceiver:NO ] ; else [ rx2 enableReceiver:NO ] ;
}

//  receive frequency set not by clicking, but by direct entry
- (void)receiveFrequency:(float)freq setBy:(int)receiver
{
	[ self frequencyUpdatedTo:freq receiver:receiver ] ;
	[ self clicked:freq secondsAgo:0.0 option:( receiver != 0 ) fromWaterfall:NO waterfallID:0 ] ;
}

- (void)setTimeOffset:(float)timeOffset index:(int)index 
{
	if ( transmitState == NO ) {
		if ( index == 0 ) [ rx1 setTimeOffset:timeOffset ] ; else [ rx2 setTimeOffset:timeOffset ] ; 
	}
}

//  frequency update from PSKReceiver
- (void)frequencyUpdatedTo:(float)tone receiver:(int)uniqueID
{
	[ waterfall forceToneTo:tone receiver:uniqueID ] ;
}

- (void)setAFCState:(Boolean)state
{
	if ( rx1Control ) [ rx1Control setAFCState:state ] ;
	if ( rx2Control ) [ rx2Control setAFCState:state ] ;
}

- (void)useControlButton:(Boolean)state
{
	[ waterfall useControlButton:state ] ;
	if ( rx1 ) [ rx1 useControlButton:state ] ;
	if ( rx2 ) [ rx2 useControlButton:state ] ;
}

- (void)setVisibleState:(Boolean)visible
{
	if ( pskAuralMonitor ) [ pskAuralMonitor setModemActive:visible ] ;
	if ( rx1 ) [ rx1 updateVisibleState:visible ] ;
	if ( rx2 ) [ rx2 updateVisibleState:visible ] ;
	if ( config ) [ config updateVisibleState:visible ] ;
}

- (PSKReceiver*)receiver:(int)index
{
	if ( index == 1 ) return rx2 ;
	return rx1 ;
}

- (void)setWaterfallOffset:(float)freq sideband:(int)sideband
{
	float offset ;
	
	offset = fabs( freq ) ;
	if ( rx1 ) [ rx1 setVFOOffset:offset sideband:sideband ] ;
	if ( rx2 ) [ rx2 setVFOOffset:offset sideband:sideband ] ;
	
	[ waterfall setOffset:freq sideband:sideband ] ;
}


//	v0.78
//  (Private API)
- (void)setupAuralMonitorDefaultPreferences:(Preferences*)pref
{
	int i ;
	SubDictionary *p ;
	
	[ pref setInt:1 forKey:kMasterMute ] ;
	[ pref setFloat:0.5 forKey:kMasterVolume ] ;

	//  create sub dictionaries to hold PSK Aural Monitor parameters for the two receivers, transmitter and wideband
	for ( i = 0; i < 4; i++ ) {
		auralMonitorPlist[i] = [ [ SubDictionary alloc ] init ] ;
	}
	
	//  initially disable all channels
	for ( i = 0; i < 4; i++ ) [ auralMonitorPlist[i] setInt:0 forKey:kMonitorEnable ] ;
	
	for ( i = 0; i < 2; i++ ) {
		//  receiver defaults
		p = auralMonitorPlist[i] ;
		[ p setFloat:0.0 forKey:kMonitorAttenuator ] ;
		[ p setInt:0 forKey:kMonitorFixSelect ] ;
		[ p setFloat:1760.0 forKey:kMonitorFrequency ] ;
	}
	
	//  transmitter defaults
	p = auralMonitorPlist[2] ;
	[ p setFloat:6.0 forKey:kMonitorAttenuator ] ;
	[ p setInt:0 forKey:kMonitorFixSelect ] ;
	[ p setFloat:1048.0 forKey:kMonitorFrequency ] ;
	
	//  wideband default
	[ auralMonitorPlist[3] setFloat:10.0 forKey:kMonitorAttenuator ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferences:pref ] ;
	[ self setupAuralMonitorDefaultPreferences:pref ] ;	//  v0.78 
	
	[ pref setString:@"Verdana" forKey:kPSK1Font ] ;
	[ pref setFloat:14.0 forKey:kPSK1FontSize ] ;
	[ pref setString:@"Verdana" forKey:kPSK2Font ] ;
	[ pref setFloat:14.0 forKey:kPSK2FontSize ] ;
	[ pref setString:@"Verdana" forKey:kPSKTxFont ] ;
	[ pref setFloat:14.0 forKey:kPSKTxFontSize ] ;
	[ pref setInt:1 forKey:kPSKWaterfallNR ] ;				//  v0.73
	
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kPSKTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kPSKSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kPSKBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kPSKPlotColor ] ;

	[ (PSKConfig*)config setupDefaultPreferences:pref ] ;
	
	[ pref setFloat:1.0 forKey:kPSKSquelchA ] ;
	[ pref setFloat:1.0 forKey:kPSKSquelchB ] ;
	
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (PSKMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
}

static int kState[] = { NSOffState, NSOnState } ;

- (void)updateFromAuralMonitorPlist:(Preferences*)pref
{
	int i ;
	NSDictionary *d ;
	SubDictionary *p ;
	NSButton *button ;
	NSTextField *field ;
	NSMatrix *matrix ;
	
	//  merge in values from the plist file, if any
	d = [ pref dictionaryForKey:kAuralMonitor0 ] ;
	if ( d != nil ) [ [ auralMonitorPlist[0] dictionary ] addEntriesFromDictionary:d ] ;
	
	d = [ pref dictionaryForKey:kAuralMonitor1 ] ;
	if ( d != nil ) [ [ auralMonitorPlist[1] dictionary ] addEntriesFromDictionary:d ] ;	

	d = [ pref dictionaryForKey:kAuralTransmitter ] ;
	if ( d != nil ) [ [ auralMonitorPlist[2] dictionary ] addEntriesFromDictionary:d ] ;	

	d = [ pref dictionaryForKey:kAuralWideband ] ;
	if ( d != nil ) [ [ auralMonitorPlist[3] dictionary ] addEntriesFromDictionary:d ] ;	

	[ masterMute setState:( [ pref intValueForKey:kMasterMute ] == 1 ) ? NSOnState : NSOffState ] ;
	[ self masterMuteChanged ] ;
	[ masterLevel setFloatValue:[ pref floatValueForKey:kMasterVolume ] ] ;
	[ self masterLevelChanged ] ;

	// aural channel enable buttons
	for ( i = 0; i < 4; i++ ) {
		p = auralMonitorPlist[i] ;
		button = auralAction[i].enableButton ;
		[ button setState:kState[ [ p intValueForKey:kMonitorEnable ] & 3 ] ] ;
		[ self enableChanged:button ] ;
	}
	//  aural channel attenuators
	for ( i = 0; i < 4; i++ ) {
		p = auralMonitorPlist[i] ;
		field = auralAction[i].attenuationField ;
		[ field setFloatValue:[ p floatValueForKey:kMonitorAttenuator ] ] ;
		[ self attenuatorChanged:field ] ;
	}
	//  aural channel fixed/float selection
	for ( i = 0; i < 3; i++ ) {
		p = auralMonitorPlist[i] ;
		matrix = auralAction[i].floatMatrix ;
		[ matrix selectCellAtRow:[ p intValueForKey:kMonitorFixSelect ] column:0 ] ;
		[ self floatMatrixChanged:matrix ] ;
	}
	//  aural channel fixed frequencies
	for ( i = 0; i < 3; i++ ) {
		p = auralMonitorPlist[i] ;
		field = auralAction[i].fixedFrequency ;
		[ field setFloatValue:[ p floatValueForKey:kMonitorFrequency ] ] ;
		[ self fixedFrequencyChanged:field ] ;
	}
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	int i ;
	
	[ super updateFromPlist:pref ] ;
	[ self updateFromAuralMonitorPlist:pref ] ;
	
	if ( rx1 ) [ rx1 updateFromPlist:pref ] ;
	if ( rx2 ) [ rx2 updateFromPlist:pref ] ;
	
	fontName = [ pref stringValueForKey:kPSK1Font ] ;
	fontSize = [ pref floatValueForKey:kPSK1FontSize ] ;
	[ receive1View setTextFont:fontName size:fontSize attribute:receive1TextAttribute ] ;

	fontName = [ pref stringValueForKey:kPSK2Font ] ;
	fontSize = [ pref floatValueForKey:kPSK2FontSize ] ;
	[ receive2View setTextFont:fontName size:fontSize attribute:receive2TextAttribute ] ;
    
	fontName = [ pref stringValueForKey:kPSKTxFont ] ;
	fontSize = [ pref floatValueForKey:kPSKTxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	//  v0.73
	[ waterfall setNoiseReductionState:[ pref intValueForKey:kPSKWaterfallNR ] ] ;
	
	[ rx1Control setSquelchValue:[ pref floatValueForKey:kPSKSquelchA ] ] ;
	[ rx2Control setSquelchValue:[ pref floatValueForKey:kPSKSquelchB ] ] ;
	
	[ manager showSplash:@"Updating PSK configurations" ] ;
	[ (PSKConfig*)config updateFromPlist:pref ] ;
	
	[ manager showSplash:@"Loading PSK macros" ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) {
			[ (PSKMacros*)( macroSheet[i] ) updateFromPlist:pref option:i ] ;
		}
	}
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;
	
	plistHasBeenUpdated = YES ;						//  v0.53d
	return YES ;
}

- (void)retrieveForAuralMonitorPlist:(Preferences*)pref
{
	int i, n ;
	float v ;
	SubDictionary *p ;
	NSButton *button ;
	NSTextField *field ;
	NSMatrix *matrix ;
	
	[ pref setInt:( ( [ masterMute state ] == NSOnState ) ? 1 : 0 ) forKey:kMasterMute ] ;
	[ pref setFloat:[ masterLevel floatValue ] forKey:kMasterVolume ] ;

	// aural channel enable buttons
	for ( i = 0; i < 4; i++ ) {
		p = auralMonitorPlist[i] ;
		button = auralAction[i].enableButton ;
		n = ( [ button state ] == NSOnState ) ? 1 : 0 ;
		[ p setInt:n forKey:kMonitorEnable ] ;
	}
	//  aural channel attenuators
	for ( i = 0; i < 4; i++ ) {
		p = auralMonitorPlist[i] ;
		field = auralAction[i].attenuationField ;
		v = [ field floatValue ] ;
		[ p setFloat:v forKey:kMonitorAttenuator ] ;
	}
	//  aural channel fix/float selection
	for ( i = 0; i < 3; i++ ) {
		p = auralMonitorPlist[i] ;
		matrix = auralAction[i].floatMatrix ;
		n = [ matrix selectedRow ] ;
		[ p setInt:n forKey:kMonitorFixSelect ] ;
	}
	//  aural channel fixed frequency
	for ( i = 0; i < 3; i++ ) {
		p = auralMonitorPlist[i] ;
		field = auralAction[i].fixedFrequency ;
		v = [ field floatValue ] ;
		[ p setFloat:v forKey:kMonitorFrequency ] ;
	}

	//  set subdirector into plist
	[ pref setDictionary:[ auralMonitorPlist[0] dictionary ] forKey:kAuralMonitor0 ] ;
	[ pref setDictionary:[ auralMonitorPlist[1] dictionary ] forKey:kAuralMonitor1 ] ;
	[ pref setDictionary:[ auralMonitorPlist[2] dictionary ] forKey:kAuralTransmitter ] ;
	[ pref setDictionary:[ auralMonitorPlist[3] dictionary ] forKey:kAuralWideband ] ;
}

//  retrieve the preferences that are in use
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	int i ;
	
	if ( plistHasBeenUpdated == NO ) return ;		//  v0.53d
	[ super retrieveForPlist:pref ] ;
	[ self retrieveForAuralMonitorPlist:pref ] ;
	
	if ( rx1 ) [ rx1 retrieveForPlist:pref ] ;
	if ( rx2 ) [ rx2 retrieveForPlist:pref ] ;
	
	[ pref setFloat:[ rx1Control squelchValue ] forKey:kPSKSquelchA ] ;
	[ pref setFloat:[ rx2Control squelchValue ] forKey:kPSKSquelchB ] ;
	
	if ( [ [ NSApp delegate ] isLite ] == NO ) {		//  v0.64d don't play with fonts of Lite window
		font = [ receive1View font ] ;
		[ pref setString:[ font fontName ] forKey:kPSK1Font ] ;
		[ pref setFloat:[ font pointSize ] forKey:kPSK1FontSize ] ;
		font = [ receive2View font ] ;
		[ pref setString:[ font fontName ] forKey:kPSK2Font ] ;
		[ pref setFloat:[ font pointSize ] forKey:kPSK2FontSize ] ;
		font = [ transmitView font ] ;
		[ pref setString:[ font fontName ] forKey:kPSKTxFont ] ;
		[ pref setFloat:[ font pointSize ] forKey:kPSKTxFontSize ] ;
	}
	//  v0.73
	[ pref setInt:[ waterfall noiseReductionState ] forKey:kPSKWaterfallNR ] ;
	
	[ (PSKConfig*)config retrieveForPlist:pref ] ;
	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (PSKMacros*)( macroSheet[i] ) retrieveForPlist:pref option:i ] ;
	}
}

//  need to add text colors to the two separate receive views
- (void)setTextColor:(NSColor*)inTextColor sentColor:(NSColor*)sentTColor backgroundColor:(NSColor*)bgColor plotColor:(NSColor*)pColor
{
	[ super setTextColor:inTextColor sentColor:sentTColor backgroundColor:bgColor plotColor:pColor ] ;
	[ receive1View setTextColor:textColor attribute:receive1TextAttribute ] ;
	[ receive2View setTextColor:textColor attribute:receive2TextAttribute ] ;
	[ receive1View setBackgroundColor:bgColor ] ;				//  v0.38
	[ receive2View setBackgroundColor:bgColor ] ;				//  v0.38
}

//  sideband state (set from PSKConfig's LSB/USB button)
//  NO = LSB
- (void)selectAlternateSideband:(Boolean)state
{
	[ waterfall setSideband:( state ) ? 1 : 0 ] ;
}

- (void)sendMessageImmediately
{
	[ transmitCountLock lock ] ;
	transmitCount++ ;
	[ transmitCountLock unlock ] ;
}

/* local */
//  this gets periodically called
- (void)timedOut:(NSTimer*)timer
{
	if ( charactersSinceTimerStarted == 0 ) {
		//  timed out!
		[ self changeTransmitStateTo:NO ] ;
	}
	charactersSinceTimerStarted = 0 ;
}

//  v0.70
- (void)setUseShiftJIS:(Boolean)state
{
	[ shiftJISTextField setStringValue:( state == YES ) ? NSLocalizedString( @"Shift-JIS", nil ) : @"" ] ;
	[ rx1 setUseShiftJIS:state ] ;
	//  rx2 is always in ASCII
}

- (void)setUseRawForPSK:(Boolean)state
{
	[ rx1 setUseRawForPSK:state ] ;
	//  rx2 is always in ASCII
}

//  (Private API)
//	v0.70 added this filter to convert Unicode to other encodings
- (void)transmitCharacterFilter:(unichar)uch
{
	int ch, vfo ;
	Boolean useShiftJIS ;
	
	ch = uch & 0xffff ;
	
	useShiftJIS = NO ;
	vfo = [ txControl selectedTransceiver ] ;
	if ( vfo == 0 ) useShiftJIS = [ rx1 useShiftJIS ] ;
	
	if ( useShiftJIS ) {
		//  Send unicode as double byte Shift-JIS code
		[ config transmitDoubleByteCharacter:unicodeToJis[ch*2] second:unicodeToJis[ch*2+1] ] ;
	}
	else {
		//  not Unicode
		if ( ch > 255 ) ch = '.' ;
		[ config transmitCharacter:ch ] ;
	}
}

//  allow receive data to flush through the pipeline before changing text color
//  and sending transmit buffer
- (void)delayTransmit:(NSTimer*)timer
{
	unichar uch ;
	NSString *string ;
	NSTextStorage *storage ;
	
	[ transmitView select ] ;
	//  send any pending storage
	[ transmitViewLock lock ] ;
	storage = [ transmitView textStorage ] ;
	string = [ storage string ] ;		
	while ( indexOfUntransmittedText < unmarkedTextLength ) {
		uch = [ string characterAtIndex:indexOfUntransmittedText++ ] ;
		[ self transmitCharacterFilter:uch ] ;
		charactersSinceTimerStarted++ ;
	}
	[ transmitViewLock unlock ] ;
}

- (void)checkTransmitBuffer:(NSTimer*)timer
{
	unichar uch ;
	NSString *string ;
	NSTextStorage *storage ;
	int total ;

	[ transmitViewLock lock ] ;
	if ( indexOfUntransmittedText < unmarkedTextLength ) {
		storage = [ transmitView textStorage ] ;
		string = [ storage string ] ;
		total = [ string length ] ;
		while ( indexOfUntransmittedText < unmarkedTextLength ) {
			if ( indexOfUntransmittedText >= total ) break ;				//  sanity check
			uch = [ string characterAtIndex:indexOfUntransmittedText++ ] ;
			[ self transmitCharacterFilter:uch ] ;
			charactersSinceTimerStarted++ ;
		}
	}
	[ transmitViewLock unlock ] ;
}

- (Boolean)transmitting
{
	return transmitState ;
}

- (void)useSlashedZero:(Boolean)state
{
	[ super useSlashedZero:state ] ;
	if ( rx1 ) [ rx1 useSlashedZero:state ] ;
	if ( rx2 ) [ rx2 useSlashedZero:state ] ;
}

- (void)selectTransceiver:(Transceiver*)transceiver andChangeTransmitStateTo:(Boolean)transmit
{
	int index ;
	PSKTransmitControl *control ;
	
	index = ( transceiver == transceiver1 ) ? 0 : 1 ;
	control = ( inContestMode ) ? contestTxControl : txControl ;

	if ( index != [ control selectedTransceiver ] ) {
		[ control selectTransceiver:index ] ;
	}
	[ self enterTransmitMode:transmit ] ;
}

- (int)selectedTransceiver
{
	PSKTransmitControl *control ;
	
	control = ( inContestMode ) ? contestTxControl : txControl ;
	return [ control selectedTransceiver ] + 1 ;
}

//  v0.89  also called from Applescript
- (void)flushClickBuffer
{
	[ rx1 clearClickBuffer ] ;
	[ rx2 clearClickBuffer ] ;
}

//  Application sends this through the ModemManager when quitting
- (void)applicationTerminating
{
	[ ptt applicationTerminating ] ;				//  v0.89
}

- (void)changeTransmitStateTo:(Boolean)state
{
	int xcvr, indicatorState ;
	
	if ( state == 0 ) {		//  v0.66
		//  state is changed back to receive state, mark as backspace limit
		hardLimitForBackspace = indexOfUntransmittedText ;
	}	
	transmitState = [ config turnOnTransmission:state button:transmitButton mode:[ self currentPSKMode ] ] ;			// v0.47
	
	if ( transmitState == YES ) {
		[ self ptt:YES ] ;
		indicatorState =  TxActive ;
		[ [ transmitView window ] makeFirstResponder:transmitView ] ;
		if ( timeout ) [ timeout invalidate ] ;
		charactersSinceTimerStarted = 0 ;
		if ( [ manager useWatchdog ] ) timeout = [ NSTimer scheduledTimerWithTimeInterval:150 target:self selector:@selector(timedOut:) userInfo:self repeats:YES ] ;
		transmitBufferCheck = [ NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(checkTransmitBuffer:) userInfo:self repeats:YES ] ;
		//  set text color in receive view and turn on transmit
		[ NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(delayTransmit:) userInfo:self repeats:NO ] ;		
		[ self flushClickBuffer ] ; //  v0.89
	}
	else {
		if ( timeout ) [ timeout invalidate ] ;
		timeout = nil ;
		if ( transmitBufferCheck ) [ transmitBufferCheck invalidate ] ;
		transmitBufferCheck = nil ;
		[ self ptt:NO ] ;
		[ transmitCountLock lock ] ;
		transmitCount = 0 ;
		[ transmitCountLock unlock ] ;
		indicatorState = TxReady ;
		[ self setSentColor:NO view:activeReceiveView textAttribute:activeReceiveTextAttribute ] ;
		[ transmitView select ] ;
	}
	
	xcvr = [ self selectedReceiver ] ;
	if ( xcvr == 0 ) {
		[ rx2 setTransmitLightState:TxOff ] ;
		[ rx1 setTransmitLightState:indicatorState ] ;
	}
	else {
		[ rx1 setTransmitLightState:TxOff ] ;
		[ rx2 setTransmitLightState:indicatorState ] ;
	}
}

- (void)setFrequencyDefined
{
	frequencyDefined = YES ;
}

//  this overrides the method in Modem.m that is called from the app
- (void)enterTransmitMode:(Boolean)state
{
	int xcvr ;
	PSKReceiver *rx ;
	
	if ( !frequencyDefined ) return ;		//  return if the waterfall has not been previously clicked
	
	if ( state != transmitState ) {
		xcvr = [ self selectedReceiver ] ;
		if ( state == YES ) {
			//  immediately change state to transmit
			activeReceiveView = ( xcvr == 0 ) ? receive1View : receive2View ;
			[ self changeTransmitStateTo:state ] ;
		}
		else {
			//  enter a %[rx] character into the stream
			[ transmitView insertInTextStorage:[ NSString stringWithFormat:@"%c", 5 /*^E*/ ] ] ;
			rx = ( xcvr == 0 ) ? rx1 : rx2 ;
			[ rx setTransmitLightState:TxWait ] ;
		}
	}
}

- (void)selectView
{
	int xcvr ;
	
	xcvr = [ self selectedReceiver ] ;
	activeReceiveView = ( xcvr == 0 ) ? receive1View : receive2View ;
}

/* local */
- (Boolean)canTransmit
{
	int xcvr ;

	xcvr = [ self selectedReceiver ] ;	
	return ( ( xcvr == 0 ) ? [ rx1 canTransmit ] : [ rx2 canTransmit ] ) ;
}

- (void)flushOutput
{
	[ transmitCountLock lock ] ;
	transmitCount = 0 ;
	[ transmitCountLock unlock ] ;
	//  flush transmit view also
	indexOfUntransmittedText = [ [ transmitView textStorage ] length ] ;
	//  now flush whatever is in the apsk bit buffer
	[ config flushTransmitBuffer ] ;
}

//  this overrides the method in Modem.m
- (void)flushAndLeaveTransmit
{
	[ self flushOutput ] ;
	[ self enterTransmitMode:NO ] ;
}

- (NSSlider*)inputAttenuator:(ModemConfig*)config
{
	return inputAttenuator ;
}

- (void)transmitButtonChanged
{
	int state ;
	
	state = ( [ transmitButton state ] == NSOnState ) ;
	
	if ( state ) {
		if ( ![ config soundInputActive ] ) {
			//  check if A/D is active
			[ transmitButton setState:NSOffState ] ;
			[ waterfall clearMarkers ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"Sound Card not active", nil ) informativeText:NSLocalizedString( @"Select Sound Card", nil ) ] ;
			return ;
		}
		if ( ![ self canTransmit ] ) {
			//  check if receive frequency has been selected
			[ transmitButton setState:NSOffState ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"Selected PSK Transceiver not on", nil ) informativeText:NSLocalizedString( @"need to set xcvr", nil ) ] ;
			[ self flushOutput ] ;
			return ;
		}
	}
	[ self enterTransmitMode:state ] ;
}

- (void)squelchChanged
{
}

- (void)inputAttenuatorChanged
{
	[ [ (PSKConfig*)config inputSource ] setDeviceLevel:inputAttenuator ] ;
}

- (IBAction)flushTransmitStream:(id)sender
{
	[ self flushOutput ] ;
}

//	v0.97
- (void)nextStationInTableView
{
	if ( rx1 ) [ rx1 nextStationInTableView ] ;
}

//	v1.01c
- (void)previousStationInTableView
{
	if ( rx1 ) [ rx1 previousStationInTableView ] ;
}

//	v0.97
- (void)openPSKTableView:(Boolean)state
{
	if ( rx1 ) [ rx1 enableTableView:state ] ;
}

- (IBAction)openTableView:(id)sender
{
	[ self openPSKTableView:YES ] ;
}

//  Delegate of receiveView and transmitView
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)original replacementString:(NSString*)replace
{
	int start, total, length, i ;
	NSTextStorage *storage ;
	unichar *s, unicodeReplacement[513] ;
	Boolean hasZero ;
	
	if ( textView == receiveView ) {
		if ( [ replace length ] != 0 ) {
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
			[ Messages alertWithMessageText:NSLocalizedString( @"text is write only", nil ) informativeText:NSLocalizedString( @"cannot insert text", nil ) ] ;
			return NO ;
		}
		return YES ;
	}
	if ( textView == transmitView ) {
		if ( slashZero ) {
			//  v0.71 fetch string as Unicode
			length = [ replace length ] ;
			if ( length > 512 ) length = 512 ;
			[ replace getCharacters:unicodeReplacement range:NSMakeRange( 0, length ) ] ;
			unicodeReplacement[length] = 0 ;
			s = unicodeReplacement ;
			if ( s == nil ) return NO ;

			//  quick check for existance of zero
			hasZero = NO ;
			while ( *s ) if ( *s++ == '0' ) hasZero = YES ;
			
			if ( hasZero ) {
				s = unicodeReplacement ;
				while ( *s ) {
					if ( *s == '0' ) *s = Phi ;
					s++ ;
				}
				//  replace zeros with phi and try again
				NSString *replacedNSString = [ NSString stringWithCharacters:unicodeReplacement length:length ] ;
				[ transmitView replaceCharactersInRange:original withString:replacedNSString ] ;
				return NO ;
			}
		}
		
		[ transmitViewLock lock ] ;						//  v0.64
		storage = [ transmitView textStorage ] ;
		total = [ storage length ] ;		
		start = original.location ;
		length = original.length ;
		
		if ( length == total && [ replace length ] == 0 && transmitState == NO ) {
			//  erase all
			[ transmitView clearAll ] ;
			indexOfUntransmittedText = unmarkedTextLength = 0 ;
			hardLimitForBackspace = 0 ;					// v0.66
			[ transmitViewLock unlock ] ;	
			return NO ;
		}
		//  v0.95 don't do anything with double byte and umlauts; let Cocoa call -insertText in SendView
		if ( [ transmitView hasMarkedText ] == YES ) {
			[ transmitViewLock unlock ] ;
			insertionRange = [ transmitView markedRange ] ;
			return YES ;
		}
		if ( length > 0 ) {
			if ( length > 1 ) {
				//  v0.82
				NSBeep() ;
				[ transmitViewLock unlock ] ;
				return NO ;
			}			
			if ( ( start+length ) == total ) {
				//  deleting <length> characters from end
				if ( ( total-length ) < hardLimitForBackspace ) {			//  deleting past the transmitted text v0.65
					NSBeep() ;
					[ transmitViewLock unlock ] ;							// 0.66
					return NO ;
				}
				if ( transmitState == YES ) {
					if ( [ replace length ] == 0 ) {
						for ( i = 0; i < length; i++ ) [ config transmitCharacter:0x08 ] ;
					}
					indexOfUntransmittedText -= length ;  //  v0.70 don't "backspace" index of transmitted character if input method is busy
				}
				unmarkedTextLength = total-length ;
				[ transmitViewLock unlock ] ;	
				return YES ;
			}
			if ( transmitState == YES ) {
				// [ transmitView insertAtEnd:replace ] ;
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ transmitViewLock unlock ] ;	
				return NO ;
			}			
			//  not yet transmitted
			if ( original.location < indexOfUntransmittedText ) {
				[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
				[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
				[ transmitViewLock unlock ] ;	
				return NO ;
			}
			//  should not get here, sanity check on lengths
			unmarkedTextLength = indexOfUntransmittedText = total ;
			[ transmitViewLock unlock ] ;	
			return YES ;
		}
		//  insertion length = 0 (single byte text)
		if ( start != total ) {
			//  inserting in the middle of the transmitView
			if ( transmitState == YES ) {
				//  always insert text at the end when in transmit state
				NSBeep() ;
				[ transmitView insertAtEnd:replace ] ;
				[ transmitViewLock unlock ] ;	
				return NO ;
			}
			else {
				if ( original.location < indexOfUntransmittedText ) {
					//  attempt to insert into text that has already been transmitted
					[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
					[ Messages alertWithMessageText:NSLocalizedString( @"text already sent", nil ) informativeText:NSLocalizedString( @"cannot insert after sending", nil ) ] ;
					[ transmitViewLock unlock ] ;	
					return NO ;
				}
				[ transmitViewLock unlock ] ;	
				return YES ;
			}
		}
		if ( [ replace length ] != 0 ) {
			//  character will be inserted when we return, which causes SendView to call -insertedText
			[ transmitViewLock unlock ] ;
			insertionRange = original ;
			return YES ;
		}
	}
	[ transmitViewLock unlock ] ;	
	return YES ;
}

//  handle callsign clicks
- (NSRange)textView:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange
{
	NSRange range ;
	
	if ( textView == receive1View || textView == receive2View ) {
		//  cancel transmission if there is a repeating macro
		if ( contestBar ) [ contestBar cancelIfRepeatingIsActive ] ;								// v0.32

		if ( [ textView respondsToSelector:@selector(getRightMouse) ] && [ (ExchangeView*)textView getRightMouse ]  ) {	// v0.32
			if ( [ textView lockFocusIfCanDraw ] ) {
				range = [ self captureCallsign:textView willChangeSelectionFromCharacterRange:oldSelectedCharRange toCharacterRange:newSelectedCharRange ] ;
				[ textView unlockFocus ] ;
				return range ;
			}
		}
	}
	return newSelectedCharRange ;
}

- (void)textViewDidChangeSelection:(NSNotification*)notify
{
	id obj ;
	
	obj = [ notify object ] ;
	
	if ( obj == receive1View || obj == receive2View ) {
		[ self captureSelection:obj ] ;
	}
	if ( [ contestBar textInsertedFromRepeat ] ) return ;		//  v0.33
	[ self callsignClickSuccessful:enableClick ] ;
}

//  --- AppleScript support ---

//  v0.64c - return spectrum
- (NSString*)spectrum
{
	/*
	int count, i, ch ;
	char string[17], *s ;
	
	//  quick check, without needing lock
	if ( producer == consumer ) return @"" ;
	
	[ ptr lock ] ;
	if ( producer == consumer ) return @"" ;
	count = producer - consumer ;
	[ ptr unlock ] ;
	if ( count > 16 ) count = 16 ;
	s = string ;
	for ( i = 0; i < count; i++ ) {
		ch = buffer[ (consumer++)&BUFMASK ] & 0xff ;	//  mask to 8 bit ASCII
		if ( ch != 0 ) *s++ = ch ;
	}
	*s++ = 0 ;
	if ( strlen( string ) == 0 ) return @"" ;
	
	return [ NSString stringWithCString:string encoding:kTextEncoding ] ;
	*/
	
	return @"" ;
}


- (int)modulationCodeFor:(Transceiver*)transceiver
{
	PSKControl *control ;
	int mode ;
	
	control = ( transceiver == transceiver1 ) ? rx1Control : rx2Control ;
	
	switch ( [ control pskMode ] ) {
	default:
	case kBPSK31:
		mode = ModulationBPSK31 ;
		break ;
	case kQPSK31:
		mode = ModulationQPSK31 ;
		break ;
	case kBPSK63:
		mode = ModulationBPSK63 ;
		break ;
	case kQPSK63:
		mode = ModulationQPSK63 ;
		break ;
	case ( kBPSK63 | 0x8 ):
		mode = ModulationBPSK125 ;
		break ;
	case ( kQPSK63 | 0x8 ):
		mode = ModulationQPSK125 ;
		break ;
	}
	return mode ;
}

- (void)setModulationCodeFor:(Transceiver*)transceiver to:(int)code
{
	PSKControl *control ;
	NSString *mode ;
	
	control = ( transceiver == transceiver1 ) ? rx1Control : rx2Control ;
	switch ( code ) {
	default:
	case ModulationBPSK31:
		mode = @"BPSK31" ;
		break ;
	case ModulationQPSK31:
		mode = @"QPSK31" ;
		break ;
	case ModulationBPSK63:
		mode = @"BPSK63" ;
		break ;
	case ModulationQPSK63:
		mode = @"QPSK63" ;
		break ;
	case ModulationBPSK125:
		mode = @"BPSK125" ;
		break ;
	case ModulationQPSK125:
		mode = @"QPSK125" ;
		break ;
	}
	[ control changeModeToString:mode ] ;
}

- (float)frequencyFor:(Module*)module
{
	PSKReceiver *receiver ;
	
	receiver = ( [ module transceiver ] == transceiver1 ) ? rx1 : rx2 ;
	return ( ( [ module isReceiver ] ) ? [ receiver rxTone ] : [ receiver txTone ] ) ;
}

- (void)setFrequency:(float)freq module:(Module*)module
{
	PSKReceiver *receiver ;
	
	receiver = ( [ module transceiver ] == transceiver1 ) ? rx1 : rx2 ;
	if ( [ module isReceiver ] ) {
		[ receiver setAndDisplayRxTone:freq ] ; 
	}
	else {
		[ receiver setAndDisplayTxTone:freq ] ;
		[ config setTransmitFrequency:freq ] ;
	}
}

- (void)setTimeOffset:(float)offset module:(Module*)module
{
	PSKReceiver *receiver ;
	
	receiver = ( [ module transceiver ] == transceiver1 ) ? rx1 : rx2 ;
	if ( [ module isReceiver ] ) {
		[ receiver setTimeOffset:offset ] ; 
	}
}

- (void)transmitString:(const char*)s
{
	unichar uch ;
	
	while ( *s ) {
		uch = *s++ ;
		[ self transmitCharacterFilter:uch ] ;
	}
}


//  ------------ deprecated AppleScripts ----------------
- (float)getRxOffset:(int)trx
{
	return ( trx == 0 ) ? [ rx1 rxOffset ] : [ rx2 rxOffset ] ;
}

- (void)setRxOffset:(int)trx freq:(float)freq
{
	if ( trx == 0 ) [ rx1 setAndDisplayRxOffset:freq ] ; else [ rx2 setAndDisplayRxOffset:freq ] ;
}

- (float)getTxOffset:(int)trx
{
	return ( trx == 0 ) ? [ rx1 txOffset ] : [ rx2 txOffset ] ;
}

- (void)setTxOffset:(int)trx freq:(float)freq
{
	if ( trx == 0 ) [ rx1 setAndDisplayTxOffset:freq ] ; else [ rx2 setAndDisplayTxOffset:freq ] ;
}

//  PSK (transmit) modulation
- (int)getPskModulation
{
	int m ;
	
	switch ( [ self currentPSKMode ] ) {
	default:
	case kBPSK31: 
		m = PSKModeBPSK31 ;
		break ;
	case kBPSK63: 
		m = PSKModeBPSK63 ;
		break ;
	case kQPSK31: 
		m = PSKModeQPSK31 ;
		break ;
	case kQPSK63: 
		m = PSKModeQPSK63 ;
		break ;
	}
	return m ;
}

- (void)changePskModulationTo:(int)modulation
{
	int trx, index ;
	PSKControl *control ;
	
	switch ( modulation ) {
	default:
	case PSKModeBPSK31: 
		index = kBPSK31 ;
		break ;
	case PSKModeBPSK63: 
		index = kBPSK63 ;
		break ;
	case PSKModeQPSK31: 
		index = kQPSK31 ;
		break ;
	case PSKModeQPSK63: 
		index = kQPSK63 ;
		break ;
	}	
	//  get the PSK controls for the "current" transceiver 
	trx = [ txControl selectedTransceiver ] ;
	control = ( trx == 0 ) ? rx1Control : rx2Control ;
	[ control changeModeToIndex:index ] ;
}

//	v0.95 (delegate of SendView)
//  Bump text length when text is inserted at the end of the buffer. (-checkTransmitBuffer will pick it up)
//	Single byte, double byte and umlauts, etc, are all entered with this mechanism
- (void)insertedText:(NSString*)string
{
	unmarkedTextLength = insertionRange.location + [ string length ] ;
}

//	v0.96c
- (void)selectView:(int)index
{
	NSView *pview ;
	
	pview = nil ;
	switch ( index ) {
	case 1:
		pview = receive1View ;
		break ;
	case 2:
		pview = receive2View ;
		break ;
	case 0:
		pview = transmitView ;
		break ;
	}
	if ( pview ) [ [ pview window ] makeFirstResponder:pview ] ;
}

@end
