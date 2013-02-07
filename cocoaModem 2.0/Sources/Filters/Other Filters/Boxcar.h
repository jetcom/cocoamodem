#ifndef _BOXCAR_H_
	#define _BOXCAR_H_
	
	#include "CMFIR.h"

	CMFIR *BoxcarFilter( int length, int maxLength ) ;
	
	void adjustBoxcarFilter( CMFIR *filter, int newLength ) ;
	void adjustWaveshapedBoxcarFilter( CMFIR *filter, int length ) ;
	
	CMFIR *BlackmanWindow( int length, int maxLength ) ;
	void adjustBlackmanWindow( CMFIR *filter, int length ) ;

#endif

