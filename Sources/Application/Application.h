//
//  Application.h
//  cocoaModem
//
//  Created by Kok Chen on Sun May 16 2004.
//

#ifndef _APPLICATION_H_
	#define _APPLICATION_H_

	#import <Cocoa/Cocoa.h>
	#import "splash.h"
	#import "Speech.h"
	
	@class About ;
	@class AppDelegate ;
	@class AudioManager ;
	@class AuralMonitor ;
	@class Config ;
	@class DigitalInterfaces ;
	@class FSKHub ;
	@class UTC ;
	@class MacroScripts ;
	@class ModemManager ;
	@class ModemSleepManager ;
	@class StdManager ;
	@class UserInfo ;
	
	@interface Application : NSResponder {

		IBOutlet id stdManager ;	
		IBOutlet id quitMenu ;
		splash *splashScreen ;
		IBOutlet id macroTableWindow ;

		IBOutlet id resumeMenuItem ;
		IBOutlet id newMenuItem ;
		IBOutlet id recentMenuItem ;
		
		IBOutlet id qsoInterfaceEnableItem ;
		IBOutlet id qsoInterfaceItem ;
		IBOutlet id contestInterfaceItem ;
		
		IBOutlet id psk31RawInterfaceItem ;
		IBOutlet id psk31UnicodeInterfaceItem ;

		IBOutlet id voiceAssistMenuItem ;					//  v1.01b
		IBOutlet id directFrequencyAccessField ;			//  v1.02b
		
		ModemSleepManager *sleepManager ;
		
		Config *config ;
		UserInfo *userInfo ;
		
		//  local host IP	v0.47
		char localHostIP[32] ;

		DigitalInterfaces *digitalInterfaces ;				//  v0.89
		// shared FSK hub for entire application
		FSKHub *fskHub ;
		
		MacroScripts *macroScripts ;						//  v0.89
		
		//  v0.70 unicode support
		unsigned char jisToUnicode[ 65536*2 ] ;
		unsigned char unicodeToJis[ 65536*2 ] ;
		//  v0.71
		Boolean allowShiftJIS;
		
		//  v0.78 common aural monitor and AudioManager
		AuralMonitor *auralMonitor ;
		AudioManager *audioManager ;
		
		//  About panel
		About *about ;
		//  AppleScript
		AppDelegate *appleScript ;
		
		//  call/name selection
		NSTextView *selectedTextView ;
		char selectedString[34] ;			//  word clicked from exchange views

		Boolean contestMode ;
		unsigned int lastModifierFlags ;
		
		//  cocoaModem time ticks
		UTC *utc ;
		int minute ;
						
		//	v0.96d text to speech
		Speech *mainReceiverVoice ;
		Speech *subReceiverVoice ;
		Speech *transmitterVoice ;
		
		//	v1.01b
		Boolean voiceAssist ;
		Speech *assistVoice ;
		//	v1.02b
		NSString *speakAssistInfo ;
	}
	
	- (int)appLevel ;
	
	- (IBAction)showPreferences:(id)sender ;
	- (IBAction)showAboutPanel:(id)sender ;
	- (IBAction)showRTTYScope:(id)sender ;
	- (IBAction)showUserInfo:(id)sender ;
	- (IBAction)showContestInfo:(id)sender ;
	- (IBAction)showQSO:(id)sender ;
	- (IBAction)showConfig:(id)sender ;
	- (IBAction)showSoftRock:(id)sender ;
	- (IBAction)showAuralMonitor:(id)sender ;
	
	//  v1.02b, c, d
	- (IBAction)showDirectFrequencyAccess:(id)sender ;
	- (IBAction)directFrequencyAccess:(id)sender ;
	- (IBAction)speakCurrentFrequency:(id)sender ;
	- (IBAction)selectNextModem:(id)sender ;
	- (IBAction)selectPreviousModem:(id)sender ;
	- (IBAction)speakAlertInfo:(id)sender ;

	- (IBAction)switchToTransmit:(id)sender ;
	- (IBAction)switchToReceive:(id)sender ;
	- (IBAction)flushToReceive:(id)sender ;

	- (IBAction)selectInterfaceMode:(id)sender ;
	- (IBAction)swapInterfaceMode:(id)sender ;
	- (IBAction)qsoCommands:(id)sender ;
	
	//  v0.72	check for updates
	- (IBAction)checkForUpdate:(id)sender ;
	
	//  v0.96c	view select shortcuts
	- (IBAction)selectMainView:(id)sender ;
	- (IBAction)selectSubView:(id)sender ;
	- (IBAction)selectTransmitView:(id)sender ;
	
	//  v0.96d  speech
	- (IBAction)muteSpeech:(id)sender ;
	- (IBAction)spellSpeech:(id)sender ;		//  v1.00
	- (IBAction)selectQSOCall:(id)sender ;		//  v1.01a
	- (IBAction)selectQSOName:(id)sender ;		//  v1.01a
	- (IBAction)toggleVoiceAssist:(id)sender ;	//  v1.01b
	
	//  v0.78	aural monitor and AudioManager
	- (AuralMonitor*)auralMonitor ;
	- (AudioManager*)audioManager ;
	
	- (void)transferToQSOField:(int)t ;
	- (void)showSplash:(NSString*)msg ;
	
	- (void)switchInterfaceMode:(int)mode ;
	- (void)enableContestMenuItems:(Boolean)state ;
	- (void)closeConfigPanels ;
	
	- (float)OSVersion ;
	
	- (Boolean)contestModeState ;
	
	- (UTC*)clock ;
	- (const char*)localHostIP ;

	- (StdManager*)stdManagerObject ;
	- (DigitalInterfaces*)digitalInterfaces ;			//  v0.89
	- (FSKHub*)fskHub ;
	
	- (MacroScripts*)macroScripts ;						//  v0.89
	
	//  calls from ModemSleepManager
	- (void)putCodecsToSleep ;
	- (void)wakeCodecsUp ;

	- (UserInfo*)userInfoObject ;
	- (NSWindow*)mainWindow ;
	- (NSMenuItem*)qsoEnableItem ;

	- (unsigned int)keyboardModifierFlags ;
	
	- (void)setAppearancePrefs:(NSMatrix*)appearancePrefs ;	
	- (void)saveSelectedString:(NSString*)string view:(NSTextView*)view ;
	
	//  v0.70  Unicode support
	- (Boolean)useUnicodeForPSK ;
	- (void)setUseUnicodeForPSK:(Boolean)state ;
	- (unsigned char*)jisToUnicodeTable ;
	- (unsigned char*)unicodeToJisTable ;
	
	//	v0.96d text to speech
	- (void)setVoice:(NSString*)name channel:(int)channel ;
	- (void)setVoiceEnable:(Boolean)state channel:(int)channel ;
	- (void)addToVoice:(int)character channel:(int)channel ;
	- (void)clearVoiceChannel:(int)channel ;
	- (void)clearAllVoices ;
	- (void)setVerbatimSpeech:(Boolean)state channel:(int)channel ;
	
	//  v1.01b
	- (Boolean)voiceAssist ;
	- (Boolean)speakAssist:(NSString*)assist ;
	- (void)setDirectFrequencyFieldTo:(float)value ;
	- (void)updateDirectAccessFrequency ;
	- (void)flushSpeakAssist ;
	//  v1.02e
	- (void)setSpeakAssistInfo:(NSString*)string ;
	
	//  AppleScript support
	- (ModemManager*)interface ;
	- (void)changeInterfaceTo:(ModemManager*)which alternate:(Boolean)state ;

	- (NSApplicationTerminateReply)terminate ;
	
	@end

#endif
