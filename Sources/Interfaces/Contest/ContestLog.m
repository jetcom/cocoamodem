//
//  ContestLog.m
//  cocoaModem
//
//  Created by Kok Chen on 12/23/04.
	#include "Copyright.h"
//

#import "ContestLog.h"
#import "ContestManager.h"
#import "ContestQSOObj.h"
#import "Plist.h"
#import "Preferences.h"
#import "TextEncoding.h"
#import "UpperFormatter.h"


@implementation ContestLog

- (id)initWithManager:(ContestManager*)control
{
	Boolean success ;
	
	manager = control ;
	self = [ super init ] ;
	if ( self ) {
		//  this should call awakeFromNib
		success = [ NSBundle loadNibNamed:@"ContestLog" owner:self ] ;
		[ callsignSearchField setFormatter:[ [ UpperFormatter alloc ] init ] ] ;
		[ callsignSearchField setDelegate:self ] ;
	}
	return self ;
}

- (void)awakeFromManager
{
	int i, n ;
	NSArray *columns ;
	NSTableColumn *column ;
	NSString *title ;
	
	//  initialize QSO list for log (NSTableView)
	qsoArray = [ [ NSMutableArray alloc ] initWithCapacity:2000 ] ; //  initially 2000 items
	for ( i = 0; i < 8; i++ ) ascend[i] = YES ;
	previousLogColumn = nil ;
	currentSortCriterion = searchIndex = 0 ;
	bulkLogEntry = NO ;
	
	[ tableView setDataSource:self ] ;
	[ tableView setDelegate:self ] ;		//  delegate sorting
	
	n = [ (NSTableView*)tableView numberOfColumns ] ;
	columns = [ tableView tableColumns ] ;
	qsoNumber = callsign = timec = band = rst = received = mode = date = nil ;

	for ( i = 0; i < 16; i++ ) columnOrder[i] = i ;
	
	for ( i = 0; i < n; i++ ) {
		title = @"" ;
		column = columns[i] ;
		switch ( i ) {
		case 0:
			title = @"QSO #" ;
			qsoNumber = column ;
			break ;
		case 1:
			title = @"Call sign" ;
			callsign = column ;
			break ;
		case 2:
			title = @"Time" ;
			timec = column ;
			break ;
		case 3:
			title = @"Band" ;
			band = column ;
			break ;
		case 4:
			title = @"RST" ;
			rst = column ;
			break ;
		case 5:
			title = @"Received" ;
			received = column ;
			break ;
		case 6:
			title = @"Mode" ;
			mode = column ;
			break ;
		case 7:
			title = @"Date" ;
			date = column ;
			break ;
		}
		[ column setIdentifier:@(i) ] ;
		[ column setEditable:NO ] ;
		[ [ column headerCell ] setStringValue:title ] ;
	}
}

- (void)displayInfo:(char*)info
{
	[ infoField setStringValue:[ NSString stringWithCString:info encoding:kTextEncoding ] ] ;
}

- (void)allowEdit:(Boolean)allow
{
	[ callsign setEditable:allow ] ;
	[ band setEditable:allow ] ;
	[ rst setEditable:allow ] ;
	[ received setEditable:allow ] ;
	[ mode setEditable:allow ] ;
}

- (void)showWindow
{
	[ [ tableView window ] orderFront:self ] ;
}

- (NSComparisonResult)compare:(id)other 
{
	return 0 ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i, j, n ;
	char string[1024] ;
	int w[16] ;
	NSArray *columns ;
	NSTableColumn *column ;
	
	[ pref setString:[ [ tableView window ] stringWithSavedFrame ] forKey:kContestLogPosition ] ;
	
	for ( i = 0; i < 16; i++ ) {
		string[i] = ( i < 10 ) ? ( '0'+i ) : ( 'a'-10+i ) ;
	}
	string[16] = 0 ;
	[ pref setString:[ NSString stringWithCString:string encoding:kTextEncoding ] forKey:kContestLogOrder ] ;
	
	n = [ (NSTableView*)tableView numberOfColumns ] ;
	columns = [ tableView tableColumns ] ;
	
	for ( i = 0; i < 16; i++ ) w[i] = 0 ;
	for ( i = 0; i < n; i++ ) {
		column = columns[i] ;
		j = [ [ column identifier ] intValue ] ;
		w[j] = [ column width ]*10 ;
	}
	sprintf( string, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12], w[13], w[14], w[15] ) ;
	[ pref setString:[ NSString stringWithCString:string encoding:kTextEncoding ] forKey:kContestLogSize ] ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	int i, j, n, p, c, identifier, w[16] ;
	const char *columnString, *widthString ;
	NSArray *columns ;
	NSTableColumn *column ;
	
	//  window position
	[ [ tableView window ] setFrameFromString:[ pref stringValueForKey:kContestLogPosition ] ] ;
	columnString = [ [ pref stringValueForKey:kContestLogOrder ] cStringUsingEncoding:kTextEncoding ] ;
	
	n = [ (NSTableView*)tableView numberOfColumns ] ;
	columns = [ tableView tableColumns ] ;
	
	for ( i = 0; i < n; i++ ) {
		//  find who should map to column i (from columnString)
		c = columnString[i] ;
		p = ( c >= '0' && c <= '9' ) ? ( c-'0' ) : ( c-'a'+10 ) ;
		//  find the column whose identifier is the same as p
		for ( j = 0; j < n; j++ ) {
			column = columns[j] ;
			identifier = [ [ column identifier ] intValue ] ;
			if ( identifier == p && i != j ) {
				[ tableView moveColumn:j toColumn:i ] ;
				break ;
			}
		}
	}
	widthString = [ [ pref stringValueForKey:kContestLogSize ] cStringUsingEncoding:kTextEncoding ] ;
	sscanf( widthString, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w, w+1, w+2, w+3, w+4, w+5, w+6, w+7, w+8, w+9, w+10, w+11, w+12, w+13, w+14, w+15 ) ;
	for ( i = 0; i < n; i++ ) {
		column = columns[i] ;
		j = [ [ column identifier ] intValue ] ;
		[ column setWidth:w[j]*0.1 ] ;
	}
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	int i, j, n, identifier, w[16] ;
	NSArray *columns ;
	NSTableColumn *column ;
	char string[1024] ;

	//  window position
	[ pref setString:[ [ tableView window ] stringWithSavedFrame ] forKey:kContestLogPosition ] ;
	
	n = [ (NSTableView*)tableView numberOfColumns ] ;
	columns = [ tableView tableColumns ] ;
	
	//  column order
	for ( i = 0; i < n; i++ ) {
		column = columns[i] ;
		identifier = [ [ column identifier ] intValue ] ;
		if ( identifier < 0 ) identifier = 0 ; else if ( identifier >= n ) identifier = n-1 ;
		string[i] = ( identifier < 10 ) ? ( '0'+identifier ) : ( 'a'-10+identifier ) ;
	}
	for ( /* continue */; i < 16; i++ ) {
		string[i] = ( i < 10 ) ? ( '0'+i ) : ( 'a'-10+i ) ;
	}
	string[16] = 0 ;
	[ pref setString:[ NSString stringWithCString:string encoding:kTextEncoding ] forKey:kContestLogOrder ] ;

	//  column widths
	for ( i = 0; i < 16; i++ ) w[i] = 0 ;
	for ( i = 0; i < n; i++ ) {
		column = columns[i] ;
		j = [ [ column identifier ] intValue ] ;
		w[j] = [ column width ]*10 ;
	}
	sprintf( string, "%d %d %d %d %d %d %d %d %d %d %d %d %d %d %d %d", w[0], w[1], w[2], w[3], w[4], w[5], w[6], w[7], w[8], w[9], w[10], w[11], w[12], w[13], w[14], w[15] ) ;
	[ pref setString:[ NSString stringWithCString:string encoding:kTextEncoding ] forKey:kContestLogSize ] ;
}


//  both find button and text field completion ends here
- (IBAction)findCallsign:(id)sender
{
	NSString *test ;
	int i, n, j ;
	ContestQSOObj *q ;
	
	test = [ callsignSearchField stringValue ] ;
	if ( [ test length ] <= 0 ) return ;
	
	[ test retain ] ;
	n = [ qsoArray count ] ;
	
	for ( i = searchIndex; i < n; i++ ) {
		q = qsoArray[i] ;
		if ( [ test isEqualToString:[ q callsign ] ] ) {
			[ tableView selectRowIndexes:[ NSIndexSet indexSetWithIndex:i ] byExtendingSelection:NO ] ;
			j = i - 2 ;
			if ( j < 0 ) j = 0 ;
			[ tableView scrollRowToVisible:j ] ;
			j = i + 2 ;
			if ( j >= n ) j = n-1 ;
			[ tableView scrollRowToVisible:j ] ;
			[ tableView scrollRowToVisible:i ] ;  //  make sure i is visible!
			//  update searchIndex for the next search
			searchIndex = ( i+1 ) ;
			[ test release ] ;
			return ;
		}
	}
	if ( searchIndex == 0 ) [ notFoundText setStringValue:@"Not Found" ] ; else [ notFoundText setStringValue:@"No more QSO" ] ;
	[ test release ] ;
}

- (IBAction)lockButtonChanged:(id)sender
{
	switch ( [ sender state ] ) {
	case NSOffState:
		[ sender setTitle:@"Locked" ] ;
		[ self allowEdit:NO ] ;
		break ;
	case NSOnState:
		[ sender setTitle:@"Unlocked" ] ;
		[ self allowEdit:YES ] ;
		break ;
	}
}


/* local */
- (int)sortQSOList:(ContestQSOObj*)p with:(SEL)method
{
	ContestQSOObj *q ;
	int i, lower, upper, n, lastn, count ;
	NSComparisonResult order ;
	IntMethod compare ;

	//  sort by callsign
	lower = 0 ;
	upper = ( count = [ qsoArray count ] ) - 1 ;
	compare = (IntMethod)[ p methodForSelector:method ] ;
	lastn = -1 ;
	
	//  limit search to 2^16
	order = NSOrderedAscending ;
	for ( i = 0; i < 16; i++ ) {
	
		n = ( upper+lower )/2 ;
		if ( n == lastn ) break ;
		lastn = n ;
		
		q = qsoArray[n] ;
		order = compare( p, method, q ) ;
		if ( order == NSOrderedAscending ) upper = n ; else lower = n ;
	}
	if ( order == NSOrderedDescending ) n++ ;
	
	return n ;
}

- (void)setBulkLog:(Boolean)bulk
{
	Boolean old ;
	
	old = bulkLogEntry ;
	bulkLogEntry = bulk ;
	if ( old != bulk && bulk == false ) {
		//  finally sort at the end of a bulk entry
		[ tableView reloadData ] ;
	}
}

//  called from a Contest Interface when a new QSO is logged
//  inform the ContestLog (NSTableView)
- (void)newQSOCreated:(ContestQSO*)qso
{
	ContestQSOObj *p ;
	int n, where ;
	
	p = [ [ ContestQSOObj alloc ] initWith:qso ] ;
	if ( bulkLogEntry ) {
		[ qsoArray addObject:p ] ;
		return ;
	}
	
	where = 0 ;
	switch ( currentSortCriterion ) {
	case 0:
		//  sort by QSO number
		if ( ascend[0] ) {
			[ qsoArray addObject:p ] ; 
			where = [ qsoArray count ]-1 ;
		}
		else [ qsoArray insertObject:p atIndex:0 ] ;
		break ;
	case 1:
		n = ( ascend[1] ) ? [ self sortQSOList:p with:@selector(sortByCallsign:) ] : [ self sortQSOList:p with:@selector(reverseByCallsign:) ] ;
		[ qsoArray insertObject:p atIndex:n ] ;
		where = n ;
		break ;
	case 3:
		n = ( ascend[3] ) ? [ self sortQSOList:p with:@selector(sortByBand:) ] : [ self sortQSOList:p with:@selector(reverseByBand:) ] ;
		[ qsoArray insertObject:p atIndex:n ] ;
		where = n ;
		break ;
	default:
		//  default to adding at the end
		[ qsoArray addObject:p ] ;
		where = [ qsoArray count ]-1 ;
		break ;
	}
	[ tableView noteNumberOfRowsChanged ] ;
	[ tableView scrollRowToVisible:where ] ;
}

static void convertToUpper( char *string )
{
	int v ;
	
	while ( *string ) {
		v = *string & 0xff ;
		if ( v == 216 || v == 175 ) /* slashed zero */ v = '0' ;
		if ( v >= 'a' && v <= 'z' ) v += 'A' - 'a' ;
		*string++ = v ;
	}
}

//  ----- delegates ---------------

//  ContestLog (NSTableDataSource)
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
	return [ qsoArray count ] ;
}

//  ContestLog asking for a table value (NSTableDataSource)
- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)index 
{
	int column ;
	NSString *string ;
	DateTime *t ;
	ContestQSOObj *qso ;
	
	column = [ [ tableColumn identifier ] intValue ] ;
	qso = qsoArray[index] ;
	string = @"" ;
	
	switch ( column ) {
	case 0:
		// QSO #
		string = [ NSString stringWithFormat:@"%d", [ qso qsoNumber ] ] ;
		break ;
	case 1:
		//  call sign
		string = [ qso callsign ] ;
		break ;
	case 2:
		//  time
		t = [ qso time ] ;
		string = [ NSString stringWithFormat:@"%02d:%02d", t->hour, t->minute ] ;
		break ;
	case 3:
		//  band
		string = [ NSString stringWithFormat:@"%5d", [ qso band ] ] ;
		break ;
	case 4:
		//  RST (can be blank)
		string = [ qso rst ] ;
		break ;
	case 5:
		//  received exchange
		string = [ qso exchange ] ;
		break ;
	case 6:
		//  mode
		string = [ qso mode ] ;
		break ;
	case 7:
		//  date
		t = [ qso time ] ;
		string = [ NSString stringWithFormat:@"%02d-%02d-%02d", t->day, t->month, t->year%100 ] ;
		break ;
	}
	return string ;
}

//  value set from ContestLog (NSTableDataSource)
- (void)tableView:(NSTableView*)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn*)tableColumn row:(int)index 
{
	int column, metres, old ;
	char localString[64] ;
	NSString *was, *is ;
	ContestQSOObj *qso ;
	Boolean changed ;
	
	column = [ [ tableColumn identifier ] intValue ] ;
	is = (NSString*)object ;
	qso = qsoArray[index] ;
	changed = NO ;
	
	switch ( column ) {
	case 1:
		// callsign
		was = [ qso callsign ] ;
		//  change to NIL if empty
		if ( [ is length ] <= 0 ) is = @"NIL" ;
		if ( [ was isEqualTo:is ] ) /* no change */ return ;
		// need to modify the log data structure in the contest
		strncpy( localString, [ is cStringUsingEncoding:kTextEncoding ], 63 ) ;
		localString[63] = 0 ;
		convertToUpper( localString ) ;
		[ manager changeQSO:[ qso ptr ] to:localString ] ;
		changed = YES ;
		break ;
	case 3:
		// band
		metres = old = [ qso band ] ;
		if ( [ is length ] <= 0 ) is = @"20" ;
		sscanf( [ is cStringUsingEncoding:kTextEncoding ], "%d", &metres ) ;
		if ( metres != old ) {
			if ( metres == 160 || metres == 80 || metres == 40 || metres == 20 || metres == 15 || metres == 10 ) {
				[ qso setBand:metres ] ;
				changed = YES ;
			}
		}
		break ;
	case 4:
		// RST
		was = [ qso rst ] ;
		if ( [ is length ] <= 0 ) is = @"599" ;
		if ( [ was isEqualTo:is ] ) /* no change */ return ;
		[ qso setRST:is ] ;
		changed = YES ;
		break ;
	case 5:
		// received exchange
		was = [ qso exchange ] ;
		if ( [ was isEqualTo:is ] ) /* no change */ return ;
		[ qso setExchange:is ] ;
		changed = YES ;
		break ;
	case 6:
		//  mode
		if ( [ is length ] <= 0 ) is = @"RY" ;
		strncpy( localString, [ is cStringUsingEncoding:kTextEncoding ], 3 ) ;
		localString[2] = 0 ;
		convertToUpper( localString ) ;
		if ( strcmp( localString, [ [ qso mode ] cStringUsingEncoding:kTextEncoding ] ) == 0 ) return ;
		if ( !strcmp( localString, "RY" ) || !strcmp( localString, "CW" ) || !strcmp( localString, "PH" ) || !strcmp( localString, "PK" ) ) {
			[ qso setQSOMode:localString ] ;
			changed = YES ;
		}
		break ;
	}
	if ( changed ) [ manager journalChanged ] ;
}

//  clicked on colum header (NSTableDataSource), decide on the sort method to use
- (void)tableView:(NSTableView*)inTableView didClickTableColumn:(NSTableColumn*)tableColumn
{
	int column ;
	SEL sortSelector ;
	char *preamble ;
	Boolean reclick ;
	
	reclick = ( previousLogColumn == tableColumn ) ;
	previousLogColumn = tableColumn ;
	
	column = [ [ tableColumn identifier ] intValue ] ;
	currentSortCriterion = column ;

	if ( reclick ) ascend[column] = !ascend[column] ;
	
	preamble = ( ascend[column] ) ? "sort" : "reverse" ;
	
	switch ( column ) {
	case 0:
		sortSelector = NSSelectorFromString( [ NSString stringWithFormat:@"%sByNumber:", preamble ] ) ;
		break ;
	case 1:
		sortSelector = NSSelectorFromString( [ NSString stringWithFormat:@"%sByCallsign:", preamble ] ) ;
		break ;
	case 3:
		sortSelector = NSSelectorFromString( [ NSString stringWithFormat:@"%sByBand:", preamble ] ) ;
		break ;
	default:
		return ;
	}
	[ qsoArray sortUsingSelector: sortSelector ] ;
	[ tableView reloadData ] ;
}

//  reset search index
- (void)controlTextDidChange:(NSNotification *)aNotification
{
	[ notFoundText setStringValue:@"" ] ;
	searchIndex = 0 ;
}

//  allow editing tableview columns that are editable
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn*)tableColumn row:(int)index
{
	return YES ;
}


@end
