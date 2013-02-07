/*
 *  CMComplexFIR.h
 *  Filter (CoreModem)
 *
 *  Created by Kok Chen on 11/3/05.
 */

#ifndef _CMCOMPLEXFIR_H_
	#define _CMCOMPLEXFIR_H_
	
	#import "CoreFilterTypes.h"
	#import "CMFIR.h"

	typedef struct {
		CMFIR *re ;
		CMFIR *im ;
	} CMComplexFIR ;

	CMComplexFIR *CMComplexFIRDecimateWithCutoff( int factor, float cutoff, float fsampling, int activeTaps ) ;
	CMAnalyticPair CMDecimateAnalyticBuffer( CMComplexFIR *fir, CMAnalyticBuffer *inBuffer, int offset ) ;
	void CMDeleteComplexFIR( CMComplexFIR *fir ) ;
	
	//  Analytic buffers
	CMAnalyticBuffer *CMMallocAnalyticBuffer( int size ) ;
	void CMShiftAnalyticBuffer( CMAnalyticBuffer *b, int samples ) ;
	void freeAnalyticBuffer( CMAnalyticBuffer *b ) ;
	
#endif
