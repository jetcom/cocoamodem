//
//  LitePSKDemodulator.m
//  cocoaModem 2.0  v0.57b
//
//  Created by Kok Chen on 10/19/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "LitePSKDemodulator.h"
#import "PSKBrowserHub.h"

@implementation LitePSKDemodulator

- (id)initWithClient:(PSKBrowserHub*)client uniqueID:(int)uid 
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		hub = client ;
		frequency = 0 ;
		state = kDemodulatorIdle ;
		uniqueID = uid ;
		userIndex = -1 ;		// negative if a row in the TableViews has not yet been assigned
		decodeOffset = 0 ;
		mark = 0 ;
		doubleByteIndex = 0 ;
		
		//printf( "LitePSKDemodulator initialized with id = %d\n", uid ) ;
				
		removeCount = 0 ;
		// VCO
		vco = [ [ VCO8k alloc ] init ] ;
		[ vco setCarrier:frequency ] ;
		//  decimation filter (8000 s/s input, 1000 s/s output)
		decimateFilter = CMComplexFIRDecimateWithCutoff( 8, 31.25*0.91, 8000.0, 512 ) ;
		//  comb filter to extract clock
		previousClockSample = 0.0 ;
		comb = CMFIRCombFilter( 31.25, 8000.0/8, 2048, 0.1 ) ;
		//  Matched filter
		matchedFilter = [ [ LitePSKMatchedFilter alloc ] initWithClient:self ] ;
		[ matchedFilter setDelegate:self ] ;
		//  Varicode decoder
		varicode = [ [ CMVaricode alloc ] init ] ;
		varicodeCharacter = 0 ;
		//  afc
		cycle = 0 ;
		freqError = 0 ;
		for ( i = 0; i < 32; i++ ) freqErrors[i] = 0 ;
		//  aligned memory for vDSP
		input = CMMallocAnalyticBuffer( 16 ) ;
	}
	return self ;
}

- (void)dealloc
{
	[ VCO8k release ] ;
	[ matchedFilter release ] ;
	[ varicode release ] ;
	CMDeleteFIR( comb ) ;
	CMDeleteComplexFIR( decimateFilter ) ;
	freeAnalyticBuffer( input ) ;
	[ super dealloc ] ;
}

- (void)activateWithFrequency:(float)freq
{
	userIndex = -1 ;
	frequency = freq ;
	[ vco setCarrier:frequency ] ;
	state = kDemodulatorAcquire ;
	removeCount = 0 ;
	disabled = NO ;
}

- (void)afcToFrequency:(float)freq
{
	if ( disabled ) return ;
	
	float old = [ vco frequency ] ;
	frequency = frequency*0.7 + freq*0.3 ;
	if ( fabs( frequency - old ) > 0.027 /* 10 degrees */ ) [ vco setCarrier:frequency ] ;
}

//  return the original userIndex
- (int)setToIdle
{
	int result = userIndex ;
	
	state = kDemodulatorIdle ;
	frequency = 0 ;
	userIndex = -1 ;
	removeCount = 0 ;
	disabled = NO ;
	
	return result ;
}

- (int)uniqueID
{
	return uniqueID ;
}

- (float)frequency
{
	return frequency ;
}

// this is a user settable integer that can be used during searches, etc
- (int)mark
{
	return mark ;
}

- (void)setMark:(int)value
{
	mark = value ;
}

- (void)clearRemoveCount
{
	removeCount = 0 ;
}

- (int)increaseRemoveCount 
{
	removeCount++ ;
	return removeCount ;
}

- (void)decreaseRemovalCount:(int)amount
{
	removeCount -= amount ;
	if ( removeCount <  0 ) removeCount = 0 ;
}

- (int)removeCount 
{
	return removeCount ;
}

//  I-Q mixer
//	Input is an array of 512 real samples at 8000 s/s.
//  Result is placed in the 64 point decimated I/Q buffers where 32 samples represents one chip (31.25 milliseconds for PSK31) of data.
- (void)mix:(float*)array
{
	int i, j, n ;
	float v ;
	CMAnalyticPair pair ;
	
	for ( n = 0; n < 64; n++ ) {
		j = n*8 ;
		for ( i = 0; i < 8; i++ ) {
			v = array[i+j] ;
			//  note:the VCO runs at a rate of Fs
			pair = [ vco nextVCOMixedPair:v ] ;
			input->re[i] = pair.re ;
			input->im[i] = pair.im ;
		}
		pair = CMDecimateAnalyticBuffer( decimateFilter, input, 0 ) ;		//  decimation filter cutoffs are at 100 Hz
		decimatedI[n] = pair.re ;
		decimatedQ[n] = pair.im ;
	}
}

- (void)acquire:(float*)buffer
{
	//printf( "acquired demodulator %d frequency %.0f\n", uniqueID, frequency ) ;
	//  no rough tune, move to decode immediately
	state = kDemodulatorStartDecode ;
	finishedAcquire = NO ;
	acquireCount = 0 ;
	[ matchedFilter setPrintEnable:NO ] ;
}

//  v0.70  adapted to work with Shift-JIS double byte
//  new bit received from Matched Filter
- (void)receivedBit:(int)bit quality:(float)quality
{
	int c ;
	Boolean useShiftJIS, isShiftJISCharacter ;
	
	if ( userIndex < -1 ) return ;
	
	//  wait for start bit
	if ( bit == 0 && varicodeCharacter == 0 ) return ;
	
	varicodeCharacter = varicodeCharacter*2 + bit ;

	if ( ( varicodeCharacter & 0x3 ) == 0 && varicodeCharacter != 0 ) {
	
		if ( ( varicodeCharacter & 0xffffc000 ) == 0 ) {
			c = [ varicode decode:varicodeCharacter ] & 0xff ;
			lastDecoded = c ;
			lastQuality = quality ;
				
			useShiftJIS = [ hub useShiftJIS ] ;

			if ( c != 0 || useShiftJIS ) {
				//  start only when quality is good
				if ( userIndex < 0 && quality > 0.5 ) [ hub demodulator:self startingAtFrequency:frequency ] ;
				
				if ( userIndex >= 0 ) {
					
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
							if ( isShiftJISCharacter == NO && c != 0 ) {
								//  Not a first byte for Shift-JIS, decode as ASCII...  Note, 00 is assumed to be a 0 page of unicode
								if ( c == '\t' || c == '\r' || c == '\n' ) c = ' ' ;
								[ hub demodulator:self newCharacter:c quality:quality frequency:frequency ] ;
								quality = 1.0 ;
								varicodeCharacter = 0 ;
								return ;
							}
							//  buffer up the first byte of a double byte character
							doubleByteValue[0] = c ;
							doubleByteIndex++ ;
						}
						else {
							c = doubleByteValue[0]*256 + c ;
							doubleByteIndex = 0 ;
							if ( c == '\t' || c == '\r' || c == '\n' ) c = ' ' ;
							[ hub demodulator:self newCharacter:c quality:quality frequency:frequency ] ;
						}
						quality = 1.0 ;
						varicodeCharacter = 0 ;
						return ;
					}
					//  not useShiftJIS
					if ( c == '\t' || c == '\r' || c == '\n' ) c = ' ' ;
					[ hub demodulator:self newCharacter:c quality:quality frequency:frequency ] ;
				}
			}
		}
		else removeCount++ ;
		
		quality = 1.0 ;
		varicodeCharacter = 0 ;
	}
}

- (float)quality 
{
	return lastQuality ;
}

- (int)decoded
{
	return lastDecoded ;
}

//  each call has 32 samples of baseband I/Q signal at 1000 samples per second
- (void)processChipBuffer:(float*)inphase quadrature:(float*)quadrature
{
	int i, currentBit ;
	float pi, pq, mag, clockSample, tune ;
	Boolean bitSync ;
	
	for ( i = 0; i < 32; i++ ) {
		pi = inphase[i] ;
		pq = quadrature[i] ;
		mag = pi*pi + pq*pq + .00001 ;
		clockSample = CMSimpleFilter( comb, mag ) ;
		bitSync = ( previousClockSample < 0 && clockSample >= 0 ) ;
		previousClockSample = clockSample ;
		
		currentBit = [ matchedFilter bpsk:pi imag:pq bitSync:bitSync ] ;
		
		if ( bitSync ) {
	
			//  afc track only every 16 chips, except fot acquistion stage
			cycle = ( cycle + 1 ) % 16 ;
			if ( !finishedAcquire ) cycle = 0 ;
			
			freqError += freqErrors[cycle] = ( 31.25/( 3.1415926*2 ) )*[ matchedFilter phaseError ] ;
		
			if ( cycle == 0 ) {
			
				if ( !finishedAcquire ) {
					acquireCount++ ;
					if ( acquireCount > 4 ) {
						[ matchedFilter setPrintEnable:YES ] ;
						finishedAcquire = YES ;
					}
				}
				tune = -freqError*( 3.1415926*0.5/16 ) ; 		//  average data from collected chip
				//  check AFC
				//  look for quality of phase error
				float minerr, maxerr, deltaerr ;
				int e ;
					
				minerr = maxerr = freqErrors[0] ;
				for ( e = 1; e < 16; e++ ) {
					if ( freqErrors[e] > maxerr ) maxerr = freqErrors[e] ;
					if ( freqErrors[e] < minerr ) minerr = freqErrors[e] ;
				}
				deltaerr = maxerr - minerr ;
				if ( deltaerr < 1 ) deltaerr = 1 ;
				//  adjust AFC correction term base on phase error quality
				tune = tune/pow( deltaerr, 0.8 ) ;
				if ( tune > 0.5 ) tune = 0.5 ; else if ( tune < -0.5 ) tune = -0.5 ;
					
				if ( fabs( tune ) > 0.05 ) {
					[ vco tune:tune ] ;
					//  update demodulator frequency
					frequency = [ vco frequency ] ;
				}
				freqError = 0 ;
			}
		}
	}
}

//  This is where the data arrives.
//  Buffers are 512 samples in length, at a sampling rate of 8000 s/s.
//  The buffer has 64 segments of 512 samples each.  the offset index is the index of which of thee 512-sample buffers is the current "real-time" segment.
//  The "old" data is used for "click buffering."
- (void)decode:(float*)buffer offset:(int)index
{
	float *currentBuf ;
	
	if ( disabled ) return ;
	
	if ( state == kDemodulatorAcquire ) {
		currentBuf = &buffer[ index*512 ] ;
		[ self acquire:currentBuf ] ;
		decodeOffset = ( index - 40 + 64 )%64 ;		//  40 buffers worth of click buffer.
		return ;
	}
	// return if state is not in decode
	if ( frequency < 10 ) {
		//printf( "LitePSKDemodulator %d received data while idle??? state = %d frequency = %.0f\n", uniqueID, state, frequency ) ;
		return ;
	}
	//  there are up to 64 512-sample buffers.
	//  In the kDemodulatorStartDecode state, we decode two 512 buffers at a time until we have caught up to the real 
	//   time data, at which point we switch to the kDemodulatorDecode state and process just a 512 real time buffer at a time.
	//
	//  Not that the mixer decimates the data from 512 samples to 64 I/Q samples.  
	//	The chip processor takes 32 I/Q samples at a time, so we send the decimated buffer in two sepate calls per 512 input samples.
	if ( state == kDemodulatorStartDecode ) {
		decodeOffset %= 64 ;
		currentBuf = &buffer[ decodeOffset*512 ] ;
		[ self mix:currentBuf ] ;
		[ self processChipBuffer:decimatedI quadrature:decimatedQ ] ;
		[ self processChipBuffer:decimatedI+32 quadrature:decimatedQ+32 ] ;	
		if ( decodeOffset == index ) {
			state = kDemodulatorDecode ;								//  caught up with mini-click buffer
			return ;
		}
		decodeOffset = ( decodeOffset+1 )%64 ;
	
		currentBuf = &buffer[ decodeOffset*512 ] ;
		[ self mix:currentBuf ] ;
		[ self processChipBuffer:decimatedI quadrature:decimatedQ ] ;
		[ self processChipBuffer:decimatedI+32 quadrature:decimatedQ+32 ] ;	
		if ( decodeOffset == index ) state = kDemodulatorDecode ;		//  caught up with mini-click buffer
		decodeOffset = ( decodeOffset+1 )%64  ;
		return ;
	}
	//  State is kDemodulatorDecode, Decimate and decode current buffer
	currentBuf = &buffer[ index*512 ] ;
	[ self mix:currentBuf ] ;		
	[ self processChipBuffer:decimatedI quadrature:decimatedQ ] ;
	[ self processChipBuffer:decimatedI+32 quadrature:decimatedQ+32 ] ;	
}

- (int)userIndex
{
	return userIndex ;
}

- (void)setUserIndex:(int)index
{
	userIndex = index ;
}

- (int)state
{
	return state ;
}

- (Boolean)disabled
{
	return disabled ;
}

- (void)setDisabled:(Boolean)d
{
	disabled = d ;
}


@end
