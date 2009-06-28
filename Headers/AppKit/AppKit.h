/* 
   AppKit.h

   Main include file for GNUstep GUI Library

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
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

#ifndef _GNUstep_H_AppKit
#define _GNUstep_H_AppKit
#import <GNUstepBase/GSVersionMacros.h>

/* Define library version */
#include <GNUstepGUI/GSVersion.h>

//
// Foundation
//
#include <Foundation/Foundation.h>

//
// GNUstep GUI Library functions
//
#include <AppKit/NSGraphics.h>

#include <AppKit/NSActionCell.h>
#include <AppKit/NSAnimation.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSAttributedString.h>
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
#include <AppKit/NSColorPicking.h>
#include <AppKit/NSColorWell.h>
#include <AppKit/NSControl.h>
#include <AppKit/NSCursor.h>
#include <AppKit/NSCustomImageRep.h>
#include <AppKit/NSDataLink.h>
#include <AppKit/NSDataLinkManager.h>
#include <AppKit/NSDataLinkPanel.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSEPSImageRep.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSFontManager.h>
#include <AppKit/NSFontPanel.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSFormCell.h>
#include <AppKit/NSHelpPanel.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSImageCell.h>
#include <AppKit/NSImageRep.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSMenu.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenuItemCell.h>
#include <AppKit/NSMenuView.h>
#include <AppKit/NSNibLoading.h>
#include <AppKit/NSOpenPanel.h>
#include <AppKit/NSPageLayout.h>
#include <AppKit/NSPanel.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSPopUpButton.h>
#include <AppKit/NSPopUpButtonCell.h>
#include <AppKit/NSPrinter.h>
#include <AppKit/NSPrintInfo.h>
#include <AppKit/NSPrintOperation.h>
#include <AppKit/NSPrintPanel.h>
#include <AppKit/NSResponder.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSScreen.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSSegmentedCell.h>
#include <AppKit/NSSegmentedControl.h>
#include <AppKit/NSSelection.h>
#include <AppKit/NSSlider.h>
#include <AppKit/NSSliderCell.h>
#include <AppKit/NSSpellChecker.h>
#include <AppKit/NSSpellProtocol.h>
#include <AppKit/NSSplitView.h>
#include <AppKit/NSStringDrawing.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSView.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSWorkspace.h>

#if OS_API_VERSION(GS_API_MACOSX, GS_API_LATEST)
#include <AppKit/NSAlert.h>
#include <AppKit/NSAffineTransform.h>
#include <AppKit/NSArrayController.h>
#include <AppKit/NSBezierPath.h>
#include <AppKit/NSComboBox.h>
#include <AppKit/NSComboBoxCell.h>
#include <AppKit/NSController.h>
#include <AppKit/NSDocument.h>
#include <AppKit/NSDocumentController.h>
#include <AppKit/NSDrawer.h>
#include <AppKit/NSFileWrapper.h>
#include <AppKit/NSFontDescriptor.h>
#include <AppKit/NSGraphicsContext.h>
#include <AppKit/NSHelpManager.h>
#include <AppKit/NSInputManager.h>
#include <AppKit/NSInputServer.h>
#include <AppKit/NSInterfaceStyle.h>
#include <AppKit/NSKeyValueBinding.h>
#include <AppKit/NSLayoutManager.h>
#include <AppKit/NSLevelIndicator.h>
#include <AppKit/NSLevelIndicatorCell.h>
#include <AppKit/NSMovie.h>
#include <AppKit/NSMovieView.h>
#include <AppKit/NSNib.h>
#include <AppKit/NSNibDeclarations.h>
#include <AppKit/NSObjectController.h>
#include <AppKit/NSOpenGL.h>
#include <AppKit/NSOpenGLView.h>
#include <AppKit/NSOutlineView.h>
#include <AppKit/NSParagraphStyle.h>
#include <AppKit/NSProgressIndicator.h>
#include <AppKit/NSRulerMarker.h>
#include <AppKit/NSRulerView.h>
#include <AppKit/NSSearchField.h>
#include <AppKit/NSSearchFieldCell.h>
#include <AppKit/NSSecureTextField.h>
#include <AppKit/NSSound.h>
#include <AppKit/NSSpeechSynthesizer.h>
#include <AppKit/NSStepper.h>
#include <AppKit/NSStepperCell.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSTableHeaderView.h>
#include <AppKit/NSTableView.h>
#include <AppKit/NSTabView.h>
#include <AppKit/NSTabViewItem.h>
#include <AppKit/NSTextAttachment.h>
#include <AppKit/NSTextContainer.h>
#include <AppKit/NSTextList.h>
#include <AppKit/NSTextStorage.h>
#include <AppKit/NSTextTable.h>
#include <AppKit/NSTextView.h>
#include <AppKit/NSToolbar.h>
#include <AppKit/NSToolbarItem.h>
#include <AppKit/NSUserDefaultsController.h>
#include <AppKit/NSUserInterfaceValidation.h>
#include <AppKit/NSWindowController.h>
#endif

#include <AppKit/PSOperators.h>

#endif /* _GNUstep_H_AppKit */
