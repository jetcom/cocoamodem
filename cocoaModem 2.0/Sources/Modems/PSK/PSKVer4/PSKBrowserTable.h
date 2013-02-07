//
//  PSKBrowserTable.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/20/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Preferences.h"

@class PSKBrowserHub ;

typedef struct {
	int row ;
	float frequency ;
	Boolean active ;
	int spaces ;
	unichar message[1025] ;
	int length ;
} Slot ;

typedef struct {
	int slot ;
	Boolean dirty ;
	int refreshedCount ;
	int refreshNeeded ;
} Row ;

@interface PSKBrowserTable : NSObject {

	IBOutlet id alarmTextField ;
	IBOutlet id ignoreCaseCheckbox ;
	
	PSKBrowserHub *hub ;
	
	NSTableView *table ;
	NSTableColumn *freqColumn ;
	NSTableColumn *textColumn ;
	float fontAdvance ;
	
	NSDictionary *alarmText ;
	
	Slot slot[41] ;
	Row row[21] ;
	NSLock *busy ;
	
	NSString *dot, *null ;
	NSMutableString *returnString ;
	NSMutableAttributedString *attributedString ;
	//  vfo offsets
	Boolean isUSB ;
	float vfoOffset ;
	
	NSTimer *refreshCheck ;
	int refreshCycle ;
	Boolean refreshBusy ;
	
	//  alarms
	NSString *alarmString ;
	int alarmMask ;
	NSLock *alarmLock ;
}

- (id)initWithTable:(NSTableView*)which client:(PSKBrowserHub*)client ;
- (void)assignRow:(int)row toSlot:(int)slotIndex frequency:(float)freq ;
- (void)addUnicodeCharacter:(unichar)unicode toSlot:(int)row withFrequency:(float)freq ;		//  v0.70 change to Unicode

- (void)openAlarm ;

- (void)setVFOOffset:(float)offset sideband:(Boolean)polarity ;

- (Slot*)slot ;
- (float)frequencyForSlot:(int)slotIndex ;
- (int)rowForSlot:(int)slotIndex ;
- (int)slotForRow:(int)row ;
- (void)removeSlot:(int)slotIndex ;

- (float)selectSlot:(int)index ;		//	v0.97, 1.01d
- (void)unselectSlots ;					//  v0.97

- (void)checkAndUpdateRow:(int)row ;
- (Boolean)rowIsInUse:(int)row ;

//  plist
- (Boolean)updateFromPlist:(Preferences*)pref ;
- (void)retrieveForPlist:(Preferences*)pref ;

@end
