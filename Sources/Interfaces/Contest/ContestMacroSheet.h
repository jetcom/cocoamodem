//
//  ContestMacroSheet.h
//  cocoaModem
//
//  Created by Kok Chen on 10/15/04.
//

#ifndef _CINTESTMACROSHEET_H_
	#define _CINTESTMACROSHEET_H_

	#import <Cocoa/Cocoa.h>
	#include "MacroSheet.h"
	
	@class ContestManager ;

	@interface ContestMacroSheet : MacroSheet {
		IBOutlet id contestSheetName ;
		
		NSString *messageStore ;
		NSString *captionStore ;
		ContestManager *contestManager ;
	}
	
	- (void)setName:(NSString*)str ;
	- (void)setMessages:(NSString*)mString ;
	- (NSString*)messages ;
	- (void)setCaptions:(NSString*)tString ;
	- (NSString*)captions ;
	
	- (void)showMacroSheet:(NSWindow*)window ;
	
	- (void)delegateTextChangesTo:(ContestManager*)manager ;
	
	@end

#endif
