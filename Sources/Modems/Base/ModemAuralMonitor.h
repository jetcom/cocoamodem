//
//  ModemAuralMonitor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/12/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "DestClient.h"
#import "AuralMonitor.h"
#import "CoreModemTypes.h"


@interface ModemAuralMonitor : DestClient {
	AuralMonitor *auralMonitor ;
	Boolean muted ;
	float masterGain ;
	Boolean demodulatorIsActive ;

	CMFIR *rxLowpassIFilter[2] ;
	CMFIR *rxLowpassQFilter[2] ;
	CMFIR *txLowpassIFilter[2] ;
	CMFIR *txLowpassQFilter[2] ;
	
	Boolean clickBufferActive ;							//  v0.88
	Boolean resampleClickBuffer ;						//  v0.88
}

- (void)setDDA:(CMDDA*)dda freq:(float)freq ;
- (CMAnalyticPair)updateDDA:(CMDDA*)dda ;


- (void)setClickBufferActive:(Boolean)state ;			//  v0.88
- (Boolean)clickBufferBusy ;							//  v0.88

- (void)setClickBufferResampling:(Boolean)state ;		//  v0.88
- (Boolean)performClickBufferResampling ;


#define	AURALRECEIVE	0
#define	AURALTRANSMIT	1
#define	AURALBACKGROUND	2
#define	AURALMASTER		3

@end
