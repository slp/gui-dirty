/* 
   NSPasteboard.m

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

#include <gnustep/gui/NSPasteboard.h>

// Pasteboard Type Globals 
NSString *NSStringPboardType;
NSString *NSColorPboardType;
NSString *NSFileContentsPboardType;
NSString *NSFilenamesPboardType;
NSString *NSFontPboardType;
NSString *NSRulerPboardType;
NSString *NSPostScriptPboardType;
NSString *NSTabularTextPboardType;
NSString *NSRTFPboardType;
NSString *NSTIFFPboardType;
NSString *NSDataLinkPboardType;
NSString *NSGeneralPboardType;

// Pasteboard Name Globals 
NSString *NSDragPboard;
NSString *NSFindPboard;
NSString *NSFontPboard;
NSString *NSGeneralPboard;
NSString *NSRulerPboard;

@implementation NSPasteboard

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSPasteboard class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating and Releasing an NSPasteboard Object
//
+ (NSPasteboard *)generalPasteboard
{
  return nil;
}

+ (NSPasteboard *)pasteboardWithName:(NSString *)name
{
  return nil;
}

+ (NSPasteboard *)pasteboardWithUniqueName
{
  return nil;
}

//
// Getting Data in Different Formats 
//
+ (NSPasteboard *)pasteboardByFilteringData:(NSData *)data
				     ofType:(NSString *)type
{
  return nil;
}

+ (NSPasteboard *)pasteboardByFilteringFile:(NSString *)filename
{
  return nil;
}

+ (NSPasteboard *)pasteboardByFilteringTypesInPasteboard:(NSPasteboard *)pboard
{
  return nil;
}

+ (NSArray *)typesFilterableTo:(NSString *)type
{
  return nil;
}

//
// Instance methods
//

//
// Creating and Releasing an NSPasteboard Object
//
- (void)releaseGlobally
{}

//
// Referring to a Pasteboard by Name 
//
- (NSString *)name
{
  return nil;
}

//
// Writing Data 
//
- (int)addTypes:(NSArray *)newTypes
	  owner:(id)newOwner
{
  return 0;
}

- (int)declareTypes:(NSArray *)newTypes
	      owner:(id)newOwner
{
  return 0;
}

- (BOOL)setData:(NSData *)data
	forType:(NSString *)dataType
{
  return NO;
}

- (BOOL)setPropertyList:(id)propertyList
		forType:(NSString *)dataType
{
  return NO;
}

- (BOOL)setString:(NSString *)string
	  forType:(NSString *)dataType
{
  return NO;
}

- (BOOL)writeFileContents:(NSString *)filename
{
  return NO;
}

//
// Determining Types 
//
- (NSString *)availableTypeFromArray:(NSArray *)types
{
  return nil;
}

- (NSArray *)types
{
  return nil;
}

//
// Reading Data 
//
- (int)changeCount
{
  return 0;
}

- (NSData *)dataForType:(NSString *)dataType
{
  return nil;
}

- (id)propertyListForType:(NSString *)dataType
{
  return nil;
}

- (NSString *)readFileContentsType:(NSString *)type
			    toFile:(NSString *)filename
{
  return nil;
}

- (NSString *)stringForType:(NSString *)dataType
{
  return nil;
}

//
// Methods Implemented by the Owner 
//
- (void)pasteboard:(NSPasteboard *)sender
provideDataForType:(NSString *)type
{}

- (void)pasteboardChangedOwner:(NSPasteboard *)sender
{}

@end
