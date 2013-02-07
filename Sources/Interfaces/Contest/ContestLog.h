//
//  ContestLog.h
//  cocoaModem
//
//  Created by Kok Chen on 12/23/04.
//

#ifndef _CONTESTLOG_H_
	#define _CONTESTLOG_H_

	#import <Cocoa/Cocoa.h>

	@class ContestManager ;
	@class Preferences ;

	@interface ContestLog : NSObject {
	
		IBOutlet id tableView ;
		IBOutlet id callsignSearchField ;
		IBOutlet id notFoundText ;
		IBOutlet id logLockButton ;
		IBOutlet id infoField ;

		ContestManager *manager ;
		
		NSTableColumn *qsoNumber ;
		NSTableColumn *callsign ;
		NSTableColumn *timec ;
		NSTableColumn *band ;
		NSTableColumn *rst ;
		NSTableColumn *received ;
		NSTableColumn *mode ;
		NSTableColumn *date ;
		
		NSMutableArray *qsoArray ;	//  array of ContestQSOObj
		Boolean ascend[8] ;
		NSTableColumn *previousLogColumn ;
		int currentSortCriterion ;
		int searchIndex ;
		Boolean bulkLogEntry ;
		int columnOrder[16] ;
	}

	- (IBAction)findCallsign:(id)sender ;
	- (IBAction)lockButtonChanged:(id)sender ;

	- (id)initWithManager:(ContestManager*)control ;
	- (void)awakeFromManager ;
	- (void)showWindow ;
	
	- (void)setBulkLog:(Boolean)bulk ;
	- (void)newQSOCreated:(struct _ContestQSO*)q ;
	
	- (void)allowEdit:(Boolean)allow ;
	- (NSComparisonResult)compare:(id)other ;
	
	- (void)displayInfo:(char*)info ;
	
	
	//  plist
	- (void)setupDefaultPreferences:(Preferences*)pref ;
	- (Boolean)updateFromPlist:(Preferences*)pref ;
	- (void)retrieveForPlist:(Preferences*)pref ;
	
	@end


#endif
