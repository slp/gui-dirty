/* 
   GNUAlertPanel.m

   GNUAlertPanel window class

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1998
   
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
#include <AppKit/NSApplication.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSScreen.h>
#include <AppKit/IMLoading.h>
#include <extensions/GMArchiver.h>

#define	PANX	362.0
#define	PANY	191.0

@class	GNUAlertPanel;

static GNUAlertPanel	*standardAlertPanel = nil;
static GNUAlertPanel	*reusableAlertPanel = nil;

@interface	GNUAlertPanel : NSPanel
{
  NSButton	*defButton;
  NSButton	*altButton;
  NSButton	*othButton;
  NSButton	*icoButton;
  NSTextField	*messageField;
  NSTextField	*titleField;
  int		result;
  BOOL		active;
}
- (void) buttonAction: (id)sender;
- (int) result;
- (int) runModal;
- (void) setTitle: (NSString*)title
	  message: (NSString*)message
	      def: (NSString*)defaultButton
	      alt: (NSString*)alternateButton
	    other: (NSString*)otherButton;
@end

@implementation	GNUAlertPanel
- (void) buttonAction: (id)sender
{
  if (active == NO)
    {
      NSLog(@"alert panel buttonAction: when not in modal loop\n");
      return;
    }
  else if (sender == defButton)
    {
      result = NSAlertDefaultReturn;
    }
  else if (sender == altButton)
    {
      result = NSAlertAlternateReturn;
    }
  else if (sender == othButton)
    {
      result = NSAlertOtherReturn;
    }
  else
    {
      NSLog(@"alert panel buttonAction: from unknown sender - x%x\n",
		(unsigned)sender);
    }
  active = NO;
  [self orderOut: self];
  [[NSApplication sharedApplication] stopModal];
}

- (void) dealloc
{
  [defButton release];
  [altButton release];
  [othButton release];
  [icoButton release];
  [messageField release];
  [titleField release];
  [super dealloc];
}

- (void) encodeWithModelArchiver: (GMArchiver *)archiver
{
  if (standardAlertPanel)
    [archiver encodeObject: standardAlertPanel withName: @"AlertPanel"];
}

- (id) initWithContentRect: (NSRect)r
		 styleMask: (unsigned)m
		   backing: (NSBackingStoreType)b
		     defer: (BOOL)d
		    screen: (NSScreen*)s
{
  self = [super initWithContentRect: r
			  styleMask: m
			    backing: b
			      defer: d
			     screen: s];
  if (self)
    {
      NSView	*content;
      unsigned	bs = 8.0;		/* Inter-button space	*/
      unsigned	bh = 24.0;		/* Button height.	*/
      unsigned	bw = 72.0;		/* Button width.	*/
      NSRect	rect;
      NSBox	*box;

      [self setMaxSize: r.size];
      [self setMinSize: r.size];
      [self setTitle: @" "];

      content = [self contentView]; 

      rect.size.height = 2.0;
      rect.size.width = 362.0;
      rect.origin.y = 95.0;
      rect.origin.x = 0.0;
      box = [[NSBox alloc] initWithFrame: rect];
      [box setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [box setTitlePosition: NSNoTitle];
      [box setBorderType: NSGrooveBorder];
      [content addSubview: box];
      [box release];

      rect.size.height = bh;
      rect.size.width = bw;
      rect.origin.y = bs;
      rect.origin.x = 280.0;
      defButton = [[NSButton alloc] initWithFrame: rect];
      [defButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
      [defButton setButtonType: NSMomentaryPushButton];
      [defButton setTitle: @"Default"];
      [defButton setTarget: self];
      [defButton setAction: @selector(buttonAction:)];
      [defButton setFont: [NSFont systemFontOfSize: 12.0]];
      [defButton setKeyEquivalent: @"\r"];
      [defButton setImagePosition: NSImageRight];
      [defButton setImage: [NSImage imageNamed: @"common_ret"]];

      rect.origin.x = 199.0;
      altButton = [[NSButton alloc] initWithFrame: rect];
      [altButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
      [altButton setButtonType: NSMomentaryPushButton];
      [altButton setTitle: @"Alternative"];
      [altButton setTarget: self];
      [altButton setAction: @selector(buttonAction:)];
      [altButton setFont: [NSFont systemFontOfSize: 12.0]];

      rect.origin.x = 120.0;
      othButton = [[NSButton alloc] initWithFrame: rect];
      [othButton setAutoresizingMask: NSViewMinXMargin | NSViewMaxYMargin];
      [othButton setButtonType: NSMomentaryPushButton];
      [othButton setTitle: @"Other"];
      [othButton setTarget: self];
      [othButton setAction: @selector(buttonAction:)];
      [othButton setFont: [NSFont systemFontOfSize: 12.0]];

      rect.size.height = 48.0;
      rect.size.width = 48.0;
      rect.origin.y = 105.0;
      rect.origin.x = 8.0;
      icoButton = [[NSButton alloc] initWithFrame: rect];
      [icoButton setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin];
      [icoButton setBordered: NO];
      [icoButton setEnabled: NO];
      [icoButton setImagePosition: NSImageOnly];
      [icoButton setImage:
	[[NSApplication sharedApplication] applicationIconImage]];

      rect.size.height = 36.0;
      rect.size.width = 344.0;
      rect.origin.y = 46.0;
      rect.origin.x = 8.0;
      messageField = [[NSTextField alloc] initWithFrame: rect];
      [messageField setAutoresizingMask:
		NSViewWidthSizable | NSViewHeightSizable | NSViewMaxYMargin];
      [messageField setEditable: NO];
      [messageField setSelectable: NO];
      [messageField setBordered: NO];
      [messageField setDrawsBackground: NO];
      [messageField setStringValue: @""];
      [messageField setFont: [NSFont systemFontOfSize: 14.0]];

      rect.size.height = 21.0;
      rect.size.width = 289.0;
      rect.origin.y = 121.0;
      rect.origin.x = 64.0;
      titleField = [[NSTextField alloc] initWithFrame: rect];
      [titleField setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin];
      [titleField setEditable: NO];
      [titleField setSelectable: NO];
      [titleField setBordered: NO];
      [titleField setDrawsBackground: NO];
      [titleField setStringValue: @""];
      [titleField setFont: [NSFont systemFontOfSize: 18.0]];

    }
  return self;
}

- (id) initWithModelUnarchiver: (GMUnarchiver*)unarchiver
{
  if (!standardAlertPanel)
    standardAlertPanel = [unarchiver decodeObjectWithName: @"AlertPanel"];
  [self release];
  return standardAlertPanel;
}

- (int) result
{
  return result;
}

- (int) runModal
{
  NSApplication	*app;

  app = [NSApplication sharedApplication];
  active = YES;
  [app runModalForWindow: self];
  return result;
}

- (void) setTitle: (NSString*)title
	  message: (NSString*)message
	      def: (NSString*)defaultButton
	      alt: (NSString*)alternateButton
	    other: (NSString*)otherButton
{
  NSView	*content = [self contentView];

  if (defaultButton)
    {
      [defButton setTitle: defaultButton];
      if ([defButton superview] == nil)
	{
	  [content addSubview: defButton];
	}
    }
  else
    {
      if ([defButton superview] != nil)
	{
	  [defButton removeFromSuperview];
	}
    }

  if (alternateButton)
    {
      [altButton setTitle: alternateButton];
      if ([altButton superview] == nil)
	{
	  [content addSubview: altButton];
	}
    }
  else
    {
      if ([altButton superview] != nil)
	{
	  [altButton removeFromSuperview];
	}
    }

  if (otherButton)
    {
      [othButton setTitle: otherButton];
      if ([othButton superview] == nil)
	{
	  [content addSubview: othButton];
	}
    }
  else
    {
      if ([othButton superview] != nil)
	{
	  [othButton removeFromSuperview];
	}
    }

  if (message)
    {
      [messageField setStringValue: message];
      if ([messageField superview] == nil)
	{
	  [content addSubview: messageField];
	}
    }
  else
    {
      if ([messageField superview] != nil)
	{
	  [messageField removeFromSuperview];
	}
    }

  if (title)
    {
      [titleField setStringValue: title];
      if ([titleField superview] == nil)
	{
	  [content addSubview: titleField];
	}
    }
  else
    {
      if ([titleField superview] != nil)
	{
	  [titleField removeFromSuperview];
	}
    }

  result = NSAlertErrorReturn;	/* If no button was pressed	*/
  [content display];
  
//  [self notImplemented: _cmd];
}
@end

id
NSGetAlertPanel(NSString *title,
		NSString *msg,
		NSString *defaultButton,
		NSString *alternateButton,
		NSString *otherButton, ...)
{
  va_list	ap;
  NSString	*message;
  GNUAlertPanel	*panel;

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (title == nil)
    title = @"Alert";

  if (standardAlertPanel == nil)
    {
#if 0
      if (![GMModel loadIMFile: @"AlertPanel" owner: [GNUAlertPanel alloc]])
	{
	  NSLog(@"cannot open alert panel model file\n");
	  return nil;
        }
#else
      NSRect	frame = [[NSScreen mainScreen] frame];

      /*
       *	Center the panel in the screen.
       */
      if (frame.size.width > PANX)
	frame.origin.x += (frame.size.width - PANX)/2.0;
      frame.size.width = PANX;

      if (frame.size.height > PANY)
	frame.origin.y += (frame.size.height - PANY)/2.0;
      frame.size.height = PANY;

      panel = [GNUAlertPanel alloc];
      panel = [panel initWithContentRect: frame
			       styleMask: 0
				 backing: NSBackingStoreRetained
				   defer: YES
				  screen: nil];
#endif
    }
  else
    {
      panel = standardAlertPanel;
      standardAlertPanel = nil;
    }
  [panel setTitle: title
	  message: message
	      def: defaultButton
	      alt: alternateButton
	    other: otherButton];

  return panel;
}

id
NSGetCriticalAlertPanel(NSString *title,
			NSString *msg,
			NSString *defaultButton,
			NSString *alternateButton,
			NSString *otherButton, ...)
{
  va_list	ap;
  NSPanel	*panel;

  if (title == nil)
    title = @"Warning";
  va_start (ap, otherButton);
  panel = NSGetAlertPanel(title, msg, defaultButton,
			alternateButton, otherButton, ap);
  va_end (ap);

  return [panel retain];
}

id
NSGetInformationalAlertPanel(NSString *title,
			     NSString *msg,
			     NSString *defaultButton,
			     NSString *alternateButton,
			     NSString *otherButton, ...)
{
  va_list	ap;
  NSPanel	*panel;

  if (title == nil)
    title = @"Information";
  va_start (ap, otherButton);
  panel = NSGetAlertPanel(title, msg, defaultButton,
			alternateButton, otherButton, ap);
  va_end (ap);

  return [panel retain];
}

void
NSReleaseAlertPanel(id alertPanel)
{
  [alertPanel release];
}

int
NSRunAlertPanel(NSString *title,
		NSString *msg,
		NSString *defaultButton,
		NSString *alternateButton,
		NSString *otherButton, ...)
{
  va_list	ap;
  GNUAlertPanel	*panel;
  NSString	*message;
  int		result;

  if (title == nil)
    title = @"Alert";
  if (defaultButton == nil)
    defaultButton = @"OK";

  va_start (ap, otherButton);
  message = [NSString stringWithFormat: msg arguments: ap];
  va_end (ap);

  if (reusableAlertPanel)
    {
      panel = reusableAlertPanel;
      reusableAlertPanel = nil;
      [panel setTitle: title
	      message: message
		  def: defaultButton
		  alt: alternateButton
		other: otherButton];
    }
  else
    {
      panel = NSGetAlertPanel(title, message, defaultButton,
			alternateButton, otherButton, ap);
    }

  result = [panel runModal];

  if (reusableAlertPanel == nil)
    reusableAlertPanel = panel;
  else
    NSReleaseAlertPanel(panel);

  return result;
}

