/* 
   NSActionCell.m

   Abstract cell for target/action paradigm

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

#include <gnustep/gui/NSActionCell.h>
#include <gnustep/base/NSCoder.h>
#include <gnustep/gui/NSControl.h>

@implementation NSActionCell

//
// Class methods
//
+ (void)initialize
{
  if (self == [NSActionCell class])
    {
      NSDebugLog(@"Initialize NSActionCell class\n");

      // Initial version
      [self setVersion:1];
    }
}

//
// Instance methods
//
- init
{
  [super init];
  target = nil;
  action = NULL;
  tag = 0;
  return self;
}

- initImageCell:(NSImage *)anImage
{
  [super initImageCell:anImage];
  target = nil;
  action = NULL;
  tag = 0;
  return self;
}

- initTextCell:(NSString *)aString
{
  [super initTextCell:aString];
  target = nil;
  action = NULL;
  tag = 0;
  return self;
}

//
// Configuring an NSActionCell 
//
- (void)setAlignment:(NSTextAlignment)mode
{
  [super setAlignment:mode];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (void)setBezeled:(BOOL)flag
{
  [super setBezeled:flag];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (void)setBordered:(BOOL)flag
{
  [super setBordered:flag];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (void)setEnabled:(BOOL)flag
{
  [super setEnabled:flag];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(unsigned int)leftDigits
			 right:(unsigned int)rightDigits
{
  [super setFloatingPointFormat:autoRange left:leftDigits right:rightDigits];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (void)setFont:(NSFont *)fontObject
{
  [super setFont:fontObject];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (void)setImage:(NSImage *)image
{
  [super setImage:image];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

//
// Setting the NSCell's State 
//
- (void)setState:(int)value
{
  [super setState: value];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

//
// Manipulating NSActionCell Values 
//
- (double)doubleValue
{
  return [super doubleValue];
}

- (float)floatValue
{
  return [super floatValue];
}

- (int)intValue
{
  return [super intValue];
}

- (void)setStringValue:(NSString *)aString
{
  [super setStringValue:aString];
  if (control_view)
    if ([control_view isKindOfClass: [NSControl class]])
      [(NSControl *)control_view updateCell: self];
}

- (NSString *)stringValue
{
  return [super stringValue];
}

//
// Displaying 
//
- (void)drawWithFrame:(NSRect)cellFrame
	       inView:(NSView *)controlView
{
  [super drawWithFrame:cellFrame inView:controlView];
}

- (NSView *)controlView
{
  return [super controlView];
}

//
// Target and Action 
//
- (SEL)action
{
  return action;
}

- (void)setAction:(SEL)aSelector
{
  action = aSelector;
}

- (void)setTarget:(id)anObject
{
  target = anObject;
}

- (id)target
{
  return target;
}

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt
{
  tag = anInt;
}

- (int)tag
{
  return tag;
}

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder
{
  [super encodeWithCoder:aCoder];

  [aCoder encodeValueOfObjCType: "i" at: &tag];
  [aCoder encodeObjectReference: target withName: @"Target"];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &action];
}

- initWithCoder:aDecoder
{
  [super initWithCoder:aDecoder];

  [aDecoder decodeValueOfObjCType: "i" at: &tag];
  [aDecoder decodeObjectAt: &target withName: NULL];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &action];

  return self;
}

@end
