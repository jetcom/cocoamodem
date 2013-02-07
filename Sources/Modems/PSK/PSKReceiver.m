//
//  PSKReceiver.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Sep 02 2004.
	#include "Copyright.h"
//

#import "PSKReceiver.h"
#import "AppDelegate.h"
#import "Application.h"
#import "cocoaModemParams.h"
#import "ExchangeView.h"
#import "FrequencyIndicator.h"
#import "Module.h"
#import "PhaseIndicator.h"
#import "Plist.h"
#import "Preferences.h"
#import "PSK.h"
#import "PSKAuralMonitor.h"
#import "PSKBrowserHub.h"
#import "PSKControl.h"
#import "PSKHub.h"
#import "PSKMonitor.h"
#import "Waterfall.h"
#import "CMPCO.h"
#import "CMDSPWindow.h"
#import <math.h>

#define q180	3.14159265358979323
#define q360	(q180*360./180.)
#define q315	(q180*315./180.)
#define q270	(q180*270./180.)
#define q225	(q180*225./180.)
#define q135	(q180*135./180.)
#define q90		(q180*90./180.)
#define q45		(q180*45./180.)

enum LockCondition {
	kNoData,
	kHasData
} ;


@implementation PSKReceiver

//	(Private API)
- (int)printable:(int)character extended:(int)extended
{
	int previous = lastASCII ;
	lastASCII = character ;
	
	if ( character == 010 ) return character ;

	if ( character == '\r' ) {
		if ( previous != '\n' ) return '\n' ;
		//  suppress
		lastASCII = -1 ;
		return 0 ;
	}
	if ( character == '\n' ) {
		if ( previous != '\r' ) return '\n' ;
		//  suppress
		lastASCII = -1 ;
		return 0 ;
	}
	if ( character >= 32 && character < 128 ) return character ;
	//  HTML extended ASCII
	if ( extended ) {
		if ( character > 159 && character < 256 ) return character ;
		if ( character == 145 || character == 146 ) return character ;
	}
	return 0 ;
}

- (Boolean)loadReceiver:(NSView*)view index:(int)index
{
	if ( [ NSBundle loadNibNamed:@"PSKReceiver" owner:self ] ) {	
		// loadNib should have set up controlView connection
		if ( view && controlView ) [ view addSubview:controlView ] ;
		
		transmitFrequency = 10 ;			//  stay away from active signals
		vfoOffset = 0 ;
		sideband = NO ;	
		monitor = [ [ PSKMonitor alloc ] init ] ;
		[ monitor setTitle:@"PSK Monitor" ] ;
		//  set up rx field
		[ rxFrequencyField setStringValue:NSLocalizedString( @"Off", nil ) ] ;
		[ rxFrequencyField setAction:@selector( rxFieldChanged ) ] ;
		[ rxFrequencyField setTarget:self ] ;
		//  set up tx field
		[ txFrequencyField setStringValue:@"" ] ;
		[ txFrequencyField setAction:@selector( txFieldChanged ) ] ;
		[ txFrequencyField setTarget:self ] ;
		//  tx light
		[ self setTransmitLightState:TxOff ] ;
		return YES ;
	}
	return NO ;
}

- (id)initIntoView:(NSView*)view client:(Modem*)modem index:(int)index
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
	
		//  v0.70
		useShiftJIS = useRawOutput = NO ;
		doubleByteIndex = 0 ;
		lastASCII = -1 ;
		//  v0.57b -- PSKDemodulator is now behind the PSKHub
		pskHub = [ [ PSKHub alloc ] initHub ] ;
		[ pskHub setDelegate:self ] ;
				
		pskBrowserHub = nil ;
		if ( index == 0 ) {
			pskBrowserHub = [ [ PSKBrowserHub alloc ] initHub ] ;
			[ pskBrowserHub setDelegate:self ] ;
		}
		delayedRelease = nil ;

		//  local CMDataStream
		cmData.samplingRate = 11025.0 ;
		cmData.samples = 512 ;
		cmData.components = 1 ;
		cmData.channels = 1 ;
		data = &cmData ;
	
		uniqueID = index ;
		client = modem ;
		[ pskHub setPSKModem:(PSK*)modem index:uniqueID ] ;				//	v0.78 hub passes the modem and uniqueID (0,1) to the mainDemoodulator

		slashZero = NO ;
		extendedASCII = YES ;
		txOff = [ NSColor colorWithCalibratedWhite:0.5 alpha:1.0 ] ;
		txReady0 = [ NSColor greenColor ] ; 
		txReady1 = [ NSColor magentaColor ] ; 
		txWait = [ NSColor yellowColor ] ; 
		txActive = [ NSColor redColor ]  ;
		
		displayedRxFrequency = displayedTxFrequency = -1 ;
		receiveView = nil ;
		control = nil ;
		appleScript = nil ;
		squelchHold = 0 ;
		
		mux = 0 ;
		transferToTransmitFreq = YES ;
		
		//  create history buffer (blocks of 512 samples)
		clickBufferProducer = clickBufferConsumer = 0 ;				//  buffer number (512 samples per buffer)
		clickBufferLock = [ [ NSLock alloc ] init ] ;
		for ( i = 0; i < 512; i++ ) {
			// 1 MB buffer, for 262,144 floating point samples (23.77 seconds)
			clickBuffer[i] = (float*)malloc( 512*sizeof( float ) ) ;	
		}		
		overrunLock = [ [ NSLock alloc ] init ] ;
		lock = [ [ NSLock alloc ] init ] ;
		newData = [ [ NSConditionLock alloc ] initWithCondition:kNoData ] ;

		[ NSThread detachNewThreadSelector:@selector(receiveThread:) toTarget:self withObject:self ] ;
		if ( [ self loadReceiver:view index:index ] ) return self ;
	}
	return nil ;
}

//  v0.70
- (void)setUseShiftJIS:(Boolean)state
{
	useShiftJIS = state ;
	[ pskBrowserHub setUseShiftJIS:state ] ;	//  for TableView printing
}

//  v0.70
- (Boolean)useShiftJIS
{
	return useShiftJIS ;
}

//  v0.70
- (void)setUseRawForPSK:(Boolean)state
{
	useRawOutput = state ;
}

//	v0.70
- (void)setJisToUnicodeTable:(unsigned char*)uarray
{
	memcpy( jisToUnicode, uarray, 65536*2 ) ;
	[ pskBrowserHub setJisToUnicodeTable:uarray ] ;
}

//	v0.70
- (void)setUnicodeToJisTable:(unsigned char*)uarray
{
	memcpy( unicodeToJis, uarray, 65536*2 ) ;
}

- (PSK*)controlModem		//  v0.57b
{
	return (PSK*)client ;
}

- (void)enableTableView:(Boolean)state
{
	if ( state == YES ) [ pskBrowserHub enableTableView ] ; else [ pskBrowserHub disableTableView ] ;				//  v0.97
}

//	v0.97
- (void)nextStationInTableView
{
	[ pskBrowserHub nextStationInTableView ] ;
}

//	v1.01c
- (void)previousStationInTableView
{
	[ pskBrowserHub previousStationInTableView ] ;
}

- (void)awakeFromNib
{
	if ( uniqueID == 0 && pskBrowserHub ) {
		[ pskBrowserHub setBrowserTable:browserTable ] ;
	}
}

//	v0.89
- (void)clearClickBuffer
{
	if ( clickBuffer != nil ) {
		[ clickBufferLock lock ] ;
		clickBufferProducer = clickBufferConsumer = 0 ;
		[ clickBufferLock unlock ] ;
	}
}

//	sends output of click buffer to PSKHub
- (void)receiveThread:(id)ourself
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	int i ;

	[ NSThread setThreadPriority:[ NSThread threadPriority ]*0.95 ] ;			//  lower thread priority
	
	while ( 1 ) {
		// block here waiting for data	
		[ newData lockWhenCondition:kHasData ] ;
		if ( [ pskHub demodulatorEnabled ] ) {
			//  copy the stream info but use the buffered data, and set the pointer to the click buffer
			//  process 8 click buffers as fast as possible until the stream has caught up
			for ( i = 0; i < 8; i++ ) {
				if ( clickBufferConsumer == clickBufferProducer ) break ;
				//  push out unprocessed data
				cmData.array = clickBuffer[clickBufferConsumer] ;
				clickBufferConsumer = ( clickBufferConsumer+1 ) & 0x1ff ; // wrap around a 256K (512*512 sample) buffer
				[ pskHub importData:self ] ;
			}
			if ( clickBufferConsumer == 0 ) {
				//  periodically (about once every 30 seconds) flush the Autorelease pool
				
				//	v0.76 : don't drain pool in Snow Leopard
				SInt32 systemVersion = 0 ;
				Gestalt( gestaltSystemVersionMinor, &systemVersion ) ;
		
				if ( systemVersion < 6 /* before snow leopard */ ) {
					if ( delayedRelease != nil ) [ delayedRelease drain ] ;		// v0.57b
					delayedRelease = pool ;
					pool = [ [ NSAutoreleasePool alloc ] init ] ;
				}
			}
		}
		[ newData unlockWithCondition:kNoData ] ;			//  v0.62
	}
	[ pool release ] ;
}

//	audio data is sent here from PSK.m
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	float *array, *buf ;
	
	if ( [ overrunLock tryLock ] ) {
		[ newData lockWhenCondition:kNoData ] ;
		buf = clickBuffer[clickBufferProducer] ;
		clickBufferProducer = ( clickBufferProducer+1 ) & 0x1ff ; // wrap around a 256K (512*512 sample) buffer
	
		if ( pskBrowserHub ) {
			//  TableView
			float *hubBuf = clickBuffer[ ( clickBufferProducer - 9 + 0x200 )&0x1ff ] ;
			[ pskBrowserHub importBuffer:hubBuf ] ;
		}
	
		//  copy data into tail of clickBuffer
		stream = [ pipe stream ] ;
		array = stream->array ;
		//  copy another 512 samples into the click buffer
		memcpy( buf, array, 512*sizeof( float ) ) ;
		//  run the receive thread
		cmData.userData = stream->userData ;
		cmData.sourceID = stream->sourceID ;
		// signal receiveThread of new block of data that new data has arrived
		[ newData unlockWithCondition:kHasData ] ;
		[ overrunLock unlock ] ;
	}
}

- (void)useSlashedZero:(Boolean)state
{
	slashZero = state ;
}

- (Boolean)isEnabled
{
	return [ pskHub demodulatorEnabled ] ;
}
	
- (void)setExchangeView:(ExchangeView*)eview
{
	receiveView = eview ;
}

- (void)registerModule:(Module*)module
{
	appleScript = module ;
}

- (void)enableReceiver:(Boolean)state
{
	[ pskHub enableReceiver:state ] ;
	if ( pskBrowserHub ) [ pskBrowserHub enableReceiver:state ] ;
	if ( state == NO ) {
		[ freqIndicator clear ] ;
		[ phaseIndicator clear ] ;
		[ rxFrequencyField setStringValue:NSLocalizedString( @"Off", nil ) ] ;
		[ txFrequencyField setStringValue:@"" ] ;
		[ IMDField setStringValue:@"" ] ;
		[ [ client application ] clearVoiceChannel:uniqueID+1 ] ;		//  v0.96d	voice synthesizer
	}
	//  update indicator light
	[ self setTransmitLightState:indicatorState ] ;
}

- (float)currentTransmitFrequency
{
	return transmitFrequency ;
}

- (void)setPSKControl:(PSKControl*)inControl
{
	control = inControl ;
}

- (void)displayFrequency:(float)freq on:(NSTextField*)field
{
	[ field setStringValue:[ NSString stringWithFormat:@"%.1f", freq ] ] ;
}

//  called from NewPSKDemodulator when AFC updates
- (void)setReceiveFrequency:(float)freq
{
	[ self displayFrequency:freq on:rxFrequencyField ] ;
}

- (void)updateReceiveFrequencyDisplay:(float)tone
{
	int p ;
	float freq ;
	
	freq = ( sideband ) ? tone-vfoOffset : vfoOffset-tone ;
	p = freq*10 ;
	freq = p*0.1 ;
	if ( freq != displayedRxFrequency ) {
	if ( [ rxFrequencyField floatValue ] != freq ) [ self displayFrequency:freq on:rxFrequencyField ] ;
		[ (PSK*)client frequencyUpdatedTo:tone receiver:uniqueID ] ;
	}
	displayedRxFrequency = freq ;
}

- (void)updateTransmitFrequencyDisplay:(float)tone
{
	int p ;
	float freq ;
		
	freq = ( sideband ) ? tone-vfoOffset : vfoOffset-tone ;
	p = freq*10 ;
	freq = p*0.1 ;
	if ( freq != displayedTxFrequency ) {
		[ self displayFrequency:freq on:txFrequencyField ] ;
	}
	displayedTxFrequency = freq ;
}

//  check if transmit is within range
- (Boolean)canTransmit
{
	return ( [ pskHub demodulatorEnabled ] && transmitFrequency > 250 && transmitFrequency < 4800 ) ;		// v0.68
}

- (void)setTransmitLightState:(int)state
{
	NSColor *color ;
	
	indicatorState = state ;
	if ( ![ self canTransmit ] ) color = txOff ;
	else {
		switch ( state ) {
		default:
		case TxOff:
			color = txOff ;
			break ;
		case TxReady:
			color = ( uniqueID == 0 ) ? txReady0 : txReady1 ;   //  0 - Green, 1 - Magenta
			break ;
		case TxWait:
			color = txWait ;
			break ;
		case TxActive:
			color = txActive ;
			break ;
		}
	}
	[ transmitLight setBackgroundColor:color ] ;
}

//  callback from VCO
- (void)vcoChangedTo:(float)vcoFreq
{
	float tone ;
	
	tone = vcoFreq ;
	[ pskHub setReceiveFrequency:tone ] ;
	[ self updateReceiveFrequencyDisplay:tone ] ;
}

- (void)setPSKMode:(int)mode
{
	[ pskHub setPSKMode:mode ] ;
}

//  0.64e  - set click buffer offset
- (void)setTimeOffset:(float)history
{
	//  set up where in click buffer to use
	if ( history < 0.1 ) history = 0.1 ;
	if ( history > 20.0 ) history = 20.0 ;
	
	[ clickBufferLock lock ] ;
	clickBufferConsumer = clickBufferProducer + ( 512 - (int)( 21.5*history ) ) ;
	clickBufferConsumer = clickBufferConsumer & 0x1ff ; // wrap around a 256K sample (512*512 samples) floating point buffer
	[ clickBufferLock unlock ] ;	
}

- (void)selectFrequency:(float)freq secondsAgo:(float)history fromWaterfall:(Boolean)fromWaterfall
{
	[ self setTimeOffset:history ] ;
	squelchHold = 0 ;
	transferToTransmitFreq = fromWaterfall ;
	if ( fromWaterfall ) {	
		//  clear indicators
		[ freqIndicator clear ] ;
		[ phaseIndicator clear ] ;	
		[ IMDField setStringValue:@"" ] ;	
	}
	[ self updateReceiveFrequencyDisplay:freq ] ;
	//  set up transmit VCO here if clicked from waterfall
	if ( fromWaterfall ) [ self setTransmitFrequencyToTone:freq ] ;
	[ self setTransmitLightState:indicatorState ] ;
	[ pskHub selectFrequency:freq fromWaterfall:fromWaterfall ] ;
	[ [ client application ] clearVoiceChannel:uniqueID+1 ] ;		//  v0.96d	voice synthesizer
}

//  display PSK Monitor
- (void)showScope
{
	[ monitor showWindow ] ;
}

- (void)hideScopeOnDeactivation:(Boolean)hide
{
	[ monitor hideScopeOnDeactivation:hide ] ;
}

- (void)setVFOOffset:(float)offset sideband:(Boolean)polarity
{
	vfoOffset = offset ;
	sideband = polarity ;
	[ freqIndicator setSideband:( sideband ) ? 1 : 0 ] ;
	
	if ( pskBrowserHub ) [ pskBrowserHub setVFOOffset:offset sideband:polarity ] ;
}

- (void)setTransmitFrequencyToReceiveFrequency
{
	float tone ;
	
	tone = [ pskHub receiveFrequency ] ;
	if ( tone > 10.5 ) [ self setTransmitFrequencyToTone:tone ] ;
}

- (void)setTransmitFrequencyToTone:(float)tone
{
	//  set transmit freq (actual tone frequency, no offset)
	[ self updateTransmitFrequencyDisplay:tone ] ;
	transmitFrequency = tone ;
	[ self setTransmitLightState:indicatorState ] ;
}

- (void)setFrequencyDefined
{
	[ (PSK*)client setFrequencyDefined ] ;
}

/* local */
- (float)setRxOffset:(float)freq
{
	float tone ;
	
	tone = ( sideband ) ? freq+vfoOffset : vfoOffset-freq ;
	if ( freq != displayedRxFrequency ) {
		displayedRxFrequency = freq ;
		[ (PSK*)client receiveFrequency:tone setBy:uniqueID ] ;
	}
	return tone ;
}

/* local */
- (float)setRxTone:(float)tone
{
	float freq ;
	
	freq = ( sideband ) ? tone-vfoOffset : vfoOffset-tone ;
	if ( freq != displayedRxFrequency ) {
		displayedRxFrequency = freq ;
		[ (PSK*)client receiveFrequency:tone setBy:uniqueID ] ;
	}
	return freq ;
}

/* local */
- (float)setTxOffset:(float)freq
{
	float tone ;
	
	tone = ( sideband ) ? freq+vfoOffset : vfoOffset-freq ;
	if ( freq != displayedTxFrequency ) {
		displayedTxFrequency = freq ;
		[ self setTransmitFrequencyToTone:tone ] ;
	}
	return tone ;
}

/* local */
- (float)setTxTone:(float)tone
{
	float freq ;
	
	freq = ( sideband ) ? tone-vfoOffset : vfoOffset-tone ;
	if ( freq != displayedTxFrequency ) {
		displayedTxFrequency = freq ;
		[ self setTransmitFrequencyToTone:tone ] ;
	}
	return freq ;
}

- (void)setAndDisplayRxOffset:(float)freq
{
	[ self setRxOffset:freq ] ;
	[ rxFrequencyField setStringValue:[ NSString stringWithFormat:@"%.1f", freq ] ] ;
}

- (void)setAndDisplayRxTone:(float)tone
{
	float freq ;
	
	freq = [ self setRxTone:tone ] ;
	[ rxFrequencyField setStringValue:[ NSString stringWithFormat:@"%.1f", freq ] ] ;
}

- (void)setAndDisplayTxOffset:(float)freq
{
	[ self setTxOffset:freq ] ;
	[ txFrequencyField setStringValue:[ NSString stringWithFormat:@"%.1f", freq ] ] ;
}

- (void)setAndDisplayTxTone:(float)tone
{
	float freq ;
	
	freq = [ self setTxTone:tone ] ;
	[ txFrequencyField setStringValue:[ NSString stringWithFormat:@"%.1f", freq ] ] ;
}

- (float)rxTone
{
	float tone ;
	
	if ( displayedRxFrequency < 0 ) return -1.0 ;
	
	tone = ( sideband ) ? displayedRxFrequency+vfoOffset : vfoOffset-displayedRxFrequency ;
	return tone ;
}

- (float)rxOffset
{
	return displayedRxFrequency ;
}

- (float)txOffset
{
	return displayedTxFrequency ;
}

- (float)txTone
{
	float tone ;
	
	if ( displayedTxFrequency < 0 ) return -1.0 ;

	tone = ( sideband ) ? displayedTxFrequency+vfoOffset : vfoOffset-displayedTxFrequency ;
	return tone ;
}

- (void)rxFieldChanged
{
	[ self setRxOffset:[ rxFrequencyField floatValue ] ] ;
}

- (void)txFieldChanged
{
	[ self setTxOffset:[ txFrequencyField floatValue ] ] ;
}

//  delegate of CMPSKMatchedFilter
- (void)updatePhase:(float)phase
{
	[ phaseIndicator newPhase:phase ] ;
}

//  delegate of CMPSKMatchedFilter
- (void)receivedCharacter:(int)c spectrum:(float*)spectrum
{
	printf( "PSKReceiver: receivedCharacter:spectrum deprecated\n" ) ;
	exit( 0 ) ;
	
	#ifdef DEPRECATED
	int decoded ;
	float inBand, outOfBand, squelch ;
	char buffer[2] ;
	

	c &= 0xff ;
	if ( c == '\n' ) c = '\r' ;			// v0.44 some programs are sending line feeds for carriage returns
	
	squelch = 1.0 - [ control squelchValue ] ;
	if ( squelch < .01 ) {
		squelchHold = 0 ;
	}
	else {
		inBand = spectrum[0]+spectrum[2]+spectrum[4]+spectrum[6]+spectrum[8] ;
		outOfBand = spectrum[11]+spectrum[12]+spectrum[13] ;
	
		if ( inBand < squelch*10*outOfBand ) {
			squelchHold = 2 ;
			return ;
		}
		if ( squelchHold > 0 ) squelchHold-- ;
		if ( squelchHold > 0 ) return ;
	}
	decoded = [ self printable:c extended:extendedASCII ] ;
	if ( receiveView && decoded != 0 ) {
		if ( appleScript ) [ appleScript insertBuffer:decoded ] ;
		if ( decoded == '0' && slashZero ) decoded = Phi ;
		buffer[0] = decoded ;
		buffer[1] = 0 ;
		[ receiveView append:buffer ] ;
	}
	#endif
}

//  v0.57 -- new -receivedCharacter that has quality of character
//  delegate of CMPSKMatchedFilter
- (void)receivedCharacter:(int)c spectrum:(float*)spectrum quality:(float)quality
{
	int decoded ;
	unichar uch ;
	float q, squelch ;
	char buffer[64] ;
	Boolean isShiftJISCharacter ;
	
	c &= 0xff ;

	//  check squelch -- used to squelch print byut not decoding
	squelch = 1-[ control squelchValue ] ;
	if ( squelch < 0.05 ) {
		squelchHold = 0 ;
	}
	else {
		//  v0.57 -- use character quality
		//	quality of 0.3 - 0.4 appears to print fine most of the time
		q = quality*1.1 ;
		if ( q < squelch ) squelchHold = 2 ; else if ( squelchHold > 0 ) squelchHold-- ;
	}
	//  v0.70 - raw output
	if ( useRawOutput ) {
		if ( squelchHold > 0 ) return ;
		sprintf( buffer, "<%02x>", c ) ;
		[ receiveView append:buffer ] ;
		return ;
	}

	//  double byte output
	if ( useShiftJIS ) {
		if ( doubleByteIndex == 0 ) {
			//  validate that it is the first byte of Shift-JIS
			isShiftJISCharacter = YES ;
			if ( !( c >= 0x81 && c <= 0x84 ) ) {
				if ( !( c >= 0x87 && c <= 0x9f ) ) {
					if ( !( c >= 0xe0 && c <= 0xea ) ) {
						if ( !( c >= 0xed && c <= 0xee ) ) isShiftJISCharacter = NO ;
					}
				}
			}
			if ( isShiftJISCharacter == NO ) {
				//  Not a first byte for Shift-JIS, decode as ASCII...
				//  Check squelch first -- squelch a character away while the squelch is being held
				if ( squelchHold > 0 ) return ;

				decoded = [ self printable:c extended:extendedASCII ] ;
				if ( decoded != 0 ) {
					if ( appleScript ) [ appleScript insertBuffer:decoded ] ;
					if ( decoded == '0' && slashZero ) decoded = Phi ;
					buffer[0] = decoded ;
					buffer[1] = 0 ;
					[ receiveView append:buffer ] ;
				}
				return ;
			}
			lastASCII = -1 ;
			doubleByteValue[0] = c ;
			doubleByteIndex++ ;
			return ;
		}
		else {
			lastASCII = -1 ;
			c = doubleByteValue[0]*256 + c ;
			doubleByteIndex = 0 ;
		}
	}
	if ( c == '\n' ) c = '\r' ;			// v0.44 some programs are sending line feeds for carriage returns
	
	//  Squelch a character away while the squelch is being held
	//  NOTE: if a character is busted, the likelihood is that the sync is bad, so we squelch past the next character's (more likely correct) sync.
	if ( squelchHold > 0 ) return ;
	
	if ( useShiftJIS ) {
		uch = jisToUnicode[c*2]*256 + jisToUnicode[c*2+1] ;
		if ( uch >= 0xffff ) {
			//  error in table lookup!
			buffer[0] = '.' ;
			buffer[1] = 0 ;
			[ receiveView append:buffer ] ;
			return ;
		}
		[ receiveView appendUnicode:uch ] ;
		return ;
	}
	//  single byte case
	decoded = [ self printable:c extended:extendedASCII ] ;
	if ( receiveView && decoded != 0 ) {
		if ( appleScript ) [ appleScript insertBuffer:decoded ] ;
		if ( decoded == '0' && slashZero ) decoded = Phi ;
		buffer[0] = decoded ;
		buffer[1] = 0 ;
		[ receiveView append:buffer ] ;
		[ [ client application ] addToVoice:decoded channel:uniqueID+1 ] ;		//  v0.96d	voice synthesizer
	}
}

- (IBAction)browserSquelchChanged:(id)sender
{
	if ( pskBrowserHub ) [ pskBrowserHub squelchChanged:sender ] ;
}

- (IBAction)browserSquelchRescan:(id)sender
{
	if ( pskBrowserHub ) [ pskBrowserHub rescan ] ;
}

- (IBAction)browserSetAlarm:(id)sender
{
	if ( pskBrowserHub ) [ pskBrowserHub openAlarm ] ;
}

//  this button is hidden in released version
- (IBAction)testCheck:(id)sender
{
	if ( pskBrowserHub ) [ pskBrowserHub testCheck ] ;
}

- (void)useControlButton:(Boolean)state
{
	if ( pskBrowserHub ) [ pskBrowserHub useControlButton:state ] ;
}

- (void)updateVisibleState:(Boolean)visible
{
	if ( pskBrowserHub ) [ pskBrowserHub updateVisibleState:visible ] ;
}

//  delegate to CMPSKDemodulator
- (void)newSpectrum:(DSPSplitComplex*)buf size:(int)length
{
	//  v0.57 full spectrum arrives (used to be demux here)
	[ freqIndicator newSpectrum:buf size:length ] ;
}

//  delegate to CMPSKDemodulator
- (Boolean)afcEnabled
{
	return [ control afcEnabled ] ;
}

//  delegate to CMPSKDemodulator
- (float)squelchValue
{
	return [ control squelchValue ] ;
}

//  delegate to CMPSKDemodulator
- (void)updateDisplayFrequency:(float)tone
{
	[ self updateReceiveFrequencyDisplay:tone ] ;
}

//  delegate to CMPSKDemodulator
//  v0.57 -- change snr behavior
//		snr < 0 = clear
//		snr > imd noise limited
//		snr < imd good reading
- (void)updateIMD:(float)imd snr:(float)snr
{
	int n ;
	
	if ( snr < 0 ) {
		[ IMDField setStringValue:@"" ] ;	// clear IMD field
		return ;
	}
	if ( imd < -0.1 ) {
		[ IMDField setStringValue:@"NL" ] ;					//  "noise limited"
		return ;
	}
	n = 10*log10( imd ) - 0.5 ;		//  quantize to 1 dB steps
	if ( fabs( snr ) > fabs( imd ) ) {
		[ IMDField setStringValue:[ NSString stringWithFormat:@"%d", n ] ] ;
	}
	else {
		[ IMDField setStringValue:[ NSString stringWithFormat:@"%d*", n ] ] ;
	}
}

//  delegate to CMPSKDemodulator
- (void)setTransmitFrequency:(float)tone
{
	if ( transferToTransmitFreq ) {
		[ self setTransmitFrequencyToTone:(float)tone ] ;
	}
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *str ;
	
	str = [ pref stringValueForKey:kPSKBrowserWindowPosition ] ;
	if ( str && uniqueID == 0 ) [ [ browserTable window ] setFrameFromString:str ] ;
	str = [ pref stringValueForKey:kPSKBrowserSquelch ] ;
	if ( str && uniqueID == 0 ) [ browserSquelch setFloatValue:[ str floatValue ] ] ;
	if ( uniqueID == 0 && pskBrowserHub != nil ) [ pskBrowserHub updateFromPlist:pref ] ;

	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	if ( uniqueID == 0 ) {
		[ pref setString:[ [ browserTable window ] stringWithSavedFrame ] forKey:kPSKBrowserWindowPosition ] ;
		[ pref setString:[ NSString stringWithFormat:@"%.3f", [ browserSquelch floatValue ] ] forKey:kPSKBrowserSquelch ] ;
		if ( pskBrowserHub != nil ) [ pskBrowserHub retrieveForPlist:pref ] ;
	}
}

@end
