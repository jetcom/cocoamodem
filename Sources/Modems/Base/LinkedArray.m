//
//  LinkedArray.m
//  cocoaModem 2.0
//
//  Created by Kok Chen on 11/8/08.
//  Copyright 2008 Kok Chen, W7AY. All rights reserved.
//

#import "LinkedArray.h"


@implementation LinkedArray


- (id)initWithCapacity:(int)size ident:(NSString*)inIdent
{
	int i ;
	
	self = [ super init ] ;
	if ( self ) {
		capacity = size ;
		array = head = current = nil ;
		busy = [ [ NSLock alloc ] init ] ;
		all = (DataElement*)calloc( capacity, sizeof( DataElement ) ) ;
		idle = (DataElement**)calloc( capacity, sizeof( DataElement* ) ) ;
		for ( i = 0; i < capacity; i++ ) idle[i] = &all[i] ;
		elements = 0 ;
		idleElements = capacity ;
		ident = [ [ NSString alloc ] initWithString:inIdent ] ;
	}
	return self ;
}

- (id)initWithCapacity:(int)size
{
	return [ self initWithCapacity:size ident:[ NSString stringWithFormat:@"%d", (int)self ] ] ;
}

- (id)init
{
	return [ self initWithCapacity:64 ] ;
}

- (void)dealloc
{
	free( all ) ;
	[ busy release ] ;
	[ ident release ] ;
	[ super dealloc ] ;
}

- (DataElement*)getIdleElement
{
	idleElements-- ;
	return idle[ idleElements ] ;
}

- (void)putIdleElement:(DataElement*)element
{
	idle[ idleElements ] = element ;
	idleElements++ ;
}

- (int)count
{
	return elements ;
}

- (DataElement*)assign:(id)object next:(DataElement*)next
{
	DataElement *p = [ self getIdleElement ] ;
	
	if ( elements >= capacity ) {
		NSLog( [ NSString stringWithFormat:@"DataArray exceeced capacity (%d)!", elements ] ) ;
		//assert( elements < capacity ) ;
		p = nil ;
		p->next = nil ;
		return p ;
	}
	
	p->next = next ;
	p->data = object ;
	elements++ ;
	return p ;
}

- (id)objectAtIndex:(int)index
{
	DataElement *p ;
	id object ;
	int i ;
	
	if ( index >= elements ) {
		NSLog( [ NSString stringWithFormat:@"DataArray objectAtIndex error: array index (%d) out of bounds (%d)!", index, elements ] ) ;
		assert( index < elements ) ;
		current = nil ;
		return nil ;
	}
	[ busy lock ] ;
	p = head ;
	for ( i = 0; i < index; i++ ) p = p->next ;
	if ( p == nil ) {
		DataElement *q = head ;
		for ( i = 0; i < elements; i++ ) {
			q = q->next ;
			if ( q == nil ) break ;
		}
	}
	object = p->data ;
	current = p ;
	[ busy unlock ] ;
	return object ;
}

//  after an objectAtIndex call, or aprevious nextObject call, this returns the next object, or nil
- (id)nextObject
{
	if ( current == nil ) return nil ;
	current = current->next ;
	if ( current == nil ) return nil ;
	return current->data ;
}

- (void)addObject:(id)object
{
	DataElement *p ;
	int i ;
	
	#ifdef DEBUGARRAY
	printf( "%s: addObject %d, count was %d\n", [ ident UTF8String ], (int)object, elements ) ;
	#endif
	
	if ( elements >= capacity ) {
		//  increase capacity here
		NSLog( @"Internal DataArray error: capacity reached!" ) ;
		assert( elements < capacity ) ;
		return ;
	}
	[ busy lock ] ;
	if ( elements == 0 ) {
		head = [ self assign:object next:nil ] ;
		[ busy unlock ] ;
		return ;
	}
	// find tail
	p = head ;
	for ( i = 0; i < elements; i++ ) {
		if ( p->next == nil ) break ;
		p = p->next ;
	}
	if ( i >= elements ) {
		NSLog( @"Internal DataArray error: did not find tail of linked list." ) ;
		[ busy unlock ] ;
		assert( i < elements ) ;
		return ;
	}
	p->next = [ self assign:object next:p->next ] ;
	[ busy unlock ] ;
}

- (void)insertObject:(id)object atIndex:(int)index
{
	DataElement *p ;
	int i ;
	
	#ifdef DEBUGARRAY
	printf( "%s: insertObject %d, at index %d, count was %d\n", [ ident UTF8String ], (int)object, index, elements ) ;
	#endif

	[ busy lock ] ;
	if ( index == 0 ) {
		//  let index 0 be used even if list is empty
		head = [ self assign:object next:head ] ;
		[ busy unlock ] ;
		return ;
	}

	if ( index >= elements ) {
		NSLog( [ NSString stringWithFormat:@"DataArray insertObject error: array index (%d) out of bounds (%d)!", index, elements ] ) ;
		[ busy unlock ] ;
		return ;
	}
	for ( p = head, i = 1; i < index; i++ ) p = p->next ;
	p->next = [ self assign:object next:p->next ] ;
	
	[ busy unlock ] ;
}

- (void)removeObjectAtIndex:(int)index
{
	DataElement *p, *q ;
	int i ;
	
	#ifdef DEBUGARRAY
	 printf( "%s: removeObjectAtIndex %d out of %d\n", [ ident UTF8String ], index, elements ) ;
	 #endif
	
	if ( index >= elements ) {
		NSLog( [ NSString stringWithFormat:@"DataArray removeObject error: array index (%d) out of bounds (%d)!", index, elements ] ) ;
		assert( index < elements ) ;
		return ;
	}
	[ busy lock ] ;
	if ( index == 0 ) {
		[ self putIdleElement:head ] ;
		elements-- ;
		head = head->next ;
		[ busy unlock ] ;
		return ;
	}	
	p = q = head ;	
	for ( i = 0; i < index; i++ ) {
		q = p ;
		p = p->next ;
	}
	[ self putIdleElement:p ] ;
	elements-- ;
	q->next = p->next ;

	[ busy unlock ] ;
}

//  find index of object, return -1 if not found
- (int)indexOfObject:(id)object
{
	DataElement *p ;
	int i ;

	[ busy lock ] ;
	p = head ;
	for ( i = 0; i < elements; i++ ) {
		if ( p == nil ) {
			[ busy unlock ] ;
			return -1 ;
		}
		if ( p->data == object ) {
			[ busy unlock ] ;
			return i ;
		}
		p = p->next ;
	}
	[ busy unlock ] ;
	return -1 ;
}

- (void)removeObject:(id)object
{
	Boolean found ;
	DataElement *p, *q ;
	int i ;
	
	found = NO ;
	[ busy lock ] ;
	p = q = head ;
	for ( i = 0; i < elements; i++ ) {
		if ( p == nil ) {
			NSLog( [ NSString stringWithFormat:@"DataArray internal error in removeObject: list shorter than it should be!" ] ) ;
			[ busy unlock ] ;
			assert( p != nil ) ;
			return ;
		}
		if ( p->data == object ) {
			if ( found ) {
				// sanity check
				NSLog( [ NSString stringWithFormat:@"DataArray removeObject error: object found in more than one location!" ] ) ;
				
				#ifdef DEBUGARRAY
				printf( "%s: index %d out of %d, object %d\n", [ ident UTF8String ], i, elements, (int)object ) ;
				#endif
				
				if ( p == head ) head = p->next ; else q->next = p->next ;		//  v0.58
				[ self putIdleElement:p ] ;										//  v0.58
				elements-- ;													//  v0.58
				p = q ;															//  v0.58
				
				// --- assert ( !found ) ;										//  v0.58
			}
			else {
				found = YES ;
				
				#ifdef DEBUGARRAY
				printf( "%s: removing index %d object %d\n", [ ident UTF8String ], i, (int)i ) ;
				#endif
				
				if ( p == head ) head = p->next ; else q->next = p->next ;
				[ self putIdleElement:p ] ;
				elements-- ;
				p = q ;
			}
		}
		q = p ;
		p = p->next ;
	}
	if ( !found ) {
		NSLog( [ NSString stringWithFormat:@"DataArray removeObject error: object not found!" ] ) ;
		// --- assert( found ) ;												//  v0.58
	}
	[ busy unlock ] ;
}

- (void)removeAllObjects
{
	DataElement *p ;
	int i ;
	
	[ busy lock ] ;
	p = head ;
	for ( i = 0; i < elements; i++ ) {
		if ( p == nil ) {
			NSLog( [ NSString stringWithFormat:@"DataArray internal error in removeAllObjects: list shorter than it should be!" ] ) ;
			assert( p != nil ) ;
			break ;
		}
		[ self putIdleElement:p ] ;
		p = p->next ;
	}
	head = nil ;
	elements = 0 ;
	[ busy unlock ] ;
}

//  increase the index of an object, if possible
- (void)increaseIndexOfObject:(id)object
{
	DataElement *p, *q, *r ;
	int i ;	
	
	[ busy lock ] ;
	p = q = head ;
	for ( i = 0; i < elements; i++ ) {
		if ( p == nil ) {
			NSLog( [ NSString stringWithFormat:@"DataArray internal error in increaseIndexOfObject: list shorter than it should be!" ] ) ;
			[ busy unlock ] ;
			assert( p != nil ) ;
			return ;
		}
		if ( p->data == object ) {
			r = p->next ;
			if ( r == nil ) {
				//  already at tail
				[ busy unlock ] ;
				return ;
			}
			if ( head == p ) head = r ; else q->next = r ;
			p->next = r->next ;
			r->next = p ;
			[ busy unlock ] ;
			return ;
		}
		q = p ;
		p = p->next ;
	}
	NSLog( [ NSString stringWithFormat:@"DataArray error in increaseIndexOfObject: object not found!" ] ) ;
	assert( i < elements ) ;
	[ busy unlock ] ;
}

//  increase the index of an object, if possible
- (void)increaseIndexOfObjectAtIndex:(int)index
{
	DataElement *p, *q, *r ;
	int i ;	
	
	if ( elements <= 1 ) return ;

	[ busy lock ] ;
	if ( index == 0 ) {
		p = head ;
		r = p->next ;
		head = r ;
		p->next = r->next ;
		r->next = p ;
		[ busy unlock ] ;
		return ;
	}
	if ( index >= elements ) {
		NSLog( [ NSString stringWithFormat:@"DataArray increaseIndexOfObjectAtIndex error: array index (%d) out of bounds (%d)!", index, elements ] ) ;
		[ busy unlock ] ;
		assert( index < elements ) ;
		return ;
	}	
	p = q = head ;
	for ( i = 1; i < index; i++ ) {
		if ( p == nil ) {
			NSLog( [ NSString stringWithFormat:@"DataArray internal error in increaseIndexOfObjectAtIndex: list shorter than it should be!" ] ) ;
			[ busy unlock ] ;
			assert( p != nil ) ;
			return ;
		}
		q = p ;
		p = p->next ;
	}
	r = p->next ;
	if ( head == p ) head = r ; else q->next = r ;
	p->next = r->next ;
	r->next = p ;
	[ busy unlock ] ;
}

@end
