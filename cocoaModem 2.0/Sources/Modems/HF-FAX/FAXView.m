//
//  FAXView.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 3/27/06.
	#include "Copyright.h"
	
	
#import "FAXView.h"


@implementation FAXView

- (id)initWithFrame:(NSRect)imageframe
{
	NSSize bsize ;

    self = [ super initWithFrame:imageframe ];
    if ( self ) {
		bsize = [ self bounds ].size ;		
		faxFrame = [ [ FAXFrame alloc ] initWidth:bsize.width height:bsize.height ] ;
		[ self setImageScaling:NSScaleNone ] ;
		[ self setImage:[ faxFrame image ] ] ;

		dumpLock = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

- (BOOL)isOpaque
{
	return YES ;
}

- (void)awakeFromNib
{	
	[ faxFrame setSamplingParameters ] ;
}

//  (Test purpose)
- (int)physicalMemory
{
	struct task_basic_info tinfo;
	mach_msg_type_number_t tsize = sizeof( tinfo ) ;
	kern_return_t result ;

	result = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)&tinfo, &tsize ) ;
	if ( result != KERN_SUCCESS ) return 0 ;
	
	return tinfo.resident_size/1024/1024 ;
}

//  (Test purpose)
- (void)vmUse:(char*)title
{
	struct task_basic_info tinfo;
	mach_msg_type_number_t tsize = sizeof( tinfo ) ;
	kern_return_t result ;

	result = task_info( mach_task_self(), TASK_BASIC_INFO, (task_info_t)&tinfo, &tsize ) ;
	if ( result == KERN_SUCCESS ) printf( "%48s -- VM: %5d Physical %5d\n", title, (int)(tinfo.virtual_size/1024/1024), (int)(tinfo.resident_size/1024/1024 ) ) ;
}

//  set from Plist
- (void)setPPM:(float)value
{
	ppm = value ;
	[ faxFrame setPPM:ppm ] ;
	[ faxFrame setSamplingParameters ] ;
}

//  retrieve for Plist
- (float)ppm
{
	return ppm ;
}

//  v0.80 swap to a new NSBitmapImageRep, since Snow Leopard appears to cache it	
//	This is called whenever the image changes and needs to be displayed on the screen
- (void)swapImageRep
{
	[ faxFrame swapImageRep ] ;
}
	
@end
