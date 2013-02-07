//
//  RTTYMonitor.h
//  cocoaModem
//
//  Created by Kok Chen on Sat Jun 05 2004.
//

#ifndef _RTTYMONITOR_H_
	#define _RTTYMONITOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"
	#include "CoreModemTypes.h"

	typedef struct {
		CMTappedPipe *pipe ;
		int index ;
		Boolean enableBaudotMarkers ;
		int timebase ;
	} Connection ;
	
	@interface RTTYMonitor : CMTappedPipe {
		IBOutlet id scopeView ;
		IBOutlet id styleArray ;
		IBOutlet id sourceArray ;
		IBOutlet id specLabel ;
		Connection connection[8] ;
		Connection *selected ;
		int currentStyle ;
		int timebase ;
		Boolean enableBaudotMarkers ;
	}
	
	- (IBAction)styleChanged:(id)sender ;
	- (IBAction)sourceChanged:(id)sender ;

	- (void)setTonePairMarker:(const CMTonePair*)tonepair ;
	- (void)showWindow ;
	- (void)hideScopeOnDeactivation:(Boolean)hide ;
	- (void)setTitle:(NSString*)title ;
	- (void)setPlotColor:(NSColor*)color ;
	
	- (void)connect:(int)button to:(CMTappedPipe*)pipe title:(NSString*)name baudotMarkers:(Boolean)enableBaudot timebase:(int)timebase ;
	
	@end

#endif
