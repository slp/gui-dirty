/** <title>NSView</title>

   <abstract>Encapsulates all drawing functionality</abstract>

   Copyright <copy>(C) 1996 Free Software Foundation, Inc.</copy>

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Heavily changed and extended by Ovidiu Predescu <ovidiu@net-community.com>.
   Date: 1997
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author: <author name="Various People"></author>
   Date: Oct 2001

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

#ifndef _GNUstep_H_NSView
#define _GNUstep_H_NSView

#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSResponder.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSData;

@class NSWindow;
@class NSPasteboard;
@class NSView;
@class NSClipView;
@class NSImage;
@class NSCursor;
@class NSScrollView;
@class NSMenu;

typedef int NSTrackingRectTag;
typedef int NSToolTipTag;

/*
 * constants representing the four types of borders that
 * can appear around an NSView
 */
typedef enum _NSBorderType {
  NSNoBorder,
  NSLineBorder,
  NSBezelBorder,
  NSGrooveBorder
} NSBorderType;

/*
 * autoresize constants which NSView uses in
 * determining the parts of a view which are
 * resized when the view's superview is resized
 */
enum {
  NSViewNotSizable	= 0,	// view does not resize with its superview
  NSViewMinXMargin	= 1,	// left margin between views can stretch
  NSViewWidthSizable	= 2,	// view's width can stretch
  NSViewMaxXMargin	= 4,	// right margin between views can stretch
  NSViewMinYMargin	= 8,	// bottom margin between views can stretch
  NSViewHeightSizable	= 16,	// view's height can stretch
  NSViewMaxYMargin	= 32 	// top margin between views can stretch
};

@interface NSView : NSResponder
{
  NSRect _frame;
  NSRect _bounds;
  id _frameMatrix;
  id _boundsMatrix;
  id _matrixToWindow;
  id _matrixFromWindow;

  NSView* _super_view;
  NSMutableArray *_sub_views;
  id _window;
  NSMutableArray *_tracking_rects;
  NSMutableArray *_cursor_rects;
  NSRect _invalidRect;
  NSRect _visibleRect;
  unsigned int _autoresizingMask;
  int _gstate;

  BOOL _is_rotated_from_base;
  BOOL _is_rotated_or_scaled_from_base;
  BOOL _post_frame_changes;
  BOOL _post_bounds_changes;
  BOOL _autoresizes_subviews;
  BOOL _coordinates_valid;
  BOOL _allocate_gstate;
  BOOL _renew_gstate;

  NSView *_nextKeyView;
  NSView *_previousKeyView;
}

/*
 * Initializing NSView Objects
 */
- (id) initWithFrame: (NSRect)frameRect;

/*
 * Managing the NSView Hierarchy
 */
- (void) addSubview: (NSView*)aView;
- (void) addSubview: (NSView*)aView
	 positioned: (NSWindowOrderingMode)place
	 relativeTo: (NSView*)otherView;
- (NSView*) ancestorSharedWithView: (NSView*)aView;
- (BOOL) isDescendantOf: (NSView*)aView;
- (NSView*) opaqueAncestor;
- (void) removeFromSuperviewWithoutNeedingDisplay;
- (void) removeFromSuperview;
#ifndef	NO_GNUSTEP
- (void) removeSubview: (NSView*)aView;
#endif
- (void) replaceSubview: (NSView*)oldView
		   with: (NSView*)newView;
- (void) sortSubviewsUsingFunction: (int (*)(id ,id ,void*))compare
			   context: (void*)context;
- (NSArray*) subviews;
- (NSView*) superview;
- (NSWindow*) window;
- (void) viewWillMoveToSuperview: (NSView*)newSuper;
- (void) viewWillMoveToWindow: (NSWindow*)newWindow;
#ifndef STRICT_OPENSTEP
- (void) didAddSubview: (NSView *)subview;
- (void) viewDidMoveToSuperview;
- (void) viewDidMoveToWindow;
- (void) willRemoveSubview: (NSView *)subview;
#endif

/*
 * Assigning a Tag
 */
- (int) tag;
- (id) viewWithTag: (int)aTag;

/*
 * Modifying the Frame Rectangle
 */
- (float) frameRotation;
- (NSRect) frame;
- (void) setFrame: (NSRect)frameRect;
- (void) setFrameOrigin: (NSPoint)newOrigin;
- (void) setFrameRotation: (float)angle;
- (void) setFrameSize: (NSSize)newSize;

/*
 * Modifying the Coordinate System
 */
- (float) boundsRotation;
- (NSRect) bounds;
- (void) setBounds: (NSRect)aRect;
- (void) setBoundsOrigin: (NSPoint)newOrigin;
- (void) setBoundsRotation: (float)angle;
- (void) setBoundsSize: (NSSize)newSize;

- (void) translateOriginToPoint: (NSPoint)point;
- (void) scaleUnitSquareToSize: (NSSize)newSize;
- (void) rotateByAngle: (float)angle;

- (BOOL) isFlipped;
- (BOOL) isRotatedFromBase;
- (BOOL) isRotatedOrScaledFromBase;

/*
 * Converting Coordinates
 */
- (NSRect) centerScanRect: (NSRect)aRect;
- (NSPoint) convertPoint: (NSPoint)aPoint
		fromView: (NSView*)aView;
- (NSPoint) convertPoint: (NSPoint)aPoint
		  toView: (NSView*)aView;
- (NSRect) convertRect: (NSRect)aRect
	      fromView: (NSView*)aView;
- (NSRect) convertRect: (NSRect)aRect
		toView: (NSView*)aView;
- (NSSize) convertSize: (NSSize)aSize
	      fromView: (NSView*)aView;
- (NSSize) convertSize: (NSSize)aSize
		toView: (NSView*)aView;

/*
 * Notifying Ancestor Views
 */
- (void) setPostsFrameChangedNotifications: (BOOL)flag;
- (BOOL) postsFrameChangedNotifications;
- (void) setPostsBoundsChangedNotifications: (BOOL)flag;
- (BOOL) postsBoundsChangedNotifications;

/*
 * Resizing Subviews
 */
- (void) resizeSubviewsWithOldSize: (NSSize)oldSize;
- (void) setAutoresizesSubviews: (BOOL)flag;
- (BOOL) autoresizesSubviews;
- (void) setAutoresizingMask: (unsigned int)mask;
- (unsigned int) autoresizingMask;
- (void) resizeWithOldSuperviewSize: (NSSize)oldSize;

/*
 * Focusing
 */
+ (NSView*) focusView;
- (void) lockFocus;
- (void) unlockFocus;
#ifndef STRICT_OPENSTEP
- (BOOL) lockFocusIfCanDraw;
#endif

/*
 * Displaying
 */
- (void) display;
- (void) displayIfNeeded;
- (void) displayIfNeededIgnoringOpacity;
- (void) displayIfNeededInRect: (NSRect)aRect;
- (void) displayIfNeededInRectIgnoringOpacity: (NSRect)aRect;
- (void) displayRect: (NSRect)aRect;
- (void) displayRectIgnoringOpacity: (NSRect)aRect;
- (BOOL) needsDisplay;
- (void) setNeedsDisplay: (BOOL)flag;
- (void) setNeedsDisplayInRect: (NSRect)invalidRect;
- (BOOL) isOpaque;

- (void) drawRect: (NSRect)rect;
- (NSRect) visibleRect;
- (BOOL) canDraw;
- (BOOL) shouldDrawColor;

/*
 * Graphics State Objects
 */
- (void) allocateGState;
- (void) releaseGState;
- (int) gState;
- (void) renewGState;
- (void) setUpGState;

- (BOOL) acceptsFirstMouse: (NSEvent*)theEvent;
- (NSView*) hitTest: (NSPoint)aPoint;
- (BOOL) mouse: (NSPoint)aPoint
	inRect: (NSRect)aRect;
- (BOOL) performKeyEquivalent: (NSEvent*)theEvent;
#ifndef STRICT_OPENSTEP
- (BOOL) performMnemonic: (NSString *)aString;
#endif

/*
 * Dragging
 */
- (BOOL) dragFile: (NSString*)filename
	 fromRect: (NSRect)rect
	slideBack: (BOOL)slideFlag
	    event: (NSEvent*)event;
- (void) dragImage: (NSImage*)anImage
		at: (NSPoint)viewLocation
	    offset: (NSSize)initialOffset
	     event: (NSEvent*)event
	pasteboard: (NSPasteboard*)pboard
	    source: (id)sourceObject
	 slideBack: (BOOL)slideFlag;
- (void) registerForDraggedTypes: (NSArray*)newTypes;
- (void) unregisterDraggedTypes;
- (BOOL) shouldDelayWindowOrderingForEvent: (NSEvent*)anEvent;

/*
 * Managing the Cursor
 */
- (void) addCursorRect: (NSRect)aRect
		cursor: (NSCursor*)anObject;
- (void) discardCursorRects;
- (void) removeCursorRect: (NSRect)aRect
		   cursor: (NSCursor*)anObject;
- (void) resetCursorRects;

#ifndef STRICT_OPENSTEP
/*
 * Tool Tips
 */
- (NSToolTipTag) addToolTipRect: (NSRect)aRect 
			  owner: (id)anObject 
		       userData: (void *)data;
- (void) removeAllToolTips;
- (void) removeToolTip: (NSToolTipTag)tag;
- (void) setToolTip: (NSString *)string;
- (NSString *) toolTip;
#endif

/*
 * Tracking rectangles
 */
- (void) removeTrackingRect: (NSTrackingRectTag)tag;
- (NSTrackingRectTag) addTrackingRect: (NSRect)aRect
				owner: (id)anObject
			     userData: (void*)data
			 assumeInside: (BOOL)flag;

/*
 * Scrolling
 */
- (NSRect) adjustScroll: (NSRect)newVisible;
- (BOOL) autoscroll: (NSEvent*)theEvent;
- (NSScrollView*) enclosingScrollView;
- (void) scrollPoint: (NSPoint)aPoint;
- (void) scrollRect: (NSRect)aRect
		 by: (NSSize)delta;
- (BOOL) scrollRectToVisible: (NSRect)aRect;

- (void) reflectScrolledClipView: (NSClipView*)aClipView;
- (void) scrollClipView: (NSClipView*)aClipView
		toPoint: (NSPoint)aPoint;

#ifndef STRICT_OPENSTEP
/*
 * Menu operations
 */
+ (NSMenu *) defaultMenu;
- (NSMenu *) menuForEvent: (NSEvent *)theEvent;
#endif

/*
 * Aiding Event Handling
 */
- (void) setNextKeyView: (NSView*)aView;
- (NSView*) nextKeyView;
- (NSView*) nextValidKeyView;
- (void) setPreviousKeyView: (NSView*)aView;
- (NSView*) previousKeyView;
- (NSView*) previousValidKeyView;

/*
 * Printing
 */
- (void) fax: (id)sender;
- (void) print: (id)sender;
- (NSData*) dataWithEPSInsideRect: (NSRect)aRect;
- (void) writeEPSInsideRect: (NSRect)rect
	       toPasteboard: (NSPasteboard*)pasteboard;
#ifndef STRICT_OPENSTEP
- (NSData *)dataWithPDFInsideRect:(NSRect)aRect;
- (void)writePDFInsideRect:(NSRect)aRect 
	      toPasteboard:(NSPasteboard *)pboard;
- (NSString *)printJobTitle;
#endif

/*
 * Pagination
 */
- (void) adjustPageHeightNew: (float*)newBottom
			 top: (float)oldTop
		      bottom: (float)oldBottom
		       limit: (float)bottomLimit;
- (void) adjustPageWidthNew: (float*)newRight
		       left: (float)oldLeft
		      right: (float)oldRight
		      limit: (float)rightLimit;
- (float) heightAdjustLimit;
- (BOOL) knowsPagesFirst: (int*)firstPageNum
		    last: (int*)lastPageNum;
#ifndef STRICT_OPENSTEP
- (BOOL) knowsPageRange: (NSRange*)range;
#endif
- (NSPoint) locationOfPrintRect: (NSRect)aRect;
- (NSRect) rectForPage: (int)page;
- (float) widthAdjustLimit;

/*
 * Writing Conforming PostScript
 */
- (void) addToPageSetup;
- (void) beginPage: (int)ordinalNum
	     label: (NSString*)aString
	      bBox: (NSRect)pageRect
	     fonts: (NSString*)fontNames;
- (void) beginPageSetupRect: (NSRect)aRect
		  placement: (NSPoint)location;
- (void) beginPrologueBBox: (NSRect)boundingBox
	      creationDate: (NSString*)dateCreated
		 createdBy: (NSString*)anApplication
		     fonts: (NSString*)fontNames
		   forWhom: (NSString*)user
		     pages: (int)numPages
		     title: (NSString*)aTitle;
- (void) beginSetup;
- (void) beginTrailer;
- (void) drawPageBorderWithSize: (NSSize)borderSize;
- (void) drawSheetBorderWithSize: (NSSize)borderSize;
- (void) endHeaderComments;
- (void) endPrologue;
- (void) endSetup;
- (void) endPageSetup;
- (void) endPage;
- (void) endTrailer;
#ifndef STRICT_OPENSTEP
- (void)beginDocument;
- (void)beginPageInRect:(NSRect)aRect 
	    atPlacement:(NSPoint)location;
- (void)endDocument;
#endif

@end


@class NSAffineTransform;

/*
 * GNUstep extensions
 * Methods whose names begin with an underscore must NOT be overridden.
 */
#ifndef	NO_GNUSTEP
@interface NSView (PrivateMethods)

/*
 * The [-_invalidateCoordinates] method marks the cached visible rectangles
 * of the view and it's subview as being invalid.  NSViews methods call this
 * whenever the coordinate system of the view is changed in any way - thus
 * forcing recalculation of cached values next time they are needed.
 */
- (void) _invalidateCoordinates;
- (void) _rebuildCoordinates;

- (NSAffineTransform*) _matrixToWindow;
- (NSAffineTransform*) _matrixFromWindow;
@end
#endif

/*
 * GNUstep specific function to determine the drag types registered for a view.
 */
APPKIT_EXPORT NSArray *GSGetDragTypes(NSView* aView);

/* Notifications */
APPKIT_EXPORT NSString *NSViewFrameDidChangeNotification;
APPKIT_EXPORT NSString *NSViewBoundsDidChangeNotification;
APPKIT_EXPORT NSString *NSViewFocusDidChangeNotification;

#endif // _GNUstep_H_NSView
