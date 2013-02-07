//
//  ContestManager.m
//  cocoaModem
//
//  Created by Kok Chen on 10/17/04.
	#include "Copyright.h"
//

#define	disableContest	1

#import "ContestManager.h"
#import "Application.h"
#import "Cabrillo.h"
#import "Messages.h"
#import "ContestInterface.h"  /* modem */
#import "ContestLog.h"
#import "ContestMacroSheet.h"
#import "ContestQSOObj.h"
#import "modemTypes.h"
#import "StdManager.h"
#import "Plist.h"
#import "QSO.h"
#import "Preferences.h"
#import "TextEncoding.h"
#import "UserInfo.h"

//  contests
#import "Contest.h"
#import "Generic.h"
#import "BARTG.h"
#import "BARTGSprint.h"
#import "RTTYRoundup.h"
#import "RST Exchange.h"
#import "RST Number.h"
#import "TARA.h"
#import "WPX.h"
#import "XE RTTY.h"
#import "SP RTTY.h"


@implementation ContestManager

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

//  make sure to init macros only after the application is awake
- (void)initContestMacros
{
	int i ;
	NSString *sheetName[6] = { @"Contest macros (CQ)", @"Contest option macros (CQ)", @"Contest option-shift macros (CQ)", @"Contest macros (S&P)", @"Contest option macros (S&P)", @"Contest option-shift macros (S&P)" } ;
	ContestMacroSheet *sheet ;
	
	userInfo = [ application userInfoObject ] ;
	qsoInfo = [ stdManager qsoObject ] ;
	
	for ( i = 0; i < 6; i++ ) {
		//  3 for CQ mode, 3 for SP code
		contestMacroSheet[i] = sheet = [ [ ContestMacroSheet alloc ] initSheet ] ;
		[ sheet setName:sheetName[i] ] ;
		[ sheet setUserInfo:userInfo qso:qsoInfo modem:currentModem canImport:YES ] ;
		[ sheet delegateTextChangesTo:self ] ;
	}
}

- (void)awakeFromNib
{
	[ self setInterface:ignoreNewlineMenuItem to:@selector(ignoreNewlineChanged) ] ;
	[ ignoreNewlineMenuItem setState:NSOffState ] ;
	ignoreNewline = NO ;
}

- (void)ignoreNewlineChanged
{
	int i ;
	
	ignoreNewline = !ignoreNewline ;
	[ ignoreNewlineMenuItem setState:( ignoreNewline ) ? NSOnState : NSOffState ] ;
	for ( i = 0; i < clients; i++ ) [ client[i] setIgnoreNewline:ignoreNewline ] ;
}

//  MyCall notification message from one of the callsign spots
- (void)checkCallsign:(NSNotification*)notify
{
	NSString *str ;
	
	str = [ cabrilloInfo callUsed ] ;
	if ( str == nil || [ str length ] <= 0 ) str = [ userInfo call ] ;
	
	str = ( [ str length ] <= 0 ) ? @"" : [ str uppercaseString ] ;
	if ( contestCallsign ) [ contestCallsign release ] ;
	contestCallsign = [ str retain ] ;
}

//  MyName notification message from one of the callsign spots
- (void)checkName:(NSNotification*)notify
{
	NSString *str ;
	
	str = [ cabrilloInfo nameUsed ] ;
	if ( str == nil || [ str length ] <= 0 ) str = [ userInfo name ] ;
	
	str = ( [ str length ] <= 0 ) ? @"" : [ NSString stringWithString:str ] ;
	if ( myName ) [ myName release ] ;
	myName = [ str retain ] ;
}

//  SetDirty notification
- (void)setDirtyBit:(NSNotification*)notify
{
	[ self setDirty:YES ] ;
}

- (void)awakeFromApplication
{
	NSNotificationCenter *center ;
	
	contestName = nil ;
	contestCallsign = @"" ;
	myName = @"" ;
	prototypeName = @"Generic" ;
	saveFileName = nil ;
	master = nil ;
	selectedMenuItem = nil ;
	currentModem = nil ;
	dirty = sessionStarted = NO ;
	allowDupe = NO ;
	preference = nil ;
	
	//  create ContestLog
	contestLog = [ [ ContestLog alloc ] initWithManager:self ] ;
				
	cabrilloInfo = [ [ Cabrillo alloc ] initWithManager:self ] ;
	[ contestMenu setAutoenablesItems:NO ] ;
	[ showLogMenuItem setEnabled:NO ] ;
	[ showMultMenuItem setEnabled:NO ] ;
	[ cabrilloMenuItem setEnabled:NO ] ;
	[ ignoreNewlineMenuItem setEnabled:NO ] ;
	[ saveMenuItem setEnabled:NO ] ;
	[ saveAsMenuItem setEnabled:NO ] ;
	[ clearQSOMenuItem setEnabled:NO ] ;
	center = [ NSNotificationCenter defaultCenter ] ;
	[ center addObserver:self selector:@selector(checkCallsign:) name:@"MyCall" object:nil ] ;
	[ center addObserver:self selector:@selector(checkName:) name:@"MyName" object:nil ] ;
	[ center addObserver:self selector:@selector(setDirtyBit:) name:@"SetDirty" object:nil ] ;
	
	if ( contestLog ) [ contestLog awakeFromManager ] ;
}

- (void)displayInfo:(char*)info
{
	[ contestLog displayInfo:info ] ;
}

- (void)setAllowDupe:(Boolean)state
{
	allowDupe = state ;
}

- (Boolean)allowDupe
{
	return allowDupe ;
}

- (void)newQSOCreated:(ContestQSO*)qso
{
	[ contestLog newQSOCreated:qso ] ;
}

- (void)changeQSO:(ContestQSO*)oldqso to:(char*)callsign
{
	[ master changeQSO:oldqso to:callsign ] ;
}

/* local */
- (Contest*)allocContest:(NSString*)name
{
	if ( [ name isEqualToString:@"Generic" ] ) {
		prototypeName = @"Generic" ;
		return [ Generic alloc ] ;
	}
	if ( [ name isEqualToString:@"RST - Exchange" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ RSTExchange alloc ] ;
	}
	if ( [ name isEqualToString:@"RST - QSO Number" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ RST_Number alloc ] ;
	}
	if ( [ name isEqualToString:@"QSO Number (No RST)" ] ) {
		prototypeName = @"NumberOnly" ;
		return [ NumberOnly alloc ] ;
	}
	
	//  contest instance
	if ( [ name isEqualToString:@"BARTG Sprint" ] ) {
		prototypeName = @"NumberOnly" ;
		return [ BARTGSprint alloc ] ;
	}
	if ( [ name isEqualToString:@"CQ WPX RTTY" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ WPX alloc ] ;
	}
	if ( [ name isEqualToString:@"RTTY Roundup" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ RTTYRoundup alloc ] ;
	}
	if ( [ name isEqualToString:@"TARA" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ TARA alloc ] ;
	}
	if ( [ name isEqualToString:@"XE RTTY" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ XERTTY alloc ] ;
	}
	if ( [ name isEqualToString:@"BARTG HF" ] ) {
		prototypeName = @"BARTG" ;
		return [ BARTG alloc ] ;
	}
	if ( [ name isEqualToString:@"SP RTTY" ] ) {
		prototypeName = @"RSTExchange" ;
		return [ SPRTTY alloc ] ;
	}
	return nil ;
}

//  create a master contest instance
- (Contest*)selectContest:(NSString*)newContestName parser:(NSXMLParser*)parser
{
	Contest *test ;
	
	clients = 0 ;
	if ( contestName ) [ contestName autorelease ] ;		//  v0.96a
	contestName = [ newContestName retain ] ;
	if ( saveFileName ) [ saveFileName autorelease ] ;
	saveFileName = nil ;
	
	[ cabrilloMenuItem setEnabled:YES ] ;
	[ saveMenuItem setEnabled:YES ] ;
	[ saveAsMenuItem setEnabled:YES ] ;
	[ showLogMenuItem setEnabled:YES ] ;
	[ showMultMenuItem setEnabled:YES ] ;
	[ clearQSOMenuItem setEnabled:YES ] ;
	[ ignoreNewlineMenuItem setEnabled:YES ] ;
	
	//  create a master contest
	if ( master ) [ master autorelease ] ;
	master = [ self allocContest:contestName ] ;
	if ( master ) {
		test = [ master initContestName:contestName prototype:prototypeName parser:parser manager:self ] ;
		if ( test ) {
			[ test retain ] ;
			[ test setCabrillo:cabrilloInfo ] ;
		}
	}
	else {
		printf( "cannot alloc contest!\n" ) ;
		test = nil ;
	}
	return test ;
}

//  return the contest master
- (Contest*)contestObject
{
	return master ;
}

- (void)addContestClient:(ContestInterface*)modem
{
	Contest *clientContest ;
	
	if ( master ) {
		//  has master
		client[clients++] = modem ;
		//  clientContest provides the user interface
		//	the actual database is in the master contest object
		clientContest = [ [ self allocContest:contestName ] retain ] ;
		//  let the ContestInterface (mode) create a local Contest instance
		//  (this allows the modem to hook up any user interface)
		[ modem initContest:clientContest master:master manager:self ] ;
		[ master addSubordinate:clientContest ] ;
	}
}

- (void)startUp
{
	[ master newQSO:0 ] ;	// this will propagate to the subordinates
}

//  select the active contest interface, also set up fonts of interface at this point
- (void)setActiveContestInterface:(ContestInterface*)interface 
{
	int i ;

	currentModem = interface ;
	[ master selectFirstResponder ] ;
	//  3 macro sheets for CQ mode and 3 for S&P mode
	for ( i = 0; i < 6; i++ ) [ contestMacroSheet[i] setModem:currentModem ] ;
	//  set up fonts
	[ cabrilloInfo setFonts ] ;
}

- (ContestInterface*)selectedContestInterface
{
	return currentModem ;
}

//  fetch macro
- (NSString*)macroFor:(int)c
{
	NSString *str ;
	
	switch ( c ) {
	case 'c':
		//  callsign
		str = contestCallsign ;
		break ;
	case 'h':
		// name
		str = myName ;
		break ;
	default:
		str = [ userInfo macroFor:c ] ;
		break ;
	}
	return str ;
}

- (void)showCabrilloInfoSheet:(NSWindow*)window
{
	if ( cabrilloInfo ) [ cabrilloInfo showSheet:window ] ;
}

- (Cabrillo*)cabrilloObject
{
	return cabrilloInfo ;
}

- (UserInfo*)userInfoObject
{
	return userInfo ;
}

- (void)showContestMacroSheet:(int)n
{
	[ contestMacroSheet[n] showMacroSheet:[ application mainWindow ] ] ;
}

- (void)contestSwitchedToCQ:(Boolean)cqmode
{
	[ stdManager contestSwitchedToCQ:cqmode ] ;
}

//  call from application when Command-1, etc seen
- (Boolean)executeContestMacroFromShortcut:(int)n sheet:(int)sheet modem:(ContestInterface*)modem
{
	sheet = ( sheet%3 ) + [ modem contestModeIndex ] ;  //  get sheet for CQ/S&P mode
	[ modem newMacroForContestBar:n sheet:sheet ] ;
	return [ self executeContestMacro:n sheet:sheet modem:modem ] ;
}

/* local */
- (void)updateQSOInfo
{
	NSString *number, *qth, *call ;
	Boolean isDX ;
	const char *qths ;
	int num ;

	//  first set up the needed QSO fields, in case they are needed
	if ( qsoInfo ) {
		call = [ master callsign ]  ;
		[ qsoInfo setCallsign:call ] ;
		[ qsoInfo setDXExchange:[ master dxExchange ] ] ;
		
		number = [ master qsoNumber ] ;
		if ( number ) {
			sscanf( [ number cStringUsingEncoding:kTextEncoding ], "%d", &num ) ;
			number = [ NSString stringWithFormat:@"%03d", num ] ;
			[ qsoInfo setNumber:number ] ;
		}
		// set exchange in QSO depending on whether we are DX or not
		if ( userInfo && call && number ) {
			qth = [ userInfo qth ] ;
			if ( !qth || [ qth length ] == 0 ) isDX = YES ;
			else {
				qths = [ qth cStringUsingEncoding:kTextEncoding ] ;
				isDX = ( qths[0] == 'd' || qths[0] == 'D' ) && ( qths[1] == 'x' || qths[1] == 'X' ) ;
			}
			[ qsoInfo setExchangeString:( isDX )? number : qth ] ;
		}
	}
}

- (Boolean)executeContestMacro:(int)n sheet:(int)sheet modem:(ContestInterface*)modem
{
	NSString *title ;
	MacroSheet *macroSheet ;
	
	if ( sheet >= 6 ) return NO ; // some internal error
	
	[ self updateQSOInfo ] ;
	
	macroSheet = contestMacroSheet[sheet] ;
	title = [ macroSheet title:n ] ;
	
	if ( title == nil || [ title length ] == 0 ) {
		//  no macro defined for this button
		[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
		return NO ;
	}
	[ modem executeMacro:n macroSheet:macroSheet fromContest:YES ] ;
	return YES ;
}

- (NSMatrix*)macroTitles:(int)sheet
{
	return [ contestMacroSheet[sheet] titles ] ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	preference = pref ;
	[ pref setString:@"" forKey:kRecentContest ] ;
	
	if ( cabrilloInfo ) [ cabrilloInfo setupDefaultPreferences:pref ] ;
	if ( contestLog ) [ contestLog setupDefaultPreferences:pref ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *recent ;
	
	if ( contestLog ) [ contestLog updateFromPlist:pref ] ;
	if ( cabrilloInfo ) [ cabrilloInfo updateFromPlist:pref ] ;
	
	recent = [ pref stringValueForKey:kRecentContest ] ;
	if ( recent && [ recent length ] > 0 ) [ recentContestMenuItem setTitle:recent ] ;
	
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	if ( contestLog ) [ contestLog retrieveForPlist:pref ] ;
	if ( cabrilloInfo ) [ cabrilloInfo retrieveForPlist:pref ] ;
}

- (void)setDirty:(Boolean)state
{
	dirty = state ;
}

//  log has been edited
- (void)journalChanged
{
	[ self setDirty:YES ] ;
	[ master createNewJournal ] ;
}

- (Boolean)okToQuit
{
	if ( !contestName ) return YES ;
	return !dirty ;
}

// expand macro in UserInfo and QSO info
- (NSString*)expandMacroInUserAndQSOInfo:(const char*)macro
{
	int c ;
	const char *original ;
	NSString *macroBuf, *macroFor ;
	
	macroBuf = @"" ;

	original = macro ;
	while ( *macro ) {
		c = *macro++ ;
		switch ( c ) {
		case '%':
			c = *macro++ ;
			switch ( c ) {
			case 'b':
			case 'c':
			case 'h':
			case 's':
				if ( userInfo ) {
					macroFor = [ userInfo macroFor:c ] ;
					if ( macroFor ) macroBuf = [ macroBuf stringByAppendingString:macroFor ] ;
				}
				break ;
			case 'x':
				if ( qsoInfo ) {
					macroFor = [ qsoInfo macroFor:'x' ] ;
					if ( macroFor ) macroBuf = [ macroBuf stringByAppendingString:macroFor ] ;
				}
				break ;
			case 'C':
			case 'H':
			case 'n':
				if ( qsoInfo ) {
					macroFor = [ qsoInfo macroFor:c ] ;
					if ( macroFor ) macroBuf = [ macroBuf stringByAppendingString:macroFor ] ;
				}
				break ;
			}
			break ;
		default:
			macroBuf = [ macroBuf stringByAppendingFormat:@"%c", c ] ;
		}
	}
	return macroBuf ;
}

- (void)saveMacrosToXML:(FILE*)file
{
	int i ;
	
	fprintf( file, "\t<macros>\n" ) ;
	for ( i = 0; i < 6; i++ ) {
		fprintf( file, "\t\t<caption>%s</caption>\n", [ [ contestMacroSheet[i] captions ] cStringUsingEncoding:kTextEncoding ] ) ;
		fprintf( file, "\t\t<body>%s</body>\n", [ [ contestMacroSheet[i] messages ] cStringUsingEncoding:kTextEncoding ] ) ;
	}
	fprintf( file, "\t</macros>\n" ) ;
}

- (void)saveCabrilloToXML:(FILE*)file
{
	fprintf( file, "\t<cabrillo>\n" ) ;
	[ cabrilloInfo saveFieldsToFile:file ] ;
	fprintf( file, "\t</cabrillo>\n" ) ;
}


/* local */
//  open/continue a contest from a specification file given 
- (void)contestWithPath:(NSString*)path
{
	NSURL *url ;
	FILE *f ;
	NSXMLParser *xmlParser ;
	
	//  try opening to check for existance of file
	f = fopen( [ path cStringUsingEncoding:kTextEncoding ], "r" ) ;	
    if ( f == nil ) return ;
	fclose( f ) ;

	contestName = nil ;
	isContestName = isMacros = isCabrillo = NO ;
	isCName = isAddr1 = isAddr2 = isAddr3 = isEmail = isCategory = isBand = isExchange = NO ;
	isCaption = isMessage = NO ;
	xmlError = NO ;
	url = [ NSURL fileURLWithPath:path ] ;

	//  first pass to get contest name
	xmlParser = [ [ NSXMLParser alloc ] initWithContentsOfURL:url ] ;
	[ xmlParser setShouldResolveExternalEntities:YES ] ;
	[ xmlParser setDelegate:self ] ;
	if ( ![ xmlParser parse ] ) {
		[ Messages alertWithMessageText:@"Problem with contest file." informativeText:@"A parsing error occured with the contest file." ] ;
		if ( contestName ) [ contestName release ] ;
		return ;
	}
	if ( xmlError ) {
		[ Messages alertWithMessageText:@"Problem with contest file." informativeText:@"Duplicate contest name in the contest file?" ] ;
		return ;
	}
	if ( !contestName ) {
		[ Messages alertWithMessageText:@"Problem with contest file." informativeText:@"No contest name found in file?" ] ;
		return ;
	}
	[ xmlParser release ] ;
	
	xmlParser = [ [ NSXMLParser alloc ] initWithContentsOfURL:[ NSURL fileURLWithPath:path ] ] ;
	[ xmlParser setShouldResolveExternalEntities:YES ] ;
	// create contest and parse
	[ contestLog setBulkLog:YES ] ;
	[ stdManager selectContest:contestName parser:xmlParser ] ;
	[ contestLog setBulkLog:NO ] ;
	[ xmlParser release ] ;

	//  clean dirty bit after the log has been updated by the parser and mark session
	dirty = NO ;
	sessionStarted = YES ;
}

- (IBAction)showLog:(id)sender
{
	[ contestLog showWindow ] ;
}

- (IBAction)showMults:(id)sender
{
	[ master showMultsWindow ] ;
}

- (IBAction)clearQSO:(id)sender
{
	[ master clearCurrentQSO ] ;
}

//  sender is a NSMenuItem
//  resolve title and look inside application bundle's Contents/Resources/ for it, with xml extension
- (IBAction)newContest:(id)sender
{
	NSBundle *bundle ;
	NSString *path, *errString ;
	NSMenuItem *oldItem ;
	NSString *name ;
	FILE *test ;
	
	if ( sessionStarted && dirty ) {
		[ Messages alertWithMessageText:@"A contest session is already active!" informativeText:@"You cannot start a new contest log in the middle of an existing contest session.\nSave the current session, quit and relaunch cocoaModem to start a fresh contest session." ] ;
		return ;
	}
	oldItem = selectedMenuItem ;
	if ( oldItem ) [ oldItem setState:NSOffState ] ;
	selectedMenuItem = sender ;
	[ selectedMenuItem setState:NSOnState ] ;
	
	name = [ selectedMenuItem title ] ;
	bundle = [ NSBundle mainBundle ];
	path = [ bundle bundlePath ] ;
	path = [ path stringByAppendingString:@"/Contents/Resources/" ] ;
	path = [ path stringByAppendingString:name ] ;
	path = [ path stringByAppendingString:@".xml" ] ;
	//  check if path is in app resources
	test = fopen( [ path cStringUsingEncoding:kTextEncoding ], "r" ) ;
	if ( test ) {
		fclose( test ) ;
		[ self contestWithPath:path ] ;
	}
	else {
		//  try it without the macros, etc
		errString = @"Cannot find file " ;
		errString = [ errString stringByAppendingString:path ] ;
		errString = [ errString stringByAppendingString:@" .   Using default without loading macros." ] ;
		[ Messages alertWithMessageText:@"Contest template file not found." informativeText:errString ] ;		
		[ stdManager selectContest:name parser:nil ] ;
	}
}

//  open a recent .xml contest file
- (IBAction)recentContest:(id)sender
{
	NSString *path ;
	
	path = [ recentContestMenuItem title ] ;
	if ( [ path isEqualToString:@"None" ] ) return ;

	if ( sessionStarted && dirty ) {
		[ Messages alertWithMessageText:@"A contest session is already active!" informativeText:@"You cannot resume a previous log in the middle of a contest session." ] ;
		return ;
	}
	[ self contestWithPath:path ] ;
}

//  restore either from a contest archive (.xml) or a journal file (.jnl)
- (IBAction)continueContest:(id)sender
{
	NSOpenPanel *open ;
	NSString *path ;
	FILE *tempFile, *inputFile ;
	char line[133], *s ;
	int result ;
	Boolean isJournal ;
	
	if ( dirty ) {
		[ Messages alertWithMessageText:@"Another contest session active!" informativeText:@"You can only restore a contest when a contest session is not already running." ] ;
		return ;
	}
	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
	result = [ open runModalForDirectory:nil file:nil types:[ NSArray arrayWithObjects:@"xml", @"jnl", nil ] ] ;
	if ( result == NSOKButton ) {
		path = [ [ open filenames ] objectAtIndex:0 ] ;
		inputFile = fopen( [ path cStringUsingEncoding:kTextEncoding ], "r" ) ;
		tempFile = fopen( kTempFile, "w" ) ;
		// create a file in .tmp which has the proper header and trailer
		if ( inputFile && tempFile ) {
			isJournal = NO ;
			while ( 1 ) {
				s = fgets( line, 132, inputFile ) ;
				if ( !s ) break ;
				//  check for journal
				if ( s[0] == '<' && strncmp( s, "<!-- |journal|", 14 ) == 0 ) isJournal = YES ; 
				fputs( line, tempFile ) ;
			}
			if ( isJournal ) {
				//  if journal, append suffix
				fprintf( tempFile, "\t</contestLog>\n" ) ;
				fprintf( tempFile, "</Contest>\n" ) ;
			}
			else {
				//  if not journal, make it "recent contest"
				[ preference setString:path forKey:kRecentContest ] ;
				[ recentContestMenuItem setTitle:path ] ;
			}
			fclose( tempFile ) ;
			fclose( inputFile ) ;
		}
		[ self contestWithPath:[ NSString stringWithCString:kTempFile encoding:kTextEncoding ] ] ;
		dirty = YES ;
	}
}

//  called from saveContest and log macro %[sl]
- (void)actualSaveContest
{
	if ( saveFileName == nil ) {
		[ self saveContestAs:self ] ;
		return ;
	}
	[ master saveContest:saveFileName ] ;
	dirty = NO ;
}

- (IBAction)saveContest:(id)sender
{
	[ self actualSaveContest ] ;
}

- (IBAction)saveContestAs:(id)sender
{
	NSString *name, *fullname ;
	NSSavePanel *save ;
	int result ;
	time_t timet ;
	struct tm *t ;
	int year ;
	
	time( &timet ) ;
	t = gmtime( &timet ) ;
	year = ( t->tm_year + 1900 ) ;
		
	if ( contestName == nil ) name = @"Contest" ; else name = contestName ;
	fullname = [ name stringByAppendingFormat:@" %d.xml", year ] ; 
	
	save = [ NSSavePanel savePanel ] ;
	result = [ save runModalForDirectory:nil file:fullname ] ;
	if ( result == NSOKButton ) {
		if ( saveFileName ) [ saveFileName release ] ;
		saveFileName = [ [ save filename ] retain ] ;
		[ master saveContest:saveFileName ] ;
		dirty = NO ;
	}
}

- (IBAction)createCabrillo:(id)sender
{
	NSSavePanel *save ;
	NSString *path, *callsign, *filename ;
	int result ;
	
	if ( master ) {
		//  create a file named callsign.log
		[ self checkCallsign:nil ] ;
		callsign = contestCallsign ;
		if ( [ callsign length ] <= 0 ) callsign = @"XXX" ;
		filename = [ callsign stringByAppendingString:@".log" ] ;
		
		save = [ NSSavePanel savePanel ] ;
		// types: should be an NSArray of file extensions strings instead of nil if only those extensions are to be selectable
		result = [ save runModalForDirectory:nil file:filename ] ;
		if ( result == NSOKButton ) {
			path = [ save filename ] ;
			[ master writeCabrilloToPath:path callsign:callsign ] ;
		}
	}
}

//  contest macro text field changed
- (BOOL)control:(NSControl*)control textShouldBeginEditing:(NSText*)fieldEditor
{
	[ self journalChanged ] ;
	return YES ;
}

//  --------- NSXMLParser delegates ---------------
//  only need to recognize contestName
- (void)parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
	isContestName = [ elementName isEqualToString:@"contestName" ] ;
	isMacros = [ elementName isEqualToString:@"macros" ] ;
	isCabrillo = [ elementName isEqualToString:@"cabrillo" ] ;
	isCaption = [ elementName isEqualToString:@"caption" ] ;
	isMessage = [ elementName isEqualToString:@"body" ] ;
	isExchange = [ elementName isEqualToString:@"sent" ] ;
	isCName = [ elementName isEqualToString:@"cname" ] ;
	isAddr1 = [ elementName isEqualToString:@"addr1" ] ;
	isAddr2 = [ elementName isEqualToString:@"addr2" ] ;
	isAddr3 = [ elementName isEqualToString:@"addr3" ] ;
	isEmail = [ elementName isEqualToString:@"email" ] ;
	isCallUsed = [ elementName isEqualToString:@"callused" ] ;
	isNameUsed = [ elementName isEqualToString:@"nameused" ] ;
	isClub = [ elementName isEqualToString:@"club" ] ;
	isOperator = [ elementName isEqualToString:@"operator" ] ;
	isSoapbox = [ elementName isEqualToString:@"soapbox" ] ;
	isCategory = [ elementName isEqualToString:@"category" ] ;
	isBand = [ elementName isEqualToString:@"band" ] ;
}

- (void)parser:(NSXMLParser*)parser foundCharacters:(NSString*)string 
{
	if ( isContestName ) {
		if ( contestName ) {
			xmlError = YES ; // duplicate contest name?
			[ contestName release ] ;
			contestName = nil ;
		}
		else {
			contestName = [ string retain ] ;
		}
	}
	else if ( isMacros ) {
		isCabrillo = isMessage = NO ;
		messageSheet = captionSheet = 0 ;
	}
	else if ( isCabrillo ) {
		isCName = isAddr1 = isAddr2 = isAddr3 = isEmail = isCategory = isBand = isExchange = NO ;
		isCallUsed = isNameUsed = isClub = isOperator = isSoapbox = NO ;
	}
	else if ( isExchange ) [ cabrilloInfo setExchange:string ] ;
	else if ( isCategory ) [ cabrilloInfo setCategory:string ] ;
	else if ( isBand ) [ cabrilloInfo setBand:string ] ;
	else if ( isCName ) [ cabrilloInfo setCName:string ] ;
	else if ( isAddr1 ) [ cabrilloInfo setCAddr1:string ] ;
	else if ( isAddr2 ) [ cabrilloInfo setCAddr2:string ] ;
	else if ( isAddr3 ) [ cabrilloInfo setCAddr3:string ] ;
	else if ( isEmail ) [ cabrilloInfo setEmail:string ] ;
	else if ( isCallUsed ) [ cabrilloInfo setCallUsed:string ] ;
	else if ( isNameUsed ) [ cabrilloInfo setNameUsed:string ] ;
	else if ( isClub ) [ cabrilloInfo setClub:string ] ;
	else if ( isOperator ) [ cabrilloInfo setOperators:string ] ;
	else if ( isSoapbox ) [ cabrilloInfo setSoapbox:string ] ;
	
	else if ( isCaption ) {
		if ( captionSheet >= 0 && captionSheet < 6 ) [ contestMacroSheet[captionSheet] setCaptions:string ] ;
		captionSheet++ ;
	}
	else if ( isMessage ) {
		if ( messageSheet >= 0 && messageSheet < 6 ) [ contestMacroSheet[messageSheet] setMessages:string ] ;
		messageSheet++ ;
	}
}

- (void)parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString *)qName
{
	if ( [ elementName isEqualToString:@"contestName" ] ) isContestName = NO ;
	else if ( [ elementName isEqualToString:@"macros" ]  ) isMacros = NO ;
	else if ( [ elementName isEqualToString:@"cabrillo" ]  ) isCabrillo = NO ;
	else if ( [ elementName isEqualToString:@"caption" ]  ) isCaption = NO ;
	else if ( [ elementName isEqualToString:@"body" ]  ) isMessage = NO ;
	else if ( [ elementName isEqualToString:@"sent" ] ) isExchange = NO ;
	else if ( [ elementName isEqualToString:@"cname" ] ) isCName = NO ;
	else if ( [ elementName isEqualToString:@"addr1" ] ) isAddr1 = NO ;
	else if ( [ elementName isEqualToString:@"addr2" ] ) isAddr2 = NO ;
	else if ( [ elementName isEqualToString:@"addr3" ] ) isAddr3 = NO ;
	else if ( [ elementName isEqualToString:@"email" ] ) isEmail = NO ;
	else if ( [ elementName isEqualToString:@"callused" ] ) isCallUsed = NO ;
	else if ( [ elementName isEqualToString:@"nameused" ] ) isNameUsed = NO ;
	else if ( [ elementName isEqualToString:@"club" ] ) isClub = NO ;
	else if ( [ elementName isEqualToString:@"operator" ] ) isOperator = NO ;
	else if ( [ elementName isEqualToString:@"soapbox" ] ) isSoapbox = NO ;
	else if ( [ elementName isEqualToString:@"category" ] ) isCategory = NO ;
	else if ( [ elementName isEqualToString:@"band" ] ) isBand = NO ;
}


@end
