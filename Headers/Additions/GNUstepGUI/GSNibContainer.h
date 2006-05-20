/* 
   GSNibContainer.h

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2006
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
*/ 

#ifndef _GNUstep_H_GSNibContainer
#define _GNUstep_H_GSNibContainer

@class	NSDictionary;
@class	NSMutableDictionary;
@class  NSMutableSet;
@class  NSMutableArray;

@protocol GSNibContainer 
- (void) awakeWithContext: (NSDictionary *)context;
- (NSMutableDictionary*) nameTable;
- (NSMutableArray*) connections;
- (NSMutableSet*) topLevelObjects;
@end

#endif /* _GNUstep_H_GSNibContainer */
