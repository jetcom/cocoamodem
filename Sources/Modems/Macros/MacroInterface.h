//
//  MacroInterface.h
//  cocoaModem
//
//  Created by Kok Chen on 11/20/04.
//

#ifndef _MACROINTERFACE_H_
	#define _MACROINTERFACE_H_

	#import <Cocoa/Cocoa.h>
	#include "Modem.h"

	@class MacroSheet ;
	
	@interface MacroInterface : Modem {
		IBOutlet id messageMatrix ;
		
		//  Macro sheets (normal, option and shift-option RTTY macros)
  		MacroSheet *macroSheet[3] ;
		int currentSheet ;
		int check ;
		Boolean exclusionLicense ;
		int exclusionCount ;
	}

	- (IBAction)showMacroSheet:(id)sender ;
	- (IBAction)transmitMessage:(id)sender ;

	- (void)initMacros ;
	- (void)updateMacroButtons ;
	- (void)updateModeMacroButtons ;
	- (void)executeMacroString:(NSString*)macro ;
	- (void)executeMacro:(int)index sheetNumber:(int)n ;
	- (void)executeMacro:(int)index macroSheet:(MacroSheet*)sheet fromContest:(Boolean)fromContest ;
	- (void)executeMacroInSelectedSheet:(int)index ;
	
	- (MacroSheet*)macroSheet:(int)index ;
	- (void)setMacroSheet:(MacroSheet*)sheet index:(int)i ;

	@end

#endif
