/* 
   NSPrintInfo.m

   Stores information used in printing

   Copyright (C) 1996,1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: July 1997
   
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
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include "gnustep/gui/config.h"
#include <Foundation/NSBundle.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSValue.h>
#include <AppKit/NSPrinter.h>

#include <AppKit/NSPrintInfo.h>

#ifndef NSPrinterAdmin_PATH
#define NSPrinterAdmin_PATH @GNUSTEP_INSTALL_LIBDIR @"/PrinterAdmin"
#endif

#ifndef NSPrintInfo_PAPERFILE
#define NSPrintInfo_PAPERFILE @"PaperSizes"
#endif

#ifndef NSPrintInfo_DEFAULTSTABLE
#define NSPrintInfo_DEFAULTSTABLE @"PrintDefaults"
#endif

// FIXME: retain/release of dictionary with retain/release of printInfo?

// Class variables:
NSPrintInfo *sharedPrintInfoObject = nil;
NSMutableDictionary *printInfoDefaults = nil;
NSDictionary *paperSizes = nil;

@interface NSPrintInfo (private)
+ initPrintInfoDefaults;
@end

@implementation NSPrintInfo

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPrintInfo class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Managing the Shared NSPrintInfo Object 
//
+ (void)setSharedPrintInfo:(NSPrintInfo *)printInfo
{
  sharedPrintInfoObject = printInfo;
}

+ (NSPrintInfo *)sharedPrintInfo
{
  if (!sharedPrintInfoObject)
    {
      if (!printInfoDefaults)
	[NSPrintInfo initPrintInfoDefaults];
      sharedPrintInfoObject = [[self alloc]
				initWithDictionary:printInfoDefaults]; 
    }
  return sharedPrintInfoObject;
}

//
// Managing the Printing Rectangle 
//
+ (NSSize)sizeForPaperName:(NSString *)name
{
  return [[self defaultPrinter] pageSizeForPaper:name];
  // Alternatively:
//   NSBundle *adminBundle;
//   NSString *path;
//   NSValue *size;
//   if (!paperSizes)
//     {
//       adminBundle = [NSBundle bundleWithPath:NSPrinterAdmin_PATH];
//       path = [adminBundle pathForResource:NSPrintInfo_PAPERFILE ofType:nil];
//       // If not found
//       if (path == nil || [path length] == 0)
// 	{
// 	  [NSException raise:NSGenericException
// 		       format:@"Could not find paper size index, file %s",
// 		       [NSPrintInfo_PAPERFILE cString]];
// 	  // NOT REACHED
// 	}
//       paperSizes = [[NSDictionary dictionaryWithContentsOfFile:path] retain];
//     }
//   size = [paperSizes objectForKey:name];
//   if (!size)
//     return NSZeroSize;
//  return [size sizeValue];
}

//
// Specifying the Printer 
//
+ (NSPrinter *)defaultPrinter
{
  if (!printInfoDefaults)
    [NSPrintInfo initPrintInfoDefaults];
  return [printInfoDefaults objectForKey:NSPrintPrinter];
}

+ (void)setDefaultPrinter:(NSPrinter *)printer
{
  if (!printInfoDefaults)
    [NSPrintInfo initPrintInfoDefaults];
  [printInfoDefaults setObject:printer forKey:NSPrintPrinter];
}

//
// Instance methods
//
//
// Creating and Initializing an NSPrintInfo Instance 
//
- (id)initWithDictionary:(NSDictionary *)aDict
{
  [super init];
  info = [[NSMutableDictionary alloc] initWithDictionary:aDict];
  return self;
}

//
// Managing the Printing Rectangle 
//
- (float)bottomMargin
{
  return [(NSNumber *)[info objectForKey:NSPrintBottomMargin] floatValue];
}

- (float)leftMargin
{
  return [(NSNumber *)[info objectForKey:NSPrintLeftMargin] floatValue];
}

- (NSPrintingOrientation)orientation
{
  return [(NSNumber *)[info objectForKey:NSPrintOrientation] intValue];
}

- (NSString *)paperName
{
  return [info objectForKey:NSPrintPaperName];
}

- (NSSize)paperSize
{
  return [(NSValue *)[info objectForKey:NSPrintPaperSize] sizeValue];
}

- (float)rightMargin
{
  return [(NSNumber *)[info objectForKey:NSPrintRightMargin] floatValue];
}

- (void)setBottomMargin:(float)value
{
  [info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintBottomMargin];
}

- (void)setLeftMargin:(float)value
{
  [info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintLeftMargin];
}

- (void)setOrientation:(NSPrintingOrientation)mode
{
  [info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintOrientation];
}

- (void)setPaperName:(NSString *)name
{
  [info setObject:name forKey:NSPrintPaperName];
}

- (void)setPaperSize:(NSSize)size
{
  [info setObject:[NSValue valueWithSize:size]
	forKey:NSPrintPaperSize];
}

- (void)setRightMargin:(float)value
{
  [info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintRightMargin];
}

- (void)setTopMargin:(float)value
{
  [info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintTopMargin];
}

- (float)topMargin
{
  return [(NSNumber *)[info objectForKey:NSPrintTopMargin] floatValue];
}

//
// Pagination 
//
- (NSPrintingPaginationMode)horizontalPagination
{
  return [(NSNumber *)[info objectForKey:NSPrintHorizontalPagination]
		      intValue];
}

- (void)setHorizontalPagination:(NSPrintingPaginationMode)mode
{
  [info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintHorizontalPagination];
}

- (void)setVerticalPagination:(NSPrintingPaginationMode)mode
{
  [info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintVerticalPagination];
}

- (NSPrintingPaginationMode)verticalPagination
{
  return [(NSNumber *)[info objectForKey:NSPrintVerticalPagination] intValue];
}

//
// Positioning the Image on the Page 
//
- (BOOL)isHorizontallyCentered
{
  return [(NSNumber *)[info objectForKey:NSPrintHorizontallyCentered] 
		      boolValue];
}

- (BOOL)isVerticallyCentered
{
  return [(NSNumber *)[info objectForKey:NSPrintVerticallyCentered] boolValue];
}

- (void)setHorizontallyCentered:(BOOL)flag
{
  [info setObject:[NSNumber numberWithBool:flag]
	forKey:NSPrintHorizontallyCentered];
}

- (void)setVerticallyCentered:(BOOL)flag
{
  [info setObject:[NSNumber numberWithBool:flag]
	forKey:NSPrintVerticallyCentered];
}

//
// Specifying the Printer 
//
- (NSPrinter *)printer
{
  return [info objectForKey:NSPrintPrinter];
}

- (void)setPrinter:(NSPrinter *)aPrinter
{
  [info setObject:aPrinter forKey:NSPrintPrinter];
}

//
// Controlling Printing
//
- (NSString *)jobDisposition
{
  return [info objectForKey:NSPrintJobDisposition];
}

- (void)setJobDisposition:(NSString *)disposition
{
  [info setObject:disposition forKey:NSPrintJobDisposition];
}

- (void)setUpPrintOperationDefaultValues
{
  NSEnumerator *keys, *objects;
  NSString *key;
  id object;
  if (!printInfoDefaults)
    [NSPrintInfo initPrintInfoDefaults];
  keys = [printInfoDefaults keyEnumerator];
  objects = [printInfoDefaults objectEnumerator];
  while ((key = [keys nextObject]))
    {
      object = [objects nextObject];
      if (![info objectForKey:key])
	[info setObject:object forKey:key];
    }
}

//
// Accessing the NSPrintInfo Object's Dictionary 
//
- (NSMutableDictionary *)dictionary
{
  return info;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodePropertyList: info];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  info = [[aDecoder decodePropertyList] retain];
  return self;
}

//
// Private method to initialise printing defaults dictionary
//
+ initPrintInfoDefaults
{
  NSBundle *adminBundle;
  NSString *path;
  adminBundle = [NSBundle bundleWithPath:NSPrinterAdmin_PATH];
  path = [adminBundle pathForResource:NSPrintInfo_DEFAULTSTABLE ofType:nil];
  // If not found
  if (path == nil || [path length] == 0)
    {
      [NSException raise:NSGenericException
		   format:@"Could not find printing defaults table, file %s",
		   [NSPrintInfo_DEFAULTSTABLE cString]];
      // NOT REACHED
    }
  printInfoDefaults = [[NSMutableDictionary dictionaryWithContentsOfFile:path]
			retain];
  // The loaded dictionary contains the name of the printer for NSPrintPrinter
  // Load the real NSPrinter object...
  [printInfoDefaults 
    setObject:[NSPrinter printerWithName:[printInfoDefaults 
  					   objectForKey:NSPrintPrinter]]
    forKey:NSPrintPrinter];
  [printInfoDefaults 
    setObject:[NSValue valueWithSize:
			[NSPrintInfo sizeForPaperName:
			    [printInfoDefaults objectForKey:NSPrintPaperName]]]
    forKey:NSPrintPaperSize];
  return self;
}

@end
