//
//  SP RTTY.m
//  cocoaModem
//
//  Created by Kok Chen on 3/31/06.
	#include "Copyright.h"
//

#import "SP RTTY.h"
#import "Messages.h"
#import "ContestManager.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"
#import "UserInfo.h"


@implementation SPRTTY

typedef struct {
	char *abbrev ;
	char area ;
}  SPStateList ;

static SPStateList rawStateList[] = {
	{ "B", 1 },
	{ "C", 1 },
	{ "D", 1 },
	{ "F", 1 },
	{ "G", 1 },
	{ "J", 1 },
	{ "K", 1 },
	{ "L", 1 },
	{ "M", 1 },
	{ "O", 1 },
	{ "P", 1 },
	{ "R", 1 },
	{ "S", 1 },
	{ "U", 1 },
	{ "W", 1 },
	{ "Z", 1 },
	{ "**", 40 }
} ;

//  check state/number here
- (Boolean)validateExchange:(NSString*)exchange 
{
	const char *s, *t ;
	int c ;
	SPStateList *state ;
	
	s = t = [ exchange cStringUsingEncoding:kTextEncoding ] ;
	c = *t++ & 0xff ;
	
	//  check for state/province if first character is an alphabet
	if ( isAlpha[c] ) {
		state = &rawStateList[0] ;
		while ( 1 ) {
			if ( strcmp( state->abbrev, s ) == 0 ) return YES ;
			state++ ;
			if ( state->area > 39 ) {
				[ dxExchange markAsSelected:YES ] ;
				[ Messages alertWithMessageText:@"Error -- bad Wojewodztwo (province) abbreviation." informativeText:@"Province should be one of B, C, D, F, G, J, K, L, M, O, P, R, S, U, W, Z." ] ;
				[ dxExchange markAsSelected:NO ] ;
				return NO ;
			}
		}
	}
	//  is it a number?
	if ( isNumeric[c] ) {
		while ( c > 0 ) {
			if ( !isNumeric[c] ) {
				[ dxExchange markAsSelected:YES ] ;
				[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"SP RTTY exchange needs to be a Polish Wojewodztwo (1 letter abbreviation) or a QSO number (everyone else)." ] ;
				[ dxExchange markAsSelected:NO ] ;
				return NO ;
			}
			c = *t++ & 0xff ;
		}
		return YES ;
	}
	[ dxExchange markAsSelected:YES ] ;
	[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"SP RTTY exchange needs to be a Polish Wojewodztwo (1 letter abbreviation) or a QSO number (everyone else)." ] ;
	[ dxExchange markAsSelected:NO ] ;
	return NO ;
}

- (void)setupFields
{
	[ super setupFields ] ;
	if ( master ) [ master setCabrilloContestName:"SP-DX-RTTY-C" ] ;
}

- (void)writeCabrilloQSOs
{
	int i, count, frequency, year, month, day, utc, rst ;
	char *mode, callsign[32], myCall[32], exchange[13] ;
	Callsign *c ;
	DateTime *time ;
	ContestQSO *q ;
	
	myCall[0] = 0 ;
	if ( usedCallString ) {
		strncpy( myCall, [ usedCallString cStringUsingEncoding:kTextEncoding ], 16 ) ;
		myCall[13] = 0 ;
	}

	count = 0 ;
	for ( i = 0; i < MAXQ; i++ ) {
	
		//  reference: http://www.pkrvg.org/zbior.html
		//  QSO: ***** ** yyyy-mm-dd nnnn ************* nnn   **** ************* nnn   **** 
		//  QSO: 14089 RY 2002-04-06 1629 4Z5LA         599    080 SP6ZLC        599      D 
		//  0000000001111111111222222222233333333334444444444555555555566666666667777777777
		//  1234567890123456789012345678901234567890123456789012345678901234567890123456789

		
		q = sortedQSOList[i] ;
		if ( q ) {
		
			//  skip if callsign is NIL
			if ( q->callsign->callsign[0] == 0 || strcmp( q->callsign->callsign, "NIL" ) == 0 ) continue ;

			frequency = q->frequency*1000.0 + 0.1 ;
			mode = stringForMode( q->mode ) ;
			//  change PK to RY
			if ( strcmp( mode, "PK" ) == 0 ) mode = "RY" ;		//  report PSK as RY to Cabrillo
			time = &q->time ;
			year = time->year ;
			if ( year < 2000 ) year += 2000 ;
			month = time->month ;
			day = time->day ;
			utc = time->hour*100 + time->minute ;
							
			c = q->callsign ;
			callsign[0] = 0 ;
			if ( c ) {
				strncpy( callsign, c->callsign, 16 ) ;
				callsign[13] = 0 ;
			}
			
			fprintf( cabrilloFile, "QSO: %5d %2s ", frequency%100000, mode ) ;
			fprintf( cabrilloFile, "%4d-%02d-%02d %04d ", year, month, day, utc ) ;
			fprintf( cabrilloFile, "%-14s", myCall ) ;
			fprintf( cabrilloFile, "599  %5d ", q->qsoNumber ) ;
			fprintf( cabrilloFile, "%-14s", callsign ) ;

			rst = q->rst ;
			if ( rst > 599 ) rst = 599 ; else if ( rst < 111 ) rst = 111 ;
			
			strncpy( exchange, q->exchange, 8 ) ;
			exchange[7] = 0 ;
			fprintf( cabrilloFile, "%3d   %4s", rst, exchange ) ;		
			fprintf( cabrilloFile, "\n" ) ;
			
			if ( ++count >= numberOfQSO ) break ;
		}
	}
}

@end
