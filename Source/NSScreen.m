/* 
   NSScreen.m

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

#include <gnustep/gui/NSScreen.h>

// Global device dictionary key strings
NSString *NSDeviceResolution = @"Resolution";
NSString *NSDeviceColorSpaceName = @"ColorSpaceName";
NSString *NSDeviceBitsPerSample = @"BitsPerSample";
NSString *NSDeviceIsScreen = @"IsScreen";
NSString *NSDeviceIsPrinter = @"IsPrinter";
NSString *NSDeviceSize = @"Size";

@implementation NSScreen

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSScreen class])
    {
      // Initial version
      [self setVersion:1];
    }
}

//
// Creating NSScreen Instances
//
+ (NSScreen *)mainScreen
{
  return nil;
}

+ (NSScreen *)deepestScreen
{
  return nil;
}

+ (NSArray *)screens
{
  return nil;
}

//
// Instance methods
//
- init
{
  [super init];

  // Create our device description dictionary
  // The backend will have to fill the dictionary
  device_desc = [NSMutableDictionary dictionary];

  return self;
}

//
// Reading Screen Information
//
- (NSWindowDepth)depth
{
  return 0;
}

- (NSRect)frame
{
  return NSZeroRect;
}

// Make a copy of our dictionary and return it
- (NSDictionary *)deviceDescription
{
  NSDictionary *d = [[NSDictionary alloc] initWithDictionary: device_desc];
  return d;
}

@end
