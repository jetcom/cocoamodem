//
//  Router.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/21/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "Router.h"
#import "Messages.h"
#import "MicroKeyer.h"
#import "RouterCommands.h"
#import "TextEncoding.h"
#include <IOKit/serial/IOSerialKeys.h>


@implementation Router

//  This establishes the interface to the µH Router for the PTTHub and FSKHub

//  Find all serial ports on the computer
//  collect the stream name and the Unix device path name for each one and return the number that is found
- (int)findPorts:(NSString**)path stream:(NSString**)stream max:(int)maxCount
{
    kern_return_t kernResult ; 
    mach_port_t masterPort ;
	io_iterator_t serialPortIterator ;
	io_object_t modemService ;
    CFMutableDictionaryRef classesToMatch ;
	CFTypeRef cfString ;
	int count ;

    kernResult = IOMasterPort( MACH_PORT_NULL, &masterPort ) ;
    if ( kernResult != KERN_SUCCESS ) return 0 ;
	
    classesToMatch = IOServiceMatching( kIOSerialBSDServiceValue ) ;
    if ( classesToMatch == NULL ) return 0 ;

	// get iterator for serial ports (ignore modems)
	CFDictionarySetValue( classesToMatch, CFSTR(kIOSerialBSDTypeKey), CFSTR(kIOSerialBSDRS232Type) ) ;
    kernResult = IOServiceGetMatchingServices( masterPort, classesToMatch, &serialPortIterator ) ;    
	// walk through the iterator
	count = 0 ;
	while ( ( modemService = IOIteratorNext( serialPortIterator ) ) && count < maxCount ) {
        cfString = IORegistryEntryCreateCFProperty( modemService, CFSTR(kIOTTYDeviceKey), kCFAllocatorDefault, 0 ) ;
        if ( cfString ) {
			stream[count] = [ [ NSString stringWithString:(NSString*)cfString ] retain ] ;
            CFRelease( cfString ) ;
			cfString = IORegistryEntryCreateCFProperty( modemService, CFSTR(kIOCalloutDeviceKey), kCFAllocatorDefault, 0 ) ;
			if ( cfString )  {
				path[count] = [ [ NSString stringWithString:(NSString*)cfString ] retain ] ;
				CFRelease( cfString ) ;
				count++ ;
			}
		}
        IOObjectRelease( modemService ) ;
    }
	IOObjectRelease( serialPortIterator ) ;
	return count ;
}

//  return the script back if succeded, return nil if failed
- (NSAppleScript*)executeScript:(NSAppleScript*)script reply:(NSAppleEventDescriptor**)eventDescriptorp
{
	NSDictionary *err ;
	
	*eventDescriptorp = [ script executeAndReturnError:&err ] ;
	if ( *eventDescriptorp != nil ) return script ;
	return nil ;
}

//	v0.89
- (void)makeListOfKeyers
{
	int i, routerRd, routerWr, keyerReadFileDescriptor, keyerWriteFileDescriptor, count ;
	char request[2], response[21] ;
	int openCommand[] = { OPENMICROKEYER, OPENCWKEYER, OPENDIGIKEYER } ;
	char *dummySerial[] = { "MK", "CK", "DK" } ;
	MicroKeyer *keyer ;
	
	[ keyers removeAllObjects ] ;
	//  open read/write ports to Router
	routerRd = open( "/tmp/microHamRouterRead", O_RDONLY ) ;
	routerWr = open( "/tmp/microHamRouterWrite", O_WRONLY ) ;	
	if ( routerRd > 0 && routerWr > 0 ) {
	
		if ( version > 1.79 ) {
			//  new µH Router
			for ( i = 0; i < 16; i++ ) {
				request[0] = KEYERID ;
				request[1] = i ;
				response[0] = 0 ;
				write( routerWr, request, 2 ) ;
				count = read( routerRd, response, 20 ) ;
				if ( response[0] == 0 ) break ;
				keyer = [ [ MicroKeyer alloc ] initWithKeyerID:response ] ;
				if ( keyer != nil ) [ keyers addObject:[ keyer autorelease ] ] ;									//  v0.92 sanity check
			}
		}
		else {
			//  try opening the three keyers
			//  if present, also open the PTT port to them v0.33
			for ( i = 0; i < 3; i++ ) {
				//  open a keyer (old style)
				obtainRouterPorts( &keyerReadFileDescriptor, &keyerWriteFileDescriptor, openCommand[i], routerRd, routerWr ) ;
				if ( keyerReadFileDescriptor > 0 && keyerWriteFileDescriptor > 0 ) {
					keyer = [ [ MicroKeyer alloc ] initWithReadFileDescriptor:keyerReadFileDescriptor writeFileDescriptor:keyerWriteFileDescriptor serialNumber:dummySerial[i] ] ;
					if ( keyer != nil ) [ keyers addObject:[ keyer autorelease ] ] ;								//  v0.92 sanity check
				}	
			}
		}
	}
	close( routerRd ) ;
	close( routerWr ) ;
}

- (Boolean)openRouter
{
	int i, ports ;
	char cstring[16] ;
	Boolean hasKeyer ;
	NSString *app, *name, *stream[32], *path[32] ;
	NSWorkspace *workspace ;
	
	launched = NO ;
	//  check for existence of µH Router
	name = [ NSString stringWithCString:cstring encoding:NSMacOSRomanStringEncoding ] ;
	workspace = [ NSWorkspace sharedWorkspace ] ;
	app = [ workspace absolutePathForAppBundleWithIdentifier:@"w7ay.mh Router" ] ;
	if ( app ) {
		//  check for microHam devices among the serial ports
		//  don't bother with launching the Router app otherwise
		hasKeyer = NO ;
		ports = [ self findPorts:&path[0] stream:&stream[0] max:32 ] ;
		for ( i = 0; i < ports; i++ ) {
			name = ( [ stream[i] length ] < 13 ) ? @"" : [ stream[i] substringToIndex:12 ] ;
			strcpy( cstring, [ name cStringUsingEncoding:kTextEncoding ] ) ;
			cstring[10] = 'M' ;	//  change usbserial-DK and usbserial-CK to MK
			if ( strcmp( cstring, "usbserial-MK" ) == 0 || strcmp( cstring, "usbserial-M2" ) == 0 ) hasKeyer = YES ;
			[ stream[i] release ] ;
			[ path[i] release ] ;
		}
		if ( hasKeyer ) {
			launched = [ self launch ] ;
			if ( launched ) {
				//  v0.89
				NSAppleScript *routerVersionScript ;
				NSAppleEventDescriptor *event ;
				
				routerVersionScript = [ self loadScriptFor:@"routerVersion" ] ;
				if ( routerVersionScript ) {
					if ( [ self executeScript:routerVersionScript reply:&event ] ) {
						if ( event != nil ) {
							NSString *response = [ event stringValue ] ;
							if ( response ) {
								sscanf( [ response cStringUsingEncoding:kTextEncoding ],"%f", &version ) ;
							}
						}
					}
					[ self makeListOfKeyers ] ;
				}
			}
			return YES ;
		}
	}
	return NO ;
}

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		launched = NO ;
		version = 1.7 ;
		keyers = [ [ NSMutableArray alloc ] init ] ;
		if ( ![ self openRouter ] ) return NO ;			//  this also create keyers array
	}
	return self ;
}

- (void)dealloc
{
	[ keyers release ] ;
	[ super dealloc ] ;
}

- (float)version
{
	return version ;
}

//	return array of MicroKeyer objects
- (NSArray*)connectedKeyers
{
	return keyers ;
}

- (Boolean)launch
{
	NSAppleScript *launchScript ;
	//  start up Router by using AppleScript and asking for a parameter
	//  Use AppleScript instead of NSWorkspace to guarantee router is running
	launchScript = [ self loadScriptFor:@"routerLaunchScript" ] ;
	
	if ( launchScript ) {
		NSAppleScript *script ;
		script = [ self executeScript:launchScript withError:"router launch" ] ;
		
		if ( script ) {
			[ launchScript release ] ;
			return YES ;
		}
	}
	return NO ;
}

- (Boolean)launched
{
	return launched ;
}

- (void)releaseKeyers
{
	[ keyers removeAllObjects ] ;
}

//  v0.66  user router script when cocoaModem quits
//  if defined, this is run instead of closeRouter
- (void)runQuitScript:(NSString*)filename
{
	if ( !launched ) /* never launched */ return ;	
	
	[ self releaseKeyers ] ;
	NSAppleScript *microhamRouterQuitScript = [ self loadScriptForPath:filename ] ;
	if ( microhamRouterQuitScript ) [ self executeScript:microhamRouterQuitScript withError:"microhamRouter" ] ;
}

- (void)closeRouter
{
	NSAppleScript *microhamRouterQuitScript ;
	
	[ self releaseKeyers ] ;
	microhamRouterQuitScript = [ self loadScriptFor:@"routerCloseScript" ] ;
	if ( microhamRouterQuitScript ) {
		[ self executeScript:microhamRouterQuitScript withError:"microhamRouter" ] ;
	}
}

- (NSAppleScript*)loadScriptForPath:(NSString*)path withErrorDictionary:(NSDictionary**)dict
{
	NSURL *url ;
	NSAppleScript *script ;

	script = nil ;	
	if ( [ path length ] > 0 ) {
		url = [ NSURL fileURLWithPath:path ] ;
		if ( !url || [ url isFileURL ] == NO ) return nil ;
		script = [ [ NSAppleScript alloc ] initWithContentsOfURL:url error:dict ] ;
		if ( !script ) {
			[ Messages appleScriptError:*dict script:(const char*)[ path cStringUsingEncoding:kTextEncoding ] ] ;
			return nil ;
		}
	}
	return script ;
}

//  load a script file with an arbitrary path name
- (NSAppleScript*)loadScriptForPath:(NSString*)path
{
	NSDictionary *dict ;
	NSAppleScript *result ;
	
	result = [ self loadScriptForPath:path withErrorDictionary:&dict ] ;
	return result ;
}

- (NSAppleScript*)loadScriptFor:(NSString*)scptFile withErrorDictionary:(NSDictionary**)dict
{
	NSString *path ;
	
	path = [ [ NSBundle mainBundle ] pathForResource:scptFile ofType:@"scpt" ] ;
	return [ self loadScriptForPath:path withErrorDictionary:dict ] ;
}

//  load a script file from the Application bundle
- (NSAppleScript*)loadScriptFor:(NSString*)scptFile
{
	NSDictionary *dict ;
	NSAppleScript *result ;
	
	result = [ self loadScriptFor:scptFile withErrorDictionary:&dict ] ;
	return result ;
}

//  return the script back if succeded, return nil if failed
- (NSAppleScript*)executeScript:(NSAppleScript*)script withError:(const char*)msg
{
	NSDictionary *err ;
	
	if ( [ script executeAndReturnError:&err ] ) {
		return script ;
	}
	// AppleScript error
	[ Messages appleScriptError:err script:msg ] ;
	return nil ;
}


@end
