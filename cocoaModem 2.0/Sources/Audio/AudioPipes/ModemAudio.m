//
//  ModemAudio.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 10/19/09.
//  Copyright 2009 Kok Chen, W7AY. All rights reserved.
//

#import "ModemAudio.h"
#import "Application.h"
#import "AudioManager.h"
#import "Messages.h"
#import "TextEncoding.h"
#import "audioutils.h"


@implementation ModemAudio

#define kLeftChannel	1
#define kRightChannel	2

#define	ookLevel		0.9

- (id)init
{
	int i ;
	SoundCardInfo *s ;
	
	self = [ super init ] ;
	if ( self ) {
		audioManager = [ [ NSApp delegate ] audioManager ] ;
		isInput = YES ;
		channels = 2 ;											// 1 for mono devices
		channel = 0 ;											// left
		isSampling = restartSamplingOnWakeup = started = NO ;
		savedIOProc = nil ;
		selectedSoundCard = nil ;
		previousDeviceID = 0 ;
		previousSamplingRate = 0.0 ;
		dbSlider = scalarSlider = nil ;
		nonOOKLevel = 0.95 ;
		dbPad = nil ;
		currentDB = dBmin = dBmax = 0 ;							//  v0.88d
		for ( i = 0; i < MAXDEVICES; i++ ) {
			s = &info[i] ;
			s->streamID = 0 ;
			s->deviceID = 0 ;
		}
		resamplingPipeChannels = 2 ;		
		startStopLock = [ [ NSLock alloc ] init ] ;
	}
	return self ;
}

//  v0.85
- (int)channel
{
	return channel ;
}

- (Boolean)isInput
{
	return isInput ;
}

//  subclass (ModemSource or ModemDest) should override this  
- (void)deviceHasChanged:(short)code deviceID:(AudioDeviceID)inDeviceID
{
}

// return number of devices found (limited by maxdev)
static int discoverSoundCards( SoundCardInfo *info, int maxdev, Boolean isInput )
{
    NSString *name, *refname ;
	NSRange searchRange ;
	CFStringRef cfname ;
	AudioDeviceID list[MAXDEVICES], device ;
    AudioStreamID stream[16] ;
 	char cname[129] ;
	int devices, count, i, j, k, n, streams, status ;
	UInt32 datasize ;
 	Boolean writable ;
 	SoundCardInfo *d, *e ;
	
	count = 0 ;
    devices = enumerateAudioDevices( list, MAXDEVICES ) ;

    for ( i = 0; i < devices; i++ ) {
        device = list[i] ;
 		//  check if device responds to a CFName call
		datasize = 0 ;
		status = AudioDeviceGetPropertyInfo( device, 0, false, kAudioObjectPropertyName, &datasize, NULL ) ;
		if ( status == 0 && datasize != 0 ) {
			datasize = sizeof( CFStringRef ) ;
			status = AudioDeviceGetProperty( device, 0, false, kAudioObjectPropertyName, &datasize, &cfname ) ;
			name = [ NSString stringWithString:(NSString*)cfname ] ;
			CFRelease( cfname ) ;
		}
		else {
			//  use old Cstring call (RME FireFace 400), convert to NSString
			datasize = 128 ;
			status = AudioDeviceGetProperty( device, 0, false, kAudioDevicePropertyDeviceName, &datasize, cname ) ;
			name = [ NSString stringWithCString:cname encoding:kTextEncoding ] ;
		}

		//  check for number of streams for device
		AudioDeviceGetPropertyInfo( device, 0, isInput, kAudioDevicePropertyStreams, &datasize, &writable ) ;
		AudioDeviceGetProperty( device, 0, isInput, kAudioDevicePropertyStreams, &datasize, stream ) ;
		streams = datasize/sizeof( AudioStreamID ) ;
		if ( streams ) {
			for ( j = 0; j < streams; j++ ) {
				if ( count < maxdev ) {
					info[count].streamIndex = j ;
					info[count].deviceID = device ;
					info[count].streamID = stream[j] ;
					info[count].name = [ [ NSString alloc ] initWithString:name ] ;
					count++ ;
				}
			}
		}
    }
	//  now modify names for devices with the same name and device with multiple streams
	for ( i = 0; i < count-1; i++ ) {
		d = &info[i] ;
		//  modify devices that have the same name 
		for ( j = i+1; j < count; j++ ) {
			e = &info[j] ;
			if ( [ d->name isEqualToString:e->name ] ) {
				n = 1 ;
				refname = d->name ;
				//  shorten name if possible
				name = [ NSString stringWithString:d->name ] ;
				searchRange = [ name rangeOfString:@"(" ] ;
				if ( searchRange.location != NSNotFound ) {
					name = [ [ name substringToIndex:searchRange.location ] stringByTrimmingCharactersInSet:[ NSCharacterSet whitespaceCharacterSet ] ] ;
				}
				//  change duplicate names to "name (1)", "name (2)" etc.
				for ( k = i; k < count; k++ ) {
					e = &info[k] ;
					if ( [ refname isEqualToString:e->name ] ) {
						[ e->name autorelease ] ;
						e->name = [ name stringByAppendingFormat:@" (%d)", n++ ] ;
					}
				}
				break ;
			}
		}
	}
    return count ;
}

//  (Private API)
//  set menu with names in deviceList
- (void)setMenuTo:(SoundCardInfo*)deviceList menu:(NSPopUpButton*)menu
{
	NSMenuItem *item ;
	int i, j, n ;
	
	[ menu removeAllItems ] ;
	if ( soundcards == 0 ) {
		[ menu addItemWithTitle:@"" ] ;
		[ menu setEnabled:false ] ;
		return ;
	}
	[ menu setEnabled:true ] ;
	j = 0 ;
	for ( i = 0; i < soundcards; i++ ) {
		[ menu addItemWithTitle:deviceList[i].name ] ;
		n = [ menu numberOfItems ] ;
		if ( n > j ) {
			//  ignore repeated names (NSPopUpButton cannot handle it)
			item = (NSMenuItem*)[ menu itemAtIndex:j ] ;
			[ item setTag:i ] ;			// set tag to menu index
			j++ ;
		}
	}
}

//  return index of source menu if successful, -1 if not successful 
- (int)sourceMenuChanged
{
	UInt32 dataSource, datasize ;
	OSStatus status ;
	NSMenuItem *item ;
	int index ;
	
	index = [ sourceMenu indexOfSelectedItem ] ;
	if ( index < 0 || selectedSoundCard == nil ) return -1 ;
	
	//  don't set source if there is only one (tag would not exist)
	if ( [ sourceMenu numberOfItems ] <= 1 ) return 0 ;
	
	//  NOTE: datasource was saved in the source menu by -updateSourceMenu 
	item = (NSMenuItem*)[ sourceMenu itemAtIndex:index ] ;
	dataSource = [ item tag ] ;
	datasize = sizeof( UInt32 ) ;
	status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, 0, isInput, kAudioDevicePropertyDataSource, datasize, &dataSource );
	if ( status != 0 ) {
		NSLog( @"cannot set sound card source/destination? %d", (int)dataSource ) ;
		return -1 ;
	}
	return index ;
}

//	switch source to the one with the name passed in
//  return index of source menu if successful, -1 if not successful
- (int)selectSource:(NSString*)name
{
	[ sourceMenu selectItemWithTitle:name ] ;
	return [ self sourceMenuChanged ] ;				//  try switching Core Audio to it
}

//	update source menu from CoreAudio
//	select the default source
- (int)updateSourceMenu
{
	int i, index, sources ;
	OSStatus status ;
	UInt32 datasize, defaultIndex, dataSource[16], defaultSourceID ;
	NSMenuItem *item ;
	AudioDeviceID devID ;
	AudioValueTranslation transl ;
	CFStringRef cfname ;
	
	index = [ soundCardMenu indexOfSelectedItem ] ;
	[ sourceMenu removeAllItems ] ;
	
	if ( index < 0 ) {
		// no device found
		[ sourceMenu addItemWithTitle:@"Default" ] ;
		[ sourceMenu setEnabled:NO ] ;
		return 0 ;
	}
	[ sourceMenu setEnabled:YES ] ;
	devID = info[index].deviceID ;

	// get sources (up to 16)
	datasize = 16*sizeof( UInt32 ) ;
	status = AudioDeviceGetProperty( devID, 0, isInput, kAudioDevicePropertyDataSources, &datasize, &dataSource[0] ) ;
	sources = datasize/sizeof( UInt32 ) ;
	
	if ( status != 0 || sources < 0 ) {
		// no sources found
		[ sourceMenu addItemWithTitle:@"Default" ] ;
		[ sourceMenu setEnabled:NO ] ;
		return 0 ;
	}
	//  set up default sourceID
	defaultIndex = 0 ;
	datasize = sizeof( UInt32 ) ;
	status = AudioDeviceGetProperty( devID, 0, isInput, kAudioDevicePropertyDataSource, &datasize, &defaultSourceID ) ;
	
	if ( status != 0 ) {
		// problem getting sources
		[ sourceMenu addItemWithTitle:@"Default" ] ;
		[ sourceMenu setEnabled:NO ] ;
		return 0 ;
	}

	for ( i = 0; i < sources; i++ ) {
		//  find the source with the name that is passed in
		transl.mInputData = &dataSource[i] ;
		transl.mInputDataSize = sizeof( UInt32 ) ;
		transl.mOutputData = &cfname ;
		transl.mOutputDataSize = sizeof( CFStringRef ) ;
		datasize = sizeof( AudioValueTranslation ) ;
		status = AudioDeviceGetProperty( devID, 0, isInput, kAudioDevicePropertyDataSourceNameForIDCFString, &datasize, &transl ) ;	//  v0.70  Kanji name for source
		if ( status == 0 && datasize == sizeof( AudioValueTranslation ) ) {
			// found a data source source, set value to source ID
			[ sourceMenu addItemWithTitle:(NSString*)cfname ] ;
			item = (NSMenuItem*)[ sourceMenu itemAtIndex:i ] ;
			[ item setTag:dataSource[i] ] ;									// set tag to sourceID
			if ( dataSource[i] == defaultSourceID ) defaultIndex = i ;
			CFRelease( cfname ) ;
		}
	}
	
	//  default microKEYER II to external line input
	if ( [ [ soundCardMenu titleOfSelectedItem ] isEqualToString:@"microHAM CODEC" ] ) defaultIndex = 1 ;	

	//  select menu item corresponding to the default sourceID
	[ sourceMenu selectItemAtIndex:defaultIndex ] ;	
	[ self sourceMenuChanged ] ;
	
	return defaultIndex ;
}

//  possibly some other app has changed the source for the device in use -- simply track it with our source menu
- (void)fetchSourceFromCoreAudio
{
	NSMenuItem *item ;
	OSStatus status ;
	UInt32 datasize, sourceID ;
	int i, sources ;
	
	if ( selectedSoundCard == nil ) return ;
	
	datasize = sizeof( UInt32 ) ;
	status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyDataSource, &datasize, &sourceID ) ;
	
	if ( status != 0 ) return ;
	
	//  check if sourceMenu is already correct
	item = (NSMenuItem*)[ sourceMenu selectedItem ] ;
	if ( [ item tag ] == sourceID ) return ;

	sources = [ sourceMenu numberOfItems ] ;
	for ( i = 0 ; i < sources; i++ ) {
		item = (NSMenuItem*)[ sourceMenu itemAtIndex:i ] ;
		if ( sourceID == [ item tag ] ) {
			[ sourceMenu selectItemAtIndex:i ] ;	
			return ;
		}
	}
}

- (Boolean)samplingRateChanged
{
	UInt32 datasize ;
	OSStatus status ;
	int rateIndex ;
	Float64 rate, currentRate ;
	
	if ( selectedSoundCard == nil ) return NO ;
	
	rateIndex = [ samplingRateMenu indexOfSelectedItem ] ;
	if ( rateIndex < 0 ) return NO ;
	
	datasize = sizeof( Float64 ) ;
	rate = [ [ samplingRateMenu titleOfSelectedItem ] intValue ] ;
	
	//  v0.78b  setting sampling rate is slow, so do a getProperty to check id we really need to change the sampling rate.
	status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyNominalSampleRate, &datasize, &currentRate ) ;
	if ( status == 0 && rate == currentRate ) return YES ;

	datasize = sizeof( Float64 ) ;
	status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, 0, isInput, kAudioDevicePropertyNominalSampleRate, datasize, &rate ) ;
	
	return ( status == 0 ) ;
}

static int selectableSampleRate[6] = { 11025, 16000, 32000, 44100, 48000, 96000 } ;

//	(Private API)
//	Find available sampling rate ranges and check against the 6 rates we allow.
- (void)updateSamplingRateMenu
{
	AudioValueRange range[64] ;
	UInt32 datasize ;
	OSErr status ;
	int i, j, sampleRanges, defaultIndex, currentIndex ;
	float low, high ;
	Boolean usable[6] ;

	[ samplingRateMenu removeAllItems ] ;
	if ( selectedSoundCard == nil ) return ;
	
	datasize = 0 ;
	status = AudioDeviceGetPropertyInfo( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyAvailableNominalSampleRates, &datasize, NULL ) ;
	if ( status == 0 && datasize != 0 ) {
		if ( datasize > sizeof( AudioValueRange )*64 ) datasize = sizeof( AudioValueRange )*64 ;
		status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyAvailableNominalSampleRates, &datasize, range ) ;
		if ( status == 0 ) {
			sampleRanges = datasize/sizeof( AudioValueRange ) ;
			if ( sampleRanges > 0 ) {
				for ( j = 0; j < 6; j++ ) usable[j] = NO ;
				for ( i = 0; i < sampleRanges; i++ ) {
					low = range[i].mMinimum, high = range[i].mMaximum ;
					for ( j = 0; j < 6; j++ ) {
						if ( low <= selectableSampleRate[j] && high >= selectableSampleRate[j] ) usable[j] = YES ;
					}
				}
				defaultIndex = currentIndex = 0 ;
				for ( j = 0; j < 6; j++ ) {
					if ( usable[j] ) {
						if ( j == 1 ) defaultIndex = currentIndex ;
						[ samplingRateMenu addItemWithTitle:[ NSString stringWithFormat:@"%d", selectableSampleRate[j] ] ] ;
						currentIndex++ ;
					}
				}
				[ samplingRateMenu selectItemAtIndex:defaultIndex ] ;
				return ;
			}
		}
	}
	//	add a single 44100 s/s rate if there are errors
	[ samplingRateMenu addItemWithTitle:@"44100" ] ;
	[ samplingRateMenu selectItemAtIndex:0 ] ;
}

//  override this to accept sample rate changes
- (void)actualSamplingRateSetTo:(float)rate
{
	NSLog( @"subclass need to implement -actualSamplingRateSetTo" ) ;
}

- (void)updateChannelMenu
{
	DevParams devParams ;
	ChannelBitPair *bitpair ;
	int index, i, besti ;
	
	[ channelMenu removeAllItems ] ;

	index = [ soundCardMenu indexOfSelectedItem ] ;
	if ( index < 0 || (int)info[index].streamID <= 0 ) {
		[ channelMenu addItemWithTitle:@"" ] ;
		[ channelMenu selectItemAtIndex:0 ] ;
		[ channelMenu setHidden:YES ] ;
		[ paramString setStringValue:@"" ] ;
		return ;
	}
	getDeviceParams( info[index].streamID, isInput, &devParams ) ;
	
	//  find best channels/depth (more channels are better)
	deviceBitPair.channels = deviceBitPair.bits = 0 ;
	besti = 0 ;
	for ( i = 0; i < devParams.bitPairs; i++ ) {
		bitpair = &devParams.channelBitPair[i] ;
		if ( devParams.channelBitPair[i].channels > deviceBitPair.channels ) {
			//  bitpair with more channels found
			deviceBitPair = *bitpair ;
			besti = i ;
		}
		else {
			if ( bitpair->channels == deviceBitPair.channels ) {
				//  equal number of channels, chose the one with more bits
				if ( bitpair->bits > deviceBitPair.bits ) {
					deviceBitPair = *bitpair ;
					besti = i ;
				}
			}
		}
	}
	[ paramString setStringValue:[ NSString stringWithFormat:@"%d ch/%d", deviceBitPair.channels, deviceBitPair.bits ] ] ;
	
	
	if ( deviceBitPair.channels <= 1 ) {
		[ channelMenu addItemWithTitle:@"" ] ;
		[ channelMenu setEnabled:NO ] ;
	}
	else {
		[ channelMenu setEnabled:YES ] ;
		if ( deviceBitPair.channels == 2 ) {
			//  stereo
			[ channelMenu addItemWithTitle:@"L" ] ;
			[ channelMenu addItemWithTitle:@"R" ] ;
		}
		else {
			//  multichannel
			for ( i = 0; i < deviceBitPair.channels; i++ ) {
				[ channelMenu addItemWithTitle:[ NSString stringWithFormat:@"%d", i+1 ] ] ;
			}
		}
		channel = baseChannel = 0 ;
		[ channelMenu selectItemAtIndex:channel ] ;
	}
}

//	Note: for stereo 0 = left, 1 = right
//		multichannel 0 = first channel, 1 = second channel, etc.
//	Return index of channel menu (or 0 if failed)
- (int)channelChanged
{
	int index ;
	
	index = [ channelMenu indexOfSelectedItem ] ;

	if ( index < 0 ) index = 0 ;	
	channel = index ;
	
	//  assume channel 2 of a 3-channel menu to be a stereo channel (not currently used, but can be used for I/Q)
	if ( channel == 2 && [ channelMenu numberOfItems ] == 3 ) index = channel = 0 ;
	
	//  baseChannel is the lower of the two channels that is being received.
	//	In the case of a stereo device, the baseChannel is 0.  
	//	In the case of a multichannel device, it is an even numbered channel.
	baseChannel = channel & 0xfffe ;
	
	//  now adjust level
	[ self setDeviceLevelFromSlider ] ;
	
	return index ;
}

- (int)selectChannel:(int)channelIndex
{
	[ channelMenu selectItemAtIndex:channelIndex ] ;
	return [ self channelChanged ] ;
}

- (float)samplingRateForDeviceID:(AudioDeviceID)devID
{
	OSStatus status ;
	UInt32 datasize ;
	Float64 rate ;

	datasize = sizeof( Float64 ) ;
	status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyNominalSampleRate, &datasize, &rate ) ;

	if ( status != 0 ) return 0.0 ;
	return rate ;
}

//  possibly some other app has changed the source for the device in use -- simply track it with our source menu
- (void)fetchSamplingRateFromCoreAudio
{
	float rate ;
	int nRate ;
	
	if ( selectedSoundCard == nil ) return ;
	
	rate = [ self samplingRateForDeviceID:selectedSoundCard->deviceID ] ;
	if ( rate < 7990.0 ) return ;
	
	//  check if we already agree with system (system sends two 'nsrt')
	//  if ( fabs( [ [ samplingRateMenu titleOfSelectedItem ] floatValue ] - rate ) < 10.0 ) return ;  -- was causing false negatives
	if ( fabs( previousSamplingRate - rate ) < 10.0 ) return ;
	
	nRate = rate ;
	previousSamplingRate = nRate ;
	
	[ samplingRateMenu selectItemWithTitle:[ NSString stringWithFormat:@"%d", nRate ] ] ;
	[ self actualSamplingRateSetTo:rate ] ;
}

- (Boolean)getDBRange:(AudioValueRange*)dbRange
{
	UInt32 datasize ;
	OSStatus status ;
	
	if ( selectedSoundCard == nil ) return NO ;

	datasize = sizeof( AudioValueRange ) ;
	status = AudioDeviceGetProperty( selectedSoundCard->deviceID, channel+kLeftChannel, isInput, kAudioDevicePropertyVolumeRangeDecibels, &datasize, dbRange ) ;

	if ( status != noErr ) {
		//  check master channel if stereo channel did not work
		datasize = sizeof( AudioValueRange ) ;
		status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyVolumeRangeDecibels, &datasize, dbRange ) ;
	}
	dBmin = dbRange->mMinimum ;
	dBmax = dbRange->mMaximum ;
	return ( status == noErr ) ;
}

//  fetch dB value and dB range to set slider
- (void)fetchDeviceLevelFromCoreAudio
{
	Float32 db ;
	AudioValueRange range ;
	UInt32 datasize ;
	OSStatus status ;
	
	if ( dbSlider != nil ) {
		datasize = sizeof( Float32 ) ;
		status = AudioDeviceGetProperty( selectedSoundCard->deviceID, channel+kLeftChannel, isInput, kAudioDevicePropertyVolumeDecibels, &datasize, &db ) ;

		if ( status != noErr ) {
			//  check master channel if stereo channel did not work
			datasize = sizeof( Float32 ) ;
			status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyVolumeDecibels, &datasize, &db ) ;
		}
		if ( status == noErr && [ self getDBRange:&range ] == YES ) {
			db = db - range.mMaximum ;
			if ( dbPad ) {
				db += [ dbPad floatValue ] ;
				if ( db > 0 ) db = 0 ;
			}
			[ dbSlider setFloatValue:db ] ;
		}
	}
	if ( scalarSlider != nil ) {
		datasize = sizeof( Float32 ) ;
		status = AudioDeviceGetProperty( selectedSoundCard->deviceID, channel+kLeftChannel, isInput, kAudioDevicePropertyVolumeScalar, &datasize, &db ) ;

		if ( status != noErr ) {
			//  check master channel if stereo channel did not work
			datasize = sizeof( Float32 ) ;
			status = AudioDeviceGetProperty( selectedSoundCard->deviceID, 0, isInput, kAudioDevicePropertyVolumeScalar, &datasize, &db ) ;
		}
		if ( status == noErr ) {
			[ scalarSlider setFloatValue:db ] ;
		}
	}
}

//  (Private API)
- (OSStatus)setScalarAudioLevel:(float)value 
{
	Float32 scalar ;
	UInt32 datasize ;
	OSStatus status ;

	scalar = currentLevel = value ;
	if ( selectedSoundCard == nil ) return noErr ;
	
	status = noErr ;
	datasize = sizeof( Float32 ) ;
	//  try setting individual channel(s) first
	if ( channels == 2 ) {
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, kLeftChannel, isInput, kAudioDevicePropertyVolumeScalar, datasize, &scalar ) ;
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, kRightChannel, isInput, kAudioDevicePropertyVolumeScalar, datasize, &scalar ) ;
	} else {
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, channel+kLeftChannel, isInput, kAudioDevicePropertyVolumeScalar, datasize, &scalar ) ;
	}
	if ( status != noErr ) {
		//  try master control if individual channel does not work
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, 0, isInput, kAudioDevicePropertyVolumeScalar, datasize, &scalar ) ;
	}
	return status ;
}

//  v0.85
- (void)setOOKDeviceLevel
{
	if ( fabs( currentLevel-ookLevel ) < 0.0001 ) return ;
	[ self setScalarAudioLevel:ookLevel ] ;
}

- (float)validateDeviceLevel
{
	if ( fabs( currentLevel-nonOOKLevel ) < 0.0001 ) return nonOOKLevel ;
	
	[ self setScalarAudioLevel:nonOOKLevel ] ;
	return nonOOKLevel ;
}

// v0.88d
- (void)changeDeviceGain:(int)direction
{
	Float32 dB ;
	UInt32 datasize ;
	OSStatus status ;
	
	// direction +ve -> increase gain

	if ( dBmin == dBmax ) return ;
	
	dB = currentDB + ( direction*0.5 ) ;	
	if ( dB >= dBmax || dB <= dBmin ) return ;	
	currentDB = dB ;
			
	datasize = sizeof( Float32 ) ;
	//  try setting individual channel(s) first
	if ( channels == 2 ) {
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, kLeftChannel, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &dB ) ;
		if ( status == noErr ) status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, kRightChannel, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &dB ) ;
	}
	else {
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, channel+kLeftChannel, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &dB ) ;
	}
	if ( status != noErr ) {
		//  try master control if individual channel does not work
		status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, 0, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &dB ) ;
	}
}

//	Set level from either the dBSlider or the scalarSlider
//	note: scalar level (0 = min, 1 = max)
- (void)setDeviceLevelFromSlider
{
	Float32 db, scalar ;
	int idb ;
	AudioValueRange range ;
	UInt32 datasize ;
	OSStatus status ;
	
	if ( selectedSoundCard == nil || ( dbSlider == nil && scalarSlider == nil ) ) return ;
	
	//  first check range
	if ( [ self getDBRange:&range ] == NO || ( range.mMaximum - range.mMinimum ) < 0.1 ) {
		if ( dbSlider ) {
			[ dbSlider setEnabled:NO ] ;
			[ dbSlider setFloatValue:0.0 ] ;
		}
		if ( scalarSlider ) {
			[ scalarSlider setEnabled:NO ] ;
			[ scalarSlider setFloatValue:1.0 ] ;
		}
	}
	//  round pad to an int
	if ( dbPad ) {
		idb = [ dbPad floatValue ] + 0.1 ;
		if ( idb < 0 ) idb = 0 ;
		[ dbPad setIntValue:idb ] ;
	}
		
	if ( dbSlider ) {
		db = range.mMaximum + [ dbSlider floatValue ] ;
		if ( dbPad ) db -= [ dbPad intValue ] ;
		if ( db < range.mMinimum ) db = range.mMinimum ;
		
		currentDB = db ;
		dBmin = range.mMinimum ;
		dBmax = range.mMaximum ;

		datasize = sizeof( Float32 ) ;
		//  try setting individual channel(s) first
		if ( channels == 2 ) {
			status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, kLeftChannel, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &db ) ;
			if ( status == noErr ) status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, kRightChannel, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &db ) ;
		}
		else {
			status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, channel+kLeftChannel, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &db ) ;
		}
		if ( status != noErr ) {
			//  try master control if individual channel does not work
			status = AudioDeviceSetProperty( selectedSoundCard->deviceID, nil, 0, isInput, kAudioDevicePropertyVolumeDecibels, datasize, &db ) ;
		}
		//  if already minimum, Core Audio will not call us back if set again to minimum
		if ( db <= range.mMinimum ) [ self fetchDeviceLevelFromCoreAudio ] ;
		
		[ dbSlider setEnabled:( status == noErr ) ] ;
	}
		
	if ( scalarSlider ) {
		scalar = [ scalarSlider floatValue ] ;
		if ( scalar < 0 ) scalar = 0 ; else if ( scalar > 1 ) scalar = 1 ;
		
		nonOOKLevel = scalar ;									//  v0.85
		status = [ self setScalarAudioLevel:nonOOKLevel ] ;		//  v0.85
		[ scalarSlider setEnabled:( status == noErr ) ] ;
	}		
}

- (void)registerLevelSlider:(NSSlider*)slider isScalar:(Boolean)useScalar
{
	if ( useScalar ) scalarSlider = slider ; else dbSlider = slider ;
}

//	update sound card menu from CoreAudio
//	default to first menu item but don't select sound card yet (returns menu index (0 always) )
- (int)updateSoundCardMenu
{
	soundcards = discoverSoundCards( &info[0], MAXDEVICES, isInput ) ;
	[ soundCardMenu removeAllItems ] ;
	if ( soundcards <= 0 ) {
		// no device
		[ soundCardMenu addItemWithTitle:@"Default" ] ;
		[ soundCardMenu setEnabled:NO ] ;
		return 0 ;
	}	
	[ self setMenuTo:&info[0] menu:soundCardMenu ] ;
	[ soundCardMenu setEnabled:YES ] ;
	[ soundCardMenu selectItemAtIndex:0 ] ;

	return 0 ;
}

//  select sound card pointed to by sound card menu
- (int)soundCardChanged
{
	SoundCardInfo *newSelection ;
	int selectedDevice ;
	
	selectedDevice = [ soundCardMenu indexOfSelectedItem ] ;
	if ( selectedDevice < 0 ) {
		selectedSoundCard = nil ;
		return -1 ;
	}
	
	//  refresh source menu. sampling rate menu and ask audioManager to act as listener
	newSelection = &info[selectedDevice] ;
	selectedSoundCard = newSelection ;
	
	//  v0.78b
	if ( selectedSoundCard != nil && previousDeviceID != selectedSoundCard->deviceID ) {
		if ( previousDeviceID != 0 ) {
			//  unregister old self...
			[ audioManager audioDeviceUnregister:previousDeviceID modemAudio:self ] ;
		}
		//  ...previousDeviceIDand replace with new DeviceID
		[ audioManager audioDeviceRegister:selectedSoundCard->deviceID modemAudio:self ] ;
		previousDeviceID = selectedSoundCard->deviceID ;
	}

	//  update source menu with this selected sound card
	[ self updateSourceMenu ] ;	
	//  ...update sampling rate menu
	[ self updateSamplingRateMenu ] ;
	//  ...L/R channel and bit depth
	[ self updateChannelMenu ] ;
	//  ... set dB slider
	[ self setDeviceLevelFromSlider ] ;
	//	... clear dB pad value
	if ( dbPad ) [ dbPad setIntValue:0 ] ;
	
	//  switch to actual sampling rate
	[ self fetchSamplingRateFromCoreAudio ] ;
	
	return selectedDevice ;
}

//	return index of selected sound card menu item, or -1 if not found
- (int)selectSoundCard:(NSString*)name
{
	if ( soundCardMenu == nil || [ soundCardMenu numberOfItems ] < 1 ) return -1 ;
	
	[ soundCardMenu selectItemWithTitle:name ] ;
	return [ self soundCardChanged ] ;
}

- (void)setupSoundCards
{
	[ self updateSoundCardMenu ] ;
	[ self updateSourceMenu ] ;
	[ self updateSamplingRateMenu ] ;
	[ self updateChannelMenu ] ;	
}

//  start data sampling
//	override by ModemSource or ModemDest
- (Boolean)startSoundCard
{
	return NO ;
}

//  stop data sampling
//	override by ModemSource or ModemDest
- (Boolean)stopSoundCard
{
	return NO ;
}

- (void)applicationTerminating 
{
}
	
- (int)needData:(float*)outbuf samples:(int)n channels:(int)ch
{
	NSLog( @"ModemAudio: needData called?? should be handled by ModemDest" ) ;
	return 0 ;
}

- (void)inputArrivedFrom:(AudioDeviceID)device bufferList:(const AudioBufferList*)input
{
    AudioBuffer *audiobuffer ;
	int streamIndex, samples ;
	
	if ( resamplingPipe != nil ) {
		streamIndex = selectedSoundCard->streamIndex ;
		if ( streamIndex >= input->mNumberBuffers ) streamIndex = 0 ;
		audiobuffer = ( AudioBuffer* )( &( input->mBuffers[ streamIndex ] ) ) ;
		//	setup number of channels
		channels = audiobuffer->mNumberChannels ;
		//  write bytes into data pipe (note: 512 stereo samples is 4096 bytes)
		samples = audiobuffer->mDataByteSize/( sizeof( float )*audiobuffer->mNumberChannels ) ;
		if ( ( samples%256 ) != 0 ) [ Messages logMessage:"Device input received %d samples; should be a multiple of 256", samples ] ;
		[ resamplingPipe write:audiobuffer->mData samples:samples ] ;
	}
}

- (void)accumulateOutputFor:(AudioDeviceID)device bufferList:(const AudioBufferList*)output accumulate:(Boolean)accumulate
{
	AudioBuffer *audiobuffer ;
    float *mdata, *pbuf, v ;
    int i, samples, streamIndex, deviceChannels, pipeChannels ;
	
	if ( outputMuted ) return ;
	
	streamIndex = selectedSoundCard->streamIndex ;
	if ( streamIndex >= output->mNumberBuffers ) streamIndex = 0 ;				// sanity check
	audiobuffer = ( AudioBuffer* )( &( output->mBuffers[ streamIndex ] ) ) ;
	
	//	setup number of channels
	channels = deviceChannels = audiobuffer->mNumberChannels ;
	pipeChannels = resamplingPipeChannels ;

	mdata = ( float* )audiobuffer->mData ;
	samples = audiobuffer->mDataByteSize/deviceChannels/sizeof( float ) ;

	if ( deviceChannels != pipeChannels ) {
		pbuf = pipeBuffer ;
		[ resamplingPipe readResampledData:pbuf samples:samples ] ;
		
		memset( mdata, 0, audiobuffer->mDataByteSize ) ;		//  first clear all of destination buffer		
		mdata = &mdata[ baseChannel + channel ] ;
		
		if ( accumulate == YES ) {
			if ( pipeChannels == 1 ) {
				//  mono pipe in multichannel device
				for ( i = 0; i < samples; i++ ) {
					v = pbuf[i] ;
					mdata[0] += v ;								//  v0.85  write into only one channel
					//mdata[1] += v ;							//  write into both device channels				
					mdata += deviceChannels ;
				}
			}
			else {
				if ( deviceChannels >= 2 ) {
					//  stereo pipe in multichannel device
					for ( i = 0; i < samples; i++ ) {
						mdata[0] += pbuf[0] ;
						mdata[1] += pbuf[1] ;
						mdata += deviceChannels ;
						pbuf += 2 ;
					}
				}
				else {
					//  stereo pipe in single channel device, mix to output
					for ( i = 0; i < samples; i++ ) {
						mdata[0] += ( pbuf[0] + pbuf[1] )*0.5 ;
						mdata++ ;
						pbuf += 2 ;
					}
				}
			}
		}
		else {
			if ( pipeChannels == 1 ) {
				//  mono pipe in multichannel device
				for ( i = 0; i < samples; i++ ) {
					v = pbuf[i] ;
					mdata[0] = v ;		//  v0.85  write into only one channel
					//mdata[1] = v ;		//  write into both device channels				
					mdata += deviceChannels ;
				}
			}
			else {
				if ( deviceChannels >= 2 ) {
					//  stereo pipe in multichannel device
					for ( i = 0; i < samples; i++ ) {
						mdata[0] = pbuf[0] ;
						mdata[1] = pbuf[1] ;
						mdata += deviceChannels ;
						pbuf += 2 ;
					}
				}
				else {
					//  stereo pipe in single channel device, mix to output
					for ( i = 0; i < samples; i++ ) {
						mdata[0] = ( pbuf[0] + pbuf[1] )*0.5 ;
						mdata++ ;
						pbuf += 2 ;
					}
				}
			}
		}
	}
	else {
		//  pipe and device has the same number of channels
		[ resamplingPipe readResampledData:mdata samples:samples ] ;
	}
}

@end
