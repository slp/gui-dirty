/** <title>NSStepperCell</title>

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: 2001
   
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

#include <gnustep/gui/config.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSColor.h>
#include <AppKit/DPSOperators.h>
#include <AppKit/PSOperators.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSStepperCell.h>
#include <AppKit/NSText.h>

@implementation NSStepperCell
+ (void) initialize
{
  if (self == [NSStepperCell class])
    {
      [self setVersion: 1];
    }
}

//
// Initialization
//
- (id) init
{
  [self setIntValue: 0];
  [super setAlignment: NSRightTextAlignment];
  [super setWraps: NO];
  _autorepeat = YES;
  _valueWraps = YES;
  _maxValue = 59;
  _minValue = 0;
  _increment = 1;
  highlightUp = NO;
  highlightDown = NO;
  return self;
}

- (double) maxValue
{
  return _maxValue;
}

- (void) setMaxValue: (double)maxValue
{
  _maxValue = maxValue;
}

- (double) minValue
{
  return _minValue;
}

- (void) setMinValue: (double)minValue
{
  _minValue = minValue;
}

- (double) increment
{
  return _increment;
}

- (void) setIncrement: (double)increment
{
  _increment = increment;
}



- (BOOL)autorepeat
{
  return _autorepeat;
}

- (void)setAutorepeat: (BOOL)autorepeat
{
  _autorepeat = autorepeat;
}

- (BOOL)valueWraps
{
  return _valueWraps;
}

- (void)setValueWraps: (BOOL)valueWraps
{
  _valueWraps = valueWraps;
}

- (void) dealloc
{
  [super dealloc];
}

- (id) copyWithZone: (NSZone*)zone
{
  NSStepperCell *c = [super copyWithZone: zone];

  return c;
}

inline void DrawUpButton(NSRect aRect)
{
  NSRectEdge up_sides[] = {NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  float grays[] = {NSWhite, NSWhite, 
		   NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt;
  ctxt = GSCurrentContext();
  
  rect = NSDrawTiledRects(aRect, NSZeroRect,
			  up_sides, grays, 4);
  DPSsetgray(ctxt, NSLightGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
      
  PSsetgray(NSDarkGray);
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  PSsetgray(NSWhite);
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

inline void HighlightUpButton(NSRect aRect)
{
  NSRectEdge up_sides[] = {NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  float grays[] = {NSWhite, NSWhite, 
		   NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt;
  ctxt = GSCurrentContext();
  
  rect = NSDrawTiledRects(aRect, NSZeroRect,
			  up_sides, grays, 4);
  DPSsetgray(ctxt, NSWhite);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
      
  PSsetgray(NSLightGray);
  PSmoveto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMaxX(aRect) - 8, NSMinY(aRect) + 9);
  PSlineto(NSMaxX(aRect) - 11, NSMinY(aRect) + 4);
  PSstroke();
  PSsetgray(NSLightGray);
  PSmoveto(NSMaxX(aRect) - 11, NSMinY(aRect) + 3);
  PSlineto(NSMaxX(aRect) - 5, NSMinY(aRect) + 3);
  PSstroke();
}

inline void DrawDownButton(NSRect aRect)
{
  NSRectEdge up_sides[] = {NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  float grays[] = {NSWhite, NSWhite, 
		   NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt;
  ctxt = GSCurrentContext();
  
  rect = NSDrawTiledRects(aRect, NSZeroRect,
			  up_sides, grays, 4);
  DPSsetgray(ctxt, NSLightGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));

  PSsetlinewidth(1.0);
  PSsetgray(NSDarkGray);
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  PSsetgray(NSWhite);
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

inline void HighlightDownButton(NSRect aRect)
{
  NSRectEdge up_sides[] = {NSMinXEdge, NSMaxYEdge, 
			   NSMaxXEdge, NSMinYEdge};
  float grays[] = {NSWhite, NSWhite, 
		   NSDarkGray, NSDarkGray};
  NSRect rect;
  NSGraphicsContext *ctxt;
  ctxt = GSCurrentContext();
  
  rect = NSDrawTiledRects(aRect, NSZeroRect,
			  up_sides, grays, 4);
  DPSsetgray(ctxt, NSWhite);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));
  
  PSsetlinewidth(1.0);
  PSsetgray(NSLightGray);
  PSmoveto(NSMinX(aRect) + 4, NSMaxY(aRect) - 3);
  PSlineto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSstroke();
  PSsetgray(NSLightGray);
  PSmoveto(NSMinX(aRect) + 7, NSMaxY(aRect) - 8);
  PSlineto(NSMinX(aRect) + 10, NSMaxY(aRect) - 3);
  PSstroke();
  PSsetgray(NSBlack);
  PSmoveto(NSMinX(aRect) + 10, NSMaxY(aRect) - 2);
  PSlineto(NSMinX(aRect) + 4, NSMaxY(aRect) - 2);
  PSstroke();
}

- (void) drawInteriorWithFrame: (NSRect)cellFrame
			inView: (NSView*)controlView
{
  NSRect upRect;
  NSRect downRect;
  NSRect twoButtons;
  NSGraphicsContext *ctxt;
  ctxt = GSCurrentContext();

  {
    upRect = [self upButtonRectWithFrame: cellFrame];
    downRect = [self downButtonRectWithFrame: cellFrame];

    twoButtons = downRect;
    twoButtons.origin.y--;
    twoButtons.size.width++;
    twoButtons.size.height = 23;

    if (highlightUp)
      HighlightUpButton(upRect);
    else
      DrawUpButton(upRect);

    if (highlightDown)
      HighlightDownButton(downRect);
    else
      DrawDownButton(downRect);

    {
      NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge};
      float grays[] = {NSBlack, NSBlack}; 
      
      NSDrawTiledRects(twoButtons, NSZeroRect,
		       up_sides, grays, 2);
    }
  }
}

- (void) highlight: (BOOL) highlight
	  upButton: (BOOL) upButton
	 withFrame: (NSRect) frame
	    inView: (NSView*) controlView
{
  NSRect upRect;
  NSRect downRect;
  NSGraphicsContext *ctxt;
  ctxt = GSCurrentContext();
  {
    upRect = [self upButtonRectWithFrame: frame];
    downRect = [self downButtonRectWithFrame: frame];
    if (upButton)
      {  
	highlightUp = highlight;
	if (highlightUp)
	  HighlightUpButton(upRect);
	else
	  DrawUpButton(upRect);
      }
    else
      {
	highlightDown = highlight;
	if (highlightDown)
	  HighlightDownButton(downRect);
	else
	  DrawDownButton(downRect);
      }
  }
}

- (NSRect) upButtonRectWithFrame: (NSRect) frame
{
  NSRect upRect;
  upRect.size.width = 15;
  upRect.size.height = 11;
  upRect.origin.x = NSMaxX(frame) - 16;
  upRect.origin.y = NSMinY(frame) + ((int) frame.size.height / 2) + 1;
  return upRect;
}

- (NSRect) downButtonRectWithFrame: (NSRect) frame
{
  NSRect downRect;
  downRect.size.width = 15;
  downRect.size.height = 11;
  downRect.origin.x = NSMaxX(frame) - 16;
  downRect.origin.y = NSMinY(frame) + 
    ((int) frame.size.height / 2) - 10;
  return downRect;
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  BOOL tmp1, tmp2;
  [super encodeWithCoder: aCoder];
  tmp1 = _autorepeat;
  tmp2 = _valueWraps;
  [aCoder encodeValuesOfObjCTypes: "dddii",
	  &_maxValue, &_minValue, &_increment, &tmp1, &tmp2];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  BOOL tmp1, tmp2;
  [super initWithCoder: aDecoder];
  [aDecoder decodeValuesOfObjCTypes: "dddii",
	  &_maxValue, &_minValue, &_increment, &tmp1, &tmp2];
  _autorepeat = tmp1;
  _valueWraps = tmp2;

  return self;
}

@end
