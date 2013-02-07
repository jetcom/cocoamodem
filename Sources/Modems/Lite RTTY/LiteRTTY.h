//
//  LiteRTTY.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/2/07.

	#import <Cocoa/Cocoa.h>
	#import "WFRTTY.h"

	@interface LiteRTTY : WFRTTY {
		IBOutlet id txLockButton ;
		IBOutlet id oscilloscope ;
		Boolean controlWindowOpen ;
	}
	
	- (IBAction)openControlWindow:(id)sender ;
	- (IBAction)openSpectrumWindow:(id)sender ;
	
	- (void)showControlWindow:(Boolean)state ;
	
	- (void)drawSpectrum:(CMPipe*)pipe ;
	- (void)changeMarkersInSpectrum:(RTTYRxControl*)inControl ;
	

	@end
