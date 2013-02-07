/*
 *  cocoaModemParams.h
 *  cocoaModem
 *
 *  Created by Kok Chen on Thu Jun 10 2004.
 *
 */

#ifndef _COCOAMODEMPARAMS_H_
	#define _COCOAMODEMPARAMS_H_
		
	//#define	Phi		0xaf 
	//#define	phi		0xbf
	#define	Phi		0xd8 
	#define	phi		0xf8
	
	#define	kCallsignTextField	1
	#define	kExchangeTextField	2
	#define	kExtraTextField		3
	
	#define	CallNotify			@"SelectCallField"
	#define	ExchangeNotify		@"SelectExchField"
	#define	ExtraFieldNotify	@"SelectExtraField"
	
	#define CWMODE		1
	#define SSBMODE		2
	#define RTTYMODE	3
	#define PSKMODE		4
	#define	HELLMODE	5
	
#endif
