/* 
   NSSplitView.h

   Allows multiple views to share a region in a window

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Robert Vasvari <vrobi@ddrummer.com>
   Date: Jul 1998
   
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

#ifndef _GNUstep_H_NSSplitView
#define _GNUstep_H_NSSplitView

#import <AppKit/NSView.h>

@class NSImage, NSColor, NSNotification;

@interface NSSplitView : NSView
{
  id	delegate;
  int dividerWidth, draggedBarWidth;
  id splitCursor;
  BOOL isVertical;
  NSImage *dimpleImage;
  NSColor *backgroundColor, *dividerColor;
}

- (void) setDelegate: (id)anObject;
- (id) delegate;
- (void) adjustSubviews;
- (void) drawDividerInRect: (NSRect)aRect;

- (void) setVertical: (BOOL)flag;	/* Vertical splitview has a vertical split bar */ 
- (BOOL) isVertical;

/* extra methods to make it more usable */
- (float) dividerThickness;  //defaults to 8
- (void) setDividerThickNess: (float)newWidth;
- (float) draggedBarWidth;
- (void) setDraggedBarWidth: (float)newWidth;
/* if flag is yes, dividerThickness is reset to the height/width of the dimple
   image + 1;
*/
- (void) setDimpleImage: (NSImage *)anImage resetDividerThickness: (BOOL)flag;
- (NSImage *) dimpleImage;
- (NSColor *) backgroundColor;
- (void) setBackgroundColor: (NSColor *)aColor;
- (NSColor *) dividerColor;
- (void) seDividerColor: (NSColor *)aColor;

@end

@interface NSObject(NSSplitViewDelegate)
- (void) splitView: (NSSplitView *)sender resizeSubviewsWithOldSize: (NSSize)oldSize;
- (void) splitView: (NSSplitView *)sender constrainMinCoordinate: (float *)min maxCoordinate: (float *)max ofSubviewAt: (int)offset;
- (void) splitViewWillResizeSubviews: (NSNotification *)notification;
- (void) splitViewDidResizeSubviews: (NSNotification *)notification;
@end

/* Notifications */
extern NSString *NSSplitViewDidResizeSubviewsNotification;
extern NSString *NSSplitViewWillResizeSubviewsNotification;

#endif
