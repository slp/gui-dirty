/** <title>NSTableHeaderCell</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: 1999
   
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

#include "AppKit/NSTableHeaderCell.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSFont.h"
#include "AppKit/NSGraphics.h"
#include "AppKit/NSImage.h"
#include "AppKit/DPSOperators.h"
#include "GNUstepGUI/GSDrawFunctions.h"

// Cache the colors
static NSColor *bgCol;
static NSColor *hbgCol;
static NSColor *clearCol = nil;

@implementation NSTableHeaderCell
{
}
// Default appearance of NSTableHeaderCell
- (id) initTextCell: (NSString *)aString
{
  [super initTextCell: aString];

  [self  setAlignment: NSCenterTextAlignment];
  ASSIGN (_text_color, [NSColor windowFrameTextColor]);
  [self setBackgroundColor: [NSColor controlShadowColor]];
  [self setFont: [NSFont titleBarFontOfSize: 0]];
  _cell.is_bezeled = YES;
  _textfieldcell_draws_background = YES;

  return self;
}
- (void) drawWithFrame: (NSRect)cellFrame
		inView: (NSView *)controlView
{
  NSRect interiorFrame = NSMakeRect (cellFrame.origin.x-1, cellFrame.origin.y-1, 
				cellFrame.size.width+2, cellFrame.size.height+2);

  if (NSIsEmptyRect (cellFrame))
    return;

  if (_cell.is_highlighted == YES)
    {
	[GSDrawFunctions drawButton: cellFrame :cellFrame];
    }
  else
    {
	[GSDrawFunctions drawDarkButton: cellFrame :cellFrame];
    }

  [self drawInteriorWithFrame: interiorFrame inView: controlView];
}

- (NSColor *)textColor
{
  if (_cell.is_highlighted)
    {
      return [NSColor controlTextColor];
    }
  else
    {
      return [NSColor windowFrameTextColor];
    }
}

// Override drawInteriorWithFrame:inView: to be able 
// to display images as NSCell does
- (void) drawInteriorWithFrame: (NSRect)cellFrame 
			inView: (NSView*)controlView
{
  switch (_cell.type)
    {
    case NSTextCellType:
      [super drawInteriorWithFrame: cellFrame inView: controlView];
      break;
      
    case NSImageCellType:
      //
      // Taken (with modifications) from NSCell
      //

      // Initialize static colors if needed
      if (clearCol == nil)
	{
	  bgCol = RETAIN([NSColor controlShadowColor]);
	  hbgCol = RETAIN([NSColor controlHighlightColor]);
	  clearCol = RETAIN([NSColor clearColor]);
	}
      // Prepare to draw
      cellFrame = [self drawingRectForBounds: cellFrame];
      // Deal with the background
      if ([self isOpaque])
	{
	  NSColor *bg;
	  
	  if (_cell.is_highlighted)
	    bg = hbgCol;
	  else
	    bg = bgCol;
	  [bg set];
	  NSRectFill (cellFrame);
	}
      // Draw the image
      if (_cell_image)
	{
	  NSSize size;
	  NSPoint position;
	  
	  size = [_cell_image size];
	  position.x = MAX (NSMidX (cellFrame) - (size.width/2.), 0.);
	  position.y = MAX (NSMidY (cellFrame) - (size.height/2.), 0.);
	  if ([controlView isFlipped])
	    position.y += size.height;
	  [_cell_image compositeToPoint: position operation: NSCompositeSourceOver];
	}
      // End the drawing
      break;
      
    case NSNullCellType:
      break;
    }
}

- (void)setHighlighted: (BOOL) flag
{
  _cell.is_highlighted = flag;
  
  if (flag == YES)
    {
      [self setBackgroundColor: [NSColor controlHighlightColor]];
    }
  else
    {
      [self setBackgroundColor: [NSColor controlShadowColor]];
    }
}

@end
