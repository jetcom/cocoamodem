//
//  Preferences.h
//  cocoaModem
//
//  Created by Kok Chen on Thu May 20 2004.
//

#ifndef _PREFERENCES_H_
	#define _PREFERENCES_H_

	#import <Cocoa/Cocoa.h>
	#import "SubDictionary.h"

	@interface Preferences : NSObject {
		NSMutableDictionary *prefs ;
		NSString *path ;
		Boolean hasPlist ;
	}
	
	- (void)fetchPlist:(Boolean)copy ;
	- (void)savePlist ;
	
	- (Boolean)hasKey:(NSString*)key ;
	- (int)intValueForKey:(NSString*)key ;
	- (float)floatValueForKey:(NSString*)key ;
	- (NSString*)stringValueForKey:(NSString*)key ;
	- (NSArray*)arrayForKey:(NSString*)key ;
	- (NSDictionary*)dictionaryForKey:(NSString*)key ;							//  v0.78
	- (NSColor*)colorValueForKey:(NSString*)key ;
	- (NSObject*)objectForKey:(NSString*)key ;
	
	- (Boolean)booleanValueForKey:(NSString*)key ;								//  v1.01b
	- (void)setBoolean:(Boolean)value forKey:(NSString*)key ;					//  v1.01b
	
	- (void)setInt:(int)value forKey:(NSString*)key ;
	- (void)setFloat:(float)value forKey:(NSString*)key ;
	- (void)setString:(NSString*)string forKey:(NSString*)key ;
	- (void)setArray:(NSArray*)array forKey:(NSString*)key ;					//  v0.47
	- (void)setDictionary:(NSDictionary*)dict forKey:(NSString*)key ;			//  v0.78
	- (void)setColor:(NSColor*)color forKey:(NSString*)key ;
	- (void)setRed:(float)red green:(float)green blue:(float)blue forKey:(NSString*)key ;

	
	- (void)removeKey:(NSString*)key ;
	
	- (void)incrementIntValueForKey:(NSString*)key ;
	
	@end
	

#endif
