/* 
   NSCursor.m

   Holds an image to use as a cursor

   Copyright (C) 1996,1999 Free Software Foundation, Inc.

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include <Foundation/NSArray.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/DPSOperators.h>

// Class variables
static NSMutableArray *gnustep_gui_cursor_stack;
static NSCursor *gnustep_gui_current_cursor;
static BOOL gnustep_gui_hidden_until_move;
static Class NSCursor_class;

static NSCursor *arrowCursor = nil;
static NSCursor *ibeamCursor = nil;

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
      gnustep_gui_hidden_until_move = YES;
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

  rep = (NSBitmapImageRep *)[_cursor_image bestRepresentationForDevice: nil];
  /* FIXME: Handle cached image reps also */
  if (!rep || ![rep respondsToSelector: @selector(samplesPerPixel)])
    {
      NSLog(@"NSCursor can only handle NSBitmapImageReps for now");
      return;
    }
  if (_hot_spot.x >= [rep pixelsWide])
    _hot_spot.x = [rep pixelsWide]-1;
  
  if (_hot_spot.y >= [rep pixelsHigh])
    _hot_spot.y = [rep pixelsHigh]-1;

  DPSimagecursor(GSCurrentContext(), _hot_spot.x, _hot_spot.y, 
		 [rep pixelsWide], [rep pixelsHigh],
		 [rep samplesPerPixel], [rep bitmapData], &c);
  _cid = c;
}

/*
 * Setting the Cursor
 */
+ (void) hide
{
  DPShidecursor(GSCurrentContext());
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

      [gnustep_gui_current_cursor set];
    }
}

+ (void) setHiddenUntilMouseMoves: (BOOL)flag
{
  gnustep_gui_hidden_until_move = flag;
}

+ (BOOL) isHiddenUntilMouseMoves
{
  return gnustep_gui_hidden_until_move;
}

+ (void) unhide
{
  DPSshowcursor(GSCurrentContext());  
}

/*
 * Getting the Cursor
 */
+ (NSCursor*) arrowCursor
{
  if (arrowCursor == nil)
    {
      void *c;
    
      arrowCursor = [[NSCursor_class alloc] initWithImage: nil];
      DPSstandardcursor(GSCurrentContext(), GSArrowCursor, &c);
      [arrowCursor _setCid: c];
    }
  return arrowCursor;
}

+ (NSCursor*) currentCursor
{
  return gnustep_gui_current_cursor;
}

+ (NSCursor*) IBeamCursor
{
  if (ibeamCursor == nil)
    {
      void *c;
    
      ibeamCursor = [[NSCursor_class alloc] initWithImage: nil];
      DPSstandardcursor(GSCurrentContext(), GSIBeamCursor, &c);
      [ibeamCursor _setCid: c];
    }
  return ibeamCursor;
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

- (id) initWithImage: (NSImage *)newImage hotSpot: (NSPoint)spot
{
  //_is_set_on_mouse_entered = NO;
  //_is_set_on_mouse_exited = NO;
  _hot_spot = spot;
  [self setImage: newImage];

  return self;
}

- (id)initWithImage:(NSImage *)newImage 
foregroundColorHint:(NSColor *)fg 
backgroundColorHint:(NSColor *)bg
	    hotSpot:(NSPoint)hotSpot
{
    // FIXME: fg and bg should be set
  return [self initWithImage: newImage hotSpot: hotSpot];
}

/*
 * Defining the Cursor
 */
- (NSPoint) hotSpot
{
  // FIXME: This wont work for the two standard cursor
  return _hot_spot;
}

- (NSImage*) image
{
  // FIXME: This wont work for the two standard cursor
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
}

- (void) set
{
  gnustep_gui_current_cursor = self;
  if (_cid)
    {
      DPSsetcursorcolor(GSCurrentContext(), -1, 0, 0, 1, 1, 1, _cid);
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
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_set_on_mouse_entered];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_is_set_on_mouse_exited];
  _cursor_image = [aDecoder decodeObject];
  _hot_spot = [aDecoder decodePoint];
  [self _computeCid];

  return self;
}

@end
