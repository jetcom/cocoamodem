//
//  PSKControl.h
//  cocoaModem
//
//  Created by Kok Chen on Sun Sep 12 2004.
//

#ifndef _PSKCONTROL_H_
	#define _PSKCONTROL_H_

	#import <Cocoa/Cocoa.h>

	@class PSK ;
	@class PSKReceiver ;
	
	@interface PSKControl : NSObject {
		IBOutlet id controlView ;			//  receiver controls
		IBOutlet id title ;		
		IBOutlet id modeMenu ;
		IBOutlet id afcCheckbox ;
		IBOutlet id squelchControl ;
		
		PSK *psk ;
		PSKReceiver *receiver ;
		int index ;
		Boolean afcCheckboxState ;
		float squelchControlValue ;
		int pskMode ;
	}

	- (IBAction)setTxFrequency:(id)sender ;

	- (void)setPSKReceiver:(PSKReceiver*)rx ;
	- (Boolean)afcEnabled ;
	
	- (float)squelchValue ;
	- (void)setSquelchValue:(float)value ;
	
	- (void)changeModeToIndex:(int)pskMode ;
	- (void)changeModeToString:(NSString*)mode ;
	- (int)pskMode ;
	- (void)setAFCState:(Boolean)state ;
	
	@end
#endif
