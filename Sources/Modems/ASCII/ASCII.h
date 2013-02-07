//
//  ASCII.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/28/10.
//  Copyright 2010 Kok Chen, W7AY. All rights reserved.
//

#import "WFRTTY.h"


@interface ASCII : WFRTTY {
	IBOutlet id dataBits ;
	int hardLimitForBackspace ;
}

@end
