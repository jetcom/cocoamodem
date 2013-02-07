//
//  RSTExchange.h
//  cocoaModem
//
//  Created by Kok Chen on Sat Nov 27 2004.
//

#ifndef _RSTEXCHANGE_H_
	#define _RSTEXCHANGE_H_

	#include <Contest.h>


	@interface RSTExchange : Contest {
		IBOutlet id dxCall ;
		IBOutlet id dxExchange ;
		IBOutlet id dxRST ;
		IBOutlet id dxExtra ;

		UpperFormatter *upperFormatter ;
		NSString *qsoStrings[9] ;
		//  xml parser
		int parseQSOPhase ;
		//  for checking if field already cleared
		Boolean callFieldEmpty ;
		//  for defered field selection
		int selectedFieldType ;
	}
	
	- (void)clearFieldsToDefault ;
	
	- (void)enterQSOFromXML ;
	
	- (void)selectCallsignField ;
	- (void)selectExchangeField ;
	- (void)selectExtraField ;
	
	- (Boolean)validateExchange:(NSString*)exchange ;
	
	#define	kQSOCall	1
	#define	kQSODate	2
	#define	kQSOTime	3
	#define	kQSOExch	4
	#define	kQSOFreq	5
	#define	kQSOMode	6
	#define	kQSONumber	7
	#define	kQSORST		8

	@end

#endif
