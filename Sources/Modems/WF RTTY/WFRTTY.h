//
//  WFRTTY.h
//  cocoaModem
//
//  Created by Kok Chen on Jan 11 2006.
//

#ifndef _WFRTTY_H_
	#define _WFRTTY_H_

	#import "RTTYInterface.h"
	
	@class RTTYWaterfall ;
	@class WFRTTYConfig ;

	@interface WFRTTY : RTTYInterface {
	
		IBOutlet id groupA ;
		IBOutlet id waterfallA ;
		IBOutlet id receiverA ;
		IBOutlet id configA ;
		IBOutlet id restoreToneA ;
		IBOutlet id dynamicRangeA ;

		IBOutlet id groupB ;
		IBOutlet id waterfallB ;
		IBOutlet id receiverB ;
		IBOutlet id configB ;
		IBOutlet id restoreToneB ;
		IBOutlet id dynamicRangeB ;

		IBOutlet id configTab ;
		IBOutlet id transmitSelect ;
		IBOutlet id transmitLock ;
		IBOutlet id contestTransmitSelect ;
		
		Boolean isLite ;
		
		RTTYWaterfall *waterfall[2] ;
		RTTYRxControl *control[2] ;
		WFRTTYConfig *configObj[2] ;
		Boolean txLocked[2] ;
		
		NSRect receiveFrame ;				//  frame of receive-only receiver
		NSRect transceiveFrame ;			//  frame of receive-transmit receiver
	}

	- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr nib:(NSString*)nib ;

	- (void)commonAwakeFromNib ;

	- (Boolean)transmitIsLocked:(int)index ;
	- (void)setTransmitLockButton:(int)index toState:(Boolean)locked ;
	- (void)transmitFrom:(int)index ;
	
	- (void)changeNonAuralTransmitStateTo:(Boolean)state ; // v0.88
	
	//  config
	- (int)configChannelSelected ;
	- (void)transmitSelectChanged ;
	
	- (void)setupDefaultPreferencesFromSuper:(Preferences*)pref ;
	- (Boolean)updateFromPlistFromSuper:(Preferences*)pref ;
	- (void)retrieveForPlistFromSuper:(Preferences*)pref ;
	
	- (void)showScope ;		//  v0.76
	
	@end

#endif
