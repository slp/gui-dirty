/*
   NSSavePanel.m

   Standard save panel for saving files

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Jonathan Gapen <jagapen@smithlab.chem.wisc.edu>
   Date: 1999

   Author:  Nicola Pero <n.pero@mi.flashnet.it>
   Date: 1999

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/

#include <AppKit/IMLoading.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSBox.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/NSButton.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSForm.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSImageView.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSSavePanel.h>
#include <AppKit/NSTextField.h>
#include <AppKit/NSWorkspace.h>
#include <Foundation/NSException.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSPathUtilities.h>

#define _SAVE_PANEL_X_PAD	5
#define _SAVE_PANEL_Y_PAD	4

static NSSavePanel *_gs_gui_save_panel = nil;
static NSFileManager *_fm = nil;

static BOOL _gs_display_reading_progress = NO;

// Pacify the compiler
// Subclasses (read NSOpenPanel) may implement this 
// to filter some extensions out of displayed files.
@interface NSObject (_SavePanelPrivate)
-(BOOL) _shouldShowExtension: (NSString*)extension;
@end
//

//
// NSSavePanel private methods
//
@interface NSSavePanel (_PrivateMethods)

// Methods to manage default settings
- (id) _initWithoutGModel;
- (void) _getOriginalSize;
- (void) _resetDefaults;
// Methods invoked by buttons
- (void) _setHomeDirectory;
- (void) _mountMedia;
- (void) _unmountMedia;

@end /* NSSavePanel (PrivateMethods) */

@implementation NSSavePanel (_PrivateMethods)
-(id) _initWithoutGModel
{
  NSBox *bar;
  NSButton *button;
  NSImage *image;
  NSRect r;

  //
  // WARNING: We create the panel sized (308, 317), which is the 
  // minimum size we want it to have.  Then, we resize it at the 
  // comfortable size of (384, 426).
  //
  [super initWithContentRect: NSMakeRect (100, 100, 308, 317)
	 styleMask: (NSTitledWindowMask | NSResizableWindowMask) 
	 backing: 2 defer: YES];
  [self setMinSize: [self frame].size];
  [[self contentView] setBounds: NSMakeRect (0, 0, 308, 317)];
  
  r = NSMakeRect (0, 64, 308, 245);
  _topView = [[NSView alloc] initWithFrame: r]; 
  [_topView setBounds:  r];
  [_topView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [_topView setAutoresizesSubviews: YES];
  [[self contentView] addSubview: _topView];
  [_topView release];
  
  r = NSMakeRect (0, 0, 308, 64);
  _bottomView = [[NSView alloc] initWithFrame: r];
  [_bottomView setBounds:  r];
  [_bottomView setAutoresizingMask: NSViewWidthSizable];
  [_bottomView setAutoresizesSubviews: YES];
  [[self contentView] addSubview: _bottomView];
  [_bottomView release];

  r = NSMakeRect (8, 68, 292, 177);
  _browser = [[NSBrowser alloc] initWithFrame: r]; 
  [_browser setDelegate: self];
  [_browser setDoubleAction: @selector (ok:)];
  [_browser setTarget: self];
  [_browser setMaxVisibleColumns: 2]; 
  [_browser setHasHorizontalScroller: YES];
  [_browser setAllowsMultipleSelection: NO];
  [_browser setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
  [_browser setTag: NSFileHandlingPanelBrowser];
  [_topView addSubview: _browser];
  [_browser release];

  r = NSMakeRect (8, 39, 291, 21);
  _form = [NSForm new];
  [_form addEntry: @"Name:"];
  [_form setFrame: r];
  // Force the size we want
  [_form setCellSize: NSMakeSize (291, 21)];
  [_form setEntryWidth: 291];
  [_form setInterlineSpacing: 0];
  [_form setAutosizesCells: YES];
  [_form setTag: NSFileHandlingPanelForm];
  [_form setAutoresizingMask: NSViewWidthSizable];
  [_form setDelegate: self];
  [_bottomView addSubview: _form];
  [_form release];

  r = NSMakeRect (43, 6, 27, 27);
  button = [[NSButton alloc] initWithFrame: r]; 
  [button setBordered: YES];
  [button setButtonType: NSMomentaryPushButton];
  image = [NSImage imageNamed: @"common_Home"];
  [button setImage: image];
  [button setImagePosition: NSImageOnly]; 
  [button setTarget: self];
  [button setAction: @selector(_setHomeDirectory)];
  // [_form setNextKeyView: button];
  [button setAutoresizingMask: NSViewMinXMargin];
  [button setTag: NSFileHandlingPanelHomeButton];
  [_bottomView addSubview: button];
  [button release];
  
  r = NSMakeRect (78, 6, 27, 27);
  button = [[NSButton alloc] initWithFrame: r];
  [button setBordered: YES];
  [button setButtonType: NSMomentaryPushButton];
  image = [NSImage imageNamed: @"common_Mount"]; 
  [button setImage: image]; 
  [button setImagePosition: NSImageOnly]; 
  [button setTarget: self];
  [button setAction: @selector(_mountMedia)];
  [button setAutoresizingMask: NSViewMinXMargin];
  [button setTag: NSFileHandlingPanelDiskButton];
  [_bottomView addSubview: button];
  [button release];

  r = NSMakeRect (112, 6, 27, 27);
  button = [[NSButton alloc] initWithFrame: r];
  [button setBordered: YES];
  [button setButtonType: NSMomentaryPushButton];
  image = [NSImage imageNamed: @"common_Unmount"]; 
  [button setImage: image];
  [button setImagePosition: NSImageOnly]; 
  [button setTarget: self];
  [button setAction: @selector(_unmountMedia)];
  [button setAutoresizingMask: NSViewMinXMargin];
  [button setTag: NSFileHandlingPanelDiskEjectButton];
  [_bottomView addSubview: button];
  [button release];
  
  r = NSMakeRect (148, 6, 71, 27);
  button = [[NSButton alloc] initWithFrame: r]; 
  [button setBordered: YES];
  [button setButtonType: NSMomentaryPushButton];
  [button setTitle:  @"Cancel"];
  [button setImagePosition: NSNoImage]; 
  [button setTarget: self];
  [button setAction: @selector(cancel:)];
  [button setAutoresizingMask: NSViewMinXMargin];
  [button setTag: NSFileHandlingPanelCancelButton];
  [_bottomView addSubview: button];
  [button release];
  
  r = NSMakeRect (228, 6, 71, 27);
  _okButton = [[NSButton alloc] initWithFrame: r]; 
  [_okButton setBordered: YES];
  [_okButton setButtonType: NSMomentaryPushButton];
  [_okButton setTitle:  @"OK"];
  [_okButton setImagePosition: NSNoImage]; 
  [_okButton setTarget: self];
  [_okButton setAction: @selector(ok:)];
  //    [_okButton setNextKeyView: _form];
  [_okButton setAutoresizingMask: NSViewMinXMargin];
  [_okButton setTag: NSFileHandlingPanelOKButton];
  [_bottomView addSubview: _okButton];
  [_okButton release];
  
  r = NSMakeRect (8, 261, 48, 48);
  button = [[NSButton alloc] initWithFrame: r]; 
  image = [[NSApplication sharedApplication] applicationIconImage];
  [button setImage: image];
  [button setBordered: NO];
  [button setEnabled: NO];
  [button setImagePosition: NSImageOnly];
  [button setAutoresizingMask: NSViewMinYMargin];
  [button setTag: NSFileHandlingPanelImageButton];
  [_topView addSubview: button];
  [button release];

  r = NSMakeRect (67, 276, 200, 14);
  _titleField = [[NSTextField alloc] initWithFrame: r]; 
  [_titleField setSelectable: NO];
  [_titleField setEditable: NO];
  [_titleField setDrawsBackground: NO];
  [_titleField setBezeled: NO];
  [_titleField setBordered: NO];
  [_titleField setFont: [NSFont messageFontOfSize: 18]];
  [_titleField setAutoresizingMask: NSViewMinYMargin];
  [_titleField setTag: NSFileHandlingPanelTitleField];
  [_topView addSubview: _titleField];
  [_titleField release];

  r = NSMakeRect (0, 252, 308, 2);
  bar = [[NSBox alloc] initWithFrame: r]; 
  [bar setBorderType: NSGrooveBorder];
  [bar setTitlePosition: NSNoTitle];
  [bar setAutoresizingMask: NSViewWidthSizable|NSViewMinYMargin];
  [_topView addSubview: bar];
  [bar release];

  [self setContentSize: NSMakeSize (384, 426)];
  [super setTitle: @""];
  return self;
}

- (void) _getOriginalSize
{
  /* Used in setMinSize: */
  _originalMinSize = [self minSize];
  /* Used in setContentSize: */
  _originalSize = [[self contentView] frame].size;
}

- (void) _resetDefaults
{
  ASSIGN (_directory, [_fm currentDirectoryPath]);
  [self setPrompt: @"Name:"];
  [self setTitle: @"Save"];
  [self setRequiredFileType: @""];
  [self setTreatsFilePackagesAsDirectories: NO];
  [self setDelegate: nil];
  [self setAccessoryView: nil];
}

//
// Methods invoked by button press
//
- (void) _setHomeDirectory
{
  [self setDirectory: NSHomeDirectory()];
}

- (void) _mountMedia
{
  [[NSWorkspace sharedWorkspace] mountNewRemovableMedia];
}

- (void) _unmountMedia
{
  [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath: [self directory]];
}

@end /* NSSavePanel (PrivateMethods) */

//
// NSSavePanel methods
//
@implementation NSSavePanel

+ (void) initialize
{
  if (self == [NSSavePanel class])
    {
      [self setVersion: 1];
      ASSIGN (_fm, [NSFileManager defaultManager]);

      // A GNUstep feature
      if ([[NSUserDefaults standardUserDefaults] 
	    boolForKey: @"GSSavePanelShowProgress"])
	{
	  _gs_display_reading_progress = YES;
	}
    }
}

+ (id) savePanel
{
  if (_gs_gui_save_panel == nil)
    {
      _gs_gui_save_panel = [[NSSavePanel alloc] init];
    }

  [_gs_gui_save_panel _resetDefaults];

  return _gs_gui_save_panel;
}
//

-(void) dealloc
{
  TEST_RELEASE (_fullFileName);
  TEST_RELEASE (_directory);  
  TEST_RELEASE (_requiredFileType);

  [super dealloc];
}

// If you do a simple -init, we initialize the panel with
// the system size/mask/appearance/subviews/etc.  If you do more
// complicated initializations, you get a simple panel from super.
-(id) init
{
  //  if (![GMModel loadIMFile: @"SavePanel" owner: self]);
  [self _initWithoutGModel];
  
  _directory = nil;
  _fullFileName = nil;
  _requiredFileType = nil;
  _delegate = nil;
  
  _treatsFilePackagesAsDirectories = NO;
  _delegateHasCompareFilter = NO;
  _delegateHasShowFilenameFilter = NO;
  _delegateHasValidNameFilter = NO;

  if ([self respondsToSelector: @selector(_shouldShowExtension:)])
    _selfHasShowExtensionFilter = YES;
  else 
    _selfHasShowExtensionFilter = NO;
  
  [self _getOriginalSize];
  return self;
}

- (void) setAccessoryView: (NSView*)aView
{
  NSRect accessoryViewFrame, bottomFrame, topFrame;
  NSRect tmpRect;
  NSSize contentSize, contentMinSize;
  float addedHeight, accessoryWidth;

  if (aView == _accessoryView)
    return;
  
  /* The following code is very tricky.  Please think and test a lot
     before changing it. */

  /* Remove old accessory view if any */
  if (_accessoryView != nil)
    {
      /* Remove accessory view */
      accessoryViewFrame = [_accessoryView frame];
      [_accessoryView removeFromSuperview];

      /* Change the min size before doing the resizing otherwise it
	 could be a problem. */
      [self setMinSize: _originalMinSize];

      /* Resize the panel to the height without the accessory view. 
	 This must be done with the special care of not resizing 
	 the heights of the other views. */
      addedHeight = accessoryViewFrame.size.height + (_SAVE_PANEL_Y_PAD * 2);
      contentSize = [[self contentView] frame].size;
      contentSize.height -= addedHeight;
      // Resize without modifying topView and bottomView height.
      [_topView setAutoresizingMask: NSViewWidthSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];
      [self setContentSize: contentSize];
      [_topView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];

      /* Move top view to its position without accessory view */
      topFrame = [_topView frame];
      topFrame.origin.y -= addedHeight;
      [_topView setFrameOrigin: topFrame.origin];
    }
  
  /* Resize the panel to its original size.  This resizes freely the
     heights of the views.  NB: minSize *must* come first */
  [self setMinSize: _originalMinSize];
  [self setContentSize: _originalSize];
  
  /* Set the new accessory view */
  _accessoryView = aView;
  
  /* If there is a new accessory view, plug it in */
  if (_accessoryView != nil)
    {
      /* Make sure the new accessory view behaves */
      [_accessoryView setAutoresizingMask: ([_accessoryView autoresizingMask] 
					    & !NSViewHeightSizable 
					    & !NSViewMaxYMargin
					    & !NSViewMinYMargin)];  
      
      /* Compute size taken by the new accessory view */
      accessoryViewFrame = [_accessoryView frame];
      addedHeight = accessoryViewFrame.size.height + (_SAVE_PANEL_Y_PAD * 2);
      accessoryWidth = accessoryViewFrame.size.width + (_SAVE_PANEL_X_PAD * 2);

      /* Resize content size accordingly */
      contentSize = _originalSize;
      contentSize.height += addedHeight;
      if (accessoryWidth > contentSize.width)
	{
	  contentSize.width = accessoryWidth;
	}
      
      /* Set new content size without resizing heights of topView, bottomView */
      // Our views should resize horizontally if needed, but not vertically
      [_topView setAutoresizingMask: NSViewWidthSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];
      [self setContentSize: contentSize];
      // Restore the original autoresizing masks
      [_topView setAutoresizingMask: NSViewWidthSizable|NSViewHeightSizable];
      [_bottomView setAutoresizingMask: NSViewWidthSizable];

      /* Compute new min size */
      contentMinSize = _originalMinSize;
      contentMinSize.height += addedHeight;
      // width is more delicate
      tmpRect = NSMakeRect (0, 0, contentMinSize.width, contentMinSize.height);
      tmpRect = [NSWindow contentRectForFrameRect: tmpRect 
			  styleMask: [self styleMask]];
      if (accessoryWidth > tmpRect.size.width)
	{
	  contentMinSize.width += accessoryWidth - tmpRect.size.width;
	}
      // Set new min size
      [self setMinSize: contentMinSize];

      /*
       * Pack the Views
       */

      /* BottomView is ready */
      bottomFrame = [_bottomView frame];

      /* AccessoryView */
      accessoryViewFrame.origin.x 
	= (contentSize.width - accessoryViewFrame.size.width) / 2;
      accessoryViewFrame.origin.y =  NSMaxY (bottomFrame) + _SAVE_PANEL_Y_PAD;
      [_accessoryView setFrameOrigin: accessoryViewFrame.origin];

      /* TopView */
      topFrame = [_topView frame];
      topFrame.origin.y += addedHeight;
      [_topView setFrameOrigin: topFrame.origin];

      /* Add the accessory view */
      [[self contentView] addSubview: _accessoryView];
    }
}

- (void) setTitle: (NSString*)title
{
  [_titleField setStringValue: title];

  // TODO: Improve the following by managing 
  // vertical alignment better.
  [_titleField sizeToFit];
}

- (NSString*) title
{
  return [_titleField stringValue];
}

- (void) setPrompt: (NSString*)prompt
{
  [[_form cellAtIndex: 0] setTitle: prompt];
  [_form setNeedsDisplay: YES];
}

- (NSString*) prompt
{
  return [[_form cellAtIndex: 0] title];
}

- (NSView*) accessoryView
{
  return _accessoryView;
}

- (void) setDirectory: (NSString*)path
{
  NSString *standardizedPath = [path stringByStandardizingPath];
  BOOL	   isDir;
  
  if (standardizedPath 
      && [_fm fileExistsAtPath: standardizedPath 
	      isDirectory: &isDir] 
      && isDir)
    {
      ASSIGN (_directory, standardizedPath);
      [_browser setPath: _directory];
    }
}

- (void) setRequiredFileType: (NSString*)fileType
{
  ASSIGN(_requiredFileType, fileType);
}

- (NSString*) requiredFileType
{
  return _requiredFileType;
}

- (BOOL) treatsFilePackagesAsDirectories
{
  return _treatsFilePackagesAsDirectories;
}

- (void) setTreatsFilePackagesAsDirectories: (BOOL)flag
{
  _treatsFilePackagesAsDirectories = flag;
}

- (void) validateVisibleColumns
{
  [_browser validateVisibleColumns];
}

- (int) runModal
{
  if (_directory)
    return [self runModalForDirectory: _directory 
				 file: @""];
  else
    return [self runModalForDirectory: [_fm currentDirectoryPath] 
				 file: @""];
}

- (int) runModalForDirectory: (NSString*)path file: (NSString*)filename
{
  if (path == nil || filename == nil)
    [NSException raise: NSInvalidArgumentException
		format: @"NSSavePanel runModalForDirectory:file: "
		 @"does not accept nil arguments."];

  ASSIGN (_directory, path);
  ASSIGN (_fullFileName, [path stringByAppendingPathComponent: filename]);
  [_browser setPath: _fullFileName];
  [[_form cellAtIndex: 0] setStringValue: filename];
  [_form setNeedsDisplay: YES];

  /*
   * We need to take care of the possibility of 
   * the panel being aborted.  We return NSCancelButton 
   * in that case.
   */
  _OKButtonPressed = NO;

  [NSApp runModalForWindow: self];

  if (_OKButtonPressed)
    return NSOKButton;
  else 
    return NSCancelButton;
}

- (NSString*) directory
{
  if (_directory)
    return _directory;
  else 
    return @"";
}

- (NSString*) filename
{
  if (_fullFileName == nil)
   return @"";

  if (_requiredFileType == nil)
    return _fullFileName;

  if ([_requiredFileType isEqual: @""] == YES)
    return _fullFileName;
					    
  // add filetype extension only if the filename does not include it already
  if ([[_fullFileName pathExtension] isEqual: _requiredFileType] == YES)
    return _fullFileName;
  else
    return [_fullFileName stringByAppendingPathExtension: _requiredFileType];
}

- (void) cancel: (id)sender
{
  _fullFileName = nil;
  _directory = nil;
  [NSApp stopModal];
  [self close];
}

- (void) ok: (id)sender
{
  if (_delegateHasValidNameFilter)
    if (![_delegate panel:self isValidFilename: [self filename]])
      return;

  _OKButtonPressed = YES;
  [NSApp stopModal];
  [self close];
}

- (void) selectText: (id)sender
{
  // TODO
}

- (void) setDelegate: (id)aDelegate
{
  if ([aDelegate respondsToSelector:
		   @selector(panel:compareFilename:with:caseSensitive:)])
    _delegateHasCompareFilter = YES;
  else 
    _delegateHasCompareFilter = NO;
  
  if ([aDelegate respondsToSelector: @selector(panel:shouldShowFilename:)])
    _delegateHasShowFilenameFilter = YES;      
  else
    _delegateHasShowFilenameFilter = NO;      
  
  if ([aDelegate respondsToSelector: @selector(panel:isValidFilename:)])
    _delegateHasValidNameFilter = YES;
  else
    _delegateHasValidNameFilter = NO;
  
  [super setDelegate: aDelegate];
}

//
// NSCoding protocol
//
- (id) initWithCoder: (NSCoder*)aCoder
{
  // TODO

  return nil;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  // TODO
}
@end

//
// NSSavePanel browser delegate methods
//
@interface NSSavePanel (_BrowserDelegate)
- (void) browser: (id)sender
createRowsForColumn: (int)column
        inMatrix: (NSMatrix*)matrix;

- (BOOL) browser: (NSBrowser*)sender
   isColumnValid: (int)column;

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)column;

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)cell
           atRow: (int)row
          column: (int)column;
@end 

@implementation NSSavePanel (_BrowserDelegate)
- (void) browser: (id)sender
createRowsForColumn: (int)column
	inMatrix: (NSMatrix*)matrix
{
  NSString      *path, *file, *pathAndFile, *extension, *h; 
  NSArray       *files, *hiddenFiles;
  unsigned	i, count, addedRows; 
  BOOL		exists, isDir;
  NSBrowserCell *cell;
  // _gs_display_reading_progress variables
  unsigned      reached_frac = 0;
  unsigned      base_frac = 1;
  BOOL          display_progress = NO;
  NSString*     progressString = nil;
  /* We create lot of objects in this method, so we use a pool */
  NSAutoreleasePool *pool;

  pool = [NSAutoreleasePool new];
  
  path = [_browser pathToColumn: column];
  files = [_fm directoryContentsAtPath: path];
    
  // Remove hidden files
  h = [path stringByAppendingPathComponent: @".hidden"];
  h = [NSString stringWithContentsOfFile: h];
  hiddenFiles = [h componentsSeparatedByString: @"\n"];
  if (hiddenFiles)
    {
      files = [NSMutableArray arrayWithArray: files];
      [(NSMutableArray*)files removeObjectsInArray: hiddenFiles];
    }
  
  count = [files count];

  // if array is empty, just return (nothing to display)
  if (count == 0)
    {
      RELEASE (pool);
      return;
    }

  // Prepare Messages on title bar if directory is big and user wants them
  if (_gs_display_reading_progress && (count > 100))
    {
      display_progress = YES;
      base_frac = count / 4;
      progressString = [@"Reading Directory " stringByAppendingString: path];
      [super setTitle: progressString];
      // Is the following really safe? 
      [GSCurrentContext() flush];
    }

  //TODO: Sort after creation of matrix so we do not sort 
  // files we are not going to show.  Use NSMatrix sorting cells method
  // Sort list of files to display
  if (_delegateHasCompareFilter == YES)
    {
      int compare(id elem1, id elem2, void *context)
      {
	return (int)[_delegate panel: self
		     compareFilename: elem1
				with: elem2
		       caseSensitive: YES];
      }
      files = [files sortedArrayUsingFunction: compare 
		     context: nil];
    }
  else
    files = [files sortedArrayUsingSelector: @selector(compare:)];

  addedRows = 0;
  for (i = 0; i < count; i++)
    {
      // Update displayed message if needed
      if (display_progress && (i > (base_frac * (reached_frac + 1))))
	{
	  reached_frac++;
	  progressString = [progressString stringByAppendingString: @"."];
	  [super setTitle: progressString];
	  [GSCurrentContext() flush];
	}
      // Now the real code
      file = [files objectAtIndex: i];
      extension = [file pathExtension];
      
      pathAndFile = [path stringByAppendingPathComponent: file];
      exists = [_fm fileExistsAtPath: pathAndFile 
		    isDirectory: &isDir];
      
      if (_delegateHasShowFilenameFilter)
	{
	  exists = [_delegate panel: self
			      shouldShowFilename: pathAndFile];
	}

      if (_treatsFilePackagesAsDirectories == NO && isDir == YES && exists)
	{
	  // Ones with more chance first
	  if ([extension isEqualToString: @"app"] 
	      || [extension isEqualToString: @"bundle"] 
	      || [extension isEqualToString: @"palette"]
	      || [extension isEqualToString: @"debug"] 
	      || [extension isEqualToString: @"profile"])
	    isDir = NO;
	}

      if (_selfHasShowExtensionFilter && exists && (isDir == NO))
	{
	  exists = [self _shouldShowExtension: extension];
	}
      
      if (exists)
	{
	  if (addedRows == 0)
	    {
	      [matrix addColumn];	      
	    }
	  else // addedRows > 0
	    {
	      /* Same as [matrix addRow] */
	      [matrix insertRow: addedRows  withCells: nil];
	      /* Possible TODO: Faster would be to create all the
		 cells at once with a single call instead of resizing 
		 the matrix each time a cell is inserted. */
	    }

	  cell = [matrix cellAtRow: addedRows column: 0];
	  [cell setStringValue: file];
	  
	  if (isDir)
	    [cell setLeaf: NO];
	  else
	    [cell setLeaf: YES];

	  addedRows++;
	}
    }

  if (display_progress)
    {
      [super setTitle: @""];
      [GSCurrentContext() flush];
    }

  RELEASE (pool);
}

- (BOOL) browser: (NSBrowser*)sender
   isColumnValid: (int)column
{
  NSArray	*cells = [[sender matrixInColumn: column] cells];
  unsigned	count = [cells count], i;
  
  // iterate through the cells asking the delegate if each filename is valid
  // if it says no for any filename, the column is not valid
  if (_delegateHasShowFilenameFilter == YES)
    for (i = 0; i < count; i++)
      {
	if (![_delegate panel: self 
			shouldShowFilename:
			  [[cells objectAtIndex: i] stringValue]])
	  return NO;
      }

  return YES;
}

- (BOOL) browser: (NSBrowser*)sender
selectCellWithString: (NSString*)title
	inColumn: (int)column
{
  NSMatrix *m;
  BOOL isLeaf;
  NSString *path;

  m = [sender matrixInColumn: column];
  isLeaf = [[m selectedCell] isLeaf];
  path = [sender pathToColumn: column];

  if (isLeaf)
    {
      ASSIGN (_directory, path);
      ASSIGN (_fullFileName, [path stringByAppendingPathComponent: title]);
      [[_form cellAtIndex: 0] setStringValue: title];
      [_form setNeedsDisplay: YES];
    }
  else
    {
      ASSIGN (_directory, [path stringByAppendingPathComponent: title]);
      ASSIGN (_fullFileName, nil);
      [[_form cellAtIndex: 0] setStringValue: @""];
      [_form setNeedsDisplay: YES];
    }
  
  return YES;
}

- (void) browser: (NSBrowser*)sender
 willDisplayCell: (id)cell
	   atRow: (int)row
	  column: (int)column
{
}
@end

//
// NSForm delegate methods
//
@interface NSSavePanel (FormDelegate)
- (void) controlTextDidEndEditing: (NSNotification*)aNotification;
@end
@implementation NSSavePanel (FormDelegate)
- (void) controlTextDidEndEditing: (NSNotification*)aNotification
{
  NSString *s;

  s = [self directory];
  s = [s stringByAppendingPathComponent: [[_form cellAtIndex: 0] stringValue]];
  if (1) // TODO: condition when the filename is acceptable
    {
      ASSIGN (_fullFileName, s);
      [_browser setPath: s];
    }
  else   // typed filename is not acceptable
    {
      // TODO
    }
}
@end /* NSSavePanel */



