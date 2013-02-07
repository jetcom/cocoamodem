//
//  Speech.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/9/12.
//  Copyright 2012 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define	kVoiceBuffers	256

@interface Speech : NSObject {
	NSSpeechSynthesizer *synth ;
	NSMutableString *buffer[kVoiceBuffers] ;
	NSMutableString *lettersWord ;
	NSMutableDictionary *enunciate ;
	NSArray *enunciateKeys ;
	int producer, consumer ;
	int previousLetter ;
	Boolean needsSound ;
	Boolean enabled ;
	Boolean verbatim ;
	Boolean muted ;
	Boolean deferredDot ;
	Boolean deferredMinus ;
	Boolean useSpell ;
	NSTimer *timer ;
}

- (id)initWithVoice:(NSString*)voiceId ;
- (void)setVoice:(NSString*)name ;
- (void)setVoiceEnable:(Boolean)state ;
- (void)addToVoice:(int)ascii ;
- (void)clearVoice ;
- (void)setVerbatim:(Boolean)state ;
- (void)setRate:(float)rate ;
- (void)setMute:(Boolean)state ;
- (void)speak:(NSString*)string ;
- (void)queuedSpeak:(NSString*)string ;

- (void)setSpell:(Boolean)state ;


@end
