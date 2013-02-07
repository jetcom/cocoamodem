//
//  WBCW.h
//  cocoaModem
//
//  Created by Kok Chen on Dec 1 2006.
//

#ifndef _WBCW_H_
	#define _WBCW_H_

	#include "WFRTTY.h"
	#include "CoreModemTypes.h"
	
	@interface WBCW : WFRTTY {
		IBOutlet id monitor ;	
		IBOutlet id risetimeSlider ;	
		IBOutlet id weightSlider ;	
		IBOutlet id	ratioSlider ;	
		IBOutlet id farnsworthSlider ;	
		
		IBOutlet id sidetoneSlider ;	
		IBOutlet id speedMenu ;	

		IBOutlet id modulationMenu ;				//  v0.85 -- J2A / OOK
		
		float transmittedBuffer[512] ;
		float sidetoneGain ;
		
		CMTonePair lockedTonePair[2] ;
	}
	
	- (IBAction)defaultSliders:(id)sender ;
	
	- (void)enableWide:(Boolean)state index:(int)n ;
	- (void)enablePano:(Boolean)state index:(int)n ;
	- (void)enableMonitor:(Boolean)state index:(int)n ;
	- (void)monitorLevel:(float)value index:(int)n ;
	- (void)sidebandChanged:(int)side index:(int)n ;
	- (void)changeSpeedTo:(int)speed index:(int)n ;
	- (void)changeSquelchTo:(float)squelch fastQSB:(float)fast slowQSB:(float)slow index:(int)n ;
	
	- (void)keepBreakinAlive:(int)duration ;
	- (void)sendSidetoneBuffer:(float*)buf ;
	
	@end

#endif
