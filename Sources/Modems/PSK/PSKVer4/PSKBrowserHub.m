//
//  PSKBrowserHub.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/26/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "PSKBrowserHub.h"
#import "Application.h"
#import "ClickedTableView.h"
#import "PSK.h"
#import "PSKReceiver.h"
#include <vecLib/vDSP.h>

//  LitePSKDemodulator userIndex errors
#define	FREQOUTOFRANGE		-3
#define	LOWERROWBUSY		-4
#define	UPPERROWBUSY		-5
#define	SLOTINUSE			-6
#define	TOOCLOSETONEIGHBOR	-7

@implementation PSKBrowserHub

- (id)initHub
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		useShiftJIS = NO ; // v0.70
		mainThread = [ NSThread currentThread ] ;
		demodBusy = [ [ NSLock alloc ] init ] ;
		pskBrowserSkipBuffer = [ [ NSLock alloc ] init ] ;
		dataPipe = [ [ DataPipe alloc ] initWithCapacity:2048*sizeof(float) ] ;
		[ self setupResampler ] ;		
		bufferIndex = 0 ;
		receiver = nil ;
		table = nil ;
		currentID = 0 ;
		scanIndex = 0 ;
		hasBrowser = YES ;
		enabled = NO ;
		squelch = ( 1.0 - 0.8 )*0.75 + 0.25 ;
		debugPrint = NO ;
		refreshedRow = 0 ;
		started = NO ;
		savedSkipMultipleDemodulators = skipMultipleDemodulators = YES ;
		
		//  TableView demodulators (sorted by frequency)
		sortedDemodulators = [ [ LinkedArray alloc ] initWithCapacity:64 ident:@"demods" ] ;
		idleDemodulators = [ [ LinkedArray alloc ]  initWithCapacity:64 ident:@"idle" ] ;
		removedDemodulators = [ [ LinkedArray alloc ]  initWithCapacity:64 ident:@"removed" ] ;
		for ( i = 0; i < 1000; i++ ) peak[i] = 0.001 ;
		
		//  create some demodulators; this can grow later
		for ( i = 0; i < 16; i++ ) {
			[ idleDemodulators addObject:[ [ LitePSKDemodulator alloc ] initWithClient:self uniqueID:currentID++ ] ] ;
		}
		//  spectrum for signal capture.
		//	sampling rate is 8000 samples/sec, Each bin is 0.9765 Hz wide.
		fft = FFTSpectrum( 13, YES ) ;
	}
	return self ;
}

//  don't really release it, simply make it idle and place it in the idleDemodulator list
- (int)releaseDemodulator:(LitePSKDemodulator*)demod
{
	int result = [ demod setToIdle ] ;
	[ idleDemodulators addObject:demod ] ;
	return result ;
}

//  check first to see if already have a demodulator in the idle list and use that
- (LitePSKDemodulator*)allocDemodulator
{
	LitePSKDemodulator *demod ;
	
	while ( [ idleDemodulators count ] > 0 ) {
		demod = [ idleDemodulators objectAtIndex:0 ] ;
		[ idleDemodulators removeObjectAtIndex:0 ] ;
		//  sanity check v0.58 -- check to make sure demod is not in use
		if ( [ sortedDemodulators indexOfObject:demod ] < 0 ) return demod ;
		// keep trying to find a demodulator that is not already used!
		NSLog( @"cocoaModem PSK TableView: demodulator exists in both idle and sorted linked lists.\n" ) ;
	}
	return [ [ LitePSKDemodulator alloc ] initWithClient:self uniqueID:currentID++ ] ;
}

- (void)dealloc
{
	int i ;
	
	for ( i = 0; i < [ sortedDemodulators count ]; i++ ) [ self releaseDemodulator:[ sortedDemodulators objectAtIndex:i ] ] ;
	[ sortedDemodulators release ] ;
	[ idleDemodulators release ] ;
	[ pskBrowserSkipBuffer release ] ;
	[ demodBusy release ] ;
	CMDeleteFFT( fft ) ;
	[ super dealloc ] ;
}

- (void)useControlButton:(Boolean)state
{
	[ (ClickedTableView*)table useControlButton:state ] ;
}

- (void)activateDemodulator:(LitePSKDemodulator*)demod frequency:(float)tone
{
	[ demod activateWithFrequency:tone ] ;
}

- (LitePSKDemodulator*)allocAndActivateDemodulatorAt:(float)tone
{
	LitePSKDemodulator *demod ;
	
	demod = [ self allocDemodulator ] ;
	[ demod activateWithFrequency:tone ] ;
	
	return demod ;
}

- (void)setBrowserTable:(NSTableView*)view
{
	NSWindow *window ;

	table = view ;
	if ( view ) {
		window = [ table window ] ;
		//  create data source for TableView
		browserTable = [ [ PSKBrowserTable alloc ] initWithTable:table client:self ] ;		
		[ table setDataSource:browserTable ] ;
		[ table setDelegate:browserTable ] ;
	}
}

- (void)enableReceiver:(Boolean)state
{
	enabled = state ;
}

- (void)tableViewSelectedTone:(float)tone option:(Boolean)option
{
	PSKReceiver *rx ;
	PSK *modem ;
	
	if ( option ) {
		modem = [ receiver controlModem ] ;
		rx = [ modem receiver:1 ] ;
		if ( rx == nil ) return ;
	}
	else rx = receiver ;
	
	[ rx selectFrequency:tone secondsAgo:15 fromWaterfall:NO ] ;
	[ rx setTransmitFrequencyToTone:tone ] ;
	[ rx setFrequencyDefined ] ;
}

- (void)inspectBrowserSpectrum
{
	int i, j, k, maxpos, toneCount, filteredToneCount, demodCount ;
	float freq, prevFreq, sum, target[2600], rawTones[22], tones[22], filteredTones[22], tone, maxv, hamming[2600], mean, denom, weighted[2600], sym[2600], test ;	
	LitePSKDemodulator *demod, *prevDemod ;
	
	//  Apply Hamming window to spectrum
	for ( i = 300; i < 2600; i++ ) {
		hamming[i] = spectrum[i-1] + 2.34*spectrum[i] + spectrum[i+1] ;
	}
	
	//  Look for symmetrical structure
	for ( i = 320; i < 2570; i++ ) {
		sum = 0 ;
		for ( j = 4; j < 16; j++ ) {
			sum += ( hamming[i-j]*hamming[i+j] )/sqrt( hamming[i-j]*hamming[i-j] + hamming[i+j]*hamming[i+j] ) ;
		}
		sym[i] = sum ;
	}
	//  find weighted estimate
	for ( i = 340; i < 2550; i++ ) {
		sum = 0 ;
		for ( j = 3; j < 15; j++ ) {
			sum += ( sym[i-j] + sym[i+j] ) ;
		}
		mean = sum/28 ;			
		weighted[i] = ( sym[i]-mean )/mean*sqrt( hamming[i] ) ;
	}
	//  find weighted estimate
	//	A pure carrier produces a negative response, a random BPSK31 signal produces a symmertical response with a sharp peak
	for ( i = 350; i < 2540; i++ ) {
		target[i] = weighted[i-1]+1.34*weighted[i]+weighted[i+1] ;
	}
	toneCount = 0 ;
	
	//  find peaks
	for ( i = 380; i < 2505; i++ ) {
		if ( target[i] > ( 181.0 + squelch*500.0 ) ) {
			//  found potential target; look for local peak
			maxv = target[i] ;
			maxpos = 0 ;
			for ( j = 1; j < 28; j++ ) {
				k = i+j ;
				test = target[k] ;
				if ( test > maxv ) {
					maxv = test ;
					maxpos = j ;
				}
			}
			//  try alternate peaks up to 35 bins ahead, in case we'd locked on a sideband
			for ( j = maxpos+14; j < maxpos+35; j++ ) {
				k = i+j ;
				test = target[k] ;
				if ( test > maxv ) {
					maxv = test ;
					maxpos = j ;
				}
			}
			//  refine tone (near maxpos)
			mean = 0 ;
			denom = 0.0001 ;
			maxpos += i ;
			if ( maxpos < 2500 ) {
				for ( j = maxpos-4; j <= maxpos+4; j++ ) {
					test = target[j] ;
					mean += j*test ;
					denom += test ;
				}
				tone = ( mean/denom )*( 8000/8192.0 ) ;
				rawTones[toneCount] = tone ;
				tones[toneCount++] = tone ;
				if ( toneCount > 21 ) toneCount = 21 ;		//  stop collecting after 21 of them!
			}
			i = maxpos+60 ;
		}
	}
	//  At this point, we have found tones in spectrum.  
	//  We now need to associate any tones with existing demodulators.  
	
	//  But first, we remove repeated demodulators (or demodulators that are too close to one another in frequency)
	demodCount =  [ sortedDemodulators count ] ;
	if ( demodCount > 1 ) {
		demod = [ sortedDemodulators objectAtIndex:0 ] ;
		prevFreq = [ demod frequency ] ;
		for ( j = 1; j < demodCount; j++ ) {
			demod = [ sortedDemodulators nextObject ] ;
			freq = [ demod frequency ] ;
			if ( fabs( prevFreq-freq ) < 30 ) {
				//  v0.58 check to make sure the demodulator is not already in the list
				if ( [ removedDemodulators indexOfObject:demod ] < 0 ) [ removedDemodulators addObject:demod ] ;
			}
			prevFreq = freq ;
		}
	}
	//  Next we check the frequency order of demodulators (sanity check and drifting signal)
	demodCount = [ sortedDemodulators count ] ;
	if ( demodCount > 1 ) {
		prevDemod = [ sortedDemodulators objectAtIndex:0 ] ;
		prevFreq = [ prevDemod frequency ] ;
		for ( i = 1 ; i < demodCount; i++ ) {
			demod = [ sortedDemodulators nextObject ] ;
			freq = [ demod frequency ] ;
			if ( freq < prevFreq ) {
				//  swap elements
				[ sortedDemodulators increaseIndexOfObjectAtIndex:i-1 ] ;
				break ;
			}
			prevFreq = freq ;
			prevDemod = demod ;
		}
	}
	//  We next identify the tones that correcspond to existing demoduators, and remove the tones that already have demodulators.
	//  We also try to AFC the frequency of the demodulators to the tones that we have found a match.
	demodCount = [ sortedDemodulators count ] ;
	for ( i = 0; i < demodCount; i++ ) {
		demod = ( i == 0 ) ? [ sortedDemodulators objectAtIndex:0 ] : [ sortedDemodulators nextObject ] ;
		[ demod setMark:1 ] ;	
		freq = [ demod frequency ] ;
		for ( j = 0; j < toneCount; j++ ) {
			tone = tones[j] ;
			if ( fabs( tone - freq ) < 32 ) {
				//  found a match, do an afc
				[ demod afcToFrequency:tone ] ;
				[ demod setMark:0 ] ;								//  do not remove
				//  now disable the tone from futher searches
				tones[j] = 0 ;
				break ;
			}
		}
	}
	//  Now start/continue the process of removing the demodulators that no longer have a tone in the spectrum.
	//  When the remove count has reached the limit, remove the demod object.	
	prevFreq = 0 ;
	demodCount = [ sortedDemodulators count ] ;
	for ( i = 0; i < demodCount; i++ ) {
		demod = [ sortedDemodulators objectAtIndex:i ] ;
		freq = [ demod frequency ] ;
		if ( [ demod mark ] == 1 ) {
			int removeCount = [ demod increaseRemoveCount ] ;
			int limit = 12 ;

			//  demodulator frequency no longer found in tone list, remove faster if it is close in frequency to other demodulators
			if ( fabs( prevFreq-freq ) < 64 ) limit = 6 ;
			else {
				if ( ( i+1 ) < demodCount ) {
					prevFreq = [ [ sortedDemodulators objectAtIndex:i+1 ] frequency ] ;
					if ( fabs( prevFreq-freq ) < 64 ) limit = 6 ;
				}
			}
			if ( removeCount > limit ) {
				//  demodulator has timed out
				//  v0.58 check to be sure the demodulator is not already in the removal list before adding it there
				if ( [ removedDemodulators indexOfObject:demod ] < 0 ) [ removedDemodulators addObject:demod ] ;
				demodCount-- ;
			}
		}
		prevFreq = freq ;
	}
	//  create a clean tone list
	filteredToneCount = 0 ;
	for ( i = 0; i < toneCount; i++ ) {
		tone = tones[i] ;
		if ( tone >= 380 && tone <= 2500 ) {
			filteredTones[ filteredToneCount++] = tone ;
		}
	}

	if ( debugPrint ) {
		printf( "----\n" ) ;
		if ( toneCount > 0 ) {
			printf( "filteredToneCount %d   All tones (%d):\n", filteredToneCount, toneCount ) ;
			for ( i = 0; i < toneCount; i++ ) printf( " %.0f(%.0f)", rawTones[i], tones[i] ) ;
			printf( "\n" ) ;
		}
		demodCount = [ sortedDemodulators count ] ;
		if ( demodCount > 0 ) {
			printf( "Active demodulators: %d (slot,row)\n", demodCount ) ;
			for ( i = 0; i < demodCount; i++ ) {
				demod = [ sortedDemodulators objectAtIndex:i ] ;
				int demodSlot = [ demod userIndex ] ;
				printf( " %.0f (%d,%d) ", [ demod frequency ], demodSlot, [ browserTable rowForSlot:demodSlot ] ) ;
			}
			printf( "\n" ) ;
		}
		debugPrint = NO ;
	}
	
	if ( filteredToneCount <= 0 ) return ;		//  no new tones found

	for ( i = 0; i < filteredToneCount; i++ ) {
		tone = filteredTones[i] ;
		demodCount = [ sortedDemodulators count ] ;
		if ( demodCount == 0 ) {
			demod = [ self allocAndActivateDemodulatorAt:tone ] ;
			[ sortedDemodulators addObject:demod  ] ;
		}
		else {
			freq = [ [ sortedDemodulators objectAtIndex:0 ] frequency ] ;
			for ( j = 0; j < demodCount; j++ ) {
				if ( freq > tone ) {
					demod = [ self allocAndActivateDemodulatorAt:tone ] ;
					[ sortedDemodulators insertObject:demod atIndex:j ] ;
					break ;
				}
				prevDemod = [ sortedDemodulators nextObject ] ;
				if ( prevDemod == nil ) {
					demod = [ self allocAndActivateDemodulatorAt:tone ] ;
					[ sortedDemodulators addObject:demod ] ;
					break ;
				}
				freq = [ prevDemod frequency ] ;
			}
		}
	}
}

//  New resampled data buffer (at 8000 s/s) arrives from the readThread (see base class).
//  v0.66 place inside lock
- (void)lockedSendBufferToDemodulators:(float*)buffer samples:(int)samples
{
	int i, count, slot, currentIndex, j ;
	float *currentBuf, fftbuf[8192] ;
	LitePSKDemodulator *demod ;
	
	assert( samples == 512 ) ;
		
	if ( skipMultipleDemodulators ) return ;

	currentIndex = bufferIndex ;
	currentBuf = &liteBuffer[ currentIndex*512 ] ;
	memcpy( currentBuf, buffer, 512*sizeof( float ) ) ;
	bufferIndex = ( bufferIndex+1 )%64 ;
	
	switch ( bufferIndex&0xf ) {
	case 0:
		//	process FFT every 8192 samples
		j = ( bufferIndex - 16 + 64 )%64 ;
		for ( i = 0; i < 16; i++ ) {
			memcpy( &fftbuf[i*512], &liteBuffer[j*512], 512*sizeof(float) ) ;
			j = ( j+1 ) % 64 ;
		}
		CMPerformFFT( fft, liteBuffer, spectrum ) ;
		break ;
	case 4:
		if ( [ demodBusy tryLock ] ) {
			[ poolBusy lock ] ;
			if ( [ NSThread currentThread ] == mainThread ) {
				[ self inspectBrowserSpectrum ] ;
			}
			else {
				//  inspect spectrum only if not busy, this way sortedDemodulators is locked
				[ self performSelectorOnMainThread:@selector(inspectBrowserSpectrum) withObject:nil waitUntilDone:YES ] ;
			}
			[ poolBusy unlock ] ;
			[ demodBusy unlock ] ;
		}
		started = YES ;		
		break ;
	case 8:
		//  periodically refresh a row of the browser to get rid of orphaned rows
		refreshedRow = ( refreshedRow+1 ) % 21 ;
		[ browserTable checkAndUpdateRow:refreshedRow ] ;
		break ;
	case 12:
		//  periodically remove disabled demodulators
		[ demodBusy lock ] ;
		count = [ sortedDemodulators count ] ;
		if ( count > 0 ) {
			demod = [ sortedDemodulators objectAtIndex:0 ] ;
			for ( i = 0; i < count; i++ ) {
				if ( [ demod disabled ] ) {
					//  v0.58 check to make sure the demodulator is not alrady in the removal list before placing it there
					if ( [ removedDemodulators indexOfObject:demod ] < 0 ) [ removedDemodulators addObject:demod ] ;
				}
				demod = [ sortedDemodulators nextObject ] ;
				if ( demod == nil ) break ;
			}
		}
		[ demodBusy unlock ] ;
		break ;
	case 14:
		//  periodically check of busy slots have freed up
		[ demodBusy lock ] ;
		count = [ sortedDemodulators count ] ;
		if ( count > 0 ) {
			demod = [ sortedDemodulators objectAtIndex:0 ] ;
			for ( i = 0; i < count; i++ ) {
				if ( [ demod userIndex ] == SLOTINUSE ) {
					//  check if slot is now available
					float freq = [ demod frequency ] ;
					int slot = ( freq-400 )/50 ;
					Slot *sp = [ browserTable slot ] ;
					
					if ( sp[slot].row < 0 ) {
						//  slot has freed up
						int targetRow = ( freq-400 )/100 ;
						if ( [ browserTable rowIsInUse:targetRow ] == NO ) {
							[ browserTable assignRow:targetRow toSlot:slot frequency:freq ] ;
							[ demod setUserIndex:slot ] ;
						}
					}
				}
				if ( demod == nil ) break ;
			}
		}
		[ demodBusy unlock ] ;
		break ;
	}
	[ demodBusy lock ] ;
	//  remove demodulators that are marked for removal (demodulators that are placed into the removedDemodulator LinkedArray.
	count = [ removedDemodulators count ] ;
	if ( count > 0 ) {
		for ( i = 0; i < count; i++ ) {
			demod = [ removedDemodulators objectAtIndex:i ] ;
			//  v0.58 sanity check -- make sure it is in the sortedDemodulator list before removing it
			if ( [ sortedDemodulators indexOfObject:demod ] >= 0 ) [ sortedDemodulators removeObject:demod ] ;
			slot = [ self releaseDemodulator:demod ] ;
			if ( slot >= 0 ) [ browserTable removeSlot:slot ] ;
		}
		[ removedDemodulators removeAllObjects ] ;
	}

	//  Finally, send the wideband signal to active demodulators for mixing and decoding.
	count = [ sortedDemodulators count ] ;	
	for ( i = 0; i < count; i++ ) {
		demod = [ sortedDemodulators objectAtIndex:i ] ;
		[ demod decode:liteBuffer offset:currentIndex ] ;
	}
	[ demodBusy unlock ] ;
}

- (void)sendBufferToDemodulators:(float*)buffer samples:(int)samples
{
	if ( [ pskBrowserSkipBuffer tryLock ] ) {		//  v0.66  skip buffer if the demodulators are too slow
		[ self lockedSendBufferToDemodulators:buffer samples:samples ] ;
		[ pskBrowserSkipBuffer unlock ] ;
	}
}

- (void)testCheck
{
	debugPrint = YES ;
}

- (Boolean)isEnabled
{
	return YES ;
}

//  v0.70
- (void)setUseShiftJIS:(Boolean)state
{
	useShiftJIS = state ;
}

//  v0.70
- (Boolean)useShiftJIS
{
	return useShiftJIS ;
}

//  v0.70
- (void)setJisToUnicodeTable:(unsigned char*)uarray
{
	memcpy( jisToUnicode, uarray, 65536*2 ) ;
}

//	-- data path --
//
//	importData (data from sound system; send to pipe)
//		inputResampleProc (convert 11025 to 8000 s/s)
//			readThread (read from pipe; supply data to inputResamplingProc)
//				sendBufferToDemodulators (send sound buffers to demodulator after resampling)
//			demodulator:newCharacter (decoded characters callback from demodulator)

//  ------------------------------------------------------------------------
//	callbacks from the LitePSKDemodulator
//	v0.70 input (decoded) can be 16 bit Unicode
- (void)demodulator:(LitePSKDemodulator*)demod newCharacter:(int)decode quality:(float)quality frequency:(float)freq
{
	int slot ;
	unichar uch ;
	
	if ( useShiftJIS ) {
		if ( decode >= 0x813f && decode < 0xfc50 ) {
			//  convert from shiftJIS to unicode
			uch = jisToUnicode[decode*2]*256 + jisToUnicode[decode*2+1] ;
		}
		else {
			//  ASCII range
			if ( ( decode < 32 || decode > 127 ) && decode != 0x8 ) uch = ' ' ; else uch = decode ;
		}
	}
	else {
		//  not in ShiftJIS state
		if ( ( decode < 32 || decode > 127 ) && decode != 0x8 ) uch = ' ' ; else uch = decode ;
	}
	
	slot = [ demod userIndex ] ;

	if ( quality > squelch*0.5 && slot >= 0 && slot < 41 ) {
		//  if carrier is not found, require higher quality to print
		if ( [ demod removeCount ] > 4 ) {
			if ( quality > squelch ) [ browserTable addUnicodeCharacter:uch toSlot:slot withFrequency:freq ] ;
		}
		else {
			[ browserTable addUnicodeCharacter:uch toSlot:slot withFrequency:freq ] ;
		}
		if ( quality > ( 1.0 + squelch )*0.5 ) [ demod decreaseRemovalCount:1 ] ;
	}
}

- (void)demodulator:(LitePSKDemodulator*)demod startingAtFrequency:(float)freq
{	
	int slot, slotrow, targetRow, slotForTargetRow ;
	float slotFreq ;
	Slot *sp ;
	
	slot = ( freq-400 )/50 ;
	
	if ( slot < 0 || slot > 40 ) {
		[ demod setUserIndex:FREQOUTOFRANGE ] ;				//  frequency out of range of browser table, not assigned
		return ;
	}
	sp = [ browserTable slot ] ;
	slotrow = sp[slot].row ;
	if ( slotrow < 0 ) {
		// slot available, check if the browser row is in use
		targetRow = ( freq-400 )/100 ;
		slotForTargetRow = [ browserTable slotForRow:targetRow ] ;
		if ( slotForTargetRow >= 0 && slotForTargetRow < 41 ) {
			//  targeted row is in use, now check if we can use an adjacent row
			slotFreq = sp[slotForTargetRow].frequency ;
			if ( freq < slotFreq ) {
				if ( [ browserTable rowIsInUse:targetRow-1 ] == NO ) {
					//  found a usable row
					targetRow-- ;
				}
				else {
					//  both row and row-1 are in use!
					[ demod setUserIndex:LOWERROWBUSY ] ;
					return ;
				}
			}
			else {
				if ( [ browserTable rowIsInUse:targetRow+1 ] == NO ) {
					//  found a usable row
					targetRow++ ;
				}
				else {
					//  both row and row+1 are in use!
					[ demod setUserIndex:UPPERROWBUSY ] ;
					[ demod setDisabled:YES ] ;
					return ;
				}
			}
		}
		//  found a row to insert the slot
		[ browserTable assignRow:targetRow toSlot:slot frequency:freq ] ;
		[ demod setUserIndex:slot ] ;
		return ;
	}		
	if ( slotrow >= 0 ) {
		[ demod setUserIndex:SLOTINUSE ] ;						// 50 Hz slot still in use
		return ;
	}
	slotFreq = [ browserTable frequencyForSlot:slot ] ;
	if ( fabs( slotFreq - freq ) < 48 ) {
		[ demod setUserIndex:TOOCLOSETONEIGHBOR ] ;				// too close to existing frequency
		return ;
	}
	if ( freq < slotFreq ) slot-- ; else slot++ ;
	if ( slot >= 0 && slot < 41 ) {
		if ( [ browserTable rowForSlot:slot] >= 0 ) {
			[ demod setUserIndex:TOOCLOSETONEIGHBOR ] ;			// too close to existing frequency
			return ;
		}
	}
}

//  Buffers arrive at 11025 s/s.
//  This is converted to 8000 in the readThread (in the base class) and to -sendBufferToDemodulators.
- (void)importBuffer:(float*)buf
{
	[ dataPipe write:buf length:512*sizeof( float ) ] ;
}

//  VFO offset and sideband are sent here from the PSK receiver
//  polarity = YES if USB
- (void)setVFOOffset:(float)offset sideband:(Boolean)polarity
{
	[ browserTable setVFOOffset:offset sideband:polarity ] ;
}


- (void)squelchChanged:(NSSlider*)slider
{
	squelch = ( 1.0 - [ slider floatValue ] )*0.75 + 0.25 ;
}

- (void)removeThread:(id)ourself
{
	int row, slotIndex, i, count, start, end ;
	float freq ;
	Slot *slot, *base ;
	LitePSKDemodulator *demod ;
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	
	start = 0 ;
	end = 21 ;
	
	base = [ browserTable slot ] ;
	for ( row = start; row < end; row++ ) {	
		slotIndex = [ browserTable slotForRow:row ] ;
		if ( slotIndex >= 0 ) {
			slot =  base + slotIndex ;
			freq = slot->frequency ;
			[ demodBusy lock ] ;
			count = [ sortedDemodulators count ] ;
			for ( i = 0; i < count; i++ ) {
				demod = [ sortedDemodulators objectAtIndex:i ] ;
				if ( fabs( [ demod frequency ] - freq ) < 30 ) {
					slotIndex = [ self releaseDemodulator:demod ] ;
					[ browserTable removeSlot:slotIndex ] ;
					[ sortedDemodulators removeObject:demod ] ;
					break ;
				}
			}
			[ demodBusy unlock ] ;
		}
	}
	[ pool release ] ;
}

- (void)rescanThread:(id)ourself
{
	int row, slotIndex, i, count, start, end ;
	float freq ;
	Slot *slot, *base ;
	LitePSKDemodulator *demod ;
	NSAutoreleasePool *pool = [ [ NSAutoreleasePool alloc ] init ] ;
	
	start = [ table selectedRow ] ;
	if ( start < 0 ) {
		start = 0 ;
		end = 21 ;
	}
	else end = start+1 ;

	base = [ browserTable slot ] ;
	for ( row = start; row < end; row++ ) {	
		slotIndex = [ browserTable slotForRow:row ] ;
		if ( slotIndex >= 0 ) {
			slot =  base + slotIndex ;
			freq = slot->frequency ;
			[ demodBusy lock ] ;
			count = [ sortedDemodulators count ] ;
			for ( i = 0; i < count; i++ ) {
				demod = [ sortedDemodulators objectAtIndex:i ] ;
				if ( fabs( [ demod frequency ] - freq ) < 30 ) {
					slotIndex = [ self releaseDemodulator:demod ] ;
					[ browserTable removeSlot:slotIndex ] ;
					[ sortedDemodulators removeObject:demod ] ;
					break ;
				}
			}
			[ demodBusy unlock ] ;
		}
	}
	[ pool release ] ;
}

- (void)rescan
{
	if ( [ NSThread currentThread ] == mainThread ) {
		[ self rescanThread:self ] ;
	}
	else {
		//  start thread to resan
		[ NSThread detachNewThreadSelector:@selector(rescanThread:) toTarget:self withObject:self ] ;
	}
}

- (void)openAlarm
{
	[ browserTable openAlarm ] ;
}

- (void)enableTableView
{
	NSWindow *window ;
	
	window = [ table window ] ;
	skipMultipleDemodulators = NO ;
	[ window setDelegate:self ] ;
	if ( ![ window isVisible ] ) {
		[ window orderFront:nil ] ;
	}
}

- (void)disableTableView
{
	NSWindow *window ;
	
	if ( table != nil ) {
		//  v0.78 check first if table is defined
		window = [ table window ] ;
		if ( window ) [ window orderOut:nil ] ;							
	}
	if ( skipMultipleDemodulators == YES ) return ;			// v0.78

	skipMultipleDemodulators = YES ;
	if ( [ NSThread currentThread ] == mainThread ) {
		[ self removeThread:self ] ;
	}
	else {
		[ NSThread detachNewThreadSelector:@selector(removeThread:) toTarget:self withObject:self ] ;
	}
}

- (void)nextStationInTableView ;		//  v0.97
{
	int i, index, slotIndex, rows, previousScanIndex ;
	float freq ;
	
	if ( table == nil || skipMultipleDemodulators == YES ) {
		NSBeep() ;
		return ;
	}
	previousScanIndex = scanIndex ;
	rows = [ table numberOfRows ] ;
	for ( i = 1; i < rows+1; i++ ) {
		index = ( scanIndex + i ) % rows ;
		slotIndex = [ browserTable slotForRow:index ] ;
		if ( slotIndex >= 0 ) {
			//  found an active row
			if ( index != previousScanIndex ) {
				scanIndex = index ;
				freq = [ browserTable selectSlot:slotIndex ] ;
				//if ( freq > 10 ) {
				//	ifreq = freq ;
				//	[ [ [ NSApp delegate ] application ] speakAssist:[ NSString stringWithFormat:@"Tuned to %d Hertz", ifreq ] ] ;
				//}
			}
			return ;
		}
	}
	if ( [ [ [ NSApp delegate ] application ] speakAssist:@"No signal" ] == NO ) {	//  v1.01b
		//	didn't find any active station
		[ browserTable unselectSlots ] ;
		NSBeep() ;
		[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.3 ] ] ;
		NSBeep() ;
	}
}

- (void)previousStationInTableView ;		//  v1.01c
{
	int i, index, slotIndex, rows, previousScanIndex ;
	float freq ;
	
	if ( table == nil || skipMultipleDemodulators == YES ) {
		NSBeep() ;
		return ;
	}
	previousScanIndex = scanIndex ;
	rows = [ table numberOfRows ] ;
	for ( i = 1; i < rows+1; i++ ) {
		index = ( scanIndex - i + rows ) % rows ;
		slotIndex = [ browserTable slotForRow:index ] ;
		if ( slotIndex >= 0 ) {
			//  found an active row
			if ( index != previousScanIndex ) {
				scanIndex = index ;
				freq = [ browserTable selectSlot:slotIndex ] ;
				//if ( freq > 10 ) {
				//	ifreq = freq ;
				//	[ [ [ NSApp delegate ] application ] speakAssist:[ NSString stringWithFormat:@"Tuned to %d Hertz", ifreq ] ] ;
				//}
			}
			return ;
		}
	}
	if ( [ [ [ NSApp delegate ] application ] speakAssist:@"No signal" ] == NO ) {
		//	didn't find any active station
		[ browserTable unselectSlots ] ;
		NSBeep() ;
		[ NSThread sleepUntilDate:[ NSDate dateWithTimeIntervalSinceNow:0.3 ] ] ;
		NSBeep() ;
	}
}

- (void)updateVisibleState:(Boolean)visible
{
	if ( visible == NO ) {
		//  interface switched away from PSK
		savedSkipMultipleDemodulators = skipMultipleDemodulators ;
		[ self disableTableView ] ;
	}
	else {
		// PSK interface made visible
		if ( savedSkipMultipleDemodulators == NO ) [ self enableTableView ] ;
	}
}

- (BOOL)windowShouldClose:(id)window
{
	if ( window == [ table window ] ) [ self disableTableView ] ;
	return YES ;
}

- (Boolean)updateFromPlist:(Preferences*)pref
{
	if ( browserTable ) [ browserTable updateFromPlist:pref ] ;
	return YES ;
}

- (void)retrieveForPlist:(Preferences*)pref
{
	if ( browserTable ) [ browserTable retrieveForPlist:pref ] ;
}


@end
