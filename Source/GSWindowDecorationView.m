/** <title>GSWindowDecorationView</title>

   Copyright (C) 2004 Free Software Foundation, Inc.

   Author: Alexander Malmberg <alexander@malmberg.org>
   Date: 2004-03-24

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; see the file COPYING.LIB.
   If not, see <http://www.gnu.org/licenses/> or write to the 
   Free Software Foundation, 51 Franklin Street, Fifth Floor, 
   Boston, MA 02110-1301, USA.
*/

#import <Foundation/NSEnumerator.h>
#import <Foundation/NSException.h>

#import <GNUstepGUI/GSWindowDecorationView.h>
#import "AppKit/NSColor.h"
#import "AppKit/NSGraphics.h"
#import "AppKit/NSMenuView.h"
#import "AppKit/NSWindow.h"
#import "GNUstepGUI/GSDisplayServer.h"
#import "GNUstepGUI/GSTheme.h"

#import "NSToolbarFrameworkPrivate.h"

@implementation GSWindowDecorationView

+ (id<GSWindowDecorator>) windowDecorator
{
  if ([GSCurrentServer() handlesWindowDecorations])
    return [GSBackendWindowDecorationView self];
  else
    return [GSStandardWindowDecorationView self];
}


+ (id) newWindowDecorationViewWithFrame: (NSRect)frame
				 window: (NSWindow *)aWindow
{
  return [[self alloc] initWithFrame: frame
			      window: aWindow];
}


+ (void) offsets: (float *)l : (float *)r : (float *)t : (float *)b
    forStyleMask: (unsigned int)style
{
  [self subclassResponsibility: _cmd];
}

+ (NSRect) contentRectForFrameRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle
{
  float t = 0.0, b = 0.0, l = 0.0, r = 0.0;

  [self offsets: &l : &r : &t : &b forStyleMask: aStyle];
  aRect.size.width -= l + r;
  aRect.size.height -= t + b;
  aRect.origin.x += l;
  aRect.origin.y += b;
  return aRect;
}

+ (NSRect) frameRectForContentRect: (NSRect)aRect
			 styleMask: (unsigned int)aStyle
{
  float t = 0.0, b = 0.0, l = 0.0, r = 0.0;

  [self offsets: &l : &r : &t : &b forStyleMask: aStyle];
  aRect.size.width += l + r;
  aRect.size.height += t + b;
  aRect.origin.x -= l;
  aRect.origin.y -= b;
  return aRect;
}

+ (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle
{
  [self subclassResponsibility: _cmd];
  return 0.0;
}


- (id) initWithFrame: (NSRect)frame
{
  NSAssert(NO, @"Tried to create GSWindowDecorationView without a window!");
  return nil;
}

- (id) initWithFrame: (NSRect)frame
	      window: (NSWindow *)w
{
  self = [super initWithFrame: frame];
  if (self != nil)
    {
      hasToolbar = NO;
      hasMenu = NO;
      window = w;
      // Content rect will be everything apart from the border
      // that is including menu, toolbar and the like.
      contentRect = [isa contentRectForFrameRect: frame
                          styleMask: [w styleMask]];
    }
  return self;
}

- (void) setHasMenu: (BOOL) flag
{
  hasMenu = flag;
}

- (BOOL) hasMenu
{
  return hasMenu;
}

- (void) setHasToolbar: (BOOL) flag
{
  hasToolbar = flag;
}

- (BOOL) hasToolbar
{
  return hasToolbar;
}

- (NSRect) contentRectForFrameRect: (NSRect)aRect
                         styleMask: (unsigned int)aStyle
{
  NSRect content = [isa contentRectForFrameRect: aRect
                          styleMask: aStyle];
  NSToolbar *tb = [_window toolbar];

  if ([_window menu] != nil)
    {
      float	menubarHeight = [[GSTheme theme] 
					 menuHeightForWindow: 
				    _window];
  
      content.size.height -= menubarHeight;
    }

  if ([tb isVisible])
    {
      GSToolbarView *tv = [tb _toolbarView];

      content.size.height -= [tv _heightFromLayout];
    }

  return content;
}

- (NSRect) frameRectForContentRect: (NSRect)aRect
                         styleMask: (unsigned int)aStyle
{
  NSToolbar *tb = [_window toolbar];

  if ([_window menu] != nil)
    {
      float	menubarHeight = [[GSTheme theme] 
				  menuHeightForWindow: 
				    _window];

      aRect.size.height += menubarHeight;
    }

  if ([tb isVisible])
    {
      GSToolbarView *tv = [tb _toolbarView];

      aRect.size.height += [tv _heightFromLayout];
    }

  return [isa frameRectForContentRect: aRect
              styleMask: aStyle];
}

/* If the contentView is removed from the window we must make sure the
 * window no longer tries to access it.  This situation may occur, for
 * example, when people create inspectors where they want to swap in
 * and out views.  In the example I saw, a bunch of non-visible
 * windows were created to create the inspector views.  When an
 * inspector view was needed, it was added as a subview in the visible
 * inspector window.  We need to make sure that when 'addSubview:' is
 * called to add the view to another window, all references to it in
 * the old window will automatically disappear (this is how it works
 * on Apple too).
 */
- (void) removeSubview: (NSView*)aView
{
  RETAIN(aView);
  /*
   * If the content view is removed (for example, because it was added
   * to another view in another window), we must let the window know.
   * Otherwise, it would keep trying to resize/manage it as if it was
   * its content view, while it actually is now in another window!
   */
  [super removeSubview: aView];
  if (aView == [_window contentView])
    {
      [_window setContentView: nil];
    }
  RELEASE(aView);
}

- (void) setBackgroundColor: (NSColor *)color
{
  [self setNeedsDisplayInRect: contentRect];
}

- (void) setContentView: (NSView *)contentView
{
  [contentView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [self addSubview: contentView];
  [self layout];
}

- (void) setDocumentEdited: (BOOL)flag
{
  documentEdited = flag;
  if (windowNumber)
    [GSServerForWindow(window) docedited: documentEdited : windowNumber];
}

- (void) layout
{
  // Should resize all subviews
  NSRect contentViewFrame;
  NSToolbar *tb = [_window toolbar];
  NSRect frame = [window frame];
  NSView *windowContentView = [_window contentView];

  frame.origin = NSZeroPoint;
  contentViewFrame = [isa contentRectForFrameRect: frame
                          styleMask: [window styleMask]];

  if (hasMenu)
    {
      NSMenuView *menuView;
      GSTheme *theme = [GSTheme theme];
      float menuBarHeight = [theme menuHeightForWindow: _window];
      
      menuView = [[_window menu] menuRepresentation];
      [menuView setFrame: NSMakeRect(
              contentViewFrame.origin.x,
              NSMaxY(contentViewFrame) - menuBarHeight, 
              contentViewFrame.size.width, 
              menuBarHeight)];
      contentViewFrame.size.height -= menuBarHeight;
    }

  if (hasToolbar)
    {
      GSToolbarView *tv = [tb _toolbarView];
      float newToolbarViewHeight;
	  
      // If the width changed we may need to recalculate the height
      if (contentViewFrame.size.width != [tv frame].size.width)
	{
	  [tv setFrameSize: NSMakeSize(contentViewFrame.size.width, 100)];
	  // Will recalculate the layout
	  [tv _reload];
	}
      newToolbarViewHeight = [tv _heightFromLayout];
      [tv setFrame: NSMakeRect(contentViewFrame.origin.x,
			       NSMaxY(contentViewFrame) - newToolbarViewHeight,
			       contentViewFrame.size.width, 
			       newToolbarViewHeight)];
      contentViewFrame.size.height -= newToolbarViewHeight;
    }

  if ([windowContentView superview] == self)
    {
      [windowContentView setFrame:contentViewFrame];
    }
}

- (void) changeWindowHeight: (float)difference
{
  NSRect orgWindowFrame;
  NSRect windowFrame;
  NSRect windowContentFrame;

  contentRect.size.height += difference;
  windowFrame = [isa frameRectForContentRect: contentRect
                     styleMask: [window styleMask]];

  // Set the local frame without changing the contents view
  windowContentFrame = windowFrame;
  windowContentFrame.origin = NSZeroPoint;
  _autoresizes_subviews = NO;
  [super setFrame: windowContentFrame];
  
  // Keep the top of the window at the same place
  orgWindowFrame = [window frame];
  windowFrame.origin.y = orgWindowFrame.origin.y + orgWindowFrame.size.height - windowFrame.size.height;
  windowFrame.origin.x = orgWindowFrame.origin.x;

  // then resize the window
  [window setFrame: windowFrame display: YES];
  [self layout];
}

/*
 * Special setFrame: implementation - a minimal autoresize mechanism
 */
- (void) setFrame: (NSRect)frameRect
{
  NSSize oldSize = _frame.size;
  NSView *cv = [_window contentView];

  // Wouldn't it be better to rely on the autoresize mechanism?
  _autoresizes_subviews = NO;
  [super setFrame: frameRect];

  contentRect = [isa contentRectForFrameRect: frameRect
                      styleMask: [window styleMask]];

  // Safety Check.
  [cv setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];
  [cv resizeWithOldSuperviewSize: oldSize];

  [self layout];
}

- (void) setInputState: (int)state
{
  inputState = state;
  if (windowNumber)
    [GSServerForWindow(window) setinputstate: inputState : windowNumber];
}

- (void) setTitle: (NSString *)title
{
  if (windowNumber)
    [GSServerForWindow(window) titlewindow: title : windowNumber];
}

- (void) setWindowNumber: (int)theWindowNumber
{
  windowNumber = theWindowNumber;
  if (!windowNumber)
    return;

  [GSServerForWindow(window) titlewindow: [window title] : windowNumber];
  [GSServerForWindow(window) setinputstate: inputState : windowNumber];
  [GSServerForWindow(window) docedited: documentEdited : windowNumber];
}


- (BOOL) isOpaque
{
  return YES;
}

- (void) drawRect: (NSRect)rect
{
  if (NSIntersectsRect(rect, contentRect))
    {
      // Since this is the outermost view, we have to clear the contentRect
      // in case the theme's window background is not opaque.
      NSRectFillUsingOperation(contentRect, NSCompositeClear);  
      [[GSTheme theme] drawWindowBackground: contentRect view: self];
    }
}

- (id) initWithCoder: (NSCoder*)aCoder
{
  NSAssert(NO, @"The top-level window view should never be encoded.");
  return nil;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  NSAssert(NO, @"The top-level window view should never be encoded.");
}

@end

@implementation GSWindowDecorationView (ToolbarPrivate)

- (void) addToolbarView: (GSToolbarView*)toolbarView
{
  float newToolbarViewHeight;
  float contentYOrigin;

  hasToolbar = YES;
  [toolbarView setFrameSize: NSMakeSize(contentRect.size.width, 100)];
  // Will recalculate the layout
  [toolbarView _reload];
  newToolbarViewHeight = [toolbarView _heightFromLayout];

  // take in account of the menubar when calculating the origin
  contentYOrigin = NSMaxY(contentRect);
  if (hasMenu)
    {
      float menuBarHeight = [[GSTheme theme] menuHeightForWindow: _window];
      contentYOrigin -= menuBarHeight;
    }

  // Plug the toolbar view
  [toolbarView setFrame: NSMakeRect(
          contentRect.origin.x,
          contentYOrigin, 
          contentRect.size.width, 
          newToolbarViewHeight)];
  [self addSubview: toolbarView];

  [self changeWindowHeight: newToolbarViewHeight];  
}

- (void) removeToolbarView: (GSToolbarView *)toolbarView
{
  float toolbarViewHeight = [toolbarView frame].size.height;

  // Unplug the toolbar view
  hasToolbar = NO;
  [toolbarView removeFromSuperviewWithoutNeedingDisplay];

  [self changeWindowHeight: -toolbarViewHeight];  
}

- (void) adjustToolbarView: (GSToolbarView *)toolbarView
{
  // Frame and height
  NSRect toolbarViewFrame = [toolbarView frame];
  float toolbarViewHeight = toolbarViewFrame.size.height;
  float newToolbarViewHeight = [toolbarView _heightFromLayout];
  
  if (toolbarViewHeight != newToolbarViewHeight)
    {
      [toolbarView setFrame: NSMakeRect(
              toolbarViewFrame.origin.x,
              toolbarViewFrame.origin.y + (toolbarViewHeight - newToolbarViewHeight),
              toolbarViewFrame.size.width, 
              newToolbarViewHeight)];
          
      [self changeWindowHeight: newToolbarViewHeight - toolbarViewHeight];  
    }
}

@end

@implementation GSWindowDecorationView (Menu)

- (void) addMenuView: (NSMenuView*)menuView
{
  float	menubarHeight = [[GSTheme theme] 
			  menuHeightForWindow: 
			    _window];
  hasMenu = YES;
  // Plug the menu view
  [menuView setFrame: NSMakeRect(
          contentRect.origin.x,
          NSMaxY(contentRect), 
          contentRect.size.width, 
          menubarHeight)];
  [self addSubview: menuView];
  
  [self changeWindowHeight: menubarHeight];  
}

- (NSMenuView*) removeMenuView
{
  NSEnumerator	*e = [[self subviews] objectEnumerator];
  NSView	*v;
  float	menubarHeight = [[GSTheme theme] 
			  menuHeightForWindow: 
			    _window];
  
  while ((v = [e nextObject]) != nil)
    {
      if ([v isKindOfClass: [NSMenuView class]] == YES)
	{
	  /* Unplug the menu view and return it so that it can be
	   * restored to its original menu if necessary.
	   */

	  hasMenu = NO;
	  [RETAIN(v) removeFromSuperviewWithoutNeedingDisplay];
	  
	  [self changeWindowHeight: -(menubarHeight)];  
	  return AUTORELEASE(v);
	}
    }

  return nil;
}

@end


@implementation GSBackendWindowDecorationView

+ (void) offsets: (float *)l : (float *)r : (float *)t : (float *)b
    forStyleMask: (unsigned int)style
{
  [GSCurrentServer() styleoffsets: l : r : t : b : style];
}

+ (float) minFrameWidthWithTitle: (NSString *)aTitle
		       styleMask: (unsigned int)aStyle
{
  /* TODO: we could at least guess... */
  return 0.0;
}

@end

