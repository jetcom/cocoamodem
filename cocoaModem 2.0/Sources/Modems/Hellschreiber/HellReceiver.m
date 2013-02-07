//
//  HellReceiver.m
//  cocoaModem
//
//  Created by Kok Chen on 7/29/05.
	#include "Copyright.h"
//

#import "HellReceiver.h"
#include "Hellschreiber.h"
#include "CMPCO.h"
#include "CoreModemTypes.h"
#include "CMFIR.h"
#include <math.h>

@implementation HellReceiver

- (id)initFromModem:(Modem*)modem
{
	int size, i ;
	float ang ;
	float kernel[36] ;
	
	self = [ super init ] ;
	if ( self ) {
		lock = [ [ NSLock alloc ] init ] ;
		
		mode = HELLFELD ;
		client = modem ;
		//  matched filter (note: vDSP requires length >= 32)
		for ( i = 0; i < 36; i++ ) {
			ang = 2.0*pi*( i + 0.5 )/36.0 ;
			kernel[i] = ( 1.0 - cos( ang ) )*0.5 ;
		}
		iMatchedFilter = CMFIRFilter( kernel, 36 ) ;
		qMatchedFilter = CMFIRFilter( kernel, 36 ) ;
		agc = 1.0 ;
		addedPhase = 0 ;
		sidebandState = NO ;
		
		//  decimation
		size = sizeof( float )*512 ;
		fft = FFTForward( 9, YES ) ;
		//  dual use buffers
		//  used as IF buffers during demodulation
		//  used as FFT buffers during acquisition
		iBuf = (float*)malloc( size ) ;
		qBuf = (float*)malloc( size ) ;			
		iSpec = (float*)malloc( size ) ;
		qSpec = (float*)malloc( size ) ;
		//  derivative IIR memory
		for ( i = 0; i < 3; i++ ) {
			iReg[i] = qReg[i] = iDelay[i] = qDelay[i] = 0 ;
		}
		agc = mag = 1.0 ;
		
		//  demod buffers
		size = sizeof( float )*128 ;	
		iBuf0 = (float*)malloc( size ) ;
		qBuf0 = (float*)malloc( size ) ;			
		iBuf1 = (float*)malloc( size ) ;
		qBuf1 = (float*)malloc( size ) ;
		currentIBuf = iBuf0 ;
		currentQBuf = qBuf0 ;
		inputIndex = outputIndex = 0 ;
		inputPhase = 0.0 ;
		for ( i = 0; i < 256; i++ ) iDemod[i] = qDemod[i] = 0.0 ;
		//  pixel column
		columnPhase = 0 ;
		phaseDecimation = 5.0 ;
		for ( i = 0; i < 32; i++ ) column[i] = 0 ;
		lockedFrequency = 0.0 ;

		//  100 Hz IF filters for I and Q channel
		iFilter = CMFIRLowpassFilter( 100.0, CMFs, 256 ) ;
		qFilter = CMFIRLowpassFilter( 100.0, CMFs, 256 ) ;
	}
	return self ;
}

- (void)setMode:(int)which
{
	float freq ;
	
	mode = which ;
	
	if ( mode == HELLFM245 ) {
		freq = receiveFrequency + 245.0*0.25 ;
		if ( sidebandState ) freq -= 245.0*0.5 ;
	}
	else {
		if ( mode == HELLFM105 ) {
			freq = receiveFrequency + 105.0*0.25 ;
			if ( sidebandState ) freq -= 105.0*0.5 ;
		}
		else freq = receiveFrequency ;
	}
	[ vco setCarrier:freq ] ;	
}

- (void)setSidebandState:(Boolean)state
{
	sidebandState = state ;
	[ self setMode:mode ] ;
}

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall
{
	[ super selectFrequency:freq fromWaterfall:fromWaterfall ] ;
	//  don't use AFC
	lockProcessStarted = NO ;
	frequencyLocked = YES ;
	lockedFrequency = receiveFrequency = freq ;
	[ self setMode:mode ] ;	// set correct frequency
}

- (float)lockedFrequency
{
	return lockedFrequency ;
}

- (Boolean)canTransmit
{
	return ( receiverEnabled && lockedFrequency > 250 && lockedFrequency < 2800 ) ;
}

- (void)importData:(CMPipe*)pipe
{
	switch ( mode ) {
	default:
	case HELLFELD:
		[ self feldImport:pipe ] ;
		break ;
	case HELLFM105:
	case HELLFM245:
		[ self fmImport:pipe ] ;
		break ;
	}
}

//	CW demodulator
- (void)feldImport:(CMPipe*)pipe
{
	CMAnalyticPair pair ;
	CMDataStream *stream ;
	DSPSplitComplex input, output ;
	int i, j, k, peak, count, median, trunc ;
	float *array, v, vPeak ;
	
	if ( !receiverEnabled ) return ;		//  wait for click
	
	stream = [ pipe stream ] ;
	array = stream->array ;
	
	//  decimate and process the 512 original input samples
	//
	//  each Hellschreiber bit is 8.16 ms in duration (122.5 baud), or 90 samples
	//	we decimate by 5 to get 18 samples per bit of information, after mixing with the complex VCO
	
	for ( i = 0; i < 512; i++ ) {
		v = array[i] ;
		pair = [ vco nextVCOPair ] ;
		iMixer[i] = pair.re * v ;
		qMixer[i] = pair.im * v ;
	}
	CMPerformFIR( iFilter, iMixer, 512, iIF ) ;
	CMPerformFIR( qFilter, qMixer, 512, qIF ) ;
	
	if ( 1 || frequencyLocked ) {
		// ignore frequency lock and print right away
		// decimate by 5 (phaseDecimation), giving 18 samples per Feld-Hell bit (9 pixels per half-bit)
		for ( i = 0; i < 512; i++ ) {
			currentIBuf[outputIndex] = iIF[inputIndex] ;
			currentQBuf[outputIndex] = qIF[inputIndex] ;
			outputIndex++ ;
			
			if ( addedPhase ) {
				if ( addedPhase > 0 && outputIndex < 100 ) {
					for ( j = 0; j < 3; j++ ) {
						currentIBuf[outputIndex] = currentQBuf[outputIndex] = 0 ;
						outputIndex++ ;
					}
					addedPhase-- ;
				}
				if ( addedPhase < 0 && outputIndex > 32 ) {
					outputIndex -= 3 ;
					addedPhase++ ;
				}
			}
			
			inputPhase += phaseDecimation ;
			trunc = inputPhase ;
			inputPhase -= trunc ;
			inputIndex += trunc ;
			
			if ( outputIndex >= 126 ) {
				//  send to demodulator when we have enough samples
				[ self feldDemodulate:currentIBuf quadrature:currentQBuf length:126 ] ;
				//  select next buffer
				if ( currentIBuf == iBuf0 ) {
					currentIBuf = iBuf1 ;
					currentQBuf = qBuf1 ;
				}
				else {
					currentIBuf = iBuf0 ;
					currentQBuf = qBuf0 ;
				}
				outputIndex = 0 ;
			}
			if ( inputIndex >= 512 ) break ;
		}
		inputIndex &= 0x1ff ;	// mod 512
	}
	
	if ( !frequencyLocked ) {
		//  AFC BYPASSED in v0.18
		[ lock lock ] ;
		// acquistion phase
		if ( !lockProcessStarted ) {
			//  first pass of the acquisition phase
			lockProcessStarted = YES ;
			acquisitionPhase = 0 ;
			acquisitionPass = 0 ;
			offset = 0 ;
			for ( i = 0; i < 80; i++ ) histogram[i] = 0 ;
		}
		k = acquisitionPhase*32 ;
		for ( i = 0; i < 512; i += 16 ) {
			//  decimate by 8
			iBuf[k+i/16] = iIF[i] ;
			qBuf[k+i/16] = qIF[i] ;
		}
		if ( acquisitionPhase++ >= 15 ) {
			input.realp = &iBuf[0] ;
			input.imagp = &qBuf[0] ;
			output.realp = &iSpec[0] ;
			output.imagp = &qSpec[0] ;
			CMPerformComplexFFT( fft, &input, &output ) ;
			
			peak = 0 ;
			vPeak = ( iSpec[peak]*iSpec[peak] + qSpec[peak]*qSpec[peak] ) ;
			for ( i = 1; i < 40; i++ ) {
				v = ( iSpec[i]*iSpec[i] + qSpec[i]*qSpec[i] ) ;
				if ( v > vPeak ) {
					vPeak = v ;
					peak = i ;
				}
				v = ( iSpec[512-i]*iSpec[512-i] + qSpec[512-i]*qSpec[512-i] ) ;
				if ( v > vPeak ) {
					vPeak = v ;
					peak = -i ;
				}
			}
			histogram[peak+40]++ ;
			
			//  move indicator on waterfall for user feedback
			offset = ( offset + peak*CMFs*0.5/(256*16) )*0.5 ;
			[ (Hellschreiber*)client frequencyUpdatedTo:receiveFrequency+offset ] ;
			acquisitionPhase = 0 ;

			if ( histogram[peak+40] >= 2 ) {
				//  found confirming spectral peak
				frequencyLocked = YES ;
			}
			else {
				// find median
				if ( ++acquisitionPass >= 5 ) {
					frequencyLocked = YES ;
					lockProcessStarted = NO ;					
					// find median in histogram
					count = 0 ;
					median = acquisitionPass/2 ;
					for ( i = 0; i < 80; i++ ) {
						count += histogram[i] ;
						if ( count > median ) break ;
					}
					peak = i - 40 ;
				}
			}
			if ( frequencyLocked ) {
				lockProcessStarted = NO ;
				offset = peak*CMFs*0.5/(256*16) ;
				lockedFrequency = ( receiveFrequency += offset ) ;
				[ vco setCarrier:receiveFrequency ] ;
				[ (Hellschreiber*)client frequencyUpdatedTo:receiveFrequency ] ;
			}
		}
		[ lock unlock ] ;
	}
}

//  FM demodulator
- (void)fmImport:(CMPipe*)pipe
{
	CMAnalyticPair pair ;
	CMDataStream *stream ;
	int i, j, trunc ;
	float *array, v, iDot, qDot, freq ;
	
	if ( !receiverEnabled ) return ;		//  wait for click
	
	stream = [ pipe stream ] ;
	array = stream->array ;
	
	//  decimate and process the 512 original input samples
	//
	//  each FM 245 Hellschreiber bit is 8.16 ms in duration (122.5 baud), or 90 samples
	//	we decimate by 5 to get 18 samples per bit of information, after mixing with the complex VCO
	//  this gives 9 samples per half pixel
	//
	//  each FM 105 Hellschreiber bit is 9.52 ms in duration (105 baud), or 105 samples
	//	we decimate by 5 to get 21 samples per bit of information, after mixing with the complex VCO
	
	for ( i = 0; i < 512; i++ ) {
		v = array[i] ;
		pair = [ vco nextVCOPair ] ;
		iMixer[i] = pair.re * v ;
		qMixer[i] = pair.im * v ;
	}
	CMPerformFIR( iFilter, iMixer, 512, iIF ) ;
	CMPerformFIR( qFilter, qMixer, 512, qIF ) ;
	
	//  in the future, any FM limiting can go here.
	
	for ( i = 0 ; i < 512; i++ ) {
	
		//  IIR differentiator using Al-Alaoui's 1994 algorithm
		//	http://mechatronics.ece.usu.edu/yqchen/dd/AL_Ala4.pdf
		
		iReg[0] = iIF[i] - 0.5358*iReg[1] - 0.0718*iReg[2] ;
		iDot = iReg[2]-iReg[0] ;
		
		qReg[0] = qIF[i] - 0.5358*qReg[1] - 0.0718*qReg[2] ;
		qDot = qReg[2]-qReg[0] ;
		
		//  apply a slow AGC
		mag = mag*0.9 + 0.1*( iDelay[0]*iDelay[0] + qDelay[0]*qDelay[0] ) ;
		freq = ( qDelay[0]*iDot - iDelay[0]*qDot )/mag ;

		//  update IIR registers for next pass
		iReg[2] = iReg[1] ;
		iReg[1] = iReg[0] ;		
		qReg[2] = qReg[1] ;
		qReg[1] = qReg[0] ;	
		iDelay[0] = iDelay[1] ;
		iDelay[1] = iDelay[2] ;
		iDelay[2] = iIF[i] ;
		qDelay[0] = qDelay[1] ;
		qDelay[1] = qDelay[2] ;
		qDelay[2] = qIF[i] ;
		
		freqBuf[i] = freq ;
	}
	
	for ( i = 0; i < 512; i++ ) {
	
		currentIBuf[outputIndex] = freqBuf[inputIndex] ;
		outputIndex++ ;
		
		//  decimate by phaseDecimation (approx 5 plus a correction factor)
		if ( addedPhase ) {
			if ( addedPhase > 0 && outputIndex < 100 ) {
				for ( j = 0; j < 3; j++ ) {
					currentIBuf[outputIndex] = 0 ;
					outputIndex++ ;
				}
				addedPhase-- ;
			}
			if ( addedPhase < 0 && outputIndex > 32 ) {
				outputIndex -= 3 ;
				addedPhase++ ;
			}
		}
		inputPhase += phaseDecimation ;
		trunc = inputPhase ;
		inputPhase -= trunc ;
		inputIndex += trunc ;
		
		if ( outputIndex >= 126 ) {
			//  send to demodulator when we have enough samples (18*7 for FM 245 or 21*6 for FM 105)
			if ( mode == HELLFM105 ) [ self fmResample105:currentIBuf ] ; else [ self fmResample245:currentIBuf ] ;
			//  select next buffer
			currentIBuf = ( currentIBuf == iBuf0 ) ? iBuf1 : iBuf0 ;
			outputIndex = 0 ;
		}
		if ( inputIndex >= 512 ) break ;

	}	
	inputIndex &= 0x1ff ;	// mod 512
}

//  quadrature tone demodulator for FM HELL 245
//  clled when 126 samples are collected
- (void)fmResample245:(float*)freq
{
	int i, j, k ;
	float *columnPtr, pixelColumn[28], u ;
	
	//  create 14 half-pixels from 126 sample with 9 element boxcar
	columnPhase = ( columnPhase + 1 ) & 1 ;
	
	columnPtr = &column[ columnPhase*16 ] ;
	
	for ( i = 0; i < 14; i++ ) {
		u = 0 ;
		k = i*9 ;
		for ( j = 0; j < 9; j++ ) {
			u += ( freq[k+j]*14.3 ) + 0.5 ;			// scale (-122.5, +122.5) Hz deviation to ( 0, 1.0 )
		}
		u /= 9.0 ;
		if ( u > 1.0 ) u = 1.0 ; else if ( u < 0 ) u = 0 ;
		columnPtr[i] = ( sidebandState ) ? ( 1.0-u ) : u ;
	}
	
	//  output double height column (28 pixels total)
	//  Note: receive view is 900 pixels wide and 512 high in a scollview 288 pixels high

	columnPtr = &column[( columnPhase^1 )*16] ;
	for ( i = 0; i < 14; i++ ) pixelColumn[i] = columnPtr[i] ;
	columnPtr = &column[ columnPhase*16 ] ;
	for ( i = 0; i < 14; i++ ) pixelColumn[i+14] = columnPtr[i] ;
	
	[ (Hellschreiber*)client addColumn:pixelColumn index:0 xScale:2 ] ;
}

//  quadrature tone demodulator for FM HELL 105
//  called when 126 samples are collected
- (void)fmResample105:(float*)freq
{
	int i, j, k ;
	float *columnPtr, pixelColumn[28], u ;
	
	//  create 12 half-pixels from 126 sample with 10/21 element boxcar
	columnPhase = ( columnPhase + 1 ) & 1 ;
	
	columnPtr = &column[ columnPhase*16 ] ;
	
	k = 0 ;
	for ( i = 0; i < 12; i += 2 ) {
		//  first half pixel
		u = 0 ;
		for ( j = 0; j < 11; j++ ) u += ( freq[k+j]*24.5 ) + 0.5 ;				// scale to ( -1,+1 )
		u /= 11.0 ;
		if ( u > 1.0 ) u = 1.0 ; else if ( u < 0 ) u = 0 ;
		columnPtr[i] = ( sidebandState ) ? ( 1.0-u ) : u ;

		//  second half pixel
		u = 0 ;
		for ( j = 11; j < 21; j++ ) u += ( freq[k+j]*24.5 ) + 0.5 ;				// scale to ( -1,+1 )
		u /= 10.0 ;
		if ( u > 1.0 ) u = 1.0 ; else if ( u < 0 ) u = 0 ;
		columnPtr[i+1] = ( sidebandState ) ? ( 1.0-u ) : u ;
		
		k += 21 ;
	}
	
	//  output double height column (28 pixels total)
	//  Note: receive view is 900 pixels wide and 512 high in a scollview 288 pixels high

	columnPtr = &column[( columnPhase^1 )*16] ;
	for ( i = 0; i < 12; i++ ) pixelColumn[i+2] = columnPtr[i] ;
	columnPtr = &column[ columnPhase*16 ] ;
	for ( i = 0; i < 12; i++ ) pixelColumn[i+14] = columnPtr[i] ;
	pixelColumn[0] = pixelColumn[1] = pixelColumn[26] = pixelColumn[27] = 0 ;
	
	[ (Hellschreiber*)client addColumn:pixelColumn index:0 xScale:2 ] ;
}

//  quadrature tone demodulator for Hellschreiber
//  length should be 126 
- (void)feldDemodulate:(float*)inphase quadrature:(float*)quadrature length:(int)length
{
	int i, j, k, size ;
	float v, u, *columnPtr, pixelColumn[28] ;
	
	columnPhase = ( columnPhase + 1 ) & 1 ;
	
	size = sizeof( float )*length ;
	memmove( iDemod, iDemod+length, size ) ;
	CMPerformFIR( iMatchedFilter, inphase, length, iDemod+length ) ;
	memmove( qDemod, qDemod+length, size ) ;
	CMPerformFIR( qMatchedFilter, quadrature, length, qDemod+length ) ;
	
	//  each column of data consists of 7 full Hellschreiber pixels.
	//  At this interface, each full pixel has 18 samples.  Thus each colum has 7*18 = 126 samples.
	
	columnPtr = &column[ columnPhase*16 ] ;
	for ( i = 0; i < 14; i++ ) {
		u = 0 ;
		k = i*9 ;
		for ( j = 0; j < 9; j++ ) {
			v = sqrt( iDemod[k]*iDemod[k] + qDemod[k]*qDemod[k] ) ;
			k++ ;
			//  agc, fast charge, slow discharge
			agc = ( v > agc ) ? ( agc*0.9 + 0.1*v ) : ( agc*0.9995 + 0.0005*v ) ;
			u += v / (0.5 + agc*0.5) ;
		}
		u /= 9.0 ;
		if ( u > 1.0 ) u = 1.0 ;
		columnPtr[i] = u ;
	}
	
	//  output double height column (28 pixels total)
	//  Note: receive view is 900 pixels wide and 512 high in a scollview 288 pixels high

	columnPtr = &column[( columnPhase^1 )*16] ;
	for ( i = 0; i < 14; i++ ) pixelColumn[i] = columnPtr[i] ;
	columnPtr = &column[ columnPhase*16 ] ;
	for ( i = 0; i < 14; i++ ) pixelColumn[i+14] = columnPtr[i] ;
	[ (Hellschreiber*)client addColumn:pixelColumn index:0 xScale:2 ] ;
}

- (void)slopeChanged:(float)value
{
	phaseDecimation = 5.0 - value ;
}

- (void)positionChanged:(int)direction
{
	addedPhase += direction*3 ;
}

@end
