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
//       paperSizes = RETAIN([NSDictionary dictionaryWithContentsOfFile:path]);
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
  _info = [[NSMutableDictionary alloc] initWithDictionary:aDict];
  return self;
}

- (void) dealloc
{
  RELEASE(_info);
  [super dealloc];
}

//
// Managing the Printing Rectangle 
//
- (float)bottomMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintBottomMargin] floatValue];
}

- (float)leftMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintLeftMargin] floatValue];
}

- (NSPrintingOrientation)orientation
{
  return [(NSNumber *)[_info objectForKey:NSPrintOrientation] intValue];
}

- (NSString *)paperName
{
  return [_info objectForKey:NSPrintPaperName];
}

- (NSSize)paperSize
{
  return [(NSValue *)[_info objectForKey:NSPrintPaperSize] sizeValue];
}

- (float)rightMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintRightMargin] floatValue];
}

- (void)setBottomMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintBottomMargin];
}

- (void)setLeftMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintLeftMargin];
}

- (void)setOrientation:(NSPrintingOrientation)mode
{
  [_info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintOrientation];
}

- (void)setPaperName:(NSString *)name
{
  [_info setObject:name forKey:NSPrintPaperName];
}

- (void)setPaperSize:(NSSize)size
{
  [_info setObject:[NSValue valueWithSize:size]
	forKey:NSPrintPaperSize];
}

- (void)setRightMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintRightMargin];
}

- (void)setTopMargin:(float)value
{
  [_info setObject:[NSNumber numberWithFloat:value]
	forKey:NSPrintTopMargin];
}

- (float)topMargin
{
  return [(NSNumber *)[_info objectForKey:NSPrintTopMargin] floatValue];
}

//
// Pagination 
//
- (NSPrintingPaginationMode)horizontalPagination
{
  return [(NSNumber *)[_info objectForKey:NSPrintHorizontalPagination]
		      intValue];
}

- (void)setHorizontalPagination:(NSPrintingPaginationMode)mode
{
  [_info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintHorizontalPagination];
}

- (void)setVerticalPagination:(NSPrintingPaginationMode)mode
{
  [_info setObject:[NSNumber numberWithInt:mode]
	forKey:NSPrintVerticalPagination];
}

- (NSPrintingPaginationMode)verticalPagination
{
  return [(NSNumber *)[_info objectForKey:NSPrintVerticalPagination] intValue];
}

//
// Positioning the Image on the Page 
//
- (BOOL)isHorizontallyCentered
{
  return [(NSNumber *)[_info objectForKey:NSPrintHorizontallyCentered] 
		      boolValue];
}

- (BOOL)isVerticallyCentered
{
  return [(NSNumber *)[_info objectForKey:NSPrintVerticallyCentered] boolValue];
}

- (void)setHorizontallyCentered:(BOOL)flag
{
  [_info setObject:[NSNumber numberWithBool:flag]
	forKey:NSPrintHorizontallyCentered];
}

- (void)setVerticallyCentered:(BOOL)flag
{
  [_info setObject:[NSNumber numberWithBool:flag]
	forKey:NSPrintVerticallyCentered];
}

//
// Specifying the Printer 
//
- (NSPrinter *)printer
{
  return [_info objectForKey:NSPrintPrinter];
}

- (void)setPrinter:(NSPrinter *)aPrinter
{
  [_info setObject:aPrinter forKey:NSPrintPrinter];
}

//
// Controlling Printing
//
- (NSString *)jobDisposition
{
  return [_info objectForKey:NSPrintJobDisposition];
}

- (void)setJobDisposition:(NSString *)disposition
{
  [_info setObject:disposition forKey:NSPrintJobDisposition];
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
      if (![_info objectForKey:key])
	[_info setObject:object forKey:key];
    }
}

//
// Accessing the NSPrintInfo Object's Dictionary 
//
- (NSMutableDictionary *)dictionary
{
  return _info;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodePropertyList: _info];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  _info = RETAIN([aDecoder decodePropertyList]);
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
  if (path != nil && [path length] != 0)
    {
      printInfoDefaults = RETAIN([NSMutableDictionary dictionaryWithContentsOfFile:path]);
      // NOT REACHED
    }
  if (printInfoDefaults == nil)
    {
      NSLog(@"Could not find printing defaults table, file %s",
	    [NSPrintInfo_DEFAULTSTABLE cString]);
      // FIXME: As a replacement we add a very simple definition
      printInfoDefaults = RETAIN(([NSMutableDictionary dictionaryWithObjectsAndKeys: 
							  @"Unknown", NSPrintPrinter,
							  @"A4", NSPrintPaperName,
						       NULL]));
    }

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
