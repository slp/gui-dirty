/* 
   NSMenuView.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Michael Hanni <mhanni@sprintmail.com>
   Date: June 1999
   
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

#ifndef _GNUstep_H_NSMenuView
#define _GNUstep_H_NSMenuView

#include <Foundation/NSCoder.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSException.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSString.h>
#include <Foundation/NSNotification.h>

#include <AppKit/NSColor.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItemCell.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSView.h>
#include <AppKit/NSPopUpButton.h>

@class NSFont;

@interface NSMenuView : NSView
{
  NSMenu *menuv_menu;
  BOOL menuv_horizontal;
  NSFont *menuv_font;
  int menuv_highlightedItemIndex;
  BOOL menuv_isAttached;
  BOOL menuv_isTornOff;
  float menuv_hEdgePad;
  float menuv_stateImageOffset;
  float menuv_stateImageWidth;
  float menuv_imageAndTitleOffset;
  float menuv_imageAndTitleWidth;
  float menuv_keyEqOffset;
  float menuv_keyEqWidth;
  BOOL menuv_needsSizing;
  NSSize cellSize;
@private
  NSPopUpButton *menuv_popb;
  id menuv_items_link;
}
+ (float)menuBarHeight;

- (void)setMenu:(NSMenu *)menu;
- (NSMenu *)menu;
- (void)setHorizontal:(BOOL)flag;
- (BOOL)isHorizontal;
- (void)setFont:(NSFont *)font;
- (NSFont *)font;
- (void)setHighlightedItemIndex:(int)index;
- (int)highlightedItemIndex;
- (void)setMenuItemCell:(NSMenuItemCell *)cell
         forItemAtIndex:(int)index;
- (NSMenuItemCell *)menuItemCellForItemAtIndex:(int)index;
- (NSMenuView *)attachedMenuView;
- (NSMenu *)attachedMenu;
- (BOOL)isAttached;
- (BOOL)isTornOff;
- (void)setHorizontalEdgePadding:(float)pad;
- (float)horizontalEdgePadding;
- (void)itemChanged:(NSNotification *)notification;
- (void)itemAdded:(NSNotification *)notification;
- (void)itemRemoved:(NSNotification *)notification;
- (void)detachSubmenu;
- (void)attachSubmenuForItemAtIndex:(int)index;
- (void)update;
- (void)setNeedsSizing:(BOOL)flag;
- (BOOL)needsSizing;
- (void)sizeToFit;
- (float)stateImageOffset;
- (float)stateImageWidth;
- (float)imageAndTitleOffset;
- (float)imageAndTitleWidth;
- (float)keyEquivalentOffset;
- (float)keyEquivalentWidth;
- (NSRect)innerRect;
- (NSRect)rectOfItemAtIndex:(int)index;
- (int)indexOfItemAtPoint:(NSPoint)point;
- (void)setNeedsDisplayForItemAtIndex:(int)index;
- (NSPoint)locationForSubmenu:(NSMenu *)aSubmenu;
- (void)resizeWindowWithMaxHeight:(float)maxHeight;
- (void)setWindowFrameForAttachingToRect:(NSRect)screenRect
                                onScreen:(NSScreen *)screen
                           preferredEdge:(NSRectEdge)edge
                       popUpSelectedItem:(int)selectedItemIndex;
- (void)performActionWithHighlightingForItemAtIndex:(int)index;
- (BOOL)trackWithEvent:(NSEvent *)event;
@end

@interface NSMenuView (Private)
- (id) initWithFrame: (NSRect)aFrame
            cellSize: (NSSize)aSize;
- (void) setPopUpButton: (NSPopUpButton *)popb;
- (NSPopUpButton *) popupButton;
@end

#endif
