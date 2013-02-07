//
//  RSTExchange.m
//  cocoaModem
//
//  Created by Kok Chen on Sat Nov 27 2004.
	#include "Copyright.h"
//

#import "RSTExchange.h"
#import "Cabrillo.h"
#import "Messages.h"
#import "Modem.h"
#import "ContestManager.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"


@implementation RSTExchange


- (void)awakeFromNib
{
	[ self initializeActions ] ;
	[ self setInterface:dxCall to:@selector(callFieldChanged) ] ;	
	if ( dxExchange ) [ self setInterface:dxExchange to:@selector(exchangeFieldChanged) ] ;	
	if ( dxRST ) [ self setInterface:dxRST to:@selector(rstFieldChanged) ] ;	
	if ( dxExtra ) [ self setInterface:dxExtra to:@selector(extraFieldChanged) ] ;	
}

- (void)selectCallsignField
{
	selectedFieldType = kCallsignTextField ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:CallNotify object:dxCall ] ;
	[ self selectField:dxCall ] ;
	[ dxCall markAsSelected:YES ] ;
	[ dxExchange markAsSelected:NO ] ;
	if ( dxExtra ) [ dxExtra markAsSelected:NO ] ;
}

- (void)selectExchangeField
{
	selectedFieldType = kExchangeTextField ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:ExchangeNotify object:dxExchange ] ;
	[ self selectField:dxExchange ] ;
	[ dxCall markAsSelected:NO ] ;
	[ dxExchange markAsSelected:YES ] ;
	if ( dxExtra ) [ dxExtra markAsSelected:NO ] ;
}

- (void)selectExtraField
{
	if ( dxExtra ) {
		selectedFieldType = kExtraTextField ;
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:ExtraFieldNotify object:dxExtra ] ;
		[ self selectField:dxExtra ] ;
		[ dxCall markAsSelected:NO ] ;
		[ dxExchange markAsSelected:NO ] ;
		[ dxExtra markAsSelected:YES ] ;
	}
}

- (void)selectFirstResponderInActivePanel
{
	[ self selectCallsignField ] ;
}

- (void)timedMakeFieldFirstResponder
{
	if ( !master ) {
		//  select activeField called to master
		[ activeSubordinate selectActiveField ] ;
		return ;
	}
	if ( self != [ master activeSubordinate ] ) return ;
	
	if ( selectedFieldType == kExchangeTextField ) {
		[ dxExchange becomeFirstResponder ] ;
	}
	else if ( selectedFieldType == kCallsignTextField ) {
		[ dxCall becomeFirstResponder ] ;
	}
}

- (void)makeFieldFirstResponder
{
	[ NSTimer scheduledTimerWithTimeInterval:0.35 target:self selector:@selector(timedMakeFieldFirstResponder) userInfo:self repeats:NO ] ;
}


//  select the text field in the active subordinate
- (void)selectActiveField
{
	if ( !master ) {
		//  select activeField called to master
		[ activeSubordinate selectActiveField ] ;
		return ;
	}
	if ( self != [ master activeSubordinate ] ) return ;
	
	//  active contest interface
	if ( selectedFieldType == kExchangeTextField ) {
		[ self selectExchangeField ] ; 
		[ dxExchange selectText:self ] ;
		[ dxExchange becomeFirstResponder ] ;
	}
	else if ( selectedFieldType == kCallsignTextField ) {
		[ self selectCallsignField ] ; 
		//[ [ dxCall window ] selectKeyViewFollowingView:dxCall ] ;
		[ dxCall selectText:self ] ;
		[ dxCall becomeFirstResponder ] ;
	}
}

//  new callsign entered
- (void)newCallsign:(NSNotification*)notify
{
	NSString *capturedString ;
	int band ;
	Boolean duped ;
	Modem *src ;
	ContestInterface *activeModem ;
	
	src = [ notify object ] ;	
	if ( !src ) return ;
	
	//  check if we are the active interface (RTTY, Hellschreiber and PSK are all possible interfaces)
	activeModem = [ manager selectedContestInterface ] ;
	if ( (Modem*)client != (Modem*)activeModem ) return ;
	
	//  enter callsign
	if ( master ) {

		band = [ self selectedBand ] ;
		capturedString = [ self asciiCString:[ src capturedString ] ] ;   // strip phi
		activeCall = [ master receivedCallsign:capturedString band:band isDupe:&duped ] ;
		//  activeCall is nil if the callsign is a dupe
		//  however, insert callsign into call field anyway even if dupe, and display dupe
		//  remember that activeCall is nil (dupes have to be treated differently when logging)
		[ dxCall setStringValue:capturedString ] ;
		[ dxCall display ] ;
		
		if ( activeCall != nil ) {
			// register and update time
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"RegisterAndUpdateTime" object:nil ] ;
			//  and move to exchange text field
			selectedFieldType = kExchangeTextField ;
			[ master setDupeState:NO ] ;
			if ( !duped ) [ self setWatermarkState:NO ] ; else [ self setSmallWatermarkState:YES ] ;
		}
		else {
			//  stay in callsign field
			selectedFieldType = kCallsignTextField ;
			[ master setDupeState:YES ];
			[ self setWatermarkState:YES ] ;
		}
		[ capturedString release ] ;
	}
}

//  this is called from a TransparentTextField notification
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
		if ( dxExtra ) [ dxExtra markAsSelected:NO ] ;
		selectedFieldType = kCallsignTextField ;
		break ;
	case kExchangeTextField:
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:ExchangeNotify object:dxExchange ] ;
		[ dxCall markAsSelected:NO ] ;
		[ dxExchange markAsSelected:YES ] ; 
		if ( dxExtra ) [ dxExtra markAsSelected:NO ] ;
		selectedFieldType = kExchangeTextField ;
		break ;
	case kExtraTextField:
		if ( dxExtra ) {
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:ExtraFieldNotify object:dxExtra ] ;
			[ dxCall markAsSelected:NO ] ;
			[ dxExchange markAsSelected:NO ] ; 
			[ dxExtra markAsSelected:YES ] ;
			selectedFieldType = kExtraTextField ;
		}
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
	
	if ( master ) {
		src = [ notify object ] ;	
		capturedString = [ self asciiCString:[ src capturedString ] ] ;
		length = [ capturedString length ] ;
		if ( length > 10 ) length = 10 ;
		str = [ capturedString substringWithRange:NSMakeRange(0,length) ] ;			// v0.25 bug fix - retain, v0.27 remove retain
		[ capturedString release ] ;
		
		if ( dxExchange ) {
			str = [ self asciiString:str ] ;	//  strip phi
			[ dxExchange setStringValue:str ] ;
			//  validate exchange and reselect the visible exchange field
			if ( ![ self validateExchange:str ] ) {
				[ [ dxExchange window ] makeKeyAndOrderFront:self ] ;
				[ dxExchange setStringValue:@"" ] ;
				[ dxExchange selectText:self ] ;
			}
			//  stay in exchange field
			selectedFieldType = kExchangeTextField ;
		}
	}
}

//  initialize this contest here
- (void)setupFields
{
	if ( !master ) /* sanity check */ return ;
	
	savedCallsign = savedExchange = @"" ;
	callFieldEmpty = YES ;
	
	[ super setupFields ] ;

	upperFormatter = [ [ UpperFormatter alloc ] init ] ;
	if ( upperFormatter ) {
		[ dxCall setFormatter:upperFormatter ] ;
		[ dxRST setFormatter:upperFormatter ] ;
		[ dxExchange setFormatter:upperFormatter ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newCallsign:) name:@"CapturedContestCallsign" object:nil ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newExchange:) name:@"CapturedContestExchange" object:nil ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(selectActiveField) name:@"FinishControlClick" object:nil ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(newFieldSelected:) name:@"SelectNewField" object:nil ] ;
		[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(makeFieldFirstResponder) name:@"ReselectField" object:nil ] ;

		//  field that overlap watermark are transparent.  Place it over everything
		//  (there is an disabled opaque filed below each transparent field -- the watermark is in between)
		[ dxCall moveAbove ] ;
		[ dxCall setFieldType:kCallsignTextField ] ;
		[ dxRST moveAbove ] ;
		[ dxExchange moveAbove ] ;
		[ dxExchange setFieldType:kExchangeTextField ] ;
		[ qsoNumberField moveAbove ] ;
		if ( dxExtra ) {
			//  set up tage of UTC field
			[ dxExtra moveAbove ] ;
			[ dxExtra setFieldType:kExtraTextField ] ;
		}
		[ dxCall setDelegate:self ] ;  // to remove DUPE watermark
		[ dxCall setNextKeyView:dxExchange ] ;
		[ dxExchange setNextKeyView:dxExchange ] ;	//  loop in dxExchange field
		selectedFieldType = kCallsignTextField ;
	}
	[ self setWatermarkState:NO ] ;
}

- (NSString*)fetchCallString
{
	return [ dxCall stringValue ] ;
}

- (NSString*)fetchSavedCallString
{
	return savedCallsign ;
}

- (NSString*)fetchReceivedExchange
{
	return [ dxExchange stringValue ] ;
}

- (NSString*)fetchSavedReceivedExchange
{
	return savedExchange ;
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

//  override by subclass to set up default fields
- (void)clearFieldsToDefault
{
	[ dxCall setStringValue:@"" ] ;
	if ( dxRST ) [ dxRST setStringValue:@"599" ] ;
	if ( dxExchange ) [ dxExchange setStringValue:@"" ] ;
	if ( dxExtra ) [ dxExtra setStringValue:@"" ] ;
}

- (void)newQSO:(int)n
{
	int i ;
	
	if ( master ) {
		// subordinate
		[ qsoNumberField setIntValue:n ] ;
		[ self clearFieldsToDefault ] ;
		activeQSONumber = n ;
		return ;
	}
	//  master -- sets up all subordinates, and then select first responder
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"RegisterTime" object:nil ] ;
	for ( i = 0; i < subordinates; i++ ) [ subordinate[i] newQSO:activeQSONumber ] ;
	[ self selectFirstResponder ] ;
}

- (void)clearCurrentQSO
{
	int i ;
	
	if ( master ) {
		// subordinate
		[ self clearFieldsToDefault ] ;
		[ self setWatermarkState:NO ] ;
		return ;
	}
	//  master -- sets up all subordinates, and then select first responder
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"RegisterTime" object:nil ] ;
	[ self setDupeState:NO ] ;
	for ( i = 0; i < subordinates; i++ ) [ subordinate[i] clearCurrentQSO ] ;
	[ self selectFirstResponder ] ;
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
	
	t1 = t2 = t3 = 0 ;
	sscanf( [ qsoStrings[kQSOTime] cStringUsingEncoding:kTextEncoding ], "%d:%d:%d", &t1, &t2, &t3 ) ;
	t.hour = t1 ;
	t.minute = t2 ;
	t.second = t3 ;
	t1 = t2 = 1 ; 
	t3 = 5 ;
	sscanf( [ qsoStrings[kQSODate] cStringUsingEncoding:kTextEncoding ], "%d/%d/%d", &t1, &t2, &t3 ) ;
	t.day = t1 ;
	t.month = t2 ;
	t.year = t3 ;
	if ( [ qsoStrings[kQSOCall] length ] <= 0 ) {
		activeCall = [ self hash:"NIL" ] ;
	}
	else {
		activeCall = [ self hash:(char*)[ qsoStrings[kQSOCall] cStringUsingEncoding:kTextEncoding ] ] ;
	}
	p = (ContestQSO*)malloc( sizeof( ContestQSO ) ) ;
	p->frequency = 14.080 ;
	if ( [ qsoStrings[kQSOFreq] length ] > 0 ) sscanf( [ qsoStrings[kQSOFreq] cStringUsingEncoding:kTextEncoding ], "%f", &p->frequency ) ;
	importedFrequency = p->frequency ;
	
	//  QSO number
	if ( [ qsoStrings[kQSONumber] length ] > 0 ) {
		t1 = 0 ;
		sscanf( [ qsoStrings[kQSONumber] cStringUsingEncoding:kTextEncoding ], "%d", &t1 ) ;
		p->qsoNumber = t1 ;
	}
	if ( p->qsoNumber >= activeQSONumber ) activeQSONumber = p->qsoNumber ;
	//  QSO time
	p->time = t ;
	//  QSO mode
	p->mode = modeForString( qsoStrings[kQSOMode] ) ;
	//  RST
	t1 = 599 ;
	if ( [ qsoStrings[kQSORST] length ] > 0 ) sscanf( [ qsoStrings[kQSORST] cStringUsingEncoding:kTextEncoding ], "%d", &t1 ) ;
	p->rst = t1 ;

	str = qsoStrings[kQSOExch] ;
	p->exchange = "" ;
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
//  master only
//  return true if successful, false if duped
- (Boolean)setDXCall:(NSString*)str panel:(Contest*)panel isDupe:(Boolean*)duped
{
	if ( master ) return NO ;
	
	activeBand = [ panel selectedBand ] ;
	activeCall = [ self receivedCallsign:str band:activeBand isDupe:duped ] ;
	return ( activeCall != nil ) ;
}

//  set master entry from dxRSTSet
- (void)setDXRST:(NSString*)string panel:(RSTExchange*)panel
{
	//  no need to do anything, thetextField already has the string
}

- (void)callFieldChanged
{
	NSString *string ;
	Boolean notDupe, realDupe ;
	
	string = [ dxCall stringValue ] ;
	if ( [ string isEqualToString:previousCall ] ) return ;

	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"RegisterTime" object:nil ] ;
	
	if ( [ string length ] > 0 ) {
		callFieldEmpty = NO ;
		//  call to master
		[ string retain ] ;
		notDupe = [ (RSTExchange*)master setDXCall:string panel:self isDupe:&realDupe ] ;
		[ string release ] ;
				
		if ( notDupe ) {
			//  not a dupe, update time
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"RegisterAndUpdateTime" object:nil ] ;

			if ( realDupe ) {
				// dupe was bypassed
				[ self setSmallWatermarkState:YES ] ;
			}
			selectedFieldType = kExchangeTextField ;
			activeCall = [ master currentCallsign ] ;
			[ dxExchange setIgnoreFirstResponder:NO ] ;
			[ self selectExchangeField ] ;
		}
		else {
			selectedFieldType = kCallsignTextField ;
			activeCall = nil ;
			[ self setWatermarkState:YES ] ;
			[ dxExchange setIgnoreFirstResponder:YES ] ;
			string = @"" ;
		}
	}
	else {
		//  always clear dupe if dxField is cleared
		if ( !callFieldEmpty ) {
			[ self setWatermarkState:NO ] ;
		}
		callFieldEmpty = YES ;
		[ dxExchange setIgnoreFirstResponder:NO ] ;
	}	
	[ previousCall setString:string ] ;
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

//  override if class has third field
- (void)extraFieldChanged
{
}

- (void)rstFieldChanged
{
	if ( master ) [ self setDXRST:[ dxRST stringValue ] panel:self ] ;
}

- (ContestQSO*)createQSOFromCurrentData
{
	ContestQSO *p ;
	NSString *str ;

	p = [ super createQSOFromCurrentData ] ;
	p->callsign = [ self currentCallsign ] ;
	str = [ dxExchange stringValue ] ;
	p->exchange = ( char* )malloc( [ str length ]+1 ) ;
	strcpy( p->exchange, [ str cStringUsingEncoding:kTextEncoding ] ) ;
	p->rst = [ dxRST intValue ] ;

	return p ;
}

//  this is where we log a QSO using -createQSOFromCurrentData
- (void)logButtonPushed
{
	ContestQSO *p ;
	NSString *c ;
	
	//  check DX fields
	if ( [ self isEmpty:dxCall ] || [ self isEmpty:dxExchange ] ) {
		[ Messages alertWithMessageText:@"Not all field are filled." informativeText:@"Call sign and exchange fields need to be non-empty.  Please fill them and click on Log again." ] ;
		return ;
	}	
	if ( master ) {	
		//  save fields
		[ savedCallsign release ] ;
		savedCallsign = [ [ NSString alloc ] initWithString:[ dxCall stringValue ] ] ;
		[ savedExchange release ] ;
		savedExchange = [ [ NSString alloc ] initWithString:[ dxExchange stringValue ] ] ;
		
		if ( [ (RSTExchange*)master validateExchange:savedExchange ] ) {
			//  get call from dxCall field if it was a dupe, create one
			if ( activeCall == nil ) {
				c = [ dxCall stringValue ] ;
				activeCall = [ self getCallsign:[ c cStringUsingEncoding:kTextEncoding ] ] ;
			}
			p = [ self createQSOFromCurrentData ] ;
			[ master createQSO:p callsign:activeCall mode:activeMode ] ;
			[ master journalQSO:p ] ;
			[ master newQSO:0 ] ;
			[ self selectCallsignField ] ;
		}
		else {
			[ dxExchange setStringValue:@"" ] ;
			[ dxExchange selectText:self ] ;
		}
		//  force clear the dupe state/marker
		[ master setDupeState:NO ] ;
		[ self setWatermarkState:NO ] ;
		
		[ master logMacro ] ;
	}
	else [ self setDupeState:NO ] ;
}

/* local */
void saveRSTToXML( FILE* file, ContestQSO* q )
{
	int rst = q->rst ;
	
	if ( rst > 599 ) rst = 599 ; else if ( rst < 100 ) rst = 100 ;
	fprintf( file, "\t\t\t<rst>%d</rst>\n", rst ) ;
}

- (void)saveQSOToXML:(FILE*)file qso:(ContestQSO*)q
{
	fprintf( file, "\t\t<QSO>\n" ) ;
	saveQSONumberToXML( file, q ) ;
	saveCallToXML( file, q ) ;
	saveDateToXML( file, q ) ;
	saveTimeToXML( file, q ) ;
	saveModeToXML( file, q ) ;
	saveRSTToXML( file, q ) ;
	saveExchangeToXML( file, q ) ;
	saveFrequencyToXML( file, q ) ;
	fprintf( file, "\t\t</QSO>\n" ) ;
}

// ------------------- Panther XML parser -------------------------
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
				else if ( [ elementName isEqualToString:@"rst" ] ) parseQSOPhase = kQSORST ;
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
	else if ( [ elementName isEqualToString:@"rst" ] ) parseQSOPhase = 0 ;
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
