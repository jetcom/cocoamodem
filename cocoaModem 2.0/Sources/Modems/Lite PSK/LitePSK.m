//
//  LitePSK.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/2/07.
//  Copyright 2007 Kok Chen, W7AY. All rights reserved.
//

#import "LitePSK.h"
#import "ModemManager.h"


@implementation LitePSK

- (id)initIntoTabView:(NSTabView*)tabview manager:(ModemManager*)mgr
{
	[ mgr showSplash:@"Creating Lite PSK Modem" ] ;
			
	self = [ super initIntoTabView:tabview nib:@"LitePSK" manager:mgr ] ;
	if ( self ) {
		manager = mgr ;
		transceivers = 2 ;
	}
	return self ;
}

@end
