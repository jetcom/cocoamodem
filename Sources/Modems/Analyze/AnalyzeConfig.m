//
//  AnalyzeConfig.m
//  cocoaModem
//
//  Created by Kok Chen on 2/22/05.
	#include "Copyright.h"
//

#import "AnalyzeConfig.h"
#include "Analyze.h"
#include "AnalyzeScope.h"
#include "ModemSource.h"
#include "RTTYRxControl.h"
#include "VUMeter.h"


@implementation AnalyzeConfig

- (void)awakeFromModem:(RTTYConfigSet*)set rttyRxControl:(RTTYRxControl*)control
{
	[ super awakeFromModem:set rttyRxControl:control txConfig:nil ] ;
	plotMode = [ scopePlotMode selectedRow ] + [ scopePlotMode selectedColumn ]*4 ;
	triggerMode = [ scopeTriggerMode indexOfSelectedItem ] ;
	triggerOnError = [ scopeTriggerOnError indexOfSelectedItem ] != 0 ;
	hasError = hasFramingError = NO ;
}

- (void)updateColorsFromPreferences:(Preferences*)pref
{
	NSColor *color, *sent, *bg, *plot ;
		
	color = [ [ NSColor colorWithCalibratedRed:1 green:0.8 blue:0 alpha:1 ] retain ] ;
	sent = [ color retain ] ;
	bg = [ NSColor blackColor ] ;
	plot = [ [ NSColor colorWithCalibratedRed:0 green:1.0 blue:0 alpha:1 ] retain ] ;		
	//  set colors
	[ textColor setColor:color ] ;
	[ transmitTextColor setColor:sent ] ;
	[ backgroundColor setColor:bg ] ;
	[ plotColor setColor:plot ] ;
	[ modemObj setTextColor:color sentColor:sent backgroundColor:bg plotColor:plot forReceiver:[ modemRxControl uniqueID ] ] ;
}

- (void)retrieveActualColorPreferences:(Preferences*)pref rttyRxControl:(RTTYRxControl*)control
{
	//  do nothing since analyze has no preferences
}

- (void)soundFileStarting:(NSString*)str
{
	[ super soundFileStarting:str ] ;
	[ fileName setStringValue:[ str lastPathComponent ] ] ;
	bitCount = bitErrorCount = characterCount = characterErrorCount = framingErrorCount = 0 ;
	[ bitErrorField setStringValue:@"" ] ;
	[ characterErrorField setStringValue:@"" ] ;
	[ framingErrorField setStringValue:@"" ] ;
}

//  new character arrived
- (void)accumBits:(int)bits
{
	//  clear error state for this character
	hasFramingError = hasError = NO ;
	
	bitCount += bits ;
	characterCount++ ;
	[ characterCountField setIntValue:characterCount ] ;

	[ bitErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", bitErrorCount*1.0/bitCount ] ] ;
	[ characterErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", characterErrorCount*1.0/characterCount ] ] ;
	[ framingErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", framingErrorCount*1.0/characterCount ] ] ;
}

- (void)frameError:(int)position
{
	hasFramingError = YES ;
	framingErrorCount++ ;
	characterErrorCount++ ;
	characterCount++ ;
	[ characterErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", characterErrorCount*1.0/characterCount ] ] ;
	[ framingErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", framingErrorCount*1.0/characterCount ] ] ;
}

- (void)accumErrorBits:(int)bits
{
	hasError = ( bits != 0 ) ;
	hasFramingError = NO ;
	
	bitErrorCount += bits ;
	characterErrorCount++ ;
	
	[ bitErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", bitErrorCount*1.0/bitCount ] ] ;
	[ characterErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", characterErrorCount*1.0/characterCount ] ] ;
	[ framingErrorField setStringValue:[ NSString stringWithFormat:@"%5.2e", framingErrorCount*1.0/characterCount ] ] ;
}

//  data arrived from sound source
- (void)importData:(CMPipe*)pipe
{
/* @@@@
	if ( [ modemSource fileRunning ] ) {
		[ modemSource setPeriodic:NO ] ;		// turn off periodic sampling
		*data = *[ pipe stream ] ;
		[ self exportData ] ;
		[ vuMeter importData:pipe ] ;
		if ( scope ) {
			if ( triggerOnError ) {
				if ( hasError ) [ scope updatePlot:plotMode ] ;
				if ( triggerMode == 0 || !hasError ) [ modemSource nextSoundFrame ] ;
			}
			else {
				[ scope updatePlot:plotMode ] ;
				if ( triggerMode == 0 ) [ modemSource nextSoundFrame ] ; //  fetch next frame in aperiodic sampling mode
			}
		}
	}
	
	**** */
}

- (void)setSyncState:(int)state
{
	switch ( state ) {
	case 0:
	default:
		[ sync setBackgroundColor:[ NSColor redColor ] ] ;
		break ;
	case 1:
		[ sync setBackgroundColor:[ NSColor yellowColor ] ] ;
		break ;
	case 2:
		[ sync setBackgroundColor:[ NSColor greenColor ] ] ;
		break ;
	}
}

- (IBAction)scopeModeChanged:(id)sender
{
	plotMode = [ scopePlotMode selectedRow ] + [ scopePlotMode selectedColumn ] * 4 ;
	if ( scope ) [ scope updatePlot:plotMode ] ;
}

- (IBAction)scopeTriggerChanged:(id)sender
{
	triggerMode = [ scopeTriggerMode indexOfSelectedItem ] ;
	triggerOnError = [ scopeTriggerOnError indexOfSelectedItem ] != 0 ;
}

- (IBAction)scopeTriggered:(id)sender
{
	hasError = NO ;	// clear error conditions
	[ modemSource nextSoundFrame ] ;
}

@end
