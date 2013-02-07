//
//  PSKMonitor.h
//  cocoaModem
//
//  Created by Kok Chen on Tue Jul 27 2004.
//

#ifndef _PSKMONITOR_H_
	#define _PSKMONITOR_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilter.h"

	typedef struct {
		CMTappedPipe *pipe ;
		int index ;
	} Connection ;
	
	@interface PSKMonitor : CMTappedPipe {
		IBOutlet id scopeView ;
		IBOutlet id styleArray ;
		IBOutlet id sourceArray ;
		IBOutlet id specLabel ;
		Connection connection[8] ;
		Connection *selected ;
		int currentStyle ;
	}
	
	- (IBAction)styleChanged:(id)sender ;
	- (IBAction)sourceChanged:(id)sender ;

	- (void)showWindow ;
	- (void)hideScopeOnDeactivation:(Boolean)hide ;
	- (void)setTitle:(NSString*)title ;
	- (void)setPlotColor:(NSColor*)color ;
	
	- (void)connect:(int)button to:(CMTappedPipe*)pipe title:(NSString*)name ;
	
	@end

#endif
