/* 
   AppKit.h

   Main include file for GNUstep GUI Library

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

#ifndef _GNUstep_H_AppKit
#define _GNUstep_H_AppKit

#include <AppKit/stdappkit.h>

//
// System dependent information
//
float MB_SCREEN_MAXWIDTH();
float MB_SCREEN_MAXHEIGHT();

//
// Display Postscript System
//
#include <DPSClient/DPSOperators.h>

//
// Types and Constants for GNUstep GUI Library
//
#include <AppKit/TypesandConstants.h>

//
// GNUstep GUI Library functions
//
#include <AppKit/Functions.h>

//
// Protocols
//

//
// Classes
//
@class NSWorkspace;
@class NSResponder, NSApplication, NSScreen;
@class NSWindow, NSPanel, NSView, NSMenu;
@class NSSavePanel, NSOpenPanel, NSHelpPanel;
@class NSClipView, NSScrollView, NSSplitView;
@class NSText;
// Controls
@class NSControl, NSButton, NSTextField, NSScroller, NSBox, NSForm, NSMatrix;
@class NSPopUpButton, NSSlider, NSBrowser, NSForm;
// Cells
@class NSCell, NSActionCell, NSButtonCell, NSTextFieldCell, NSFormCell;
@class NSSliderCell, NSMenuCell, NSBrowserCell, NSFormCell;
@class NSEvent, NSCursor;
@class NSColor, NSColorList, NSColorPanel, NSColorPicker, NSColorWell;
@class NSImage, NSImageRep, NSBitmapImageRep, NSCachedImageRep;
@class NSCustomImageRep, NSEPSImageRep;
@class NSDataLink, NSDataLinkManager, NSDataLinkPanel;
@class NSFont, NSFontManager, NSFontPanel;
@class NSPageLayout, NSPrinter, NSPrintInfo, NSPrintOperation, NSPrintPanel;
@class NSPasteboard, NSSelection;
@class NSSpellChecker, NSSpellServer;

#include <AppKit/NSActionCell.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSBitmapImageRep.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSButtonCell.h>
#include <AppKit/NSCachedImageRep.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSClipView.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSColorList.h>
#include <AppKit/NSColorPanel.h>
#include <AppKit/NSColorPicker.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSCustomImageRep.h>
#include <AppKit/NSDataLink.h>
#include <AppKit/NSDataLinkManager.h>
#include <AppKit/NSDataLinkPanel.h>
#include <AppKit/NSEPSImageRep.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSHelpPanel.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSImageRep.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuCell.h>
#include <AppKit/NSOpenPanel.h>
#include <AppKit/NSPageLayout.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPrinter.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPrintOperation.h>
#include <AppKit/NSPrintPanel.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSSelection.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSSpellServer.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSWorkspace.h>

#endif _GNUstep_H_AppKit
