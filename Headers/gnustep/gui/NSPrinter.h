/* 
   NSPrinter.h

   Description...

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   If you are interested in a warranty or support for this source code,
   contact Scott Christley <scottc@net-community.com> for more information.
   
   You should have received a copy of the GNU Library General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
*/ 

#ifndef _GNUstep_H_NSPrinter
#define _GNUstep_H_NSPrinter

#include <AppKit/stdappkit.h>
#include <Foundation/NSCoder.h>

@interface NSPrinter : NSObject <NSCoding>

{
  // Attributes
}

//
// Finding an NSPrinter 
//
+ (NSPrinter *)printerWithName:(NSString *)name;
+ (NSPrinter *)printerWithType:(NSString *)type;
+ (NSArray *)printerTypes;

//
// Printer Attributes 
//
- (NSString *)host;
- (NSString *)name;
- (NSString *)note;
- (NSString *)type;

//
// Retrieving Specific Information 
//
- (BOOL)acceptsBinary;
- (NSRect)imageRectForPaper:(NSString *)paperName;
- (NSSize)pageSizeForPaper:(NSString *)paperName;
- (BOOL)isColor;
- (BOOL)isFontAvailable:(NSString *)fontName;
- (int)languageLevel;
- (BOOL)isOutputStackInReverseOrder;

//
// Querying the NSPrinter Tables 
//
- (BOOL)booleanForKey:(NSString *)key
	      inTable:(NSString *)table;
- (NSDictionary *)deviceDescription;
- (float)floatForKey:(NSString *)key
	     inTable:(NSString *)table;
- (int)intForKey:(NSString *)key
	 inTable:(NSString *)table;
- (NSRect)rectForKey:(NSString *)key
	     inTable:(NSString *)table;
- (NSSize)sizeForKey:(NSString *)key
	     inTable:(NSString *)table;
- (NSString *)stringForKey:(NSString *)key
		   inTable:(NSString *)table;
- (NSArray *)stringListForKey:(NSString *)key
		      inTable:(NSString *)table;
- (NSPrinterTableStatus)statusForTable:(NSString *)table;
- (BOOL)isKey:(NSString *)key
      inTable:(NSString *)table;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSPrinter
