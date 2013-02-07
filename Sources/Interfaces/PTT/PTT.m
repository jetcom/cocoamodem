//
//  PTT.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/11/06.
	#include "Copyright.h"
	
#import "PTT.h"
#import "Application.h"
#import "MicroKeyer.h"


#define	DKMENU	@"DIGI KEYER"
#define	MKMENU	@"microKEYER"
#define	CKMENU	@"CW KEYER"

@implementation PTT

- (id)initWithHub:(PTTHub*)inHub menu:(NSPopUpButton*)inMenu
{
	NSArray *microKeyers ;
	MicroKeyer *keyer ;
	DigitalInterfaces *digitalInterfaces ;
	DigitalInterface *interface ;
	Application *application ;
	NSString *name ;
	int i, cks, mks, dks, n ;
	
	self = [ super init ] ;
	if ( self ) {
		menu = inMenu ;
		hub = inHub ;
		[ hub registerPTT:self ] ;
		dummyInterfaces = [ [ NSMutableArray alloc ] init ] ;
		
		application = [ NSApp delegate ] ;	
		digitalInterfaces = [ application digitalInterfaces ] ;
		
		//	v0.89 -- set up PTT popup menu
		[ menu removeAllItems ] ;
		n = 0 ;
		
		interfaces[n++] = interface = [ digitalInterfaces voxInterface ] ;
		[ menu insertItemWithTitle:[ interface name ] atIndex:0 ] ;
		
		interfaces[n++] = interface = [ digitalInterfaces cocoaPTTInterface ] ;
		[ menu insertItemWithTitle:[ interface name ] atIndex:1 ] ;
		
		interfaces[n++] = interface = [ digitalInterfaces macLoggerDX ] ;
		[ menu insertItemWithTitle:[ interface name ] atIndex:2 ] ;

		interfaces[n++] = interface = [ digitalInterfaces userPTTInterface ] ;
		[ menu insertItemWithTitle:[ interface name ] atIndex:3 ] ;
		
		microKeyers = [ digitalInterfaces microHAMKeyers ] ;
		
		if ( [ microKeyers count ] <= 0 ) {
			//  use old style menu
			interfaces[n++] = interface = [ [ DigitalInterface alloc ] initWithName:DKMENU ] ;
			[ dummyInterfaces addObject:[ interface autorelease ] ] ;
			[ menu insertItemWithTitle:[ interface name ] atIndex:kMicroKeyerGroup ] ;

			interfaces[n++] = interface = [ [ DigitalInterface alloc ] initWithName:MKMENU ] ;
			[ dummyInterfaces addObject:[ interface autorelease ] ] ;
			[ menu insertItemWithTitle:[ interface name ] atIndex:kMicroKeyerGroup+1 ] ;

			interfaces[n++] = interface = [ [ DigitalInterface alloc ] initWithName:CKMENU ] ;
			[ dummyInterfaces addObject:[ interface autorelease ] ] ;
			[ menu insertItemWithTitle:[ interface name ] atIndex:kMicroKeyerGroup+2 ] ;
		}
		else {
			cks = [ digitalInterfaces numberOfCWKeyers ] ;
			mks = [ digitalInterfaces numberOfMicroKeyers ] ;
			dks = [ digitalInterfaces numberOfDigiKeyers ] ;
			for ( i = 0; i < [ microKeyers count ]; i++ ) {
				keyer = microKeyers[i] ;
				if ( [ keyer isDigiKeyer ] ) {
					name = ( dks > 1 ) ? [ NSString stringWithFormat:@"%@    %s", DKMENU, [ keyer keyerID ] ] : DKMENU ;
				}
				else if ( [ keyer isCWKeyer ] ) {
					name = ( cks > 1 ) ? [ NSString stringWithFormat:@"%@      %s", CKMENU, [ keyer keyerID ] ] : CKMENU ;
				}
				else {
					name = ( mks > 1 ) ? [ NSString stringWithFormat:@"%@   %s", MKMENU, [ keyer keyerID ] ] : MKMENU ;
				}
				[ menu insertItemWithTitle:name atIndex:kMicroKeyerGroup+i ] ;
				interfaces[n++] = keyer ;
			}
		}		
		[ menu selectItemAtIndex:0 ] ;		
		[ menu setAction:@selector(menuChanged:) ] ;	//  causes validateMenuItems to get called
		[ menu setTarget:self ] ;
	}
	return self ;
}

- (void)menuChanged:(id)sender
{
}

- (void)applicationTerminating
{
}

- (void)dealloc
{
	[ dummyInterfaces release ] ;
	[ super dealloc ] ;
}

- (DigitalInterface*)selectedInterface
{
	int index ;
	
	index = [ menu indexOfSelectedItem ] ;
	if ( index >= 0 ) {
		return interfaces[ index ] ;
	}
	return nil ;
}


//  v0.87 set keyer mode of a microHAM keyer
- (void)setKeyerMode:(int)mode
{
	DigitalInterface *interface ;
	
	interface = [ self selectedInterface ] ;
	if ( [ interface type ] != kMicroHAMType ) return ;
	if ( interface != nil ) {
		[ (MicroKeyer*)interface setKeyerMode:mode ] ;
	}
}

//  check if q-CW exists
- (Boolean)hasQCW
{
	DigitalInterface *interface ;
	
	interface = [ self selectedInterface ] ;
	if ( [ interface type ] != kMicroHAMType ) return NO ;
	return [ (MicroKeyer*)interface hasQCW ] ;
}

- (void)updateUserPTTName:(NSString*)name
{
	[ [ menu itemAtIndex:kUserPTTIndex ] setTitle:name ] ;
}

- (void)executePTT:(Boolean)state
{
	int index ;
	DigitalInterface *interface ;
	
	index = [ menu indexOfSelectedItem ] ;
	if ( index >= 0 ) {
		interface = interfaces[ index ] ;
		if ( interface != nil ) [ interface setPTTState:state ] ;
	}
}

- (void)selectItem:(NSString*)pttName
{
	int index ;
	DigitalInterface *interface ;
	
	[ menu selectItemWithTitle:pttName ] ;
	index = [ menu indexOfSelectedItem ] ;
	if ( index >= 0 ) {
		interface = interfaces[ index ] ;
		if ( [ interface connected ] == YES ) return ;
	}
	[ hub missingPTT:index name:pttName ] ;
	//  select VOX instead
	[ menu selectItemAtIndex:0 ] ;
}

- (NSString*)selectedItem
{
	return [ menu titleOfSelectedItem ] ;
}

// NSMenuValidation for PTT menu
-(BOOL)validateMenuItem:(NSMenuItem*)item
{
	int i ;
	DigitalInterface *interface ;
	
	for ( i = 0; i < kPTTItems; i++ ) {		
		if ( item == [ menu itemAtIndex:i ] ) {
			interface = interfaces[ i ] ;
			return ( interface == nil ) ? NO : [ interface connected ] ;
		}
	}
	return YES ;
}

@end
