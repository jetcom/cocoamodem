//
//  RTTYAuralMonitor.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/8/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ModemAuralMonitor.h"

@interface RTTYAuralMonitor : ModemAuralMonitor {
	
	Boolean monitorIsActive ;
	
	Boolean rxMonitorOn ;
	Boolean rxUseFloatingTone ;
	float rxGain, rxBaseGain ;
	
	Boolean rxBackgroundOn ;
	float rxBackgroundGain, rxBackgroundBaseGain ;
	float backgroundBuffer[512] ;
	
	Boolean txMonitorOn ;
	Boolean txUseFloatingTone ;
	float txGain, txBaseGain ;
	
	float auralWindow[512] ;
	float clickBufferBeep[512] ;				//  v0.88c
	Boolean transmitEngaged ;					//  v0.88
	NSTimer *pttToneTimer ;						//  v0.88
	int	pttBitIndex ;							//  v0.88
	int pttSampleIndex ;
	
	float pttDDA, pttDDAdelta ;					//  v0.88
	float pttMark, pttSpace ;					//  v0.88
	int baudot ;								//  v0.88
	int transmitType ;							//  v0.88
	Boolean emitBeep ;							//  v0.88c
	float clickVolume ;							//  v0.88c
	Boolean useSoftLimiting ;					//  v0.88c
	float agcVoltage ;							//  v0.88c
	
	CMDDA receiveCarrier ;
	CMDDA transmitCarrier ;
	CMDDA receiveAuralCenter ;
	CMDDA transmitAuralCenter ;
}

- (void)setTransmitState:(Boolean)state transmitType:(int)transmitType ;	//  v0.88

- (void)makeFilters ;
- (void)setTonePair:(const CMTonePair*)pair ;
- (void)setTransmitTonePair:(const CMTonePair*)tonepair ;

- (void)setDemodulatorActive:(Boolean)state ;

- (void)setState:(Boolean)state source:(int)source ;
- (void)setGain:(float)gain source:(int)source ;
- (void)setAttenuation:(int)db source:(int)source ;
- (void)setOutputFrequency:(float)freq source:(int)source ;
- (void)setFloatingTone:(Boolean)state source:(int)source ;
- (void)setClickVolume:(float)volume ;
- (void)setClickPitch:(float)pitch ;
- (void)setSoftLimit:(Boolean)state ;

- (void)emitBeep ;						//  v0.88
- (void)clickBufferCleared ;			//  v0.89

- (void)newWidebandData:(CMPipe*)pipe ;
- (void)newBandpassFilteredData:(float*)array scale:(float)scale fromReceiver:(Boolean)fromReceiver ;

- (void)newWidebandBuffer:(float*)array ;

@end
