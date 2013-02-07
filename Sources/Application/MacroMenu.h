//
//  MacroMenu.h
//  cocoaModem
//
//  Created by Kok Chen on Sun Jul 04 2004.
//

#ifndef _MACROMENU_H_
	#define _MACROMENU_H_
	#import <Cocoa/Cocoa.h>
	#include "MacroNode.h"

	@interface MacroMenu : NSObject {
		MacroNode *rootNode[6] ;
	}

	- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item ;
	- (BOOL)outlineView:(NSOutlineView*)outline isItemExpandable:(id)item ;
	- (id)outlineView:(NSOutlineView*)outline child:(int)index ofItem:(id)item ;
	- (id)outlineView:(NSOutlineView*)outline objectValueForTableColumn:(NSTableColumn*)tableColumn byItem:(id)item ;

	@end

#endif
