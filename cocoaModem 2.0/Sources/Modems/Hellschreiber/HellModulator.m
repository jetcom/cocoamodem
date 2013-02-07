//
//  HellModulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/29/06.
	#include "Copyright.h"


#import "HellModulator.h"
#include "Hellschreiber.h"
#include "CoreModemTypes.h"


@implementation HellModulator

//  HellModulator works in a pull fashion.
//  Characters are sent to the modulator using -appendASCII (or -insertShortIdle or -insertEndofTransmit)
//  Sound buffers are then fetched from the modulator using -fillBuffer.
//  if there are not enough characters to make up the full buffer, idle characters will be generated

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		bitValue = qBitValue = 0 ;
		qBitPhase = 0 ;
		modem = nil ;
		font = nil ;
		cw = NO ;
		diddle = NO ;
		sidebandState = NO ;
		
		//  set up transmit BPF
		carrier = fmCarrier = 0 ;
		fir = nil ;
		transmitBPF = nil ;
		[ self setFrequency:1000.0 ] ;
		//  finish init
		for ( i = 0; i < 16; i++ ) {
			idleColumn[i] = 0 ;
			diddleCharacter[i] = diddleCharacter[i+16] = diddleCharacter[i+32] = 0 ;
		}
		diddleCharacter[22] = diddleCharacter[23] = 0xf0 ;
		charLock = [ [ NSLock alloc ] init ] ;
		[ self resetModulator ] ;
	}
	return self ;
}

- (void)setSidebandState:(Boolean)state
{
	sidebandState = state ;
}

- (void)createTransmitBPF:(float)freq
{
	float bw, w, t, x, f, baseband, sum, n, center ;
	int i ;
	
	if ( modulationMode == HELLFELD ) {
		//  FeldHell
		center = freq ;
		//bw = 225.0 ;
		bw = 115.0 ;				// v0.33
	}
	else {
		// FM Hell
		if ( modulationMode == HELLFM105 ) {
			center = freq + 105.0*0.25 + 10 ;
			if ( sidebandState ) center -= 105.0*0.5 ;
			bw = 70.0 ;
		}
		else {
			center = freq + 245.0*0.25 ;
			if ( sidebandState ) center -= 245.0*0.5 ;
			bw = 100.0 ;
		}
	}
	
	n = 1024 ;
	f = 0.5*center*n/CMFs ;
	w = bw*n/CMFs ;
	
	if ( fir ) free( fir ) ;
	fir = ( float* )malloc( sizeof( float )*n ) ;
	sum = 0 ;
	for ( i = 0; i < n; i++ ) {
		t = n/2 ;
		x = ( i - t )/t ;
		baseband = CMModifiedBlackmanWindow( i, n )*CMSinc( i, n, w ) ;
		sum += baseband ;
		fir[i] = baseband*cos( 2.0*CMPi*f*x ) ;
	}
	w = 2/sum ;
	for ( i = 0; i < n; i++ ) fir[i] *= w ;
	
	if ( transmitBPF ) CMDeleteFIR( transmitBPF ) ;
	transmitBPF = CMFIRFilter( fir, n ) ;
}

- (void)setFont:(HellschreiberFontHeader*)newfont
{
	font = newfont ;
}

- (void)setDiddle:(Boolean)state
{
	diddle = state ;
}

- (float)frequency
{
	return carrier*CMFs/kPeriod ;
}

- (void)setFMCarrier
{
	float c ;
	
	c = carrier ;
	if ( sidebandState == YES ) {
		float freq = [ self frequency ] ;
		if ( modulationMode == HELLFM105 ) {
			c = ( freq - 105.0*0.5 )*kPeriod/CMFs ;
		}
		else if ( modulationMode == HELLFM245 ) {
			c = ( freq - 245.0*0.5 )*kPeriod/CMFs ;
		}
	}
	fmCarrier = c ;
	deviation = ( ( modulationMode == HELLFM105 ) ? 52.5 : 122.5 )*kPeriod/CMFs ;
}

//  setup carrier for self (NCO object)
- (void)setFrequency:(float)freq
{
	float oldFreq = [ self frequency ], diff ;
	
	carrier = freq*kPeriod/CMFs ;
	[ self setFMCarrier ] ;
	diff = fabs( oldFreq - freq ) ;
	if ( diff > 5.0 ) [ self createTransmitBPF:freq ] ;
}

- (void)setMode:(int)mode
{
	modulationMode = mode ;
	
	[ self setFMCarrier ] ;
	[ self setBaudRate:( modulationMode == HELLFM105 ) ? 105.0 : 245.0 ] ;
	[ self createTransmitBPF:carrier*CMFs/kPeriod ] ;
	// v0.33
	bitValue = qBitValue = 0 ;
	qBitPhase = 0 ;
}

/* local */
//  expand a column of bitmap data into a stream structure
- (int)insertBitColumn:(unsigned char*)pixel length:(int)length eof:(Boolean)eof into:(ToneStream*)stream
{
	int i, p ;
	
	if ( modulationMode == HELLFM105 ) {
		//  create 6 column tall fuzzy font version
		for ( i = 0; i < 6; i++ ) {
			p = ( pixel[i*2] + pixel[i*2+1] )/2 ;
			stream->eof = eof ;
			stream->echo = ( i == 0 || eof == YES ) ? pixel : nil ;
			stream->gray = p ;
			stream++ ;
		}
		return 6 ;
	}
	
	for ( i = 0; i < length; i++ ) {
		stream->eof = eof ;
		stream->echo = ( i == 0 || eof == YES ) ? pixel : nil ;
		stream->gray = pixel[i] ;
		stream++ ;
	}
	return length ;
}

/* local */
//  expand a ring buffer entry (per character basis into columns of bitmap stream structures
- (void)expandCharacter:(CharacterStream*)character
{
	int i, columns, bits ;
	unsigned char *body ;
	ToneStream *stream ;
	
	stream = &bitBuffer[0] ;
	
	bitIndex = bitLimit = 0 ;
	if ( character->eof ) {
		bits = [ self insertBitColumn:idleColumn length:14 eof:YES into:stream ] ;
		stream += bits ;
		bitLimit += bits ;
		i = 1 ;
	}
	else {
		body = character->pixmap ;
		// limit to 30 columns (size of ToneStream buffer)
		columns = character->columns ;
		if ( columns > 30 ) columns = 30 ;
		for ( i = 0; i < columns; i++ ) {
			bits = [ self insertBitColumn:body length:14 eof:NO into:stream ] ;
			stream += bits ;
			bitLimit += bits ;
			body += 16 ;		//  font bitmap arranged in 16 pixel tall columns
		}
	}
}

//  insert character into ring buffer
- (void)insertCharacter:(unsigned char*)pixmap columns:(int)width eof:(Boolean)eof
{
	int k ;
	
	[ charLock lock ] ;
	k = charProducer ;
	ring[k].pixmap = pixmap ;
	ring[k].columns = width ;
	ring[k].eof = eof ;
	k = ( k+1 )&RINGMASK ;
	charProducer = k ;
	[ charLock unlock ] ;
}

- (void)flushTransmitBuffer
{
	[ charLock lock ] ;
	charConsumer = charProducer ;
	[ charLock unlock ] ;
}

- (void)insertEndOfTransmit
{
	//  insert eof in the stream column to indicate that the end of transmit stream is reached
	[ self insertCharacter:idleColumn columns:1 eof:YES ] ;
}

- (void)appendASCII:(int)ascii
{
	unsigned char *body ;
	int offset, columns, asciiEquiv ;
	
	if ( font ) {
	
		// undo slashed zero
		if ( ascii == 0xd8 || ascii == 0xf8 ) ascii = '0' ;
		
		offset = font->index[ ascii & 0x1ff ] ;
		body = font->fontData + offset ;
		asciiEquiv = body[0] ;
		columns = body[1] ;
		if ( columns <= 12 ) {
			// only allow fonts of up to 12 columns
			body += 2 ;
			[ self insertCharacter:body columns:columns eof:NO ] ;
		}
	}
}

- (void)insertDiddle
{
	ToneStream *stream ;
	int bits ;
	
	stream = &bitBuffer[0] ;

	bits = [ self insertBitColumn:&diddleCharacter[0] length:14 eof:NO into:stream ] ;
	bits += [ self insertBitColumn:&diddleCharacter[16] length:14 eof:NO into:&stream[ bits] ] ;
	bits += [ self insertBitColumn:&diddleCharacter[32] length:14 eof:NO into:&stream[bits] ] ;
	bitIndex = 0 ;
	bitLimit = bits ;
}

//  insert idle into the stream
- (void)insertShortIdle
{
	bitLimit = [ self insertBitColumn:idleColumn length:14 eof:NO into:&bitBuffer[0] ] ;
	bitIndex = 0 ;
}

//  Fetch next pixel modulation from the ring buffer.
//  If the buffer is empty, an idle bit is first inserted into the buffer.
- (float)getNextPixel
{
	int pix ;
	unsigned char *echo ;
	CharacterStream *character ;
	
	if ( terminated ) return 0 ;
	
	//  check if any more bits left in toneBuffer[]
	if ( bitIndex >= bitLimit ) {
		//  no more bits
		if ( charConsumer == charProducer ) {
			//  no more characters left, send idle column(s)
			if ( diddle ) [ self insertDiddle ] ; else [ self insertShortIdle ] ;
		}
		else {
			//  fetch next character into bit buffer
			character = &ring[charConsumer] ;
			if ( character->eof ) {
				//  at the end of message or a series of messages
				//  eof is inserted into the ring by -insertEndOfTransmit
				terminated = YES ;
				return 0.0 ;
			}
			[ self expandCharacter:(CharacterStream*)character ] ;
			charConsumer = ( charConsumer+1 ) & RINGMASK ;
		}
	}
	
	if ( bitIndex >= bitLimit ) {
		// in case -insertDiddle or -insertShortIdle or -expandCharacter fails, just send a quiet pixel
		return 0.0 ;
	}
	
	//  fetch data from next bit
	echo = bitBuffer[bitIndex].echo ;
	pix = bitBuffer[bitIndex].gray ;
	bitIndex++ ;
	bitIndex &= 0xff ;						//  sanity limit, should not normally reach this large
	
	//  echo all transmitted column 
	if ( echo ) [ self transmittedColumn:echo ] ;

	//  actual pixel value
	return ( pix & 0xff )/255.0 ;
}

- (Boolean)terminated
{
	return terminated ;
}

//  called from config to transmit a pure carrier
- (void)setCW:(Boolean)state
{
	cw = state ;
}

//  (local) Hellschreiber modulator (client interface is -getBufferWithIdleFill::)
-(float)nextSample
{	
	float output, v, mCos, mSin, t, modulation ;
	
	if ( terminated ) return 0.0 ;
	
	if ( cw ) return  [ self sin:carrier ]*0.9 ;		// test CW tone
	
	if ( modulationMode == HELLFM105 || modulationMode == HELLFM245 ) {
	
		//  find when we need to fetch next bit
		if ( [ self advanceBitSample ] ) {
			v = [ self getNextPixel ] ;
			if ( sidebandState ) v = 1.0 - v ;
			if ( qBitPhase == 0 ) bitValue = v ; else qBitValue = v ;
			qBitPhase = ( qBitPhase+1 ) & 0x1 ;
		}		
		t = [ self sinForModulation ] ;
		mSin = t*t ;
		t = [ self cosForModulation ] ;
		mCos = t*t ;
		modulation =  ( bitValue*mCos + qBitValue*mSin )*deviation ;		//  instantaneous deviation
		/* FM */
		output = [ self sin:( fmCarrier + modulation ) ]*0.9 ;	
	}
	else {
		if ( [ self advanceBitSample ] ) bitValue = [ self getNextPixel ] ;
		/* AM */ 
		output = bitValue*[ self sin:carrier ]*0.9 ;						// feld hell
	}
	return output ;
}

- (void)getBufferWithIdleFill:(float*)outbuf length:(int)samples
{
	int i ;
	
	assert( samples <= 512 ) ;
	for ( i = 0; i < samples; i++ ) bpfBuf[i] = [ self nextSample ] ;
	
	//  apply bandpass filter and save into output
	CMPerformFIR( transmitBPF, bpfBuf, samples, outbuf ) ;
}

- (void)resetModulator
{
	bitIndex = bitLimit = 0 ;
	[ charLock lock ] ;
	charProducer = charConsumer = 0 ;
	[ charLock unlock ] ;
	terminated = NO ;
}

- (void)setModemClient:(Hellschreiber*)client
{
	modem = client ;
}

- (void)transmittedColumn:(unsigned char *)column
{
	float pix[28], v ;
	int i ;
	
	if ( modem ) {
		if ( modulationMode == HELLFM105 ) {
			for ( i = 0; i < 6; i++ ) {
				v = ( column[i*2] + column[i*2+1] )/510.0 ;
				if ( v < 0 ) v = 0 ; else if ( v > 1.0 ) v = 1.0 ;
				pix[i*2] = pix[i*2+1] = pix[i*2+14] = pix[i*2+15] = v ;
			}
		}
		else {
			for ( i = 0; i < 12; i++ ) {
				v = column[i]/255.0 ;
				pix[i] = pix[i+14] = v ;
			}
		}
		pix[12] = pix[13] = pix[26] = pix[27] = 0 ;
		[ modem addColumn:pix index:1 xScale:2 ] ;
	}
}

@end
