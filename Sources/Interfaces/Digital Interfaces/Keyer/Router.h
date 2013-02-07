//
//  Router.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 2/21/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

@interface Router : NSObject {
	Boolean launched ;
	float version ;
	NSMutableArray *keyers ;	//  array of MicroKeyer objects
}

//  µH Router support
- (void)closeRouter ;
- (void)runQuitScript:(NSString*)fileName ;
- (Boolean)launch ;
- (Boolean)launched ;			//  v0.89
- (float)version ;				//  v0.89
- (NSArray*)connectedKeyers ;	//	v0.89

//  serial ports
- (int)findPorts:(NSString**)path stream:(NSString**)stream max:(int)maxCount ;

//  AppleScript support
- (NSAppleScript*)executeScript:(NSAppleScript*)script withError:(const char*)msg ;
- (NSAppleScript*)loadScriptFor:(NSString*)scptFile ;	
- (NSAppleScript*)loadScriptForPath:(NSString*)scptFile ;	

	@end
