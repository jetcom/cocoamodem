//
//  PSKBrowserTable.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/20/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "PSKBrowserTable.h"
#import "ClickedTableView.h"
#import "Plist.h"
#import "PSKBrowserHub.h"
#import "TextEncoding.h"

@implementation PSKBrowserTable


//  NSTableViewSource for the TableViews

//  The tableView has 21 rows.
//	These rows are mapped from 41 possible slots of 50 Hz each.

- (void)initSlot:(int)index row:(int)rowIndex frequency:(float)freq
{
	Slot *s ;
	int i ;
	
	s = &slot[index] ;
	s->row = rowIndex ;
	s->frequency = freq ;
	s->length = 220 ;
	for ( i = 0; i < 220; i++ ) s->message[i] = ' ' ;		//  left fill with spaces
	s->spaces = 0 ;
	s->active = NO ;
}

- (id)initWithTable:(NSTableView*)which client:(PSKBrowserHub*)client
{
	NSArray *columns ;
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		alarmLock = [ [ NSLock alloc ] init ] ;
		alarmString = nil ;
		alarmMask = NSCaseInsensitiveSearch ;
		[ NSBundle loadNibNamed:@"PSKAlarms" owner:self ] ;
		
		alarmText = [ @{NSForegroundColorAttributeName: [ NSColor redColor ]} retain ] ;
		
		table = which ;
		busy = [ [ NSLock alloc ] init ] ;
		hub = client ;
		
		columns = [ table tableColumns ] ;
		freqColumn = columns[1] ;
		textColumn = columns[0] ;
		
		vfoOffset = 0 ;
		isUSB = YES ;
				
		dot = [ [ NSString alloc ] initWithString:@"." ] ;
		null = [ [ NSString alloc ] initWithString:@"" ] ;
		returnString = [ [ NSMutableString alloc ] initWithCapacity:1024 ] ;
		[ returnString setString:null ] ;
		
		attributedString = [ [ NSMutableAttributedString alloc ] initWithString:@"test 0123456789" ] ;
		
		 //  assume fixed width font
		NSFont *font = [ [ textColumn dataCell ] font ] ;
		fontAdvance = [ font maximumAdvancement ].width ;
		
		//  allow up to 41 (50 Hz wide) frequency slots
		for ( i = 0; i < 41; i++ ) [ self initSlot:i row:-1 frequency:-1 ] ;	// init slots as unused
		for ( i = 0; i < 21; i++ ) {
			row[i].slot = -1 ;
			row[i].dirty = NO ;
			row[i].refreshedCount = row[i].refreshNeeded = 0 ;
		}
		refreshBusy = NO ;
		refreshCheck = [ NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(refreshCheck:) userInfo:self repeats:YES ] ;
	}
	return self ;
}

/* local */
- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

- (void)alarmChanged
{
	NSString *string ;
	
	[ alarmLock lock ] ;
	
	string = [ alarmTextField stringValue ] ;
	if ( alarmString ) [ alarmString release ] ;
	if ( [ string length ] > 0 ) alarmString = [ [ NSString alloc ] initWithString:string ] ; else alarmString = nil ;
	alarmMask = ( [ ignoreCaseCheckbox state ] == NSOnState ) ? NSCaseInsensitiveSearch : 0 ;
	
	[ alarmLock unlock ] ;
}

- (void)awakeFromNib
{
	[ self setInterface:alarmTextField to:@selector(alarmChanged) ] ;
	[ self setInterface:ignoreCaseCheckbox to:@selector(alarmChanged) ] ;
	[ self alarmChanged ] ;
}

- (void)openAlarm
{
	[ [ alarmTextField window ] makeKeyAndOrderFront:self ] ;
}

- (void)refreshCheck:(NSTimer*)timer
{
	Row *r ;
	int i, refreshNeeded, tableRow ;
	
	if ( refreshBusy ) return ;
	refreshBusy = YES ;
	
	for ( i = ( refreshCycle++ )&0x1; i < 21; i += 2 ) {
		r = &row[i] ;
		refreshNeeded = r->refreshNeeded ;
		if ( r->refreshedCount < refreshNeeded ) {
			tableRow = ( isUSB ) ? i : 20-i ;
			[ table setNeedsDisplayInRect:[ table rectOfRow:tableRow ] ] ; 
			r->refreshedCount = refreshNeeded ;
		}
	}
	refreshBusy = NO ;
}

- (Slot*)slot 
{
	return &slot[0] ;
}

- (int)mappedRow:(int)inrow
{
	if ( isUSB ) return inrow ;
	return 20-inrow ;				//  v0.59 bugfix; was 21-inrow
}

//  note: the rows assigned here is referenced to the absolute tone (irrespective of USB or LSB)
- (void)assignRow:(int)rowIndex toSlot:(int)slotIndex frequency:(float)freq
{
	if ( rowIndex < 0 || rowIndex > 20 ) return ;
	row[rowIndex].slot = slotIndex ;
	[ self initSlot:slotIndex row:rowIndex frequency:freq ] ;
}

- (Boolean)rowIsInUse:(int)rowIndex
{
	if ( rowIndex < 0 || rowIndex > 20 ) return YES ;
	return ( row[rowIndex].slot < 0 ) ? NO : YES ;
}

- (void)updateRow:(int)rowIndex
{
	if ( rowIndex < 0 || rowIndex > 20 ) return ;
	row[rowIndex].refreshNeeded++ ;
}

- (void)checkAndUpdateRow:(int)rowIndex
{
	if ( rowIndex < 0 || rowIndex > 20 ) return ;
	
	if ( row[rowIndex].dirty == NO ) return ;
	
	row[rowIndex].refreshNeeded++ ;
}

- (void)removeSlot:(int)slotIndex
{
	Slot *s ;
	int rowIndex ;
	
	if ( slotIndex < 0 || slotIndex > 40 ) return ;	//  sanity check

	//  unlink row points to slots
	s = &slot[slotIndex] ;
	rowIndex = s->row ;
	if ( rowIndex >= 0 && rowIndex < 21 ) row[rowIndex].slot = -1 ;

	[ self initSlot:slotIndex row:-1 frequency:-1 ] ;
	[ self updateRow:rowIndex ] ;
}

- (float)frequencyForSlot:(int)slotIndex
{
	if ( slotIndex < 0 || slotIndex > 40 ) return 0.0 ;
	return slot[slotIndex].frequency ;
}

- (int)rowForSlot:(int)slotIndex
{
	if ( slotIndex < 0 || slotIndex > 40 ) return -1 ;
	return slot[slotIndex].row ;
}

- (int)slotForRow:(int)rowIndex
{
	if ( rowIndex > 20 ) return -1 ;
	return row[rowIndex].slot ;
}

- (int)numberOfRowsInTableView:(NSTableView *)tableView
{
	//  set to 21 rows
	//	Nominal starting row = 400 Hz, last row = 2400, with 100 Hz steps.
	return 21 ;
}

//  v0.70 change from ascii to unicode
//  clears the buffer if freq < 0; that should free the slot
- (void)addUnicodeCharacter:(unichar)unicode toSlot:(int)slotIndex withFrequency:(float)freq
{
	Slot *sp ;
	unichar *s ;
	int rowIndex, length ;
	
	if ( slotIndex < 0 || slotIndex > 40 ) return ;	//  sanity check
	sp = &slot[slotIndex] ;
	rowIndex = sp->row ;	
	if ( rowIndex < 0 || rowIndex > 20 ) return ;	
	
	sp->frequency = freq ;
	sp->active = YES ;
	length = sp->length ;
	s = sp->message ;
	
	if ( unicode == 8 ) {
		//  backspace
		if ( length <= 2 ) return ;	//  don't apply backspace for the first couple of characters
		if ( sp->spaces > 0 ) {
			sp->spaces-- ;
			if ( sp->spaces >= 3 ) return ;
		}
		sp->length = length-1 ;
		[ self updateRow:rowIndex ] ;
		return ;
	}	
	if ( length <= 0 ) {
		s[0] = unicode ;
		sp->length = 1 ;
	}
	else {
		//  truncate spaces to at most 3
		if ( unicode == ' ' ) {
			sp->spaces++ ;
			if ( sp->spaces > 3 ) return ;
		}
		else sp->spaces = 0 ;
		
		if ( length >= 512 ) {
			//  exceeded buffer length, prune it back to 200 characters
			memcpy( s, s+512-200, 200*sizeof( unichar ) ) ;
			length = 200 ;
		}
		s[length] = unicode ;
		sp->length = length+1 ;
	}
	[ self updateRow:rowIndex ] ;
}

- (void)setVFOOffset:(float)offset sideband:(Boolean)polarity
{
	isUSB = polarity ;
	vfoOffset = offset ;
	[ table reloadData ] ;
}

//  v0.70  - change font metric for for ShiftJIS
- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn*)tableColumn row:(int)requestedRow
{
	float freq ;
	int try, t, inrow, rowIndex, characters, offset, strlength ;
	Slot *sp ;
	NSString *str, *substr ;
	unichar *s ;
	NSRange range ;
	
	
	inrow = requestedRow ;
	rowIndex = [ self mappedRow:inrow ] ;  		//  in LSB, the table row is inverted from the virtual row
	
	t = [ self slotForRow:rowIndex ] ;	
	sp = ( t < 0 || t > 40 ) ? nil : &slot[ t ] ;
	if ( sp && sp->active == NO ) sp = nil ;
	
	if ( tableColumn == freqColumn ) {
		if ( sp == nil ) return dot ;
		
		freq = sp->frequency;
		if ( freq < 0 ) return dot ;
		
		freq -= vfoOffset ;
		if ( !isUSB ) freq = -freq ;
		
		str = [ [ NSString alloc ] initWithFormat:@"%d", (int)( freq + 0.5 ) ] ;
		[ returnString setString:str ] ;
		[ str release ] ;
		return returnString ;
	}
	
	if ( sp == nil || sp->length <= 0 ) {
		row[rowIndex].dirty = NO ;
		return null ;
	}
	s = sp->message ;
	row[rowIndex].dirty = YES ;
	
	//  typography nonsense so text line fits the table column
	float width, tableWidth = [ tableColumn width ] ;
	int i, end ;
	
	width = 0 ;
	end = sp->length-1 ;
	for ( i = 0; i <= end; i++ ) {
		width += ( s[end-i] > 256 ) ? fontAdvance*1.7 : fontAdvance*1.10 ;
		if ( width > tableWidth ) break ;
	}
	characters = i ;	
	str = [ NSString stringWithCharacters:&s[ sp->length-characters ] length:characters ] ;	
	
	if ( alarmString == nil ) return str ;
	
	//  check for alarms
	[ alarmLock lock ] ;
	
	range = [ str rangeOfString:alarmString options:alarmMask ] ;
	if ( range.location == NSNotFound ) {
		[ alarmLock unlock ] ;
		return str ;
	}
	
	//  Has alarm -- create attributedString to highlight the alarm string.	
	int length = [ attributedString length ] ;
	[ attributedString removeAttribute:NSForegroundColorAttributeName range:NSMakeRange(0, 1) ] ;
	[ attributedString replaceCharactersInRange:NSMakeRange( 0, length ) withString:str ] ;
	
	//  find other ranges
	offset = 0 ;
	strlength = [ str length ] ;
	for ( try = 0; try < 50; try++ ) {
		range.location += offset ;
		[ attributedString addAttribute:NSForegroundColorAttributeName value:[ NSColor redColor ] range:range ] ;
		//  next search at a different offset in the string
		offset = range.location + range.length ;
		if ( offset >= strlength ) break ;	// reach end of string
		substr = [ str substringFromIndex:offset ] ;
		if ( substr == nil ) break ;  //  cannot make substring
		range = [ substr rangeOfString:alarmString options:alarmMask ] ;
		if ( range.location == NSNotFound ) break ;	//  no more found
	}
	[ alarmLock unlock ] ;
	return attributedString ;
}

//	v0.97, 1.01d
- (float)selectSlot:(int)slotIndex
{
	int mappedRowIndex ;
	
	mappedRowIndex = [ self mappedRow:[ self rowForSlot:slotIndex ] ] ;
	
	[ table selectRowIndexes:[ NSIndexSet indexSetWithIndex:mappedRowIndex ] byExtendingSelection:NO ] ;
	if ( slotIndex >= 0 && slotIndex < 40 ) {
		[ hub tableViewSelectedTone:slot[slotIndex].frequency option:NO ] ;
		return slot[slotIndex].frequency ;
	}
	return -1 ;
}

//	v0.97
- (void)unselectSlots
{
	[ table deselectAll:self ] ;
}

- (BOOL)tableView:(NSTableView*)tableView shouldSelectRow:(int)rowIndex
{
	int index ;
	Boolean optionClicked ;
	
	optionClicked = [ (ClickedTableView*)tableView optionClicked ] ;
	
	rowIndex = [ self mappedRow:rowIndex ] ;
	index = [ self slotForRow:rowIndex ] ;
	if ( index >= 0 && index < 40 ) [ hub tableViewSelectedTone:slot[index].frequency option:optionClicked ] ;

	return YES ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	NSString *str ;
	
	str = [ pref stringValueForKey:kPSKAlarmString ] ;
	if ( str && alarmTextField != nil ) [ alarmTextField setStringValue:str ] ;
	str = [ pref stringValueForKey:kPSKAlarmCase ] ;
	if ( str && ignoreCaseCheckbox != nil ) {
		[ ignoreCaseCheckbox setState:(  [ str characterAtIndex:0 ] == '1'  ) ? NSOnState : NSOffState ] ;
	}
	if ( alarmTextField != nil ) [ self alarmChanged ] ;

	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	if ( alarmTextField != nil ) {
		[ pref setString:[ alarmTextField stringValue ] forKey:kPSKAlarmString ] ;
	}
	if ( ignoreCaseCheckbox != nil ) {
		[ pref setString:( ( [ ignoreCaseCheckbox state ] == NSOnState ) ? @"1" : @"0" ) forKey:kPSKAlarmCase ] ;
	}
}


@end
