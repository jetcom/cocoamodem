//
//  BARTG.m
//  cocoaModem
//
//  Created by Kok Chen on 2/12/06.
	#include "Copyright.h"
//

#import "BARTG.h"
#import "ContestManager.h"
#import "Contest.h"
#import "Messages.h"
#import "Modem.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"
#import "UserInfo.h"


@implementation BARTG


//  initialize master
- (id)initContestName:(NSString*)name prototype:(NSString*)prototype parser:(NSXMLParser*)inParser manager:(ContestManager*)inManager
{
	//  check to make sure we are master
	if ( master ) return nil ;
	
	return [ super initContestName:name prototype:prototype parser:inParser manager:inManager ] ;
}

- (Boolean)validateNumber:(NSString*)exchange
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
				[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"BARTG HF exchange needs to be a QSO number and a UTC time" ] ;
				[ dxExchange markAsSelected:NO ] ;
				return NO ;
			}
			c = *t++ & 0xff ;
		}
		return YES ;
	}
	[ dxExchange markAsSelected:YES ] ;
	[ Messages alertWithMessageText:@"Error -- bad exchange." informativeText:@"BARTG HF exchange needs to be a QSO number and a UTC time" ] ;
	[ dxExchange markAsSelected:NO ] ;
	return NO ;
}

- (Boolean)validateTime:(NSString*)exchange
{
	const char *s, *t ;
	int c, time ;
	
	s = t = [ exchange cStringUsingEncoding:kTextEncoding ] ;
	c = *t++ & 0xff ;
	
	//  is it a number?
	if ( isNumeric[c] ) {
		while ( c > 0 ) {
			if ( !isNumeric[c] ) {
				[ dxExtra markAsSelected:YES ] ;
				[ Messages alertWithMessageText:@"Error -- bad UTC time." informativeText:@"BARTG HF exchange needs to be a QSO number and a UTC time" ] ;
				[ dxExtra markAsSelected:NO ] ;
				return NO ;
			}
			c = *t++ & 0xff ;
		}
		sscanf( s, "%d\n", &time ) ;
		if ( strlen( s ) != 4 || time < 0 || time > 2359 ) {
			[ dxExtra markAsSelected:YES ] ;
			[ Messages alertWithMessageText:@"Error -- bad UTC format." informativeText:@"UTC time should be a 4 digit 24-hour UTC time" ] ;
			[ dxExtra markAsSelected:NO ] ;
			return NO ;
		}
		return YES ;
	}
	[ dxExtra markAsSelected:YES ] ;
	[ Messages alertWithMessageText:@"Error -- bad UTC time." informativeText:@"BARTG HF exchange needs to be a QSO number and a UTC time" ] ;
	[ dxExtra markAsSelected:NO ] ;
	return NO ;
}

- (void)exchangeFieldChanged
{
	NSString *string ;
	
	if ( master ) {
		//  validate exchange if it is not empty
		string = [ dxExchange stringValue ] ;
		if ( [ string length ] > 0 ) {
			if ( ![ self validateNumber:string ] ) {
				//  bad
				[ dxExchange setStringValue:@"" ] ;
				[ dxExchange selectText:self ] ;
			}
			else {
				selectedFieldType = kExtraTextField ;
				[ dxExtra setIgnoreFirstResponder:NO ] ;
				[ self selectExtraField ] ;
			}
		}
		else {
			// stay in QSO number field
			selectedFieldType = kExchangeTextField ;
			[ dxExtra setIgnoreFirstResponder:YES ] ;
			string = @"" ;
		}
	}
	else {
		[ dxExtra setIgnoreFirstResponder:NO ] ;
	}	
}

- (void)extraFieldChanged
{
	NSString *str ;
	
	if ( master ) {
		//  validate exchange if it is not empty
		str = [ dxExtra stringValue ] ;
		if ( [ str length ] > 0 ) {
			if ( ![ self validateTime:str ] ) {
				[ dxExtra setStringValue:@"" ] ;
				[ dxExtra selectText:self ] ;
			}
		}
	}
}

//  set up the extra UTC field in the key view chain
- (void)setupFields
{
	[ super setupFields ] ;
	//  extend key view chain to include UTC field
	[ dxExchange setNextKeyView:dxExtra ] ;
	[ dxExtra setNextKeyView:dxExtra ] ;	//  loop in dxExtra (UTC) field
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newSecondExchange:) name:@"CapturedSecondExchange" object:nil ] ;
	
	if ( master ) [ master setCabrilloContestName:"BARTG-RTTY" ] ;
}

//  check GMT here
- (void)newSecondExchange:(NSNotification*)notify
{
	NSString *str, *capturedString ;
	Modem *src ;
	int length ;
	
	//  check if we are the active interface
	if ( client != [ manager selectedContestInterface ] ) return ;
	
	if ( master ) {
		src = [ notify object ] ;	
		capturedString = [ self asciiCString:[ src capturedString ] ] ;
		
		length = [ capturedString length ] ;
		if ( length > 10 ) length = 10 ;
		str = [ capturedString substringWithRange:NSMakeRange(0,length) ] ;
		[ capturedString release ] ;
		
		if ( dxExchange ) {
			str = [ self asciiString:str ] ;	//  strip phi
			[ dxExchange setStringValue:str ] ;
			//  validate exchange and reselect the visible exchange field
			if ( ![ self validateTime:str ] ) {
				[ [ dxExchange window ] makeKeyAndOrderFront:self ] ;
				[ dxExchange setStringValue:@"" ] ;
				[ dxExchange selectText:self ] ;
			}
			//  stay in time field
			selectedFieldType = kExtraTextField ;
		}
	}
}

//  merge the QSO number received and UTC received into a single text field
- (ContestQSO*)createQSOFromCurrentData
{
	ContestQSO *p ;
	NSString *str1, *str2 ;
	int length ;

	p = [ super createQSOFromCurrentData ] ;
	p->callsign = [ self currentCallsign ] ;
	
	str1 = [ dxExchange stringValue ] ;
	str2 = [ dxExtra stringValue ] ;
	
	//  cancat the two received fields
	length = [ str1 length ]+[ str2 length ]+2 ;
	p->exchange = ( char* )malloc( length ) ;
	sprintf( p->exchange, "%s-%s", [ str1 cStringUsingEncoding:kTextEncoding ], [ str2 cStringUsingEncoding:kTextEncoding ] ) ;
	p->exchange[length-1] = 0 ;
	
	p->rst = [ dxRST intValue ] ;

	return p ;
}

//  NOTE: the QSO number and UTC received are saved as 123-0030 format in the internal log
- (void)writeCabrilloFields
{
	NSString *section, *qth ;
	const char *qths ;
	
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
	int i, count, frequency, year, month, day, utc, rst, rxNumber, rxUTC ;
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
	
		//											     QSO  UTC				  QSO  UTC
		//  QSO: 28000 RY 2002-03-17 0910 ZZ6ZZ      599 0001 0908 CT1AGF     599 0321 0909
		
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
			
			fprintf( cabrilloFile, "%-11s", myCall ) ;
			fprintf( cabrilloFile, "599 %04d %04d ", q->qsoNumber, utc ) ;
			
			fprintf( cabrilloFile, "%-11s", callsign ) ;

			rst = q->rst ;
			if ( rst > 599 ) rst = 599 ; else if ( rst < 111 ) rst = 111 ;
			
			sscanf( q->exchange,"%d-%d", &rxNumber, &rxUTC ) ;

			fprintf( cabrilloFile, "%3d %04d %04d", rst, rxNumber, rxUTC ) ;
		
			fprintf( cabrilloFile, "\n" ) ;
			
			if ( ++count >= numberOfQSO ) break ;
		}
	}
}

@end
