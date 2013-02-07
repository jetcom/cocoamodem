//
//  DominoModulator.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 7/16/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DominoModulator.h"
#import "cocoaModemParams.h"
#import "DominoVaricode.h"
#import "MFSKVaricode.h"
#import "TextEncoding.h"

@implementation DominoModulator

//static char *defaultBeaconString = "cocoaModem 2.0  " ;
static int nibbleValue[] = { '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f' } ;
static char asciiToNibble[] = {
	/* 0 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 1 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 2 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 3 */	0,	1,	2,	3,	4,	5,	6,	7,	8,	9,	0,	0,	0,	0,	0,	0,	
	/* 4 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,
	/* 5 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 6 */	0,	10,	11,	12,	13,	14,	15,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 7 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 8 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* 9 */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* a */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* b */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* c */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* d */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* e */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
	/* f */	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	0,	
} ;

static int primaryFECEncodeTable[260] = {
	/*0*/	0,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	8,  	95,  	
	/*1*/	13,  	95,  	95,  	13,  	95,  	95,  	95,  	95,  	95,  	95,  	
	/*2*/	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	
	/*3*/	95,  	95,  	32,  	33,  	34,  	35,  	36,  	37,  	38,  	39,  	
	/*4*/	40,  	41,  	42,  	43,  	44,  	45,  	46,  	47,  	48,  	49,  	
	/*5*/	50,  	51,  	52,  	53,  	54,  	55,  	56,  	57,  	58,  	59,  	
	/*6*/	60,  	61,  	62,  	63,  	64,  	65,  	66,  	67,  	68,  	69,  	
	/*7*/	70,  	71,  	72,  	73,  	74,  	75,  	76,  	77,  	78,  	79,  	
	/*8*/	80,  	81,  	82,  	83,  	84,  	85,  	86,  	87,  	88,  	89,  	
	/*9*/	90,  	91,  	92,  	93,  	94,  	95,  	96,  	97,  	98,  	99,  	
	/*10*/	100,  	101,  	102,  	103,  	104,  	105,  	106,  	107,  	108,  	109,  	
	/*11*/	110,  	111,  	112,  	113,  	114,  	115,  	116,  	117,  	118,  	119,  	
	/*12*/	120,  	121,  	122,  	123,  	124,  	125,  	126,  	95,  	95,  	95,  	
	/*13*/	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	
	/*14*/	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	
	/*15*/	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	95,  	
	/*16*/	160,  	161,  	162,  	163,  	164,  	165,  	166,  	167,  	168,  	169,  	
	/*17*/	170,  	171,  	172,  	173,  	174,  	175,  	176,  	177,  	178,  	179,  	
	/*18*/	180,  	181,  	182,  	183,  	184,  	185,  	186,  	187,  	188,  	189,  	
	/*19*/	190,  	191,  	192,  	193,  	194,  	195,  	196,  	197,  	198,  	199,  	
	/*20*/	200,  	201,  	202,  	203,  	204,  	205,  	206,  	207,  	208,  	209,  	
	/*21*/	210,  	211,  	212,  	213,  	214,  	215,  	216,  	217,  	218,  	219,  	
	/*22*/	220,  	221,  	222,  	223,  	224,  	225,  	226,  	227,  	228,  	229,  	
	/*23*/	230,  	231,  	232,  	233,  	234,  	235,  	236,  	237,  	238,  	239,  	
	/*24*/	240,  	241,  	242,  	243,  	244,  	245,  	246,  	247,  	248,  	249,  	
	/*25*/	250,  	251,  	252,  	253,  	254,  	255,  	95,  	95,  	95,  	95,  	
} ;

static int secondaryFECEncodeTable[260] = {
	//		0		1		2		3		4		5		6		7		8		9
	//	    ---------------------------------------------------------------------------
	/*0*/	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	
	/*1*/	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	
	/*2*/	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	
	/*3*/	0,  	0,  	1,  	2,  	3,  	0,  	5,  	6,  	7,  	9,  	
	/*4*/	10,  	11,  	12,  	24,  	25,  	26,  	27,  	28,  	14,  	15,  	
	/*5*/	16,  	17,  	18,  	19,  	20,  	21,  	22,  	23,  	29,  	30,  	
	/*6*/	31,  	153,  	154,  	155,  	156,  	127,  	128,  	129,  	130,  	131,  	
	/*7*/	132,  	133,  	134,  	135,  	136,  	137,  	138,  	139,  	140,  	141,  	
	/*8*/	142,  	143,  	144,  	145,  	146,  	147,  	148,  	149,  	150,  	151,  	
	/*9*/	152,  	157,  	158,  	159,  	0,  	4,  	0,  	127,  	128,  	129,  	
	/*10*/	130,  	131,  	132,  	133,  	134,  	135,  	136,  	137,  	138,  	139,  	
	/*11*/	140,  	141,  	142,  	143,  	144,  	145,  	146,  	147,  	148,  	149,  	
	/*12*/	150,  	151,  	152,  	10,  	158,  	11,  	0,  	0,  	0,  	0,  	
	/*13*/	0,  	132,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	
	/*14*/	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	
	/*15*/	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	0,  	
	/*16*/	0,  	0,  	0,  	138,  	0,  	0,  	0,  	0,  	0,  	129,  	
	/*17*/	127,  	31,  	0,  	0,  	144,  	0,  	0,  	0,  	16,  	17,  	
	/*18*/	0,  	15,  	0,  	0,  	0,  	0,  	130,  	154,  	0,  	0,  	
	/*19*/	0,  	155,  	127,  	127,  	127,  	127,  	127,  	127,  	131,  	129,  	
	/*20*/	131,  	131,  	131,  	131,  	135,  	135,  	135,  	135,  	130,  	140,  	
	/*21*/	141,  	141,  	141,  	141,  	141,  	150,  	14,  	147,  	147,  	147,  	
	/*22*/	147,  	151,  	0,  	128,  	127,  	127,  	127,  	127,  	127,  	127,  	
	/*23*/	131,  	129,  	131,  	131,  	131,  	131,  	135,  	135,  	135,  	135,  	
	/*24*/	0,  	140,  	141,  	141,  	141,  	141,  	141,  	0,  	0,  	147,  	
	/*25*/	147,  	147,  	147,  	151,  	0,  	151,  	0,  	0,  	0,  	0,  	
} ;


//	(Private API)
//	unpack Varicode into string of nibbleValues
- (void)unpack:(CodeString*)codeString from:(unsigned short*)packedVaricode
{
	int i, j, packed, n ;
	unsigned char *s ;
	
	for ( i = 0; i < 256; i++ ) {
		s = codeString[i] ;
		for ( j = 0; j < 4; j++ ) s[j] = 0 ;	//  first zero out unpacked code
		packed = packedVaricode[i] ;
		if ( packed == 0 ) s[0] = nibbleValue[0] ;
		else {
			if ( ( packed & 0xff0 ) == 0 ) {
				n = packed & 0xf ;
				if ( packed < 8 ) s[0] = nibbleValue[n] ;
				else {
					s[0] = nibbleValue[0] ;
					s[1] = nibbleValue[n] ;
				}
			}
			else if ( ( packed & 0xf00 ) == 0 ) {
				n = ( packed / 16 ) & 0xf ;
				if ( n < 8 ) {
					s[1] = nibbleValue[ packed & 0xf ] ;
					packed /= 16 ;
					s[0] = nibbleValue[ packed & 0xf ] ;
				}
				else {
					s[2] = nibbleValue[ packed & 0xf ] ;
					packed /= 16 ;
					s[1] = nibbleValue[ packed & 0xf ] ;
					s[0] = nibbleValue[0] ;
				}
			}
			else {
				s[2] = nibbleValue[ packed & 0xf ] ;
				packed /= 16 ;
				s[1] = nibbleValue[ packed & 0xf ] ;
				packed /= 16 ;
				s[0] = nibbleValue[ packed & 0xf ] ;
			}
		}
	}
}

//#define MAKETABLE

#ifdef MAKETABLE
- (void)makeRangeFrom:(int)a to:(int)z offset:(int)offset
{
	int i ;
	for ( i = a; i <= z; i++ ) secondaryFECEncodeTable[i] = i - a + offset ;
}

- (void)setRangeFrom:(int)a to:(int)z offset:(int)offset
{
	int i ;
	for ( i = a; i <= z; i++ ) secondaryFECEncodeTable[i] = offset ;
}

- (void)makeFECTable
{
	int i, j, n ;
	
	for ( i = 0; i < 260; i++ ) secondaryFECEncodeTable[i] = 0 ;				//  secondary channel underscore
	[ self makeRangeFrom:'A' to:'Z' offset:127 ] ;
	[ self makeRangeFrom:'a' to:'z' offset:127 ] ;
	[ self makeRangeFrom:'0' to:'9' offset:14 ] ;
	[ self makeRangeFrom:' ' to:'"' offset:1 ] ;
	secondaryFECEncodeTable['_'] = 4 ;
	[ self makeRangeFrom:'$' to:'&' offset:5 ] ;
	[ self makeRangeFrom:'\'' to:'*' offset:9 ] ;
	[ self makeRangeFrom:'+' to:'/' offset:24 ] ;
	[ self makeRangeFrom:':' to:'<' offset:29 ] ;
	[ self makeRangeFrom:'=' to:'@' offset:153 ] ;
	[ self makeRangeFrom:'[' to:']' offset:157 ] ;
	
	[ self setRangeFrom:192 to:197 offset:secondaryFECEncodeTable['A'] ] ;
	[ self setRangeFrom:224 to:229 offset:secondaryFECEncodeTable['A'] ] ;
	secondaryFECEncodeTable[170] = secondaryFECEncodeTable['A'] ;
	
	secondaryFECEncodeTable[223] = secondaryFECEncodeTable['B'] ;
	
	secondaryFECEncodeTable[199] = secondaryFECEncodeTable[231] = secondaryFECEncodeTable[169] = secondaryFECEncodeTable['C'] ;
	
	secondaryFECEncodeTable[208] = secondaryFECEncodeTable[186] = secondaryFECEncodeTable['D'] ;		// D bar and degree symbol

	[ self setRangeFrom:232 to:235 offset:secondaryFECEncodeTable['E'] ] ;
	[ self setRangeFrom:200 to:203 offset:secondaryFECEncodeTable['E'] ] ;
	secondaryFECEncodeTable[230] = secondaryFECEncodeTable[198] = secondaryFECEncodeTable['E'] ;
	
	secondaryFECEncodeTable[131] = secondaryFECEncodeTable['F'] ;										// script f

	[ self setRangeFrom:236 to:239 offset:secondaryFECEncodeTable['I'] ] ;
	[ self setRangeFrom:204 to:207 offset:secondaryFECEncodeTable['I'] ] ;

	secondaryFECEncodeTable[163] = secondaryFECEncodeTable['L'] ;										//  pound sterling
	
	secondaryFECEncodeTable[209] = secondaryFECEncodeTable[241] = secondaryFECEncodeTable['N'] ;		//  N tilde

	[ self setRangeFrom:242 to:246 offset:secondaryFECEncodeTable['O'] ] ;
	[ self setRangeFrom:210 to:214 offset:secondaryFECEncodeTable['O'] ] ;

	secondaryFECEncodeTable[174] = secondaryFECEncodeTable['R'] ;										//  registered name

	[ self setRangeFrom:249 to:252 offset:secondaryFECEncodeTable['U'] ] ;
	[ self setRangeFrom:217 to:220 offset:secondaryFECEncodeTable['U'] ] ;

	secondaryFECEncodeTable[215] = secondaryFECEncodeTable['X'] ;										//  multiply

	secondaryFECEncodeTable[221] = secondaryFECEncodeTable['Y'] ;
	secondaryFECEncodeTable[253] = secondaryFECEncodeTable['Y'] ;
	secondaryFECEncodeTable[255] = secondaryFECEncodeTable['Y'] ;
	
	secondaryFECEncodeTable[216] = secondaryFECEncodeTable['0'] ;										//  phi
	secondaryFECEncodeTable[181] = secondaryFECEncodeTable['1'] ;										//  superscript 1
	secondaryFECEncodeTable[178] = secondaryFECEncodeTable['2'] ;										//  superscript 2
	secondaryFECEncodeTable[179] = secondaryFECEncodeTable['3'] ;										//  superscript 3
	secondaryFECEncodeTable[191] = secondaryFECEncodeTable['?'] ;										//  turned question mark
	secondaryFECEncodeTable[187] = secondaryFECEncodeTable['>'] ;										//  >>
	secondaryFECEncodeTable[171] = secondaryFECEncodeTable['<'] ;										//  <<
	secondaryFECEncodeTable['{'] = secondaryFECEncodeTable['('] ;
	secondaryFECEncodeTable['}'] = secondaryFECEncodeTable[')'] ;
	secondaryFECEncodeTable['|'] = secondaryFECEncodeTable['\\'] ;

	for ( j = 0; j < 256; j += 10 ) {
		printf( "\t/*%d*/\t", j/10 ) ;
		for ( i = 0; i < 10; i++ ) printf( "%d,  \t", secondaryFECEncodeTable[j+i] ) ;
		printf( "\n" ) ;
	}
	printf( "--------------------------\n" ) ;
	
	for ( i = 0; i < 256; i++ ) primaryFECEncodeTable[i] = i ;
	for ( ; i < 260; i++ ) primaryFECEncodeTable[i] = '_' ;
	//  map away the slots that are used by the secondary table
	for ( i = 0; i < 260; i++ ) {
		n = secondaryFECEncodeTable[i] ;
		if ( n != 0 ) primaryFECEncodeTable[n] = '_' ;
	}
	primaryFECEncodeTable['\n'] ='\r' ;
	
	for ( j = 0; j < 256; j += 10 ) {
		printf( "\t/*%d*/\t", j/10 ) ;
		for ( i = 0; i < 10; i++ ) printf( "%d,  \t", primaryFECEncodeTable[j+i] ) ;
		printf( "\n" ) ;
	}
}
#endif

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		binWidth = 15.625 ;
		baudDDA = binWidth*kPeriod/CMFs ;
		useFEC = NO ;								//  default to no FEC
		interleaverStages = 4 ;						//  default FEC to 4 stage interleaver
		
		#ifdef MAKETABLE
		[ self makeFECTable ] ;
		#endif
		
		NSString *version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleVersion" ] ;
		defaultString = [ NSString stringWithFormat:@" cocoaModem 2.0 v%s ..", [ version cStringUsingEncoding:kTextEncoding ] ] ;
		strcpy( defaultBeaconString, (char*)[ defaultString cStringUsingEncoding:kTextEncoding ] ) ;		
		strcpy( beaconString, "" ) ;
		beaconPtr = defaultBeaconString ;
		[ self unpack:&primaryVaricode[0] from:ASCIITOPRIVAR ] ;
		[ self unpack:&secondaryVaricode[0] from:ASCIITOSECVAR ] ;
	}
	return self ;
}

- (void)setUseFEC:(Boolean)state
{
	useFEC = state ;
}

- (void)resetModulator
{
	[ super resetModulator ] ;
	deltaTone = 0 ;
	lastTone = 0 ;
	beaconPtr = beaconString ;
}

- (void)flushOutput
{
	[ bitLock lock ] ;
	bitProducer = bitConsumer = 0 ;
	[ bitLock unlock ] ;
}

//	(Private API)
//  Note: caller must apply lock to bitLock
- (void)insertPrimaryValue:(int)value withCharacter:(int)ch
{
	ring[bitProducer].character = ch ;
	ring[bitProducer].secondaryCharacter = 0 ;
	ring[bitProducer++].value = value  ;
	bitProducer &= RINGMASK ;
}

//  Note: caller must apply lock to bitLock
- (void)insertSecondaryValue:(int)value withCharacter:(int)ch
{
	ring[bitProducer].character = 0 ;
	ring[bitProducer].secondaryCharacter = ch ;
	ring[bitProducer++].value = value  ;
	bitProducer &= RINGMASK ;
}

//	Non-FEC DominoEX
- (void)insertNibbles:(char*)array length:(int)length fromCharacter:(int)ch secondary:(Boolean)isSecondary
{
	int i ;
	
	[ bitLock lock ] ;
	if ( isSecondary ) {
		for ( i = 0; i < length; i++ ) {
			[ self insertValue:array[i] withCharacter:0 secondary: ( ( i == 0 ) ? ch : 0 ) ] ;
		}
	}
	else {
		for ( i = 0; i < length; i++ ) {
			[ self insertValue:array[i] withCharacter: ( ( i == 0 ) ? ch : 0 ) secondary:0 ] ;
		}
	}
	[ bitLock unlock ] ;
}

//	non-FEC DominoEX
- (void)appendEOM
{
	char e[2] ;
	
	e[0] = e[1] = nibbleValue[0] ;
	[ self insertNibbles:e length:2 fromCharacter:5 secondary:NO ] ;		//  the 5 signals the modem to terminate transmit state
}

//  non-FEC DominoEX
- (void)insertPrimaryASCIIIntoNibbleBuffer:(int)ascii
{
	char *nibbles ;
	
	nibbles = (char*)primaryVaricode[ ascii ] ;
	[ self insertNibbles:nibbles length:strlen( nibbles ) fromCharacter:ascii secondary:NO ] ;
}

//  non-FEC DominoEX
- (void)insertSecondaryASCIIIntoNibbleBuffer:(int)ascii
{
	char *nibbles ;
	
	nibbles = (char*)secondaryVaricode[ ascii ] ;
	[ self insertNibbles:nibbles length:strlen( nibbles ) fromCharacter:ascii secondary:YES ] ;
}

//	(Private API)
//	New ASCII arrived
- (void)encodeAndInsertCharacter:(int)ascii secondary:(Boolean)asSecondary
{
	int secondary ;
	
	if ( useFEC ) {
		if ( !asSecondary ) {
			ascii = primaryFECEncodeTable[ ascii ] ;
			[ self insertPrimaryASCIIIntoFECBuffer:ascii fromCharacter:ascii ] ;

		}
		else {
			secondary = secondaryFECEncodeTable[ascii] ;
			if ( secondary == 0 ) {
				ascii = '_' ;
				secondary = secondaryFECEncodeTable[ ascii ] ;
			}
			[ self insertSecondaryASCIIIntoFECBuffer:secondary fromCharacter:ascii ] ;
		}
	}
	else {
		if ( !asSecondary ) [ self insertPrimaryASCIIIntoNibbleBuffer:ascii ] ; else [ self insertSecondaryASCIIIntoNibbleBuffer:ascii ] ;
	}
}

- (void)appendASCII:(int)ascii
{	
	ascii &= 0xff ;
	
	// ignore opt u, i, `, e, n (e.g., umlaut prefix)
	if ( ( ascii == 168 ) || ( ascii == 710 ) || ( ascii == 96 )  || ( ascii == 180 ) || ( ascii == 732 ) ) return ;

	switch ( ascii ) {
	case 0x5: // %[rx]
		if ( useFEC ) [ super appendEOM ] ; else [ self appendEOM ] ;
		return ;
	case 0x6: // %[tx]
		//  if macros are appended when we are terminating, abort the terminating sequence
		if ( terminateState == TERMINATESTARTED || terminateState == TERMINATETAIL ) {
			terminateState = NOTTERMINATING ;
			[ (MFSK*)modem changeTransmitLight:1 ] ;
		}
		// ignore this non-printing character
		return ;
	default:
		if ( terminateState == NOTTERMINATING ) {
			//  make sure zero is not transmitted as phi
			if ( ascii == Phi || ascii == phi ) ascii = '0' ;
			[ self encodeAndInsertCharacter:ascii secondary:NO ] ;
		}
	}
}

//	(PrivateAPI)
- (int)getNextToneIndex
{
	int ascii, primaryChar, secondaryChar, nibble ;
	
	if ( terminateState == TERMINATED ) return 0 ;

	if ( bitConsumer == bitProducer ) {	
		//  no more user input, insert beacon or empty message into the seconary channel
		if ( terminateState == NOTTERMINATING ) {
			//  ran out of input, insert a charcater from the secondary (beacon) message
			ascii = *beaconPtr++ ;
			if ( ascii == 0 ) {
				//  end of beacon message
				beaconPtr = ( beaconString[0] != 0 ) ? beaconString : defaultBeaconString ;
				ascii = *beaconPtr++ ;
			}
			[ self insertSecondaryASCIIIntoNibbleBuffer:ascii ] ;
		}
		else {
			//  a %[rx] (0x5) character places the MFSK modulator in the TERMINATESTATED state
			//  Send spaces in secondary channel
			terminateState = ( terminateState == TERMINATESTARTED ) ? TERMINATETAIL : TERMINATED ;
			[ self insertSecondaryASCIIIntoNibbleBuffer:' ' ] ;
		}
	}
	primaryChar = ring[bitConsumer].character ;
	secondaryChar = ring[bitConsumer].secondaryCharacter ;
	nibble = ring[bitConsumer++].value ;
	bitConsumer &= RINGMASK ;
	
	//  check for end-of-message that the client has inserted
	switch ( primaryChar ) {
	case 5 /* ^E */:
		terminateState = TERMINATESTARTED ;
		[ self insertSecondaryASCIIIntoNibbleBuffer:' ' ] ;
		primaryChar = ring[bitConsumer].character ;
		secondaryChar = ring[bitConsumer].secondaryCharacter ;
		nibble = ring[bitConsumer++].value ;
		bitConsumer &= RINGMASK ;
		//  tell user we have entered the terminating sequence
		[ (MFSK*)modem changeTransmitLight:2 ] ;
		return [ self getNextToneIndex ] ;
	default:
		break ;
	}
	//  save character for echo back in fillBuffer, delayed by 128 characters to compensate for the interleaver
	if ( primaryChar != 0 ) [ modem transmittedPrimaryCharacter:primaryChar ] ;
	if ( secondaryChar != 0 ) [ modem transmittedSecondaryCharacter:secondaryChar ] ;
	
	return asciiToNibble[ nibble ] ;
}

//  (Private API)
- (void)setDDAFrequency:(float)freq
{
	carrier = freq*kPeriod/CMFs ;
}

//	Private API
//  Fetch next data bit modulation from the ring buffer.
//  If the buffer is empty, the data is taken from the beacon buffer.
- (int)getNextDominoFECBit
{
	int ascii, newBit, primaryChar, secondaryChar ;
	
	if ( terminateState == TERMINATED ) return 0 ;

	if ( bitConsumer == bitProducer ) {	
		if ( terminateState == NOTTERMINATING ) {
			//  ran out of input, insert a charcater from the secondary (beacon) message
			ascii = *beaconPtr++ ;
			if ( ascii == 0 ) {
				//  end of beacon message
				beaconPtr = ( beaconString[0] != 0 ) ? beaconString : defaultBeaconString ;
				ascii = *beaconPtr++ ;
			}
			[ self encodeAndInsertCharacter:ascii secondary:YES ] ;		//  output to beacon channel
		}
		else {		
			//  a %[rx] (0x5) character places the MFSK modulator in the TERMINATESTATED state
			//  This will send 5 nulls and then the modulator will enter the TERMINATETAIL state, where 52 zeros are transmitted.
			//  The 52 zeros allow the data to flush through the interleaver.
			//  At the end of the TERMINATETAIL, the state is set to TERMINATED.
			
			switch ( terminateState ) {
			case TERMINATESTARTED:
				//  a ^E was seen earlier.  Send 5 nulls before going to the next state
				terminateCount++ ;
				if ( terminateCount < 5 ) [ self insertPrimaryFECVaricodeFor:0 fromCharacter:0 ] ;
				else {
					terminateState = TERMINATETAIL ;
					terminateCount = 0 ;
					[ self insertValue:0 withCharacter:0 secondary:0 ] ;
				}
				break ;
			case TERMINATETAIL:
				//  terminate state has entered the carrier tail state
				terminateCount++ ;
				if ( terminateCount < 52 ) {
					[ self lockAndInsertValue:0 withCharacter:0 secondary:0 ] ;
				}
				else {
					terminateState = TERMINATED ;
					terminateCount = 0 ;
				}
			}
		}
	}
	primaryChar = ring[bitConsumer].character ;
	secondaryChar = ring[bitConsumer].secondaryCharacter ;
	newBit = ring[bitConsumer++].value ;
	bitConsumer &= RINGMASK ;
	
	//  check for end-of-message that the client has inserted
	switch ( primaryChar ) {
	case 5 /* ^E */:
		//  check first to make sure there are no more macros
		if ( bitConsumer == bitProducer ) {
			//  Character buufer is truly empty at the moment, initiate a terminate sequence
			//  This terminate sequence can be broken with an incoming macro; see -appendASCII:
			terminateState = TERMINATESTARTED ;
			terminateCount = 0 ;
			[ self insertPrimaryASCIIIntoFECBuffer:0 fromCharacter:0 ] ;
			primaryChar = ring[bitConsumer].character ;
			secondaryChar = ring[bitConsumer].secondaryCharacter ;
			newBit = ring[bitConsumer++].value ;
			bitConsumer &= RINGMASK ;
			//  tell user we have entered the terminating sequence
			[ (MFSK*)modem changeTransmitLight:2 ] ;
		}
		else {
			//  continue transmitting
			return [ self getNextFECBit ] ;
		}
		break ;
	default:
		break ;
	}
	//  save character for echo back in fillBuffer, delayed by 128 characters to compensate for the interleaver
	if ( primaryChar != 0 ) [ modem transmittedPrimaryCharacter:primaryChar ] ;
	if ( secondaryChar != 0 ) [ modem transmittedSecondaryCharacter:secondaryChar ] ;
	
	characterRing[characterRingIndex] = primaryChar ;				//  test with just secondary char
	characterRingIndex = ( characterRingIndex+1 ) & 0x3f ;
		
	return ( newBit == 0 ) ? 0 : 1 ;
}

- (int)getNextFECBit
{
	int bit ;
	
	bit = [ self getNextDominoFECBit ] ;
	return bit ;
}

//	(Private API)
//  Fetch next audio sample
-(float)nextAudioSample
{
	float v ;
	
	if ( terminateState == TERMINATED ) {
		return ( ( transmitBPF ) ? CMSimpleFilter( transmitBPF, 0.0 ) : 0.0 ) ;
	}
	if ( cw ) return [ self sin:carrier ]*0.9 ;		// test CW tone	
	
	//  check if the next symbol is needed
	if ( [ self modulation:baudDDA ] ) {
		//  differential encode FSK here
		lastTone = ( lastTone + deltaTone + 2 ) % 18 ;
		if ( !useFEC ) {
			deltaTone =  [ self getNextToneIndex ] ; 
		}
		else {
			deltaTone =  [ self getNextFECIndex ] ;		//  same as MFSK16, but with no gray scale encoding
		}
		[ self setDDAFrequency:( idleFrequency + binWidth*sideband*lastTone ) ] ;
	}
	v = [ self sin:carrier ]*0.9 ;
	
	return ( ( transmitBPF ) ? CMSimpleFilter( transmitBPF, v ) : v ) ;
}

- (void)getBufferWithIdleFill:(float*)buf length:(int)samples
{
	int i ;
	
	if ( idleFrequency < 20.0 ) {
		for ( i = 0; i < samples; i++ ) buf[i] = 0.0 ;
		return ;
	}
	for ( i = 0; i < samples; i++ ) buf[i] = [ self nextAudioSample ] ;
}

- (void)setFrequency:(float)freq
{
	CMFIR *tmp ;
	float delta, side ;
	
	idleFrequency = freq ;
	[ self setDDAFrequency:freq ] ;
	
	if ( transmitBPF ) {
		tmp = transmitBPF ;
		transmitBPF = nil ;
		CMDeleteFIR( tmp ) ;
	}
	side = binWidth*3.2	;				//  lower cutoff
	delta = binWidth*17 + side ;		//  upper cutoff
	
	if ( sideband > 0 ) {
		transmitBPF = CMFIRBandpassFilter( freq-side, freq+delta, CMFs, 1024 ) ;
	}
	else {
		transmitBPF = CMFIRBandpassFilter( freq-delta, freq+side, CMFs, 1024 ) ;
	}
}

- (void)setBinWidth:(float)hz baudRatio:(int)inBaudRatio
{
	binWidth = hz ;
	baudRatio = inBaudRatio ;
	baudDDA = binWidth*kPeriod/CMFs/baudRatio ;
}

- (void)setBeacon:(char*)msg
{
	int length ;
	
	length = strlen( msg ) ;
	if ( length >= 2047 ) return ;		//  sanitity check for buffer overflow

	memset( &beaconString[length], 0, 2048-length ) ;
	strcpy( beaconString, msg ) ;
	if ( length > 0 ) beaconPtr = beaconString ;
}

//	----- FEC -----

//	(Private API)
//  insert bits into the ring buffer 
//	bits is either an ascii string of '0' or '1', or actual interger value 0 or 1
- (void)insertSecondaryASCIIIntoFECBuffer:(int)ascii fromCharacter:(int)ch
{
	int i, length ;
	const char *bits ;
	
	[ bitLock lock ] ;
	idleSequenceState = 0 ;
	bits = [ varicode encode:ascii ] ;
	length = strlen( bits ) ;
	
	for ( i = 0; i < length; i++ ) {
		[ self insertValue:( ( bits[i] == '0' || bits[i] == 0 ) ? 0 : 1 ) withCharacter:0 secondary: ( ( i == 0 ) ? ch : 0 ) ] ;
	}
	[ bitLock unlock ] ;
}


- (void)insertPrimaryFECVaricodeFor:(int)ascii fromCharacter:(int)echo
{
	int secondary ;
	
	secondary = secondaryFECEncodeTable[ascii] ;
	if ( secondary != 0 ) ascii = '_' ;				//  ASCII code overlaps into secondary code, replace by _
	
	[ self insertPrimaryASCIIIntoFECBuffer:ascii fromCharacter:echo ] ;
}

- (void)insertSecondaryFECVaricodeFor:(int)ascii fromCharacter:(int)echo
{
	int secondary ;
	
	secondary = secondaryFECEncodeTable[ascii] ;
	if ( secondary == 0 ) {
		ascii = secondary = '_' ;				//  Unassigned secondary code, replace by secondary _
	}
	[ self insertSecondaryASCIIIntoFECBuffer:secondary fromCharacter:echo ] ;
}


@end
