//
//  RTTYDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/27/07.
	#include "Copyright.h"
	
	
#import "RTTYDemodulator.h"
#import "CMBaudotDecoder.h"
//#import "CMFSKMixer.h"
#import "RTTYATC.h"
#import "RTTYMatchedFilter.h"
#import "RTTYReceiver.h"
#import "CMFSKTypes.h"



@implementation RTTYDemodulator


//  Subclass of the original CMFSKDemodulator in CoreModem v0.33
//  Uses RTTYATC instead of CMATC in CoreModem

- (id)initFromReceiver:(RTTYReceiver*)rcvr
{
	CMTonePair defaultTonePair = { 2125.0, 2295.0, 45.45 } ;
	CMATC *atc ;

	self = [ super initSuper ] ;
	if ( self ) {
		delegate = nil ;
		receiver = rcvr ;
		decoder = [ [ RTTYBaudotDecoder alloc ] initWithDemodulator:self ] ;
		atc = [ [ CMATC alloc ] init ] ;
		[ self initPipelineStages:&defaultTonePair decoder:decoder atc:atc bandwidth:340.0 ] ;
		//  initpipeline should have set up iSRTTY
		auralMonitor = ( isRTTY ) ? [ rcvr rttyAuralMonitor ] : nil ;
	}
	return self ;
}

//  print FIGS, LTRS, CR, LF
- (void)setPrintControl:(Boolean)state
{
	[ decoder setPrintControl:state ] ;
}

//  received wideband data from Core Audio.
- (void)importData:(CMPipe*)pipe
{	
	CMFSKPipeline *p = (CMFSKPipeline*)pipeline;
	
	//  v0.89 was commented away
	if ( auralMonitor != nil ) [ auralMonitor newWidebandData:pipe ] ;
	
	//  send data through the processing chain starting at the bandpass filter
	if ( p->bandpassFilter ) [ p->bandpassFilter importData:pipe ] ;
}

@end
