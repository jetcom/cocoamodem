/*
 *  CMDSPWindow.h
 *  Filter (CoreModem)
 *
 *  Created by Kok Chen on 10/24/05
 *
 */

#ifndef _CMDSPWINDOW_H_
	#define _CMDSPWINDOW_H_

	#include <Carbon/Carbon.h>

	float *CMMakeSinc( int n, double w ) ;
	float *CMMakeBlackmanWindow( int n ) ;
	float *CMMakeModifiedBlackmanWindow( int n ) ;

	double CMSinc( int i, int n, double w ) ;
	double CMModifiedBlackmanWindow( int i, int n ) ;
	double CMBlackmanWindow( int i, int n ) ;
	double CMHammingWindow( int i, int n ) ;
	double CMHanningWindow( int i, int n ) ;
	double CMSineWindow( int i, int n ) ;
		
#endif

