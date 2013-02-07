//
//  ASCII.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/28/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "ASCII.h"
#import "AppDelegate.h"
#import "Application.h"
#import "cocoaModemParams.h"
#import "Config.h"
#import "ModemSource.h"
#import "Module.h"
#import "Plist.h"
#import "RTTYMacros.h"
#import "RTTYReceiver.h"
#import "RTTYRxControl.h"
#import "RTTYTxConfig.h"
#import "RTTYWaterfall.h"
#import "Spectrum.h"
#import "Transceiver.h"
#import "WFRTTYConfig.h"


@implementation ASCII

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr nib:(NSString*)nib
{
	CMTonePair tonepair ;
	float ellipseFatness = 0.9 ;
	
	RTTYConfigSet setA = { 
		LEFTCHANNEL, 
		kASCIIMainDevice, 
		kASCIIOutputDevice, 
		kASCIIOutputLevel, 
		kASCIIOutputAttenuator, 
		kASCIIMainTone, 
		kASCIIMainMark, 
		kASCIIMainSpace,
		kASCIIMainBaud,
		kASCIIMainControlWindow,
		kASCIIMainSquelch,
		kASCIIMainActive,
		kASCIIMainStopBits,
		kASCIIMainMode,
		kASCIIMainRxPolarity,
		kASCIIMainTxPolarity,
		kASCIIMainPrefs,
		kASCIIMainTextColor,
		kASCIIMainSentColor,
		kASCIIMainBackgroundColor,
		kASCIIMainPlotColor,
		kASCIIMainOffset,
		kASCIIMainFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kASCIIMainAuralMonitor
	} ;

	RTTYConfigSet setB = { 
		RIGHTCHANNEL, 
		kASCIISubDevice, 
		nil, 
		nil, 
		nil, 
		kASCIISubTone, 
		kASCIISubMark, 
		kASCIISubSpace,
		kASCIISubBaud,
		kASCIISubControlWindow,
		kASCIISubSquelch,
		kASCIISubActive,
		kASCIISubStopBits,
		kASCIISubMode,
		kASCIISubRxPolarity,
		kASCIISubTxPolarity,
		kASCIISubPrefs,
		kASCIISubTextColor,
		kASCIISubSentColor,
		kASCIISubBackgroundColor,
		kASCIISubPlotColor,
		kASCIISubOffset,
		kASCIISubFSKSelection,
		YES,							// usesRTTYAuralMonitor
		kASCIISubAuralMonitor
	} ;

	self = [ super initIntoTabView:tabview nib:nib manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		isASCIIModem = YES ;
		bitsPerCharacter = 7 ;
		hardLimitForBackspace = 0 ;	

		//  initialize txConfig before rxConfigs (nte at this point rttyRxControls is undefined)
		[ txConfig awakeFromModem:&setA rttyRxControl:nil ] ;
		ptt = [ txConfig pttObject ] ;
		
		a.isAlive = YES ;
		a.control = [ [ RTTYRxControl alloc ] initIntoView:receiverA client:self index:0 ] ;
		a.receiver = [ a.control receiver ] ;
		[ a.receiver createClickBuffer ] ;
		currentRxView = a.view = [ a.control view ] ;
		[ a.view setDelegate:self ] ;		//  text selections, etc
		a.textAttribute = [ a.control textAttribute ] ;
		[ a.control setName:NSLocalizedString( @"Main Receiver", nil ) ] ;
		[ a.control setEllipseFatness:ellipseFatness ] ;
		[ configA awakeFromModem:&setA rttyRxControl:a.control txConfig:txConfig ] ;
		[ configA setChannel:0 ] ;
		control[0] = a.control ;
		configObj[0] = configA ;
		txLocked[0] = NO ;
		
		//  v0.78
		[ txConfig setRTTYAuralMonitor:[ a.receiver rttyAuralMonitor ] ] ;
		
		tonepair = [ a.control baseTonePair ] ;
		[ waterfallA setTonePairMarker:&tonepair index:0 ] ;

		b.isAlive = YES ;
		b.control = [ [ RTTYRxControl alloc ] initIntoView:receiverB client:self index:1 ] ;
		b.receiver = [ b.control receiver ] ;
		[ b.receiver createClickBuffer ] ;
		b.view = [ b.control view ] ;
		[ b.view setDelegate:self ] ;		//  text selections, etc
		b.textAttribute = [ b.control textAttribute ] ;
		[ b.control setName:NSLocalizedString( @"Sub Receiver", nil ) ] ;
		[ b.control setEllipseFatness:ellipseFatness ] ;
		[ configB awakeFromModem:&setB rttyRxControl:b.control txConfig:txConfig ] ;	// note:shared txConfig
		[ configB setChannel:1 ] ;
		control[1] = b.control ;
		configObj[1] = configB ;
		txLocked[1] = NO ;
		tonepair = [ b.control baseTonePair ] ;
		[ waterfallB setTonePairMarker:&tonepair index:1 ] ;

		[ configTab setDelegate:self ] ;

		//  AppleScript text callback
		[ a.receiver registerModule:[ transceiver1 receiver ] ] ;
		a.transmitModule = [ transceiver1 transmitter ] ;
		if ( !isLite ) {
			[ b.receiver registerModule:[ transceiver2 receiver ] ] ;
			b.transmitModule = [ transceiver2 transmitter ] ;
		}
	}
	return self ;
}

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	isLite = NO ;
	[ mgr showSplash:@"Creating ASCII Modem" ] ;
	return [ self initIntoTabView:tabview manager:mgr nib:@"ASCII" ] ;
}

- (void)awakeFromNib
{
	ident = NSLocalizedString( @"ASCII", nil ) ;
	[ self setInterface:dataBits to:@selector(numberOfBitsChanged:) ] ;
	[ self commonAwakeFromNib ] ;
}

- (void)numberOfBitsChanged:(id)sender
{
	bitsPerCharacter= ( [ sender selectedRow ] == 0 ) ? 7 : 8 ; 
	[ [ a.receiver demodulator ] setBitsPerCharacter:bitsPerCharacter ] ;
	[ [ b.receiver demodulator ] setBitsPerCharacter:bitsPerCharacter ] ;
	[ txConfig setBitsPerCharacter:bitsPerCharacter ] ;
}

- (void)changeTransmitStateTo:(Boolean)state
{
	if ( state == 0 ) {
		//  state is changed back to receive state, mark as backspace limit
		hardLimitForBackspace = indexOfUntransmittedText ;
	}	
	[ super changeTransmitStateTo:state ] ;
}

//  Delegate of receiveView and transmitView
- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)original replacementString:(NSString *)replace
{
	NSTextStorage *storage ;
	int i, start, length, total ;

	//  check if backspacing at the of transmit view end while transmitting	
	if ( textView == transmitView && transmitState == YES && [ replace length ] == 0 ) {
		[ transmitViewLock lock ] ;
		storage = [ transmitView textStorage ] ;
		if ( storage != nil ) {
			total = [ storage length ] ;		
			start = original.location ;
			length = original.length ;
			if ( ( start+length ) >= total ) {
				//  deleting <length> characters from end
				if ( ( total-original.length ) < hardLimitForBackspace ) {			
					//  deleting pass the transmitted text
					NSBeep() ;
					[ transmitViewLock unlock ] ;
					return NO ;
				}
				for ( i = 0; i < length; i++ ) {
					[ txConfig transmitCharacter:0x08 ] ;
				}
				if ( [ transmitView hasMarkedText ] == NO ) indexOfUntransmittedText -= length ;
			}
			[ transmitViewLock unlock ] ;	
			return YES ;
		}
		[ transmitViewLock unlock ] ;
	}
	// if not backspacing while transmitting, just call base class
	return [ super textView:textView shouldChangeTextInRange:original replacementString:replace ] ;
}

//  before Plist is read in
- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	
	[ super setupDefaultPreferences:pref ] ;
	
	[ pref setString:@"Verdana" forKey:kASCIIFontA ] ;
	[ pref setFloat:14.0 forKey:kASCIIFontSizeA ] ;
	[ pref setString:@"Verdana" forKey:kASCIIFontB ] ;
	[ pref setFloat:14.0 forKey:kASCIIFontSizeB ] ;
	
	[ pref setString:@"Verdana" forKey:kASCIITxFont ] ;
	[ pref setFloat:14.0 forKey:kASCIITxFontSize ] ;
	[ pref setInt:1 forKey:kASCIIMainWaterfallNR ] ;
	[ pref setInt:1 forKey:kASCIISubWaterfallNR ] ;
	[ pref setInt:bitsPerCharacter forKey:kASCIIBitsPerCharacter ] ;
		
	[ pref setInt:0 forKey:kASCIITransmitChannel ] ;
	[ pref setInt:0 forKey:kASCIILockA ] ;
	[ pref setInt:0 forKey:kASCIILockB ] ;

	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kASCIIMainTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kASCIIMainSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kASCIIMainBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kASCIIMainPlotColor ] ;
	[ pref setRed:1.0 green:0.8 blue:0.0 forKey:kASCIISubTextColor ] ;
	[ pref setRed:0.0 green:0.8 blue:1.0 forKey:kASCIISubSentColor ] ;
	[ pref setRed:0.0 green:0.0 blue:0.0 forKey:kASCIISubBackgroundColor ] ;
	[ pref setRed:0.0 green:1.0 blue:0.0 forKey:kASCIISubPlotColor ] ;
	
	[ configA setupDefaultPreferences:pref rttyRxControl:a.control ] ;
	[ configB setupDefaultPreferences:pref rttyRxControl:b.control ] ;

	for ( i = 0; i < 3; i++ ) {
		if ( macroSheet[i] ) [ (RTTYMacros*)( macroSheet[i] ) setupDefaultPreferences:pref option:i ] ;
	}
}

//  set up this Modem's setting from the Plist
- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontName ;
	float fontSize ;
	int txChannel ;
	Boolean locked ;
	
	[ super updateFromPlist:pref ] ;
	
	fontName = [ pref stringValueForKey:kASCIIFontA ] ;
	fontSize = [ pref floatValueForKey:kASCIIFontSizeA ] ;
	[ a.view setTextFont:fontName size:fontSize attribute:[ a.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kASCIIFontB ] ;
	fontSize = [ pref floatValueForKey:kASCIIFontSizeB ] ;
	[ b.view setTextFont:fontName size:fontSize attribute:[ b.control textAttribute ] ] ;
	
	fontName = [ pref stringValueForKey:kASCIITxFont ] ;
	fontSize = [ pref floatValueForKey:kASCIITxFontSize ] ;
	[ transmitView setTextFont:fontName size:fontSize attribute:transmitTextAttribute ] ;
	
	txChannel = [ pref intValueForKey:kASCIITransmitChannel ] ;
	[ self transmitFrom:txChannel ] ;
	[ transmitSelect selectCellAtRow:0 column:txChannel ] ;
	[ contestTransmitSelect selectCellAtRow:0 column:txChannel ] ;
	//  update visual interfaces
	[ self transmitSelectChanged ] ;
	
	locked = ( [ pref intValueForKey:kASCIILockA ] != 0 ) ;
	[ self setTransmitLockButton:0 toState:locked ] ;
	[ control[0] setTransmitLock:locked ] ;
	txLocked[0] = locked ;
	
	locked = ( [ pref intValueForKey:kASCIILockB ] != 0 ) ;
	[ self setTransmitLockButton:1 toState:locked ] ;
	[ control[1] setTransmitLock:locked ] ;
	txLocked[1] = locked ;
	
	[ waterfallA setNoiseReductionState:[ pref intValueForKey:kASCIIMainWaterfallNR ] ] ;
	[ waterfallB setNoiseReductionState:[ pref intValueForKey:kASCIISubWaterfallNR ] ] ;
	
	[ dataBits selectCellAtRow:( [ pref intValueForKey:kASCIIBitsPerCharacter ] == 8 )? 1 : 0 column:0 ] ;
	[ self numberOfBitsChanged:dataBits ] ;
	
	[ manager showSplash:@"Updating ASCII configurations" ] ;
	[ configA updateFromPlist:pref rttyRxControl:a.control ] ;	
	[ configB updateFromPlist:pref rttyRxControl:b.control ] ;
	//  check slashed zero key
	[ self useSlashedZero:[ pref intValueForKey:kSlashZeros ] ] ;

	plistHasBeenUpdated = YES ;
	return YES ;
}

//  retrieve the preferences before exiting
- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	
	if ( plistHasBeenUpdated == NO ) return ;
	
	[ super retrieveForPlist:pref ] ;
	
	font = [ a.view font ] ;
	[ pref setString:[ font fontName ] forKey:kASCIIFontA ] ;
	[ pref setFloat:[ font pointSize ] forKey:kASCIIFontSizeA ] ;
	font = [ b.view font ] ;
	[ pref setString:[ font fontName ] forKey:kASCIIFontB ] ;
	[ pref setFloat:[ font pointSize ] forKey:kASCIIFontSizeB ] ;
	
	font = [ transmitView font ] ;
	[ pref setString:[ font fontName ] forKey:kASCIITxFont ] ;
	[ pref setFloat:[ font pointSize ] forKey:kASCIITxFontSize ] ;
	
	[ pref setInt:transmitChannel forKey:kASCIITransmitChannel ] ;
	
	[ pref setInt:( ( [ self transmitIsLocked:0 ] ) ? 1 : 0 ) forKey:kASCIILockA ] ;
	[ pref setInt:( ( [ self transmitIsLocked:1 ] ) ? 1 : 0 ) forKey:kASCIILockB ] ;
	
	[ pref setInt:[ waterfallA noiseReductionState ] forKey:kASCIIMainWaterfallNR ] ;
	[ pref setInt:[ waterfallB noiseReductionState ] forKey:kASCIISubWaterfallNR ] ;
	[ pref setInt:( [ dataBits selectedRow ] == 0 ) ? 7 : 8 forKey:kASCIIBitsPerCharacter ] ;

	[ configA retrieveForPlist:pref rttyRxControl:a.control ] ;
	[ configB retrieveForPlist:pref rttyRxControl:b.control ] ;
}


//  Application sends this through the ModemManager when quitting
- (void)applicationTerminating
{
	[ ptt applicationTerminating ] ;				//  v0.89
}


@end
