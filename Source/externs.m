/*
   externs.m

   External data

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: August 1997

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

#include "gnustep/gui/config.h"
#include <Foundation/NSString.h>
#include "AppKit/NSEvent.h"

// Global strings
NSString *NSModalPanelRunLoopMode = @"ModalPanelMode";
NSString *NSEventTrackingRunLoopMode = @"EventTrackingMode";

//
// Global Exception Strings
//
NSString *NSAbortModalException = @"AbortModal";
NSString *NSAbortPrintingException = @"AbortPrinting";
NSString *NSAppKitIgnoredException = @"AppKitIgnored";
NSString *NSAppKitVirtualMemoryException = @"AppKitVirtualMemory";
NSString *NSBadBitmapParametersException = @"BadBitmapParameters";
NSString *NSBadComparisonException = @"BadComparison";
NSString *NSBadRTFColorTableException = @"BadRTFColorTable";
NSString *NSBadRTFDirectiveException = @"BadRTFDirective";
NSString *NSBadRTFFontTableException = @"BadRTFFontTable";
NSString *NSBadRTFStyleSheetException = @"BadRTFStyleSheet";
NSString *NSBrowserIllegalDelegateException = @"BrowserIllegalDelegate";
NSString *NSColorListIOException = @"ColorListIO";
NSString *NSColorListNotEditableException = @"ColorListNotEditable";
NSString *NSDraggingException = @"Draggin";
NSString *NSFontUnavailableException = @"FontUnavailable";
NSString *NSIllegalSelectorException = @"IllegalSelector";
NSString *NSImageCacheException = @"ImageCache";
NSString *NSNibLoadingException = @"NibLoading";
NSString *NSPPDIncludeNotFoundException = @"PPDIncludeNotFound";
NSString *NSPPDIncludeStackOverflowException = @"PPDIncludeStackOverflow";
NSString *NSPPDIncludeStackUnderflowException = @"PPDIncludeStackUnderflow";
NSString *NSPPDParseException = @"PPDParse";
NSString *NSPrintOperationExistsException = @"PrintOperationExists";
NSString *NSPrintPackageException = @"PrintPackage";
NSString *NSPrintingCommunicationException = @"PrintingCommunication";
NSString *NSRTFPropertyStackOverflowException = @"RTFPropertyStackOverflow";
NSString *NSTIFFException = @"TIFF";
NSString *NSTextLineTooLongException = @"TextLineTooLong";
NSString *NSTextNoSelectionException = @"TextNoSelection";
NSString *NSTextReadException = @"TextRead";
NSString *NSTextWriteException = @"TextWrite";
NSString *NSTypedStreamVersionException = @"TypedStreamVersion";
NSString *NSWindowServerCommunicationException = @"WindowServerCommunication";
NSString *NSWordTablesReadException = @"WordTablesRead";
NSString *NSWordTablesWriteException = @"WordTablesWrite";

NSString *GSWindowServerInternalException = @"WindowServerInternal";

// Application notifications
NSString *NSApplicationDidBecomeActiveNotification
              = @"ApplicationDidBecomeActive";
NSString *NSApplicationDidFinishLaunchingNotification
              = @"ApplicationDidFinishLaunching";
NSString *NSApplicationDidHideNotification = @"ApplicationDidHide";
NSString *NSApplicationDidResignActiveNotification
              = @"ApplicationDidResignActive";
NSString *NSApplicationDidUnhideNotification = @"ApplicationDidUnhide";
NSString *NSApplicationDidUpdateNotification = @"ApplicationDidUpdate";
NSString *NSApplicationWillBecomeActiveNotification
              = @"ApplicationWillBecomeActive";
NSString *NSApplicationWillFinishLaunchingNotification
              = @"ApplicationWillFinishLaunching";
NSString *NSApplicationWillTerminateNotification = @"ApplicationWillTerminate";
NSString *NSApplicationWillHideNotification = @"ApplicationWillHide";
NSString *NSApplicationWillResignActiveNotification
              = @"ApplicationWillResignActive";
NSString *NSApplicationWillUnhideNotification = @"ApplicationWillUnhide";
NSString *NSApplicationWillUpdateNotification = @"ApplicationWillUpdate";

// NSColor Global strings
NSString *NSCalibratedWhiteColorSpace = @"NSCalibratedWhiteColorSpace";
NSString *NSCalibratedBlackColorSpace = @"NSCalibratedBlackColorSpace";
NSString *NSCalibratedRGBColorSpace = @"NSCalibratedRGBColorSpace";
NSString *NSDeviceWhiteColorSpace = @"NSDeviceWhiteColorSpace";
NSString *NSDeviceBlackColorSpace = @"NSDeviceBlackColorSpace";
NSString *NSDeviceRGBColorSpace = @"NSDeviceRGBColorSpace";
NSString *NSDeviceCMYKColorSpace = @"NSDeviceCMYKColorSpace";
NSString *NSNamedColorSpace = @"NSNamedColorSpace";
NSString *NSPatternColorSpace = @"NSPatternColorSpace";
NSString *NSCustomColorSpace = @"NSCustomColorSpace";

// NSColor Global gray values
const float NSBlack = 0;
const float NSDarkGray = .333;
const float NSGray = 0.5;
const float NSLightGray = .667;
const float NSWhite = 1;

// NSColor notification
NSString *NSSystemColorsDidChangeNotification =
            @"NSSystemColorsDidChangeNotification";

// NSColorList notifications
NSString *NSColorListChangedNotification = @"NSColorListChange";

// NSColorPanel notifications
NSString *NSColorPanelColorChangedNotification =
@"NSColorPanelColorChangedNotification";

// NSComboBox notifications
NSString *NSComboBoxWillPopUpNotification = 
@"NSComboBoxWillPopUpNotification";
NSString *NSComboBoxWillDismissNotification = 
@"NSComboBoxWillDismissNotification";
NSString *NSComboBoxSelectionDidChangeNotification = 
@"NSComboBoxSelectionDidChangeNotification";
NSString *NSComboBoxSelectionIsChangingNotification = 
@"NSComboBoxSelectionIsChangingNotification";

// NSControl notifications
NSString *NSControlTextDidBeginEditingNotification =
@"NSControlTextDidBeginEditingNotification";
NSString *NSControlTextDidEndEditingNotification =
@"NSControlTextDidEndEditingNotification";
NSString *NSControlTextDidChangeNotification =
@"NSControlTextDidChangeNotification";

// NSDataLink global strings
NSString *NSDataLinkFileNameExtension = @"dlf";

// NSDrawer notifications
NSString *NSDrawerDidCloseNotification =
@"NSDrawerDidCloseNotification";
NSString *NSDrawerDidOpenNotification =
@"NSDrawerDidOpenNotification";
NSString *NSDrawerWillCloseNotification =
@"NSDrawerWillCloseNotification";
NSString *NSDrawerWillOpenNotification =
@"NSDrawerWillOpenNotification";

// NSForm private notification
NSString *_NSFormCellDidChangeTitleWidthNotification 
= @"_NSFormCellDidChangeTitleWidthNotification";

// NSGraphicContext constants
NSString *NSGraphicsContextDestinationAttributeName = 
@"NSGraphicsContextDestinationAttributeName";
NSString *NSGraphicsContextPDFFormat = 
@"NSGraphicsContextPDFFormat";
NSString *NSGraphicsContextPSFormat = 
@"NSGraphicsContextPSFormat";
NSString *NSGraphicsContextRepresentationFormatAttributeName = 
@"NSGraphicsContextRepresentationFormatAttributeName";

NSString *NSImageInterpolationDefault = @"NSImageInterpolationDefault";
NSString *NSImageInterpolationNone = @"NSImageInterpolationNone";
NSString *NSImageInterpolationLow = @"NSImageInterpolationLow";
NSString *NSImageInterpolationHigh = @"NSImageInterpolationHigh";

// NSHelpManager notifications;
NSString *NSContextHelpModeDidActivateNotification =
@"NSContextHelpModeDidActivateNotification";
NSString *NSContextHelpModeDidDeactivateNotification =
@"NSContextHelpModeDidDeactivateNotification";

// NSFont Global Strings
NSString *NSAFMAscender = @"Ascender";
NSString *NSAFMCapHeight = @"CapHeight";
NSString *NSAFMCharacterSet = @"CharacterSet";
NSString *NSAFMDescender = @"Descender";
NSString *NSAFMEncodingScheme = @"EncodingScheme";
NSString *NSAFMFamilyName = @"FamilyName";
NSString *NSAFMFontName = @"FontName";
NSString *NSAFMFormatVersion = @"FormatVersion";
NSString *NSAFMFullName = @"FullName";
NSString *NSAFMItalicAngle = @"ItalicAngle";
NSString *NSAFMMappingScheme = @"MappingScheme";
NSString *NSAFMNotice = @"Notice";
NSString *NSAFMUnderlinePosition = @"UnderlinePosition";
NSString *NSAFMUnderlineThickness = @"UnderlineThickness";
NSString *NSAFMVersion = @"Version";
NSString *NSAFMWeight = @"Weight";
NSString *NSAFMXHeight = @"XHeight";

// NSScreen Global device dictionary key strings
NSString *NSDeviceResolution = @"NSDeviceResolution";
NSString *NSDeviceColorSpaceName = @"NSDeviceColorSpaceName";
NSString *NSDeviceBitsPerSample = @"NSDeviceBitsPerSample";
NSString *NSDeviceIsScreen = @"NSDeviceIsScreen";
NSString *NSDeviceIsPrinter = @"NSDeviceIsPrinter";
NSString *NSDeviceSize = @"NSDeviceSize";

// NSImageRep notifications
NSString *NSImageRepRegistryChangedNotification =
@"NSImageRepRegistryChangedNotification";

// Pasteboard Type Globals
NSString *NSStringPboardType = @"NSStringPboardType";
NSString *NSColorPboardType = @"NSColorPboardType";
NSString *NSFileContentsPboardType = @"NSFileContentsPboardType";
NSString *NSFilenamesPboardType = @"NSFilenamesPboardType";
NSString *NSFontPboardType = @"NSFontPboardType";
NSString *NSRulerPboardType = @"NSRulerPboardType";
NSString *NSPostScriptPboardType = @"NSPostScriptPboardType";
NSString *NSTabularTextPboardType = @"NSTabularTextPboardType";
NSString *NSRTFPboardType = @"NSRTFPboardType";
NSString *NSRTFDPboardType = @"NSRTFDPboardType";
NSString *NSTIFFPboardType = @"NSTIFFPboardType";
NSString *NSDataLinkPboardType = @"NSDataLinkPboardType";
NSString *NSGeneralPboardType = @"NSGeneralPboardType";
NSString *NSPDFPboardType = @"NSPDFPboardType";
NSString *NSPICTPboardType = @"NSPICTPboardType";
NSString *NSURLPboardType = @"NSURLPboardType";
NSString *NSHTMLPboardType = @"NSHTMLPboardType";

// Pasteboard Name Globals
NSString *NSDragPboard = @"NSDragPboard";
NSString *NSFindPboard = @"NSFindPboard";
NSString *NSFontPboard = @"NSFontPboard";
NSString *NSGeneralPboard = @"NSGeneralPboard";
NSString *NSRulerPboard = @"NSRulerPboard";

//
// Pasteboard Exceptions
//
NSString *NSPasteboardCommunicationException
= @"NSPasteboardCommunicationException";

// Printing Information Dictionary Keys
NSString *NSPrintAllPages = @"PrintAllPages";
NSString *NSPrintBottomMargin = @"PrintBottomMargin";
NSString *NSPrintCopies = @"PrintCopies";
NSString *NSPrintFaxCoverSheetName = @"PrintFaxCoverSheetName";
NSString *NSPrintFaxHighResolution = @"PrintFaxHighResolution";
NSString *NSPrintFaxModem = @"PrintFaxModem";
NSString *NSPrintFaxReceiverNames = @"PrintFaxReceiverNames";
NSString *NSPrintFaxReceiverNumbers = @"PrintFaxReceiverNumbers";
NSString *NSPrintFaxReturnReceipt = @"PrintFaxReturnReceipt";
NSString *NSPrintFaxSendTime = @"PrintFaxSendTime";
NSString *NSPrintFaxTrimPageEnds = @"PrintFaxTrimPageEnds";
NSString *NSPrintFaxUseCoverSheet = @"PrintFaxUseCoverSheet";
NSString *NSPrintFirstPage = @"PrintFirstPage";
NSString *NSPrintHorizonalPagination = @"PrintHorizonalPagination";
NSString *NSPrintHorizontallyCentered = @"PrintHorizontallyCentered";
NSString *NSPrintJobDisposition = @"PrintJobDisposition";
NSString *NSPrintJobFeatures = @"PrintJobFeatures";
NSString *NSPrintLastPage = @"PrintLastPage";
NSString *NSPrintLeftMargin = @"PrintLeftMargin";
NSString *NSPrintManualFeed = @"PrintManualFeed";
NSString *NSPrintOrientation = @"PrintOrientation";
NSString *NSPrintPagesPerSheet = @"PrintPagesPerSheet";
NSString *NSPrintPaperFeed = @"PrintPaperFeed";
NSString *NSPrintPaperName = @"PrintPaperName";
NSString *NSPrintPaperSize = @"PrintPaperSize";
NSString *NSPrintPrinter = @"PrintPrinter";
NSString *NSPrintReversePageOrder = @"PrintReversePageOrder";
NSString *NSPrintRightMargin = @"PrintRightMargin";
NSString *NSPrintSavePath = @"PrintSavePath";
NSString *NSPrintScalingFactor = @"PrintScalingFactor";
NSString *NSPrintTopMargin = @"PrintTopMargin";
NSString *NSPrintHorizontalPagination = @"PrintHorizontalPagination";
NSString *NSPrintVerticalPagination = @"PrintVerticalPagination";
NSString *NSPrintVerticallyCentered = @"PrintVerticallyCentered";

NSString *NSPrintPageDirection = @"NSPrintPageDirection";

// Print Job Disposition Values
NSString  *NSPrintCancelJob = @"PrintCancelJob";
NSString  *NSPrintFaxJob = @"PrintFaxJob";
NSString  *NSPrintPreviewJob = @"PrintPreviewJob";
NSString  *NSPrintSaveJob = @"PrintSaveJob";
NSString  *NSPrintSpoolJob = @"PrintSpoolJob";

// NSSplitView notifications
NSString *NSSplitViewDidResizeSubviewsNotification =
@"NSSplitViewDidResizeSubviewsNotification";
NSString *NSSplitViewWillResizeSubviewsNotification =
@"NSSplitViewWillResizeSubviewsNotification";

// NSTableView notifications
NSString *NSTableViewColumnDidMove = @"NSTableViewColumnDidMoveNotification";
NSString *NSTableViewColumnDidResize 
= @"NSTableViewColumnDidResizeNotification";
NSString *NSTableViewSelectionDidChange 
= @"NSTableViewSelectionDidChangeNotification";
NSString *NSTableViewSelectionIsChanging 
= @"NSTableViewSelectionIsChangingNotification";

// NSText notifications
NSString *NSTextDidBeginEditingNotification =
@"NSTextDidBeginEditingNotification";
NSString *NSTextDidEndEditingNotification = @"NSTextDidEndEditingNotification";
NSString *NSTextDidChangeNotification = @"NSTextDidChangeNotification";

// NSTextStorage Notifications
NSString *NSTextStorageWillProcessEditingNotification =
  @"NSTextStorageWillProcessEditingNotification";
NSString *NSTextStorageDidProcessEditingNotification =
  @"NSTextStorageDidProcessEditingNotification";

// NSTextView notifications
NSString *NSTextViewDidChangeSelectionNotification =
@"NSTextViewDidChangeSelectionNotification";
NSString *NSTextViewWillChangeNotifyingTextViewNotification =
@"NSTextViewWillChangeNotifyingTextViewNotification";

// NSView notifications
NSString *NSViewFocusDidChangeNotification
    = @"NSViewFocusDidChangeNotification";
NSString *NSViewFrameDidChangeNotification
    = @"NSViewFrameDidChangeNotification";
NSString *NSViewBoundsDidChangeNotification
    = @"NSViewBoundsDidChangeNotification";

// NSMenu notifications
NSString* const NSMenuDidSendActionNotification = @"MenuDidSendAction";
NSString* const NSMenuWillSendActionNotification = @"MenuWillSendAction";
NSString* const NSMenuDidAddItemNotification = @"MenuDidAddItem";
NSString* const NSMenuDidRemoveItemNotification = @"MenuDidRemoveItem";
NSString* const NSMenuDidChangeItemNotification = @"MenuDidChangeItem";

// NSPopUpButton notification
NSString *NSPopUpButtonWillPopUpNotification = @"PopUpButtonWillPopUp";
NSString *NSPopUpButtonCellWillPopUpNotification = @"PopUpButtonCellWillPopUp";

// NSTable notifications
NSString *NSTableViewSelectionDidChangeNotification = @"TableViewSelectionDidChange";
NSString *NSTableViewColumnDidMoveNotification = @"TableViewColumnDidMove";
NSString *NSTableViewColumnDidResizeNotification = @"TableViewColumnDidResize";
NSString *NSTableViewSelectionIsChangingNotification = @"TableViewSelectionIsChanging";

// NSOutlineView notifications
NSString *NSOutlineViewSelectionDidChangeNotification = @"OutlineViewSelectionDidChange";
NSString *NSOutlineViewColumnDidMoveNotification = @"OutlineViewColumnDidMove";
NSString *NSOutlineViewColumnDidResizeNotification = @"OutlineViewColumnDidResize";
NSString *NSOutlineViewSelectionIsChangingNotification = @"OutlineViewSelectionIsChanging";
NSString *NSOutlineViewItemDidExpandNotification = @"OutlineViewItemDidExpand";
NSString *NSOutlineViewItemDidCollapseNotification = @"OutlineViewItemDidCollapse";
NSString *NSOutlineViewItemWillExpandNotification = @"OutlineViewItemWillExpand";
NSString *NSOutlineViewItemWillCollapseNotification = @"OutlineViewItemWillCollapse";

// NSWindow notifications
NSString *NSWindowDidBecomeKeyNotification = @"WindowDidBecomeKey";
NSString *NSWindowDidBecomeMainNotification = @"WindowDidBecomeMain";
NSString *NSWindowDidChangeScreenNotification = @"WindowDidChangeScreen";
NSString *NSWindowDidDeminiaturizeNotification = @"WindowDidDeminiaturize";
NSString *NSWindowDidExposeNotification = @"WindowDidExpose";
NSString *NSWindowDidMiniaturizeNotification = @"WindowDidMiniaturize";
NSString *NSWindowDidMoveNotification = @"WindowDidMove";
NSString *NSWindowDidResignKeyNotification = @"WindowDidResignKey";
NSString *NSWindowDidResignMainNotification = @"WindowDidResignMain";
NSString *NSWindowDidResizeNotification = @"WindowDidResize";
NSString *NSWindowDidUpdateNotification = @"WindowDidUpdate";
NSString *NSWindowWillCloseNotification = @"WindowWillClose";
NSString *NSWindowWillMiniaturizeNotification = @"WindowWillMiniaturize";
NSString *NSWindowWillMoveNotification = @"WindowWillMove";

// Workspace File Type Globals
NSString *NSPlainFileType = @"NSPlainFileType";
NSString *NSDirectoryFileType = @"NSDirectoryFileType";
NSString *NSApplicationFileType = @"NSApplicationFileType";
NSString *NSFilesystemFileType = @"NSFilesystemFileType";
NSString *NSShellCommandFileType = @"NSShellCommandFileType";

// Workspace File Operation Globals
NSString *NSWorkspaceCompressOperation = @"NSWorkspaceCompressOperation";
NSString *NSWorkspaceCopyOperation = @"NSWorkspaceCopyOperation";
NSString *NSWorkspaceDecompressOperation = @"NSWorkspaceDecompressOperation";
NSString *NSWorkspaceDecryptOperation = @"NSWorkspaceDecryptOperation";
NSString *NSWorkspaceDestroyOperation = @"NSWorkspaceDestroyOperation";
NSString *NSWorkspaceDuplicateOperation = @"NSWorkspaceDuplicateOperation";
NSString *NSWorkspaceEncryptOperation = @"NSWorkspaceEncryptOperation";
NSString *NSWorkspaceLinkOperation = @"NSWorkspaceLinkOperation";
NSString *NSWorkspaceMoveOperation = @"NSWorkspaceMoveOperation";
NSString *NSWorkspaceRecycleOperation = @"NSWorkspaceRecycleOperation";

// NSWorkspace notifications
NSString *NSWorkspaceDidLaunchApplicationNotification =
@"NSWorkspaceDidLaunchApplicationNotification";
NSString *NSWorkspaceDidMountNotification = @"NSWorkspaceDidMountNotification";
NSString *NSWorkspaceDidPerformFileOperationNotification =
@"NSWorkspaceDidPerformFileOperationNotification";
NSString *NSWorkspaceDidTerminateApplicationNotification =
@"NSWorkspaceDidTerminateApplicationNotification";
NSString *NSWorkspaceDidUnmountNotification =
@"NSWorkspaceDidUnmountNotification";
NSString *NSWorkspaceWillLaunchApplicationNotification =
@"NSWorkspaceWillLaunchApplicationNotification";
NSString *NSWorkspaceWillPowerOffNotification =
@"NSWorkspaceWillPowerOffNotification";
NSString *NSWorkspaceWillUnmountNotification =
@"NSWorkspaceWillUnmountNotification";

/*
 *	NSStringDrawing NSString additions
 */
NSString *NSFontAttributeName  = @"NSFontAttributeName";
NSString *NSParagraphStyleAttributeName = @"NSParagraphStyleAttributeName";
NSString *NSForegroundColorAttributeName = @"NSForegroundColorAttributeName";
NSString *NSUnderlineStyleAttributeName = @"NSUnderlineStyleAttributeName";
NSString *NSSuperscriptAttributeName = @"NSSuperscriptAttributeName";
NSString *NSBackgroundColorAttributeName = @"NSBackgroundColorAttributeName";
NSString *NSAttachmentAttributeName = @"NSAttachmentAttributeName";
NSString *NSLigatureAttributeName = @"NSLigatureAttributeName";
NSString *NSBaselineOffsetAttributeName = @"NSBaselineOffsetAttributeName";
NSString *NSKernAttributeName = @"NSKernAttributeName";
NSString *NSLinkAttributeName = @"NSLinkAttributeName";

// NSToolbar notifications
NSString *NSToolbarDidRemoveItemNotification = @"NSToolbarDidRemoveItemNotification";
NSString *NSToolbarWillAddItemNotification = @"NSToolbarWillAddItemNotification";

// NSToolbarItem constants
NSString *NSToolbarSeperatorItemIdentifier = @"NSToolbarSeperatorItemIdentifier";
NSString *NSToolbarSpaceItemIdentifier = @"NSToolbarSpaceItemIdentifier";
NSString *NSToolbarFlexibleSpaceItemIdentifier = @"NSToolbarFlexibleSpaceItemIdentifier";
NSString *NSToolbarShowColorsItemIdentifier = @"NSToolbarShowColorsItemIdentifier";
NSString *NSToolbarShowFontsItemIdentifier = @"NSToolbarShowFontsItemIdentifier";
NSString *NSToolbarCustomizeToolbarItemIdentifier = @"NSToolbarCustomizeToolbarItemIdentifier";
NSString *NSToolbarPrintItemIdentifier = @"NSToolbarPrintItemIdentifier";

/*
 * NSTextView userInfo for notifications 
 */
NSString *NSOldSelectedCharacterRange = @"NSOldSelectedCharacterRange";

/* NSFont matrix */
const float NSFontIdentityMatrix[] = {1, 0, 0, 1, 0, 0};

/* Drawing engine externs */
NSString *NSBackendContext = @"NSBackendContext";

typedef int NSWindowDepth;

/**** Color function externs ****/
/* Since these are constants it was not possible
   to do the OR directly.  If you change the
   _GS*BitValue numbers, please remember to
   change the corresponding depth values */
const NSWindowDepth _GSGrayBitValue = 256;
const NSWindowDepth _GSRGBBitValue = 512;
const NSWindowDepth _GSCMYKBitValue = 1024;
const NSWindowDepth _GSNamedBitValue = 2048;
const NSWindowDepth _GSCustomBitValue = 4096;
const NSWindowDepth NSDefaultDepth = 0;            // GRAY = 256, RGB = 512
const NSWindowDepth NSTwoBitGrayDepth = 258;       // 0100000010 GRAY | 2bps
const NSWindowDepth NSEightBitGrayDepth = 264;     // 0100001000 GRAY | 8bps
const NSWindowDepth NSEightBitRGBDepth = 514;      // 1000000010 RGB  | 2bps
const NSWindowDepth NSTwelveBitRGBDepth = 516;     // 1000000100 RGB  | 4bps
const NSWindowDepth GSSixteenBitRGBDepth = 517;    // 1000000101 RGB  | 5bps GNUstep specific
const NSWindowDepth NSTwentyFourBitRGBDepth = 520; // 1000001000 RGB  | 8bps
const NSWindowDepth _GSWindowDepths[7] = { 258, 264, 514, 516, 517, 520, 0 };

/* End of color functions externs */

extern void __objc_gui_force_linking (void);

void
__objc_gui_force_linking (void)
{
  extern void __objc_gui_linking (void);
  __objc_gui_linking ();
}


