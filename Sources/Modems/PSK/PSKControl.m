//
//  PSKControl.m
//  cocoaModem
//
//  Created by Kok Chen on Sun Sep 12 2004.
	#include "Copyright.h"
//

#import "PSKControl.h"
#import "PSK.h"
#import "PSKReceiver.h"


@implementation PSKControl

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initIntoView:(NSView*)view client:(Modem*)modem index:(int)inIndex
{
	self = [ super init ] ;
	if ( self ) {
		receiver = nil ;
		afcCheckboxState = NO ;
		squelchControlValue = 2.0 ;
		psk = (PSK*)modem ;
		index = inIndex ;
		pskMode = kBPSK31 ;
		if ( [ NSBundle loadNibNamed:@"PSKControl" owner:self ] ) {	
			// loadNib should have set up controlView connection
			if ( view && controlView ) [ view addSubview:controlView ] ;
			[ title setStringValue:[ NSString stringWithFormat:@"Xcvr %d", index+1 ] ] ;
			
			[ self setInterface:modeMenu to:@selector(modeMenuChanged) ] ;
			[ self setInterface:squelchControl to:@selector(squelchChanged) ] ;
			[ self setInterface:afcCheckbox to:@selector(afcCheckboxChanged) ] ;

			return self ;
		}
	}
	return nil ;
}

- (void)setPSKReceiver:(PSKReceiver*)rx
{
	receiver = rx ;
}

- (void)setAFCState:(Boolean)state
{
	afcCheckboxState = state ;
	[ afcCheckbox setState: (state) ? NSOnState : NSOffState ] ;
}

- (Boolean)afcEnabled
{
	return afcCheckboxState ;
}

- (float)squelchValue
{
	return squelchControlValue ;
}

- (void)setSquelchValue:(float)value
{
	[ squelchControl setFloatValue:value ] ;
	squelchControlValue = value ;
}

- (void)squelchChanged
{
	squelchControlValue = [ squelchControl floatValue ] ;
}

//  change mode to @"BPSK31", etc
- (void)changeModeToString:(NSString*)mode
{
	int i, n ;
	
	n = [ modeMenu numberOfItems ] ;
	for ( i = 0; i < n; i++ ) {
		if ( [ mode isEqualToString:[ modeMenu itemTitleAtIndex:i ] ] ) {
			[ modeMenu selectItemAtIndex:i ] ;
			[ self changeModeToIndex:i ] ;
		}
	}
}

static int pskIndexMap[] = { 0, 1, 0x8|1, 2, 3, 0x8|3 } ;

//  kBPSK31, etc, psk125 has the 0x8 bit turned on
- (int)pskMode
{
	int n ;
	
	//  v0.88  sanity check
	n = [ modeMenu indexOfSelectedItem ] ;	
	if ( n < 0 ) {
		n = 0 ;
		[ modeMenu selectItemAtIndex:0 ] ;
		[ receiver setPSKMode:pskIndexMap[0] ] ;
	}
	pskMode = pskIndexMap[ n ] ;	
	
	return pskMode ;
}


//  v0.64f  added psk125
//  change mode to index in the mode menu (0 = BPSK31, etc)
- (void)changeModeToIndex:(int)n
{
	//  PSK125 masquerades as PSK63, with the 0x8 flag turned on
	//  0,1,2 => 0,1,1
	//  3,4,5 => 2,3,3
	
	if ( n > 5 ) n = 0 ;		//  sanity check
		
	pskMode = pskIndexMap[ n ] ;
	[ receiver setPSKMode:pskMode ] ;
}

- (void)afcCheckboxChanged
{
	afcCheckboxState = ( [ afcCheckbox state ] == NSOnState ) ;
}

- (void)modeMenuChanged
{
	int indx ;
	
	if ( [ psk transmitting ] ) {
		//  don't allow mode switching while transmitting!  Stay with current setting
		//  v0.64f -- added psk125 menu
		switch ( pskMode & 0x3 ) {
		default:
		case kBPSK31:
			indx = 0 ;
			break ;
		case kBPSK63:
			indx = 1 ;
			break ;
		case kQPSK31:
			indx = 3 ;
			break ;
		case kQPSK63:
			indx = 5 ;
			break ;
		}
		if ( pskMode & 0x8 ) indx += 1 ;
		[ modeMenu selectItemAtIndex:indx ] ;
		return ;
	} 
	[ self changeModeToIndex:[ modeMenu indexOfSelectedItem ] ] ;
}

- (IBAction)setTxFrequency:(id)sender
{
	if ( receiver ) [ receiver setTransmitFrequencyToReceiveFrequency ] ;
}

@end
