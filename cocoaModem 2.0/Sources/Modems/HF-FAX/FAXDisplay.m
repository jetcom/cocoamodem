//
//  FAXDisplay.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 1/26/06.
	#include "Copyright.h"


#import "FAXDisplay.h"
#include "CoreFilterTypes.h"		// for CMFs (11025.0)
#include "CMDSPWindow.h"	
#include <string.h>
#include <math.h>
#include <sys/types.h>
#include <sys/stat.h>
#include "FAXStepper.h"


@implementation FAXDisplay

//  ReceiveView for HF-FAX
//  The image size is 904 pixels wide and about 3200 high (2280 required for DWD) inside a scollview 
//	that is 430 pixels high
//
//  FAXDisplay receives oversampled data (11025 samples/second) and resamples the data to the IOC 
//	(IOC 576 is equivalent to a sampling rate of 3619.115 samples per second).

//  The resampling to IOC is done with a DDA and therefore accurate to about 1/3 of a pixel for IOC 576.
//  Since A/D converters' clocks are not precise, the input sampling rate would differ from 11025 by up to 
//	a few hundred parts per million and this is corrected when the resampling takes place.
//
//  The fractional pixel from IOC 576 is handled by incrementing the resampling DDA by that fraction.
//
//	The input data is a bipolar signal that is scaled such that a 1500 Hz signal (black) appears as a -0.23 
//	level and a 2300 Hz signal (white) appears as a +0.23 level (this is because 2.pi represents 11025 Hz).
//
//	The backing store (so that the black level and contrast of an image can be dynamically adjusted) saves 
//	the image as an 8 bit deep image, with nominal black and white levels set to 32 and 224, respectively.
//
//	The backing store is a circular buffer of size MAXBACKING.  Images start at the offset currentImageOrigin of the
//	backing store.


#define	VSYNCWAIT		0
#define	VSYNCSTARTING	1
#define	VSYNCCHECK		2
#define	VSYNCENDPAUSE	3
#define	VSYNCSTARTWAIT	4

static int drawCount = 100 ;

- (void)scrollBuffer
{
	int top ;
	
	top = [ scroller maxValue ] - [ scroller floatValue ] ;	
	[ faxFrame setScrollOffset:top ] ;
}

//	(Private API)
//	v0.80 no longer done from main thread
- (void)refreshImage
{	
	[ self setNeedsDisplay:YES ] ;
}

//	(Private API)
-(void)unconditionalSetPosition:(int)where
{
	[ scroller setFloatValue:scrollerHeight - where ] ;
	[ self scrollBuffer ] ;
	[ self performSelectorOnMainThread:@selector(refreshImage) withObject:nil waitUntilDone:YES ] ;
}

//	(Private API)
-(void)setPosition:(int)where
{
	float scrollertop ;

	//	v0.80 no longer uses the enclosing scrollview, but a slider
	//	the scroll/clip view is leaking massive amounts of memory when the FAX gets past the bottom of the view		
	scrollertop = scrollerHeight - [ scroller floatValue ] ;	
	if ( where != 0 && fabs( where - scrollertop ) > 2 ) return ;		//  scroller moved away by user

	[ self unconditionalSetPosition:where ] ;
}

// (Private API)
- (void)setInterface:(NSControl*)object to:(SEL)selector
{
	[ object setAction:selector ] ;
	[ object setTarget:self ] ;
}

//	(Private API)
//	Executed in main thread
-(void)swapImageRepAndRefresh
{
	//  point NSBitmapImageRep to scrolled position, and redraw
	[ self swapImageRep ] ;
	[ self refreshImage ] ;
}

- (void)scrollBufferFromScroller
{
	[ self scrollBuffer ] ;
	//  point NSBitmapImageRep to scrolled position, and redraw
	[ self performSelectorOnMainThread:@selector(swapImageRepAndRefresh) withObject:nil waitUntilDone:YES ] ;
}

//  local
- (void)displayRunLightColor:(NSColor*)color
{
	[ runLight setBackgroundColor:color ] ;
	[ runLight setNeedsDisplay:YES ] ;
}


/* local */
//  return power at frequency using Goertzel algorithm (256 unsigned char samples)
- (float)goertzel:(unsigned char*)x tone:(float)s
{
	int i ;
	float d0=0, d1=0, d2 ;
	
	for ( i = 0; i < 256; i++ ) {
		d2 = d1 ;
		d1 = d0 ;
		d0 = 2*s*d1 - d2 + goertzelWindow[i]*( x[i]-128 ) ;
	}
	return d0*d0 + d1*d1 - 2*s*d0*d1 ;
}

- (float)findVSync:(unsigned char*)array
{
	float start, stop, sum, x1, x2, r, d1, d2 ;
	int i ;
	
	//  cross coorrelate with shifted data (for multiple of 75 Hz tones)
	r = 0 ;
	d1 = d2 = 0.1 ;
	for ( i = 0; i < 256; i++ ) {
		x1 = array[i]-128 ;
		x2 = array[i+294]-128 ;
		r += x1*x2 ;
		d1 += x1*x1 ;
		d2 += x2*x2 ;
	}
	r = fabs( r/sqrt( d1*d2 ) ) ;
	
	if ( r < 0.8 ) return 0 ;
	
	start = [ self goertzel:array tone:startTone ] ;
	stop = [ self goertzel:array tone:stopTone ] ;
	
	sum = 0 ;
	for ( i = 0; i < 256; i++ ) {
		x1 = array[i]-128 ;
		sum += x1*x1 ;
	}
	sum *= 7 ;
	
	r = ( ( stop > start ) ? -stop : start )/sum ;

	return r ;
}

- (void)findHSyncAtRow:(int)v
{
	int offset, i ;
	BackingFrame *backingframe ;
	
	offset = [ faxFrame frameOrigin ] + [ faxFrame frameOffsetForSample:0 ofRow:v ] ;
	backingframe = [ faxFrame backingFrame ] ; 
	for ( i = 0; i < 5512; i++ ) {
		offset %= MAXBACKING ;
		syncBuffer[i] += ( backingframe->backing[offset] - 128 ) ;
		offset++ ;
	}
}

- (void)checkSyncBuffer
{
	int i ;
	int sum1, sum2, peak, v, tap ;
	
	//  first extend the buffer to emulate a circular buffer
	for ( i = 0; i < 129; i++ ) syncBuffer[i+5512] = syncBuffer[i] ;
	
	
	//  init boxcar filter
	sum1 = sum2 = 0 ;
	for ( i = 0; i < 64; i++ ) {
		sum1 += syncBuffer[i] ;
		sum2 += syncBuffer[i+64] ;
	}
	//  boxcar filter
	peak = sum2 - sum1 ;
	for ( i = 0; i < 5512; i++ ) {
		tap = syncBuffer[i+64] ;
		sum1 += tap-syncBuffer[i] ;
		sum2 += syncBuffer[i+128]-tap ;		// v0.26 bug fix
		v = sum1-sum2 ;
		if ( v > peak ) {
			peak = v ;
		}
	}
		
	if ( peak < 2000 ) return ;		//  probably not a sync pulse
	
	//  position is where the correlation peaks
	for ( i = 0; i < 5512; i++ ) {
		if ( syncBuffer[i+1] < 0 && syncBuffer[i] >= 0 ) {
			[ faxFrame setHorizontalOffset:i ] ;
			[ faxFrame clearSwath:32 ] ;
			[ self setPosition:0 ] ;
			return ;
		}
	}
}

- (void)start
{
	[ faxFrame startNewImage ] ;
	sync = 0.0 ;

	running = YES ;
	paused = NO ;
	[ runLight setBackgroundColor:[ NSColor greenColor ] ] ;
	if ( vsyncState == VSYNCSTARTWAIT ) vsyncState = VSYNCWAIT ;
}

//  (stop signal) -> VSYNCENDPAUSE -> VSYNCWAIT -> (start signal) -> VSYNCSTARTING -> (start signal goes away) -> VSYNCWAIT
- (void)outputLine
{
	int random, i, syncIndex, pos, row ;
	float newsync ;
	NSString *folder ;
	BackingFrame *backingframe ;
	
	//  new line received, inform background thread
	if ( vsyncState == VSYNCWAIT || vsyncState == VSYNCSTARTING || vsyncState == VSYNCSTARTWAIT ) {
		// look for sync at different locations on the scanline to avoid false positives
		//  each scaline is 0.5 seconds long and has 11025/2 samples
		//  use a slow attack fast decay decoder
		backingframe = [ faxFrame backingFrame ] ;
		random = ( backingframe->input & 0x7 ) * 500 ;
		syncIndex = ( backingframe->origin + backingframe->input - 5000 + random )%MAXBACKING ;
		newsync = [ self findVSync:&backingframe->backing[syncIndex] ] ;
		sync = ( newsync < sync ) ? ( sync*0.3 + 0.7*newsync ) :  ( sync*0.7 + 0.3*newsync ) ;
	}
	switch ( vsyncState ) {
	case VSYNCSTARTING:
		if ( sync < 0.40 ) {
			linesFromTop = 0 ;
			sync = 0.0 ;
			for ( i = 0; i < 5510; i++ ) syncBuffer[i] = 0.0 ;
			vsyncState = VSYNCWAIT ;
			[ self start ] ;
			drawCount = 0 ;
			[ runLight setBackgroundColor:[ NSColor yellowColor ] ] ;
			[ self performSelectorOnMainThread:@selector(displayRunLightColor:) withObject:[ NSColor yellowColor ] waitUntilDone:NO ] ;
		}
		break ;
	case VSYNCENDPAUSE:
		//  pause after a STOP signal before waiting for START
		if ( ++pauseCount > 10 ) {
			paused = YES ;
			[ runLight setBackgroundColor:[ NSColor redColor ] ] ;
			vsyncState = VSYNCSTARTWAIT ;
			sync = 0.0 ;
		}
		break ;
	case VSYNCSTARTWAIT:
		if ( sync > 0.8 ) vsyncState = VSYNCSTARTING ;
		break ;
	default:
		linesFromTop++ ;
		backingframe = [ faxFrame backingFrame ] ;
		if ( linesFromTop > 10 && linesFromTop <= 32 ) {
			//  look for hsync 
			[ self findHSyncAtRow:backingframe->displayRow ] ;
			if ( linesFromTop == 32 ) {
				[ self checkSyncBuffer ] ;
				[ runLight setBackgroundColor:[ NSColor greenColor ] ] ;
				[ self performSelectorOnMainThread:@selector(displayRunLightColor:) withObject:[ NSColor greenColor ] waitUntilDone:NO ] ;
			}
		} 
		if ( sync > 0.8 ) {
			// saw individual (not after stop) start signal	
			if ( [ autoButton state ] == NSOnState ) {
				//  if auto is checked, start at the top and look for H Sync
				vsyncState = VSYNCSTARTING ;
			}
		}
		else if ( sync < -0.8 ) {
			// saw stop signal
			if ( [ autoButton state ] == NSOnState ) {
				//  do auto sequence if auto is checked
				pauseCount = 0 ;
				vsyncState = VSYNCENDPAUSE ;
				[ faxFrame markDisplayRow ] ;
				folder = [ tempFolder stringValue ] ;
				//  dump image to pdf file
				if ( folder != nil && [ folder length ] > 0 ) {		//  v0.80 check string for nil first
					[ faxFrame dumpCurrentFrameToFolder:folder ] ;	//  v0.81 use FAXFrame to dump
				}
			}
		}
	}
	//  update all touched scanlines
	if ( vsyncState == VSYNCWAIT && !paused ) {
		if ( [ drawLock tryLock ] ) {
			row = [ faxFrame drawLineAndAdvanceRow ] ;
			//  reposition scroller if image is larger than the view, and refresh display if needed
			pos = row - 4 - viewHeight ;
			if ( pos >= 0 ) [ self setPosition:pos ] ;
			[ self performSelectorOnMainThread:@selector(refreshImage) withObject:nil waitUntilDone:YES ] ;
			[ drawLock unlock ] ;
			[ faxFrame setFrameMark:1 ] ;
		}
	}
}

- (int)drawCount
{
	return drawCount ;
}

//   called from redrawThread 
- (void)redrawFAX
{
	[ drawLock lock ] ;
	[ faxFrame redrawFrame ] ;
	[ drawLock unlock ] ;
	[ self performSelectorOnMainThread:@selector(refreshImage) withObject:nil waitUntilDone:YES ] ;
}

//  Data sample received from FAXReceiver
//  Received vales are bi-polar, with black at about -0.23 and white at about +0.23. (-.244 to +.244 for DWD)
//  The image is simply stored into the backing buffer as a 8-bit value, with black at level 32 and white at level 224.
//  Every 1024 samples (approx 1/5 of a scanline), a tick is sent to the rendering thread
- (void)addPixel:(float)value
{
	int v ;

	// scale input data so that blacklevel is at about 16 and white is at about 240 in a 0-255 scale
	if ( dev850 ) {
		// v0.73  (+,-)425 Hz deviation for DWD
		v = ( value + 0.279 )*459 ;
	}
	else {
		//  (+,-)400
		v = ( value + 0.263 )*485 ;
	}
	if ( v < 0 ) v = 0 ; else if ( v > 255 ) v = 255 ;
	
	[ faxFrame addPixel:v ] ;

	if ( !running ) return ;
	
	if ( imageParametersChanged ) {
		[ faxFrame setSamplingParameters ] ;
		[ self redrawFAX ] ;
		imageParametersChanged = NO ;
	}
	if ( [ faxFrame passedMark ] && [ updateLock tryLock ] ) {
		//  skip this step if busy
		[ self outputLine ] ;
		[ updateLock unlock ] ;
	}
}

//	v0.73
- (void)setDeviation:(int)state
{
	dev850 = ( state != 0 ) ;
}

- (id)initWithFrame:(NSRect)imageframe
 {
    self = [ super initWithFrame:imageframe ];
    if ( self ) {
		// display appearance
		scrollerHeight = 2400 ;
		running = paused = NO ;
		nominalBlackLevel = 32 ;
		nominalContrast = 192 ;
		imageParametersChanged = NO ;
		updateRequested = NO ;
		dev850 = NO ;						//  v0.73
		
		spareImage = [ [ NSImage alloc ] init ] ;
	
		// set grayscale table to nominal blackLevel and contrast
		[ faxFrame setGrayscaleFrom:nominalBlackLevel to:nominalBlackLevel+nominalContrast ] ;

		//  sync detector
		goertzelWindow = CMMakeBlackmanWindow( 256 ) ;
		startTone = cos( 2*3.1415926535/CMFs*300 ) ;
		stopTone = cos( 2*3.1415926535/CMFs*450 ) ;		
		vsyncState = VSYNCWAIT ;
		linesFromTop = 5000 ;
	}
    return self;
}

//  connect actions to Nib
- (void)awakeFromNib
{
	NSRect sframe ;
	
	updateLock = [ [ NSLock alloc ] init ] ;
	drawLock = [ [ NSLock alloc ] init ] ;
	firstDraw = YES ;
	[ super awakeFromNib ] ;
	ppm = [ clockOffsetField floatValue ] ;						// A/D clock adjustment
	[ runLight setBackgroundColor:[ NSColor redColor ] ] ;
	
	sframe = [ scroller frame ] ;
	sframe.origin.y += 30.0 ;
	[ scroller setFrame:sframe ] ;
	
	scrollerHeight = 2400 ;
	viewHeight = [ self bounds ].size.height + 11 ;
	[ scroller setFloatValue:0.0 ] ;
	[ scroller setMinValue:0.0 ] ;
	[ scroller setMaxValue:scrollerHeight ] ;
	[ self unconditionalSetPosition:0 ] ;

	//  clear both the row number of the display image and the pointer to the backingBuffer
	[ faxFrame resetFrame ] ;

	[ self setInterface:halfButton to:@selector(scaleChanged:) ] ;
	[ self setInterface:blackLevelSlider to:@selector(grayscaleChanged) ] ;
	[ self setInterface:contrastSlider to:@selector(grayscaleChanged) ] ;
	[ self setInterface:clockOffsetField to:@selector(ppmChanged) ] ;
	[ self setInterface:clockOffsetStepper to:@selector(ppmStepped) ] ;
	[ self setInterface:pauseButton to:@selector(pauseChanged) ] ;
	[ self setInterface:newButton to:@selector(newChanged) ] ;
	[ self setInterface:saveButton to:@selector(savePushed) ] ;
	[ self setInterface:scroller to:@selector(scrollBufferFromScroller) ] ;
	
	//  v 0.57d no longer used [ NSThread detachNewThreadSelector:@selector(drawThread:) toTarget:self withObject:self ] ;
}

- (void)updateRequest 
{
	if ( updateRequested ) return ;
	updateRequested = YES ;
	if ( [ updateLock tryLock ] ) {
		[ self redrawFAX ] ;
		[ updateLock unlock ] ;
	}
	updateRequested = NO ;
}

//  action for half/full button
- (void)scaleChanged:(id)button
{
	int oldHeight, oldPos ;
	Boolean halfSize ;
	
	halfSize = ( [ button state ] != NSOnState ) ;
	[ faxFrame setHalfSize:halfSize ] ;
	[ button setTitle:( halfSize == NO ) ? NSLocalizedString( @"Full", nil ) : NSLocalizedString( @"Half", nil ) ] ;
	
	oldHeight = scrollerHeight ;
	scrollerHeight = ( halfSize == YES ) ? 2400 : 4800 ;
	oldPos = [ scroller intValue ] ;
	[ scroller setMaxValue:scrollerHeight ] ;
	[ scroller setIntValue:( oldPos*scrollerHeight )/oldHeight ] ;
	[ self updateRequest ] ;
	[ [ self enclosingScrollView ] setHasHorizontalScroller:( halfSize == NO ) ] ;
}

- (void)setupScale:(Boolean)full
{
	[ halfButton setState:( full ) ? NSOnState : NSOffState ] ;
	[ self scaleChanged:halfButton ] ;
}

- (Boolean)scaleIsFullSize
{
	return ( [ halfButton state ] == NSOnState ) ;
}

- (void)grayscaleChanged
{
	float blackLevel, contrast ;
	
	blackLevel = nominalBlackLevel - [ blackLevelSlider floatValue ] ;
	contrast = nominalContrast - [ contrastSlider floatValue ] ;
	[ faxFrame setGrayscaleFrom:blackLevel to:blackLevel+contrast ] ;
	[ self updateRequest ] ;
	//  v0.57d
	//if ( pipeEnabled ) write( fdOut, updateRequest, 1 ) ;
}

- (void)ppmChanged
{
	ppm = (int)[ clockOffsetField floatValue ] ;				// A/D clock adjustment
	[ clockOffsetStepper setFloatValue:ppm ] ;
	[ faxFrame setPPM:ppm ] ;
	imageParametersChanged = YES ;
}

- (void)ppmStepped
{
	int stepsSinceMouseDown ;
	
	stepsSinceMouseDown = [ (FAXStepper*)clockOffsetStepper steps ] ;
	ppm = (int)[ clockOffsetStepper floatValue ] ;				// A/D clock adjustment
	if ( stepsSinceMouseDown > 1 ) {
		if ( stepsSinceMouseDown > 5 ) stepsSinceMouseDown = 5 ;
		ppm = ppm + stepsSinceMouseDown*( ppm - [ clockOffsetField floatValue ] ) ;
		[ clockOffsetStepper setFloatValue:ppm ] ;
	}
	[ clockOffsetField setFloatValue:ppm ] ;
	[ self ppmChanged ] ;

	imageParametersChanged = YES ;
}

- (void)newChanged
{
	if ( [ pauseButton state ] == NSOnState ) {
		[ pauseButton setState:NSOffState ] ;
		[ pauseButton setTitle:NSLocalizedString( @"Pause", nil ) ] ;
		[ runLight setBackgroundColor:[ NSColor greenColor ] ] ;
		running = YES ;
	}
	[ self start ] ;
}

- (void)savePushed
{
	NSString *folder ;
	NSRect rect ;
	
	folder = [ tempFolder stringValue ] ;
	
	rect = [ self bounds ] ;
	[ faxFrame dumpCurrentFrameToFolder:folder ] ;
}

- (void)pauseChanged
{
	if ( [ pauseButton state ] == NSOnState ) {
		[ pauseButton setTitle:NSLocalizedString( @"Resume", nil ) ] ;
		running = NO ;
		paused = YES ;
		[ runLight setBackgroundColor:[ NSColor redColor ] ] ;
	}
	else {
		[ pauseButton setTitle:NSLocalizedString( @"Pause", nil ) ] ;
		[ runLight setBackgroundColor:[ NSColor greenColor ] ] ;
		running = YES ;
		paused = NO ;
		if ( vsyncState == VSYNCSTARTWAIT ) vsyncState = VSYNCWAIT ;
	}
}

- (void)setPPM:(float)value
{
	ppm = value ;
	[ faxFrame setPPM:ppm ] ;
	[ clockOffsetField setFloatValue:ppm ] ;
	[ clockOffsetStepper setFloatValue:ppm ] ;
	[ faxFrame setSamplingParameters ] ;
}

- (void)setFolder:(NSString*)folder
{
	[ tempFolder setStringValue:folder ] ;
}

- (NSString*)folder
{
	return [ tempFolder stringValue ] ;
}

- (IBAction)selectFolder:(id)sender
{
	NSOpenPanel *panel ;
	NSString *current ;
	int result ;
	
	panel = [ NSOpenPanel openPanel ] ;
	[ panel setCanChooseDirectories:YES ] ;
	
	[ panel setCanCreateDirectories:YES ] ;
	[ panel setNameFieldLabel:@"Select Directory" ] ;
	//  use a garbage type so we can only choose directories
	result = [ panel runModalForTypes:[ NSArray arrayWithObjects:@"onlyPickFolders", nil ] ] ;
	if ( result == NSOKButton ) {
		current = [ panel filename ] ;
		[ tempFolder setStringValue:[ current stringByAbbreviatingWithTildeInPath ] ] ;
	}
}

- (IBAction)clearFolder:(id)sender 
{
	NSString *current ;
	
	current = [ tempFolder stringValue ] ;
	if ( [ current length ] == 0 ) return ;
	[ tempFolder setStringValue:@"" ] ;
}

//  horizontal positioning
- (void)mouseDown:(NSEvent*)event
{	
	float position ;

	position = [ self convertPoint:[ event locationInWindow ] fromView:nil ].x ;
	[ faxFrame mouseDownAt:position ] ;
	[ self updateRequest ] ;
}

@end
