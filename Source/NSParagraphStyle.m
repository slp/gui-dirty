/** <title>NSParagraphStyle</title>

   <abstract>NSParagraphStyle and NSMutableParagraphStyle hold paragraph style 
     information NSTextTab holds information about a single tab stop</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date March 1999
   
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

/* To keep the allocation counts valid when swizzling the class in
[NSMutableParagraphStyle -copyWithZone:]. */
#include <Foundation/NSDebug.h>

#include <Foundation/NSException.h>
#include "AppKit/NSParagraphStyle.h"

@implementation NSTextTab

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone(self, aZone) == YES)
    return RETAIN(self);
  return NSCopyObject(self, 0, aZone);
}

- (id) initWithType: (NSTextTabType)type location: (float)loc
{
  self = [super init];
  _tabStopType = type;
  _location = loc;
  return self;
}

- (NSComparisonResult) compare: (id)anObject
{
  float	loc;

  if (anObject == self)
    return NSOrderedSame;
  if (anObject == nil || ([anObject isKindOfClass: self->isa] == NO))
    return NSOrderedAscending;
  loc = ((NSTextTab*)anObject)->_location;
  if (_location < loc)
    return NSOrderedAscending;
  else if (_location > loc)
    return NSOrderedDescending;
  else
    return NSOrderedSame;
}

- (unsigned) hash
{
  unsigned val = (unsigned)_location;

  val ^= (unsigned)_tabStopType;
  return val;
}

- (BOOL) isEqual: (id)anObject
{
  if (anObject == self)
    return YES;
  if ([anObject isKindOfClass: self->isa] == NO)
    return NO;
  else if (((NSTextTab*)anObject)->_tabStopType != _tabStopType)
    return NO;
  else if (((NSTextTab*)anObject)->_location != _location)
    return NO;
  return YES;
}

- (float) location
{
  return _location;
}

- (NSTextTabType) tabStopType
{
  return _tabStopType;
}
@end



@implementation NSParagraphStyle

static NSParagraphStyle	*defaultStyle = nil;

+ (NSParagraphStyle*) defaultParagraphStyle
{
  if (defaultStyle == nil)
    {
      NSParagraphStyle	*style = [[self alloc] init];
      int		i;

      for (i = 0; i < 12; i++)
	{
	  NSTextTab	*tab;

	  /* FIXME: (i * 1) ? */
	  tab = [[NSTextTab alloc] initWithType: NSLeftTabStopType
				       location: (i * 1) * 28.0];
	  [style->_tabStops addObject: tab];
	  RELEASE(tab);
	}
      defaultStyle = style;
    }
  return defaultStyle;
}

+ (void) initialize
{
  if (self == [NSParagraphStyle class])
    {
      /* Set the class version to 2, as the writing direction is now 
	 stored in the encoding */
      [self setVersion: 2];
    }
}

+ (NSWritingDirection) defaultWritingDirectionForLanguage: (NSString*) language
{
  static NSArray *rightToLeft;
  NSWritingDirection writingDirection;
  NSString *langCode = nil;

  /* If language is 5/6 characters long with underscore in the middle,
     treat it as ISO language-region format. */
  if ([language length] == 5 && [language characterAtIndex: 2] == '_')
      langCode = [language substringToIndex: 2];
  else if ([language length] == 6 && [language characterAtIndex: 3] == '_')
      langCode = [language substringToIndex: 3];
  /* Else if it's just two or three chars long, treat as ISO 639 code. */
  else if ([language length] == 2 || [language length] == 3)
    langCode = language;
  
  if (!rightToLeft)
    // Holds languages whose current scripts are written right to left.
    rightToLeft = [[NSArray alloc] initWithObjects: @"ar", @"ara", @"arc",
				   @"chi", @"fa", @"fas", @"he", @"heb", @"iw",
				   @"ji", @"kas", @"ks", @"ku", @"kur", @"pa",
				   @"pan", @"per" @"ps", @"pus", @"sd", @"snd",
				   @"syr", @"tk", @"tmh", @"tuk", @"ug",
				   @"uig", @"ur," @"urd", @"yi", @"yid", @"zh",
				   @"zho", nil];
  if ([rightToLeft containsObject: langCode] == YES)
    writingDirection = NSWritingDirectionRightToLeft;
  else // If it's not RTL, assume LTR.
    writingDirection = NSWritingDirectionLeftToRight;
  
  return writingDirection;  
}

- (void) dealloc
{
  if (self == defaultStyle)
    {
      NSLog(@"Argh - attempt to dealloc the default paragraph style!");
      return;
    }
  RELEASE (_tabStops);
  [super dealloc];
}

- (id) init
{
  self = [super init];
  _alignment = NSNaturalTextAlignment;
  _firstLineHeadIndent = 0.0;
  _headIndent = 0.0;
  _lineBreakMode = NSLineBreakByWordWrapping;
  _lineSpacing = 0.0;
  _maximumLineHeight = 0.0;
  _minimumLineHeight = 0.0;
  _paragraphSpacing = 0.0;
  _tailIndent = 0.0;
  _baseDirection = NSWritingDirectionNaturalDirection;
  _tabStops = [[NSMutableArray allocWithZone: [self zone]] 
		initWithCapacity: 12];
  return self;
}

/*
 *      "Leading": distance between the bottom of one line fragment and top
 *      of next (applied between lines in the same container).
 *      Can't be negative. This value is included in the line fragment
 *      heights in layout manager.
 */
- (float) lineSpacing
{
  return _lineSpacing;
}

/*
 *      Distance between the bottom of this paragraph and top of next.
 */
- (float) paragraphSpacing
{
  return _paragraphSpacing;
}

- (NSTextAlignment) alignment
{
  return _alignment;
}

/*
 *      The following values are relative to the appropriate margin
 *      (depending on the paragraph direction)
 */

/*
 *      Distance from margin to front edge of paragraph
 */
- (float) headIndent
{
  return _headIndent;
}

/*
 *      Distance from margin to back edge of paragraph; if negative or 0,
 *      from other margin
 */
- (float) tailIndent
{
  return _tailIndent;
}

/*
 *      Distance from margin to edge appropriate for text direction
 */
- (float) firstLineHeadIndent
{
  return _firstLineHeadIndent;
}

/*
 *      Distance from margin to tab stops
 */
- (NSArray *) tabStops
{
  return AUTORELEASE ([_tabStops copyWithZone: NSDefaultMallocZone ()]);
}

/*
 *      Line height is the distance from bottom of descenders to to
 *      of ascenders; basically the line fragment height. Does not include
 *      lineSpacing (which is added after this computation).
 */
- (float) minimumLineHeight
{
  return _minimumLineHeight;
}

/*
 *      0 implies no maximum.
 */
- (float) maximumLineHeight
{
  return _maximumLineHeight;
} 

- (NSLineBreakMode) lineBreakMode
{
  return _lineBreakMode;
}

- (NSWritingDirection) baseWritingDirection
{
  return _baseDirection;
}

- (id) copyWithZone: (NSZone*)aZone
{
  if (NSShouldRetainWithZone (self, aZone) == YES)
    return RETAIN (self);
  else
    {
      NSParagraphStyle	*c;

      c = (NSParagraphStyle*)NSCopyObject (self, 0, aZone);
      c->_tabStops = [_tabStops mutableCopyWithZone: aZone];
      return c;
    }
}

- (id) mutableCopyWithZone: (NSZone*)aZone
{
  NSMutableParagraphStyle	*c;

  c = [[NSMutableParagraphStyle allocWithZone: aZone] init];
  [c setParagraphStyle: self];
  return c;
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  [aCoder decodeValueOfObjCType: @encode(NSTextAlignment) at: &_alignment];
  [aCoder decodeValueOfObjCType: @encode(NSLineBreakMode) 
	  at: &_lineBreakMode];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_firstLineHeadIndent];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_headIndent];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_lineSpacing];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_maximumLineHeight];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_minimumLineHeight];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_paragraphSpacing];
  [aCoder decodeValueOfObjCType: @encode(float) at: &_tailIndent];

  /*
   *	Tab stops don't conform to NSCoding - so we do it the long way.
   */
  [aCoder decodeValueOfObjCType: @encode(unsigned) at: &count];
  _tabStops = [[NSMutableArray alloc] initWithCapacity: count];
  if (count > 0)
    {
      float		locations[count];
      NSTextTabType	types[count];
      unsigned		i;

      [aCoder decodeArrayOfObjCType: @encode(float)
			      count: count
				 at: locations];
      [aCoder decodeArrayOfObjCType: @encode(NSTextTabType)
			      count: count
				 at: types];
      for (i = 0; i < count; i++)
	{
	  NSTextTab	*tab;

	  tab = [NSTextTab alloc];
	  tab = [tab initWithType: types[i] location: locations[i]];
	  [_tabStops addObject: tab];
	  RELEASE (tab);
	}
    }

  if ([aCoder versionForClassName: @"NSParagraphStyle"] >= 2)
    {
      [aCoder decodeValueOfObjCType: @encode(int) at: &_baseDirection];
    }

  return self;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  unsigned	count;

  [aCoder encodeValueOfObjCType: @encode(NSTextAlignment) at: &_alignment];
  [aCoder encodeValueOfObjCType: @encode(NSLineBreakMode) 
	  at: &_lineBreakMode];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_firstLineHeadIndent];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_headIndent];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_lineSpacing];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_maximumLineHeight];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_minimumLineHeight];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_paragraphSpacing];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_tailIndent];

  /*
   *	Tab stops don't conform to NSCoding - so we do it the long way.
   */
  count = [_tabStops count];
  [aCoder encodeValueOfObjCType: @encode(unsigned) at: &count];
  if (count > 0)
    {
      float		locations[count];
      NSTextTabType	types[count];
      unsigned		i;

      for (i = 0; i < count; i++)
	{
	  NSTextTab	*tab = [_tabStops objectAtIndex: i];

	  locations[i] = [tab location]; 
	  types[i] = [tab tabStopType]; 
	}
      [aCoder encodeArrayOfObjCType: @encode(float)
			      count: count
				 at: locations];
      [aCoder encodeArrayOfObjCType: @encode(NSTextTabType)
			      count: count
				 at: types];
    }

  [aCoder encodeValueOfObjCType: @encode(int) at: &_baseDirection];
}


- (BOOL) isEqual: (id)aother
{
  NSParagraphStyle *other = aother;
  if (other == self)
    return YES;
  if ([other isKindOfClass: [NSParagraphStyle class]] == NO)
    return NO;

#define C(x) if (x != other->x) return NO
  C(_lineSpacing);
  C(_paragraphSpacing);
  C(_headIndent);
  C(_tailIndent);
  C(_firstLineHeadIndent);
  C(_minimumLineHeight);
  C(_maximumLineHeight);
  C(_alignment);
  C(_lineBreakMode);
  C(_baseDirection);
#undef C

  return [_tabStops isEqualToArray: other->_tabStops];
}

- (unsigned int) hash
{
  return _alignment + _lineBreakMode;
}


@end



@implementation NSMutableParagraphStyle 

+ (NSParagraphStyle*) defaultParagraphStyle
{
  return AUTORELEASE ([[NSParagraphStyle defaultParagraphStyle] mutableCopy]);
}

- (void) setLineSpacing: (float)aFloat
{
  NSAssert (aFloat >= 0.0, NSInvalidArgumentException);
  _lineSpacing = aFloat;
}

- (void) setParagraphSpacing: (float)aFloat
{
  NSAssert (aFloat >= 0.0, NSInvalidArgumentException);
  _paragraphSpacing = aFloat;
}

- (void) setAlignment: (NSTextAlignment)newAlignment
{
  _alignment = newAlignment;
}

- (void) setFirstLineHeadIndent: (float)aFloat
{
  NSAssert (aFloat >= 0.0, NSInvalidArgumentException);
  _firstLineHeadIndent = aFloat;
}

- (void) setHeadIndent: (float)aFloat
{
  NSAssert (aFloat >= 0.0, NSInvalidArgumentException);
  _headIndent = aFloat;
}

- (void) setTailIndent: (float)aFloat
{
  _tailIndent = aFloat;
}

- (void) setLineBreakMode: (NSLineBreakMode)mode
{
  _lineBreakMode = mode;
}

- (void) setMinimumLineHeight: (float)aFloat
{
  NSAssert (aFloat >= 0.0, NSInvalidArgumentException);
  _minimumLineHeight = aFloat;
}

- (void) setMaximumLineHeight: (float)aFloat
{
  NSAssert (aFloat >= 0.0, NSInvalidArgumentException);
  _maximumLineHeight = aFloat;
}

- (void) setBaseWritingDirection: (NSWritingDirection)direction
{
  _baseDirection = direction;
}

- (void) addTabStop: (NSTextTab*)anObject
{
  unsigned	count = [_tabStops count];

  if (count == 0)
    {
      [_tabStops addObject: anObject];
    }
  else
    {
      while (count-- > 0)
	{
	  NSTextTab	*tab;

	  tab = [_tabStops objectAtIndex: count];
	  if ([tab compare: anObject] != NSOrderedDescending)
	    {
	      [_tabStops insertObject: anObject atIndex: count + 1];
	      return;
	    }
	}
      [_tabStops insertObject: anObject atIndex: 0];
    }
}

- (void) removeTabStop: (NSTextTab*)anObject
{
  unsigned	i = [_tabStops indexOfObject: anObject];

  if (i != NSNotFound)
    [_tabStops removeObjectAtIndex: i];
}

- (void) setTabStops: (NSArray *)array
{
  if (array != _tabStops)
    {
      [_tabStops removeAllObjects];
      [_tabStops addObjectsFromArray: array];
      [_tabStops sortUsingSelector: @selector(compare:)];
    }
}

- (void) setParagraphStyle: (NSParagraphStyle*)obj
{
  NSMutableParagraphStyle	*p = (NSMutableParagraphStyle*)obj;

  if (p == self)
    return;

  /* Can add tab stops without sorting as we know they are already sorted. */
  [_tabStops removeAllObjects];
  [_tabStops addObjectsFromArray: p->_tabStops];

  _alignment = p->_alignment;
  _firstLineHeadIndent = p->_firstLineHeadIndent;
  _headIndent = p->_headIndent;
  _lineBreakMode = p->_lineBreakMode;
  _lineSpacing = p->_lineSpacing;
  _maximumLineHeight = p->_maximumLineHeight;
  _minimumLineHeight = p->_minimumLineHeight;
  _paragraphSpacing = p->_paragraphSpacing;
  _tailIndent = p->_tailIndent;
  _baseDirection = p->_baseDirection;
}

- (id) copyWithZone: (NSZone*)aZone
{
  NSMutableParagraphStyle	*c;

  c = (NSMutableParagraphStyle*)NSCopyObject (self, 0, aZone);
  GSDebugAllocationRemove(c->isa, c);
  c->isa = [NSParagraphStyle class];
  GSDebugAllocationAdd(c->isa, c);
  c->_tabStops = [_tabStops mutableCopyWithZone: aZone];
  return c;
}

@end
