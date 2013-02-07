//
//  CMFSKMatchedFilter.h
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//

#ifndef _CMFSKMATCHEDFILTER_H_
	#define _CMFSKMATCHEDFILTER_H_
	
	#import <Foundation/Foundation.h>
	#import "CMTappedPipe.h"
	#import "CMFIR.h"
	#import "CoreModemTypes.h"

	@interface CMFSKMatchedFilter : CMTappedPipe {
		float baud ;
		float demodulated[512] ;	// "split complex" demodulated amplitudes for Mark and Space channels
		CMFIR *markIFilter ;
		CMFIR *markQFilter ;
		CMFIR *spaceIFilter ;
		CMFIR *spaceQFilter ;
		float markIOutput[256] ;
		float markQOutput[256] ;
		float spaceIOutput[256] ;
		float spaceQOutput[256] ;
		float markIBuffer[2048] ;
		float markQBuffer[2048] ;
		float spaceIBuffer[2048] ;
		float spaceQBuffer[2048] ;
		CMDataStream mfStream ;
		Boolean enabled ;
		float *kernel ;
		float width ;		// width of impulse
		int mux ;
	}
	
	- (id)initDefaultFilterWithBaudRate:(float)baudrate ;
	- (void)setDataRate:(float)rate ;
	- (void)setDataRate:(float)rate lowpass:(float)cutoff ;
	
	- (CMFIR*)setupFilter:(CMFIR*)filter length:(int)n ;
	int dotPrKernelSize( int n ) ;
	
	float *createMatchedFilterKernel( int n, int m ) ;
	float *createExtendedMatchedFilterKernel( int n, int m, float cutoff, int extn ) ;

	@end
	
#endif
