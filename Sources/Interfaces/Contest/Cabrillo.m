//
//  Cabrillo.m
//  cocoaModem
//
//  Created by Kok Chen on Thu Jul 01 2004.
	#include "Copyright.h"
//

#import "Cabrillo.h"
#import "Contest.h"
#import "ContestManager.h"
#import "Messages.h"
#import "Plist.h"
#import "Preferences.h"
#import "TextEncoding.h"


@implementation Cabrillo

- (id)initWithManager:(ContestManager*)inManager
{
	NSRect rect ;
	NSFont *font ;
	
	self = [ self init ] ;
	if ( self ) {
		manager = inManager ;
		journalFile = nil ;
		name = nil ;
		if ( [ NSBundle loadNibNamed:@"Cabrillo" owner:self ] ) { 
			rect = [ view bounds ] ;
			[ self setFrame:rect display:NO ] ;
			[ [ self contentView ] addSubview:view ] ;
		}
		if ( fontField ) {
			[ fontField setAllowsEditingTextAttributes:YES ] ;	//  allow font change
			[ fontField setDelegate:self ] ;
			//  set up default font
			[ fontField setFont:[ NSFont systemFontOfSize:12 ] ] ;
			font = [ fontField font ] ;	
			if ( font ) [ fontField setStringValue:[ font fontName ] ] ;
		}
	}
	return self ;
}

- (NSString*)category
{
	return [ [ categoryMenu selectedItem ] title ] ;
}

- (NSString*)band
{
	return [ [ bandMenu selectedItem ] title ] ;
}

- (NSString*)name
{
	return [ nameField stringValue ] ;
}
	
- (NSString*)addr1
{
	return [ addr1Field stringValue ] ;
}
	
- (NSString*)addr2
{
	return [ addr2Field stringValue ] ;
}
	
- (NSString*)addr3
{
	return [ addr3Field stringValue ] ;
}
	
- (NSString*)email
{
	return [ emailField stringValue ] ;
}

- (NSString*)nameUsed
{
	return [ nameUsedField stringValue ] ;
}
	
- (NSString*)callUsed
{
	return [ callUsedField stringValue ] ;
}
	
- (NSString*)operators
{
	return [ operatorsField stringValue ] ;
}
	
- (NSString*)club
{
	return [ clubField stringValue ] ;
}

- (NSString*)soapbox
{
	return [ [ soapboxView textStorage ] string ] ;
}
	
- (void)showSheet:(NSWindow*)window
{
	controllingWindow = window ;
	[ NSApp beginSheet:self modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil ] ;
	[ NSApp runModalForWindow:self ] ;
	//  ... modal mode waits for stopModal in done
	[ NSApp endSheet:self ] ;
	[ self orderOut:controllingWindow ] ;
}

//  set all ContestTextField to current contest font
- (void)setFonts
{
	id font ;
	
	font = [ fontField font ] ;
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"ContestFont" object:font ] ;
}

- (IBAction)done:(id)sender
{
	NSNotificationCenter *center ;
	
	[ NSApp stopModal ] ;
	center = [ NSNotificationCenter defaultCenter ] ;
	[ center postNotificationName:@"MyCall" object:nil ] ;
	if ( manager ) {
		[ manager journalChanged ] ;
		[ manager setAllowDupe:( [ allowDupe state ] == NSOnState ) ] ;
	}
}

static void clearPrefString( Preferences *pref, NSString *key )
{
	if ( key ) [ pref setString:@"" forKey:key ] ;
}

//  replace the TextField by a non-empty string
//  string -> TextField
static void setFieldFromString( NSTextField* field, NSString* string )
{
	if ( string && [ string length ] ) [ field setStringValue:string ] ;
}

//  replace string in TextField by the string value in the Plist key
//  Plist -> TextField
static void setFieldFromPref( Preferences *pref, NSTextField *field, NSString *key )
{
	[ field setStringValue:[ pref stringValueForKey:key ] ] ;
}

//  if TextField has a non empty string, use it to set the string value of the Plist key
//  TextField -> Plist
static void setStringPref( Preferences *pref, NSTextField *field, NSString *key )
{
	NSString *str ;
	
	str = [ field stringValue ] ;
	if ( str ) [ pref setString:str forKey:key ] ;
}


//  called from ContestManager
- (void)setExchange:(NSString*)string 
{
	setFieldFromString( exchangeSent, string ) ;
}

- (NSString*)exchangeString
{
	return [ exchangeSent stringValue ] ;
}

- (NSString*)logExtensionString
{
	return [ logExtension stringValue ] ;
}

//  called from ContestManager
- (void)setCName:(NSString*)string 
{ 
	setFieldFromString( nameField, string ) ;
}

//  called from ContestManager
- (void)setCAddr1:(NSString*)string 
{
	setFieldFromString( addr1Field, string ) ; 
}

//  called from ContestManager
- (void)setCAddr2:(NSString*)string 
{ 
	setFieldFromString( addr2Field, string ) ; 
}

//  called from ContestManager
- (void)setCAddr3:(NSString*)string 
{
	setFieldFromString( addr3Field, string ) ;  
}

//  called from ContestManager
- (void)setEmail:(NSString*)string 
{ 
	setFieldFromString( emailField, string ) ; 
}

//  category menu, called from Contestmanager
- (void)setCategory:(NSString*)string 
{
	[ categoryMenu selectItemWithTitle:string ] ;
}

//  band menu, called from Contestmanager
- (void)setBand:(NSString*)string 
{
	[ bandMenu selectItemWithTitle:string ] ; 
}

//  called from ContestManager
- (void)setCallUsed:(NSString*)string 
{
	setFieldFromString( callUsedField, string ) ; 
}

//  called from ContestManager
- (void)setNameUsed:(NSString*)string 
{
	setFieldFromString( nameUsedField, string ) ; 
}

//  called from ContestManager
- (void)setClub:(NSString*)string
{
	setFieldFromString( clubField, string ) ;
}

//  called from ContestManager
- (void)setOperators:(NSString*)string
{
	setFieldFromString( operatorsField, string ) ;
}

//  set string into view, called from ContestManager
- (void)setSoapbox:(NSString*)string
{
	NSTextStorage *storage ;
	
	storage = [ soapboxView textStorage ] ;
	[ storage replaceCharactersInRange:NSMakeRange(0,[storage length]) withString:string ] ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	[ pref setString:@"Verdana" forKey:kContestFontName ] ;
	[ pref setString:@"" forKey:kTempFolder ] ;
	[ pref setFloat:12.0 forKey:kContestFontSize ] ;
	[ pref setInt:0 forKey:kContestAllowDupe ] ;
	
	clearPrefString( pref, kCabrilloName ) ;
	clearPrefString( pref, kCabrilloAddr1 ) ;
	clearPrefString( pref, kCabrilloAddr2 ) ;
	clearPrefString( pref, kCabrilloAddr3 ) ;
	clearPrefString( pref, kCabrilloMail ) ;
	clearPrefString( pref, kContestLogExtension ) ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *fontname, *tempFolderName ;
	float fontsize ;
	int dupeButton ;
	NSFont *font ;
	//NSTextStorage *storage ;
	
	fontname = [ pref stringValueForKey:kContestFontName ] ;
	fontsize = [ pref floatValueForKey:kContestFontSize ] ;
	font = [ NSFont fontWithName:fontname size:fontsize ] ;
	if ( !font ) font = [ NSFont systemFontOfSize:12 ] ;
	[ font retain ] ;
	[ fontField setFont:font ] ;
	[ self setFonts ] ;
	
	tempFolderName = [ pref stringValueForKey:kTempFolder ] ;
	[ tempFolder setStringValue:tempFolderName ] ;
	
	font = [ fontField font ] ;	
	[ fontField setStringValue:[ font fontName ] ] ;
	
	dupeButton = [ pref intValueForKey:kContestAllowDupe ] ;
	[ allowDupe setState:( dupeButton == 0 ) ? NSOffState : NSOnState ] ;
	[ manager setAllowDupe:( dupeButton != 0 ) ] ;

	setFieldFromPref( pref, nameField, kCabrilloName ) ;
	setFieldFromPref( pref, addr1Field, kCabrilloAddr1 ) ;
	setFieldFromPref( pref, addr2Field, kCabrilloAddr2 ) ;
	setFieldFromPref( pref, addr3Field, kCabrilloAddr3 ) ;
	setFieldFromPref( pref, emailField, kCabrilloMail ) ;
	setFieldFromPref( pref, logExtension, kContestLogExtension ) ;

	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	NSFont *font ;
	
	font = [ fontField font ] ;
	[ pref setString:[ font fontName ] forKey:kContestFontName ] ;
	[ pref setFloat:[ font pointSize ] forKey:kContestFontSize ] ;
	setStringPref( pref, nameField, kCabrilloName ) ;
	setStringPref( pref, addr1Field, kCabrilloAddr1 ) ;
	setStringPref( pref, addr2Field, kCabrilloAddr2 ) ;
	setStringPref( pref, addr3Field, kCabrilloAddr3 ) ;
	setStringPref( pref, emailField, kCabrilloMail ) ;
	setStringPref( pref, logExtension, kContestLogExtension ) ;

	[ pref setString:[ tempFolder stringValue ] forKey:kTempFolder ] ;
	
	[ pref setInt:( ( [ allowDupe state ] == NSOnState ) ? 1 : 0 ) forKey:kContestAllowDupe ] ;
}

- (void)saveFieldsToFile:(FILE*)file
{
	fprintf( file, "\t\t<category>%s</category>\n", [ [ categoryMenu titleOfSelectedItem ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<band>%s</band>\n", [ [ bandMenu titleOfSelectedItem ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<cname>%s</cname>\n", [ [ nameField  stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<addr1>%s</addr1>\n", [ [ addr1Field stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<addr2>%s</addr2>\n", [ [ addr2Field stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<addr3>%s</addr3>\n", [ [ addr3Field stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<email>%s</email>\n", [ [ emailField stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<callused>%s</callused>\n", [ [ callUsedField stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<nameused>%s</nameused>\n", [ [ nameUsedField stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<operators>%s</operators>\n", [ [ operatorsField stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<club>%s</club>\n", [ [ clubField stringValue ] cStringUsingEncoding:kTextEncoding ] ) ;
	fprintf( file, "\t\t<soapbox>%s</soapbox>\n", [ [ [ soapboxView textStorage ] string ] cStringUsingEncoding:kTextEncoding ] ) ;
}

//  import Cabrillo strings
- (IBAction)import:(id)sender
{
	Preferences *prefs ;
	NSOpenPanel *open ;
	NSString *path ;
	int result ;
	
	open = [ NSOpenPanel openPanel ] ;
	[ open setAllowsMultipleSelection:NO ] ;
	result = [ open runModalForDirectory:nil file:nil types:nil ] ;
	if ( result == NSOKButton ) {
		path = [ open filenames ][0] ;
		prefs = [ [ Preferences alloc ] initWithPath:path ] ;
		if ( prefs ) {
			[ prefs fetchPlist:NO ] ;
			[ self updateFromPlist:prefs ] ;
			[ prefs release ] ;
		}
	}
}


- (NSString*)tempFolderName
{
	NSString *current ;
	
	current = [ tempFolder stringValue ] ;
	if ( [ current length ] == 0 ) current = @"~" ;
	current = [ current stringByExpandingTildeInPath ] ;
	
	return current ;
}

//  export Cabrillo strings
- (IBAction)export:(id)sender
{
	Preferences *prefs ;
	NSSavePanel *save ;
	int result ;
	
	save = [ NSSavePanel savePanel ] ;
	result = [ save runModalForDirectory:nil file:@"ContestInfo.xml" ] ;
	if ( result == NSOKButton ) {
		prefs = [ [ Preferences alloc ] initWithPath:[ save filename ] ] ;
		if ( prefs ) {
			//  get the macros into this temp dictionary
			[ self retrieveForPlist:prefs ] ;
			[ prefs savePlist ] ;
			[ prefs release ] ;
		}
	}
}

- (IBAction)selectTempFolder:(id)sender
{
	NSOpenPanel *panel ;
	NSString *current ;
	Boolean needInit ;
	int result ;
	
	current = [ tempFolder stringValue ] ;
	needInit = ( [ current length ] == 0 ) ;
	
	if ( [ manager contestObject ] != nil && !needInit ) {
		[ Messages alertWithMessageText:@"Contest journaling already active." informativeText:@"You cannot change the folder since a journal file is alreadly writing into it.\n\nYou need to change the folder before starting a contest session." ] ;
		return ;
	}
	if ( [ current length ] == 0 ) current = [ @"~" stringByExpandingTildeInPath ] ;
	
	panel = [ NSOpenPanel openPanel ] ;
	[ panel setCanChooseDirectories:YES ] ;
	
	[ panel setCanCreateDirectories:YES ] ;  // only in 10.3 or later
	[ panel setNameFieldLabel:@"Select Directory" ] ;
	//  use a garbage type so we can only choose directories
	result = [ panel runModalForTypes:@[@"onlyPickFolders"] ] ;
	if ( result == NSOKButton ) {
		current = [ panel filename ] ;
		[ tempFolder setStringValue:[ current stringByAbbreviatingWithTildeInPath ] ] ;
	}
}

- (IBAction)clearTempFolder:(id)sender 
{
	NSString *current ;
	
	current = [ tempFolder stringValue ] ;
	if ( [ current length ] == 0 ) return ;
	
	if ( [ manager contestObject ] != nil ) {
		[ Messages alertWithMessageText:@"Contest journaling already active." informativeText:@"You cannot clear the folder since a journal file is alreadly writing into it.\n\nYou need to clear the folder before starting a contest session." ] ;
		return ;
	}
	[ tempFolder setStringValue:@"" ] ;
}

- (FILE*)openJournalFile:(Contest*)contest
{
	NSString *folder, *date ;
	
	if ( journalFile ) {
		// for safety.  we should not get here
		close( journalFile ) ;
		journalFile = nil ;
	}
	folder = [ tempFolder stringValue ] ;
	if ( folder == nil || [ folder length ] <= 0 ) return nil ;
	folder = [ folder stringByExpandingTildeInPath ] ;
	
	name = [ folder stringByAppendingString:@"/cocoaModem " ] ;
	date = [ [ NSDate date ] descriptionWithCalendarFormat:@"%Y-%m-%d %H%M.jnl" timeZone:nil locale:nil ] ;
	name = [ name stringByAppendingString:date ] ;
	
	journalFile = fopen( [ name cStringUsingEncoding:kTextEncoding ], "w" ) ;
	if ( journalFile ) [ contest updateQSOToJournal:journalFile ] ;
	return journalFile ;
}

- (FILE*)reOpenJournalFile:(Contest*)contest
{
	if ( journalFile && name ) {
		journalFile = freopen( NULL, "w", journalFile ) ;
		if ( journalFile ) [ contest updateQSOToJournal:journalFile ] ;
		return journalFile ;
	}
	[ self closeJournalFile ] ;
	return [ self openJournalFile:contest ] ;
}

- (void)closeJournalFile
{
	if ( journalFile ) {
		fclose( journalFile ) ;
		journalFile = nil ;
	}
}

- (FILE*)journal
{
	return journalFile ;
}

//  delegate for fontField (to register font changes)
- (void)controlTextDidChange:(NSNotification *)notification
{
	NSAttributedString *str ;
	NSFont *font, *current ;
	NSString *fname ;
	int len, i ;
	float size ;
	
	current = [ fontField font ] ;
	fname = [ current fontName ] ;
	size = [ current pointSize ] ;

	str = [ fontField attributedStringValue ] ;
	len = [ str length ] ;
	for ( i = 0; i < len; i++ ) {
		//  apply any change to entire field
		font = (NSFont*)[ str attribute:NSFontAttributeName atIndex:i effectiveRange:nil ] ;
		if ( ![ [ font fontName ] isEqualTo:fname ] || [ font pointSize ] != size ) {
			[ fontField setFont:font ] ;
			[ fontField setStringValue:[ font fontName ] ] ;
			//  set all contest fields
			[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"ContestFont" object:font ] ;
			break ;
		}
	}
}

@end
