//
//  CoreModemTypes.h
//  CoreModem
//
//  Created by Kok Chen on 10/24/05.
//
//

#ifndef _COREMODEMTYPES_H_
	#define _COREMODEMTYPES_H_
	
	#include "CoreFilterTypes.h"
	
	typedef struct {
		float freq ;
		double deltaTheta ;
		double cost ;
		double sint ;
		double theta ;
	} CMDDA ;
	
	typedef struct {
		double mark ;
		double space ;
		double baud ;
	} CMTonePair ;
		

	

#endif
