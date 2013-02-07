//
//  PSKAuralMonitor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/11/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ModemAuralMonitor.h"

typedef struct {
	Boolean enabled ;
	Boolean active ;
	float centerFrequency ;
	CMDDA carrier ;
	float bandwidth ;
	float gain ;
	Boolean	isFloating ;
	float fixedFrequency ;
	CMDDA outputTone ;
	CMFIR *bandpassFilter ;
} AuralChannel ;
	

@interface PSKAuralMonitor : ModemAuralMonitor {
	Boolean pskSampling ;
	AuralChannel trxChannel[4] ;		//  channel == 2 is transmit channel, channel == 3 is widebandChannel
	int transmitChannel ;				//  receive channel (0,1) that we are transmitting on
}

- (void)importWidebandData:(CMPipe*)pipe ;
- (void)importTransmitData:(float*)array ; 

//	master controls
- (void)setMute:(Boolean)state ;
- (void)setMasterGain:(float)value ;
- (void)setModemActive:(Boolean)state ;

//  channel dependent controls
- (void)setEnable:(Boolean)state channel:(int)channel ;
- (void)setAttenuation:(float)atten channel:(int)channel ;
- (void)setFloating:(Boolean)state forChannel:(int)channel ;
- (void)setFixedFrequency:(float)freq forChannel:(int)channel ;
- (void)disactivateChannel:(int)channel ;

- (void)setCenterFrequency:(float)freq bandwidth:(float)bandwidth channel:(int)channel ;
- (void)transmitOnReceiver:(int)n ;

@end
