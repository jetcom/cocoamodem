/*
 *  modemTypes.h
 *  cocoaModem
 *
 *  Created by Kok Chen on Fri May 14 2004.
	#include "Copyright.h"
 *
 */

#ifndef _MODEMTYPES_H_
	#define _MODEMTYPES_H_

	#include "CoreModemTypes.h"
		
	extern int vuSegmentTable[1416] ;
	
	typedef struct {
		unsigned char day ;
		unsigned char month ;
		unsigned char year ;
		unsigned char hour ;
		unsigned char minute ;
		unsigned char second ;
	} DateTime ;
	
	typedef int (*IntMethod)( id, SEL, ...) ;
	
	//  the following are 4-character constants used by AppleScripts
	
	//  transceiver states
	enum {
		//  modemStates
		ModemTransmit = 'trTX',
		ModemReceive = 'trRX',
		ModemNotConnected = 'txNC'
	} ;
	
	//  modulation modes
	enum {
		ModulationBPSK31 = 'bP31',
		ModulationBPSK63 = 'bP63',
		ModulationQPSK31 = 'qP31',
		ModulationQPSK63 = 'qP63',
		ModulationRTTY45 = 'rT45',
		ModulationFeld = 'Feld',
		ModulationFM105 = 'h105',
		ModulationFM245 = 'h245',
		ModulationMFSK16 = 'mf16',

		ModulationBPSK125 = 'bP12',			//  v0.64f
		ModulationQPSK125 = 'qP12',			//  v0.64f
	} ;

	//  -- deprecated --
	enum {
		//  interfaceModes (deprecated)
		RTTYInterfaceMode = 'irty',
		PSKInterfaceMode = 'ipsk',
		//  pskModes (deprecated)
		PSKModeBPSK31 = 'pb31',
		PSKModeQPSK31 = 'pq31',
		PSKModeBPSK63 = 'pb63',
		PSKModeQPSK63 = 'pq63'
	} ;

#endif
