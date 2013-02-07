//
//  Config.h
//  cocoaModem
//
//  Created by Kok Chen on Mon May 17 2004.
//

#ifndef _CONFIG_H_
	#define _CONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "Preferences.h"

	@class Application ;
	
	@interface Config : Preferences {
		IBOutlet id prefPanel ;
		IBOutlet id appearancePrefs ;		// NSMatrix of NSButtons
		IBOutlet id pskPrefs ;				// NSMatrix of NSButtons
		IBOutlet id modemPrefs ;			// NSMatrix of checkboxes
		Application *application ;
		
		IBOutlet id hideWindowCheckbox ;
		
		IBOutlet id autoConnectCheckbox ;
		
		IBOutlet id netAudioEnableCheckbox ;
		IBOutlet id netInputServiceMatrix ;
		IBOutlet id netInputAddressMatrix ;
		IBOutlet id netInputPortMatrix ;
		IBOutlet id netInputPasswordMatrix ;
		IBOutlet id netOutputServiceMatrix ;
		IBOutlet id netOutputAddressMatrix ;
		IBOutlet id netOutputPortMatrix ;
		IBOutlet id netOutputPasswordMatrix ;
		
		IBOutlet id userPTTFolderField ;
		IBOutlet id logScriptField ;

		//IBOutlet id microKeyerSetupString ;			//  v0.89
		IBOutlet id microKeyerModeCheckbox ;			//  v0.68
		IBOutlet id microKeyerQuitScriptField ;			//  v0.66
		
		IBOutlet id macroScript0 ;						//  v0.89
		IBOutlet id macroScript1 ;						//  v0.89
		IBOutlet id macroScript2 ;						//  v0.89
		IBOutlet id macroScript3 ;						//  v0.89
		IBOutlet id macroScript4 ;						//  v0.89
		IBOutlet id macroScript5 ;						//  v0.89

		IBOutlet id noOpenRouter ;						//  v0.89
		IBOutlet id quitWithAutoRouting ;				//  v0.93b
		
		//	v0.96d
		IBOutlet id mainReceiverSpeechCheckbox ;
		IBOutlet id mainReceiverSpeechMenu ;
		IBOutlet id mainReceiverVerbatimCheckbox ;
		IBOutlet id subReceiverSpeechCheckbox ;
		IBOutlet id subReceiverSpeechMenu ;
		IBOutlet id subReceiverVerbatimCheckbox ;
		IBOutlet id transmitterSpeechCheckbox ;
		IBOutlet id transmitterSpeechMenu ;	
		IBOutlet id transmitterVerbatimCheckbox ;
		NSArray *voices ;
		
		// v1.02d
		IBOutlet id voiceAssistSpeechMenu ;

		NSString *logScriptFileName ;
		NSString *microKeyerQuitScriptFileName ;
		NSString *pttScriptFolderName ;
		NSString *macroScriptFileName[6] ;
		
		Boolean rttyIsActive ;
		
		Boolean prefChanged ;
		Boolean usos ;						//  unshift on space
	}
	
	- (IBAction)prefPanelChanged:(id)sender ;
	
	- (IBAction)browseForLogScript:(id)sender ;
	- (IBAction)browseForMicroHamQuitScript:(id)sender ;
	- (IBAction)scriptFieldChanged:(id)sender ;
	
	- (IBAction)browseForMacroScript:(id)sender ;		//  v0.89
	- (IBAction)macroScriptFieldChanged:(id)sender ;	//  v0.89

	- (IBAction)browseForPTTFolder:(id)sender ;
	- (IBAction)pttFolderChanged:(id)sender ;

	- (void)awakeFromApplication ;
	
	- (void)showPreferencePanel:(id)sender ;

	- (id)initWithApp:(Application*)app ;

	- (void)setupMicroKeyer ;
	//- (NSTextField*)microKeyerSetupField ;		//  v0.89
	- (NSString*)microKeyerQuitScriptFileName ;		//  v0.66
	- (Boolean)quitWithAutoRouting ;				//  v0.93b set microHAM to auto routing when cocoaModem quits
	
	- (void)setupDefaultPreferences ;
	- (Boolean)updatePreferences ;
	
	- (NSString*)logScriptFile ;
	- (NSString*)pttScriptFolder ;
	
	@end

#endif
