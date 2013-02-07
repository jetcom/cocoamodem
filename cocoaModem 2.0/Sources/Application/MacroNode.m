//
//  MacroNode.m
//  cocoaModem
//
//  Created by Kok Chen on Sun Jul 04 2004.
	#include "Copyright.h"
//

#import "MacroNode.h"


@implementation MacroNode

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		children = [ [ NSMutableArray alloc ] init ] ;
		name = @"" ;
	}
	return self ;
}

- (id)initWithName:(NSString*)nameString function:(NSString*)functionString
{
	self = [ self init ] ;
	if ( self ) {
		[ self setNodeName:nameString function:functionString ] ;
	}
	return self ;
}

-(void)setNodeName:(NSString*)nameString function:(NSString*)functionString
{
	if ( name ) [ name release ] ;
	name = [ nameString retain ] ;
	if ( function ) [ function release ] ;
	function = [ functionString retain ] ;
}

- (NSString*)nodeName
{
	return name ;
}

- (NSString*)nodeFunction
{
	return function ;
}

- (void)addChild:(MacroNode*)node
{
    [ children addObject:node ] ;
}

- (MacroNode*)childAtIndex:(int)i
{
    return [ children objectAtIndex:i ] ;
}

- (int)childrenCount
{
    return [ children count ] ;
}

@end
