//
//  DateTimeField.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 12/26/05.
	#include "Copyright.h"
//

#import "DateTimeField.h"


@implementation DateTimeField

- (void)setContestFont:(NSNotification*)notify
{
	NSString *name ;
	NSFont *font ;
	float size ;
	
	font = [ notify object ] ;
	size = [ font pointSize ]*0.875 ;
	name = [ font fontName ] ;
	[ self setFont:[ NSFont fontWithName:name size:size ] ] ;
}

- (void)awakeFromNib
{
	//  accepts fontChanges messages here
	[ [ NSNotificationCenter defaultCenter ] addObserver:self selector:@selector(setContestFont:) name:@"ContestFont" object:nil ] ;
}


@end
