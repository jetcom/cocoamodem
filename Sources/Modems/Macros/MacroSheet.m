//
//  MacroSheet.m
//  cocoaModem
//
//  Created by Kok Chen on Mon May 31 2004.
	#include "Copyright.h"
//

#import "MacroSheet.h"
#import "Application.h"
#import "MacroInterface.h"
#import "MacroScripts.h"
#import "Messages.h"
#import "Plist.h"
#import "Preferences.h"
#import "QSO.h"
#import "TextEncoding.h"
#import "UserInfo.h"

#define CMFIGSCODE	0x1b
#define CMLTRSCODE	0x1f


@implementation MacroSheet

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		macroBuf = @"" ;
		userInfo = nil ;
		qso = nil ;
		excessTransmitMacros = 0 ;
	}
	return self ;
}

- (id)initSheet
{
	NSRect rect ;
	
	self = [ super init ] ;
	if ( self ) {
		if ( [ NSBundle loadNibNamed:@"MacroSheet" owner:self ] ) {   
			rect = [ view bounds ] ;
			[ self setFrame:rect display:NO ] ;
			[ [ self contentView ] addSubview:view ] ;
			excessTransmitMacros = 0 ;
		}
	}
	return self ;
}

- (void)setUserInfo:(UserInfo*)info qso:(QSO*)qsoObj modem:(MacroInterface*)inModem canImport:(Boolean)canImport
{
	userInfo = info ;
	qso = qsoObj ;
	modem = inModem ;
}

//  this allows the Macrosheet to target a particular modem's contest interface
- (void)setModem:(MacroInterface*)inModem
{
	modem = inModem ;
}

//  macros storage (in Plist) strings are separated by ~ characters
NSString *nextMsg( NSString **full )
{
	NSString *s, *result ;
	int n, length, ch = 0 ;
	
	s = *full ;
	n = 0 ;
	length = [ s length ] ;
	for ( n = 0; n < length; n++ ) {
		ch = [ s characterAtIndex:n ]&0x7f ;
		if ( ch == '~' ) break ;
	} 
	result = ( n == 0 ) ? (NSString*)( @"" ) : [ s substringWithRange:NSMakeRange(0,n) ] ;

	//  update full string to start at next field
	if ( ch == '~' ) n++ ;
	*full = [ s substringFromIndex: n ] ;
	
	return result ;
}

- (void)showMacroSheet:(NSWindow*)window modem:(MacroInterface*)inModem
{
	controllingWindow = window ;
	modem = inModem ;
	[ NSApp beginSheet:self modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil ] ;
	//  [ NSApp runModalForWindow:self ] ;
	//  dont use modal mode so we can show dictionary
}


- (NSString*)title:(int)index
{
	return [ [ titleMatrix cellAtRow:index column:0 ] stringValue ] ;
}

- (NSMatrix*)titles
{
	return titleMatrix ;
}

- (NSString*)macro:(int)index
{
	return [ [ macroMatrix cellAtRow:index column:0 ] stringValue ] ;
}

/* local */
//  append macro and return end of string
//		\n		new line
//		%b		brag tape   (in userInfo)
//		%c		myCall		(in userInfo)
//		%h		name		(in userInfo)
- (NSString*)macroFor:(int)c
{
	NSString *str ;
	
	switch ( c ) {
	default:
		str = @"" ;		// for now no macros
		break ;
	}
	return str ;
}

//	v0.89	MacroScript
- (Boolean)executeMacroScript:(char*)str
{
	int index ;
	Application *application ;
	
	if ( str[0] != 'a' ) return NO ;
	
	index = str[1] - '0' ;
	if ( index >= 0 && index < 6 ) {
		application = [ [ NSApp delegate ] application ] ;
		[ [ application macroScripts ] executeMacroScript:index ] ;
		return YES ;
	}	
	return NO ;
}

//  this is overridden by subclasses to execute button macros
- (Boolean)executeButtonMacro:(char*)str modem:(MacroInterface*)macroInterface
{
	// override
	return NO ;
}

- (void)appendToMessageBuf:(NSString*)string
{
	if ( !string ) return ;
	
	macroBuf = [ macroBuf stringByAppendingString:string ] ;
}

//	v0.70 changed argument from const char* to NSString
- (NSString*)expandMacroString:(NSString*)macroString modem:(MacroInterface*)macroInterface
{
	int n, i,length ;
	char button[3] ;
	unichar unichars[1024], c ;
	NSString *original ;
	NSString *str ;
	NSString *formatted ;
	
	macroBuf = @"" ;
	
	original = [ NSString stringWithString:macroString ] ;		//  v0.78 changed from original = macroString
	if ( [ macroString length ] > 1000 ) macroString = [ macroString substringToIndex:1000 ] ;
	[ macroString getCharacters:unichars ] ;
	length = [ macroString length ] ;
	
	i = 0 ;
	while ( i < length ) {
		c = unichars[i++] ;
		switch ( c & 0xff ) {
		case '%':
			c = unichars[i++] ;
			n = 1 ;
			if ( c == '0' || c == '3' || c == '4' ) {
				n = c - '0' ;
				c = unichars[i++] ;		// v0.78 "c =" was missing? ealier version used C string.  Macros became NSString to support Kanji.
			}
			switch ( c ) {
			case 'b':
			case 'c':
			case 'h':
			case 's':
				if ( userInfo ) [ self appendToMessageBuf:[ userInfo macroFor:c ] ] ;
				break ;
			case 'x':
			case 'X':
			case 'C':
			case 'H':
			case 'p':
			case 'P':
			case 't':
			case 'T':
				if ( qso ) [ self appendToMessageBuf:[ qso macroFor:c ] ] ;
				break ;
			case 'n':
			case 'N':
			case 'o':
				if ( qso ) {
					if ( n == 1 ) [ self appendToMessageBuf:[ qso macroFor:c ] ] ; else [ self appendToMessageBuf:[ qso macroFor:c count:n ] ] ;
				}
				break ;
			case '[':
				button[0] = unichars[i++] & 0xff ;
				button[1] = unichars[i++] & 0xff ;
				button[2] = 0 ;
				if ( ( unichars[i++] & 0xff ) != ']' ) {
					formatted = [ NSString stringWithFormat:@"%@", original ] ;
					[ Messages alertWithMessageText:NSLocalizedString( @"Bad macro", nil ) informativeText:formatted ] ;
				}
				else {
					[ self executeButtonMacro:button modem:macroInterface ] ;
				}
				break ;
			default:
				[ self appendToMessageBuf:[ self macroFor:c ] ] ;
				break ;
			}
			break ;
		case '\\':
			c = unichars[i++] ;
			switch ( c ) {
			//  0.68
			case 'l':
				str = [ NSString stringWithFormat:@"%c", CMLTRSCODE ] ;
				[ self appendToMessageBuf:str  ] ;
				break ;
			case 'f':
				[ self appendToMessageBuf:[ NSString stringWithFormat:@"%c", CMFIGSCODE ]  ] ;
				break ;
			case 'n':
			case 'p': /* already paired as \r\n at the AFSK generator */
				[ self appendToMessageBuf:@"\n" ] ;
				break ;
			case 'r':
				[ self appendToMessageBuf:@"\r" ] ;
				break ;
			default:
				macroBuf = [ macroBuf stringByAppendingString:[ NSString stringWithCharacters:&c length:1 ] ] ;		//  v0.70
				break ;
			}
			break ;
		default:
			macroBuf = [ macroBuf stringByAppendingString:[ NSString stringWithCharacters:&c length:1 ] ] ;		//  v0.70
		}
	}
	// balanced out transmit macros (tx not balanced by rx within a macro)
	while ( excessTransmitMacros-- > 0 ) macroBuf = [ macroBuf stringByAppendingFormat:@"%c", 'Z'-'A'+1 ] ;  
	return macroBuf ;
}

//  expand macro at index into an NSString, client releases
- (NSString*)expandMacro:(int)index modem:(MacroInterface*)macroInterface
{
	NSString *macro ;
	NSTextField *msgField ;

	msgField = [ macroMatrix cellAtRow:index column:0 ] ;
	if ( msgField == nil ) return nil ;
	
	macro = [ msgField stringValue ] ;
	if ( [ macro length ] == 0 ) return nil ;
	
	excessTransmitMacros = 0 ;
	return [ self expandMacroString:macro modem:macroInterface ] ;		//  v0.70
}

//  set up defaults before Plist is fetched
- (void)setupDefaultPreferences:(Preferences*)pref messageKey:(NSString*)messageKey titleKey:(NSString*)titleKey
{
}

- (Boolean)has0x7e:(NSString*)str
{
	unichar uni ;
	int i, n ;
	
	if ( str == nil ) return NO ;
	n = [ str length ] ;
	for ( i = 0; i < n; i++ ) {
		uni = [ str characterAtIndex:i ] ;
		if ( ( uni / 256 ) == '~' ) return YES ;
		if ( ( uni & 0xff ) == '~' ) return YES ;
	}
	return NO ;
}

//  v0.72 -- return as NSArray if there are ~ in the messages otherwise (to maintain compatibility) get messages into a long string separated by ~
- (NSObject*)getMessageObject
{
	int i, n ;
	NSString *string, *msgString ;
	NSTextField *msg ;
	NSMutableArray *array ;
	
	n = [ macroMatrix numberOfRows ] ;
	//   first check all strings to see if there is any ~
	for ( i = 0; i < n; i++ ) {
		string = [ [ macroMatrix cellAtRow:i column:0 ] stringValue ] ;
		if ( [ self has0x7e:string ] ) break ;
	}
	if ( i >= n ) {
		//  no squiggles, use old method for compatibility
		string = @"" ;
		for ( i = 0; i < n; i++ ) {
			msg = [ macroMatrix cellAtRow:i column:0 ] ;
			if ( msg ) {
				msgString = [ msg stringValue ] ;
				if ( [ msgString length ] > 0 ) string = [ string stringByAppendingString:msgString ] ;
			}
			string = [ string stringByAppendingString:@"~" ] ;
		}
		return string ;
	}
	array = [ NSMutableArray arrayWithCapacity:n ] ;
	for ( i = 0; i < n; i++ ) {
		msg = [ macroMatrix cellAtRow:i column:0 ] ;
		if ( msg ) {
			msgString = [ msg stringValue ] ;
			if ( msgString != nil ) [ array addObject:msgString ] ; else [ array addObject:@"" ] ;
		}
		else [ array addObject:@"" ] ;
	}
	return array ;
}

//  v0.72 -- return as NSArray if there are ~ in the messages otherwise (to maintain compatibility) get messages into a long string separated by ~
- (NSObject*)getCaptionObject
{
	int i, n ;
	NSString *string, *msgString ;
	NSTextField *msg ;
	NSMutableArray *array ;
	
	n = [ titleMatrix numberOfRows ] ;
	//   first check all strings to see if there is any ~
	for ( i = 0; i < n; i++ ) {
		string = [ [ titleMatrix cellAtRow:i column:0 ] stringValue ] ;
		if ( [ self has0x7e:string ] ) break ;
	}
	if ( i >= n ) {
		string = @"" ;
		for ( i = 0; i < n; i++ ) {
			msg = [ titleMatrix cellAtRow:i column:0 ] ;
			if ( msg ) {
				msgString = [ msg stringValue ] ;
				if ( [ msgString length ] > 0 ) string = [ string stringByAppendingString:msgString ] ;
			}
			string = [ string stringByAppendingString:@"~" ] ;
		}
		return string ;
	}
	array = [ NSMutableArray arrayWithCapacity:n ] ;
	for ( i = 0; i < n; i++ ) {
		msg = [ titleMatrix cellAtRow:i column:0 ] ;
		if ( msg ) {
			msgString = [ msg stringValue ] ;
			if ( msgString != nil ) [ array addObject:msgString ] ; else [ array addObject:@"" ] ;
		}
		else [ array addObject:@"" ] ;
	}
	return array ;
}

//	v0.72 (was updateFromMessageString:titleString:)
//  update macro fields from either ~ delimted strings or from NSArray of strings
- (void)updateFromMessageObject:(NSObject*)msgObject titleObject:(NSObject*)titleObject
{
	NSString *result, *string ;
	NSArray *array ;
	int i, n ;
	
	n = [ macroMatrix numberOfRows ] ;
	if ( [ msgObject isKindOfClass:[ NSString class ] ] ) {		//  v0.93a, was using [ @"" class ] to compare for string class, but Lion returns const NSString* instead
		string = (NSString*)msgObject ;
		for ( i = 0; i < n; i++ ) {
			result = nextMsg( &string ) ;
			[ [ macroMatrix cellAtRow:i column:0 ] setStringValue:result ] ;
		}
	}
	else {
		array = (NSArray*)msgObject ;
		if ( n > [ array count ] ) n = [ array count ] ;
		for ( i = 0; i < n; i++ ) {
			result = (NSString*)array[i] ;
			[ [ macroMatrix cellAtRow:i column:0 ] setStringValue:result ] ;
		}
	}
	n = [ titleMatrix numberOfRows ] ;
	if ( [ titleObject isKindOfClass:[ NSString class ] ] ) {		//  v0.93a
		string = (NSString*)titleObject ;
		for ( i = 0; i < n; i++ ) {
			result = nextMsg( &string ) ;
			[ [ titleMatrix cellAtRow:i column:0 ] setStringValue:result ] ;
		}
	}
	else {
		array = (NSArray*)titleObject ;
		if ( n > [ array count ] ) n = [ array count ] ;
		for ( i = 0; i < n; i++ ) {
			result = (NSString*)array[i] ;
			[ [ titleMatrix cellAtRow:i column:0 ] setStringValue:result ] ;
		}
	}
	[ modem updateMacroButtons ] ;
}

//	v0.72
//  update macro fields from the plist (called after fetchPlist )
- (void)updateFromPlist:(Preferences*)pref messageKey:(NSString*)messageKey titleKey:(NSString*)titleKey
{
	NSObject *msgObject, *titleObject ;
	
	msgObject = [ pref objectForKey:messageKey ] ;
	titleObject = [ pref objectForKey:titleKey ] ;
	
	[ self updateFromMessageObject:msgObject titleObject:titleObject ] ;
}

//  v0.93a - fixed [ @"" class ]
- (void)retrieveForPlist:(Preferences*)pref messageKey:(NSString*)messageKey titleKey:(NSString*)titleKey 
{
	NSObject *object ;
	
	object = [ self getMessageObject ] ;
	if ( [ object  isKindOfClass:[ NSString class ] ] ) [ pref setString:(NSString*)object forKey:messageKey ] ; else [ pref setArray:(NSArray*)object forKey:messageKey ] ;

	object = [ self getCaptionObject ] ;
	if ( [ object  isKindOfClass:[ NSString class ] ] ) [ pref setString:(NSString*)object forKey:titleKey ] ; else [ pref setArray:(NSArray*)object forKey:titleKey ] ;
}

//  override this in ContestMacroSheet
- (void)performDone
{
	[ modem updateMacroButtons ] ;
	// 	[ NSApp stopModal ] ;		sheet is not model
	[ NSApp endSheet:self ] ;
	[ self orderOut:controllingWindow ] ;
}

- (IBAction)done:(id)sender
{
	[ self performDone ] ;
}

//  import macros
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
			[ self updateFromPlist:prefs messageKey:kMessages titleKey:kMessageTitles ] ;
			[ prefs release ] ;
		}
	}
}

//  export macros
- (IBAction)export:(id)sender
{
	Preferences *prefs ;
	NSSavePanel *save ;
	NSString *path ;
	int result ;
	
	save = [ NSSavePanel savePanel ] ;
	// types: should be an NSArray of file extensions strings instead of nil if only those extensions are to be selectable
	result = [ save runModal ] ;
	if ( result == NSOKButton ) {
		path = [ save filename ] ;
		prefs = [ [ Preferences alloc ] initWithPath:path ] ;
		if ( prefs ) {
			//  get the macros into this temp dictionary
			[ self retrieveForPlist:prefs messageKey:kMessages titleKey:kMessageTitles ] ;
			[ prefs savePlist ] ;
			[ prefs release ] ;
		}
	}
}

@end
