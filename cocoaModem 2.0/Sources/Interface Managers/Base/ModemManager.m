//
//  ModemManager.m
//  cocoaModem
//
//  Created by Kok Chen on 8/7/05.
	#include "Copyright.h"
//

#import "ModemManager.h"
#import "Application.h"
#import "AppDelegate.h"		//  NSApp delegate
#import "Messages.h"
#import "Modem.h"
#import "PSK.h"
#import "PTTHub.h"


@implementation ModemManager

Boolean gTestDump = NO ;

- (void)setupWindow:(Boolean)textured lite:(Boolean)lite
{
	NSWindow *window ;

	isLiteWindow = lite ;
	takesContestMenus = NO ;
	useWatchdog = YES ;
	preferences = nil ;					// v0.53b
	
	//  create hub for PTT actions
	ptt = [ [ PTTHub alloc ] init ] ;
	
	//  AppleScript support for window position
	windowLocked = NO ;
	
	//  select whether to use textured interface
	if ( lite ) tabview = tabviewLite ;
	else {
		tabview = ( textured ) ? tabviewTextured : tabviewUntextured ;
	}
	//  hide window for now
	window = [ tabview window ] ;
	if ( window ) {
		if ( lite ) [ window setLevel:NSNormalWindowLevel ] ;
		[ window orderOut:self ] ;
		//  delegate window for close/quit
		[ window setDelegate:self ] ;
	}
	//  set tabview delegate to ourself to capture tab changes
	[ tabview setDelegate:self ] ;
}

- (void)useSmoothPattern:(Boolean)state
{
	//  implemented in StdManager
}

//  v0.70
- (void)setUseShiftJIS:(Boolean)state
{
	[ (PSK*)psk setUseShiftJIS:state ] ;
}

//  v0.70
- (void)setUseRawForPSK:(Boolean)state
{
	[ (PSK*)psk setUseRawForPSK:state ] ;
}

//  v0.71
- (void)setAllowShiftJISForPSK:(Boolean)state
{
	[ application setAllowShiftJISForPSK:state ] ;
}

- (void)applicationTerminating
{
	int i ;
	
	[ self enableModems:NO ] ;
	for ( i = 0; i < installedModems; i++ ) {
		[ installedModem[i].modem applicationTerminating ] ;
	}
}

- (PTTHub*)pttHub
{
	return ptt ;
}

- (void)showSplash:(NSString*)msg
{
	[ application showSplash:msg ] ;
}

//  override by subclass
- (void)updateRTTYMacroButtons
{
}

//  override by subclass
- (void)createModems:(Preferences*)pref startModemsFromPlist:(Preferences*)modemList
{
	rtty = psk = dualRTTY = wfRTTY = cw = hell = analyze = selectedModem = nil ;
	softRock = nil ;
	installedModems = 0 ;
	preferences = [ pref retain ] ;			//  0.53b
	
	#ifdef MOVED
	log = nil ;
	//  create logging object
	if ( logView ) {
		log = [ [ Messages alloc ] initIntoView:logView ] ;
		[ log awakeFromApplication ] ;
	}
	#endif
}

- (void)dealloc
{
	if ( preferences ) [ preferences release ] ;
	[ super dealloc ] ;
}

//  override by subclass
- (void)updateModemSources
{
}

//  
- (void)activateModems:(Boolean)state
{
	if ( state == NO ) {
		[ self enableModems:NO ] ;
		[ [ tabview window ] orderOut:self ] ;
	}
	else {
		[ self enableModems:YES ] ;
		//  check to see if window should be visible  v0.64c
		if ( [ [ NSApp delegate ] windowIsVisible ] ) [ [ tabview window ] orderFront:self ] ;
	}
}

//  override by subclass
- (void)enableModems:(Boolean)state
{
}

- (Modem*)currentModem
{
	return selectedModem ;
}

- (Boolean)modemIsVisible:(Modem*)modem
{
	NSTabViewItem *currentTabViewItem = [ tabview selectedTabViewItem ] ;
	return ( currentTabViewItem == [ modem tabItem ] ) ;
}

//  Recursively clearing tooltips inside a view
- (void)clearToolTipsInView:(NSView*)view
{
	NSArray *sub ;
	int i, count ;
	
	if ( !view ) return ;
	[ view removeAllToolTips ] ;
	
	sub = [ view subviews ] ;
	count = [ sub count ] ;
	for ( i = 0; i < count; i++ ) [ self clearToolTipsInView:[ sub objectAtIndex:i ] ] ;
}

//  v0.53b -- for case where there is ony one modem interface
- (void)switchToInstalledModem:(InstalledModem*)installed
{
	Modem *newModem ;
	Boolean canTransmit, enableContest ;

	if ( !finishedCreatingModems ) return ;

	newModem = installed->modem ;
	enableContest = installed->contest ;
	canTransmit = ( !installed->receiveOnly ) ;

	if ( newModem ) {
		//  First check if the plist has already been updated
		//  if not, update the modem from the plist and also update th active state depeding on what the plist did to the active button
		
		/*** 0.53d no longer needed
		if ( installed->updatedFromPlist == NO ) {
			[ newModem updateFromPlist:preferences ] ;
			if ( enableContest ) [ self updateContestBar:(ContestInterface*)newModem ] ;
			//  turn on active if updateFromPlist has set the active button
			[ newModem updateSourceFromConfigInfo ] ;
			//  set the already-updated-from-Plist flag
			installed->updatedFromPlist = YES ;
		}
		*/		
		selectedModem = newModem ;
		[ selectedModem setVisibleState:YES ] ;
		if ( enableContest ) [ (ContestInterface*)selectedModem updateContestMacroButtons ] ;  // v0.21
		[ self setModemCanTransmit:canTransmit ] ;
	}
	if ( takesContestMenus ) [ application enableContestMenuItems:enableContest ] ;
}

//  0.31
//	0.53d also call -selectModemInTabViewItem
- (void)switchToTabView:(int)index
{
	int currentIndex ;
	
	currentIndex = [ tabview indexOfTabViewItem:[ tabview selectedTabViewItem ] ] ;
	
	if ( index == currentIndex ) {
		//  v0.78 - need to call selectModemInTabViewItem if the tab view had changed previously
		//			this happens when first launched into a tab view
		[ self selectModemInTabViewItem:[ tabview selectedTabViewItem ] ] ;
	}
	else {
		if ( index < 0 ) index = 0 ;
		[ tabview selectTabViewItemAtIndex:index ] ;
		//  v0.76 the above will already cause tabview:willselecttabviewitem: to run. see also v0.78 change above
		//  [ self selectModemInTabViewItem:[ tabview selectedTabViewItem ] ] ;
	}
}

//  select a modem by its reference.  Return NO if not possible.
- (Boolean)selectModem:(Modem*)modem
{
	NSTabViewItem *item ;
	int index ;
	
	item = [ modem tabItem ] ;
	if ( item ) {
		//  make sure it exists by looking for the index
		index = [ tabview indexOfTabViewItem:item ] ;
		if ( index != NSNotFound ) {
			[ self switchToTabView:index ] ;
			return YES ;
		}
	}
	return NO ;
}

//  select a modem by its tab view name
- (void)selectTabView:(NSString*)viewName
{
	int i, n ;
	NSString *tabName ;
	
	n = [ tabview numberOfTabViewItems ] ;

	for ( i = 0; i < n; i++ ) {
		tabName = [ [ tabview tabViewItemAtIndex:i ] label ] ;
		if ( [ tabName isEqualToString:viewName ] ) {
			[ self switchToTabView:i ] ;
			return ;
		}
	}
	//  v0.53b select first view when the original tab name is not found
	[ self switchToTabView:0 ] ;
}

//  return name of tab view item
- (NSString*)nameOfSelectedTabView
{
	return [ [ tabview selectedTabViewItem ] label ] ;
}

- (NSTabViewItem*)activeTabView
{
	return [ tabview selectedTabViewItem ] ;
}

//  override by subclass todisplay current modem config panel
- (void)showConfigPanel
{
}

- (void)showSoftRock
{
}

//  override by subclass to close all modem config panels
- (void)closeConfigPanels
{
}

- (Application*)appObject
{
	return application ;
}

//  return the window (textured or untextured) which is in use
- (NSWindow*)windowObject
{
	return [ tabview window ] ;
}

- (Boolean)okToQuit
{
	return YES ;
}

- (void)setModemCanTransmit:(Boolean)state
{
}

- (Boolean)useWatchdog
{
	return useWatchdog ;
}

- (void)setupDefaultPreferences:(Preferences*)pref
{
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
}

- (void)setAppearancePrefs:(NSMatrix*)appearancePrefs
{
}

- (void)setPSKPrefs:(NSMatrix*)pskPrefs
{
}

- (IBAction)showDiagnostic:(id)sender
{
	if ( log ) [ log show ] ;
}

//  v0.41
- (void)setModemAtTab:(NSTabViewItem*)tabViewItem
{
	int i ;
	Modem *newModem ;
	Boolean canTransmit, enableContest ;
	InstalledModem *installed ;
	
	//  flag new modem as active
	newModem = nil ;
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( [ installed->modem tabItem ] == tabViewItem ) {
			newModem = installed->modem ;
			enableContest = installed->contest ;
			canTransmit = ( !installed->receiveOnly ) ;
			break ;
		}
		installed++ ;
	}
	if ( newModem ) {
		selectedModem = newModem ;
		[ selectedModem setVisibleState:YES ] ;
		if ( enableContest ) [ (ContestInterface*)selectedModem updateContestMacroButtons ] ;  // v0.21
		[ self setModemCanTransmit:canTransmit ] ;
	}
	if ( takesContestMenus ) [ application enableContestMenuItems:enableContest ] ;
}

//  v0.53b this is overriden by StdManager to deferred updating of the contest bar (which does not exit in ModemManager)
- (void)updateContestBar:(ContestInterface*)modem
{
}

- (void)updateModemNow:(InstalledModem*)installed
{
	extern Boolean gSplashShowing ;
	Boolean splashShowing = gSplashShowing ;
	
	if ( installed->updatedFromPlist == NO ) {
		//  v0.78c [ selectedModem setVisibleState:NO ] ;
		if ( splashShowing == NO ) {
			[ waitProgressBar setUsesThreadedAnimation:YES ] ;
			[ waitPanel orderFront:self ] ;
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.1 ] ] ;
			[ waitProgressBar startAnimation:self ] ;
		}
		[ installed->modem updateFromPlist:preferences ] ;
		
		if ( installed->contest ) [ self updateContestBar:(ContestInterface*)installed->modem ] ;
		//  turn on active if updateFromPlist has set the active button
		if ( splashShowing == NO ) {
			[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.1 ] ] ;
		}
		[ installed->modem updateSourceFromConfigInfo ] ;
		//  set the already-updated-from-Plist flag
		installed->updatedFromPlist = YES ;
		if ( splashShowing == NO ) {
			[ waitProgressBar stopAnimation:self ] ;
			[ waitPanel orderOut:self ] ;
			//  v0.78c [ selectedModem setVisibleState:YES ] ;
		}
	}
}

//  0.53d --  called when tab changes or when the app starts (to select first modem)
- (void)selectModemInTabViewItem:(NSTabViewItem*)tabViewItem
{
	int i ;
	Modem *newModem ;
	Boolean canTransmit, enableContest ;
	InstalledModem *installed ;
	
	//  flag new modem as active
	newModem = nil ;
	enableContest = NO ;
	installed = &installedModem[0] ;
	for ( i = 0; i < installedModems; i++ ) {
		if ( [ installed->modem tabItem ] == tabViewItem ) {
			newModem = installed->modem ;
			enableContest = installed->contest ;
			canTransmit = ( !installed->receiveOnly ) ;
			break ;
		}
		installed++ ;
	}
	if ( newModem ) {
	
		//  v0.53b first check if the plist has already been updated
		//  if not, update the modem from the plist and also update the active state depeding on what the plist did to the active button
		
		if ( installed->updatedFromPlist == NO ) [ self updateModemNow:installed ] ;
		//  change visibility if needed
		if ( selectedModem != newModem ) {
				
			if ( selectedModem ) [ selectedModem setVisibleState:NO ] ;	//  disable previous modem
	
			selectedModem = newModem ;
			[ selectedModem setVisibleState:YES ] ;
			if ( enableContest ) [ (ContestInterface*)selectedModem updateContestMacroButtons ] ;  // v0.21
		}
		[ self setModemCanTransmit:canTransmit ] ;
		//  v0.87
		[ selectedModem switchModemIn ] ;
		
		//	v0.99
		SInt32 systemVersion = 0 ;
		Gestalt( gestaltSystemVersionMinor, &systemVersion ) ;
		
		if ( systemVersion > 4 ) {
			//  v0.96c
			[ selectTransmitMenuItem setHidden:installed->receiveOnly ] ;
			[ selectReceive1MenuItem setHidden:installed->numberOfReceiveViews < 1 ] ;
			[ selectReceive2MenuItem setHidden:installed->numberOfReceiveViews < 2 ] ;
		}
	}
	if ( takesContestMenus ) [ application enableContestMenuItems:enableContest ] ;
}

//	v1.02b
- (void)directSetFrequency:(float)freq
{
	if ( selectedModem == nil ) return ;
	[ selectedModem directSetFrequency:freq ] ;
}

//	v1.02b
- (float)selectedFrequency
{
	if ( selectedModem == nil ) return -10.0 ;
	return [ selectedModem selectedFrequency ] ;
}

//	v1.02c
- (void)speakModemSelection
{
	[ application speakAssist:[ [ tabview selectedTabViewItem ] label ] ] ;
	[ application speakAssist:@" interface selected." ] ;
}

//	v1.02c
- (void)tabView:(NSTabView *)view didSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	if ( view == tabview ) {
		[ self speakModemSelection ] ;
		if ( [ [ NSApp delegate ] appLevel ] == 0 ) [ [ NSApp delegate ] updateDirectAccessFrequency ] ; else [ [ [ NSApp delegate ] application ] updateDirectAccessFrequency ] ;
	}
}

//	v1.02c
- (void)selectNextModem
{
	int i, n ;
	
	i = [ tabview indexOfTabViewItem:[ tabview selectedTabViewItem ] ] ;
	n = [ tabview numberOfTabViewItems ] ;
	if ( i > ( n-2 ) ) [ tabview selectFirstTabViewItem:self ] ; else [ tabview selectNextTabViewItem:self ] ;
}

//	v1.02c
- (void)selectPreviousModem
{
	int i ;
	
	i = [ tabview indexOfTabViewItem:[ tabview selectedTabViewItem ] ] ;
	if ( i == 0 ) [ tabview selectLastTabViewItem:self ] ; else [ tabview selectPreviousTabViewItem:self ] ;
}

//  delegate of tabview
//  tracks which modem interface is being viewed.  sound streams activated/deativated here
- (void)tabView:(NSTabView*)view willSelectTabViewItem:(NSTabViewItem*)tabViewItem
{
	NSTabViewItem *oldTabViewItem = [ tabview selectedTabViewItem ] ;
	
	if ( !finishedCreatingModems ) return ;
	
	if ( view == tabview && tabViewItem != oldTabViewItem ) {
		[ application clearAllVoices ] ;		//  v0.96d	
		//  tab view changed
		[ application closeConfigPanels ] ;
		[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.05 ] ] ;
		[ self selectModemInTabViewItem:tabViewItem ] ;
	}
}

//  -- AppleScript support --

- (NSColor*)backgroundColor
{
	NSWindow *window ;
	
	window = [ tabview window ] ;
	if ( window == nil ) {
		return [ NSColor colorWithDeviceRed:1 green:1 blue:1 alpha:1 ] ;
	}
	return [ [ window backgroundColor ] colorUsingColorSpaceName:NSDeviceRGBColorSpace ] ;
}

- (void)setBackgroundColor:(NSColor*)inColor
{
	NSColor *color ;
	//int count ;
	NSWindow *window ;
	
	color = [ inColor colorUsingColorSpaceName:NSDeviceRGBColorSpace ] ;
	window = [ tabview window ] ;	
	[ window setBackgroundColor:color ] ;
}

- (NSPoint)windowPosition
{	
	return [ [ tabview window ] frame ].origin ;
}

- (void)setWindowPosition:(NSPoint)position
{
	NSRect frame ;
	
	frame = [ [ tabview window ] frame ] ;
	frame.origin = position ;
	[ [ tabview window ] setFrame:frame display:YES ] ;
	
}

//  AppleScript for showing/hide window
- (Boolean)windowState
{
	return [ [ tabview window ] isVisible ] ;
}

- (void)setWindowState:(Boolean)state ;
{
	NSWindow *window = [ tabview window ] ;
	
	if ( state == YES ) [ window makeKeyAndOrderFront:self ] ; else [ window orderOut:self ] ;
	[ [ NSApp delegate ] setWindowIsVisible:state ] ;
}

//  AppleScript select <interface> command
- (void)selectInterface:(NSScriptCommand*)command
{
}

- (void)resetWatchdog:(NSScriptCommand*)command
{
}

// contest band
- (int)band 
{
	return 0 ;
}

- (void)setBand:(int)data
{
}

- (NSData*)position
{
	short array[3] ;
	NSPoint point ;
	
	point = [ [ tabview window ] frame ].origin ;
	array[0] = point.y ;
	array[1] = point.x ;
	array[2] = 0 ;
	return [ NSData dataWithBytes:array length:4 ] ;
}

- (void)setPosition:(NSData*)data
{
	short *p = (short*)[ data bytes ] ;
	
	origin.x = p[1]-1 ;
	origin.y = p[0] ;
	[ [ tabview window ] setFrameOrigin:origin ] ;
}

- (Boolean)lock
{
	return windowLocked ;
}

- (void)setLock:(Boolean)state
{
	windowLocked = state ;
}

//  ---------- the following have been deprecated ---------
- (int)pskModulation
{
	if ( psk ) return [ (PSK*)psk getPskModulation ] ;
	return 0 ;
}

- (void)setPskModulation:(int)modulation
{
	if ( psk ) [ (PSK*)psk changePskModulationTo:modulation ] ;
}

- (int)modemMode
{
	Modem *modem ;
	
	modem = [ self currentModem ] ;
	if ( modem == rtty || modem == dualRTTY ) return RTTYInterfaceMode ;
	if ( modem == psk ) return PSKInterfaceMode ;
	
	return 0 ;
}

- (void)setModemMode:(int)interfaceMode
{
	int i, n ;
	NSString *str, *target ;
	
	switch ( interfaceMode ) {
	default:
	case RTTYInterfaceMode:
		target = @"RTTY" ;
		break ;
	case PSKInterfaceMode:
		target = @"PSK" ;
		break ;
	}
	n = [ tabview numberOfTabViewItems ] ;
	for ( i = 0; i < n; i++ ) {
		str = [ [ tabview tabViewItemAtIndex:i ] label ] ;
		if ( [ target isEqualTo:[ str uppercaseString ] ] ) {
			[ self switchToTabView:i ] ;
			break ;
		}
	}
}

- (IBAction)testDump:(id)sender 
{
	gTestDump = YES ;
}

@end
