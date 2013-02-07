//
//  MacroMenu.m
//  cocoaModem
//
//  Created by Kok Chen on Sun Jul 04 2004.
	#include "Copyright.h"
//

#import "MacroMenu.h"

@implementation MacroMenu

- (void)addGeneral:(MacroNode*)node
{
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"\\n" function:@"new line" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"\\r" function:@"carriage return" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"" function:@"-----" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%b" function:@"brag tape" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%c" function:@"my callsign" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%C" function:@"DX callsign" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%h" function:@"my name" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%H" function:@"DX name" ] ] ;    
}

- (void)addContest:(MacroNode*)node
{
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%a" function:@"ARRL section" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%g" function:@"grid square" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%n" function:@"QSO Number" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%o" function:@"Cut Number (0 substituted by T)" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%N" function:@"Cut Number (1/A,9/N,0/T)" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%p" function:@"previous QSO Number" ] ] ;    
	[ node addChild:[ [ MacroNode alloc ] initWithName:@"%P" function:@"previous registered UTC time" ] ] ;    
	[ node addChild:[ [ MacroNode alloc ] initWithName:@"%s" function:@"state/province/DX" ] ] ; 
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%t" function:@"UTC time hhmm" ] ] ; 
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%T" function:@"registered UTC time" ] ] ; 
	[ node addChild:[ [ MacroNode alloc ] initWithName:@"%x" function:@"contest exchange" ] ] ; 
	[ node addChild:[ [ MacroNode alloc ] initWithName:@"%X" function:@"received contest exchange" ] ] ; 
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%y" function:@"year licensed" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%z" function:@"CQ zone" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%Z" function:@"ITU zone" ] ] ;    
}

- (void)addRTTY:(MacroNode*)node
{
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[tx]" function:@"switch to transmit" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[rx]" function:@"return to receive" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[b1]" function:@"narrow bandwidth" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[b2]" function:@"normal bandwidth" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[b3]" function:@"wide bandwidth" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[d1]" function:@"M/S demod" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[d2]" function:@"MP- demod" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[d3]" function:@"MP+ demod" ] ] ;    
}

- (void)addPSK:(MacroNode*)node
{
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[tx]" function:@"switch to transmit" ] ] ;    
    [ node addChild:[ [ MacroNode alloc ] initWithName:@"%[rx]" function:@"return to receive" ] ] ;    
}

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		rootNode[0] = [ [ MacroNode alloc ] init ] ;
		[ rootNode[0] setNodeName: @"General" function:@"" ] ;
		[ self addGeneral:rootNode[0] ] ;
		rootNode[1] = [ [ MacroNode alloc ] init ] ;
		[ rootNode[1] setNodeName: @"Contest" function:@"" ] ;
		[ self addContest:rootNode[1] ] ;
		rootNode[2] = [ [ MacroNode alloc ] init ] ;
		[ rootNode[2] setNodeName: @"RTTY" function:@"" ] ;
		[ self addRTTY:rootNode[2] ] ;
		rootNode[3] = [ [ MacroNode alloc ] init ] ;
		[ rootNode[3] setNodeName: @"PSK" function:@"" ] ;
		[ self addPSK:rootNode[3] ] ;
	}
	return self ;
}

- (int)outlineView:(NSOutlineView*)outline numberOfChildrenOfItem:(id)item
{
    if ( item == nil ) {
		//  number of base objects
        return 4 ;
    }
    return [ item childrenCount ] ;
}

- (BOOL)outlineView:(NSOutlineView*)outline isItemExpandable:(id)item
{
    return ( [ item childrenCount ] > 0 ) ;
}

- (id)outlineView:(NSOutlineView*)outline child:(int)index ofItem:(id)i
{
	MacroNode *item = i ;
	
    if ( item ) {
        return [ item childAtIndex:index ] ;
	}
    else {
        return rootNode[index] ;
	}
}

- (id)outlineView:(NSOutlineView*)outline objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item
{
    NSString *identifier = [ tableColumn identifier ] ;
    
    if ( [ identifier isEqual:@"Function" ] ) {
        return [ item nodeFunction ] ;
    }
	return [ item nodeName ] ;
}

@end
