/* 
   NSColorPanel.h

   System generic color panel

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

#ifndef _GNUstep_H_NSColorPanel
#define _GNUstep_H_NSColorPanel

#include <AppKit/stdappkit.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSColorList.h>
#include <Foundation/NSCoder.h>

@interface NSColorPanel : NSPanel <NSCoding>

{
  // Attributes
}

//
// Creating the NSColorPanel 
//
+ (NSColorPanel *)sharedColorPanel;
+ (BOOL)sharedColorPanelExists;

//
// Setting the NSColorPanel 
//
+ (void)setPickerMask:(int)mask;
+ (void)setPickerMode:(int)mode;
- (NSView *)accessoryView;
- (BOOL)isContinuous;
- (int)mode;
- (void)setAccessoryView:(NSView *)aView;
- (void)setAction:(SEL)aSelector;
- (void)setContinuous:(BOOL)flag;
- (void)setMode:(int)mode;
- (void)setShowsAlpha:(BOOL)flag;
- (void)setTarget:(id)anObject;
- (BOOL)showsAlpha;

//
// Attaching a Color List
//
- (void)attachColorList:(NSColorList *)aColorList;
- (void)detachColorList:(NSColorList *)aColorList;

//
// Setting Color
//
+ (BOOL)dragColor:(NSColor **)aColor
	withEvent:(NSEvent *)anEvent
fromView:(NSView *)sourceView;
- (float)alpha;
- (NSColor *)color;
- (void)setColor:(NSColor *)aColor;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSColorPanel
