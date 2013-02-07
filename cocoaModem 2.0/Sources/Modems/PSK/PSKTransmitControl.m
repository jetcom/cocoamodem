//
//  PSKTransmitControl.m
//  cocoaModem
//
//  Created by Kok Chen on Sun Sep 12 2004.
	#include "Copyright.h"
//

#import "PSKTransmitControl.h"
#import "PSK.h"
#import "PSKAuralMonitor.h"


@implementation PSKTransmitControl

- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (id)initIntoView:(NSView*)view client:(Modem*)modem
{
	self = [ super init ] ;
	if ( self ) {
		receiver = nil ;
		psk = (PSK*)modem ;
		index = 0 ;
		if ( [ NSBundle loadNibNamed:@"PSKTransmitControl" owner:self ] ) {	
			// loadNib should have set up controlView connection
			if ( view && controlView ) [ view addSubview:controlView ] ;
			index = [ [ vfoMenu selectedItem ] tag ] ;
			return self ;
		}
	}
	return nil ;
}

- (void)awakeFromNib
{
	[ self setInterface:vfoMenu to:@selector(vfoMenuChanged) ] ;	
}

- (int)selectedTransceiver
{
	int n ;
	PSKAuralMonitor *p ;
	
	n = [ [ vfoMenu selectedItem ] tag ] ;
	if ( psk ) {
		p = [ psk auralMonitor ] ;
		if ( p ) [ p transmitOnReceiver:n ] ;
	}
	return n ;
}

//  index == 0 or 1
- (void)selectTransceiver:(int)new
{
	int i, n, old ;

	old = [ [ vfoMenu selectedItem ] tag ] ;
	if ( old == new ) return ;
	
	n = [ vfoMenu numberOfItems ] ;
	for ( i = 0; i < n; i++ ) {
		if ( [ [ vfoMenu itemAtIndex:i ] tag ] == new ) {
			[ vfoMenu selectItemAtIndex:i ] ;
			[ psk transceiverChanged ] ;
			index = i ;
			return ;
		}
	}
}

- (void)vfoMenuChanged
{
	int newIndex ;
	
	if ( psk ) {
		newIndex = [ vfoMenu indexOfSelectedItem ] ;
		if ( [ psk transmitting ] ) {
			if ( index != newIndex ) [ vfoMenu selectItemAtIndex:index ] ;
		}
		else {
			[ psk transceiverChanged ] ;
			index = newIndex ;
		}
	}
}

@end
