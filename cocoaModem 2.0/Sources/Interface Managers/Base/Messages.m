//
//  Messages.m
//  cocoaModem
//
//  Created by Kok Chen on Tue Jun 08 2004.
	#include "Copyright.h"
//

#import "Messages.h"
#import "AYTextView.h"
#import "TextEncoding.h"
#import "Application.h"
#import "AppDelegate.h"

@implementation Messages

static Messages *mainLog ;


+ (void)logMessage:(char*)format,...
{
	va_list ap ;
	char msg[256] ;
	
	va_start( ap, format ) ;						//  v0.38  reduce vargs to a single level
	vsprintf( msg, format, ap ) ;
	va_end( ap ) ;

	[ mainLog msg:msg ] ;
}

+ (int)alertWithMessageText:(NSString*)msg informativeText:(NSString*)info
{
	//  v1.02e
	if ( [ [ NSApp delegate ] appLevel ] == 0 ) {
		if ( [ [ NSApp delegate ] voiceAssist ] ) {
			[ [ NSApp delegate ] speakAssist:[ NSString stringWithFormat:@"Alert! %@ .", msg ] ] ;
			[ [ NSApp delegate ] setSpeakAssistInfo:info ] ;
			return NSAlertDefaultReturn ;
		}
	}
	else {
		if ( [ [ [ NSApp delegate ] application ] voiceAssist ] ) {
			[ [ [ NSApp delegate ] application ] speakAssist:[ NSString stringWithFormat:@"Alert! %@ .", msg ] ] ;
			[ [ [ NSApp delegate ] application ] setSpeakAssistInfo:info ] ;
			return NSAlertDefaultReturn ;
		}
	}
	return [ [ NSAlert alertWithMessageText:msg defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:info ] runModal ] ;
}

+ (void)alertWithHiraganaError
{
	[ [ NSAlert alertWithMessageText:NSLocalizedString( @"Unrecognized encoding", nil ) defaultButton:NSLocalizedString( @"OK", nil ) alternateButton:nil otherButton:nil informativeTextWithFormat:NSLocalizedString( @"kotoeri", nil ) ] runModal ] ;
}

+ (void)appleScriptError:(NSDictionary*)dict script:(const char*)from
{
	int code ;
	NSString *msg ;
	NSString *nstr ;
	char *errString, str[256] ;

	if ( dict ) {
		code = [ [ dict objectForKey:NSAppleScriptErrorNumber] intValue ] ;
		msg = [ dict objectForKey:NSAppleScriptErrorMessage ] ;
		nstr = nil ;
		switch ( code ) {
		case -43:
			nstr = NSLocalizedString( @"File not found", nil ) ;
			break ;
		case -120:
			nstr = NSLocalizedString( @"Directory not found", nil ) ;
			break ;
		case -128:
			//  user cancelled
			return ;
		case -1703:
			nstr = NSLocalizedString( @"Wrong data type", nil ) ;
			break ;
		case -2753:
			nstr = NSLocalizedString( @"Undefined variable", nil ) ;
			break ;
		}
		if ( nstr == nil ) {
			errString = (char*)[ [ [ NSError errorWithDomain:NSOSStatusErrorDomain code:code userInfo:nil ] localizedDescription ] cStringUsingEncoding:kTextEncoding ] ;
			sprintf( str, "%s for %s script.\n\nError detail: %s", errString, from, [ msg cStringUsingEncoding:kTextEncoding ] ) ;
		}
		else {
			errString = (char*)[ nstr cStringUsingEncoding:NSUTF8StringEncoding ] ;
			sprintf( str, "%s for %s script.", errString, from ) ;
		}
		[ self alertWithMessageText:NSLocalizedString( @"AppleScript error", nil ) informativeText:[ NSString stringWithCString:str encoding:kTextEncoding ] ] ;
	}
}

//  initialize with given view
- (id)initIntoView:(NSTextView*)view
{
	self = [ super init ] ;
	if ( self ) {
		sessionStartDate = [ [ NSDate date ] retain ] ;
		if ( [ NSBundle loadNibNamed:@"ModemLog" owner:self ] ) {
			// loadNib should have set up contentView connection
			if ( contentView ) {
				mainLog = self ;
				logView = view ;
				return self ;
			}
		}
	}
	return nil ;
}

//  initialize, and load the log view from the Nib into the tab view (not used in cocoaModem 2.0)
- (id)initIntoTabView:(NSTabView*)tabview
{
	self = [ super init ] ;
	if ( self ) {
		sessionStartDate = [ [ NSDate date ] retain ] ;
		if ( [ NSBundle loadNibNamed:@"ModemLog" owner:self ] ) {
			// loadNib should have set up contentView connection
			if ( contentView ) {
				//  create a new TabViewItem for config
				logTabItem = [ [ NSTabViewItem alloc ] init ] ;
				[ logTabItem setLabel:@"Diagnostics" ] ;
				[ logTabItem setView:contentView ] ;
				//  and insert as tabView item
				controllingTabView = tabview ;
				[ controllingTabView addTabViewItem:logTabItem ] ;
				mainLog = self ;
				return self ;
			}
		}
	}
	return nil ;
}

- (void)appendToBuffer:(NSString*)str
{
	if ( str == nil ) return ;
	
	[ bufferedString appendString:str ] ;

	if ( [ [ logView window ] isVisible ] ) {
		[ logView setEditable:YES ] ;
		[ logView insertText:bufferedString ] ;
		[ logView setEditable:NO ] ;
		[ bufferedString setString:@"" ] ;
	}
}

- (void)show
{
	NSWindow *window ;
	
	window = [ logView window ] ;
	[ window orderFront:self ] ;
	if ( [ bufferedString length ] > 0 ) {
		[ self appendToBuffer:@"" ] ;
	}
}

- (void)awakeFromApplication
{
	mainLog = self ;
	bufferedString = [ [ NSMutableString stringWithCapacity:4096 ] retain ] ;
	[ self appendToBuffer:NSLocalizedString( @"welcome", nil ) ] ;
}

- (void)msg:(char*)msg
{
	double elapsed ;
	int m, s, n ;
	char fullmsg[256] ;
	
	elapsed = [ [ NSDate date ] timeIntervalSinceDate:sessionStartDate ] ;
	n = elapsed ;
	s = n%60 ;
	m = ( n/60 )%60;
	n = ( elapsed-n )*1000 ;
	if ( n >= 1000 ) n = 999 ;
	
	sprintf( fullmsg, "[ %02d: %02d: %02d.%03d ]  %s\n", n/3600, m, s, n, msg ) ;	
	[ (Messages*)mainLog appendToBuffer:[ NSString stringWithCString:fullmsg encoding:kTextEncoding ] ] ;
}


@end
