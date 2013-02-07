//
//  CWModulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/5/07.
	#include "Copyright.h"
	
	
#import "CWModulator.h"
#import "TextEncoding.h"
#import "WBCW.h"


@implementation CWModulator

- (void)initMorse
{
	int i, index ;
	FILE *ext ;
	NSString *name ;
	const char *path ;
	char string[257], *store ;
	
	for ( i = 0; i < 16384; i++ ) ascii[i] = "" ;

	ascii[' '] = " " ;		// interword == 4 inter-element (+3 intercharacter)
	ascii['a'] = ".-" ;
	ascii['b'] = "-..." ;
	ascii['c'] = "-.-." ;
	ascii['d'] = "-.." ;
	ascii['e'] = "." ;
	ascii['f'] = "..-." ;
	ascii['g'] = "--." ;
	ascii['h'] = "...." ;
	ascii['i'] = ".." ;
	ascii['j'] = ".---" ;
	ascii['k'] = "-.-" ;
	ascii['l'] = ".-.." ;
	ascii['m'] = "--" ;
	ascii['n'] = "-." ;
	ascii['o'] = "---" ;
	ascii['p'] = ".--." ;
	ascii['q'] = "--.-" ;
	ascii['r'] = ".-." ;
	ascii['s'] = "..." ;
	ascii['t'] = "-" ;
	ascii['u'] = "..-" ;
	ascii['v'] = "...-" ;
	ascii['w'] = ".--" ;
	ascii['x'] = "-..-" ;
	ascii['y'] = "-.--" ;
	ascii['z'] = "--.." ;
	for ( i = 'a'; i <= 'z'; i++ ) ascii[i-'a'+'A'] = ascii[i] ;
	ascii['0'] = "-----" ;
	ascii['1'] = ".----" ;
	ascii['2'] = "..---" ;
	ascii['3'] = "...--" ;
	ascii['4'] = "....-" ;
	ascii['5'] = "....." ;
	ascii['6'] = "-...." ;
	ascii['7'] = "--..." ;
	ascii['8'] = "---.." ;
	ascii['9'] = "----." ;

	ascii['.'] = ".-.-.-" ;
	ascii[','] = "--..--" ;
	ascii['?'] = "..--.." ;
	ascii[0x22] = ".-..-." ;
	ascii['#'] = ascii['%'] = ascii['&'] = ascii['*'] = ".." ;
	ascii['$'] = "...-..-" ;
	ascii[0x27] = ".----." ;
	ascii['('] = "-.--." ;
	ascii[')'] = "-.--.-" ;
	ascii['+'] = ".-.-." ;
	ascii['-'] = "-....-" ;
	ascii['/'] = "-..-." ;
	ascii[':'] = "-.--." ;
	ascii[';'] = ".-.-" ;
	ascii['<'] = ".-.-." ;
	ascii['='] = "-...-" ;
	ascii['>'] = "...-.-" ;
	ascii['@'] = ".--.-." ;
	
	name = [ NSString stringWithCString:"~/Library/Application Support/cocoaModem/Morse.txt" encoding:kTextEncoding ] ;
	path = [ [ name stringByExpandingTildeInPath ] cStringUsingEncoding:kTextEncoding ] ;
	ext = fopen( path , "r" ) ;
	if ( ext ) {
		while ( 1 ) {
			index = 0 ;
			string[0] = 0 ;
			if ( fscanf( ext, "%d %s", &index, string ) == nil ) break ;
			if ( index <= 0 || index > 16383 || string[0] == 0 ) break ;
			store = malloc( sizeof( char )*( strlen( string ) + 1 ) ) ;
			strcpy( store, string ) ;
			ascii[index] = store ;
			fgets( string, 256, ext ) ;	//  skip to next line
		}
		fclose( ext ) ;
	}
}

#ifdef TESTSPECTRUM
- (void)testSpectrum
{
	int i, j ;
	float x[2048], y[2048], v ;
	CMFFT *spectrum ;
	
	spectrum = FFTSpectrum( 12, YES ) ;
	
	for ( i = 0; i < 4096; i++ ) {
		j = i/512 ;
		v = ( ( j & 1 ) == 0 ) ? 0.0 : 1.0 ;
		x[i] = CMSimpleFilter( waveshape, v )*[ vco nextSample ] ;
	}
	CMPerformFFT( spectrum, &x[0], &y[0] ) ;
	
	v = 0 ;
	for ( i = 0; i < 2048; i++ ) {
		if ( y[i] > v ) v = y[i] ;
	}
	for ( i = 0; i < 2048; i++ ) {
		y[i] = y[i]/v ;
	}
	for ( i = 0; i < 400; i++ ) {
		y[i] = 10.0*log10( y[i+80] ) ;
		if ( y[i] < -120 ) y[i] = -120 ;
		printf( "%f\t%f\n", (i+80)*11025/4096.0-750.0, y[i] ) ;
	}	
	exit( 0 ) ;
}
#endif

//	NOTE: one Morse element at 50 wpm is approx 264 elements at 11025 s/s
- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		
		waveshape = BlackmanWindow( 131, 300 ) ;		//  width 131 = approx 5 ms rise and fall times
		vco = [ [ CMPCO alloc ] init ] ;
		[ vco setCarrier:750.0 ] ;
		testTone = [ [ CMPCO alloc ] init ] ;
		[ testTone setCarrier:700.0 ] ;
		speed = 25.0 ;
		weight = 0.5 ;
		ratio = 3.0 ;
		farnsworth = 1.0 ;
		transmitHoldoff = 0 ;
		ook = 0 ;										//  v0.85
		[ self setGain:1.0 ] ;
		[ self setSpeed:speed ] ;
		[ self initMorse ] ;
		tick = state = 0 ;
		ringProducer = ringConsumer = 0 ;
	}
	return self ;
}

//  set test tone frequency
- (void)setTestFrequency:(float)v
{
	[ testTone setCarrier:v ] ;
}

//  set gain (e.g., from equalizer)
- (void)setGain:(float)v
{
	gain = v ;
}

//  set VCO amplitude from the output attenuator slider
- (void)setOutputScale:(float)value
{
	value *= 0.902 * [ modem outputBoost ] ;							//  v0.88 equalized to PSK peak level and allow 2 dB boost
	[ vco setOutputScale:value ] ;
	[ testTone setOutputScale:value ] ;
}

//	v0.85
- (void)setModulationMode:(int)index
{
	ook = ( index != 0 ) ;
	if ( ook ) {
		[ vco setCarrier:2500.0 ] ;
	}
	else {
		[ vco setCarrier:carrierFreq ] ;
	}
}

- (void)setRisetime:(float)t weight:(float)w ratio:(float)r farnsworth:(float)f
{
	int length ;
	
	length = 131.0*t/5.0 ;
	//  limit change to 1.9 ms to 10.3 ms
	if ( length < 50 ) length = 50 ; else if ( length > 270 ) length = 270 ;
	adjustBlackmanWindow( waveshape, length ) ;

	weight = w ;
	if ( weight < 0.1 ) weight = 0.1 ; else if ( weight > 0.9 ) weight = 0.9 ;
	
	ratio = r ;
	if ( ratio < 2.0 ) ratio = 2.0 ; else if ( ratio > 4.0 ) ratio = 4.0 ;
	
	if ( f > 1.0 ) f = 1.0 ; else if ( f < 0.2 ) f = 0.2 ;
	farnsworth = 1.0/f ;
	
	//  recompute element durations
	[ self setSpeed:speed ] ;
}

//  use basic speed to compute the elements
- (void)setSpeed:(float)inSpeed
{
	int basicElement ;
	
	speed = inSpeed ;
	basicElement = 264.0*50.0/speed ;
	
	interElement = 2.0*(1-weight)*basicElement ;
	dit = 2.0*weight*basicElement ;
	dash = ratio*dit ;
	interCharacter = 3*basicElement*farnsworth ;		// farnsworth is between 1.0 (normal) and 5.0
	interWord = 7*basicElement*farnsworth ;
}

- (void)setCarrier:(float)freq
{
	carrierFreq = freq ;
	[ vco setCarrier:( ook ) ? 2500.0 : freq ] ;
}

- (void)appendASCII:(int)ch
{
	char *seq ;
	Boolean first, shortSpace ;
	int i, j ;
	
	// ignore opt u, i, `, e, n (e.g., umlaut prefix)
	if ( *ascii[ch] == 0 ) {
		//  no user Morse.txt encoding
		if ( ( ch == 168 ) || ( ch == 710 ) || ( ch == 96 )  || ( ch == 180 ) || ( ch == 732 ) ) return ;
	}
	
	i = ringProducer ;
	if ( ch == ' ' || ch == 5 ) {
		ring[i].ascii = ch ;								//  v0.37 insert EndOfTransmit as a space with a character 5 (^E)
		ring[i].duration = interWord - interCharacter ;
		ring[i].state = 0 ;
		ringProducer = ( i+1 )&0xfff ;
		return ;
	}
	
	seq = ( ch == 0xd8 ) ? ascii['0'] : ascii[ch&0x3fff] ;
	if ( *seq == 0 ) return ;
	
	first = YES ;
	//  sanity check, limit to 16 elements
	j = 0 ;
	while ( j++ < 16 ) {
		ring[i].ascii = ( first ) ? ch : 0 ;
		first = NO ;		
		switch ( *seq++ ) {
		case '.':
			ring[i].duration = dit ;
			shortSpace = NO ;
			break ;
		case '*':
			ring[i].duration = dit*3/2 ;
			shortSpace = NO ;
			break ;
		case '-':
			ring[i].duration = dash ;
			shortSpace = NO ;
			break ;
		case '=':
			ring[i].duration = dash*3/2 ;
			shortSpace = NO ;
			break ;
		case '|':
			ring[i].duration = interElement ;
			ring[i].ascii = 0 ;
			ring[i].state = 0 ;
			shortSpace = YES ;
			j-- ;								// space does not count as an element
			break ;
		}
		if ( !shortSpace ) {
			ring[i].state = 1 ;
			i = ( i+1 )&0xfff ;
			ring[i].ascii = 0 ;
			ring[i].duration = interElement ;
			ring[i].state = 0 ;
		}
		if ( *seq <= 0 ) break ;
		i = ( i+1 )&0xfff ;
	}
	//  change last inter-element to inter-character
	ring[i].duration = interCharacter ; 
	ringProducer = ( i+1 )&0xfff ;
}

//  Wait for the character stream to flush through
//  ... and send a end-of-message when we have finished flushing
- (void)insertEndOfTransmit
{
	[ self appendASCII:5 ] ;						//  v0.37 send 5 into modulator
	//[ self transmittedCharacter:5 ] ;						//  @@ fake an immediate end response for now
}

// send transmitted character to modem to echo in the exchange view
- (void)transmittedCharacter:(int)character
{
	if ( modem && character ) {
		[ modem transmittedCharacter:character ] ;			//  send to CW modem that the character has been transmitted
	}
}

- (void)holdOff:(int)milliseconds
{
	transmitHoldoff = milliseconds*(CMFs/1000) ;		//  convert from milliseconds to samples
}

- (Boolean)bufferEmpty
{
	return ( ringProducer == ringConsumer && tick <= 0 ) ;
}

- (int)needData:(float*)outbuf samples:(int)samples
{
	int i, p ;
	float x, xook, keyedBuf[512] ;
	
	//  assume
	//  outputSamplingRate = 11025
	//  outputChannels = 1
	
	assert( samples <= 512 ) ;
	switch ( toneIndex ) {
	case 0:
		if ( vco ) {
			for ( i = 0; i < samples; i++ )  {
				if ( transmitHoldoff > 0 ) {
					xook = 0 ;
					x = CMSimpleFilter( waveshape, xook )*gain ;
					transmitHoldoff-- ;
					if ( modem ) [ (WBCW*)modem keepBreakinAlive:100 ] ;
				}
				else {
					if ( tick <= 0 ) {
						//  check if there is more elements in the ring
						state = 0 ;
						if ( ringProducer != ringConsumer ) {
							state = ring[ringConsumer].state ;
							tick = ring[ringConsumer].duration ;
							p = ring[ringConsumer].ascii ;
							if ( p == 5 || p > 10 ) [ self transmittedCharacter:p ] ;		// v0.37 echo ^E to end stream
							if ( p == 5 ) {
								// v0.37 skip over the ^E
								return 1 ;
							}
							//  moved below "if" v0.48
							//  fixes macro problem in manual transmit
							ringConsumer = ( ringConsumer+1 )&0xfff ;					
							if ( modem ) [ (WBCW*)modem keepBreakinAlive:tick/11 ] ;		//  each tick is about 0.09 ms
						}
					}
					else {
						tick-- ;
					}
					xook = ( state ) ? 1.0 : 0.0 ;
					x = CMSimpleFilter( waveshape, xook )*gain ;
				}
				keyedBuf[i] = x ;
				outbuf[i] = ( ( ook ) ? xook : x*0.78 )*[ vco nextSample ] ;			//  v0.88 drop non-ook by 1.28
			}
			//  for aural monitor
			[ (WBCW*)modem sendSidetoneBuffer:keyedBuf ] ;
			return 1 ;
		}
		break ;
	case 1:
		if ( testTone ) {
			for ( i = 0; i < 512; i++ ) {
				outbuf[i] =  [ testTone nextSample ]*CMSimpleFilter( waveshape, 1.0 )*gain*1.1 ;		//  incorporate waveshape's gain
			}
			return 1 ;
		}
		break ;
	}
	for ( i = 0; i < 512; i++ ) outbuf[i] = 0 ;
				
	return 1 ; // output channels
}

- (void)selectTestTone:(int)index
{
	toneIndex = index ;
}

//  called when flushing
- (void)clearOutput
{
	ringConsumer = ringProducer ;
	tick = 0 ;
}

@end
