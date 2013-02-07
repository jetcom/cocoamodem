//
//  ClickedTableView.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/7/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ClickedTableView : NSTableView {
	Boolean option ;
	unsigned int optionMask;
}

- (Boolean)optionClicked ;
- (void)useControlButton:(Boolean)state ;

@end
