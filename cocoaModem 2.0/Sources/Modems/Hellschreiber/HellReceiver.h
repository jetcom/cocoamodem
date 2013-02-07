//
//  HellReceiver.h
//  cocoaModem
//
//  Created by Kok Chen on 7/29/05.
//

#ifndef _HELLRECEIVER_H_
	#define _HELLRECEIVER_H_

	#import <Cocoa/Cocoa.h>
	#include "CMToneReceiver.h"
	#include "CMFIR.h"
	#include "CMFFT.h"

	typedef float RawColumn[126] ;
	
	@class Modem ;
	
	@interface HellReceiver : CMToneReceiver {
	
		Modem *client ;
		
		//  matched filter
		CMFIR *iMatchedFilter, *qMatchedFilter ;
		float iDemod[256], qDemod[256] ;
		
		//  agc
		float agc ;
		
		//  decimating filter
		CMFIR *iFilter, *qFilter ;
		float iMixer[512], qMixer[512] ;
		float iIF[512], qIF[512] ;
		float freqBuf[512] ;
		float *iBuf0, *qBuf0 ;
		float *iBuf1, *qBuf1 ;
		float *currentIBuf, *currentQBuf ;
		int inputIndex, outputIndex ;
		float inputPhase, phaseDecimation /* 5.0 nominal decimation */ ;
		
		//  mode (HELLFELD, HELLFM...)
		int mode ;
		float iReg[3], qReg[3], iDelay[3], qDelay[3], mag ;
		
		//  demod output
		float column[32] ;			// to store 2x14 subpixels
		int columnPhase ;
		Boolean sidebandState ;
		
		//  acquisition
		CMFFT *fft ;
		int acquisitionPhase ;
		int acquisitionPass ;
		int histogram[80] ;
		int addedPhase ;
		float *iBuf, *qBuf, *iSpec, *qSpec ;
		float offset ;
		NSLock *lock ;
		float lockedFrequency ;
	}
	
	- (id)initFromModem:(Modem*)modem ;
	- (void)setMode:(int)mode ;
	- (void)setSidebandState:(Boolean)state ;
	
	- (void)feldImport:(CMPipe*)pipe ;
	- (void)feldDemodulate:(float*)inphase quadrature:(float*)quadrature length:(int)length ;

	- (void)fmImport:(CMPipe*)pipe ;	
	- (void)fmResample105:(float*)inphase ;
	- (void)fmResample245:(float*)inphase ;
	
	- (void)slopeChanged:(float)value ;
	- (void)positionChanged:(int)direction ;
	
	- (Boolean)canTransmit ;
	- (float)lockedFrequency ;

	@end

#endif
