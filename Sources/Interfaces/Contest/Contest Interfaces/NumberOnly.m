//
//  NumberOnly.m
//  cocoaModem
//
//  Created by Kok Chen on 1/2/05.
	#include "Copyright.h"
//

#import "NumberOnly.h"
#import "Messages.h"
#import "ContestManager.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"
#import "UserInfo.h"


@implementation NumberOnly


//  check state/number here
- (Boolean)validateExchange:(NSString*)exchange 
{
	const char *s, *t ;
	int c ;
	
	s = t = [ exchange cStringUsingEncoding:kTextEncoding ] ;
	c = *t++ & 0xff ;
	
	//  is it a number?
	if ( isNumeric[c] ) {
		while ( c > 0 ) {
			if ( !isNumeric[c] ) {
				[ dxExchange markAsSelected:YES ] ;
				[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"The exchange needs to be a QSO number." ] ;
				[ dxExchange markAsSelected:NO ] ;
				return NO ;
			}
			c = *t++ & 0xff ;
		}
		return YES ;
	}
	[ dxExchange markAsSelected:YES ] ;
	[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"The exchange needs to be a QSO number." ] ;
	[ dxExchange markAsSelected:NO ] ;
	return NO ;
}

- (void)setupFields
{
	[ super setupFields ] ;
	if ( master ) [ master setCabrilloContestName:"Numbers Exchange" ] ;
}

// Use BARTG Sprint format for Cabrillo
- (void)writeCabrilloQSOs
{
	int i, count, frequency, year, month, day, utc, num ;
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
			
			//  QSO: 21000 RY 2002-01-26 1201 GW4BRS            0001   RW3LB             0001 
			//  versus Roundup:
			//  QSO: 21080 RY 2004-01-03 1800 W7AY         599     OR AK0A         599     KS

			fprintf( cabrilloFile, "QSO: %5d %2s ", frequency%100000, mode ) ;
			fprintf( cabrilloFile, "%4d-%02d-%02d %04d ", year, month, day, utc ) ;
			fprintf( cabrilloFile, "%-18s", myCall ) ;
			fprintf( cabrilloFile, "%04d   ", q->qsoNumber ) ;

			fprintf( cabrilloFile, "%-18s", callsign ) ;

			num = 1 ;
			sscanf( q->exchange, "%d", &num ) ;
			fprintf( cabrilloFile, "%04d", num ) ;
		
			fprintf( cabrilloFile, "\n" ) ;
			
			if ( ++count >= numberOfQSO ) break ;
		}
	}
}

@end
