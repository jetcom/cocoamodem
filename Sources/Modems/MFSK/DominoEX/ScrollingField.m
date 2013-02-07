//
//  ScrollingField.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 6/24/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ScrollingField.h"
#import "PrivateNSFont.h"
#import "MFSKModes.h"

@implementation ScrollingField

- (id)initWithFrame:(NSRect)rect
{
	self = [ super initWithFrame:rect ] ;
	if ( self ) {
		textField = nil ;
		stringValue = [ [ NSMutableString alloc ] initWithCapacity:60 ] ;
		[ stringValue appendString:@"                        ." ] ;
		producer = consumer = 0 ;
		scrollCount = extraPause = 0 ;
		scrollRate = 1 ;
		useSmooth = YES ;
		fast = NO ;
		timer = nil ;
		currentMode = 0 ;
		busy = NO ;			//  not critical, no need to use lock
	}
	return self ;
}

//	(Private API)
- (void)restartTimer:(int)mode
{
	float baudRate ;
	
	if ( timer ) [ timer invalidate ] ;
	timer = nil ;
	busy = NO ;
	
	baudRate = 0.0 ;
	switch ( mode % 100 ) {
	case DOMINOEX22:
		baudRate = 21.533 ;
		break ;
	case DOMINOEX16:
		baudRate = 15.625 ;
		break ;
	case DOMINOEX11:
		baudRate = 10.766 ;
		break ;
	case DOMINOEX8:
		baudRate = 7.8125 ;
		break ;
	case DOMINOEX5:
		baudRate = 5.3833 ;
		break ;
	case DOMINOEX4:
		baudRate = 3.90625 ;
		break ;
	}
	if ( baudRate < .01 ) return ;	//  don't start timer
	
	timer = [ NSTimer scheduledTimerWithTimeInterval:0.028*( 15.625 + 0.25 )/( baudRate+0.25 ) target:self selector:@selector(tick:) userInfo:self repeats:YES ] ;
}

- (void)clear
{
	producer = consumer ;
	[ textField setStringValue:@"" ] ;
}

//  check if we have a character to scroll into the view
- (void)tick:(NSTimer*)tm
{
	unichar c, uc[2] ;
	int length ;
	NSRect fieldRect ;
	NSString *newString ;
	
	if ( busy ) return ;
	busy = YES ;
	
	if ( scrollCount != 0 ) {
		scrollCount -= scrollRate ;
		if ( scrollCount <= 1 ) {
			//  last step
			if ( scrollCount < 0 ) scrollCount = 0 ;
			fieldRect = originalRect ;
			fieldRect.origin.x += scrollCount ;	
			[ textField setFrame:fieldRect ] ;
			[ textField display ] ;
			scrollCount = 0 ;
			busy = NO ;
			return ;
		}
		//  not last step
		fieldRect = originalRect ;
		fieldRect.origin.x += scrollCount ;	
		[ textField setFrame:fieldRect ] ;
		[ textField display ] ;
		busy = NO ;
		return ;
	}
	//  check backlog for characters
	length = producer - consumer ;

	//	Extra pause for spaces, tabs, etc if there is no (large) backlog of characters
	//	This averages out the non-fix-width characters.
	if ( extraPause > 0 ) {
		if ( length < 1 ) {
			extraPause-- ;
			busy = NO ;
			return ;
		}
		extraPause = 0 ;	//  has backlog, cut the pause short
	}
	if ( length <= 0 ) {
		busy = NO ;
		return ;		//  nothing to process
	}
	
	//  get char
	c = backlogString[ consumer % 2048 ] & 0xff ;
	consumer++ ;
			
	//	adjust scroll rate
	fast = NO ;
	if ( length < 8 ) scrollRate = 1 ; 
	else if ( length > 12 ) {
		fast = YES ;
		if ( length > 15 ) scrollRate = 60 ; else scrollRate = 2 ;
	}
	//  first remove trailing <space, space,dot> that we had inserted (see below)
	length = [ stringValue length ] ;
	uc[0] = c ;
	newString = [ NSString stringWithCharacters:uc length:1 ] ;	
	[ stringValue replaceCharactersInRange:NSMakeRange( length-3, 0 ) withString:newString ] ;
	
	length = [ stringValue length ] ;
	if ( length > 48 ) [ stringValue deleteCharactersInRange:NSMakeRange( 0, length-48 ) ] ;

	currentFontAdvance = fontAdvance[ c ] ;
	fieldRect = originalRect ;

	if ( useSmooth == NO ) {
		scrollCount = 0 ;
		extraPause = 0 ;
	}
	else {
		scrollCount = 30 ;
		if ( scrollCount > currentFontAdvance ) scrollCount = currentFontAdvance + 0.5 ;
		extraPause = ( c <= 32 ) ? 60 : 0 ;
	}
	fieldRect.origin.x += scrollCount ;	
	[ textField setPaused:YES ] ;
	[ textField setStringValue:stringValue ] ;
	[ textField setFrame:fieldRect ] ;
	[ textField setPaused:NO ] ;
	busy = NO ;
}

- (void)appendCharacter:(int)c draw:(Boolean)draw
{
	if ( draw == NO ) return ;
	
	backlogString[ producer % 2048 ] = c ;
	producer++ ;
}

//	set the text field, and also gather font advance information
- (void)setTextField:(NSTextField*)field 
{
	NSRect boxRect ;
	NSGlyph g ;
	float zeroWidth ;
	int i ;
	
	textField = (TextFieldForScrolling*)field ;
	
	boxRect = [ self frame ] ;
	originalRect = [ field bounds ] ;
	originalRect.size.width = boxRect.size.width + 180 ;		//  set up an underlying clipped field that is much wider so text formatter don't start compressing text
	originalRect.size.height = boxRect.size.height - 1 ;
	originalRect.origin.x = -173 ;
	originalRect.origin.y = 0 ;
	[ field setFrame:originalRect ] ;
	[ field setBounds:originalRect ] ;

	font = [ textField font ] ;
	zeroWidth = [ font advancementForGlyph:0 ].width ;
	
	for ( i = 0; i < 256; i++ ) {
		glyph[i] = g = [ font _defaultGlyphForChar:i ] ;
		fontAdvance[i] = ( ( g == 0 ) ? zeroWidth : [ font advancementForGlyph:g ].width ) ;
	}
}

- (void)setBackgroundColor:(NSColor*)color
{
	if ( textField ) [ textField setBackgroundColor:color ] ;
}

- (void)setTextColor:(NSColor*)color
{
	if ( textField ) [ textField setTextColor:color ] ;
}

- (void)setSmoothState:(NSButton*)checkbox 
{
	useSmooth = ( [ checkbox state ] == NSOnState ) ;
}

//	This determines the smooth scrolling rate
- (void)setMFSKMode:(int)mode 
{
	if ( mode != currentMode ) {
		currentMode = mode ;
		[ self restartTimer:mode ] ;
	}
}

@end
