//
//  WPX.m
//  cocoaModem
//
//  Created by Kok Chen on 1/2/05.
	#include "Copyright.h"
//

#import "WPX.h"
#import "TextEncoding.h"


@implementation WPX

- (void)setupFields
{
	[ super setupFields ] ;
	if ( master ) [ master setCabrilloContestName:"CQ-WPX-RTTY" ] ;
}

- (void)writeCabrilloQSOs
{
	int i, count, frequency, year, month, day, utc, rst, num ;
	char *mode, callsign[32], myCall[32] ;
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
		
		// Roundup
		// QSO: 21080 RY 2004-01-03 1800 W7AY         599     OR AK0A         599     KS
		// WPX
		// QSO: ***** ** yyyy-mm-dd nnnn ************* nnn ****** ************* nnn ****** n
		// QSO: 28000 RY 2002-02-10 2126 LU/N5KO       599 0001   KA4RRU        599 0530  
		// 000000000111111111122222222223333333333444444444455555555556666666666777777777788
		// 123456789012345678901234567890123456789012345678901234567890123456789012345678901
		
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
			fprintf( cabrilloFile, "599 %04d   ", q->qsoNumber ) ;
			fprintf( cabrilloFile, "%-14s", callsign ) ;

			rst = q->rst ;
			if ( rst > 599 ) rst = 599 ; else if ( rst < 111 ) rst = 111 ;
			
			num = 1 ;
			sscanf( q->exchange, "%d", &num ) ;
			fprintf( cabrilloFile, "%3d %04d", rst, num ) ;
			fprintf( cabrilloFile, "\n" ) ;
			
			if ( ++count >= numberOfQSO ) break ;
		}
	}
}

@end
