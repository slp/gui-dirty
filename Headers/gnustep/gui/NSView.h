/* 
   NSView.h

   The wonderful view class; it encapsulates all drawing functionality

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

#ifndef _GNUstep_H_NSView
#define _GNUstep_H_NSView

#include <AppKit/stdappkit.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSImage.h>
#include <Foundation/NSArray.h>
#include <AppKit/TrackingRectangle.h>
#include <AppKit/NSCursor.h>
#include <Foundation/NSCoder.h>

@class NSWindow;
@class NSClipView;

@interface NSView : NSResponder <NSCoding>

{
  // Attributes
  NSRect frame;
  NSRect bounds;
  float frame_rotation;

  id super_view;
  NSMutableArray *sub_views;
  id window;
  NSMutableArray *tracking_rects;

  BOOL is_flipped;
  BOOL is_rotated_from_base;
  BOOL is_rotated_or_scaled_from_base;
  BOOL opaque;
  BOOL needs_display;
  BOOL disable_autodisplay;
  BOOL post_frame_changes;
  BOOL autoresize_subviews;

  // Reserved for back-end use
  void *be_view_reserved;
}

//
//Initializing NSView Objects 
//
- (id)initWithFrame:(NSRect)frameRect;

//
// Managing the NSView Hierarchy 
//
- (void)addSubview:(NSView *)aView;
- (void)addSubview:(NSView *)aView
	positioned:(NSWindowOrderingMode)place
relativeTo:(NSView *)otherView;
- (NSView *)ancestorSharedWithView:(NSView *)aView;
- (BOOL)isDescendantOf:(NSView *)aView;
- (NSView *)opaqueAncestor;
- (void)removeFromSuperview;
- (void)replaceSubview:(NSView *)oldView
		  with:(NSView *)newView;
- (void)sortSubviewsUsingFunction:(int (*)(id ,id ,void *))compare 
			  context:(void *)context;
- (NSMutableArray *)subviews;
- (NSView *)superview;
- (void)setSuperview:(NSView *)superview;
- (NSWindow *)window;
- (void)viewWillMoveToWindow:(NSWindow *)newWindow;

//
// Modifying the Frame Rectangle 
//
- (float)frameRotation;
- (NSRect)frame;
- (void)rotateByAngle:(float)angle;
- (void)setFrame:(NSRect)frameRect;
- (void)setFrameOrigin:(NSPoint)newOrigin;
- (void)setFrameRotation:(float)angle;
- (void)setFrameSize:(NSSize)newSize;

//
// Modifying the Coordinate System 
//

- (float)boundsRotation;
- (NSRect)bounds;
- (BOOL)isFlipped;
- (BOOL)isRotatedFromBase;
- (BOOL)isRotatedOrScaledFromBase;
- (void)scaleUnitSquareToSize:(NSSize)newSize;
- (void)setBounds:(NSRect)aRect;
- (void)setBoundsOrigin:(NSPoint)newOrigin;
- (void)setBoundsRotation:(float)angle;
- (void)setBoundsSize:(NSSize)newSize;
- (void)translateOriginToPoint:(NSPoint)point;

//
// Converting Coordinates 
//
- (NSRect)centerScanRect:(NSRect)aRect;
- (NSPoint)convertPoint:(NSPoint)aPoint
	       fromView:(NSView *)aView;
- (NSPoint)convertPoint:(NSPoint)aPoint
		 toView:(NSView *)aView;
- (NSRect)convertRect:(NSRect)aRect
	     fromView:(NSView *)aView;
- (NSRect)convertRect:(NSRect)aRect
	       toView:(NSView *)aView;
- (NSSize)convertSize:(NSSize)aSize
	     fromView:(NSView *)aView;
- (NSSize)convertSize:(NSSize)aSize
	       toView:(NSView *)aView;

//
// Notifying Ancestor Views 
//
- (BOOL)postsFrameChangedNotifications;
- (void)setPostsFrameChangedNotifications:(BOOL)flag;

//
// Resizing Subviews 
//
- (void)resizeSubviewsWithOldSize:(NSSize)oldSize;
- (void)setAutoresizesSubviews:(BOOL)flag;
- (BOOL)autoresizesSubviews;
- (void)setAutoresizingMask:(unsigned int)mask;
- (unsigned int)autoresizingMask;
- (void)resizeWithOldSuperviewSize:(NSSize)oldSize;

//
// Graphics State Objects 
//
- (void)allocateGState;
- (void)releaseGState;
- (int)gState;
- (void)renewGState;
- (void)setUpGState;

//
// Focusing 
//
+ (NSView *)focusView;
- (void)lockFocus;
- (void)unlockFocus;

//
// Displaying 
//
- (BOOL)canDraw;
- (void)display;
- (void)displayIfNeeded;
- (void)displayIfNeededIgnoringOpacity;
- (void)displayRect:(NSRect)aRect;
- (void)displayRectIgnoringOpacity:(NSRect)aRect;
- (void)drawRect:(NSRect)rect;
- (NSRect)visibleRect;
- (BOOL)isOpaque;
- (BOOL)needsDisplay;
- (void)setNeedsDisplay:(BOOL)flag;
- (void)setNeedsDisplayInRect:(NSRect)invalidRect;
- (BOOL)shouldDrawColor;

//
// Scrolling 
//
- (NSRect)adjustScroll:(NSRect)newVisible;
- (BOOL)autoscroll:(NSEvent *)theEvent;
- (void)reflectScrolledClipView:(NSClipView *)aClipView;
- (void)scrollClipView:(NSClipView *)aClipView
	       toPoint:(NSPoint)aPoint;
- (void)scrollPoint:(NSPoint)aPoint;
- (void)scrollRect:(NSRect)aRect
		by:(NSSize)delta;
- (BOOL)scrollRectToVisible:(NSRect)aRect;

//
// Managing the Cursor 
//
- (void)addCursorRect:(NSRect)aRect
	       cursor:(NSCursor *)anObject;
- (void)discardCursorRects;
- (void)removeCursorRect:(NSRect)aRect
		  cursor:(NSCursor *)anObject;
- (void)resetCursorRects;

//
// Assigning a Tag 
//
- (int)tag;
- (id)viewWithTag:(int)aTag;

//
// Aiding Event Handling 
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (NSView *)hitTest:(NSPoint)aPoint;
- (BOOL)mouse:(NSPoint)aPoint
       inRect:(NSRect)aRect;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)removeTrackingRect:(NSTrackingRectTag)tag;
- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent;
- (NSTrackingRectTag)addTrackingRect:(NSRect)aRect
			       owner:(id)anObject
userData:(void *)data
			       assumeInside:(BOOL)flag;
- (NSArray *)trackingRectangles;

//
// Dragging 
//
- (BOOL)dragFile:(NSString *)filename
	fromRect:(NSRect)rect
slideBack:(BOOL)slideFlag
	event:(NSEvent *)event;
- (void)dragImage:(NSImage *)anImage
	       at:(NSPoint)viewLocation
offset:(NSSize)initialOffset
	       event:(NSEvent *)event
pasteboard:(NSPasteboard *)pboard
	       source:(id)sourceObject
slideBack:(BOOL)slideFlag;
- (void)registerForDraggedTypes:(NSArray *)newTypes;
- (void)unregisterDraggedTypes;

//
// Printing
//
- (NSData *)dataWithEPSInsideRect:(NSRect)aRect;
- (void)fax:(id)sender;
- (void)print:(id)sender;
- (void)writeEPSInsideRect:(NSRect)rect
	      toPasteboard:(NSPasteboard *)pasteboard;

//
// Pagination 
//
- (void)adjustPageHeightNew:(float *)newBottom
			top:(float)oldTop
bottom:(float)oldBottom
			limit:(float)bottomLimit;
- (void)adjustPageWidthNew:(float *)newRight
		      left:(float)oldLeft
right:(float)oldRight	 
		      limit:(float)rightLimit;
- (float)heightAdjustLimit;
- (BOOL)knowsPagesFirst:(int *)firstPageNum
		   last:(int *)lastPageNum;
- (NSPoint)locationOfPrintRect:(NSRect)aRect;
- (NSRect)rectForPage:(int)page;
- (float)widthAdjustLimit;

//
// Writing Conforming PostScript 
//
- (void)addToPageSetup;
- (void)beginPage:(int)ordinalNum
	    label:(NSString *)aString
bBox:(NSRect)pageRect
	    fonts:(NSString *)fontNames;
- (void)beginPageSetupRect:(NSRect)aRect
		 placement:(NSPoint)location;
- (void)beginPrologueBBox:(NSRect)boundingBox
	     creationDate:(NSString *)dateCreated
createdBy:(NSString *)anApplication
	     fonts:(NSString *)fontNames
forWhom:(NSString *)user
	     pages:(int)numPages
title:(NSString *)aTitle;
- (void)beginSetup;
- (void)beginTrailer;
- (void)drawPageBorderWithSize:(NSSize)borderSize;
- (void)drawSheetBorderWithSize:(NSSize)borderSize;
- (void)endHeaderComments;
- (void)endPrologue;
- (void)endSetup;
- (void)endPageSetup;
- (void)endPage;
- (void)endTrailer;

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSView
