//
//  CMFSKTypes.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/11/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

typedef struct {
	CMBandpassFilter *bandpassFilter, *originalBandpassFilter ;
	CMFSKMixer *mixer ;
	CMFSKMatchedFilter *matchedFilter, *originalMatchedFilter ;
	CMATC *atc ;
	CMBaudotDecoder *decoder ;
} CMFSKPipeline ;

