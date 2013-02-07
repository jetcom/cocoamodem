//
//  CWRxControl.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/2/06.


#ifndef _CWRXCONTROL_H_
	#define _CWRXCONTROL_H_

	#import "RTTYRxControl.h"

	@class CWMonitor ;
	
	@interface CWRxControl : RTTYRxControl {
	
		IBOutlet id bandwidthMenu ;
		IBOutlet id wideButton ;
		IBOutlet id panoButton ;
		IBOutlet id levelSlider ;
		IBOutlet id monitorButton ;
		IBOutlet id speedMenu ;
		IBOutlet id cwSquelchSlider ;
		IBOutlet id reportSpeed ;
		IBOutlet id latencyMenu ;
		
		Boolean cwEnabled ;
		CWMonitor *cwMonitor ;
		int previousReportedSpeed ;
		
		CMTonePair lockedTonePair ;
	}
	
	- (void)setupCWReceiverWithMonitor:(CWMonitor*)sidetone ;
	- (void)enableCWReceiver:(Boolean)state ;
	- (void)setFrequency:(float)freq ;
	- (void)newClick:(float)delta ;
	
	- (void)setMonitorEnableButton:(Boolean)state ;
	- (void)setReportedSpeed:(int)wpm limited:(Boolean)limited ;
	- (void)speedChanged ;
	
	- (void)lockTonePairToCurrentTone ;
	
	@end

#endif
