//
//  Contest.m
//  cocoaModem
//
//  Created by Kok Chen on Mon Oct 04 2004.
	#include "Copyright.h"
//

#import "Contest.h"
#import <Cocoa/Cocoa.h>
#import "Cabrillo.h"
#import "cocoaModemParams.h"
#import "ContestInterface.h"
#import "ContestManager.h"
#import "Messages.h"
#import "Modem.h"
#import "TextEncoding.h"
#import "TransparentTextField.h"

@implementation Contest

//  Each Contest has a master Contest instance, create by the ContestManager
//  Each ContestInterface (Modem) has its own Contest instance, but only as a user interface.

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)init
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		activeCall = nil ;
		activeBand = 20 ;
		activeMode = RTTYMODE ;
		activeQSONumber = 1 ;
		oncePerMode = NO ;
		oncePerBand = YES ;
		manyPerBand = NO ;
		dupeState = NO ;
		bandMenuBypass = NO ;
		parser = nil ;
		master = nil ;
		manager = nil ;
		prototypeName = @"Generic" ;
		cabrilloContest = "" ;
		cabrilloCategorySuffix = nil ;   // if not nil, then "RTTY", etc
		previousField = nil ;
		activeSubordinate = nil ;
		busy = NO ;
		savedCallsign = savedExchange = @"" ;
		previousCall = [ [ NSMutableString alloc ] initWithCapacity:33 ] ;
		[ previousCall setString:@"" ] ;
		
		for ( i = 0; i < MAXQ-1; i++ ) {
			qso[i].callsign[0] = 0 ;
			qso[i].link = nil ;
			qso[i].next = &qso[i+1] ;
		}
		strcpy( qso[i].callsign, "****" ) ;
		qso[i].link = nil ;
		qso[i].next = &qso[0] ;
		
		for ( i = 0; i < 256; i++ ) isAlpha[i] = ( ( i >= 'a' && i <= 'z' ) || ( i >= 'A' && i <= 'Z' ) ) ; 
		for ( i = 0; i < 256; i++ ) isNumeric[i] = ( i >= '0' && i <= '9' ) ; 
		isNumeric[phi] = isNumeric[Phi] = YES ;
	}
	return self ;
}

- (void)initializeActions
{
	[ self setInterface:logButton to:@selector(logButtonPushed) ] ;
	[ self setInterface:clearButton to:@selector(clearButtonPushed) ] ;
	[ self setInterface:bandMenu to:@selector(bandMenuChanged) ] ;
}

- (ContestInterface*)modemClient
{
	return client ;
}

//  override by instance to pick the field to use as first responder when a newQSO happens
- (void)selectFirstResponderInActivePanel
{
}

//  select first responding textfield
- (void)selectFirstResponder
{
	int i ;
	Contest *sub ;
	ContestInterface *selectedModem ;
	
	if ( master ) {
		[ self selectFirstResponderInActivePanel ] ;
	}
	else {
		selectedModem = [ manager selectedContestInterface ] ;
		activeMode = [ selectedModem transmissionMode ] ;
		for ( i = 0; i < subordinates; i++ ) {
			sub = subordinate[i] ;
			if ( [ sub modemClient ] == selectedModem ) {
				[ sub selectFirstResponder ] ;
				activeSubordinate = sub ;
			}
		}
	}
}

- (id)initIntoBox:(NSBox*)box contestName:(NSString*)name prototype:(NSString*)prototype modem:(ContestInterface*)inClient master:(Contest*)inMaster manager:(ContestManager*)mgr
{
	NSView *oldView, *content ;
	NSArray *views ;
	NSString *s ;
	
	self = [ self init ] ;
	if ( self ) {
		client = inClient ;
		manager = mgr ;
		master = inMaster ;
		parser = nil ;
		subordinates = numberOfQSO = 0 ;
		parseContest = parseContestName = parseContestLog = parseQSO = NO ;
		contestName = [ [ NSString alloc ] initWithString:name ] ;
		if ( box ) {
			//  subordinate
			if ( [ NSBundle loadNibNamed:prototype owner:self ] ) {	
				// loadNib should have set up controlView connection
				if ( box && contestView ) {
					content = [ box contentView ] ;
					views = [ content subviews ] ;
					if ( views && [ views count ] > 0 ) {
						//  remove old subview
						oldView = views[0] ;
						if ( oldView ) [ oldView removeFromSuperview ] ;
					}
					[ box addSubview:contestView ] ;
				}
				[ contestView addSubview:watermark positioned:NSWindowAbove relativeTo:nil ] ;
				
				if ( logButton ) {
					//  for adding cmd-L to the button title
					unichar u[2] ;
					NSString *commandL ;
	
					u[0] = 0x2318 ;
					u[1] = 'L' ;
					commandL = [ NSString stringWithCharacters:u length:2 ] ;
					[ logButton setTitle:[ @"Log  " stringByAppendingString:commandL ] ] ;
				}
			}
			else {
				[ self release ] ;
				return nil ;
			}
		}
		s = prototypeName ;
		prototypeName = [ prototype retain ] ;
		if ( s ) [ s release ] ;

		if ( master ) {
			[ self setupFields ] ;
		}
	}
	return self ;
}

- (Boolean)isEmpty:(NSTextField*)field
{
	NSString *string ;
	const char *s ;
	
	string = [ field stringValue ] ;
	if ( [ string length ] == 0 ) return YES ;
	s = [ string cStringUsingEncoding:kTextEncoding ] ;
	while ( *s ) {
		if ( *s != ' ' || *s != '\t' ) break ;
		s++ ;
	}
	return ( *s == 0 ) ;
}

//  update band menu from selected (importedFrequency) frequency
- (void)updateBandMenu:(float)freq
{
	int v, n, i ;
	
	if ( !master ) return ;
	v = band( freq ) ;
	n = [ bandMenu numberOfItems ] ;
	for ( i = 0; i < n; i++ ) {
		if ( [ [ bandMenu itemAtIndex:i ] tag ] == v ) {
			[ bandMenu selectItemAtIndex:i ] ;
			break ;
		}
	}
	[ self bandSwitched:v ] ;
}

//  master
- (id)initContestName:(NSString*)name prototype:(NSString*)prototype parser:(NSXMLParser*)inParser manager:(ContestManager*)inManager
{
	Contest *t ;

	t = [ self initIntoBox:nil contestName:name prototype:prototype modem:nil master:nil manager:inManager ] ;

	importedFrequency = 14.080 ;
	manager = inManager ;
	parser = inParser ;
	if ( parser ) {
		[ parser setDelegate:self ] ;
		[ parser parse ] ;
	}
	return t ;
}

- (Contest*)activeSubordinate
{
	return activeSubordinate ;
}

//  add subordinates to master 
- (void)addSubordinate:(Contest*)sub
{
	if ( !master ) {
		//  no master pointer, so we are the master instance
		if ( subordinates < 15 ) {
			subordinate[subordinates++] = sub ;
			[ sub updateBandMenu:importedFrequency ] ;
		}
	}
}

//  subclasses of Contest should override this to set up fields and parse XML data
- (void)setupFields
{
	if ( master ) [ master setCabrilloContestName:"**REPLACE-ME**" ] ;
}

- (NSString*)contestName
{
	return contestName ;
}

- (NSString*)prototypeName
{
	return prototypeName ;
}

int band( float freq )
{
	if ( freq < 1.7 ) return 200 ;
	if ( freq < 2.1 ) return 160 ;
	if ( freq < 4.1 ) return 80 ;
	if ( freq < 8.1 ) return 40 ;
	if ( freq < 11.1 ) return 30 ;
	if ( freq < 15.1 ) return 20 ;
	if ( freq < 19.1 ) return 17 ;
	if ( freq < 22.1 ) return 15 ;
	if ( freq < 25.1 ) return 12 ;
	if ( freq < 30.1 ) return 10 ;
	if ( freq < 60.1 ) return 6 ;
	return 2 ;
}

//  look for callsign in hash table
//  create an entry if it is not there, and return a pointer to the table
- (Callsign*)hash:(const char*)call
{
	int i ;
	unsigned long h ;
	const char *c ;
	Callsign *p ;
	
	h = 0 ;
	c = call ;
	for ( i = 0; i < 32; i++ ) {
		if ( *c == 0 ) break ;
		h = ( h << 2 ) + ( ( *c++ )&0xff ) ;
	}
	h = h & ( MAXQ-1 ) ;
	p = &qso[h] ;
	for ( i = 0; i < MAXQ; i++ ) {
		if ( p->callsign[0] == 0 ) {
			strcpy( p->callsign, call ) ;
			p->link = nil ;
			return p ;
		}
		if ( strcmp( p->callsign, call ) == 0 ) return p ;
		p = p->next ;
	}
	printf( "cocoaModem: hash table out of memory?!\n" ) ;
	return nil ;
}

float defaultCWFrequency[]   = { 1.8, 3.525, 7.025, 14.025, 21.025, 28.025 } ;
float defaultRTTYFrequency[] = { 1.8, 3.580, 7.080, 14.080, 21.080, 28.080 } ;
float defaultSSBFrequency[]  = { 1.8, 3.750, 7.150, 14.150, 21.200, 28.350 } ;
float defaultPSKFrequency[]  = { 1.8, 3.610, 7.070, 14.070, 21.070, 28.120 } ;

float rttyFrequency( int band )
{
	int b ;
	
	switch ( band ) {
	case 160:
		b = 0 ;
		break ;
	case 80:
		b = 1 ;
		break ;
	case 40:
		b = 2 ;
		break ;
	default:
	case 20:
		b = 3 ;
		break ;
	case 15:
		b = 4 ;
		break ;
	case 10:
		b = 5 ;
		break ;
	}
	return defaultRTTYFrequency[b] ;
}

- (float)defaultFrequencyForBand
{
	int b ;
	
	switch ( activeBand ) {
	case 160:
		b = 0 ;
		break ;
	case 80:
		b = 1 ;
		break ;
	case 40:
		b = 2 ;
		break ;
	default:
	case 20:
		b = 3 ;
		break ;
	case 15:
		b = 4 ;
		break ;
	case 10:
		b = 5 ;
		break ;
	}
	if ( activeMode == CWMODE ) return defaultCWFrequency[b] ;
	if ( activeMode == SSBMODE ) return defaultSSBFrequency[b] ;
	if ( activeMode == PSKMODE ) return defaultPSKFrequency[b] ;
	// default to RTTY
	return defaultRTTYFrequency[b] ;
}

//  return activeCall from master
- (Callsign*)currentCallsign
{
	if ( master ) return [ master currentCallsign ] ;
	return activeCall ;
}

//  return callsign if not dupe, nil if dupe
- (Callsign*)getCallsignCheckingDupe:(const char*)call
{
	ContestQSO *qsoLink ;
	DateTime *t ;
	int i ;
	char info[256] ;
	
	if ( !call || call[0] == 0 ) return nil ;
	
	activeCall = [ self hash:call ] ;
	if ( manyPerBand ) return activeCall ;  // unlimited calls
	
	qsoLink = activeCall->link ;
	
	for ( i = 0; i < 2000; i++ ) {
		if ( qsoLink == nil ) return activeCall ;	
		
		if ( band( qsoLink->frequency ) == activeBand ) {
			//  worked once already on this band
			if ( !oncePerMode /* not allowed to work more than one band/mode */ || activeMode == qsoLink->mode /*  already worked in this mode */ ) {

				t = &qsoLink->time ;
				sprintf( info, "DUPE: %d-%02d-%02d %02d:%02d (%d) %s Received:%s", t->day, t->month, t->year, t->hour, t->minute, qsoLink->qsoNumber, qsoLink->callsign->callsign, qsoLink->exchange ) ;
				[ manager displayInfo:info ] ;
				
				return nil ; 
			}
		}
		qsoLink = qsoLink->next ;
	}
	return activeCall ;
}

- (Callsign*)getCallsign:(const char*)call
{
	activeCall = [ self hash:call ] ;
	return activeCall ;  // unlimited callsign
}

int modeForString(NSString* str )
{
	if ( [ str isEqualToString:@"RY" ] ) return RTTYMODE ;
	if ( [ str isEqualToString:@"CW" ] ) return CWMODE ;
	if ( [ str isEqualToString:@"PH" ] ) return SSBMODE ;
	if ( [ str isEqualToString:@"PK" ] ) return PSKMODE ;
	return CWMODE ;
}

char* stringForMode(int mode)
{
	switch ( mode ) {
	case RTTYMODE:
		return "RY" ;
	case CWMODE:
		return "CW" ;
	case SSBMODE:
		return "PH" ;
	case PSKMODE:
		return "PK" ;
	}
	return "CW" ;
}

- (void)createMult:(ContestQSO*)p
{
	//  override by instances which handle mults
}

//  create a new QSO in the database
- (void)createQSO:(ContestQSO*)p callsign:(Callsign*)call mode:(int)mode
{
	ContestQSO *q ;
	
	if ( !call ) {
		printf( "cocoaModem: createQSO called with nil callsign\n" ) ;
		return ;
	}
	[ self createMult:p ] ;
	qsoList[numberOfQSO++] = p ;
	p->next = nil ;
	p->callsign = call ;
	p->mode = mode ;
	//  add to linked list
	if ( call->link == nil ) call->link = p ;
	else {
		q = call->link ;
		while ( q ) {
			if ( q->next == nil ) {
				q->next = p ;
				break ;
			}
			q = q->next ;
		}
	}
	[ manager setDirty:YES ] ;
	[ manager newQSOCreated:p ] ;
	//  next QSO number
	activeQSONumber++ ;
}

//  make local DateTime struct from time_t struct
void makeDateTime( DateTime* dt, time_t timet )
{
	struct tm *t ;
	
	t = gmtime( &timet ) ;
	
	dt->second = t->tm_sec ;
	dt->minute = t->tm_min ;
	dt->hour = t->tm_hour ;
	dt->day = t->tm_mday ;
	dt->month = t->tm_mon+1 ;
	dt->year = ( t->tm_year + 1900 ) % 100 ;
}

- (ContestQSO*)createQSOFromCurrentData
{
	ContestQSO *p ;

	p = (ContestQSO*)malloc( sizeof( ContestQSO ) ) ;
	p->frequency = [ self defaultFrequencyForBand ] ;
	makeDateTime( &p->time, time(nil) ) ;
	p->mode = activeMode ;
	p->exchange = nil ;
	p->rst = 0 ;
	p->qsoNumber = activeQSONumber ;
	//  Contest subclasses fill in these...
	p->callsign = nil ;
	p->exchange = nil ;
	return p ;
}

//  overide by subclasses of Contest
- (void)newQSO:(int)n
{
}

//  overide by subclasses of Contest
- (void)clearCurrentQSO
{
}

//  overide by subclasses of Contest
//  get callsign directly from the callsign field
- (NSString*)fetchCallString
{
	return @"" ;
}

- (NSString*)fetchSavedCallString
{
	return @"" ;
}

- (NSString*)fetchReceivedExchange
{
	return @"" ;
}

- (NSString*)fetchSavedReceivedExchange
{
	return @"" ;
}



//  overide by subclasses of Contest
//  get number directly from the number field
- (NSString*)fetchExchangeNumberString
{
	return [ qsoNumberField stringValue ] ;
}

//  get callsign (only from master)
- (NSString*)callsign
{
	if ( master ) return nil ;
	
	//  is a master -- look at active subordinate's field
	if ( !activeSubordinate ) return nil ;
	
	return [ activeSubordinate fetchCallString ] ;
}

- (NSString*)dxExchange
{
	if ( master ) return nil ;
	
	//  is a master -- look at active subordinate's field
	if ( !activeSubordinate ) return nil ;
	
	return [ activeSubordinate fetchReceivedExchange ] ;
}

//  overide by subclasses of Contest
- (void)selectActiveField
{
}

//  get QSO number (only from master)
- (NSString*)qsoNumber
{
	Contest *sub ;

	if ( master ) return @"1" ;
	
	sub = subordinate[0] ;
	if ( !sub ) return @"1" ;

	return [ sub fetchExchangeNumberString ] ;
}

//  only in master
//  return nil if dupe
- (Callsign*)receivedCallsign:(NSString*)call band:(int)band isDupe:(Boolean*)isDupe
{
	Callsign *c ;
	
	if ( master || !call ) return nil ;
	
	activeBand = band ;
	c = [ self getCallsignCheckingDupe:[ call cStringUsingEncoding:kTextEncoding ] ] ;
	if ( c == nil ) {
		*isDupe = YES ;
		if ( [ manager allowDupe ] ) {
			c = [ self getCallsign:[ call cStringUsingEncoding:kTextEncoding ] ] ;
		}
	}
	else *isDupe = NO ;
	dupeState = ( c == nil ) ;

	return c ;
}

//  only in master
//  change the QSO entry to be under a different callsign
- (void)changeQSO:(ContestQSO*)oldqso to:(char*)callsign
{
	Callsign *oldhead, *newhead ;
	ContestQSO *link ;
		
	oldhead = [ self hash:oldqso->callsign->callsign ] ;
	if ( oldhead ) {
		link = oldhead->link ;
		if ( link == oldqso ) {
			//  remove QSO from old Callsign's linked list
			oldhead->link = oldqso->next ;
		}
		else {
			while ( 1 ) {
				if ( link->next == oldqso ) {
					//  remove from one of the old Callsign's ContestQSO*
					link->next = oldqso->next ;
					break ;
				}
				if ( link->next == nil ) return ;
				link = link->next ;
			}
		}
		//  at this point oldqso has been isolated
		newhead = [ self hash:callsign ] ;
		if ( newhead ) {
			//  modify oldqso
			oldqso->callsign = newhead ;
			oldqso->next = nil ;
			if ( newhead->link == nil ) {
				//  newhead has no other QSO
				newhead->link = oldqso ;
				return ;
			}
			link = newhead->link ;
			while ( 1 ) {
				if ( link->next == nil ) {
					link->next = oldqso ;
					return ;
				}
				link = link->next ;
			}
		}		
	}
}

//  only in master
//  send post-logging macro
- (void)logMacro
{
	NSString *str ;
	
	str = [ cabrillo logExtensionString ] ;
	if ( [ str length ] > 0 ) [ client executeMacroString:str ] ;
}

//  only in master
//  returns old state 
- (Boolean)setDupeState:(Boolean)state
{
	Boolean old ;
	
	old = dupeState ;
	dupeState = state ;
	return old ;
}

- (Boolean)isDuped
{
	return dupeState ;
}

//  only in subordinate
- (void)setWatermarkState:(Boolean)state
{
	if ( master ) {
		//  has master
		[ watermark setStringValue:(state)?@"DUPE" : @"" ] ;
		if ( state == NO ) [ manager displayInfo:"" ] ;
	}
}

- (void)setSmallWatermarkState:(Boolean)state
{
	if ( master ) {
		//  has master
		[ watermark setStringValue:(state)?@"*" : @"" ] ;
		if ( state == NO ) [ manager displayInfo:"" ] ;
	}
}

//  override by subclasses of Contest if something esle needs to be done when band is switched
- (void)bandSwitched:(int)band
{
	activeBand = band ;
}

- (void)selectField:(NSTextField*)field
{
	[ field selectText:self ] ;
	
	//[ NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(timedField:) userInfo:field repeats:NO ] ;
}

void stripPhi( char *buffer, char *input )
{
	int n = 0, t ;
	
	while ( *input ) {
		t = *input++ & 0xff ;
		if ( t == phi || t == Phi ) t = '0' ;
		*buffer++ = t ;
		if ( n++ > 60 ) break ;
	}
	*buffer = 0 ;
}

void saveQSONumberToXML( FILE* file, ContestQSO* q )
{
	fprintf( file, "\t\t\t<qnum>%d</qnum>\n", q->qsoNumber ) ;
}

void saveCallToXML( FILE* file, ContestQSO* q )
{
	char buffer[64] ;
	
	stripPhi( buffer, q->callsign->callsign ) ;
	fprintf( file, "\t\t\t<call>%s</call>\n", buffer ) ;
}

void saveDateToXML( FILE* file, ContestQSO* q )
{
	fprintf( file, "\t\t\t<date>%02d/%02d/%02d</date>\n", q->time.day, q->time.month, q->time.year ) ;
}

void saveTimeToXML( FILE* file, ContestQSO* q )
{
	fprintf( file, "\t\t\t<time>%02d:%02d:%02d</time>\n", q->time.hour, q->time.minute, q->time.second ) ;
}

void saveExchangeToXML( FILE* file, ContestQSO* q )
{
	char buffer[64] ;
	stripPhi( buffer, q->exchange ) ;
	fprintf( file, "\t\t\t<exch>%s</exch>\n", buffer ) ;
}

void saveFrequencyToXML( FILE* file, ContestQSO* q )
{
	fprintf( file, "\t\t\t<freq>%.3f</freq>\n", q->frequency ) ;
}

void saveModeToXML( FILE* file, ContestQSO* q )
{
	fprintf( file, "\t\t\t<mode>%s</mode>\n", stringForMode(q->mode) ) ;
}

- (void)saveQSOToXML:(FILE*)file qso:(ContestQSO*)q
{
	fprintf( file, "\t\t<QSO>\n" ) ;
	saveQSONumberToXML( file, q ) ;
	saveCallToXML( file, q ) ;
	saveDateToXML( file, q ) ;
	saveTimeToXML( file, q ) ;
	saveModeToXML( file, q ) ;
	saveExchangeToXML( file, q ) ;
	saveFrequencyToXML( file, q ) ;
	fprintf( file, "\t\t</QSO>\n" ) ;
}

//  dump all QSO up to this point to the journal
- (void)updateQSOToJournal:(FILE*)file
{
	int i ;
	
	[ self saveXMLHead:file isJournal:YES ] ;
	fprintf( file, "\t<contestLog>\n" ) ;
	for ( i = 0; i < numberOfQSO; i++ ) {
		[ self saveQSOToXML:file qso:qsoList[i] ] ;
	}
	fflush( file ) ;
}

- (void)journalQSO:(ContestQSO*)q
{
	if ( cabrilloFile == nil ) {
		cabrilloFile = [ cabrillo openJournalFile:self ] ;
		// this should cause the QSO log up to this point to be dumped out
		return ;
	}
	[ self saveQSOToXML:cabrilloFile qso:q ] ;
	fflush( cabrilloFile ) ;
}

- (void)createNewJournal
{
	cabrilloFile = ( cabrilloFile == nil ) ? [ cabrillo openJournalFile:self ] : [ cabrillo reOpenJournalFile:self ] ;
}

- (void)saveLogToXML:(FILE*)file
{
	int i ;
	
	fprintf( file, "\t<contestLog>\n" ) ;
	for ( i = 0; i < numberOfQSO; i++ ) [ self saveQSOToXML:file qso:qsoList[i] ] ;
	fprintf( file, "\t</contestLog>\n" ) ;
}

- (void)saveXMLHead:(FILE*)file isJournal:(Boolean)isJournal
{
	NSString *exchangeString ;

	fprintf( file, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" ) ;
	if ( isJournal ) fprintf( file, "<!-- |journal| -->\n" ) ;
	fprintf( file, "<Contest>\n" ) ;
	fprintf( file, "\t<contestName>%s</contestName>\n", [ contestName cStringUsingEncoding:kTextEncoding ] ) ;
	exchangeString = [ cabrillo exchangeString ] ;
	fprintf( file, "\t<sent>%s</sent>\n", [ exchangeString cStringUsingEncoding:kTextEncoding ] ) ;
	[ manager saveMacrosToXML:file ] ;
	[ manager saveCabrilloToXML:file ] ;
}

//  save contest
- (void)saveXML:(NSString*)path
{
	FILE *saveFile ;

	saveFile = fopen( [ path cStringUsingEncoding:kTextEncoding ], "w" ) ;

	if ( saveFile ) {
		[ self saveXMLHead:saveFile isJournal:NO ] ;
		[ self saveLogToXML:saveFile ] ;
		fprintf( saveFile, "</Contest>\n" ) ;
		fclose( saveFile ) ;
	}
}

//  overide by subclasses of Contest
- (void)saveContest:(NSString*)path
{
	[ self saveXML:path ] ;
}

- (void)showMultsWindow
{
	[ Messages alertWithMessageText:@"No multiplier panel for this contest." informativeText:@"Sorry.  Multiplier counting is not implemented for this contest." ] ;
}

- (void)switchBandTo:(int)which index:(int)index
{
	Contest *s ;
	int i ;
	
	activeBand = which ;
	if ( !master ) {
		for ( i = 0; i < subordinates; i++ ) {
			s = subordinate[i] ;
			if ( s ) [ s switchBandTo:which index:index ] ;
		}
	}
	else {
		//  visible instances
		[ self bandSwitched:which ] ;
		if ( self != activeSubordinate ) [ bandMenu selectItemAtIndex:index ] ;
	}
}

- (void)bandMenuChanged
{
	if ( self != activeSubordinate && master != nil ) {
		[ master switchBandTo:[ [ bandMenu selectedItem ] tag ] index:[ bandMenu indexOfSelectedItem ]  ] ;
	}
}

//  overide by subclasses of Contest
- (void)logButtonPushed
{
}

//  overide by subclasses of Contest if needed
//	the default simple calls clearCurrentQSO in the subclass
- (void)clearButtonPushed
{
	[ master clearCurrentQSO ] ;
}

//  ------ cabrillo -----------
static void convertToUpper( char *s )
{
	int c ;
	
	while ( *s != 0 ) {
		c = *s & 0xff ;
		if ( c >= 'a' && c <= 'z' ) c += 'A' - 'a' ;
		*s++ = c ;
	}
}

static void convertToBand( char *s )
{
	if ( strncmp( s, "ALL", 3 ) == 0 ) strcpy( s, "ALL" ) ;
}

//  this is called from setUpField of a subordinate
- (void)setCabrilloContestName:(const char*)s
{
	cabrilloContest = s ;
}

- (void)setCabrilloCategorySuffix:(const char*)str ;
{
	cabrilloCategorySuffix = str ;
}

- (void)sortQSOForCabrillo
{
	int i ;
	
	//  just copy over for now
	for ( i = 0; i < MAXQ; i++ ) sortedQSOList[i] = qsoList[i] ;
}

//  override by contests' individual formats
- (void)writeCabrilloQSOs
{
}

//  override by contests which don't use the ARRL categories
- (void)writeCabrilloCategory
{
	char category[64], band[64], kind[66] ;

	//  category
	strcpy( category, [ [ cabrillo category ] cStringUsingEncoding:kTextEncoding ] ) ;
	convertToUpper( category ) ;
	if ( strncmp( category, "SINGLE-OP", 9 ) == 0 ) {
		//  single op
		strcpy( band, [ [ cabrillo band ] cStringUsingEncoding:kTextEncoding ] ) ;
		convertToUpper( band ) ;
		convertToBand( band ) ;
		
		if ( strcmp( category+10, "ASSISTED" ) == 0 ) {
			strcpy( category, "SINGLE-OP-ASSISTED " ) ;
			strcat( category, band ) ;
		}
		else {
			strcpy( kind, &category[10] ) ;
			strcpy( category, "SINGLE-OP " ) ;
			strcat( category, band ) ;
			strcat( category, " " ) ;
			strcat( category, kind ) ;
		}
	}
	if ( cabrilloCategorySuffix == nil ) 
		fprintf( cabrilloFile, "CATEGORY: %s\n", category ) ;
	else 
		fprintf( cabrilloFile, "CATEGORY: %s %s\n", category, cabrilloCategorySuffix ) ;	
}

- (void)writeCabrilloFields
{
	NSString *str, *name ;
	char kind[66] ;
	int i ;

	fprintf( cabrilloFile, "CONTEST: %s\n", cabrilloContest ) ;

	[ self writeCabrilloCategory ] ;

	name = [ cabrillo name ] ;	
	if ( [ name length ] > 0 ) {
		fprintf( cabrilloFile, "NAME: %s\n", [ name cStringUsingEncoding:kTextEncoding ] ) ;
	}
	
	str = [ cabrillo addr1 ] ;	
	if ( [ str length ] > 0 ) fprintf( cabrilloFile, "ADDRESS: %s\n", [ str cStringUsingEncoding:kTextEncoding ] ) ;
	
	if ( [ name length ] <= 0 || [ str length ] <= 0 ) {
		[ Messages alertWithMessageText:@"No post office name/address in Contest panel." informativeText:@"Please enter the name and postal address fields (address where plaques and certificates are mailed to)." ] ;
	}
	
	str = [ cabrillo addr2 ] ;	
	if ( [ str length ] > 0 ) fprintf( cabrilloFile, "ADDRESS: %s\n", [ str cStringUsingEncoding:kTextEncoding ] ) ;
	str = [ cabrillo addr3 ] ;	
	if ( [ str length ] > 0 ) fprintf( cabrilloFile, "ADDRESS: %s\n", [ str cStringUsingEncoding:kTextEncoding ] ) ;
	str = [ cabrillo email ] ;	
	if ( [ str length ] > 0 ) fprintf( cabrilloFile, "ADDRESS: E-mail: %s\n", [ str  cStringUsingEncoding:kTextEncoding ] ) ;

	str = [ cabrillo operators ] ;	
	if ( [ str length ] > 0 ) fprintf( cabrilloFile, "OPERATORS: %s\n", [ str cStringUsingEncoding:kTextEncoding ] ) ;
	str = [ cabrillo club ] ;	
	if ( [ str length ] > 0 ) fprintf( cabrilloFile, "CLUB: %s\n", [ str cStringUsingEncoding:kTextEncoding ] ) ;

	str = [ cabrillo soapbox ] ;
	while ( [ str length ] > 0 ) {
		if ( [ str length ] <= 64 ) {
			strcpy( kind, [ str cStringUsingEncoding:kTextEncoding ] ) ;
			str = @"" ;
		}
		else {
			strcpy( kind, [ [ str substringToIndex:64 ] cStringUsingEncoding:kTextEncoding ] ) ;
			for ( i = 63; i > 0 ; i-- ) {
				if ( kind[i] == ' ' || kind[i] == '\t' ) {
					kind[i] = 0 ;
					break ;
				}
			}
			if ( i != 0 ) {
				str = [ str substringFromIndex:i+1 ] ;
			}
			else str = [ str substringFromIndex:64 ] ;
		}
		fprintf( cabrilloFile, "SOAPBOX: %s\n", kind ) ;
	}
}

- (void)setCabrillo:(Cabrillo*)obj 
{
	cabrillo = obj ;
}

- (void)writeCabrilloToPath:(NSString*)path callsign:(NSString*)callsign
{
	NSString *version ;
	
	userInfo = [ manager userInfoObject ] ;
	
	cabrilloFile = fopen( [ path cStringUsingEncoding:kTextEncoding ], "w" ) ;
	fprintf( cabrilloFile, "START-OF-LOG: 2.0\n" ) ;
	
	//  create a CREATED-BY field with version number
	version = [ [ NSBundle mainBundle ] objectForInfoDictionaryKey:@"CFBundleShortVersionString" ] ;
	if ( version ) {
		fprintf( cabrilloFile, "CREATED-BY: cocoaModem 2.0 v%s (W7AY)\n", [ version cStringUsingEncoding:kTextEncoding ] ) ;
	}
	usedCallString = callsign ;
	fprintf( cabrilloFile, "CALLSIGN: %s\n", [ callsign cStringUsingEncoding:kTextEncoding ] ) ;
	
	[ self writeCabrilloFields ] ;
	
	// sort and output QSO lines
	[ self sortQSOForCabrillo ] ;
	[ self writeCabrilloQSOs ] ;
	
	fprintf( cabrilloFile, "END-OF-LOG:\n" ) ;
	fclose( cabrilloFile ) ;
}

//  AppleScript support
- (void)selectBand:(int)v
{
	int n, i ;
	Contest *s ;
		
	if ( !master ) {
		if ( v == 160 || v == 80 || v == 40 || v == 20 || v == 15 || v == 10 ) {
			for ( i = 0; i < subordinates; i++ ) {
				s = subordinate[i] ;
				if ( s ) [ s selectBand:v ] ;
			}
		}
	}
	else {
		n = [ bandMenu numberOfItems ] ;
		for ( i = 0; i < n; i++ ) {
			if ( [ [ bandMenu itemAtIndex:i ] tag ] == v ) {
				[ bandMenu selectItemAtIndex:i ] ;
				break ;
			}
		}
	}
	[ self bandSwitched:v ] ;
}

- (int)selectedBand
{
	return activeBand ;
}

@end
