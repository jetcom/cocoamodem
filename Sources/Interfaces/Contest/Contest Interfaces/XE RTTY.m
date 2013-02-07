//
//  XE RTTY.m
//  cocoaModem
//
//  Created by Kok Chen on 1/16/05.
	#include "Copyright.h"
//

#import "XE RTTY.h"
#import "Messages.h"
#import "ContestManager.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"
#import "UserInfo.h"


@implementation XERTTY

typedef struct {
	char *abbrev ;
	char area ;
}  XEStateList ;

static XEStateList rawStateList[] = {
	{ "AGS", 1 },
	{ "BC",  1 },	{ "BCS", 1 },
	{ "CAM", 1 },	{ "CHH", 1 },	{ "CHS", 1 },	{ "COA", 1 },	{ "COL", 1 },	
	{ "DF",  1 },
	{ "DGO", 1 },
	{ "EMX", 1 },
	{ "GRO", 1 },	{ "GTO", 1 },
	{ "HGO", 1 },
	{ "JAL", 1 },
	{ "MIC", 1 },	{ "MOR", 1 },
	{ "NAY", 1 },	{ "NL",  1 },
	{ "OAX", 1 },
	{ "PUE", 1 },
	{ "QRO", 1 },	{ "QTR", 1 },
	{ "SIN", 1 },	{ "SLP", 1 },	{ "SON", 1 },
	{ "TAB", 1 },	{ "TLX", 1 },	{ "TMS", 1 },
	{ "VER", 1 },
	{ "YUC", 1 },
	{ "ZAC", 1 },
	{ "**", 40 }
} ;

//  check state/number here
- (Boolean)validateExchange:(NSString*)exchange 
{
	const char *s, *t ;
	int c ;
	XEStateList *state ;
	
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
				[ Messages alertWithMessageText:@"Error -- bad state abbreviation." informativeText:@"State should be one of AGS BC, BCS, CAM, CHH, CHS, COA, COL, DF, DGO, EMX, GRO, GTO, HGO, JAL, MIC, MOR, NAY, NL, OAX, PUE, QRO, QTR, SIN, SLP, SON, TAB, TLX, TMS, VER, YUC, ZAC." ] ;
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
				[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"XE RTTY exchange needs to be a Mexican State (2 or 3 letter abbreviation) or a QSO number (everyone else)." ] ;
				[ dxExchange markAsSelected:NO ] ;
				return NO ;
			}
			c = *t++ & 0xff ;
		}
		return YES ;
	}
	[ dxExchange markAsSelected:YES ] ;
	[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"XE RTTY exchange needs to be a Mexican State (2 or 3 letter abbreviation) or a QSO number (everyone else)." ] ;
	[ dxExchange markAsSelected:NO ] ;
	return NO ;
}

- (void)setupFields
{
	[ super setupFields ] ;
	if ( master ) [ master setCabrilloContestName:"XE-RTTY" ] ;
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
		
		//  QSO: 21080 RY 2004-01-03 1800 W7AY         599     OR AK0A         599     KS
		
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
			fprintf( cabrilloFile, "%-13s", myCall ) ;
			fprintf( cabrilloFile, "599%7d ", q->qsoNumber ) ;
			fprintf( cabrilloFile, "%-13s", callsign ) ;

			rst = q->rst ;
			if ( rst > 599 ) rst = 599 ; else if ( rst < 111 ) rst = 111 ;
			
			strncpy( exchange, q->exchange, 8 ) ;
			exchange[7] = 0 ;
			fprintf( cabrilloFile, "%3d%7s", rst, exchange ) ;		
			fprintf( cabrilloFile, "\n" ) ;
			
			if ( ++count >= numberOfQSO ) break ;
		}
	}
}

@end
