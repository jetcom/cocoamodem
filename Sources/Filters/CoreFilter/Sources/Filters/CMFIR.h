/*
 *  CMFIR.h
 *  Filter (CoreModem)
 *
 *  Created by Kok Chen on 10/24/05
 *
 */

#ifndef _CMFIR_H_
	#define _CMFIR_H_

	#include <Carbon/Carbon.h>
	#include <vecLib/vDSP.h>

	typedef enum {
		kCMInterpolate,			//  output samples > input samples
		kCMFilter,				//  output samples = input samples
		kCMDecimate,			//  output samples < input samples
		kCMDelayLine
	} CMFIRStyle ;

	typedef struct {
		float *kernel ;
		float *delayLine ;
		int activeTaps ;
		int stride ;
		int delaylineHead ;
		CMFIRStyle style ;
		float fsampling ;			// sampling frequency
	} CMFIR ;
	
	CMFIR *CMFIRFilter( float *kernel, int activeTaps ) ;
	CMFIR *CMFIRInterpolate( int factor, float *kernel, int activeTaps ) ;
	CMFIR *CMFIRDecimate( int factor, float *kernel, int activeTaps ) ;
	CMFIR *CMDelayLine( int delayUnits ) ;
	//  updates
	void CMUpdateFIRFilter( CMFIR *fir, float *kernel, int activeTaps ) ;
	void CMUpdateFIRLowpassFilter( CMFIR *fir, float cutoff ) ;
	void CMUpdateFIRBandpassFilter( CMFIR *fir, float low, float high ) ;
	
	//  "simple" filters (windowed sinc)
	CMFIR *CMFIRLowpassFilter( float cutoff, float fsampling, int ActiveTaps ) ;
	CMFIR *CMFIRBandpassFilter( float low, float high, float fsampling, int ActiveTaps ) ;
	CMFIR *CMFIRCombFilter( float freq, float fsampling, int activeTaps, float phase ) ;
	CMFIR *CMFIRDecimateWithCutoff( int factor, float cutoff, float fsampling, int activeTaps ) ;
	
	// perform filtering
	void CMPerformFIR( CMFIR *fir, float *inArray, int inLength, float *outArray ) ;
	float CMDecimate( CMFIR *fir, float *inArray ) ;
	float CMSimpleFilter( CMFIR *fir, float input ) ;
	void CMAdvanceFilter( CMFIR *fir, float *p, int n ) ;
	float CMSimpleDelay( CMFIR *fir, float input ) ;
	
	//  housekeeping
	void CMDeleteFIR( CMFIR *fir ) ;

#endif
