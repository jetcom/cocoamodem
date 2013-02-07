/*
 *  error.h
 *  cocoaModem
 *
 *  Created by Kok Chen on 3/18/05.
 *
 */

#ifndef _ERROR_H_
	#define _ERROR_H_

	#include <Carbon/Carbon.h>
	#include <math.h>


	float BERnFSK( float snr ) ;
	float BER3kRTTY( float snr ) ;
	float CER( float snr ) ;
	float WER( float snr ) ;
	float WERfromBER( float ber ) ;
	float TER( float snr ) ;

#endif
