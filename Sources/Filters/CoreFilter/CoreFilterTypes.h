//
//  CoreFilterTypes.h
//  Filter (CoreModem)
//
//  Created by Kok Chen on 11/11/05.

#ifndef _COREFILTERTYPES_H_
	#define _COREFILTERTYPES_H_
	
	#import "AudioDeviceTypes.h"
	
	#define CMFs		11025.0
	#define CMPi   3.141592653589793
	
	typedef struct {
		float *array ;
		long userData ;
		float samplingRate ;
		int sourceID ;
		int samples ;
		int components ;
		int channels ;
	} CMDataStream ;
	
	typedef struct {
		float re ;
		float im ;
	} CMAnalyticPair ;

	typedef struct {
		float *re ;
		float *im ;
		int size ;
	} CMAnalyticBuffer ;
	
	
#endif
