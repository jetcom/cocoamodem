//
//  CWMonitor.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/1/06.
	#include "Copyright.h"
	
	
#import "CWMonitor.h"
#import "Application.h"
#import "AuralMonitor.h"
#import "CWReceiver.h"
#import "Plist.h"
#import "WBCW.h"


@implementation CWMonitor

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)init
{
	int i ;
	float t, *kernel ;
	
	self = [ super init ] ;
	if ( self ) {
		modem = nil ;
		receiver[0] = receiver[1] = nil ;
		monitorGain[0] = monitorGain[1] = 1.0 ;
		sideband[0] = sideband[1] = 1 ;		// default initially to USB
		auralMonitor = nil ;
		accumulatedRx = accumulatedTx = 0 ;
		auralLockout = 0 ;
		memset( localLeftBuf, 0, 512*sizeof( float ) ) ;
		memset( localRightBuf, 0, 512*sizeof( float ) ) ;
		
		running = mute = isWide[0] = isWide[1] = isPano[0] = isPano[1] = NO ;
		isEnabled[0] = isEnabled[1] = NO ;
		allowSidetone[0] = allowSidetone[1] = NO ;
		mainChannels = subChannels = txChannels = 3 ;
		agcGain[0] = agcGain[1] = 0.3 ;
		activeState = modemVisible = NO ;
		
		//  this smooths out the transitions when switched between Tx and Rx
		//  should be at least as wide as the wideband passband
		leftRxFilter = CMFIRLowpassFilter( 2400.0, CMFs, 64 ) ;			//  v0.88 separated Rx from Tx filters
		rightRxFilter = CMFIRLowpassFilter( 2400.0, CMFs, 64 ) ;			//	v0.88
		leftTxFilter = CMFIRLowpassFilter( 2400.0, CMFs, 64 ) ;			//  v0.88 separated Rx from Tx filters
		rightTxFilter = CMFIRLowpassFilter( 2400.0, CMFs, 64 ) ;			//	v0.88
		panoReversed = NO ;
		
		transmitSidetone = [ [ CMPCO alloc ] init ] ;
		[ transmitSidetone setOutputScale:1.0 ] ;
		[ transmitSidetone setCarrier:650 ] ;
		txSidetoneState = YES ;
		transmitState = NO ;
		
		//  create low and high pass filters for pano mode (sinc^2 impluse response to get tent LPF)
		panoLow = CMFIRLowpassFilter( 880, CMFs, 256 ) ;
		kernel = panoLow->kernel ;
		for ( i = 0; i < panoLow->activeTaps; i++ ) kernel[i] = kernel[i]*kernel[i]*4.0 ;
		panoHigh = CMFIRLowpassFilter( 880, CMFs, 256 ) ;
		for ( i = 0; i < panoHigh->activeTaps; i++ ) {
			t = fabs( i-panoHigh->activeTaps*0.5 )*2.0*3.1415926535*2400.0/CMFs ;	// center highpass at 2400 Hz
			panoHigh->kernel[i] = kernel[i]*cos( t ) ;
		}
	}
	return self ;
}

- (void)awakeFromNib
{
	[ self setInterface:txPitch to:@selector(sidetoneFrequencyChanged) ] ;
	[ self setInterface:txSidetoneEnable to:@selector(sidetoneFrequencyChanged) ] ;
	[ self setInterface:mainPitch to:@selector(sidetoneFrequencyChanged) ] ;
	[ self setInterface:subPitch to:@selector(sidetoneFrequencyChanged) ] ;
	[ self setInterface:mainChannel to:@selector(channelSelectionChanged) ] ;
	[ self setInterface:subChannel to:@selector(channelSelectionChanged) ] ;
	[ self setInterface:txChannel to:@selector(channelSelectionChanged) ] ;
	[ self setInterface:panoSeparation to:@selector(panoParamsChanged) ] ;
	[ self setInterface:panoBalance to:@selector(panoParamsChanged) ] ;
	[ self setInterface:panoReverseCheckbox to:@selector(panoParamsChanged) ] ;
	[ self setInterface:activeButton to:@selector(activeChanged) ] ;
}

- (void)setupMonitor:(NSString*)deviceName modem:(WBCW*)cwModem main:(CWReceiver*)main sub:(CWReceiver*)sub
{
	Application *application ;
	
	modem = cwModem ;
	receiver[0] = main ;
	receiver[1] = sub ;
	
	application = [ modem application ] ;	
	if ( application ) {
		//  fetch the common aural monitor
		auralMonitor = [ application auralMonitor ] ;
	}
}

- (void)sidetoneFrequencyChanged
{
	[ receiver[0] setSidetoneFrequency:[ mainPitch floatValue ] ] ;
	[ receiver[1] setSidetoneFrequency:[ subPitch floatValue ] ] ;
	//  set tx pitch to 0 to disable
	txSidetoneState = ( [ txSidetoneEnable state ] == NSOnState ) ;
	[ transmitSidetone setCarrier:[ txPitch floatValue ] ] ;
}

//  the tag of the menu item carries the two bits to lelect left (0x01) or right (0x02) [or both bits set]
- (void)channelSelectionChanged
{
	mainChannels = [ [ mainChannel selectedItem ] tag ] ;
	subChannels = [ [ subChannel selectedItem ] tag ] ;
	txChannels = [ [ txChannel selectedItem ] tag ] ;
}

- (void)panoParamsChanged
{
	separation = [ panoSeparation floatValue ] ;
	balance = [ panoBalance floatValue ] ;
	panoReversed = ( [ panoReverseCheckbox state ] == NSOnState ) ;
}

- (void)updateSoundState
{
	Boolean state ;
	
	if ( auralMonitor == nil ) return ;
	
	state = ( ( allowSidetone[0] && isEnabled[0] ) || ( allowSidetone[1] && isEnabled[1] ) ) && activeState && modemVisible ;

	if ( state == YES ) {
		if ( running ) return ;
		running = YES ;
		[ auralMonitor addClient:self ] ; 
	}
	else {
		if ( !running ) return ;
		running = NO ;
		[ auralMonitor removeClient:self ] ; 
	}
}

- (void)activeChanged
{
	activeState = ( [ activeButton state ] == NSOnState ) ;
	[ receiver[0] setMonitorEnable:activeState ] ;
	[ receiver[1] setMonitorEnable:activeState ] ;
	[ activeButton setTitle:( activeState ) ? NSLocalizedString( @"Active", nil ) : NSLocalizedString( @"Inactive", nil ) ] ;
	[ self updateSoundState ] ;
}

- (void)setVisibleState:(Boolean)state
{
	modemVisible = state ;
	[ self updateSoundState ] ;
}

- (void)enableSidetone:(Boolean)state index:(int)n
{
	allowSidetone[n] = state ;
	[ self updateSoundState ] ;
}

- (void)sidebandChanged:(int)state index:(int)n
{
	if ( n >= 0 && n < 2 ) sideband[n] = state ;
}

- (void)setMute:(Boolean)state
{
	mute = state ;
}

- (void)enableWide:(Boolean)state index:(int)n
{
	if ( n >= 0 && n < 2 ) isWide[n] = state ;
}

- (void)enablePano:(Boolean)state index:(int)n
{
	if ( n >= 0 && n < 2 ) isPano[n] = state ;
}

- (void)setEnabled:(Boolean)state index:(int)n
{
	if ( n >= 0 && n < 2 ) isEnabled[n] = state ;
	[ self updateSoundState ] ;
}

- (void)monitorLevel:(float)value index:(int)n
{
	if ( n >= 0 && n < 2 ) monitorGain[n] = value ;
}

//  update agc
void agc( float *buf, int n, float *lowmean, float *highmean )
{
	int i, j, k ;
	float m, p, s, v ;
	
	m = 0 ;
	for ( i = 0; i < n; i++ ) {
		m += fabs( buf[i] ) ;
	}
	m /= n ;
	p = s = m ;
	j = k = 1 ;
	for ( i = 0; i < n; i++ ) {
		v = fabs( buf[i] ) ;
		if ( v > m ) {
			p += v ;
			j++ ;
		}
		else {
			s += v ;
			k++ ;
		}
	}
	p /= j ;
	s /= k ;
	*lowmean = s ;
	*highmean = p ;
}


- (void)addLeft:(float*)leftbuf right:(float*)rightbuf state:(int)pushState
{
	int i ;
	
	if ( accumulatedRx == 0 && accumulatedTx == 0 ) {
		memcpy( localLeftBuf, leftbuf, 512*sizeof( float ) ) ;
		memcpy( localRightBuf, rightbuf, 512*sizeof( float ) ) ;
		if ( pushState == 1 ) accumulatedRx = 1 ; else accumulatedTx = 1 ;
		return ;
	}
	if ( pushState == 1 && accumulatedRx > 0 ) {
		//  flush
		[ auralMonitor addLeft:localLeftBuf right:localRightBuf samples:512 client:self ] ;
		memcpy( localLeftBuf, leftbuf, 512*sizeof( float ) ) ;
		memcpy( localRightBuf, rightbuf, 512*sizeof( float ) ) ;
		accumulatedRx = 1 ;
		accumulatedTx = 0 ;
		return ;
	}
	if ( pushState == 2 && accumulatedTx > 0 ) {
		//  flush
		[ auralMonitor addLeft:localLeftBuf right:localRightBuf samples:512 client:self ] ;
		memcpy( localLeftBuf, leftbuf, 512*sizeof( float ) ) ;
		memcpy( localRightBuf, rightbuf, 512*sizeof( float ) ) ;
		accumulatedRx = 0 ;
		accumulatedTx = 1 ;
		return ;
	}
	if ( ( pushState == 1 && accumulatedTx > 0 ) || ( pushState == 2 && accumulatedRx > 0 ) ) {
		for ( i = 0; i < 512; i++ ) {
			localLeftBuf[i] += leftbuf[i] ;
			localRightBuf[i] += rightbuf[i] ;
		}
		//  flush
		[ auralMonitor addLeft:localLeftBuf right:localRightBuf samples:512 client:self ] ;
		accumulatedRx = accumulatedTx = 0 ;
		return ;
	}
	
	//  flush
	[ auralMonitor addLeft:localLeftBuf right:localRightBuf samples:512 client:self ] ;
	memcpy( localLeftBuf, leftbuf, 512*sizeof( float ) ) ;
	memcpy( localRightBuf, rightbuf, 512*sizeof( float ) ) ;
	accumulatedRx = accumulatedTx = 0 ;
	if ( pushState == 1 ) accumulatedRx = 1 ; else accumulatedTx = 1 ;
}

//	v0.78	aural received changed to push model, using the common AuralMonitor
- (void)push:(float*)inph quadrature:(float*)quad wide:(float*)wide samples:(int)n
{
	int i, offset ;
	float gain, t, v, save, *buf, leftBuf[512], rightBuf[512], leftOutbuf[512], rightOutbuf[512] ;
	
	if ( !running || mute ) {
		//  if not running, return zeros, left channel only
		return ;
	}
	if ( n > 512 ) n = 512 ;											//  sanity check

	if ( isEnabled[0] == NO && isEnabled[1] == NO ) return ;

	//  transmit aural monitor sets auralLockout so both transmit and receive won't be sent to the monitor at the same time
	if ( auralLockout > 0 ) {
		auralLockout-- ;
		if ( auralLockout > 4 ) auralLockout = 4 ;		//  sanity check
		return ;
	}
	
	memset( leftBuf, 0, sizeof(float)*512 ) ;
	memset( rightBuf, 0, sizeof(float)*512 ) ;

		//  main channel
	if ( isEnabled[0] ) {
		if ( isWide[0] && isPano[0] ) {
			// pano (reverse for LSB)
			[ receiver[0] needSidetone:panoBuf inphase:inph quadrature:quad wide:wide samples:n wide:YES ] ;
			CMPerformFIR( panoLow, panoBuf, 512, sidetoneBuf ) ;
			CMPerformFIR( panoHigh, panoBuf, 512, sidetoneBuf+512 ) ;
			
			//  blend for separation
			t = 1.0 - separation ;
			for ( i = 0; i < 512; i++ ) {
				save = sidetoneBuf[i] ;
				sidetoneBuf[i] = separation*sidetoneBuf[i] + t*sidetoneBuf[i+512] ;
				sidetoneBuf[i+512] = separation*sidetoneBuf[i+512] + t*save ;
			}			
			//  left channel
			offset = ( panoReversed ) ? 512 : 0 ;
			gain = monitorGain[0] * ( 1.0 - balance ) ;
			if ( sideband[0] == 0 ) offset = 512-offset ;
			buf = &sidetoneBuf[offset] ;
			for ( i = 0; i < n; i++ ) leftBuf[i] += buf[i]*gain ;
			
			//  right channel
			offset = ( panoReversed ) ? 0 : 512 ;
			gain = monitorGain[0] * ( 1.0 + balance ) ;
			if ( sideband[0] == 0 ) offset = 512-offset ;
			buf = &sidetoneBuf[offset] ;
			for ( i = 0; i < n; i++ ) rightBuf[i] += buf[i]*gain ;
		}
		else {		
			//  non-pano
			[ receiver[0] needSidetone:sidetoneBuf inphase:inph quadrature:quad wide:wide samples:n wide:isWide[0] ] ;
			gain = monitorGain[0]*( ( isWide[0] ) ? 0.316 : ( 0.6/agcGain[0] ) ) ;			// -16 dB for wideband
			
			if ( mainChannels == 0x01 ) {
				// left channel
				for ( i = 0; i < n; i++ ) leftBuf[i] += gain*sidetoneBuf[i] ;
			}
			else if ( mainChannels == 0x02 ) {
				// right channel
				for ( i = 0; i < n; i++ ) rightBuf[i] += gain*sidetoneBuf[i] ;
			}
			else if ( mainChannels == 0x03 ) {
				// left and right channels
				for ( i = 0; i < n; i++ ) {
					v = gain*sidetoneBuf[i] ;
					leftBuf[i] += v ;
					rightBuf[i] += v ;
				}
			}
		}
	}
	//  sub channel
	if ( isEnabled[1] ) {
		if ( isWide[1] && isPano[1] ) {
			// pano (reverse for LSB)
			[ receiver[1] needSidetone:panoBuf inphase:inph quadrature:quad wide:wide samples:n wide:YES ] ;
			CMPerformFIR( panoLow, panoBuf, 512, sidetoneBuf ) ;
			CMPerformFIR( panoHigh, panoBuf, 512, sidetoneBuf+512 ) ;
			
			//  blend for separation
			t = 1.0 - separation ;
			for ( i = 0; i < 512; i++ ) {
				save = sidetoneBuf[i] ;
				sidetoneBuf[i] = separation*sidetoneBuf[i] + t*sidetoneBuf[i+512] ;
				sidetoneBuf[i+512] = separation*sidetoneBuf[i+512] + t*save ;
			}
			//  left channel
			offset = ( panoReversed ) ? 512 : 0 ;
			gain = monitorGain[1] * ( 1.0 - balance ) ;
			if ( sideband[1] == 0 ) offset = 512-offset ;
			buf = &sidetoneBuf[offset] ;
			for ( i = 0; i < n; i++ ) leftBuf[i] += buf[i]*gain ;
			
			//  right channel
			offset = ( panoReversed ) ? 0 : 512 ;
			gain = monitorGain[1] * ( 1.0 + balance ) ;
			if ( sideband[1] == 0 ) offset = 512-offset ;
			buf = &sidetoneBuf[offset] ;
			for ( i = 0; i < n; i++ ) rightBuf[i] += buf[i]*gain ;
		}
		else {
			//  non-pano
			[ receiver[0] needSidetone:sidetoneBuf inphase:inph quadrature:quad wide:wide samples:n wide:isWide[1] ] ;
			gain = monitorGain[1]*( ( isWide[1] ) ? 0.316 : ( 0.6/agcGain[1] ) ) ;			// -16 dB for wideband
			
			if ( subChannels == 0x01 ) {
				// left channel
				for ( i = 0; i < n; i++ ) leftBuf[i] += gain*sidetoneBuf[i] ;
			}
			else if ( subChannels == 0x02 ) {
				// right channel
				for ( i = 0; i < n; i++ ) rightBuf[i] += gain*sidetoneBuf[i] ;
			}
			else if ( subChannels == 0x03 ) {
				// left and right channels
				for ( i = 0; i < n; i++ ) {
					v = gain*sidetoneBuf[i] ;
					leftBuf[i] += v ;
					rightBuf[i] += v ;
				}
			}
		}
	}
	for ( i = 0; i < n; i++ ) leftOutbuf[i] = CMSimpleFilter( leftRxFilter, leftBuf[i] ) ;
	for ( i = 0; i < n; i++ ) rightOutbuf[i] = CMSimpleFilter( rightRxFilter, rightBuf[i] ) ;
	
	[ self addLeft:leftOutbuf right:rightOutbuf state:1 ] ;
}

//	v0.78	transmit sidetone changed to push model, using the common AuralMonitor
- (void)transmitted:(float*)keyed samples:(int)n
{
	int i ;
	float buf[512], leftbuf[512], rightbuf[512] ;
	
	if ( n != 512 ) return ;
	
	auralLockout = 2 ;
	
	if ( !running || mute || txSidetoneState == NO ) {
		//  if not running, no need to push data to aural monitor
		return ;
	}
		
	for ( i = 0; i < 512; i++ ) {
		buf[i] = keyed[i]*[ transmitSidetone nextSample ]*0.1 ;
	}
		
	if ( txChannels & 0x01 ) {
		// left channel
		for ( i = 0; i < 512; i++ ) leftbuf[i] = CMSimpleFilter( leftTxFilter, buf[i] ) ;
	}
	else {
		for ( i = 0; i < 512; i++ ) leftbuf[i] = CMSimpleFilter( leftTxFilter, 0.0 ) ;
	}
	
	//  v0.88 bug fix, was writing into [i+n] instead of [i]
	if ( txChannels & 0x02 ) {
		// right channel
		for ( i = 0; i < 512; i++ ) rightbuf[i] = CMSimpleFilter( rightTxFilter, buf[i] ) ;
	}
	else {
		for ( i = 0; i < 512; i++ ) rightbuf[i] = CMSimpleFilter( rightTxFilter, 0.0 ) ;
	}
	
	[ self addLeft:leftbuf right:rightbuf state:2 ] ;
}

- (void)changeTransmitStateTo:(Boolean)state
{
	transmitState = state ;
}

//  this is no longer needed in the push model
- (int)needData:(float*)outbuf samples:(int)n
{
	NSLog( @"CWMonitor needData called, should no longer be called." ) ;	
	return n ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setInt:650 forKey:kWBCWMainPitch ] ;
	[ pref setInt:750 forKey:kWBCWSubPitch ] ;
	[ pref setInt:700 forKey:kWBCWTransmitPitch ] ;
	[ pref setInt:1 forKey:kWBCWTransmitSidetone ] ;
	[ pref setInt:3 forKey:kWBCWTransmitChannels ] ;
	[ pref setInt:3 forKey:kWBCWMainChannels ] ;
	[ pref setInt:0 forKey:kWBCWSubChannels ] ;
	[ pref setFloat:0.75 forKey:kWBCWPanoSeparation ] ;
	[ pref setFloat:0 forKey:kWBCWPanoBalance ] ;
	[ pref setInt:0 forKey:kWBCWPanoReverse ] ;
	[ pref setInt:0 forKey:kWBCWMonitorActive ] ;
	[ pref setFloat:0 forKey:kWBCWTxSidetoneLevel ] ;
	[ pref setFloat:0 forKey:kWBCWMainSidetoneLevel ] ;
	[ pref setFloat:0 forKey:kWBCWSubSidetoneLevel ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	[ txPitch setIntValue:[ pref intValueForKey:kWBCWTransmitPitch ] ] ;
	[ txSidetoneEnable setIntValue:[ pref intValueForKey:kWBCWTransmitSidetone ] ] ;
	[ mainPitch setIntValue:[ pref intValueForKey:kWBCWMainPitch ] ] ;
	[ subPitch setIntValue:[ pref intValueForKey:kWBCWSubPitch ] ] ;
	[ self sidetoneFrequencyChanged ] ;
	
	[ txChannel selectItemWithTag:[ pref intValueForKey:kWBCWTransmitChannels ] ] ;
	[ mainChannel selectItemWithTag:[ pref intValueForKey:kWBCWMainChannels ] ] ;
	[ subChannel selectItemWithTag:[ pref intValueForKey:kWBCWSubChannels ] ] ;
	[ self channelSelectionChanged ] ;
	
	[ panoSeparation setFloatValue:[ pref floatValueForKey:kWBCWPanoSeparation ] ] ;
	[ panoBalance setFloatValue:[ pref floatValueForKey:kWBCWPanoBalance ] ] ;
	[ panoReverseCheckbox setState: ( [ pref intValueForKey:kWBCWPanoReverse ] ) ? NSOnState : NSOffState ] ;
	[ self panoParamsChanged ] ;
	
	[ activeButton setState:( [ pref intValueForKey:kWBCWMonitorActive ] != 0 ) ? NSOnState : NSOffState ] ;
	[ self activeChanged ] ;

	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	[ pref setInt:[ mainPitch intValue ] forKey:kWBCWMainPitch ] ;
	[ pref setInt:[ subPitch intValue ] forKey:kWBCWSubPitch ] ;
	[ pref setInt:[ txPitch intValue ] forKey:kWBCWTransmitPitch ] ;
	[ pref setInt:( ( [ txSidetoneEnable state ] == NSOnState ) ? 1 : 0 ) forKey:kWBCWTransmitSidetone ] ;

	[ pref setInt:[ [ mainChannel selectedItem ] tag ] forKey:kWBCWMainChannels ] ;
	[ pref setInt:[ [ subChannel selectedItem ] tag ] forKey:kWBCWSubChannels ] ;

	[ pref setFloat:[ panoSeparation floatValue ] forKey:kWBCWPanoSeparation ] ;
	[ pref setFloat:[ panoBalance floatValue ] forKey:kWBCWPanoBalance ] ;
	[ pref setInt:( [ panoReverseCheckbox state ] == NSOnState ) ? 1 : 0 forKey:kWBCWPanoReverse ] ;
	
	[ pref setInt:( [ activeButton state ] == NSOnState ) ? 1 : 0 forKey:kWBCWMonitorActive ] ;
}

- (void)terminate
{
	running = NO ;
	[ auralMonitor removeClient:self ] ;
}

@end
