//
//  MultiStereoATC.m
//  cocoaModem
//
//  Created by Kok Chen on 2/25/05.
	#include "Copyright.h"
//

#import "MultiStereoATC.h"
#include "StereoRefATCBuffer.h"

//  This is an implementation of multiATC which derives takes an indepedent channel for clocking
//  First the dut signal stream calls importData
//  Then the reference signal stream calls importClockData

@implementation MultiStereoATC

static int hammingWeight[] = { 
	0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4,
	1, 2, 2, 3, 2, 3, 3, 4, 2, 3, 3, 4, 3, 4, 4, 5
} ;

- (id)init
{
	self = [ super init ] ;
	if ( self ) {
		config = nil ;
		scope = nil ;		
		dut = [ [ RTTYDecoder alloc ] initWithBitPeriod:22.0 ] ;
		ref = [ [ RTTYDecoder alloc ] initWithBitPeriod:22.0 ] ;
		dutStartBitSearch = refStartBitSearch = 0 ;
		dutSyncOffset = refSyncOffset = 0 ;
		tickDiff = balance = 0 ;
		estimate = 15.0 ;
		characterCount = 0 ;
	}
	return self ;
}

- (void)setConfigClient:(AnalyzeConfig*)cfg
{
	config = cfg ;
}

- (void)setScope:(AnalyzeScope*)ascope
{
	scope = ascope ;
}

//  the DUT streams calls this point, after that, reference stream calls importClockData
- (void)importData:(CMPipe*)pipe
{
	CMDataStream *stream ;
	int samples ;
	float *m, *s ;
	
	stream = [ pipe stream ] ;
	bitStream.sourceID = stream->sourceID ;
	samples = stream->samples ;
	if ( samples > 256 ) samples = 256 ;

	//  invert M/S polarity here.
	if ( invert ) {
		s = stream->array ;
		m = stream->array+samples ;
	}
	else {
		m = stream->array ;
		s = stream->array+samples ;
	}
	[ dut addSamples:samples mark:m space:s ] ;
}

//  new data is stuffed into the end of a 768-sample delay line
- (void)importClockData:(CMTappedPipe*)pipe
{
	CMDataStream *stream ;
	int samples ;
	float *m, *s ;
	
	stream = [ pipe stream ] ;
	bitStream.sourceID = stream->sourceID ;
	samples = stream->samples ;
	if ( samples > 256 ) samples = 256 ;
	
	//  invert M/S polarity here.
	if ( invert ) {
		s = stream->array ;
		m = stream->array+samples ;
	}
	else {
		m = stream->array ;
		s = stream->array+samples ;
	}
	[ ref addSamples:samples mark:m space:s ] ;
	[ self checkForCharacter ] ; 
}

static long lastSync = 0 ;
//static int syncCount = 0 ;

- (void)checkForCharacter
{
	CMATCPair refPair[256], dutPair[256], projPair[256] ;
	float atc ;
	int i, j, dataByte ;
	RTTYByte checkSync ;
	
	for ( i = 0 ; i < 256; i++ ) {
		tickDiff++ ;
		refSync.tick++ ;
		dutSync.tick++ ;
		dutStartBitSearch-- ;
		refStartBitSearch-- ;
		
		dutSyncOffset-- ;
		refSyncOffset-- ;
		
		//  first check if we have a sync in the dut channel
		if ( dutStartBitSearch <= 0 ) {
		
			[ dut validateSyncForMarkOffset:0 spaceOffset:0 sync:&dutSync ] ;
			
			//if ( dutSync.confidence > 0.01 ) printf( "character %3d: confidence %8.3f\n", characterCount, dutSync.confidence ) ;
			
			if ( dutSync.confidence > 0.4 ) {
				//printf( "sync %ld: %8.2f %ld\n", dutSync.tick, dutSync.confidence,  dutSync.tick+dutSync.offset-lastSync ) ;
			}
			else {
				[ dut bestAsyncForMarkOffset:5 spaceOffset:5 sync:&dutSync ] ;
				//if ( dutSync.confidence > 0.01 ) printf( "character %3d: async confidence %8.3f\n", characterCount, dutSync.confidence ) ;
				//if ( dutSync.frameSync ) printf( "async %8.2f @%ld\n", dutSync.confidence, dutSync.tick ) ; else if ( dutSync.confidence > 0.01 ) printf( "  %8.2f\n", dutSync.confidence ) ; 
			}
			
			[ dut checkSyncForMarkOffset:0 spaceOffset:0 sync:&checkSync ] ;
			if ( checkSync.frameSync && checkSync.confidence > 0.66 ) {
				[ config setSyncState:2 ] ;
			}
			else {
				[ config setSyncState:0 ] ;
			}
		
			if ( dutSync.frameSync && dutSync.confidence > 0.66 ) {
				lastSync = dutSync.tick + dutSync.offset ;
				//  fetch data
				dutSyncOffset = dutSync.offset ;
				//printf( "dist = %ld\n", dutSync.offset + dutSync.tick - dutSync.syncTick ) ;
				dutSync.syncTick = dutSync.offset + dutSync.tick ;
				dutStartBitSearch = 196 + ( dutSyncOffset ) ;
				dataByte = 0 ;
				atc = ( [ [ dut mark ] agcAtOffset:dutSyncOffset ] - [ [ dut space ] agcAtOffset:dutSyncOffset ] )*0.5 ;
				for ( j = 4; j >= 0; j-- ) {
					dataByte = ( dataByte << 1 ) + ( ( ( [ dut markAtBit:j offset:dutSyncOffset ] - [ dut spaceAtBit:j offset:dutSyncOffset ] - atc ) > 0 ) ? 1 : 0 ) ;
				}
				
				//printf( "0x%02x\n", dataByte ) ;
				
				
				RTTYByte tSync ;
				
				[ dut bestAsyncForMarkOffset:dutSyncOffset-8 spaceOffset:dutSyncOffset-8 sync:&tSync ] ;
				//printf( "byte 0x%02x %8.2f %8.2f\n", dataByte, dutSync.confidence, tSync.confidence ) ;
				
				characterCount++ ;
				[ self exportCharacter:dataByte buffer:atcDummyData ] ;
									
				if ( scope ) {						
					[ ref getBuffer:refPair markOffset:refSyncOffset spaceOffset:refSyncOffset ] ;
					[ scope addReference:refPair ] ;
					[ dut getBuffer:dutPair markOffset:dutSyncOffset spaceOffset:dutSyncOffset ] ;
					[ scope addDUT:dutPair ] ;
					[ dut getBuffer:projPair markOffset:dutSyncOffset spaceOffset:dutSyncOffset ] ;
					[ scope addCompensated:projPair ] ;
				}
				if ( balance == 0 ) {
					tickDiff = 0 ;
					balance = 1 ;
					savedByte = dataByte ;
				}
				else {
					if ( balance > 0 ) {
						//printf( "false positive\n" ) ;
						[ config frameError:1 ] ;		// two dut syncs in a row
						tickDiff = 0 ;
						balance = 1 ;
						savedByte = dataByte ;
					}
					else {
						if ( tickDiff < 30 ) {
							balance = 0 ;
							[ config accumBits:5 ] ;
							if ( savedByte != dataByte ) {
							
								//printf( "savedByte %02x dut %02x\n", savedByte, dataByte ) ;
								//[ dut dumpData ] ;
									
								[ self exportCharacter:-1 buffer:atcDummyData ] ;
								//printf( "+ref 0x%02x %2d tick = %3d dut 0x%02x %2d tick %3d\n", savedByte, refSync.offset, refSync.syncTick, dataByte, dutSync.offset, dutSync.syncTick ) ;
								[ config accumErrorBits:hammingWeight[ ( savedByte ^ dataByte )&0x1f ] ] ;
							}
						}
						else {
							//printf( "false negative\n" ) ;
							[ config frameError:2 ] ;		//  missed dut sync
							tickDiff = 0 ;
							balance = 1 ;
							savedByte = dataByte ;
						}
					}
				}
			}
		}
		
		//  now check if we have a sync in the ref channel
		if ( refStartBitSearch <= 0 ) {
			[ ref bestAsyncForMarkOffset:0 spaceOffset:0 sync:&refSync ] ;
			if ( refSync.frameSync && refSync.confidence > 0.5 ) {
			
				//if ( syncCount++ > 12 ) {
				//	[ dut checkSyncForMarkOffset:0 spaceOffset:0 sync:&checkSync ] ;
				//	exit( 0 ) ;
				//}

				//  fetch data
				refSyncOffset = refSync.offset ;
				refSync.syncTick = refSync.tick ;
				refSync.tick = 0 ;
				refStartBitSearch = 192 + refSyncOffset ;
				dataByte = 0 ;
				for ( j = 4; j >= 0; j-- ) {
					dataByte = ( dataByte << 1 ) + ( ( ( [ ref markAtBit:j offset:refSyncOffset ] - [ ref spaceAtBit:j offset:refSyncOffset ] ) > 0 ) ? 1 : 0 ) ;
				}
				//printf( "ref byte 0x%02x offset %d\n", dataByte, refSyncOffset ) ;
				if ( balance == 0 ) {
					tickDiff = 0 ;
					balance = -1 ;
					savedByte = dataByte ;
				}
				else {
					if ( balance < 0 ) {
						//printf( "false negative\n" ) ;
						[ config frameError:3 ] ;	//  two ref syncs in a row
						tickDiff = 0 ;
						balance = -1 ;
						savedByte = dataByte ;
					}
					else {
						if ( tickDiff < 30 ) {
							balance = 0 ;
							[ config accumBits:5 ] ;
							if ( savedByte != dataByte ) {
							
								//printf( "savedByte %02x ref %02x character %d\n", savedByte, dataByte, characterCount ) ;
								//[ dut dumpData ] ;

								[ self exportCharacter:-1 buffer:atcDummyData ] ;
								//printf( "-ref 0x%02x %2d tick = %3d dut 0x%02x %2d tick %3d\n", savedByte, refSync.offset, refSync.syncTick, dataByte, dutSync.offset, dutSync.syncTick ) ;
								[ config accumErrorBits:hammingWeight[ ( savedByte ^ dataByte )&0x1f ] ] ;
							}
						}
						else {
							//printf( "false positive\n" ) ;
							[ config frameError:4 ] ;	//  extra dut sync
							tickDiff = 0 ;
							balance = -1 ;
							savedByte = dataByte ;
						}
					}
				}
			}
		}
		[ ref advance ] ;
		[ dut advance ] ;
	}
}

@end
