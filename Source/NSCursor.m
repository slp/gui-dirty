/** <title>NSCursor</title>

   <abstract>Holds an image to use as a cursor</abstract>

   Copyright (C) 1996,1999,2001 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Adam Fedor <fedor@gnu.org>
   Date: Dec 2001
   
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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/ 

#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSKeyedArchiver.h>

#include "AppKit/NSColor.h"
#include "AppKit/NSCursor.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/NSBitmapImageRep.h"

#include "GNUstepGUI/GSDisplayServer.h"

// Class variables
static NSMutableArray *gnustep_gui_cursor_stack;
static NSCursor *gnustep_gui_current_cursor;
static BOOL gnustep_gui_hidden_until_move;
static Class NSCursor_class;

static NSMutableDictionary *cursorDict = nil;

@implementation NSCursor

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSCursor class])
    {
      // Initial version
      [self setVersion:1];

      // Initialize class variables
      NSCursor_class = self;
      gnustep_gui_cursor_stack = [[NSMutableArray alloc] initWithCapacity: 2];
      gnustep_gui_hidden_until_move = NO;
      cursorDict = [NSMutableDictionary new]; 
      [[self arrowCursor] push];
    }
}

- (void *) _cid
{
  return _cid;
}

- (void) _setCid: (void *)val
{
  _cid = val;
}

- (void) _computeCid
{
  void *c;
  NSBitmapImageRep *rep;
  
  if (_cursor_image == nil)
    {
      _cid = NULL;
      return;
    }

/*
  We should rather convert the image to a bitmap representation here via 
  the following code, but this is currently not supported by the libart backend

{
  NSSize size = [_cursor_image size];

  [_cursor_image lockFocus];
  rep = [[NSBitmapImageRep alloc] initWithFocusedViewRect: 
            NSMakeRect(0, 0, size.width, size.height)];
  AUTORELEASE(rep);
  [_cursor_image unlockFocus];
} 
 */
  rep = (NSBitmapImageRep *)[_cursor_image bestRepresentationForDevice: nil];
  if (!rep || ![rep respondsToSelector: @selector(samplesPerPixel)])
    {
      NSLog(@"NSCursor can only handle NSBitmapImageReps for now");
      return;
    }
  if (_hot_spot.x >= [rep pixelsWide])
    _hot_spot.x = [rep pixelsWide]-1;
  
  if (_hot_spot.y >= [rep pixelsHigh])
    _hot_spot.y = [rep pixelsHigh]-1;

  [GSCurrentServer() imagecursor: _hot_spot 
		 : [rep pixelsWide] : [rep pixelsHigh]
		 : [rep samplesPerPixel] : [rep bitmapData] : &c];
  _cid = c;
}

/*
 * Setting the Cursor
 */
+ (void) hide
{
  [GSCurrentServer() hidecursor];
}

+ (void) pop
{
  /*
   * The object we pop is the current cursor
   */
  if ([gnustep_gui_cursor_stack count] > 1)
    {
      [gnustep_gui_cursor_stack removeLastObject];
      gnustep_gui_current_cursor = [gnustep_gui_cursor_stack lastObject];

      NSDebugLLog(@"NSCursor", @"Cursor pop");
      [gnustep_gui_current_cursor set];
    }
}

+ (void) setHiddenUntilMouseMoves: (BOOL)flag
{
  if (flag)
    {
      [self hide];
    } 
  else 
    {
      [self unhide];
    } 
  gnustep_gui_hidden_until_move = flag;
}

+ (BOOL) isHiddenUntilMouseMoves
{
  return gnustep_gui_hidden_until_move;
}

+ (void) unhide
{
  [GSCurrentServer() showcursor];
}

/*
 * Getting the Cursor
 */
static
NSCursor *getStandardCursor(NSString *name, int style)
{
  NSCursor *cursor = [cursorDict objectForKey: name];

  if (cursor == nil)
    {
      void *c = NULL;
    
      cursor = [[NSCursor_class alloc] initWithImage: nil];
      [GSCurrentServer() standardcursor: style : &c];
      if (c == NULL)
        {
	  /* 
	     There is no standard cursor with this name defined in the 
	     backend, so try an image with this name.
	  */
	  [cursor setImage: [NSImage imageNamed: name]];
	}
      else
        {
	  [cursor _setCid: c];
	}
      [cursorDict setObject: cursor forKey: name];
      RELEASE(cursor);
    }
  return cursor;
}

+ (NSCursor*) arrowCursor
{
  return getStandardCursor(@"GSArrowCursor", GSArrowCursor);
}

+ (NSCursor*) IBeamCursor
{
  return getStandardCursor(@"GSIBeamCursor", GSIBeamCursor);
}

+ (NSCursor*) closedHandCursor
{
  return getStandardCursor(@"GSClosedHandCursor", GSClosedHandCursor);
}

+ (NSCursor*) crosshairCursor
{
  return getStandardCursor(@"GSCrosshairCursor", GSCrosshairCursor);
}

+ (NSCursor*) disappearingItemCursor
{
  return getStandardCursor(@"GSDisappearingItemCursor", GSDisappearingItemCursor);
}

+ (NSCursor*) openHandCursor
{
  return getStandardCursor(@"GSOpenHandCursor", GSOpenHandCursor);
}

+ (NSCursor*) pointingHandCursor
{
  return getStandardCursor(@"GSPointingHandCursor", GSPointingHandCursor);
}

+ (NSCursor*) resizeDownCursor
{
  return getStandardCursor(@"GSResizeDownCursor", GSResizeDownCursor);
}

+ (NSCursor*) resizeLeftCursor
{
  return getStandardCursor(@"GSResizeLeftCursor", GSResizeLeftCursor);
}

+ (NSCursor*) resizeLeftRightCursor
{
  return getStandardCursor(@"GSResizeLeftRightCursor", GSResizeLeftRightCursor);
}

+ (NSCursor*) resizeRightCursor
{
  return getStandardCursor(@"GSResizeRightCursor", GSResizeRightCursor);
}

+ (NSCursor*) resizeUpCursor
{
  return getStandardCursor(@"GSResizeUpCursor", GSResizeUpCursor);
}

+ (NSCursor*) resizeUpDownCursor
{
  return getStandardCursor(@"GSResizeUpDownCursor", GSResizeUpDownCursor);
}

+ (NSCursor*) currentCursor
{
  return gnustep_gui_current_cursor;
}

+ (NSCursor*) greenArrowCursor
{
  NSString *name = @"GSGreenArrowCursor";
  NSCursor *cursor = [cursorDict objectForKey: name];
  if (cursor == nil)
    {
      void *c;
    
      cursor = [[NSCursor_class alloc] initWithImage: nil];
      [GSCurrentServer() standardcursor: GSArrowCursor : &c];
      [GSCurrentServer() setcursorcolor: [NSColor greenColor] 
      	                               : [NSColor blackColor] : c];
      [cursor _setCid: c];
      [cursorDict setObject: cursor forKey: name];
      RELEASE(cursor);
    }
  return cursor;
}

/*
 * Initializing a New NSCursor Object
 */
- (id) init
{
  return [self initWithImage: nil hotSpot: NSMakePoint(0,15)];
}

- (id) initWithImage: (NSImage *)newImage
{
  return [self initWithImage: newImage
		     hotSpot: NSMakePoint(0,15)];
}

- (id) initWithImage: (NSImage *)newImage hotSpot: (NSPoint)hotSpot
{
  //_is_set_on_mouse_entered = NO;
  //_is_set_on_mouse_exited = NO;
  _hot_spot = hotSpot;
  [self setImage: newImage];

  return self;
}

- (id)initWithImage:(NSImage *)newImage 
foregroundColorHint:(NSColor *)fg 
backgroundColorHint:(NSColor *)bg
	    hotSpot:(NSPoint)hotSpot
{
  NSCursor *cursor = [self initWithImage: newImage hotSpot: hotSpot];
  if (fg || bg)
    {
      if (bg == nil)
	bg = [NSColor whiteColor];
      if (fg == nil)
	fg = [NSColor blackColor];
      bg = [bg colorUsingColorSpaceName: NSDeviceRGBColorSpace];
      fg = [fg colorUsingColorSpaceName: NSDeviceRGBColorSpace];
      [GSCurrentServer() setcursorcolor: fg : bg : _cid];
    }
  return cursor;
}
- (void)dealloc
{
  RELEASE (_cursor_image);
  [super dealloc];
}
/*
 * Defining the Cursor
 */
- (NSPoint) hotSpot
{
  // FIXME: This wont work for the standard cursor
  return _hot_spot;
}

- (NSImage*) image
{
  // FIXME: This wont work for the standard cursor
  return _cursor_image;
}

- (void) setHotSpot: (NSPoint)spot
{
  _hot_spot = spot;
  [self _computeCid];
}

- (void) setImage: (NSImage *)newImage
{
  ASSIGN(_cursor_image, newImage);
  [self _computeCid];
}

/*
 * Setting the Cursor
 */
- (BOOL) isSetOnMouseEntered
{
  return _is_set_on_mouse_entered;
}

- (BOOL) isSetOnMouseExited
{
  return _is_set_on_mouse_exited;
}

- (void) mouseEntered: (NSEvent*)theEvent
{
  if (_is_set_on_mouse_entered == YES)
    {
      [self set];
    }
  else if (_is_set_on_mouse_exited == NO)
    {
      /*
       * Undocumented behavior - if a cursor is not set on exit or entry,
       * we assume a push-pop situation instead.
       */
      [self push];
    }
}

- (void) mouseExited: (NSEvent*)theEvent
{
  NSDebugLLog(@"NSCursor", @"Cursor mouseExited:");
  if (_is_set_on_mouse_exited == YES)
    {
      [self set];
    }
  else if (_is_set_on_mouse_entered == NO)
    {
      /*
       * Undocumented behavior - if a cursor is not set on exit or entry,
       * we assume a push-pop situation instead.
       */
      [self pop];
    }
}

- (void) pop
{
  [NSCursor_class pop];
}

- (void) push
{
  [gnustep_gui_cursor_stack addObject: self];
  [self set];
  NSDebugLLog(@"NSCursor", @"Cursor push %p", _cid);
}

- (void) set
{
  gnustep_gui_current_cursor = self;
  if (_cid)
    {
      [GSCurrentServer() setcursorcolor: nil : nil : _cid];
    }
}

- (void) setOnMouseEntered: (BOOL)flag
{
  _is_set_on_mouse_entered = flag;
}

- (void) setOnMouseExited: (BOOL)flag
{
  _is_set_on_mouse_exited = flag;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // FIXME: This wont work for the two standard cursor
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_set_on_mouse_entered];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_is_set_on_mouse_exited];
  [aCoder encodeObject: _cursor_image];
  [aCoder encodePoint: _hot_spot];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      int type = 0;
      NSPoint hotSpot;
      
      if ([aDecoder containsValueForKey: @"NSCursorType"])
        {
	  type = [aDecoder decodeIntForKey: @"NSCursorType"];
	}

      DESTROY(self);
      // FIXME
      if (type == 0)
        {
	  self = [NSCursor arrowCursor];
	}
      else if (type == 1)
        {
	  self = [NSCursor IBeamCursor];
	}
      else 
        {
	  // FIXME
	  self = [NSCursor arrowCursor];
	}
      
      if ([aDecoder containsValueForKey: @"NSHotSpot"])
        {
	  hotSpot = [aDecoder decodePointForKey: @"NSHotSpot"];
	}
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_set_on_mouse_entered];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_set_on_mouse_exited];
      _cursor_image = [aDecoder decodeObject];
      _hot_spot = [aDecoder decodePoint];
      [self _computeCid];
    }
  return self;
}

@end
