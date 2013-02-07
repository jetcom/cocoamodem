//
//  ContestQSOObj.m
//  cocoaModem
//
//  Created by Kok Chen on 12/24/04.
	#include "Copyright.h"
//

#import "ContestQSOObj.h"
#import "TextEncoding.h"


@implementation ContestQSOObj

//	encapsulates ContestQSO into an Objective C object

- (id)initWith:(ContestQSO*)q
{
	self = [ super init ] ;
	if ( self ) {
		qso = q ;
	}
	return self ;
}

- (ContestQSO*)ptr
{
	return qso ;
}

- (int)qsoNumber
{
	return qso->qsoNumber ;
}

- (NSString*)callsign
{
	return [ NSString stringWithCString:qso->callsign->callsign encoding:kTextEncoding ] ;
}

//  return band (metres)
- (int)band
{
	return band( qso->frequency ) ;
}

- (void)setBand:(int)value
{
	qso->frequency = rttyFrequency( value ) ;
}

- (DateTime*)time
{
	return &( qso->time ) ;
}

- (NSString*)rst
{
	int val = qso->rst ;
	return ( val == 0 ) ? @"" : [ NSString stringWithFormat:@"%d", val ] ;
}

- (void)setRST:(NSString*)rst 
{
	int p ;
	
	p = 599 ;
	sscanf( [ rst cStringUsingEncoding:kTextEncoding ], "%d", &p ) ;
	qso->rst = p ;
}

- (NSString*)exchange
{
	char *x = qso->exchange ;
	
	return [ NSString stringWithCString:x encoding:kTextEncoding ] ;
}

- (void)setExchange:(NSString*)exch 
{
	qso->exchange = ( char* )malloc( [ exch length ]+1 ) ;
	strcpy( qso->exchange, [ exch cStringUsingEncoding:kTextEncoding ] ) ;
}

//  return mode
- (NSString*)mode
{
	switch ( qso->mode ) {
	case RTTYMODE:
		return @"RY" ;
	case CWMODE:
		return @"CW" ;
	case SSBMODE:
		return @"PH" ;
	case PSKMODE:
		return @"PK" ;
	}
	return @"??" ;
}

- (void)setQSOMode:(char*)m
{
	if ( strcmp( m, "RY" ) == 0 ) qso->mode = RTTYMODE ;
	else if ( strcmp( m, "CW" ) == 0 ) qso->mode = CWMODE ;
	else if ( strcmp( m, "PH" ) == 0 ) qso->mode = SSBMODE ;
	else if ( strcmp( m, "PK" ) == 0 ) qso->mode = PSKMODE ;
}

//  sort by callsign, arranging the same callsign by band
- (NSComparisonResult)sortByCallsign:(ContestQSOObj*)other
{
	NSComparisonResult order ;
	int band0, band1 ;
	
	order = [ [ self callsign ] compare:[ other callsign ] ] ;
	if ( order != NSOrderedSame ) return order ;
	
	//  same callsign, check band
	band0 = [ self band ] ;
	band1 = [ other band ] ;
	if ( band0 == band1 ) {
		//  same band, check QSO number
		return ( qso->qsoNumber < [ other qsoNumber ]  ) ?  NSOrderedAscending : NSOrderedDescending ;
	}
	return ( band0 < band1 ) ?  NSOrderedAscending : NSOrderedDescending ;
}

//  reverse sort by callsign, arranging the same callsign by band
- (NSComparisonResult)reverseByCallsign:(ContestQSOObj*)other
{
	NSComparisonResult order ;
	int band0, band1 ;
	
	order = [ [ other callsign ] compare:[ self callsign ] ] ;
	if ( order != NSOrderedSame ) return order ;
	
	//  same callsign, check band
	band0 = [ self band ] ;
	band1 = [ other band ] ;
	if ( band0 == band1 ) {
		//  same band, check QSO number
		return ( qso->qsoNumber < [ other qsoNumber ]  ) ?  NSOrderedAscending : NSOrderedDescending ;
	}
	return ( band0 < band1 ) ?  NSOrderedAscending : NSOrderedDescending ;
}

- (NSComparisonResult)sortByNumber:(ContestQSOObj*)other
{
    return ( qso->qsoNumber < [ other qsoNumber ]  ) ?  NSOrderedAscending : NSOrderedDescending ;
}

- (NSComparisonResult)reverseByNumber:(ContestQSOObj*)other
{
    return ( qso->qsoNumber > [ other qsoNumber ]  ) ?  NSOrderedAscending : NSOrderedDescending ;
}

//  sort by band, in ascending QSO number
- (NSComparisonResult)sortByBand:(ContestQSOObj*)other
{
	int diff ;
	
	diff = [ self band ] - [ other band ] ;
	if ( diff == 0 ) {
		return ( qso->qsoNumber < [ other qsoNumber ]  ) ?  NSOrderedAscending : NSOrderedDescending ;
	}
	return ( diff < 0 ) ? NSOrderedAscending : NSOrderedDescending ;
}

//  reverse sort by band, in ascending QSO number
- (NSComparisonResult)reverseByBand:(ContestQSOObj*)other
{
	int diff ;
	
	diff = [ self band ] - [ other band ] ;
	if ( diff == 0 ) {
		return ( qso->qsoNumber < [ other qsoNumber ]  ) ?  NSOrderedAscending : NSOrderedDescending ;
	}
	return ( diff > 0 ) ? NSOrderedAscending : NSOrderedDescending ;
}

@end
