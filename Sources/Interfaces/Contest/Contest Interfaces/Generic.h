//
//  Generic.h
//  cocoaModem
//
//  Created by Kok Chen on Mon Oct 11 2004.
//

#ifndef _GENERIC_H_
	#define _GENERIC_H_

	#include <Contest.h>


	@interface Generic : Contest {
		IBOutlet id dxCall ;
		IBOutlet id dxExchange ;
		
		UpperFormatter *upperFormatter ;
		NSString *qsoStrings[8] ;
		
		char exchSent[32] ;		//  this should be set by the contest
		
		//  xml parser
		int parseQSOPhase ;
	}
	
	- (void)enterQSOFromXML ;
	
	#define	kQSOCall	1
	#define	kQSODate	2
	#define	kQSOTime	3
	#define	kQSOExch	4
	#define	kQSOFreq	5
	#define	kQSOMode	6
	#define	kQSONumber	7

	@end

#endif
