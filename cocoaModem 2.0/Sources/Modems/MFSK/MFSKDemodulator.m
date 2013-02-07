//
//  MFSKDemodulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/30/06.
	#include "Copyright.h"
	
	
#import "MFSKDemodulator.h"
#import "MFSK.h"
#import "MFSKVaricode.h"

//  http://www.arrl.org/FandES/field/regulations/techchar/MFSK.html

@implementation MFSKDemodulator

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		modem = nil ;
		m = 16 ;							//  16 for MFSK16, 18 for DominoEX
		useFEC = YES ;
		interleaverStages = 10 ;			//  10 for MFSK16, 4 default interleaver stages for DominoEX
		
		//   set up data pipeline (256 frames) and start decode thread
		decodePipe = [ [ DataPipe alloc ] initWithCapacity:sizeof( float )*64*256 ] ;
		[ NSThread detachNewThreadSelector:@selector(decodeThread:) toTarget:self withObject:self ] ;
		
		//  carrier to noise estimate and delay line
		cnr = 30.0 ;
		for ( i = 0; i < 64; i++ ) delayedCNR[i] = 30.0 ;
		cnrCycle = 0 ;
		squelchThreshold = 1.5 ;
		
		//  convolutional and varicode decoders
		decodeLag = 45 ;
		fec = [ [ ConvolutionCode alloc ] initWithConstraintLength:7 generator:0x6d generator:0x4f ] ;
		[ fec setTrellisDepth:decodeLag ] ;
		varicode = [ [ MFSKVaricode alloc ] init ] ;
		decodedBits = 0 ;
		previousChar = 0 ;
		
		//  demodulator
		afcFFT = FFTForward( 9, NO /*window*/ ) ;
		freqIndicator = nil ;
		freqLabel = nil ;
		softDecode = YES ;
		afcState = 1 ;
		lowestAFCBin = 4 ;
		freqOffset = 0.0 ;
		dFreqOffset = 0.1 ;
		sidebandState = YES ;		// usb (high RF = high audio)
		[ self newFreqAlignment ] ;
	}
	return self ;
}

- (Boolean)useFEC
{
	return useFEC ;
}

- (void)setUseFEC:(Boolean)state
{
	//	Implemented in DominoDemodulator; MFSK16 always has FEC on
}

- (void)setInterleaverStages:(int)stages
{
	if ( stages < 4 ) stages = 4 ; else if ( stages > 10 ) stages = 10 ;
	interleaverStages = stages ;
}

- (void)setFreqIndicator:(MFSKIndicator*)indicator label:(MFSKIndicatorLabel*)label
{
	freqIndicator = indicator ;
	freqLabel = label ;
}

- (void)setModem:(MFSK*)client
{
	modem = client ;
}

//  YES = USB (high RF = high audio)
- (void)setSidebandState:(Boolean)state
{
	sidebandState = state ;
}

- (void)resetFEC
{
	int i ;
	
	[ fec resetTrellis ] ;
	//  clear the bin averaging (for detecting lowest and highest frequency bins)
	for ( i = 0; i < 24; i++ ) smoothedVector[i] = 0 ;
	//  choose 11 cycle comb for clock extraction filter
	[ self setClockExtraction:11 ] ;
}

- (void)resetDemodulatorState
{
	int i ;
	float dummy[32] ;
	
	//  reset deinterleaver
	interleaverIndex = 0 ;
	for ( i = 0; i < 160; i++ ) interleaverRegister[i] = 0 ;
	
	memset( timeAperture, 0, sizeof( float )*64 ) ;
	memset( iTime, 0, sizeof( float )*2048 ) ;
	memset( qTime, 0, sizeof( float )*2048 ) ;
	ringIndex = 0 ;
	for ( i = 0; i < 32; i++ ) CMPerformFIR( clockExtractFilter, dummy, 32, iTime ) ;

	[ self resetFEC ] ;
	hasSync = NO ;
}

//  Once frequency is properly aligned, the lowerBound will point at the lowest tone and the upperBound will be lowerBound+15.
- (void)newFreqAlignment
{
	//  start with an frequency offset of center of a bin that is 4 full bins into the 32 bin FFT
	//  this allows us to pull 24 bins out of the data and allow a drift of up of (+,-)4 bins (62.5 Hz)
	absoluteOffset = 3*16+8 ;
	correction = 0.0 ;
	bufferedFreqProducer = bufferedFreqConsumer = 0 ;	
}

//  set the length of the clock extraction kernel.
//  1 <= cycles <= clockExtractionCycles
//  use 5 cycles for acquisition, then switch to 11 then to 15 cycles once locked
- (void)setClockExtraction:(int)cycles
{
	int i ;
	
	if ( cycles > clockExtractionCycles ) cycles = clockExtractionCycles ;
	
	for ( i = 0; i < (15-cycles)*32; i++ ) clockExtractKernel[i] = 0 ;
	for ( ; i < 480; i++ ) clockExtractFilter->kernel[i] = clockExtractKernel[i] ;
}

//  new buffer of 32 complex samples arrived
//  data is assumed to be sampled at 500 samples/second (each symbol clock is therefore 32 samples from one another)
//
//  32 point FFT is performed even though only 16 (18 for DominoEX) output bins are needed -- this is so the signal can be off tuned and still be decoded
//
//  This step uses a sliding time window to identify the symbol boundary.  When it is found, the bit aligned 32-vector data is
//  passed to -afcVector:
//
//	Note: the premise is that if a 32 point transform is not done at bit boundaries, the spectral peaks will overlap bins and 
//  spectal amplitude peaks are centered in a bin only when there is perfect sync of the transform to bit boundaries.
//  Since energy (amplitude squared) is constant, the transform that yields the largest spectral peak therefore happens we are synced to symbol boundaries.
//
//	i.e., -newBuffer:: finds the time alignment and -afcVector: finds the frequency alignment

- (void)newBufferedData:(float*)iBuf imag:(float*)qBuf
{
	DSPSplitComplex input, output ;
	int i, k, index, size, dt ;
	float v, maxv, mean, track[32], timeVector[32] ;
	float iSpec[32], qSpec[32] ;
	
	if ( iBuf[0] == 0 && qBuf[0] == 0 ) return ;
	
	//  copy the next 32 samples into the double ring buffer
	size = 32*sizeof( float ) ;
	ringIndex %= 1024 ;
	memcpy( &iTime[ringIndex], &iBuf[0], size ) ;
	memcpy( &iTime[ringIndex+1024], &iBuf[0], size ) ;
	memcpy( &qTime[ringIndex], &qBuf[0], size ) ;
	memcpy( &qTime[ringIndex+1024], &qBuf[0], size ) ;
	ringIndex = ( ringIndex + 32 ) % 1024 ;
	
	//  Find approx time peak by sliding a 32-point time window and taking a 32-point FFT for each window.
	//  For each FFT, the max energy bin is recorded.
	//  The clockExtractFilter provides a sufficient lowpass comb to interpolate the missing data.
	for ( maxv = 0, k = 0; k < 32; k++ ) {
	
		index = ( ringIndex + ( 1024 - 96 ) )%1024 ;
		input.realp = &iTime[k+index] ;
		input.imagp = &qTime[k+index] ;
		output.realp = &iSpec[0] ;
		output.imagp = &qSpec[0] ;
		//  32 point FFT
		CMPerformComplexFFT( clockExtractFFT, &input, &output ) ;

		for ( mean = 0, i = 0; i < 32; i++ ) {
			v = ( iSpec[i]*iSpec[i] + qSpec[i]*qSpec[i] ) ;
			mean += v*v ;
		}
		//  time vector
		timeVector[k] = mean ;
		if ( mean > maxv ) maxv = mean ;
	}
	if ( maxv < 0.0001 ) return ;
	
	//  average normalized vector into denoised timeAperture
	maxv = 1.0/maxv ;
	for ( k = 0; k < 32; k++ ) timeAperture[k] =  timeAperture[k]*0.94 + timeVector[k]*maxv ;
	
	//  apply the (running) lowpassed comb to find the symbol alignment
	CMPerformFIR( clockExtractFilter, timeAperture, 32, track ) ;
		
	//  Find the zero crossing from the 32 filtered symbol transitions. 	
	//  The premise is that the output of the comb will produce a periodic signal that is aligned to the symbol timing.
	//  When we find a zero crossing, that identifies the symbol time alignment and an aligned 32 element data array (at 500 Hz sampling rate) is 
	//  passed to -newTimeVector: to process.
	for ( i = 0; i < 32; i++ ) {
		//  look for a zero crossing and then apply offset to the peak
		//	assume cycle of 32
		if ( prevClock <= 0 && track[i] > 0 ) {		
			dt = i ;
			index = ( ringIndex + dt + ( 1024 - 256 + 24 ) ) % 1024 ;		//  the offset is derived from optimizong DominoEX 11 at -10.5 dB SNR
			if ( fabs( prevClock ) < track[dt]*1.5 ) index-- ;				//  v0.73 pick the closer sample to zero crossing
			timeOffset = dt ;
			input.realp = &iTime[index] ;
			input.imagp = &qTime[index] ;
			[ self afcVector:&input length:32 ] ;
		}
		prevClock = track[i] ;
	}	
}

//	(Thread)
//	the actual decode/print is done from this thread so as not to back up earlier stages
- (void)decodeThread:(id)client
{
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	float packed[64] ;
	
	while ( 1 ) {
		[ decodePipe readData:packed length:sizeof( float )*32*2 ] ;
		[ self newBufferedData:&packed[0] imag:&packed[32] ] ;
	}
	[ pool release ] ;
}

//	v0.73
//  add a pipeline before processing the vector
- (void)newBuffer:(float*)iBuf imag:(float*)qBuf
{
	float packed[64], *q ;
	int i ;
	
	q = &packed[32] ;
	for ( i = 0; i < 32; i++ ) {
		packed[i] = iBuf[i] ;
		q[i]= qBuf[i] ;
	}
	[ decodePipe write:packed length:sizeof( float )*32*2 ] ;
}

- (void)updateRxFreqField:(int)binoffset
{
	int offset ;
	
	offset = ( binoffset == 0 ) ? 0 : ( absoluteOffset - MFSKFREQOFFSET + (binoffset*16) ) ;
	if ( binoffset != 0 ) [ modem applyRxFreqOffset:( absoluteOffset + (binoffset*16) - 128 )*0.976 ] ;
}

- (void)updateRxFreqLabelAndField:(int)binoffset
{
	int offset ;
	
	offset = ( binoffset == 0 ) ? 0 : ( absoluteOffset - MFSKFREQOFFSET + (binoffset*16) ) ;
	[ freqLabel setOffset:offset ] ;
	if ( binoffset != 0 ) {
		// update client once locked
		// each bin equivalent tp 500/512 Hz = 0.976 Hz
		// when tuned, the offset total offset that is 128 FFT bins away 
		// i.e., absoluteOffset + (binOffset*16) = 128
		[ modem applyRxFreqOffset:( absoluteOffset + (binoffset*16) - 128 )*0.976 ] ;
	}
}

- (void)afcVector:(DSPSplitComplex*)vector length:(int)length
{
	//  override by implementation
}

- (QuadBits)softEncode:(float*)vector
{
	//  override by implementation
	QuadBits result ;
	
	return result ;
}

//	v0.73
- (void)waterfallClicked
{
	[ self resetDemodulatorState ] ;
}

- (void)setTrellisDepth:(int)depth
{
	decodeLag = depth ;
	[ fec setTrellisDepth:depth ] ;
}

- (void)setSoftDecodeState:(Boolean)state
{
	softDecode = state ;
}

- (void)setAFCState:(int)state
{
	afcState = state ;
}

- (void)setSquelchThreshold:(float)value
{
	squelchThreshold = value ;
}


//	------- FEC -------

//  Receives the next 4 bits of data (decoded from a gray code of one of the 16 tone offsets)
//  deinterleaving is done here
- (void)decodeBits:(QuadBits)quad
{
	//  deinterleave the soft quad, and send as dibits to the convolutional decoder
	quad = [ self deinterleave:quad ] ;
	[ self convolutionDecodeMSB:quad.bit[0] LSB:quad.bit[1] ] ;		//  decode first two bits
	[ self convolutionDecodeMSB:quad.bit[2] LSB:quad.bit[3] ] ;		//  decode next two bits
}

//  Use the convolutional decoder to decode the next soft dibit and send to Varicode decode
- (void)convolutionDecodeMSB:(float)msb LSB:(float)lsb
{
	[ self varicodeDecode:[ fec decodeMSB:msb LSB:lsb ] ] ;
}

//	Accumulate bits into the bit register.
//  If the signature of the end of a character is seen, flush the accumulated bits to the Varicode decoder.
- (void)varicodeDecode:(int)bit 
{
	int c, cc ;
	
	decodedBits = ( ( decodedBits * 2 )  | ( bit & 1 ) ) ;
	
	c = decodedBits & 0x7;
	if ( c == 0x1 ) {
		//  001 received.  00 is the stop bits of a code word and 1 is the start bit of the new code.
		c = [ varicode decode:( decodedBits >> 1) ] ;
		if ( c > 0 && modem ) {
			if ( previousChar != '\r' || c != '\n' ) {
				cc = c ;
				if ( c == '\r' ) cc = '\n' ;			// v0.73
				if ( cnr > squelchThreshold ) [ modem displayCharacter:cc ] ;
			}
			previousChar = c ;
		}
		//  retain only the most recent non-zero bit
		decodedBits = 1;
	}
}

//	override this in MFSK16 and DominoEX classes
- (QuadBits)deinterleave:(QuadBits)p
{
	return p ;
}

@end
