//
//  AnalyzeConfig.h
//  cocoaModem
//
//  Created by Kok Chen on 2/22/05.
//

#ifndef _ANALYZECONFIG_H_
	#define _ANALYZECONFIG_H_

	#import <Cocoa/Cocoa.h>
	#include "RTTYConfig.h"


	@interface AnalyzeConfig : RTTYConfig {
		IBOutlet id fileRepeat ;
		IBOutlet id fileName ;
		IBOutlet id bitErrorField ;
		IBOutlet id characterErrorField ;
		IBOutlet id framingErrorField ;
		IBOutlet id characterCountField ;
		
		IBOutlet id sync ;

		//  plot
		IBOutlet id scope ;
		IBOutlet id scopePlotMode ;
		IBOutlet id scopeTriggerMode ;
		IBOutlet id scopeTriggerOnError ;
		
		int plotMode ;
		int triggerMode ;
		Boolean triggerOnError ;
		Boolean hasError, hasFramingError ;
				
		int bitCount ;
		int bitErrorCount ;
		int characterCount ;
		int characterErrorCount ;
		int framingErrorCount ;
	}
	
	//  AnalyzeScope
	- (IBAction)scopeModeChanged:(id)sender ;
	- (IBAction)scopeTriggerChanged:(id)sender ;
	- (IBAction)scopeTriggered:(id)sender ;
	
	- (void)accumBits:(int)bits ;
	- (void)accumErrorBits:(int)bits ;
	- (void)frameError:(int)position ;
	
	- (void)setSyncState:(int)state ;
	
	@end


#endif
