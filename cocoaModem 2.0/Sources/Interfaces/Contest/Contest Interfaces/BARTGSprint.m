//
//  BARTGSprint.m
//  cocoaModem
//
//  Created by Kok Chen on 1/2/05.
	#include "Copyright.h"
//

#import "BARTGSprint.h"
#import "Messages.h"
#import "TextEncoding.h"
#import "UserInfo.h"


@implementation BARTGSprint

- (void)setupFields
{
	[ super setupFields ] ;
	if ( master ) {
		[ master setCabrilloContestName:"BARTG-SPRINT" ] ;
		[ master setCabrilloCategorySuffix:"RTTY" ] ;
	}
}

- (void)writeCabrilloFields
{
	NSString *section, *qth ;
	const char *qths ;
	Boolean isDX ;
	
	[ super writeCabrilloFields ] ;

	section = [ userInfo section ] ;
	if ( section == nil || [ section length ] <= 0 ) {
		[ Messages alertWithMessageText:@"No ARRL Section in User Info panel." informativeText:@"Assume BARTG entry is from outside USA/Canada.\n\nOtherwise, please enter ARRL Section info in the User Info panel and save to Cabrillo again." ] ;
	}
	
	//  check if we are DX
	isDX = NO ;
	qth = [ userInfo qth ] ;
	if ( !qth || [ qth length ] == 0 ) {
		isDX = YES ;
		[ Messages alertWithMessageText:@"State/Province/DX field in User Info panel is empty." informativeText:@"Assume BARTG entry is from outside USA/Canada.\n\nOtherwise, please enter ARRL Section info in the User Info panel and save to Cabrillo again." ] ;
	}
	else {
		qths = [ qth cStringUsingEncoding:kTextEncoding ] ;
		isDX = ( qths[0] == 'd' || qths[0] == 'D' ) && ( qths[1] == 'x' || qths[1] == 'X' ) ;
	}
	if ( isDX ) 
		fprintf( cabrilloFile, "ARRL-SECTION: DX\n" ) ;
	else
		fprintf( cabrilloFile, "ARRL-SECTION: %s\n", [ section cStringUsingEncoding:kTextEncoding ] ) ;
}

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
