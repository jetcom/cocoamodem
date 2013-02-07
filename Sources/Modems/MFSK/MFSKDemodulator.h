//
//  MFSKDemodulator.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/30/06.


#ifndef _MFSKDEMODULATOR_H_
	#define _MFSKDEMODULATOR_H_

	#import <Cocoa/Cocoa.h>
	#import "CoreFilter.h"
	#import "CMFFT.h"
	#import "CMVaricode.h"
	#import "ConvolutionCode.h"
	#import "DataPipe.h"
	#import "MFSKFEC.h"
	#import "MFSKIndicator.h"
	#import "MFSKIndicatorLabel.h"
	
	typedef struct {
		float bin[24] ;
	} FreqBins ;
	
	@class MFSK ;

	@interface MFSKDemodulator : NSObject {
		
		MFSK *modem ;
		int m ;									//  "m" for mFSK (16 for MFSK16, 18 for DominoEX)
		
		//	GUI
		MFSKIndicator *freqIndicator ;
		MFSKIndicatorLabel *freqLabel ;
		
		//  clock extraction (from input data)
		float iTime[2048], qTime[2048] ;		//  double ring buffers (1024 actual samples)
		float timeAperture[64] ;				//  half-rate DominoEX needs all 64 values, the MFSK16 and full rate DominoEX need only 32
		int ringIndex ;
		int timeOffset ;
		float prevClock ;
		int clockExtractionCycles ;
		CMFFT *clockExtractFFT ;
		CMFIR *clockExtractFilter ;
		float clockExtractKernel[768] ;
		
		//	AFC
		CMFFT *afcFFT ;
		float freqOffset, dFreqOffset ;
		int absoluteOffset ;
		float correction ;
		float smoothedVector[24] ;
		FreqBins bufferedFreqBins[256] ;
		
		//  states
		Boolean hasSync ;
		Boolean softDecode ;
		Boolean sidebandState ;					//  NO = LSB
		int afcState ;
		int lowestAFCBin ;

		//	Data Pipeline (threaded)
		int bufferedFreqProducer, bufferedFreqConsumer ;
		
		//  deinterleaver
		int interleaverIndex ;
		int interleaverStages ;
		float interleaverRegister[160] ;
		
		//  convolutional decoder
		ConvolutionCode *fec ;
		unsigned int decodedBits ;
		int decodeLag ;
		CMVaricode *varicode ;
		Boolean useFEC ;
		
		// CRLF detection
		int previousChar ;
		
		float squelchThreshold ;
		float cnr ;
		float delayedCNR[64] ;
		int cnrCycle ;
		
		//	v0.73 import data into a pipe (decodeThread:)
		DataPipe *decodePipe ;

	}
	
	- (Boolean)useFEC ;
	- (void)setUseFEC:(Boolean)state ;
	- (void)setInterleaverStages:(int)stages ;

	- (void)setModem:(MFSK*)client ;	
	- (void)setClockExtraction:(int)cycles ;
	- (void)setSidebandState:(Boolean)state ;
	- (void)newFreqAlignment ;
	- (void)setSoftDecodeState:(Boolean)state ;
	- (void)setAFCState:(int)state ;
	- (void)setTrellisDepth:(int)depth ;
	- (void)setSquelchThreshold:(float)value ;
	
	//	Demodulator
	- (void)resetDemodulatorState ;
	- (void)afcVector:(DSPSplitComplex*)vector length:(int)length ;			//  v0.73
		
	//	GUI
	- (void)updateRxFreqLabelAndField:(int)binoffset ;						//  v0.73
	- (void)updateRxFreqField:(int)binoffset ;								//  v0.73
	- (void)setFreqIndicator:(MFSKIndicator*)indicator label:(MFSKIndicatorLabel*)label ;

	// new data from MFSKReceiver
	- (void)newBuffer:(float*)real imag:(float*)imag ;
	- (void)waterfallClicked ;												//	v0.73

	//  FEC
	- (QuadBits)deinterleave:(QuadBits)p ;
	- (void)convolutionDecodeMSB:(float)msb LSB:(float)lsb ;
	- (void)decodeBits:(QuadBits)bits ;
	- (void)varicodeDecode:(int)bit ;

	@end

#endif
