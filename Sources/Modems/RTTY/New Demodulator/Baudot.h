/*
 *  Baudot.h
 *  cocoaModem 2.0
 *
 *  Created by Kok Chen on 3/21/09.
 *  Copyright 2009 Kok Chen, W7AY. All rights reserved.
 *
 */


static char CMLtrs[] = {  '*',  'E', '\n', 'A', ' ', 'S', 'I', 'U', 
						'\r', 'D', 'R',  'J', 'N', 'F', 'C', 'K', 
						'T',  'Z', 'L',  'W', 'H', 'Y', 'P', 'Q', 
						'O',  'B', 'G',  '*', 'M', 'X', 'V', '*',
					} ;

static char CMFigs[] = {  '*',  '3',  '\n', '-',  ' ', '*', '8', '7', 
						'\r', '$',  '4',  '\'', ',', '!', ':', '(', 
						'5',  '\"', ')',  '2',  '#', '6', '0', '1', 
						'9',  '?',  '&',  '*',  '.', '/', ';', '*',
					} ;

#define CMFIGSCODE	0x1b
#define CMLTRSCODE	0x1f

