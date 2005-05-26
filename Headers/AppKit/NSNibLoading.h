/* 
   NSNibLoading.h

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   Author:  Richard Frith-Macdonald <richard@branstorm.co.uk>
   Date: 1999
   
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

#ifndef _GNUstep_H_NSNibLoading
#define _GNUstep_H_NSNibLoading

#include <Foundation/NSObject.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSGeometry.h>

@class	NSString;
@class	NSDictionary;
@class	NSMutableDictionary;

@interface NSObject (NSNibAwaking)

/*
 * Notification of Loading
 */
- (void) awakeFromNib;

@end


@interface NSBundle (NSNibLoading)

+ (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone;

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner;

- (BOOL) loadNibFile: (NSString *)fileName
   externalNameTable: (NSDictionary *)context
	    withZone: (NSZone *)zone;

#ifndef	NO_GNUSTEP
- (NSString *) pathForNibResource: (NSString *)fileName;
#endif // NO_GNUSTEP
@end

#endif /* _GNUstep_H_NSNibLoading */
