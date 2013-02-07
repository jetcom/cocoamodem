//
//  ModemEqualizer.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/29/06.
	#include "Copyright.h"


#import "ModemEqualizer.h"
#include <math.h>
#include "ModemEqualizerPlot.h"
#include "Plist.h"
#include "Preferences.h"


@implementation ModemEqualizer

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initSheetFor:(NSString*)name
{
	NSRect rect ;
	
	self = [ super init ] ;
	if ( self ) {
		deviceName = [ [ NSString alloc ] initWithString:name ] ;
		if ( [ NSBundle loadNibNamed:@"ModemEqualizer" owner:self ] ) {   
			rect = [ view bounds ] ;
			[ self setFrame:rect display:NO ] ;
			[ [ self contentView ] addSubview:view ] ;
			if ( power ) [ self setFlatResponse ] ;	
		}
	}
	return self ;
}

- (float)interpolate:(float)v
{
	int i ;
	
	i = v/25 + 0.5 ;
	if ( i < 0 ) i = 0; else if ( i > 112 ) i = 112 ;
	return interpolated[i] ;
}

- (float)interpolateRough:(float)v
{
	int i ;
	float u, y1, y2 ;
	
	i = v/100 ;
	i = i/2 ;
	y1 = response[i] ;
	y2 = response[i+1] ;
	
	u = v/100 - i*2 ;
	u *= 0.5 ;
	
	return y2*u + y1*( 1.0-u ) ;
}

- (void)setResponseFromMatrix
{
	int i, j ;
	float raw[15], logv[81], maxv, state ;
	
	//  set response, limiting below 400 Hz and above 2.4 kHz and also limiting to 3 dB.
	for ( i = 2; i < 13; i++ ) {
		raw[i] = [ [ power cellAtRow:i-2 column:0 ] floatValue ] ;
		// sanity check
		if ( raw[i] <= 0.01 ) raw[i] = 0.01 ;
	}
	raw[0] = raw[1] = raw[2] ;
	raw[14] = raw[13] = raw[12] ;
	
	maxv = -100 ;
	for ( i = 0; i < 15; i++ ) if ( raw[i] > maxv ) maxv = raw[i] ;
	for ( i = 0; i < 15; i++ ) {
		raw[i] /= maxv ;
		if ( raw[i] < 0.43 ) raw[i] = 0.43 ;		//  limit to 3.5 dB worth of adjustment
	}
	
	//  get sqrt (voltage response)
	for ( i = 0; i < 15; i++ ) response[i] = sqrt( 1.0/raw[i] ) ;

	//  roughly interpolate into 25 hz resolution
	for ( i = 0; i < 113; i++ ) interpolated[i] = [ self interpolateRough:i*25.0 ] ;

	// Gaussian filter
	for ( j = 0; j < 4; j++ ) {
		//  low pass
		state = interpolated[0] ;
		for ( i = 0; i < 113; i++ ) {
			state = state*0.2 + interpolated[i]*0.8 ;
			interpolated[i] = state ;
		}
		//  symmetricize
		state = interpolated[112] ;
		for ( i = 112; i >= 0; i-- ) {
			state = state*0.2 + interpolated[i]*0.8 ;
			interpolated[i] = state ;
		}
	}
	if ( plot ) {
		for ( i = 0; i < 81; i++ ) logv[i] = 20.0*log10( [ self interpolate:400.0+25.0*i ] ) ;
		[ plot setResponse:logv ] ;
		[ plot display ] ;
	}
}

//  returns amplitude (between 0.4 and 2.5) for a given frequency
//  this value should not drop much below 1.0 or rise much above 2.0. 
- (float)amplitude:(float)frequency
{
	float v ;
	
	v = [ self interpolate:frequency ] ;
	if ( v < 0.8 ) v = 0.8 ; else if ( v > 2.5 ) v = 2.5 ;
	return v ;
}

- (void)setFlatResponse
{
	int i ;
	
	for ( i = 0; i < 11; i++ ) {
		[ [ power cellAtRow:i column:0 ] setFloatValue:1.0 ] ;
	}
	[ self setResponseFromMatrix ] ;
}

- (void)showMacroSheetIn:(NSWindow*)window
{
	controllingWindow = window ;
	[ NSApp beginSheet:self modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil ] ;
}

- (IBAction)done:(id)sender
{
	[ self setResponseFromMatrix ] ;
	[ NSApp endSheet:self ] ;
	if ( controllingWindow ) [ self orderOut:controllingWindow ] ;
}

- (IBAction)responseUpdated:(id)sender
{
	[ self setResponseFromMatrix ] ;
}

//  plist
- (void)setupDefaultPreferences:(Preferences*)pref
{
	NSArray *array ;
	NSNumber *number[11], *defaultNumber ;
	int i ;
	
	defaultNumber = @1.0f ;
	for ( i = 0; i < 11; i++ ) number[i] = defaultNumber ;
	
	array = [ NSArray arrayWithObjects:number count: 11 ] ; 
	[ pref setArray:array forKey:[ deviceName stringByAppendingString:kEqualizer ] ] ;
}

- (void)updateFromPlist:(Preferences*)pref
{
	NSArray *array ;
	NSNumber *number ;
	int i ;
	
	array = [ pref arrayForKey:[ deviceName stringByAppendingString:kEqualizer ] ] ;	
	for ( i = 0; i < 11; i++ ) {
		number = array[i] ;
		//  set format in cell to be 2 decimal places
		[ [ power cellAtRow:i column:0 ] setStringValue:[ NSString stringWithFormat:@"%.2f", [ number floatValue ] ] ] ;
	}
	[ self setResponseFromMatrix ] ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	NSArray *array ;
	NSNumber *number[11] ;
	int i ;
	
	//  update the dictionary from the sheet
	for ( i = 0; i < 11; i++ ) number[i] = @([ [ power cellAtRow:i column:0 ] floatValue ]) ;
	array = [ NSArray arrayWithObjects:number count: 11 ] ; 
	[ pref setArray:array forKey:[ deviceName stringByAppendingString:kEqualizer ] ] ;
}


@end
