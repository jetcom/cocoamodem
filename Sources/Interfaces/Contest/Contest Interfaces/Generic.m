//
//  Generic.m
//  cocoaModem
//
//  Created by Kok Chen on Mon Oct 11 2004.
	#include "Copyright.h"
//

#import "Generic.h"
#import "Cabrillo.h"
#import "ContestManager.h"
#import "Messages.h"
#import "Modem.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"


@implementation Generic

- (void)awakeFromNib
{
	[ self initializeActions ] ;
	[ self setInterface:dxCall to:@selector(callFieldChanged) ] ;	
	[ self setInterface:dxExchange to:@selector(exchangeFieldChanged) ] ;	
}


- (void)selectCallsignField
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:CallNotify object:dxCall ] ;
	[ self selectField:dxCall ] ;
	[ dxCall markAsSelected:YES ] ;
	[ dxExchange markAsSelected:NO ] ;
}

- (void)selectExchangeField
{
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:ExchangeNotify object:dxExchange ] ;
	[ self selectField:dxExchange ] ;
	[ dxCall markAsSelected:NO ] ;
	[ dxExchange markAsSelected:YES ] ;
}

- (void)newCallsign:(NSNotification*)notify
{
	NSString *str, *capturedString ;
	int band, length ;
	Boolean duped ;
	Modem *src ;
	
	//  check if we are the active interface
	if ( client != [ manager selectedContestInterface ] ) return ;

	src = [ notify object ] ;	
	capturedString = [ self asciiCString:[ src capturedString ] ] ;

	length = [ capturedString length ] ;
	if ( length > 15 ) length = 15 ;
	str = [ capturedString substringWithRange:NSMakeRange(0,length) ] ;
	[ capturedString release ] ;
	
	//  enter callsign
	if ( master ) {
		band = [ self selectedBand ] ;
		activeCall = [ master receivedCallsign:str band:band isDupe:&duped ] ;
		if ( activeCall != nil ) {
			[ self selectExchangeField ] ; 
			[ [ dxCall window ] selectKeyViewFollowingView:dxCall ] ;
			[ dxCall setStringValue:str ] ;
			[ dxCall display ] ;
			[ dxExchange selectText:self ] ;
		}
		else [ self selectCallsignField ] ;
	}
}

//  this is called from a TransparentTextField  notification
- (void)newFieldSelected:(NSNotification*)notify
{
	TransparentTextField *field ;

	if ( client != [ manager selectedContestInterface ] ) return ;
	
	field = [ notify object ] ;
	switch ( [ field fieldType ] ) {
	case kCallsignTextField:
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:CallNotify object:dxCall ] ;
		[ dxCall markAsSelected:YES ] ;
		[ dxExchange markAsSelected:NO ] ; 
		break ;
	case kExchangeTextField:
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:ExchangeNotify object:dxExchange ] ;
		[ dxCall markAsSelected:NO ] ;
		[ dxExchange markAsSelected:YES ] ; 
		break ;
	default:
		break ;
	}
}

- (Boolean)validateExchange:(NSString*)exchange 
{
	return YES ;
}

//  check state/number here
- (void)newExchange:(NSNotification*)notify
{
	NSString *str, *capturedString ;
	Modem *src ;
	int length ;
	
	//  check if we are the active interface
	if ( client != [ manager selectedContestInterface ] ) return ;
	
	src = [ notify object ] ;	
	capturedString = [ self asciiCString:[ src capturedString ] ] ;

	length = [ capturedString length ] ;
	if ( length > 10 ) length = 10 ;
	str = [ capturedString substringWithRange:NSMakeRange(0,length) ] ;
	[ capturedString release ] ;
	if ( dxExchange ) {
		[ dxExchange setStringValue:str ] ;
		//  validate exchange and reselect the visible exchange field
		if ( ![ self validateExchange:str ] ) {
			[ [ dxExchange window ] makeKeyAndOrderFront:self ] ;
			[ dxExchange setStringValue:@"" ] ;
			[ dxExchange selectText:self ] ;
		}
	}
}

//  initialize this contest here
- (void)setupFields
{
	if ( !master ) /* sanity check */ return ;
	
	[ super setupFields ] ;
	
	if ( contestName ) [ contestName release ] ;
	contestName = [ [ NSString alloc ] initWithString:@"Generic" ] ;

	upperFormatter = [ [ UpperFormatter alloc ] init ] ;
	if ( upperFormatter ) {
		[ dxCall setFormatter:upperFormatter ] ;
		[ dxExchange setFormatter:upperFormatter ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newCallsign:) name:@"CapturedContestCallsign" object:nil ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newExchange:) name:@"CapturedContestExchange" object:nil ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newFieldSelected:) name:@"SelectNewField" object:nil ] ;

		//  field that overlap watermark are transparent.  Place it over everything
		//  (there is an disabled opaque filed below each transparent field -- the watermark is in between)
		[ dxCall moveAbove ] ;
		[ dxCall setFieldType:kCallsignTextField ] ;
		[ dxExchange moveAbove ] ;
		[ dxExchange setFieldType:kExchangeTextField ] ;
		[ qsoNumberField moveAbove ] ;
				
		[ dxCall setDelegate:self ] ;  // to remove DUPE watermark
		[ dxCall setNextKeyView:dxExchange ] ;
	}
	[ self setWatermarkState:NO ] ;
}

- (NSString*)fetchCallString
{
	return [ dxCall stringValue ] ;
}

// band switched, check call (dupe) again
- (void)bandSwitched:(int)band
{
	NSString *call ;
	Boolean duped ;
	
	activeBand = band ;
	call = [ dxCall stringValue ] ;
	if ( [ call length ] > 0 ) {
		activeCall = ( master ) ? [ master receivedCallsign:call band:band isDupe:&duped ] : [ self receivedCallsign:call band:band isDupe:&duped ] ;
	}
}

- (void)newQSO:(int)n
{
	int i ;
	
	if ( master ) {
		//  only with active contest interface
		if ( client != [ manager selectedContestInterface ] ) return ;
		// subordinate
		[ dxCall setStringValue:@"" ] ;
		[ dxExchange setStringValue:@"" ] ;
		activeQSONumber = n ;
		[ qsoNumberField setIntValue:n ] ;
		[ self selectCallsignField ] ;
	}
	else {
		//  master
		for ( i = 0; i < subordinates; i++ ) [ subordinate[i] newQSO:activeQSONumber ] ;
	}
}

//  create a log entry from XML QSO element
- (void)enterQSOFromXML
{
	int i, t1, t2, t3 ;
	DateTime t ;
	ContestQSO *p ;
	NSString *str ;
	char *s ;
	
	if ( master ) /* if has master, must be a subordinate */ return ;
	
	sscanf( [ qsoStrings[kQSOTime] cStringUsingEncoding:kTextEncoding ], "%d:%d:%d", &t1, &t2, &t3 ) ;
	t.hour = t1 ;
	t.minute = t2 ;
	t.second = t3 ;
	sscanf( [ qsoStrings[kQSODate] cStringUsingEncoding:kTextEncoding ], "%d/%d/%d", &t1, &t2, &t3 ) ;
	t.day = t1 ;
	t.month = t2 ;
	t.year = t3 ;
	activeCall = [ self hash:(char*)[ qsoStrings[kQSOCall] cStringUsingEncoding:kTextEncoding ] ] ;
	p = (ContestQSO*)malloc( sizeof( ContestQSO ) ) ;
	sscanf( [ qsoStrings[kQSOFreq] cStringUsingEncoding:kTextEncoding ], "%f", &p->frequency ) ;
	sscanf( [ qsoStrings[kQSONumber] cStringUsingEncoding:kTextEncoding ], "%d", &t1 ) ;
	p->qsoNumber = t1 ;
	if ( p->qsoNumber >= activeQSONumber ) activeQSONumber = p->qsoNumber ;
	p->time = t ;
	p->mode = modeForString( qsoStrings[kQSOMode] ) ;
	
	str = qsoStrings[kQSOExch] ;
	p->exchange = nil ;
	if ( str ) {
		s = (char*)malloc( [ str length ]+1 ) ;
		strcpy( s, [ str cStringUsingEncoding:kTextEncoding ] ) ;
		p->exchange = s ;
	}
	if ( master ) [ master createQSO:p callsign:activeCall mode:activeMode ] ; else [ self createQSO:p callsign:activeCall mode:activeMode ] ;

	for ( i = 1; i < 7; i++ ) {
		if ( qsoStrings[i] ) [ qsoStrings[i] release ] ;
		qsoStrings[i] = nil ;
	}
}

/* local */
//  set master entry from dxCallSet
//  return true if successful, false if duped
- (Boolean)setDXCall:(NSString*)str panel:(Contest*)panel
{
	Boolean duped ;
	
	if ( master ) return NO ;
	
	activeBand = [ panel selectedBand ] ;
	activeCall = [ self receivedCallsign:str band:activeBand isDupe:&duped ] ;
	return ( activeCall != nil ) ;
}

- (void)callFieldChanged
{
	NSString *string ;
	Boolean state ;
	
	if ( [ [ dxCall clickedString ] length ] > 0 ) return ;
	string = [ dxCall stringValue ] ;
	
	if ( [ string length ] > 0 ) {
		//  call to master
		state = [ (Generic*)master setDXCall:string panel:self ] ;
		if ( state ) [ self selectExchangeField ] ; else [ self setWatermarkState:YES ] ;
	}
	else {
		if ( [ master isDuped ] ) [ self setWatermarkState:NO ] ;
	}
}

- (void)exchangeFieldChanged
{
	NSString *str ;
	
	if ( master ) {
		//  validate exchange if it is not empty
		str = [ dxExchange stringValue ] ;
		if ( [ str length ] > 0 ) {
			if ( ![ self validateExchange:str ] ) {
				[ dxExchange setStringValue:@"" ] ;
				[ dxExchange selectText:self ] ;
			}
		}
	}
}

//  local version of createQSOFromCurrentData
- (ContestQSO*)createQSOFromCurrentData
{
	ContestQSO *p ;
	NSString *str ;

	p = [ super createQSOFromCurrentData ] ;
	p->callsign = [ self currentCallsign ] ;
	str = [ dxExchange stringValue ] ;
	p->exchange = ( char* )malloc( [ str length ]+1 ) ;
	strcpy( p->exchange, [ str cStringUsingEncoding:kTextEncoding ] ) ;

	return p ;
}

- (void)writeCabrilloQSOs
{
	int i, count, frequency, year, month, day, utc ;
	char *mode, callsign[32], myCall[32], exchange[16] ;
	Callsign *c ;
	DateTime *time ;
	ContestQSO *q ;
	NSString *expanded ;
	
	myCall[0] = 0 ;
	if ( usedCallString ) {
		strncpy( myCall, [ usedCallString cStringUsingEncoding:kTextEncoding ], 16 ) ;
		myCall[13] = 0 ;
	}
	
	expanded = [ manager expandMacroInUserAndQSOInfo:[ [ cabrillo exchangeString ] cStringUsingEncoding:kTextEncoding ] ] ;
	strncpy( exchSent, [ expanded cStringUsingEncoding:kTextEncoding ], 16 ) ;

	count = 0 ;
	for ( i = 0; i < MAXQ; i++ ) {
		//  QSO: 21080 RY 2004-01-03 1800 W7AY         599     OR AK0A         599     KS
		
		q = sortedQSOList[i] ;
		if ( q ) {
			frequency = q->frequency*1000.0 + 0.1 ;
			mode = stringForMode( q->mode ) ;
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
			fprintf( cabrilloFile, "%10s ", exchSent ) ;
			fprintf( cabrilloFile, "%-13s", callsign ) ;

			strncpy( exchange, q->exchange, 12 ) ;
			exchange[10] = 0 ;
			fprintf( cabrilloFile, "%10s", exchange ) ;
		
			fprintf( cabrilloFile, "\n" ) ;
			
			if ( ++count >= numberOfQSO ) break ;
		}

	}
}

- (void)logButtonPushed
{
	ContestQSO *p ;
	
	//  check DX fields
	if ( [ self isEmpty:dxCall ] || [ self isEmpty:dxExchange ] ) {
		[ Messages alertWithMessageText:@"Not all field are filled." informativeText:@"Call sign and exchange fields need to be non-empty.  Please fill them and click on Log again." ] ;
		return ;
	}	
	if ( master ) {
		if ( [ (Generic*)master validateExchange:[ dxExchange stringValue ] ] ) {
			p = [ self createQSOFromCurrentData ] ;
			[ master createQSO:p callsign:activeCall mode:activeMode ] ;
			[ master journalQSO:p ] ;
			[ master newQSO:0 ] ;
			if ( [ master setDupeState:NO ] ) [ self setWatermarkState:NO ] ;
			[ self selectCallsignField ] ;
		}
		else {
			[ dxExchange setStringValue:@"" ] ;
			[ dxExchange selectText:self ] ;
		}
	}
}

//  NSXMLParser delegates
//  the following three method depends on the contest format
- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	if ( parseContest ) {
		if ( parseContestLog ) {
			//  contest log
			if ( parseQSO ) {
				// QSO fields
				if ( [ elementName isEqualToString:@"call" ] ) parseQSOPhase = kQSOCall ;
				else if ( [ elementName isEqualToString:@"date" ] ) parseQSOPhase = kQSODate ;
				else if ( [ elementName isEqualToString:@"time" ] ) parseQSOPhase = kQSOTime ;
				else if ( [ elementName isEqualToString:@"exch" ] ) parseQSOPhase = kQSOExch ;
				else if ( [ elementName isEqualToString:@"freq" ] ) parseQSOPhase = kQSOFreq ;
				else if ( [ elementName isEqualToString:@"mode" ] ) parseQSOPhase = kQSOMode ;
				else if ( [ elementName isEqualToString:@"qnum" ] ) parseQSOPhase = kQSONumber ;
				return ;
			}
			if ( [ elementName isEqualToString:@"QSO" ] ) {
				parseQSO = YES ;
				parseQSOPhase = 0 ;
				return ;
			}
		}
		else if ( [ elementName isEqualToString:@"contestLog" ] ) parseContestLog = YES ;
		else if ( [ elementName isEqualToString:@"contestName" ] ) parseContestName = YES ;
		return ;
	}
	if ( [ elementName isEqualToString:@"Contest" ] ) {
		parseContest = YES ;
		parseQSOPhase = 0 ;
		return ;
	}
	//  found unknown element, discard
	printf( "cocoaModem read xml discarding element name %s\n", [ elementName cStringUsingEncoding:kTextEncoding ] ) ;
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string 
{
	if ( parseContest ) {
		if ( parseContestLog ) {
			//  log segment
			if ( parseQSO ) {
				if ( parseQSOPhase ) {
					qsoStrings[parseQSOPhase] = [ string retain ] ;
				}
			}
		}
		if ( parseContestName ) {
			if ( contestName ) [ contestName release ] ;
			contestName = [ string retain ] ;
		}
	}
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString *)qName
{
	if ( [ elementName isEqualToString:@"QSO" ] ) {
		//  end of QSO element
		parseQSO = NO ;	
		[ self enterQSOFromXML ] ;
		parseQSOPhase = 0 ;
	}
	else if ( [ elementName isEqualToString:@"call" ] ) parseQSOPhase = 0 ;
	else if ( [ elementName isEqualToString:@"date" ] ) parseQSOPhase = 0 ;
	else if ( [ elementName isEqualToString:@"time" ] ) parseQSOPhase = 0 ;
	else if ( [ elementName isEqualToString:@"exch" ] ) parseQSOPhase = 0 ;
	else if ( [ elementName isEqualToString:@"freq" ] ) parseQSOPhase = 0 ;
	else if ( [ elementName isEqualToString:@"mode" ] ) parseQSOPhase = 0 ;
	else if ( [ elementName isEqualToString:@"qnum" ] ) parseQSOPhase = 0 ;

	else if ( [ elementName isEqualToString:@"contestName" ] ) parseContestName = NO ;
	else if ( [ elementName isEqualToString:@"contestLog" ] ) parseContestLog = NO ;
	else if ( [ elementName isEqualToString:@"Contest" ] ) parseContest = NO ;
}

//  delegate for callsign text field
- (void)controlTextDidChange:(NSNotification*)aNotification
{
	//  clear dupe state and watermark
	[ master setDupeState:NO ] ;
	[ self setWatermarkState:NO ] ;
}

@end
