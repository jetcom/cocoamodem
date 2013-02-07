//
//  CMVaricode.h
//  CoreModem
//
//  Created by Kok Chen on 11/02/05.

#ifndef _CMVARICODE_H_
	#define _CMVARICODE_H_

	#import <Foundation/Foundation.h>
	
	typedef struct {
		char bits[16] ;
		int length ;
	} Encoding ;

	@interface CMVaricode : NSObject {
		int varicode[4096] ;				//  v0.76 bug fix, was 2096!
		Encoding encoding[256] ;
	}
	- (void)useCode:(char**)code ;
	
	- (char)decode:(int)input ;
	- (Encoding*)encode:(int)ascii ;
	
	@end

	/*  --- standard ASCII varicode
	NUL		 1010101011 
	SOH		 1011011011 
	STX		 1011101101 
	ETX		 1101110111 
	EOT		 1011101011 
	ENQ		 1101011111 
	ACK		 1011101111 
	BEL		 1011111101 
	BS		 1011111111 
	HT		 11101111 
	LF		 11101 
	VT		 1101101111 
	FF		 1011011101 
	CR		 11111 
	SO		 1101110101 
	SI		 1110101011 
	DLE		 1011110111 
	DC1		 1011110101 
	DC2		 1110101101 
	DC3		 1110101111 
	DC4		 1101011011 
	NAK		 1101101011 
	SYN		 1101101101 
	ETB		 1101010111 
	CAN		 1101111011 
	EM		 1101111101 
	SUB		 1110110111 
	ESC		 1101010101 
	FS		 1101011101 
	GS		 1110111011 
	RS		 1011111011 
	US		 1101111111 
	SP		 1 
	!		 111111111 
	"		 101011111 
	#		 111110101 
	$		 111011011 
	%		 1011010101 
	&		 1010111011 
	'		 101111111 
	(		 11111011 
	)		 11110111 
	*		 101101111 
	+		 111011111 
	,		 1110101 
	-		 110101 
	.		 1010111 
	/		 110101111 
	0		 10110111 
	1		 10111101 
	2		 11101101 
	3		 11111111 
	4		 101110111 
	5		 101011011 
	6		 101101011 
	7		 110101101 
	8		 110101011 
	9		 110110111 
	:		 11110101 
	;		 110111101 
	<		 111101101 
	=		 1010101 
	>		 111010111 
	?		 1010101111 
	@		 1010111101 
	A		 1111101 
	B		 11101011 
	C		 10101101 
	D		 10110101 
	E		 1110111 
	F		 11011011 
	G		 11111101 
	H		 101010101 
	I		 1111111 
	J		 111111101 
	K		 101111101 
	L		 11010111 
	M		 10111011 
	N		 11011101 
	O		 10101011 
	P		 11010101 
	Q		 111011101 
	R		 10101111 
	S		 1101111 
	T		 1101101 
	U		 101010111 
	V		 110110101 
	X		 101011101 
	Y		 101110101 
	Z		 101111011 
	[		 1010101101 
	\		 111110111 
	]		 111101111 
	^		 111111011 
	_		 1010111111 
	.		 101101101 
	/		 1011011111 
	a		 1011 
	b		 1011111 
	c		 101111 
	d		 101101 
	e		 11 
	f		 111101 
	g		 1011011 
	h		 101011 
	i		 1101 
	j		 111101011 
	k		 10111111 
	l		 11011 
	m		 111011 
	n		 1111 
	o		 111 
	p		 111111 
	q		 110111111 
	r		 10101 
	s		 10111 
	t		 101 
	u		 110111 
	v		 1111011 
	w		 1101011 
	x		 11011111 
	y		 1011101 
	z		 111010101 
	{		 1010110111 
	|		 110111011 
	}		 1010110101 
	~		 1011010111 
	DEL		 1110110101 
	
	"Peter G3PLX
	It is very easy to add extra characters to the Varicode alphabet without backwards-compatability
	problems. In the earlier decoder, if there was no '00' pattern received 10-bits after the last '00', it
	would simply ignore it as a corruption. In the extended alphabet I let the transmitter legally send
	codes longer than 10 bits. The old decoders will just ignore them and the extended decoder can
	interpret them as extra characters. To get another 128 varicodes means adding more ten-bit
	codes, all the eleven-bit ones, and some twelve-bit codes. There seemed little reason to be
	clever with shorter common characters so I chose to allocate them in numerical order, with code
	number 128 being 1110111101 and code number 255 being 101101011011. The vast majority
	of these will never be used. It would not be a good idea to transmit binary files this way!"
	
	1110111101
	101101011011
*/
#endif
