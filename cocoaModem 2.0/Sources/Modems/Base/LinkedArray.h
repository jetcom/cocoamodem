//
//  LinkedArray.h
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/8/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef struct _DE_ {
	id data ;
	struct _DE_ *next ;
} DataElement ;

@interface LinkedArray : NSObject {
	DataElement *array, *head, **idle, *all, *current ;
	int elements, idleElements ;
	int capacity ;
	NSLock *busy ;
	NSString *ident ;
}

- (id)initWithCapacity:(int)size ;
- (id)initWithCapacity:(int)size ident:(NSString*)inIdent ;

- (int)count ;
- (id)objectAtIndex:(int)index ;
- (id)nextObject ;
- (int)indexOfObject:(id)object ;		//  v0.58

//  insert object
- (void)addObject:(id)object ;
- (void)insertObject:(id)object atIndex:(int)index ;

//  remove object
- (void)removeObjectAtIndex:(int)index ;
- (void)removeObject:(id)object ;
- (void)removeAllObjects ;

//  move object
- (void)increaseIndexOfObject:(id)object ;
- (void)increaseIndexOfObjectAtIndex:(int)index ;

@end
