//
//  PSKTransmitControl.h
//  cocoaModem
//
//  Created by Kok Chen on Sun Sep 12 2004.
//

#ifndef _PSKTRANSMITCONTROL_H_
	#define _PSKTRANSMITCONTROL_H_

	#import <Cocoa/Cocoa.h>
	
	@class Modem ;
	@class PSK ;
	@class PSKReceiver ;

	@interface PSKTransmitControl : NSObject {

		IBOutlet id controlView ;			//  transmitter controls
		IBOutlet id vfoMenu ;		
		
		PSK *psk ;
		PSKReceiver *receiver ;
		int index ;
	}
	- (id)initIntoView:(NSView*)view client:(Modem*)modem ;
	- (int)selectedTransceiver ;
	- (void)selectTransceiver:(int)number ;
	
	- (void)vfoMenuChanged ;

	@end
#endif
