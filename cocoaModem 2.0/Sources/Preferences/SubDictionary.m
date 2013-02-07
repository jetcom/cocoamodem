//
//  SubDictionary.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/10/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "SubDictionary.h"


@implementation SubDictionary

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		dict = [ [ NSMutableDictionary alloc ] initWithCapacity:16 ] ;
	}
	return self ;
}

- (NSMutableDictionary*)dictionary
{
	return dict ;
}

- (int)intValueForKey:(NSString*)key
{
	id obj = [ dict objectForKey:key ] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSNumber class ] ] ) return 0 ;
	return [ obj intValue ] ;
}

- (void)setInt:(int)value forKey:(NSString*)key
{
	NSNumber *num ;
	
	num = [ NSNumber numberWithInt:value ] ;
	[ dict setObject:num forKey:key ] ;
}

- (float)floatValueForKey:(NSString*)key
{
	id obj = [ dict objectForKey:key ] ;
	
	if ( !obj || ![ obj isKindOfClass:[ NSNumber class ] ] ) return 0 ;
	return [ obj floatValue ] ;
}

- (void)setFloat:(float)value forKey:(NSString*)key
{
	NSNumber *num ;
	
	num = [ NSNumber numberWithFloat:value ] ;
	[ dict setObject:num forKey:key ] ;
}

@end
