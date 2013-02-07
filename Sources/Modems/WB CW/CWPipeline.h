//
//  CWPipeline.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/25/06.


#ifndef _CWPIPELINE_H_
	#define _CWPIPELINE_H_

	#import <Cocoa/Cocoa.h>
	#import "CMFFT.h"
	#import "Boxcar.h"
	#import "hadamard.h"
	
	@class CWMatchedFilter ;
	
	typedef struct {
		int state ;
		int interval ;
		float max ;
		float min ;
		Boolean valid ;
	} ElementType ;
	
	typedef struct {
		float interElement ;
		float interSymbol ;
		float dit ;
		float dash ;
		float speed ;
	} MorseTiming ;
	
	@interface CWPipeline : NSObject {
		CWMatchedFilter *client ;
		
		CMFIR *iDecimateFilter, *qDecimateFilter ;
		CMFIR *iAGCFilter, *qAGCFilter ;
		float decimated[64] ;
		
		float noiseBuffer[2048] ;
		float dataBuffer[2048] ;
		float noiseGate ;
		int dataBufferIndex ;
		
		CMFIR *dataFilter0, *dataFilter1, *dataFilter2 ;
		
		float estimatedSpeed ;

		float threshold, smoothedThreshold ;
		ElementType dataElement, previousElement, currentElement ;
		float squelch ;
		
		// key states
		int keyState ;
		int keyInterval ;
		
		int timeoutTime ;
		int currentState ;
	}
	- (id)initFromClient:(CWMatchedFilter*)matchedFilter ;
	- (void)initElement:(ElementType*)element state:(int)state valid:(Boolean)valid ;
	
	- (void)importArray:(float*)array ;
	- (void)stateChangedTo:(ElementType*)e ;
	- (void)processElement:(ElementType*)element ;

	- (void)setSquelch:(float)db fastQSB:(float)fastQSB slowQSB:(float)slowQSB ;
	- (void)updateFilter:(int)elementLength ;
	
	- (void)newClick ;


	@end

	#define	RINGMASK		0xfff					//  4096 elements (0.75 ms per element)
	#define	RINGSIZE		(RINGMASK+1)

	#define WINDOW			60						//  must be less than one buffer (64)
	#define	RINGSTART		(RINGSIZE-WINDOW)

	#define	FILTERLENGTH	1024					//  all filters must use the same length to align the epoch
	
	#define	dataThreshold	0.5

#endif
