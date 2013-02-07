/*
 *  error.c
 *  cocoaModem
 *
 *  Created by Kok Chen on 3/18/05.
	#include "Copyright.h"
 *
 */

#include "error.h"

//  BER for non-coherent FSK
//	snr is Eb/No in dB
float BERnFSK( float snr )
{
	float s ;

	s = pow( 10.0, snr*0.1 ) ;
	return 0.5*exp( -s*0.5 ) ;
}

//	BER for non-coherent FSK, 45.45 baud
//	snr is signal to noise ratio within a 3000 Hz noise bandwidth
float BER3kRTTY( float snr )
{
	float s ;
	
	s = snr + 10.0*log10( 3000.0 ) - 10.0*log10( 45.45 ) ;
	
	return BERnFSK( s ) ;
}

//	VE3NEA character error rate measure (pseudo synchonous FSK)
//	snr is signal to noise ratio within a 3000 Hz noise bandwidth
float CER( float snr )
{
	float p, q ;
	
	p = BER3kRTTY( snr ) ;
	q = 1.0 - p ;
	return 1.0 - pow( q, 6.0 ) ;
}

//	David Mills' word error rate measure (non synchronous FSK, UART model)
//	snr is signal to noise ratio within a 3000 Hz noise bandwidth
float WER( float snr )
{
	float ber ;
	
	ber = BER3kRTTY( snr ) ;
	return WERfromBER( ber ) ;
}
	
float WERfromBER( float p )
{
	float q ;
	
	q = 1.0 - p ;
	return ( 1.0 - pow( q, 7.0 ) )*( 0.25 + 4.78/2 + ( 2.33*p + 3.75*q )/4 ) ;
}

//   test case for estimating character error rate
//   stop bit error = p
float TER( float snr )
{
	float p, q, qsync, psync, p5 ;
	
	p = BER3kRTTY( snr ) ;
	q = 1 - p ;  //  probability that bit is OK
	qsync = q*q*q ;
	psync = 1.0 - qsync ;
	
	p5 = ( 1.0 - pow( q, 5.0 ) ) ;
	return psync + qsync*( p5 ) ;
}
	
