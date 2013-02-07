//
//  MacroNode.h
//  cocoaModem
//
//  Created by Kok Chen on Sun Jul 04 2004.
//

#ifndef _MACRONODE_H_
	#define _MACRONODE_H_


	#import <Cocoa/Cocoa.h>


	@interface MacroNode : NSObject {
		NSMutableArray *children ;
		NSString *name ;
		NSString *function ;
	}
	
	- (id)initWithName:(NSString*)nameString function:(NSString*)functionString ;
	
	- (NSString*)nodeName ;
	- (NSString*)nodeFunction ;
	- (void)setNodeName:(NSString*)string function:(NSString*)function ;
	- (MacroNode*)childAtIndex:(int)i ;
	- (void)addChild:(MacroNode*)node ;
	- (int)childrenCount ;

	@end

#endif
