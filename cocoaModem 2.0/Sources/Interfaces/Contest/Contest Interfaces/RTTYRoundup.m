//
//  RTTYRoundup.m
//  cocoaModem
//
//  Created by Kok Chen on 11/27/04.
	#include "Copyright.h"
//

#import "RTTYRoundup.h"
#import "ContestManager.h"
#import "Contest.h"
#import "Messages.h"
#import "RTTYRoundupMults.h" ;
#import "TextEncoding.h"
#import "TransparentTextField.h"
#import "UserInfo.h"


@implementation RTTYRoundup


static StateList rawStateList[64] = {
    { "AL", 4 },  { "AR", 5 },  { "AZ", 7 },  { "CA", 6 },
    { "CO", 0 },  { "CT", 1 },  { "DC", 3 },  { "DE", 3 },
    { "FL", 4 },  { "GA", 4 },  { "IA", 0 },  { "ID", 7 },
    { "IL", 9 },  { "IN", 9 },  { "KS", 0 },  { "KY", 4 },
    { "LA", 5 },  { "MA", 1 },  { "MD", 3 },  { "ME", 1 },  
    { "MI", 8 },  { "MN", 0 },  { "MO", 0 },  { "MS", 5 },  
    { "MT", 7 },  { "NC", 4 },  { "ND", 0 },  { "NE", 0 },    
    { "NH", 1 },  { "NJ", 2 },  { "NM", 5 },  { "NV", 7 },  
    { "NY", 2 },  { "OH", 8 },  { "OK", 5 },  { "OR", 7 },  
    { "PA", 3 },  { "RI", 1 },  { "SC", 4 },  { "SD", 0 },  
    { "TN", 4 },  { "TX", 5 },  { "UT", 7 },  { "VA", 4 },  
    { "VT", 1 },  { "WA", 7 },  { "WI", 9 },  { "WV", 8 },  
    { "WY", 7 },
    { "AB", 26 }, { "BC", 27 }, { "LB", 21 }, { "MB", 24 }, 
    { "NB", 21 }, { "NF", 21 }, { "NS", 21 }, { "NWT", 29 }, 
    { "VY0", 30 }, { "ON", 23 }, { "PEI", 21 }, { "QC", 22 }, 
    { "SK", 25 }, { "YT", 28 },
	{ "**", 40 }
} ;

//  initialize master
- (id)initContestName:(NSString*)name prototype:(NSString*)prototype parser:(NSXMLParser*)inParser manager:(ContestManager*)inManager
{
	int i, n, area, columns[11] ;
	
	//  check to make sure we are master
	if ( master ) return nil ;
	
	mult = [ [ RTTYRoundupMults alloc ] init ] ;
	[ NSBundle loadNibNamed:@"RTTYRoundupMults" owner:mult ] ;   
	
	//  initialize mult info for Roundup
	for ( i = 0; i < 11; i++ ) columns[i] = 0 ;
	for ( i = 0; i < 64; i++ ) {
		if ( *rawStateList[i].abbrev == '*' ) break ;
		rawStateList[i].worked = 0 ;
		area = rawStateList[i].area ;
		if ( area < 10 ) {
			area -= 1 ;
			if ( area < 0 ) area = 9 ;
			rawStateList[i].y = area ;
			rawStateList[i].x = columns[area]++ ;
		}
		else {
			area = 10 ;	// Canada
			n = columns[area]++ ;
			if ( n > 7 ) {
				n -= 8 ;
				area = 11 ;
			}
			rawStateList[i].y = area ;
			rawStateList[i].x = n ;			
		}
	}
	return [ super initContestName:name prototype:prototype parser:inParser manager:inManager ] ;
}


- (void)createMult:(ContestQSO*)p
{
	if ( master ) {
		[ (RTTYRoundup*)master createMult:p ] ;
		return ;
	}
	[ mult updateMult:p statelist:&rawStateList[0] ] ;
}

//  check state/number here
- (Boolean)validateExchange:(NSString*)exchange 
{
	const char *s, *t ;
	int c ;
	StateList *state ;
	
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
				[ Messages alertWithMessageText:@"Error -- bad state/province abbreviation." informativeText:@"State should be one of AL, AR, AZ, CA, CO, CT, DC, DE, FL, GA, IA, ID, IL, IN, KS, KY, LA, MA, MD, ME, MI, MN, MO, MS, MT, NC, ND, NE, NH, NJ, NM, NV, NY, OH, OK, OR, PA, RI, SC, SD, TN, TX, UT, VA, VT, WA, WI, WV, WY.\n\nProvince should be one of AB, BC, LB, MB, NB, NF, NS, NWT, ON, PEI, QC, SK, VY0, YT.\n\nNote that AK and HI are not counted as states in the RTTY Roundup." ] ;
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
				[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"RTTY Roundup exchange needs to be a State/Province (2 letter abbreviation) or a QSO number (for DX)" ] ;
				[ dxExchange markAsSelected:NO ] ;
				return NO ;
			}
			c = *t++ & 0xff ;
		}
		return YES ;
	}
	[ dxExchange markAsSelected:YES ] ;
	[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"RTTY Roundup exchange needs to be a State/Province (2 letter abbreviation) or a QSO number (for DX)" ] ;
	[ dxExchange markAsSelected:NO ] ;
	return NO ;
}

- (void)setupFields
{
	[ super setupFields ] ;
	if ( master ) [ master setCabrilloContestName:"ARRL-RTTY" ] ;
}

- (void)writeCabrilloFields
{
	NSString *section, *qth ;
	const char *qths ;
	
	[ super writeCabrilloFields ] ;

	section = [ userInfo section ] ;
	if ( section == nil || [ section length ] <= 0 ) {
		[ Messages alertWithMessageText:@"No ARRL Section in User Info panel." informativeText:@"Assume RTTY Roundup entry is from outside USA/Canada.\n\nOtherwise, please enter ARRL Section info in the User Info panel and save to Cabrillo again." ] ;
	}
	
	//  check if we are DX
	isDX = NO ;
	qth = [ userInfo qth ] ;
	if ( !qth || [ qth length ] == 0 ) {
		isDX = YES ;
		[ Messages alertWithMessageText:@"State/Province/DX field in User Info panel is empty." informativeText:@"Assume RTTY Roundup entry is from outside USA/Canada.\n\nOtherwise, please enter ARRL Section info in the User Info panel and save to Cabrillo again." ] ;
	}
	else {
		qths = [ qth cStringUsingEncoding:kTextEncoding ] ;
		isDX = ( qths[0] == 'd' || qths[0] == 'D' ) && ( qths[1] == 'x' || qths[1] == 'X' ) ;
		exchSent[0] = 0 ;
		if ( !isDX ) {
			strncpy( exchSent, qths, 8 ) ;
			exchSent[7] = 0 ;
		}
	}
	fprintf( cabrilloFile, "ARRL-SECTION: %s\n", [ section cStringUsingEncoding:kTextEncoding ] ) ;
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
			if ( !isDX ) {
				fprintf( cabrilloFile, "599%7s ", exchSent ) ;
			}
			else {
				fprintf( cabrilloFile, "599%7d ", q->qsoNumber ) ;
			}
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

- (void)showMultsWindow
{
	if ( master == nil && mult ) [ mult showWindow:rawStateList ] ;
}

@end
