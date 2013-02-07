//
//  CMFSKMixer.h
//  CoreModem
//
//  Created by Kok Chen on 10/25/05
//	(ported from cocoaModem, original file dated Wed Jun 09 2004)
//

#ifndef _CMFSKMIXER_H_
	#define _CMFSKMIXER_H_
	
	#import <Cocoa/Cocoa.h>
	#import "CoreModemTypes.h"
	#import "CMPipe.h"
	
	@class CMFSKDemodulator ;
	@class ModemConfig ;
	@class RTTYAuralMonitor ;
	
	@interface CMFSKMixer : CMPipe {
		float analyticSignal[2048] ;	// split complex signal
		//  local oscillators
		CMDDA mark, space ;
		CMDataStream mixerStream ;
		CMFSKDemodulator *demodulator ;
		RTTYAuralMonitor *auralMonitor ;
		
		ModemConfig *config ;								//  v0.88d
	}
	
	- (void)setTonePair:(const CMTonePair*)tonepair ;	
	- (void)setDemodulator:(CMFSKDemodulator*)client ;
	- (void)setConfig:(ModemConfig*)cfg ;					//  v0.88d
	- (void)setAuralMonitor:(RTTYAuralMonitor*)mon ;
	
	@end

#endif
