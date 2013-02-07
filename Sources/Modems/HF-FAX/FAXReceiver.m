//
//  FAXReceiver.m
//  cocoaModem
//
//  Created by Kok Chen on 3/6/2006.
	#include "Copyright.h"
//

#import "FAXReceiver.h"
#include "FAX.h"
#include "CMPCO.h"
#include "CoreModemTypes.h"
#include "CMFIR.h"
#include <math.h>

@implementation FAXReceiver

- (void)buildFilter:(int)n bandpass:(float)bandpass
{
	inputBandpassFilterN[n] = CMFIRBandpassFilter( 1900-bandpass, 1900+bandpass, CMFs, 256 ) ;
	limiterBandpassFilterN[n] = CMFIRBandpassFilter( 1900-bandpass, 1900+bandpass, CMFs, 256 ) ;
	iFilterN[n] = CMFIRLowpassFilter( bandpass, CMFs, 256 ) ;
	qFilterN[n] = CMFIRLowpassFilter( bandpass, CMFs, 256 ) ;
}

- (id)initFromModem:(Modem*)modem
{
	int i ;
		
	self = [ super init ] ;
	if ( self ) {
		view = (FAXDisplay*)[ (FAX*)modem faxView ] ;
		//  set center of VCO
		[ vco setCarrier:1900.0 ] ;
		
		iReg[0] = iReg[1] = iReg[3] = 0 ;
		qReg[0] = qReg[1] = qReg[3] = 0 ;

		client = modem ;
		agc = mag = 1.0 ;
		
		for ( i = 0; i < 512; i++ ) iOutput[i] = qOutput[i] ;
		
		[ self buildFilter:0 bandpass:480 ] ;
		[ self buildFilter:1 bandpass:650 ] ;
		[ self buildFilter:2 bandpass:1200 ] ;
		[ self changeBandwidthTo:1 ] ;
		
		//  DataPipe has 131,072 floating point samples (approx 12 seconds)
		datapipe = [ [ DataPipe alloc ] initWithCapacity:512*256*sizeof(float) ] ;
		[ NSThread detachNewThreadSelector:@selector(pullThread:) toTarget:self withObject:self ] ;
	}
	return self ;
}

- (void)changeBandwidthTo:(int)index
{
	if ( index < 0 || index > 2 ) return ;
		
	inputBandpassFilter = inputBandpassFilterN[index] ;
	limiterBandpassFilter = limiterBandpassFilterN[index] ;
	iFilter = iFilterN[index] ;
	qFilter = qFilterN[index] ;
}

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall
{
	//  do nothing, manually tuned
}

//	v0.57d  added DataPipe to buffer input data from the codec
//  input data is pushed into a DataPipe and pulled here
- (void)pullThread:(id)client
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ], *delayedRelease = nil ;
	int i, runLoopCycle ;	
	CMAnalyticPair pair ;
	float u, v, freq, iDot, qDot, inputBuffer[512] ;

	runLoopCycle = 0 ;
	
	//  Loop continuously requesting data at 11025 s/s from the DataPipe.  
	while ( 1 ) {
		//  block here when there is no new data
		[ datapipe readData:inputBuffer length:512*sizeof(float) ] ;
		//  bandpass signal before limiting
		CMPerformFIR( inputBandpassFilter, inputBuffer, 512, bandpassFilteredInput ) ;
	
		//  Apply soft limiter to bandpassed input
		//  Hard limiting is not used to avoid problem with insufficient oversampling.
		//  The factor of 0.45 is a compromise between too much limiting (undersampled phase measurements) and
		//	too little capture ratio.  FM capture ratio is used to avoid multipathed signals and no other equalization is done.
		for ( i = 0; i < 512; i++ ) {
			v = bandpassFilteredInput[i] ;
			u = pow( fabs( v ), 0.45 ) ;
			if ( v < 0 ) u = -u ;
			bandpassFilteredInput[i] = u ;
		}
		//  apply bandpass filter after limiting
		CMPerformFIR( limiterBandpassFilter, bandpassFilteredInput, 512, limited ) ;

		//  Mix to I and Q channels by the FAX center frequency (1900 Hz).
		for ( i = 0; i < 512; i++ ) {
			v = limited[i] ;
			pair = [ vco nextVCOPair ] ;
			iMixer[i] = pair.re * v ;
			qMixer[i] = pair.im * v ;
		}
		//  Apply lowpass to I and Q channels
		CMPerformFIR( iFilter, iMixer, 512, &iOutput[0] ) ;
		CMPerformFIR( qFilter, qMixer, 512, &qOutput[0] ) ;
	
		//  DirectFM demodultion.
		//	Use ( i.q_dot - q*i_dot )/( i.i + q.q ) to get derivative of phase
		//
		//	See Frerking, "Digital Signal Processing in Communications Systems"
		//  Notice that we still normalize by (i.i+q.q) since only a soft demodulator is used.

		for ( i = 0; i < 512; i++ ) {
			
			//  IIR differentiator using Al-Alaoui's 1994 algorithm
			//	http://mechatronics.ece.usu.edu/yqchen/dd/AL_Ala4.pdf
			
			iReg[0] = iOutput[i] - 0.5358*iReg[1] - 0.0718*iReg[2] ;
			iDot = iReg[2]-iReg[0] ;
			
			qReg[0] = qOutput[i] - 0.5358*qReg[1] - 0.0718*qReg[2] ;
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
			iDelay[2] = iOutput[i] ;
			qDelay[0] = qDelay[1] ;
			qDelay[1] = qDelay[2] ;
			qDelay[2] = qOutput[i] ;
			
			//  send oversampled data to FAXDisplay
			[ view addPixel:freq ] ;
		}
		if ( runLoopCycle++ > 1501 ) {
			//  periodically flush the Autorelease pool
			if ( delayedRelease ) {
				//  delay actual release of the old pool by one lap time to allow AudioConverter to completely drain.
				//	as a result, we will use about twice the amount of real memory for the thread.
				//	v0.76 : don't drain pool in Snow Leopard
				SInt32 systemVersion = 0 ;
				Gestalt( gestaltSystemVersionMinor, &systemVersion ) ;
		
				if ( systemVersion < 6 /* before snow leopard */ ) {
					[ delayedRelease drain ] ;		// v0.57b
				}
				delayedRelease = nil ;
			}
			runLoopCycle = 0 ;
			delayedRelease = pool ;
			pool = [ [ NSAutoreleasePool alloc ] init ] ;
		}
	}	
	[ pool release ] ;
	[ NSThread exit ] ;
}

//  The input samples come in at 11025 samples/second, and gives a time resolution of 0.09 millisecond per sample.
//  An IOC of 576 gives 1809 pixels in 0.5 seconds, or 3618 pixels per second or .276 milliseconds per pixel.  
//  With a DDA running at a rate of 11025.0/( 576*pi*2 ) = 3.0463, we can resample the stream at 3x resolution.

- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	
	if ( !receiverEnabled ) return ;		//  wait for click
	
	stream = [ pipe stream ] ;
	[ datapipe write:stream->array length:512*sizeof( float ) ] ;
}

@end
