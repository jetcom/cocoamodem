//
//  PTTHub.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 5/11/06.
	#include "Copyright.h"
	
	
#import "PTTHub.h"
#import "Application.h"
#import	"AppDelegate.h"				// v0.60 - App delegate
#import "Messages.h"
#import "PTT.h"
#import "Router.h"
#import "RouterCommands.h"
#import "TextEncoding.h"

#import "DigitalInterfaces.h"

#include <signal.h>


@implementation PTTHub

//  The PTT Hub handles all PTT requests from PTT objects.
//	Each modem interface (TxConfig) has its own PTT object.  Each PTT object calls this hub when they get used.

- (id)init
{			
	self = [ super init ] ;
	if ( self ) {
	
		application = [ NSApp delegate ] ;	
		digitalInterfaces = [ application digitalInterfaces ] ;
	
		//  catches SIGPIPE in case sleep wakeups don't reconnect.
		signal( SIGPIPE, sigpipe ) ;
		
		//  all PTT objects that use PTTHub
		clients = 0 ;	
		pttEngaged = NO ;

		//  make cocoaModem active even when other helper apps have been launched
		[ NSApp activateIgnoringOtherApps:YES ] ;
	}
	return self ;
}

- (void)registerPTT:(PTT*)ptt
{
	client[ clients++ ] = ptt ;
}

- (void)updateUserPTTScripts:(NSString*)newFolder
{
	int i ;
	NSString *name ;
	
	if ( [ [ digitalInterfaces userPTTInterface ] updateScriptsFromFolder:newFolder ] == YES ) {
		name = [ [ digitalInterfaces userPTTInterface ] folderName ] ;
		for ( i = 0; i < clients; i++ ) [ client[i] updateUserPTTName:name ] ;
	}
	else {
		for ( i = 0; i < clients; i++ ) [ client[i] updateUserPTTName:@"User Defined" ] ;
	}
}

//  called from a PTT device
//	This issues an alert if a PTT device is missing but will do it just once
- (void)missingPTT:(int)index name:(NSString*)name
{
	if ( missingAlertMessage[index] == YES ) return ;
	missingAlertMessage[index] = YES ;
	[ Messages alertWithMessageText:NSLocalizedString( @"missing ptt", nil ) informativeText:[ NSString stringWithFormat:@"PTT device %s is not found.", [ name cStringUsingEncoding:kTextEncoding ] ] ] ;
}


//  set up the audio routing for the microKeyer v0.33, for digiKeyer v0.51
//  1. open a new connection to the router
//  2. use this connection to open a control port
//  3. write the audio routing string to the control port
//  4. close the connection to the keyer
- (void)microKeyerSetupArray:(int*)array count:(int)count useDigitalModeOnlyForFSK:(Boolean)digitalModeOnlyForFSK
{
	//  v0.89  no longer used
	/*
	int routerRd, routerWr, writeConnect, readConnect, controlWrite, written, i, n ;
	char closeRequest = CLOSEKEYER ;
	unsigned char charArray[128] ;

	if ( router != nil ) {
		//  open new ports to read and write to the router
		routerRd = open( "/tmp/microHamRouterRead", O_RDONLY ) ;
		routerWr = open( "/tmp/microHamRouterWrite", O_WRONLY ) ;
		if ( routerRd > 0 && routerWr > 0 ) {
			//  open the keyer
			obtainRouterPorts( &readConnect, &writeConnect, OPENMICROKEYER, routerRd, routerWr ) ;
			if ( readConnect > 0 && writeConnect > 0 ) {
				obtainRouterPorts( nil, &controlWrite, OPENCONTROL, readConnect, writeConnect ) ;
				if ( controlWrite > 0 ) {
					if ( count > 0 ) {
						//  has microKeyer, send setup only if the string is not empty
						n = count ;
						if ( n > 128 ) n = 128 ;								// v0.51 -- allow larger setup array
						for ( i = 0; i < n; i++ ) charArray[i] = array[i] ;
						written = write( controlWrite, charArray, count ) ;
					}
					if ( !digitalModeOnlyForFSK ) {
						//  always use digital mode, set keyer mode to digital
						charArray[0] = 0x0a ;
						charArray[1] = 0x03 ;
						charArray[2] = 0x8a ;
						written = write( controlWrite, charArray, 3 ) ;
					}
				}
				//  terminate this connection to the router
				write( writeConnect, &closeRequest, 1 ) ;
				close( readConnect ) ;
				close( writeConnect ) ;
			}
			//  v0.51 -- set string for DIGIKEYER
			obtainRouterPorts( &readConnect, &writeConnect, OPENDIGIKEYER, routerRd, routerWr ) ;
			if ( readConnect > 0 && writeConnect > 0 ) {
				obtainRouterPorts( nil, &controlWrite, OPENCONTROL, readConnect, writeConnect ) ;
				if ( controlWrite > 0 ) {
					if ( count > 0 ) {
						//  has digiKeyer, send setup only if the string is not empty
						n = count ;
						if ( n > 128 ) n = 128 ;
						for ( i = 0; i < n; i++ ) charArray[i] = array[i] ;
						written = write( controlWrite, charArray, count ) ;
					}
					if ( !digitalModeOnlyForFSK ) {
						//  always use digital mode, set keyer mode to digital
						charArray[0] = 0x0a ;
						charArray[1] = 0x03 ;
						charArray[2] = 0x8a ;
						written = write( controlWrite, charArray, 3 ) ;
					}
				}
				//  terminate this connection to the router
				write( writeConnect, &closeRequest, 1 ) ;
				close( readConnect ) ;
				close( writeConnect ) ;
			}
			close( routerRd ) ;	
			close( routerWr ) ;
		}
	}
	*/
}

void sigpipe( int sigraised )
{
}

@end
