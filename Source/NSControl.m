/** <title>NSControl</title>

   <abstract>The abstract control class</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: August 1998

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

#include "config.h"

#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include "AppKit/NSActionCell.h"
#include "AppKit/NSApplication.h"
#include "AppKit/NSCell.h"
#include "AppKit/NSControl.h"
#include "AppKit/NSColor.h"
#include "AppKit/NSEvent.h"
#include "AppKit/NSTextStorage.h"
#include "AppKit/NSTextView.h"
#include "AppKit/NSWindow.h"

/*
 * Class variables
 */
static Class usedCellClass;
static Class cellClass;
static Class actionCellClass;

/**<p>TODO Description</p>
 */

@implementation NSControl

/*
 * Class methods
 */
+ (void) initialize
{
  if (self == [NSControl class])
    {
      [self setVersion: 1];
      cellClass = [NSCell class];
      usedCellClass = cellClass;
      actionCellClass = [NSActionCell class];
    }
}

/*
 * Setting the Control's Cell
 */
+ (Class) cellClass
{
  return usedCellClass;
}

+ (void) setCellClass: (Class)factoryId
{
  usedCellClass = factoryId ? factoryId : cellClass;
}

/** <p>Initializes a new NSControl into the frame frameRect and create
    a new NSCell</p><p>See Also: -setCell:</p> 
 */
- (id) initWithFrame: (NSRect)frameRect
{
  NSCell *cell = [[[self class] cellClass] new];

  [super initWithFrame: frameRect];
  [self setCell: cell];
  RELEASE(cell);
  //_tag = 0;

  return self;
}

- (void) dealloc
{
  RELEASE(_cell);
  [super dealloc];
}

/** <p>Returns the NSControl's cell</p><p>See Also: -setCell:</p> 
 */
- (id) cell
{
  return _cell;
}

/** <p>Sets the NSControl's cell to aCell, Raises an NSInvalidArgumentException
    exception if aCell is nil or if it is not a cell class</p>
    <p>See Also: -cell</p> 
 */
- (void) setCell: (NSCell *)aCell
{
  if (aCell != nil && [aCell isKindOfClass: cellClass] == NO)
    [NSException raise: NSInvalidArgumentException
		format: @"attempt to set non-cell object for control cell"];

  ASSIGN(_cell, aCell);
}

/**<p>Returns whether the selected cell of the NSControl is enabled</p>
 <p>See Also: -setEnabled:</p>
 */
- (BOOL) isEnabled
{
  return [[self selectedCell] isEnabled];
}

/**<p>Sets whether the NSControl's selected cell is enabled.
   If flag is NO, this method abort the editing. This method marks self for
   display</p><p>See Also: -isEnabled</p>
 */
- (void) setEnabled: (BOOL)flag
{
  [[self selectedCell] setEnabled: flag];
  if (!flag)
    [self abortEditing];
  [self setNeedsDisplay: YES];
}

/** <p>Returns the NSControl's selected cell</p>
 */
- (id) selectedCell
{
  return _cell;
}

/** <p>Returns the tag of the NSControl's selected cell (if exists).
    -1 otherwise</p><p>See Also: [NSCell-tag]</p>
 */
- (int) selectedTag
{
  NSCell *selected = [self selectedCell];

  if (selected == nil)
    return -1;
  else
    return [selected tag];
}

/** <p>Returns the value if the NSControl's selected cell as double</p>
    <p>See Also: [NSCell-doubleValue]</p>
 */
- (double) doubleValue
{
  // The validation is performed by the NSActionCell
  return [[self selectedCell] doubleValue];
}

/** <p>Returns the value if the NSControl's selected cell as float</p>
    <p>See Also: [NSCell-floatValue]</p>
 */
- (float) floatValue
{
  return [[self selectedCell] floatValue];
}

/** <p>Returns the value if the NSControl's selected cell as int</p>
    <p>See Also: [NSCell-intValue]</p>
 */
- (int) intValue
{
  return [[self selectedCell] intValue];
}

/** <p>Returns the value if the NSControl's selected cell as NSString</p>
    <p>See Also: [NSCell-stringValue]</p>
 */
- (NSString *) stringValue
{
  return [[self selectedCell] stringValue];
}

- (id) objectValue
{
  return [[self selectedCell] objectValue];
}

/** <p>Sets the value if the NSControl's selected cell to double.
    If the selected cell is an action cell, it marks self for display.</p>
    <p>See Also: -doubleValue [NSCell-setDoubleValue:]</p>
 */
- (void) setDoubleValue: (double)aDouble
{
  NSCell *selected = [self selectedCell];
  BOOL wasEditing = [self abortEditing];

  [selected setDoubleValue: aDouble];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];

  if (wasEditing)
    {
      [[self window] makeFirstResponder: self];
    }
}

/** <p>Sets the value if the NSControl's selected cell to float.
    If the selected cell is an action cell, it marks self for display.</p>
    <p>See Also: -floatValue [NSCell-setFloatValue:]</p>
 */
- (void) setFloatValue: (float)aFloat
{
  NSCell *selected = [self selectedCell];
  BOOL wasEditing = [self abortEditing];

  [selected setFloatValue: aFloat];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];

  if (wasEditing)
    {
      [[self window] makeFirstResponder: self];
    }
}

/** <p>Sets the value if the NSControl's selected cell to int.
    If the selected cell is an action cell, it marks self for display.</p>
    <p>See Also: -intValue [NSCell-setIntValue:]</p>
 */
- (void) setIntValue: (int)anInt
{
  NSCell *selected = [self selectedCell];
  BOOL wasEditing = [self abortEditing];

  [selected setIntValue: anInt];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];

  if (wasEditing)
    {
      [[self window] makeFirstResponder: self];
    }
}

/** <p>Sets the value if the NSControl's selected cell to NSString.
    If the selected cell is an action cell, it marks self for display.</p>
    <p>See Also: stringValue [NSCell-setStringValue:]</p>
 */
- (void) setStringValue: (NSString *)aString
{
  NSCell *selected = [self selectedCell];
  BOOL wasEditing = [self abortEditing];

  [selected setStringValue: aString];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];

  if (wasEditing)
    {
      [[self window] makeFirstResponder: self];
    }
}

- (void) setObjectValue: (id)anObject
{
  NSCell *selected = [self selectedCell];
  BOOL wasEditing = [self abortEditing];

  [selected setObjectValue: anObject];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];

  if (wasEditing)
    {
      [[self window] makeFirstResponder: self];
    }
}

/** <p>Marks self for display</p>
*/
- (void) setNeedsDisplay
{
  [super setNeedsDisplay: YES];
}

/*
 * Interacting with Other Controls
 */
- (void) takeDoubleValueFrom: (id)sender
{
  [[self selectedCell] takeDoubleValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeFloatValueFrom: (id)sender
{
  [[self selectedCell] takeFloatValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeIntValueFrom: (id)sender
{
  [[self selectedCell] takeIntValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeObjectValueFrom: (id)sender
{
  [[self selectedCell] takeObjectValueFrom: sender];
  [self setNeedsDisplay: YES];
}

- (void) takeStringValueFrom: (id)sender
{
  [[self selectedCell] takeStringValueFrom: sender];
  [self setNeedsDisplay: YES];
}

/**<p>Returns the alignment of the text in the NSControl's cell.
   Returns NSNaturalTextAlignment if the cell does not exists</p>
   <p>See Also: -setAlignment: </p>
 */
- (NSTextAlignment) alignment
{
  if (_cell)
    return [_cell alignment];
  else
    return NSNaturalTextAlignment;
}

/**<p>Returns the font of the text in the NSControl's cell.
   Returns nil if the cell does not exists</p>
   <p>See Also: -setFont: </p>
 */
- (NSFont *) font
{
  if (_cell)
    return [_cell font];
  else
    return nil;
}

/**<p>Sets the alignment of the text in the NSControl's cell.
   This method abort the editing and  marks self for display if the cell 
   is an NSActionCell</p><p>See Also: -alignment </p>
 */
- (void) setAlignment: (NSTextAlignment)mode
{
  if (_cell)
    {
      [self abortEditing];

      [_cell setAlignment: mode];
      if (![_cell isKindOfClass: actionCellClass])
	[self setNeedsDisplay: YES];
    }
}

/**<p>Sets the font of the text in the NSControl's cell.</p>
   <p>See Also: -font </p>
 */
- (void) setFont: (NSFont *)fontObject
{
  if (_cell)
    {
      NSText *editor = [self currentEditor];
      
      [_cell setFont: fontObject];
      if (editor != nil)
	[editor setFont: fontObject];
    }
}

- (void) setFloatingPointFormat: (BOOL)autoRange
			   left: (unsigned)leftDigits
			  right: (unsigned)rightDigits
{
  [self abortEditing];

  [_cell setFloatingPointFormat: autoRange  left: leftDigits
	 right: rightDigits];
  if (![_cell isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (void) setFormatter: (NSFormatter*)newFormatter 
{
  if (_cell)
    {
      [_cell setFormatter: newFormatter];
      if (![_cell isKindOfClass: actionCellClass])
	[self setNeedsDisplay: YES];
    }
}

- (id) formatter
{
  return [_cell formatter];
}

/**<p>Sends an [NSCell-endEditing:] message to the current  object used to
   edit the NSControl. Returns NO if the the currentEditor does not exists, 
   YES otherwise.</p>   
 */
- (BOOL) abortEditing
{
  NSText *text;

  text = [self currentEditor];
  if (text == nil)
    {
      return NO;
    }

  [[self selectedCell] endEditing: text];
  return YES;
}


- (NSText *) currentEditor
{
  if (_cell != nil)
    {
      NSText *text;

      text = [_window fieldEditor: NO forObject: self];
      if (([text delegate] == self) && ([_window firstResponder] == text))
        {
	  return text;
	}
    }

  return nil;
}

/**
 */
- (void) validateEditing
{
  NSText *text;

  text = [self currentEditor];
  if (text == nil)
    {
      return;
    }

  if ([text isRichText])
    {
      NSAttributedString *attr;
      NSTextStorage *storage;
      int len;
      
      storage = [(NSTextView*)text textStorage];
      len = [storage length];
      attr = [storage attributedSubstringFromRange: NSMakeRange(0, len)];
      [[self selectedCell] setAttributedStringValue: attr];
    }
  else
    {
      NSString *string;

      string = AUTORELEASE([[text string] copy]);
      [[self selectedCell] setStringValue: string];
    }
}

/**<p>Recalculates the internal size by sending [NSCell-calcDrawInfo:] 
   to the cell.</p>
 */
- (void) calcSize
{
  [_cell calcDrawInfo: [self bounds]];
}

/**<p>Resizes the NSControl to fits the NSControl's cell size</p> 
  <p>See Also: [NSCell-cellSize]</p>
 */
- (void) sizeToFit
{
  [self setFrameSize: [_cell cellSize]];
}

/** <p>Returns whether the NSControl's cell is opaque</p>
 */
- (BOOL) isOpaque
{
  return [_cell isOpaque];
}

- (void) drawRect: (NSRect)aRect
{
  [self drawCell: _cell];
}

- (void) drawCell: (NSCell *)aCell
{
  if (_cell == aCell)
    {
      [_cell drawWithFrame: _bounds inView: self];
    }
}

- (void) drawCellInside: (NSCell *)aCell
{
  if (_cell == aCell)
    {
      [_cell drawInteriorWithFrame: _bounds 
	    inView: self];
    }
}

/** <p>Selects aCell if it's the NSControl's cell</p>
 */
- (void) selectCell: (NSCell *)aCell
{
  if (_cell == aCell)
    {
      [_cell setState: 1];
      [self setNeedsDisplay: YES];
    }
}


/** <p>Marks self for display</p>
 */
- (void) updateCell: (NSCell *)aCell
{
  [self setNeedsDisplay: YES];
}

/** <p>Marks self for display</p>
 */
- (void) updateCellInside: (NSCell *)aCell
{
  [self setNeedsDisplay: YES];
}

/** <p>Returns the NSControl's cell action method</p>
    <p>See Also: -setAction: [NSCell-action] </p>
 */
- (SEL) action
{
  return [_cell action];
}

/** <p>Returns whether the NSControl's cell can continuously sends its action
    message</p>
    <p>See Also: -setContinuous: [NSCell-isContinuous] </p>
 */
- (BOOL) isContinuous
{
  return [_cell isContinuous];
}

- (BOOL) sendAction: (SEL)theAction to: (id)theTarget
{
  if (theAction)
    return [NSApp sendAction: theAction to: theTarget from: self];
  else
    return NO;
}

- (int) sendActionOn: (int)mask
{
  return [_cell sendActionOn: mask];
}

/**<p>Sets the NSControl's cell action method</p>
   <p>See Also: -action [NSCell-setAction:]</p>
*/
- (void) setAction: (SEL)aSelector
{
  [_cell setAction: aSelector];
}

/** <p>Sets whether the NSControl's cell can continuously sends its action 
    message</p><p>See Also: -isContinuous [NSCell-setContinuous:]</p>
*/ 
- (void) setContinuous: (BOOL)flag
{
  [_cell setContinuous: flag];
}

/** <p>Sets the target object of the NSControl's cell to anObject</p>
    <p>See Also: -target [NSCell-setTarget:]</p>
 */
- (void) setTarget: (id)anObject
{
  [_cell setTarget: anObject];
}

/**<p>Returns the target object of the NSControl's cell</p>
   <p>See Also: -setTarget: [NSCell-target]</p>
 */
- (id) target
{
  return [_cell target];
}

/*
 * Attributed string handling
 */
- (void) setAttributedStringValue: (NSAttributedString*)attribStr
{
  NSCell *selected = [self selectedCell];

  [self abortEditing];

  [selected setAttributedStringValue: attribStr];
  if (![selected isKindOfClass: actionCellClass])
    [self setNeedsDisplay: YES];
}

- (NSAttributedString*) attributedStringValue
{
  NSCell *selected = [self selectedCell];

  if (selected == nil)
    {
      return AUTORELEASE([NSAttributedString new]);
    }

  // As this mehtod is not defined for NSActionCell, we have 
  // to do the validation here.
  [self validateEditing];

  return [selected attributedStringValue];
}

/** 
 * Assigning a Tag
 */
- (void) setTag: (int)anInt
{
  _tag = anInt;
}

- (int) tag
{
  return _tag;
}

/*
 * Activation
 */

/**
 * Simulates a single mouse click on the control. This method calls the cell's
 * method performClickWithFrame:inView:. Take note that <var>sender</var> is not
 * used. 
 */
- (void) performClick: (id)sender
{
  [_cell performClickWithFrame: [self bounds] inView: self];
}

- (BOOL)refusesFirstResponder
{
  return [[self selectedCell] refusesFirstResponder];
}

- (void)setRefusesFirstResponder:(BOOL)flag
{
  [[self selectedCell] setRefusesFirstResponder: flag];
}

- (BOOL) acceptsFirstResponder
{
  return [[self selectedCell] acceptsFirstResponder];
}

/*
 * Tracking the Mouse
 */
- (void) mouseDown: (NSEvent *)theEvent
{
  NSApplication *theApp = [NSApplication sharedApplication];
  BOOL mouseUp = NO, done = NO;
  NSEvent *e;
  int oldActionMask;
  NSPoint location;
  unsigned int event_mask = NSLeftMouseDownMask | NSLeftMouseUpMask
    | NSMouseMovedMask | NSLeftMouseDraggedMask | NSOtherMouseDraggedMask
    | NSRightMouseDraggedMask;

  if (![self isEnabled])
    return;

  if (_ignoresMultiClick && ([theEvent clickCount] > 1))
    {  
      [super mouseDown: theEvent];
      return;
    }

  if ([_cell isContinuous])
    {
      oldActionMask = [_cell sendActionOn: NSPeriodicMask];
    }
  else
    {
      oldActionMask = [_cell sendActionOn: 0];
    }
  
  [_window _captureMouse: self];

  e = theEvent;
  // loop until mouse goes up
  while (!done)
    {
      location = [e locationInWindow];
      location = [self convertPoint: location fromView: nil];
      // ask the cell to track the mouse only
      // if the mouse is within the cell
      if ([self mouse: location inRect: _bounds])
	{
	  [_cell setHighlighted: YES];
	  [self setNeedsDisplay: YES];
	  if ([_cell trackMouse: e
		     inRect: _bounds
		     ofView: self
		     untilMouseUp: [[_cell class] prefersTrackingUntilMouseUp]])
	    done = mouseUp = YES;
	  else
	    {
	      [_cell setHighlighted: NO];
	      [self setNeedsDisplay: YES];
	    }
	}

      if (done)
	break;

      e = [theApp nextEventMatchingMask: event_mask
			      untilDate: nil
				 inMode: NSEventTrackingRunLoopMode
				dequeue: YES];
      if ([e type] == NSLeftMouseUp)
	done = YES;
    }

  [_window _releaseMouse: self];

  if (mouseUp)
    {
      [_cell setHighlighted: NO];
      [self setNeedsDisplay: YES];
    }

  [_cell sendActionOn: oldActionMask];

  if (mouseUp)
    [self sendAction: [self action] to: [self target]];
}

- (BOOL) shouldBeTreatedAsInkEvent: (NSEvent *)theEvent
{
  return NO;
}

- (void) resetCursorRects
{
  [_cell resetCursorRect: _bounds inView: self];
}

- (BOOL) ignoresMultiClick
{
  return _ignoresMultiClick;
}

- (void) setIgnoresMultiClick: (BOOL)flag
{
  _ignoresMultiClick = flag;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeValueOfObjCType: @encode(int) at: &_tag];
  [aCoder encodeObject: _cell];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_ignoresMultiClick];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
      NSCell *cell = [aDecoder decodeObjectForKey: @"NSCell"];
      
      if (cell != nil)
        {
	  [self setCell: cell];
	}
      if ([aDecoder containsValueForKey: @"NSEnabled"])
        {
	  [self setEnabled: [aDecoder decodeBoolForKey: @"NSEnabled"]];
	}
    }
  else 
    {
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_tag];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_cell];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_ignoresMultiClick];
    }

  return self;
}

@end
