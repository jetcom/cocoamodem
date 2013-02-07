//
//  CMATCTypes.h
//  CoreModem
//
//  Created by Kok Chen on 10/25/05.
//	(ported from cocoaModem, original file dated Sat Aug 07 2004)
//

#ifndef _CMATCTYPES_H_
	#define _CMATCTYPES_H_
	
	typedef struct {
		float mark ;
		float space ;
	} CMATCPair ;

	typedef struct {
		CMATCPair data[768] ;
		float attack, decay ;
		float markAGC, spaceAGC ;
	} CMATCStream ;
	
	typedef struct {
		int startingIndex ;
		int endingIndex ;
		int eq ;
		int bits[8] ;
		int weight ;
		int decoded ;
	} CMATCCase ;

#endif
