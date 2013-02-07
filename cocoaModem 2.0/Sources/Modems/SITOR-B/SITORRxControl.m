//
//  SITORRxControl.m
//  cocoaModem
//
//  Created by Kok Chen on 1/24/05.
	#include "Copyright.h"
//

#import "SITORRxControl.h"
#import "CoreModemTypes.h"
#import "CrossedEllipse.h"
#import "SITOR.h"
#import "Modem.h"
#import "RTTYConfig.h"
#import "RTTYInterface.h"
#import "RTTYModulator.h"
#import "RTTYMonitor.h"
#import "RTTYRxControl.h"
#import "RTTYWaterfall.h"
#import "SITORReceiver.h"
#import "Spectrum.h"
#import "TextEncoding.h"


@implementation SITORRxControl

//  Client is DualRTTY or RTTY

//  Usually not initialized here, but at awakeFromNib
- (id)initIntoView:(NSView*)view client:(Modem*)modem index:(int)index
{
	self = [ super init ] ;
	if ( self ) {
		if ( [ NSBundle loadNibNamed:@"SITORRxControl" owner:self ] ) {	
			// loadNib should have set up controlView connection
			if ( view && controlView ) {
				[ view addSubview:controlView ] ;
				if ( auxWindow ) [ auxWindow setTitle: (index == 0) ? @"Receiver A" : @"Receiver B" ] ;
				[ self setupWithClient:modem index:index ] ;
				if ( activeIndicator ) [ activeIndicator setBackgroundColor:[ NSColor grayColor ] ] ;
				return self ;
			}
		}
	}
	return nil ;
}

- (void)awakeFromNib
{
	spectrumView = nil ;
	waterfall = nil ;
	monitor = nil ;
	tonePair.mark = 2125 ;
	tonePair.space = 2295 ;
	tonePair.baud = 100.0 ;
	sideband = 0 ;
	rxPolarity = txPolarity = 0 ;
	activeTransmitter = NO ;
	vfoOffset = ritOffset = 0 ;
	
	[ self setInterface:bandwidthMatrix to:@selector(bandwidthChanged) ] ;
	[ self setInterface:demodulatorModeMatrix to:@selector(demodulatorModeChanged) ] ;
	[ self setInterface:squelchSlider to:@selector(squelchChanged) ] ;
	
	[ self setInterface:rxPolarityButton to:@selector(rxPolarityChanged) ] ;
	[ self setInterface:markFreq to:@selector(tonePairChanged) ] ;
	[ self setInterface:shiftField to:@selector(shiftChanged) ] ;
	[ self setInterface:baudRateBox to:@selector(baudRateChanged) ] ;

	[ self setInterface:memorySelectMenu to:@selector(tonePairSelected) ] ;
	[ self setInterface:inputAttenuator to:@selector(inputAttenuatorChanged) ] ;
	
	onColor = [ NSColor greenColor ] ;
	waitColor = [ NSColor yellowColor ] ;
	fecColor = [ NSColor orangeColor ] ;
	errorColor = [ NSColor redColor ] ;
	offColor = [ NSColor grayColor ] ;
	
	[ self setIndicator:kSITOROff ] ;
}

- (void)setIndicator:(int)state
{
	NSColor *color ;
	
	switch ( state ) {
	default:
	case kSITOROff:
		color = offColor ;
		break ;
	case kSITORWait:
		color = waitColor ;
		break ;
	case kSITOROn:
		color = onColor ;
		break ;
	case kSITORFEC:
		color = fecColor ;
		break ;
	case kSITORError:
		color = errorColor ;
		break ;
	}
	if ( lockedIndicator ) [ lockedIndicator setBackgroundColor:color ] ;
}

//  set up to use SITOR Receiver
- (void)setupWithClient:(Modem*)modem index:(int)index
{
	uniqueID = index ;
	client = (RTTY*)modem ;
	[ self setupDefaultFilters ] ;
	
	receiver = [ [ SITORReceiver alloc ] initReceiver:index modem:modem ] ;
	//  set up receiver connections
	monitor = [ [ RTTYMonitor alloc ] init ] ;
	[ monitor setTitle:@"SITOR Monitor" ] ;
	
	[ (SITORReceiver*)receiver setControl:self ] ;
	[ receiver setSquelch:squelchSlider ] ;
	[ receiver setReceiveView:exchangeView ] ;
	[ receiver setDemodulatorModeMatrix:demodulatorModeMatrix ] ;
	[ receiver setBandwidthMatrix:bandwidthMatrix ] ;
}

- (void)setupDefaultFilters
{
	CMTonePair defaultpair = { 2125.0, 2295.0, 45.45 } ;
	
	tonePair = defaultpair ;
	
	memory[0].mark = 2125 ;  memory[0].space = 2295 ;  memory[0].baud = 100.0 ;
	memory[1].mark = 2110 ;  memory[1].space = 2310 ;  memory[1].baud = 100.0 ;
	memory[2].mark = 1300 ;  memory[2].space = 1470 ;  memory[2].baud = 100.0 ;
	memory[3].mark = 1615 ;  memory[3].space = 1785 ;  memory[3].baud = 100.0 ;
	selectedTone = 0 ;
	
	[ self setTuningIndicatorState:YES ] ;
	//  receive views
	receiveTextAttribute = [ exchangeView newAttribute ] ;
	[ exchangeView setDelegate:client ] ;
}

//  ---- preferences ----
//  preferences maintainence, called from RTTYConfig.m
//  setup default preferences (keys are found in Plist.h)

/* local */
- (NSString*)toneString:(int*)f
{
	return [ NSString stringWithFormat:@"%d,%d,%d,%d", f[0], f[1], f[2], f[3] ] ;
}

/* local */
- (NSString*)baudString:(float*)f
{
	return [ NSString stringWithFormat:@"%.2f,%.2f,%.2f,%.2f", f[0], f[1], f[2], f[3] ] ;
}

/* local */
- (void)decodeToneString:(NSString*)str into:(int*)p
{
	sscanf( [ str cStringUsingEncoding:kTextEncoding ], "%d,%d,%d,%d", &p[0], &p[1], &p[2], &p[3] ) ;
}

/* local */
- (void)decodeBaudString:(NSString*)str into:(float*)p
{
	sscanf( [ str cStringUsingEncoding:kTextEncoding ], "%f,%f,%f,%f", &p[0], &p[1], &p[2], &p[3] ) ;
}

- (void)setupDefaultPreferences:(Preferences*)pref config:(ModemConfig*)cfg
{
	RTTYConfigSet *set ;
	NSRect frame ;
	float f[4] ;
	int i, g[4] ;
	
	config = cfg ;
	set = [ (RTTYConfig*)config configSet ] ;
	
	//  get sidebandMenu interface from RTTYConfig
	sidebandMenu = [ (RTTYConfig*)config sidebandMenu ] ;
	[ self setInterface:sidebandMenu to:@selector(tonePairChanged) ] ;

	[ pref setInt:selectedTone forKey:set->tone ] ;				// tone memorsideband = 0 ;
	[ pref setInt:0 forKey:set->sideband ] ;
	[ pref setInt:0 forKey:set->rxPolarity ] ;
	
	for ( i = 0; i < 4; i++ ) g[i] = memory[i].mark ;
	[ pref setString:[ self toneString:g ] forKey:set->mark ] ;
	
	for ( i = 0; i < 4; i++ ) g[i] = memory[i].space ;
	[ pref setString:[ self toneString:g ] forKey:set->space ] ;
	
	for ( i = 0; i < 4; i++ ) f[i] = memory[i].baud ;
	[ pref setString:[ self baudString:f ] forKey:set->baud ] ;
	
	[ pref setFloat:0.6 forKey:set->squelch ] ;

	if ( auxWindow && set->controlWindow ) {
		if ( uniqueID != 0 ) {
			//  offset sub control a little
			frame = [ auxWindow frame ] ;
			frame.origin.y += 20 ;
			frame.origin.x += 20 ;
			[ auxWindow setFrame:frame display:NO ] ;
		}
		[ pref setString:[ auxWindow stringWithSavedFrame ] forKey:set->controlWindow ] ;
	}
}

- (void)updateFromPlist:(Preferences*)pref config:(ModemConfig*)cfg 
{
	RTTYConfigSet *set ;
	float f[4] ;
	int i, g[4] ;
	
	config = cfg ;
	set = [ (RTTYConfig*)config configSet ] ;

	if ( auxWindow && set->controlWindow ) {
		[ auxWindow setFrameFromString:[ pref stringValueForKey:set->controlWindow ] ] ;
	}
	
	[ self decodeToneString:[ pref stringValueForKey:set->mark ] into:g ] ;
	for ( i = 0; i < 4; i++ ) memory[i].mark = g[i] ;
	
	[ self decodeToneString:[ pref stringValueForKey:set->space ] into:g ] ;
	for ( i = 0; i < 4; i++ ) memory[i].space = g[i] ;
	
	[ self decodeBaudString:[ pref stringValueForKey:set->baud ] into:f ] ;
	for ( i = 0; i < 4; i++ ) memory[i].baud = f[i] ;
	
	if ( receiver ) [ receiver setSquelchValue:[ pref floatValueForKey:set->squelch ] ] ;

	selectedTone = [ pref intValueForKey:set->tone ] ;	
	if ( selectedTone > 3 ) selectedTone = 0 ;
	[ memorySelectMenu selectItemAtIndex:selectedTone ] ;
	
	//  menus for tone pair polarities
	[ sidebandMenu selectItemAtIndex:[ pref intValueForKey:set->sideband ] ] ;
	[ rxPolarityButton setState:( [ pref intValueForKey:set->rxPolarity ] == 0 ) ? NSOffState : NSOnState ] ;
	//  tone pair table selection
	[ markFreq setIntValue:(int)memory[ selectedTone ].mark ] ;
	[ shiftField setIntValue:(int)( fabs( memory[ selectedTone ].space - memory[ selectedTone ].mark + 0.1 ) ) ] ;
	[ self setBaudRateField:memory[selectedTone].baud ] ;
	//  now set internal variables
	[ self fetchTonePairFromMemory ];
	[ self updateTonePairInformation ] ;
}
	
- (void)retrieveForPlist:(Preferences*)pref config:(ModemConfig*)cfg
{
	RTTYConfigSet *set ;
	float f[4] ;
	int i, g[4] ;
	
	config = cfg ;
	set = [ (RTTYConfig*)config configSet ] ;

	if ( auxWindow && set->controlWindow ) {
		[ pref setString:[ auxWindow stringWithSavedFrame ] forKey:set->controlWindow ] ;
	}
		for ( i = 0; i < 4; i++ ) g[i] = memory[i].mark ;
	[ pref setString:[ self toneString:g ] forKey:set->mark ] ;
	
	for ( i = 0; i < 4; i++ ) g[i] = memory[i].space ;
	[ pref setString:[ self toneString:g ] forKey:set->space ] ;
	
	for ( i = 0; i < 4; i++ ) f[i] = memory[i].baud ;
	[ pref setString:[ self baudString:f ] forKey:set->baud ] ;

	[ pref setInt:selectedTone forKey:set->tone ] ;		// tone memory
	[ pref setInt:sideband forKey:set->sideband ] ;
	[ pref setInt:rxPolarity forKey:set->rxPolarity ] ;

	if ( receiver ) [ pref setFloat:[ receiver squelchValue ] forKey:set->squelch ] ;
}

@end
