//
//  CMPipe.h
//   Filter (CoreModem)
//
//  Created by Kok Chen on 10/24/05.

#ifndef _CMPIPE_H_
	#define _CMPIPE_H_

	#import <Cocoa/Cocoa.h>
	#include "CoreFilterTypes.h"
	
	@interface CMPipe : NSObject {
		CMPipe *outputClient ;
		CMDataStream staticStream, *data ;
		Boolean isPipelined ;
	}
	
	//  Initializes the AudioPipe with an CMPipe client.
	//	inClient the CMPipe object which this CMPipe sends data to
	- (id)pipeWithClient:(CMPipe*)inClient ;
	
	//  Returns the CMPipe object which this CMPipe sends data to
	- (CMPipe*)client ;
	
	//  Sets the CMPipe client.
	//	inClient is the CMPipe object which this CMPipe sends data to
	- (void)setClient:(CMPipe*)inClient ;
	
	//  Sets the alternate CMPipe client.
	//	When the client is set this way, all output data is sent to the client's -importPipelinedData method
	- (void)setPipelinedClient:(CMPipe*)inClient ;
	
	//	Returns the storage used for the data stream
	- (CMDataStream*)stream ;
	
	//	Imports new data into the pipe.  This is the mechanism data is injected into a DSP stage.
	//	pipe the CMPipe object which contains the actual data stream
	- (void)importData:(CMPipe*)pipe ;
	
	//  Alternate importData port.  
	- (void)importPipelinedData:(CMPipe*)pipe ;

	//  Exports data into the client pipe.  Causes the client to be called with importData.
	- (void)exportData ;

	@end

#endif
