//
//  StdManager.m
//  cocoaModem
//
//  Created by Kok Chen on 8/7/05.
	#include "Copyright.h"
//

#import "StdManager.h"
#import "Application.h"
#import "ASCII.h"
#import "Contest.h"
#import "ContestBar.h"
#import "ContestInterface.h"
#import "ContestManager.h"
#import "DualRTTY.h"
#import "FAX.h"
#import "Hellschreiber.h"
#import "HellConfig.h"
#import "LiteASCII.h"
#import "LitePSK.h"
#import "LiteRTTY.h"
#import "Messages.h"
#import "MFSK.h"
#import "Plist.h"
#import "PSK.h"
#import "PSKConfig.h"
#import "QSO.h"
#import "RTTY.h"
#import "RTTYConfig.h"
#import "RTTYMacros.h"
#import "SITOR.h"
#import "SynchAM.h"
#import "WBCW.h"
#import "WFRTTY.h"


@implementation StdManager

- (void)setupWindow:(Boolean)textured lite:(Boolean)lite
{
	NSWindow *window ;
	NSView *view ;
	
	//  create logging object
	log = nil ;
	if ( logView ) {
		log = [ [ Messages alloc ] initIntoView:logView ] ;
		[ log awakeFromApplication ] ;
	}
	
	[ super setupWindow:textured lite:lite ] ;
	takesContestMenus = YES ;
	//  set up main window
	window = [ tabview window ] ;
	[ window orderOut:self ] ;
	view = [ window contentView ] ;
	tooltip = [ view addToolTipRect:[ view bounds ] owner:@"" userData:nil ] ;
	[ view setToolTip:@"" ] ;
	enableCloseButton = YES ;
	contestInCQ = YES ;
	qsoShowing = NO ;
	contest = nil ;
	isTextured = textured ;
	
	//  QSO/ContestBar 
	qsoTabview = ( textured ) ? qsoTabviewTextured : qsoTabviewUntextured ;
	qso = [ [ QSO alloc ] initIntoTabView:qsoTabview app:application ] ;
	contestBar = [ [ ContestBar alloc ] initIntoTabView:qsoTabview app:application ] ;
	//  initialize ContestManager
	[ contestManager awakeFromApplication ] ;
	[ contestManager initContestMacros ] ;

	//  set delegate window to ourself
	[ window setDelegate:self ] ;
}

- (void)useSmoothPattern:(Boolean)state
{
	NSWindow *window ;
	//  use gray window instead of brushed metal
	if ( isTextured ) {
		window = [ tabview window ] ;
		if ( state ) [ window setBackgroundColor:[ NSColor colorWithDeviceWhite:0.80 alpha:1.0 ] ] ; else [ window setBackgroundColor:nil ] ;
	}
}

- (void)setModemCanTransmit:(Boolean)state
{
	//  turn off QSO log items for non transmitting modes
	[ qso showOnlyDateAndTime:!state ] ;
}

//  here is where all the modems are created
- (void)createModems:(Preferences*)pref startModemsFromPlist:(Preferences*)modemList
{
	NSTabViewItem *dummy ;
	NSString *modemString ;
	InstalledModem *installed ;
	
	[ super createModems:pref startModemsFromPlist:(Preferences*)modemList ] ;
	
	dummy = [ tabview tabViewItemAtIndex:0 ] ;
	[ tabview removeTabViewItem:dummy ] ;
	//  create modems from the initial plist and place into the tabview
	//  modems with tabs at right are created first
	//  modems that support contests need to have the contest bar set
	
	installed = &installedModem[0] ;
	finishedCreatingModems = NO ;			//  v0.41
	
	modemString = [ modemList stringValueForKey:kModemList ] ;
	if ( modemString == nil ) modemString = @"11111111111111" ;
	
	if ( [ modemString characterAtIndex:kAMModemOrder ] == '1' && isLiteWindow == NO ) {	
		installed->modem = [ [ SynchAM alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"am" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = NO ;
		installed->receiveOnly = YES ;
		installed->numberOfReceiveViews = 0 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kFAXModemOrder ] == '1' && isLiteWindow == NO ) {	
		installed->modem = [ [ FAX alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"fax" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = NO ;
		installed->receiveOnly = YES ;
		installed->numberOfReceiveViews = 0 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kSitorModemOrder ] == '1' && isLiteWindow == NO ) {
		installed->modem = sitor = [ [ SITOR alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"sitor modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = NO ;
		installed->receiveOnly = YES ;
		installed->numberOfReceiveViews = 2 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kASCIIModemOrder ] == '1' && isLiteWindow == NO ) {	
		installed->modem = asciiRTTY = [ [ ASCII alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"ascii rtty modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = YES ;
		installed->receiveOnly =  NO ;
		installed->numberOfReceiveViews = 2 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}	
	if ( [ modemString characterAtIndex:kCWModemOrder ] == '1' && isLiteWindow == NO ) {		
		installed->modem = cw = [ [ WBCW alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"cw modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->slashedZero = YES ;
		installed->receiveOnly = installed->rttyMacro = NO ;
		installed->numberOfReceiveViews = 2 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kHellModemOrder ] == '1' && isLiteWindow == NO ) {	
		installed->modem = hell = [ [ Hellschreiber alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"hellschreiber modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = YES ;
		installed->rttyMacro = installed->slashedZero = installed->receiveOnly = NO ;
		installed->numberOfReceiveViews = 0 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kMFSKModemOrder ] == '1' && isLiteWindow == NO ) {	
		installed->modem = mfsk = [ [ MFSK alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"mfsk modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->receiveOnly = NO ;
		installed->numberOfReceiveViews = 1 ;
		installed->slashedZero = YES ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kPSKModemOrder ] == '1' ) {	
		if ( isLiteWindow ) {
			installed->modem = psk = [ [ LitePSK alloc ] initIntoTabView:tabview manager:self ] ;
		}
		else {
			installed->modem = psk = [ [ PSK alloc ] initIntoTabView:tabview manager:self ] ;
		}		
		installed->name = @"psk modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->slashedZero = YES ;
		installed->rttyMacro = installed->receiveOnly = NO ;
		installed->numberOfReceiveViews = 2 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kDualRTTYModemOrder ] == '1' && isLiteWindow == NO ) {		
		installed->modem = dualRTTY = [ [ DualRTTY alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"dual rtty modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = YES ;
		installed->receiveOnly = NO ;
		installed->numberOfReceiveViews = 2 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	if ( [ modemString characterAtIndex:kWidebandRTTYModemOrder ] == '1' ) {	
		if ( isLiteWindow ) {
			installed->modem = wfRTTY = [ [ LiteRTTY alloc ] initIntoTabView:tabview manager:self ] ;
			[ (LiteRTTY*)wfRTTY showControlWindow:NO ] ;		//  v0.64c don't display yet
		}
		else {
			installed->modem = wfRTTY = [ [ WFRTTY alloc ] initIntoTabView:tabview manager:self ] ;
		}
		installed->name = @"wideband rtty modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = YES ;
		installed->receiveOnly =  NO ;
		installed->numberOfReceiveViews = 2 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}	
	if ( [ modemString characterAtIndex:kRTTYModemOrder ] == '1' && isLiteWindow == NO ) {		
		installedModems = installed - &installedModem[0] + 1 ;		//  need to update before calling initIntoTabView v0.41
		installed->modem = rtty = [ [ RTTY alloc ] initIntoTabView:tabview manager:self ] ;
		installed->name = @"rtty modem" ;
		installed->tabItem = [ installed->modem tabItem ] ;
		installed->contest = installed->rttyMacro = installed->slashedZero = YES ;
		installed->receiveOnly = NO ;
		installed->numberOfReceiveViews = 1 ;
		installed->updatedFromPlist = NO ;
		installed++ ;
	}
	installedModems = installed - &installedModem[0] ;
	finishedCreatingModems = YES ;					// v 0.41
	
	//  initially select modem at first tab v0.53b moved to -selectDefaultModem
	//[ tabview selectFirstTabViewItem:self ] ;
	//[ self setModemAtTab:[ tabview tabViewItemAtIndex:0 ] ] ;		//  v0.41 v0.53b moved to Application.m
}

//  v0.53b
- (void)selectDefaultModem
{
	//[ tabview selectFirstTabViewItem:self ] ;
	//[ self setModemAtTab:[ tabview tabViewItemAtIndex:0 ] ] ;
}

//  0.53b	this is called after deferred plist is updated in super -willSelectTabViewItem
- (void)updateContestBar:(ContestInterface*)modem
{
	[ modem setContestBar:contestBar ] ;
}

//  make sure plist has been updated before calling this method
//  -updateModemSources calls each installed modem to update its audio source.
//  0.53b  this has been moved to the deferred Plist update code in ModemManager -willSelectTabViewItem
- (void)updateModemSources
{
	return ;
	
	/*
	int i ;
	InstalledModem *installed ;
	
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( installed->contest ) [ (ContestInterface*)( installed->modem ) setContestBar:contestBar ] ;
		[ installed->modem updateSourceFromConfigInfo ] ;
		installed++ ;
	}
	*/
}

//  switch all contest capable modems between the interactive and the contest interface
- (void)useContestMode:(Boolean)state
{
	int i ;
	InstalledModem *installed ;
	
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( installed->contest ) [ (ContestInterface*)( installed->modem ) selectContestMode:state ] ;
		installed++ ;
	}
}

//  enable/disable all installed modems
- (void)enableModems:(Boolean)state
{
	int i ;
	InstalledModem *installed ;
	
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		[ ( installed->modem ) enableModem:state ] ;
		installed++ ;
	}
}

//  called from selectContest:parser:
- (Contest*)createContestClients
{
	int i ;
	ContestInterface *activeInterface ;
	NSTabViewItem *currentTabViewItem = [ tabview selectedTabViewItem ] ;
	InstalledModem *installed ;

	activeInterface = nil ;
	
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( installed->contest ) {
			[ contestManager addContestClient:(ContestInterface*)installed->modem ] ;
			if ( currentTabViewItem == installed->tabItem ) {
				activeInterface = (ContestInterface*)installed->modem ;
				[ activeInterface updateContestMacroButtons ] ;
			}
		}
		installed++ ;
	}
	if ( activeInterface ) {
		[ contestManager setActiveContestInterface:activeInterface ] ;
		[ contestManager startUp ] ;
	}
	return contest ;
}

/* local */
- (Modem*)selectedModem
{
	int i ;
	InstalledModem *installed ;
	NSTabViewItem *currentTabViewItem = [ tabview selectedTabViewItem ] ;
	
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( currentTabViewItem == installed->tabItem ) {
			return installed->modem ;
		}
		installed++ ;
	}
	return nil ;
}

//  v0.96c
- (void)selectView:(int)index
{
	[ [ self selectedModem ] selectView:index ] ;
}					

- (NSString*)selectedModemName
{
	int i ;
	InstalledModem *installed ;
	NSTabViewItem *currentTabViewItem = [ tabview selectedTabViewItem ] ;

	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( currentTabViewItem == installed->tabItem ) return installed->name ;
		installed++ ;
	}
	return @"unknown modem" ;
}


- (void)switchCurrentModemToTransmit:(Boolean)state
{
	[ [ self selectedModem ] enterTransmitMode:state ] ;
}

- (void)flushCurrentModem
{
	[ [ self selectedModem ] flushAndLeaveTransmit ] ;
}

- (void)showConfigPanel
{
	[ [ self selectedModem ] showConfigPanel ] ;
}

- (void)closeConfigPanels
{
	int i ;
	InstalledModem *installed ;

	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		[ installed->modem closeConfigPanel ] ;
		installed++ ;
	}
}

- (void)updateQSOWindow	
{
	int index ;
	
	if ( [ application contestModeState ] ) {
		index = ( contestInCQ ) ? 2 : 1 ;
	}
	else {
		index = ( qsoShowing ) ? 0 : 1 ;
	}
	[ qsoTabview selectTabViewItemAtIndex:index ] ;
}

- (void)setEnableQSOInterface:(Boolean)state
{
	qsoShowing = state ;
	[ [ application qsoEnableItem ] setState:( qsoShowing ) ? NSOnState : NSOffState ] ;
	[ self updateQSOWindow ] ;
}

- (Boolean)qsoInterfaceShowing
{
	return qsoShowing ;
}

- (void)toggleQSOShowing
{
	[ self setEnableQSOInterface:!qsoShowing ] ;
}

//  v1.01a
- (void)selectQSOCall
{
	if ( qso ) [ qso selectCall ] ;
}

//  v1.01a
- (void)selectQSOName
{
	if ( qso ) [ qso selectName ] ;
}	

- (void)contestSwitchedToCQ:(Boolean)cqmode
{
	contestInCQ = cqmode ;
	[ self updateQSOWindow ] ;
}

- (Contest*)currentContest
{
	return contest ;
}

- (Contest*)selectContest:(NSString*)contestName parser:(NSXMLParser*)parser
{
	[ application switchInterfaceMode:1 ] ;
	contest = [ contestManager selectContest:contestName parser:parser ] ;
	return [ self createContestClients ] ;
}

- (Boolean)executeContestMacroFromShortcut:(int)n sheet:(int)sheet modem:(ContestInterface*)modem
{
	return [ contestManager executeContestMacroFromShortcut:n sheet:sheet modem:modem ] ;
}

- (void)showCabrilloInfo
{
	[ contestManager showCabrilloInfoSheet:[ tabview window ] ] ;
}

- (void)updateRTTYMacroButtons
{
	int i ;
	InstalledModem *installed ;

	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( installed->rttyMacro ) [ (MacroInterface*)( installed->modem ) updateModeMacroButtons ] ;
		installed++ ;
	}
}

- (void)displayRTTYScope
{
	if ( wfRTTY ) [ (WFRTTY*)wfRTTY showScope ] ;
	else if ( rtty ) [ (RTTY*)rtty showScope ] ; 
	else if ( dualRTTY ) [ (DualRTTY*)dualRTTY showScope ] ;
}

- (QSO*)qsoObject
{
	return qso ;
}

- (NSTabView*)qsoTabviewObject
{
	return qsoTabview ;
}

- (Boolean)okToQuit
{
	return [ contestManager okToQuit ] ;
}

//  create the shared RTTY macros
- (void)createRTTYMacros:(Preferences*)pref
{
	int i ;
	RTTYMacros *macroSheet ;
	
	for ( i = 0; i < 3; i++ ) {
		macroSheet =  [ [ RTTYMacros alloc ] initSheet ] ;
		if ( macroSheet ) {
			rttyMacroSheet[i] = macroSheet ;
			[ macroSheet setUserInfo:[ application userInfoObject ] qso:qso modem:nil canImport:YES ] ;
			[ macroSheet setupDefaultPreferences:pref option:i ] ;
		}
	}
}

- (void)loadRTTYMacros:(Preferences*)pref
{
	int i, j ;
	RTTYMacros *macroSheet ;
	InstalledModem *installed ;

	[ self showSplash:@"Loading RTTY macros" ] ;
	for ( i = 0; i < 3; i++ ) {
		macroSheet = rttyMacroSheet[i] ;
		if ( macroSheet ) {
			[ macroSheet updateFromPlist:pref option:i ] ;
			//  link and update RTTY mode macros to the common RTTY macros
			installed = &installedModem[0] ;
			for ( j = 0; j < installedModems; j++ ) {
				if ( installed->rttyMacro ) [ (MacroInterface*)( installed->modem ) setMacroSheet:macroSheet index:i ] ;
				installed++ ;
			}	
		}
	}
	[ self updateRTTYMacroButtons ] ;
}

- (void)retrieveRTTYMacros:(Preferences*)pref
{
	int i ;
	RTTYMacros *macroSheet ;
	
	for ( i = 0; i < 3; i++ ) {
		macroSheet = rttyMacroSheet[i] ;
		if ( macroSheet ) [ macroSheet retrieveForPlist:pref option:i ] ;
	}
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
	int i ;
	InstalledModem *installed ;
	
	[ self createRTTYMacros:pref ] ;
	//  set up defaults of each component
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		[ installed->modem setupDefaultPreferences:pref ] ;
		installed++ ;
	}
	[ contestManager setupDefaultPreferences:pref ] ;
}

//  v0.53b -- defer plist updates
- (Boolean)updateFromPlist:(Preferences*)pref
{
	[ super updateFromPlist:pref ] ;
	
	[ self loadRTTYMacros:pref ] ;
	[ contestManager updateFromPlist:pref ] ;
	
	// v0.53b -- this has been moved to super -willSelectTabViewItem
	/*
	InstalledModem *installed = &installedModem[0] ;
	int i ;
	for ( i = 0; i < installedModems; i++ ) {
		[ installed->modem updateFromPlist:pref ] ;
		installed++ ;
	}
	*/
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	int i ;
	InstalledModem *installed ;
	
	[ super retrieveForPlist:pref ] ;
	[ self retrieveRTTYMacros:pref ] ;
	[ contestManager retrieveForPlist:pref ] ;

	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		[ installed->modem retrieveForPlist:pref ] ;
		installed++ ;
	}
}

- (void)setAppearancePrefs:(NSMatrix*)appearancePrefs
{
	int i, j, count, state ;
	NSWindow *window ;
	NSButton *b ;
	InstalledModem *installed ;
	
	count = [ appearancePrefs numberOfRows ] ;
	window = [ tabview window ] ;
	for ( i = 0; i < count; i++ ) {
		b = [ appearancePrefs cellAtRow:i column:0 ] ;
		state = [ b state ] ;
		if ( state == NSOnState ) {
			switch ( i ) {
			case 1:
				//  enable main window close button
				enableCloseButton = YES ;
				break ;
			case 2:
				//  hide main window on deactivation
				[ window setHidesOnDeactivate:YES ] ;
				break ;
			case 3:
				//  hide aux windows on deactivation
				if ( rtty ) [ (RTTY*)rtty hideScopeOnDeactivation:YES ] ;
				break ;
			case 6:
				//  slashed zeros
				installed = &installedModem[0] ;
				for ( j = 0; j < installedModems; j++ ) {
					if ( installed->slashedZero ) [ installed->modem useSlashedZero:YES ] ;
					installed++ ;
				}
				break ;
			case 7:
				useWatchdog = YES ;
				break ;
			}
		}
		else {
			switch ( i ) {
			case 1:
				//  disable main window close button
				enableCloseButton = NO ;
				break ;
			case 2:
				//  disble hide main window on deactivation
				[ window setHidesOnDeactivate:NO ] ;
				break ;
			case 3:
				//  disble hide aux windows on deactivation
				if ( rtty ) [ (RTTY*)rtty hideScopeOnDeactivation:NO ] ;
				break ;
			case 4:
				//  remove tooltips from modems
				installed = &installedModem[0] ;
				for ( j = 0; j < installedModems; j++ ) {
					[ installed->modem removeToolTips ] ;
					installed++ ;
				}	
				break ;
			case 6:
				//  slashed zeros
				installed = &installedModem[0] ;
				for ( j = 0; j < installedModems; j++ ) {
					if ( installed->slashedZero ) [ installed->modem useSlashedZero:NO ] ;
					installed++ ;
				}	
				break ;
			case 7:
				useWatchdog = NO ;
				break ;
			}
		}
	}
}

- (void)setPSKPrefs:(NSMatrix*)pskPrefs
{
	int i, count, state ;
	NSButton *b ;
	
	count = [ pskPrefs numberOfRows ] ;
	for ( i = 0; i < count; i++ ) {
		b = [ pskPrefs cellAtRow:i column:0 ] ;
		state = [ b state ] ;
		if ( state == NSOnState ) {
			switch ( i ) {
			case 0:
				//  use control instead of option
				if ( psk ) [ (PSK*)psk useControlButton:YES ] ;
				break ;
			case 1:
				if ( psk ) [ (PSK*)psk setAFCState:YES ] ;
				break ;
			case 2:
				if ( psk ) [ (PSK*)psk setAllowShiftJIS:YES ] ;
				break ;
			}
		}
		else {
			switch ( i ) {
			case 0:
				//  use option instead of control
				if ( psk ) [ (PSK*)psk useControlButton:NO ] ;
				break ;
			case 1:
				if ( psk ) [ (PSK*)psk setAFCState:NO ] ;
				break ;
			case 2:
				if ( psk ) [ (PSK*)psk setAllowShiftJIS:NO ] ;
				break ;
			}
		}
	}
}

//  delegate of main window
- (BOOL)windowShouldClose:(id)sender
{
	if ( enableCloseButton ) {
		[ NSApp terminate:self ] ;
		return YES ;
	}
	[ [ NSNotificationCenter defaultCenter ] postNotificationName:@"SysBeep" object:nil ] ;
	return NO ;
}

//  AppleScript support

// contest band
- (int)band 
{
	if ( !contest ) return 0 ;
	return [ contest selectedBand ] ;
}

- (void)setBand:(int)data
{
	if ( contest ) [ contest selectBand:data ] ;
}

- (void)selectInterface:(NSScriptCommand*)command
{
	NSScriptObjectSpecifier *param ;
	NSString *type ;
	
	param = [ command directParameter ] ;
	type = [ param key ] ;
	[ application changeInterfaceTo:self alternate:( [ type isEqualToString:@"contestInterface" ] ) ? 1 : 0 ] ;
}

- (void)resetWatchdog:(NSScriptCommand*)command
{
	[ selectedModem resetWatchdog ] ;
}

- (Modem*)dualRTTYModem
{
	return dualRTTY ;
}

- (Modem*)wfRTTYModem
{
	return wfRTTY ;
}

- (Modem*)rttyModem
{
	return rtty ;
}

- (Modem*)pskModem
{
	return psk ;
}

- (Modem*)hellschreiberModem
{
	return hell ;
}

- (Modem*)cwModem
{
	return cw ;
}

- (Modem*)mfskModem
{
	return mfsk ;
}

- (Modem*)sitorModem
{
	return sitor ;
}

- (QSO*)QSOData
{
	return qso ;
}

//	v0.97
- (IBAction)openTableView:(id)sender 
{
	if ( [ self selectedModem ] == [ self pskModem ] ) {
		[ (PSK*)[ self pskModem ] openPSKTableView:YES ] ;
	}
	else NSBeep() ;
}

//	v0.97
- (IBAction)closeTableView:(id)sender 
{
	if ( [ self selectedModem ] == [ self pskModem ] ) {
		[ (PSK*)[ self pskModem ] openPSKTableView:NO ] ;
	}
	else NSBeep() ;
}

//	v0.97
- (IBAction)nextStationInTableView:(id)sender
{
	if ( [ self selectedModem ] == [ self pskModem ] ) {
		[ (PSK*)[ self pskModem ] nextStationInTableView ] ;
	}
	else NSBeep() ;
}

//	v1.01c
- (IBAction)previousStationInTableView:(id)sender
{
	if ( [ self selectedModem ] == [ self pskModem ] ) {
		[ (PSK*)[ self pskModem ] previousStationInTableView ] ;
	}
	else NSBeep() ;
}

@end
