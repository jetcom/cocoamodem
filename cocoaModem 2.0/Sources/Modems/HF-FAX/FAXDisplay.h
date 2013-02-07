//
//  FAXDisplay.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/6/06.



#ifndef _FAXDISPLAY_H_
	#define _FAXDISPLAY_H_
	
	#include "FAXView.h"
	#include "NamedFIFO.h"
	
	typedef unsigned char MessageBuffer[2] ;
		
	@interface FAXDisplay : FAXView {
	
		IBOutlet id autoButton ;
		IBOutlet id halfButton ;
		IBOutlet id newButton ;
		IBOutlet id pauseButton ;
		IBOutlet id saveButton ;
		IBOutlet id scroller ;				//  v0.80 scroll ourselfs since scrollview leaks

		IBOutlet id blackLevelSlider ;
		IBOutlet id contrastSlider ;
		
		IBOutlet id clockOffsetField ;
		IBOutlet id clockOffsetStepper ;
		IBOutlet id runLight ;
		
		IBOutlet id saveView ;				//  off page (but enabled) FAXView for saving data v0.81 no longer used
		IBOutlet id tempFolder ;
		
		NSImage	*spareImage ;

		float nominalBlackLevel, nominalContrast ;
		
		Boolean imageParametersChanged ;		// v 0.57d
		
		Boolean	dev850 ;						//  use 850 Hz deviation instead of 800 Hz
		
		NSLock *updateLock ;
		NSLock *drawLock ;
		int message ;
		Boolean firstDraw ;
		
		//  float sync detection
		float *goertzelWindow ;
		float startTone ;
		float stopTone ;
		float sync ;
		
		Boolean running, paused ;
		int vsyncState, pauseCount, linesFromTop ;
		int syncBuffer[5512+129] ;
		
		//  display
		int updatedRow ;

		Boolean updateRequested ;
		//  v0.80 scroller
		float scrollerHeight, viewHeight ;
	}
	- (IBAction)selectFolder:(id)sender ;
	- (IBAction)clearFolder:(id)sender ;
	
	- (void)start ;

	- (void)addPixel:(float)value ;
	- (void)setDeviation:(int)state ;		//  v0.73
	
	- (void)setFolder:(NSString*)folder ;
	- (NSString*)folder ;
	
	- (int)drawCount ;
	
	//  v0.80 for plist
	- (void)setupScale:(Boolean)full ;
	- (Boolean)scaleIsFullSize ;

	 
	@end
	
	#define	pipeName	"/tmp/cmFAXPipe"

#endif
