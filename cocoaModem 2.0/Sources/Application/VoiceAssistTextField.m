//
//  VoiceAssistTextField.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 4/13/12.
//  Copyright 2012 Kok Chen, W7AY. All rights reserved.
//

#import "VoiceAssistTextField.h"
#import "Application.h"
#import "AppDelegate.h"

@implementation VoiceAssistTextField


//  voice character
- (void)keyUp:(NSEvent*)event
{
	int ch ;
	
	ch = [ [ event characters ] characterAtIndex:0 ] ;
	switch ( ch ) {
	case 127:
		[ [ [ NSApp delegate ] application ] speakAssist:@"back spaced" ] ;
		break ;
	case '.':
		[ [ [ NSApp delegate ] application ] speakAssist:@" period " ] ;
		break ;
	default:
		[ [ [ NSApp delegate ] application ] speakAssist:[ NSString stringWithFormat:@" %c ", ch ] ] ;
		break ;
	}
	[ super keyUp:event ] ;
}

@end
