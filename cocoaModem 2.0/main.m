//
//  main.m
//  cocoaModem
//
//  Created by Kok Chen on Wed May 12 2004.
	#include "Copyright.h"
//

#import <Cocoa/Cocoa.h>
#include <CoreAudio/CoreAudio.h>
#include <CoreFoundation/CoreFoundation.h>
#include <math.h>
#include "CMIIR.h"

int vuSegmentTable[1416] ;			//  global table used by VUMeter class objects



int main(int argc, const char *argv[])
{	
	
	#ifdef TESTBAUDOT   // VE3NEA stream
	int p0, p1, p2, p3, p4, p, i, n ;
	char *s, str[] = {
		10,	21,	10,	21,	10,	21,	10,	21,	10,	21,	10,	21,	10,	21,	10,	21,
		4,	4,	2,	27,	22,	23,	19,	1,	10,	16,	21,	7,	6,	24,	22,	2,
		31,	3,	25,	14,	9,	1,	13,	26,	20,	6,	11,	15,	18,	28,	12,	24,
		22,	23,	10,	5,	16,	7,	30,	19,	29,	21,	17,	2,	3,	25,	14,	9,
		1,	13,	26,	20,	6,	11,	15,	18,	28,	12,	24,	22,	23,	10,	5,	16,
		7,	30,	19,	29,	21,	17,	2,	31,	31,	31,	31,	31,	31,	31,	31,	31,
		31,	31,	31,	31,	31,	31,	31,	31,	31,	0
	} ;
	
	p0 = p1 = p2 = p3 = p4 = p = 0 ;
	s = str ;
	while ( 1 ) {
		n = *s++ ;
		if ( n == 0 ) break ;
		i = n ;
		p++ ;
		if ( ( i & 0x01 ) != 0 ) p0++ ;
		if ( ( i & 0x02 ) != 0 ) p1++ ;
		if ( ( i & 0x04 ) != 0 ) p2++ ;
		if ( ( i & 0x08 ) != 0 ) p3++ ;
		if ( ( i & 0x10 ) != 0 ) p4++ ;
	}
	printf( "%d %8.3f\n", 0, p0*1.0/p ) ;
	printf( "%d %8.3f\n", 1, p1*1.0/p ) ;
	printf( "%d %8.3f\n", 2, p2*1.0/p ) ;
	printf( "%d %8.3f\n", 3, p3*1.0/p ) ;
	printf( "%d %8.3f\n", 4, p4*1.0/p ) ;
	exit( 0 ) ;
	#endif
	
	#ifdef CERR
	int snr ;
	
	for ( snr = -13; snr < -6; snr++ ) {
		printf( "%5d\tBER %8.2e\tCER %8.2e\tTER %8.2e\n", snr, BER3kRTTY( snr*1.0 ), CER( snr*1.0 ), TER( snr*1.0 ) ) ;
	}
	exit( 0 ) ;
	#endif
	
	#ifdef QPSKTABLE
	char table[1024] ;
	
	generateQPSKTable( table ) ;
	exit( 0 ) ;
	#endif
	
	#ifdef TESTIIRDESIGN
	double pole[16], zero[16] ;
	int i ;
	float gain ;
	gain = butterworthDesign( 4, BP, 120.0, 2125.0, pole, zero ) ;
	printf( "Gain = %f\n", gain ) ;
	for ( i = 0; i <= 4; i++ ) {
		printf( "%f %f\n", pole[i], zero[i] ) ;
	}
	exit( 0 ) ;
	#endif
	
	AudioHardwareUnload() ;
	//	use the current thread as the CoreAudio HAL's run loop
	//  CFRunLoopRef runLoop = CFRunLoopGetCurrent() ;
	//  AudioHardwareSetProperty( kAudioHardwarePropertyRunLoop, sizeof(CFRunLoopRef), &runLoop ) ;

    return NSApplicationMain(argc, argv);
}
