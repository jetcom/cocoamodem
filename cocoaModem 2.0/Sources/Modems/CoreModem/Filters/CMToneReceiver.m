//
//  CMToneReceiver.m
//  CoreModem
//
//  Created by Kok Chen on 7/29/05.
	#include "Copyright.h"
//

#import "CMToneReceiver.h"
#include "CMPCO.h"
#include "CoreModemTypes.h"
#include "CMDSPWindow.h"

@implementation CMToneReceiver

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
	
		//  set up VCO at tone's frequency
		receiveFrequency = 10 ; // for now
		vco = [ [ CMPCO alloc ] init ] ;
		[ vco setCarrier:receiveFrequency ] ;

		receiverEnabled = NO ;
		frequencyLocked = NO ;
		lockProcessStarted = NO ;
		acquire = 0 ;
		goertzelWindow = CMMakeBlackmanWindow( 256 ) ;
	}
	return self ;
}

//  return power at frequency using Goertzel algorithm (256 samples)
- (float)goertzel:(float*)x freq:(float)center
{
	int i ;
	float d0=0, d1=0, d2, s ;
	
	s = cos( 2*CMPi*16/CMFs*center ) ;
	
	for ( i = 0; i < 256; i++ ) {
		d2 = d1 ;
		d1 = d0 ;
		d0 = 2*s*d1 - d2 + goertzelWindow[i]*x[i] ;
	}
	return d0*d0 + d1*d1 - 2*s*d0*d1 ;
}

- (float)goertzel:(float*)x imag:(float*)y freq:(float)center
{
	return [ self goertzel:x freq:center ] + [ self goertzel:y freq:center ] ;
}

- (void)selectFrequency:(float)freq fromWaterfall:(Boolean)fromWaterfall
{
	receiverEnabled = YES ;
	frequencyLocked = lockProcessStarted = NO ;  // acquisition phase
	acquire = 1 ;
	
	receiveFrequency = freq ;
	if ( vco ) [ vco setCarrier:freq ] ;
}

- (float)receiveFrequency
{
	return receiveFrequency ;
}

- (void)setReceiveFrequency:(float)tone
{
	receiveFrequency = tone ;
}

- (void)enableReceiver:(Boolean)state
{
	receiverEnabled = state ;
}

- (Boolean)isEnabled
{
	return receiverEnabled ;
}


@end
