/** <title>NSBrowser</title>

   <abstract>Control to display and select from hierarchal lists</abstract>

   Copyright (C) 1996, 1997, 2002 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author:  Franck Wolff <wolff@cybercable.fr>
   Date: November 1999
   Author:  Mirko Viviani <mirko.viviani@rccr.cremona.it>
   Date: September 2000
   Author:  Fred Kiefer <FredKiefer@gmx.de>
   Date: September 2002

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

#include <math.h>                  // (float)rintf(float x)
#include <gnustep/gui/config.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSException.h>
#include <AppKit/NSBrowser.h>
#include <AppKit/NSBrowserCell.h>
#include <AppKit/AppKitExceptions.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSFont.h>
#include <AppKit/NSScrollView.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSMatrix.h>
#include <AppKit/NSTableHeaderCell.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSWindow.h>
#include <AppKit/NSBezierPath.h>

DEFINE_RINT_IF_MISSING

/* Cache */
static float scrollerWidth; // == [NSScroller scrollerWidth]
static NSTextFieldCell *titleCell;

#define NSBR_COLUMN_SEP 4
#define NSBR_VOFFSET 2

#define NSBR_COLUMN_IS_VISIBLE(i) \
(((i)>=_firstVisibleColumn)&&((i)<=_lastVisibleColumn))

//
// Internal class for maintaining information about columns
//
@interface NSBrowserColumn : NSObject <NSCoding>
{
@public
  BOOL _isLoaded;
  id _columnScrollView;
  id _columnMatrix;
  NSString *_columnTitle;
}

- (void) setIsLoaded: (BOOL)flag;
- (BOOL) isLoaded;
- (void) setColumnScrollView: (id)aView;
- (id) columnScrollView;
- (void) setColumnMatrix: (id)aMatrix;
- (id) columnMatrix;
- (void) setColumnTitle: (NSString *)aString;
- (NSString *) columnTitle;
@end

@implementation NSBrowserColumn

- (id) init
{
  [super init];

  _isLoaded = NO;

  return self;
}

- (void) dealloc
{
  TEST_RELEASE(_columnScrollView);
  TEST_RELEASE(_columnMatrix);
  TEST_RELEASE(_columnTitle);
  [super dealloc];
}

- (void) setIsLoaded: (BOOL)flag
{
  _isLoaded = flag;
}

- (BOOL) isLoaded
{
  return _isLoaded;
}

- (void) setColumnScrollView: (id)aView
{
  ASSIGN(_columnScrollView, aView);
}

- (id) columnScrollView
{
  return _columnScrollView;
}

- (void) setColumnMatrix: (id)aMatrix
{
  ASSIGN(_columnMatrix, aMatrix);
}

- (id) columnMatrix
{
  return _columnMatrix;
}

- (void) setColumnTitle: (NSString *)aString
{
  if (!aString)
    aString = @"";

  ASSIGN(_columnTitle, aString);
}

- (NSString *) columnTitle
{
  return _columnTitle;
}

- (void) encodeWithCoder: (NSCoder *)aCoder
{
  int dummy = 0;

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
  [aCoder encodeObject: _columnScrollView];
  [aCoder encodeObject: _columnMatrix];
  [aCoder encodeValueOfObjCType: @encode(int) at: &dummy];
  [aCoder encodeObject: _columnTitle];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
  int dummy = 0;

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
  _columnScrollView = [aDecoder decodeObject];
  if (_columnScrollView)
    RETAIN(_columnScrollView);
  _columnMatrix = [aDecoder decodeObject];
  if (_columnMatrix)
    RETAIN(_columnMatrix);
  [aDecoder decodeValueOfObjCType: @encode(int) at: &dummy];
  _columnTitle = [aDecoder decodeObject];
  if (_columnTitle)
    RETAIN(_columnTitle);
  return self;
}

@end

// NB: this is used in the NSFontPanel too
@interface GSBrowserTitleCell: NSTableHeaderCell
@end

@implementation GSBrowserTitleCell
- (void) drawWithFrame: (NSRect)cellFrame  inView: (NSView*)controlView
{
  if (NSIsEmptyRect (cellFrame) || ![controlView window])
    {
      return;
    }

  NSDrawGrayBezel (cellFrame, NSZeroRect);
  [self drawInteriorWithFrame: cellFrame  inView: controlView];
}
@end

//
// Private NSBrowser methods
//
@interface NSBrowser (Private)
- (NSString *) _getTitleOfColumn: (int)column;
- (void) _performLoadOfColumn: (int)column;
- (void) _remapColumnSubviews: (BOOL)flag;
- (void) _setColumnTitlesNeedDisplay;
@end

//
// NSBrowser implementation
//
@implementation NSBrowser

/** Returns the NSBrowserCell class (regardless of whether a 
    setCellClass: message has been sent to a particular instance). This
    method is not meant to be used by applications.
*/

+ (Class) cellClass
{
  return [NSBrowserCell class];
}

/** Sets the class of NSCell used in the columns of the NSBrowser. */
- (void) setCellClass: (Class)classId
{
  NSCell *aCell;

  aCell = [[classId alloc] init];
  // set the prototype for the new class
  [self setCellPrototype: aCell];
  RELEASE(aCell);
}

/** Returns the NSBrowser's prototype NSCell instance.*/
- (id) cellPrototype
{
  return _browserCellPrototype;
}

/** Sets the NSCell instance copied to display items in the columns of
    NSBrowser. */
- (void) setCellPrototype: (NSCell *)aCell
{
  ASSIGN(_browserCellPrototype, aCell);
}

/** Returns the class of NSMatrix used in the NSBrowser's columns. */
- (Class) matrixClass
{
  return _browserMatrixClass;
}

/** Sets the matrix class (NSMatrix or an NSMatrix subclass) used in the
    NSBrowser's columns. */
- (void) setMatrixClass: (Class)classId
{
  _browserMatrixClass = classId;
}

/*
 * Getting matrices, cells, and rows
 */

/** Returns the last (rightmost and lowest) selected NSCell. */
- (id) selectedCell
{
  int i;
  id matrix;

  // Nothing selected
  if ((i = [self selectedColumn]) == -1)
    {
      return nil;
    }
  
  if (!(matrix = [self matrixInColumn: i]))
    {
      return nil;
    }

  return [matrix selectedCell];
}

/** Returns the last (lowest) NSCell that's selected in column. */
- (id) selectedCellInColumn: (int)column
{
  id matrix;

  if (!(matrix = [self matrixInColumn: column]))
    {
      return nil;
    }

  return [matrix selectedCell];
}

/** Returns all cells selected in the rightmost column. */
- (NSArray *) selectedCells
{
  int i;
  id matrix;

  // Nothing selected
  if ((i = [self selectedColumn]) == -1)
    {
      return nil;
    }
  
  if (!(matrix = [self matrixInColumn: i]))
    {
      return nil;
    }

  return [matrix selectedCells];
}

/** Selects all NSCells in the last column of the NSBrowser. */
- (void) selectAll: (id)sender
{
  id matrix;

  if (!(matrix = [self matrixInColumn: _lastColumnLoaded]))
    {
      return;
    }

  [matrix selectAll: sender];
}

/** Returns the row index of the selected cell in the column specified by
   index column. */
- (int) selectedRowInColumn: (int)column
{
  id matrix;

  if (!(matrix = [self matrixInColumn: column]))
    {
      return -1;
    }

  return [matrix selectedRow];
}

/** Selects the cell at index row in the column identified by index column. */
- (void) selectRow: (int)row inColumn: (int)column 
{
  id matrix;
  id cell;

  if (column < 0 || column > _lastColumnLoaded)
    return;

  if (!(matrix = [self matrixInColumn: column]))
    return;

  if ((cell = [matrix cellAtRow: row column: 0]))
    {
      BOOL didSelect;

      if (column < _lastColumnLoaded)
	{
	  [self setLastColumn: column];
	}
      if (_allowsMultipleSelection == NO)
	[matrix deselectAllCells];

      didSelect = YES;
      if ([_browserDelegate respondsToSelector:
			      @selector(browser:selectRow:inColumn:)])
	{
	  didSelect = [_browserDelegate browser: self
				      selectRow: row
				       inColumn: column];
	}
      else
	{
	  [matrix selectCellAtRow: row column: 0];
	}

      if (didSelect && [cell isLeaf] == NO)
	{
	  [self addColumn];
	}
    }
}

/** Loads if necessary and returns the NSCell at row in column. */
/*  if you change this code, you may want to look at the _loadColumn
 method in which the following code is integrated (for speed) */
- (id) loadedCellAtRow: (int)row
	       column: (int)column
{
  NSArray *columnCells;
  id matrix;
  int count = [_browserColumns count];
  id aCell;

  // column range check
  if (column >= count)
    {
      return nil;
    }

  if (!(matrix = [self matrixInColumn: column]))
    {
      return nil;
    }

  if (!(columnCells = [matrix cells]))
    {
      return nil;
    }

  count = [columnCells count];

  // row range check
  if (row >= count)
    {
      return nil;
    }

  // Get the cell
  if (!(aCell = [matrix cellAtRow: row column: 0]))
    {
      return nil;
    }

  // Load if not already loaded
  if ([aCell isLoaded])
    {
      return aCell;
    }
  else
    {
      if (_passiveDelegate || [_browserDelegate respondsToSelector: 
		  @selector(browser:willDisplayCell:atRow:column:)])
	{
	  [_browserDelegate browser: self  willDisplayCell: aCell
			    atRow: row  column: column];
	}
      [aCell setLoaded: YES];
    }

  return aCell;
}

/** Returns the matrix located in the column identified by index column. */
- (NSMatrix *) matrixInColumn: (int)column
{
  NSBrowserColumn *bc;

  // No column selected.
  if (column == -1)
    {
      return nil;
    }

  bc = [_browserColumns objectAtIndex: column];
  
  if ((bc == nil) || !(bc->_isLoaded))
    {
      return nil;
    }

  return bc->_columnMatrix;
}

/*
 * Getting and setting paths
 */

/** Returns the browser's current path. */
- (NSString *) path
{
  return [self pathToColumn: _lastColumnLoaded + 1];
}

/** Parses path and selects corresponding items in the NSBrowser columns. */
- (BOOL) setPath: (NSString *)path
{
  NSArray	*subStrings;
  NSString	*aStr;
  unsigned	numberOfSubStrings;
  unsigned	i, j;
  int           column = 0;
  BOOL	      	found = YES;

  // If that's all, return.
  if (path == nil)
    {
      [self setNeedsDisplay: YES];
      return YES;
    }

  // Otherwise, decompose the path.
  subStrings = [path componentsSeparatedByString: _pathSeparator];
  numberOfSubStrings = [subStrings count];

  // Ignore a trailing void component. 
  if (numberOfSubStrings > 0
      && [[subStrings objectAtIndex: 0] isEqualToString: @""])
    {
      numberOfSubStrings--;

      if (numberOfSubStrings)
	{
	  NSRange theRange;

	  theRange.location = 1;
	  theRange.length = numberOfSubStrings;
	  subStrings = [subStrings subarrayWithRange: theRange];
	}

      [self loadColumnZero];
    }

  column = _lastColumnLoaded;
  if (column < 0)
    {
      column = 0;
    }

  // cycle thru str's array created from path
  for (i = 0; i < numberOfSubStrings; i++)
    {
      NSBrowserColumn	*bc = [_browserColumns objectAtIndex: column + i];
      NSMatrix		*matrix = [bc columnMatrix];
      NSArray		*cells = [matrix cells];
      unsigned		numOfRows = [cells count];
      NSBrowserCell	*selectedCell = nil;
      
      aStr = [subStrings objectAtIndex: i];

      if (![aStr isEqualToString: @""])
	{
	  found = NO;

	  // find the cell in the browser matrix which is equal to aStr
	  for (j = 0; j < numOfRows; j++)
	    {
	      NSString	*cellString;
	      
	      selectedCell = [cells objectAtIndex: j];
	      cellString = [selectedCell stringValue];
	      
	      if ([cellString isEqualToString: aStr])
		{
		  if ([_browserDelegate respondsToSelector:
			 @selector(browser:selectCellWithString:inColumn:)])
		    {
		      if ([_browserDelegate browser: self
			       selectCellWithString: [selectedCell stringValue]
					   inColumn: column+i])
			{
			  found = YES;
			}
		    }
		  else
		    {
		      [matrix selectCellAtRow: j column: 0];
		      found = YES;
		    }
		  break;
		}
	    }
	  // if unable to find a cell whose title matches aStr return NO
	  if (found == NO)
	    {
	      NSDebugLLog (@"NSBrowser", 
			   @"unable to find cell '%@' in column %d\n", 
			  aStr, column + i);
	      break;
	    }
	  // if the cell is a leaf, we are finished setting the path
	  if ([selectedCell isLeaf])
	    break;
	  
	  // else, it is not a leaf: add a column to the browser for it
	  [self addColumn];
	}
    }

  [self setNeedsDisplay: YES];
  
  return found;
}

/** Returns a string representing the path from the first column up to,
 but not including, the column at index column. */
- (NSString *) pathToColumn: (int)column
{
  NSMutableString	*s = [_pathSeparator mutableCopy];
  unsigned		i;
  NSString              *string;
  
  /*
   * Cannot go past the number of loaded columns
   */
  if (column > _lastColumnLoaded)
    {
      column = _lastColumnLoaded + 1;
    }

  for (i = 0; i < column; ++i)
    {
      id c = [self selectedCellInColumn: i];

      if (i != 0)
	{
	  [s appendString: _pathSeparator];
	}

      string = [c stringValue];
      
      if (string == nil)
	{
	  /* This should happen only when c == nil, in which case it
	     doesn't make sense to go with the path */
	  break;
	}
      else
	{
	  [s appendString: string];	  
	}
    }
  /*
   * We actually return a mutable string, but that's ok since a mutable
   * string is a string and the documentation specifically says that
   * people should not depend on methods that return strings to return
   * immutable strings.
   */

  return AUTORELEASE (s);
}

/** Returns the path separator. The default is "/". */
- (NSString *) pathSeparator
{
  return _pathSeparator;
}

/** Sets the path separator to newString. */
- (void) setPathSeparator: (NSString *)aString
{
  ASSIGN(_pathSeparator, aString);
}


/*
 * Manipulating columns 
 */
- (NSBrowserColumn *) _createColumn
{
  NSBrowserColumn *bc;
  NSScrollView *sc;
  NSRect rect = {{0, 0}, {100, 100}};

  bc = [[NSBrowserColumn alloc] init];

  // Create a scrollview
  sc = [[NSScrollView alloc]
	 initWithFrame: rect];
  [sc setHasHorizontalScroller: NO];
  [sc setHasVerticalScroller: YES];
  [bc setColumnScrollView: sc];
  [self addSubview: sc];
  RELEASE(sc);

  [_browserColumns addObject: bc];
  RELEASE(bc);

  return bc;
}

/** Adds a column to the right of the last column. */
- (void) addColumn
{
  int i;

  if (_lastColumnLoaded + 1 >= [_browserColumns count])
    {
      i = [_browserColumns indexOfObject: [self _createColumn]];
    }
  else
    {
      i = _lastColumnLoaded + 1;
    }

  if (i < 0)
    {
      i = 0;
    }

  [self _performLoadOfColumn: i];
  [self setLastColumn: i];

  _isLoaded = YES;

  [self tile];

  if (i > 0  &&  i - 1 == _lastVisibleColumn)
    {
      [self scrollColumnsRightBy: 1];
    }
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) becomeFirstResponder
{
  NSMatrix *matrix;
  int selectedColumn;

  selectedColumn = [self selectedColumn];
  if (selectedColumn == -1)
    matrix = [self matrixInColumn: 0];
  else
    matrix = [self matrixInColumn: selectedColumn];

  if (matrix)
    [_window makeFirstResponder: matrix];

  return YES;
}

/** Updates the NSBrowser to display all loaded columns. */
- (void) displayAllColumns
{
  [self tile];
}

/** Updates the NSBrowser to display the column with the given index. */
- (void) displayColumn: (int)column
{
  id bc, sc;

  // If not visible then nothing to display
  if ((column < _firstVisibleColumn) || (column > _lastVisibleColumn))
    {
      return;
    }

  [self tile];

  // Update and display title of column
  if (_isTitled)
    {
      [self lockFocus];
      [self drawTitleOfColumn: column
	    inRect: [self titleFrameOfColumn: column]];
      [self unlockFocus];
    }

  // Display column
  if (!(bc = [_browserColumns objectAtIndex: column]))
    return;
  if (!(sc = [bc columnScrollView]))
    return;

  /* FIXME: why the following ?  Are we displaying now, or marking for
   * later display ??  Given the name, I think we are displaying
   * now.  */
  [sc setNeedsDisplay: YES];
}

/** Returns the column number in which matrix is located. */
- (int) columnOfMatrix: (NSMatrix *)matrix
{
  int i, count;

  // Loop through columns and compare matrixes
  count = [_browserColumns count];
  for (i = 0; i < count; ++i)
    {
      if (matrix == [self matrixInColumn: i])
      	return i;
    }

  // Not found
  return -1;
}

/** Returns the index of the last column with a selected item. */
- (int) selectedColumn
{
  int i;
  id matrix;

  for (i = _lastColumnLoaded; i >= 0; i--)
    {
      if (!(matrix = [self matrixInColumn: i]))
      	continue;
      if ([matrix selectedCell])
      	return i;
    }
  
  return -1;
}

/** Returns the index of the last column loaded. */
- (int) lastColumn
{
  return _lastColumnLoaded;
}

/** Sets the last column to column. */
- (void) setLastColumn: (int)column
{
  int i, count, num;
  id bc, sc;

  if (column <= -1)
    {
      column = -1;
      _isLoaded = NO;
    }

  _lastColumnLoaded = column;
  // Unloads columns.
  count = [_browserColumns count];
  num = [self numberOfVisibleColumns];

  for (i = column + 1; i < count; ++i)
    {
      bc = [_browserColumns objectAtIndex: i];
      sc = [bc columnScrollView];

      if ([bc isLoaded])
	{
	  // Make the column appear empty by removing the matrix
	  if (sc)
	    {
	      [sc setDocumentView: nil];
	      [sc setNeedsDisplay: YES];
	    }
	  [bc setIsLoaded: NO];
	  [bc setColumnTitle: nil];
	}

      if (!_reusesColumns && i >= num)
	{
	  [sc removeFromSuperview];
	  [_browserColumns removeObject: bc];
	  count--;
	  i--;
	}
    }
  
  // Scroll if needed.
  if ((column < _lastVisibleColumn) && (_firstVisibleColumn > 0))
    {
      [self scrollColumnsLeftBy: _lastVisibleColumn - column];
    }
  else 
    {
      [self updateScroller];
      [self _setColumnTitlesNeedDisplay];
    }
}

/** Returns the index of the first visible column. */
- (int) firstVisibleColumn
{
  return _firstVisibleColumn;
}

/** Returns the number of columns visible. */
- (int) numberOfVisibleColumns
{
  int num;

  num = _lastVisibleColumn - _firstVisibleColumn + 1;

  return (num > 0 ? num : 1);
}

/** Returns the index of the last visible column. */
- (int) lastVisibleColumn
{
  return _lastVisibleColumn;
}

/** Invokes delegate method browser:isColumnValid: for visible columns. */
- (void) validateVisibleColumns
{
  int i;

  // If delegate doesn't care, just return
  if (![_browserDelegate respondsToSelector: 
			   @selector(browser:isColumnValid:)])
    {
      return;
    }

  // Loop through the visible columns
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
    {
      // Ask delegate if the column is valid and if not
      // then reload the column
      if (![_browserDelegate browser: self  isColumnValid: i])
	{
	  [self reloadColumn: i];
	}
    }
}


/*
 * Loading columns
 */

/** Returns whether column zero is loaded. */
- (BOOL) isLoaded
{
  return _isLoaded;
}

/** Loads column zero; unloads previously loaded columns. */
- (void) loadColumnZero
{
  // set last column loaded
  [self setLastColumn: -1];

  // load column 0
  [self addColumn];

  [self _remapColumnSubviews: YES];
  [self _setColumnTitlesNeedDisplay];
}

/** Reloads column if it is loaded; sets it as the last column. */
- (void) reloadColumn: (int)column
{
  NSArray *selectedCells;
  NSMatrix *matrix;
  int i, count, max;
  int *selectedIndexes = NULL;

  // Make sure the column even exists
  if (column > _lastColumnLoaded)
    return;

  // Save the index of the previously selected cells
  matrix = [self matrixInColumn: column];
  selectedCells = [matrix selectedCells];
  count = [selectedCells count];
  if (count > 0)
    {
      selectedIndexes = NSZoneMalloc (NSDefaultMallocZone (), 
				      sizeof (int) * count);
      for (i = 0; i < count; i++)
	{
	  NSCell *cell = [selectedCells objectAtIndex: i];
	  int sRow, sColumn;
	  
	  [matrix getRow: &sRow  column: &sColumn  ofCell: cell];
	  selectedIndexes[i] = sRow;
	}
    }
  
  // Perform the data load
  [self _performLoadOfColumn: column];
  // set last column loaded
  [self setLastColumn: column];

  // Restore the selected cells
  if (count > 0)
    {
      matrix = [self matrixInColumn: column];
      max = [matrix numberOfRows];
      for (i = 0; i < count; i++)
	{
	  // Abort when it stops making sense
	  if (selectedIndexes[i] > max)
	    {
	      break;
	    }
	  
	  [matrix selectCellAtRow: selectedIndexes[i]  column: 0];
	}
      NSZoneFree (NSDefaultMallocZone (), selectedIndexes);
    }
}


/*
 * Setting selection characteristics
 */

/** Returns whether the user can select branch items when multiple selection
    is enabled. */
- (BOOL) allowsBranchSelection
{
  return _allowsBranchSelection;
}

/** Sets whether the user can select branch items when multiple selection
    is enabled. */
- (void) setAllowsBranchSelection: (BOOL)flag
{
  _allowsBranchSelection = flag;
}

/** Returns whether there can be nothing selected. */
- (BOOL) allowsEmptySelection
{
  return _allowsEmptySelection;
}

/** Sets whether there can be nothing selected. */
- (void) setAllowsEmptySelection: (BOOL)flag
{
  _allowsEmptySelection = flag;
}

/** Returns whether the user can select multiple items. */
- (BOOL) allowsMultipleSelection
{
  return _allowsMultipleSelection;
}

/** Sets whether the user can select multiple items. */
- (void) setAllowsMultipleSelection: (BOOL)flag
{
  _allowsMultipleSelection = flag;
}


/*
 * Setting column characteristics
 */

/** Returns YES if NSMatrix objects aren't freed when their columns
    are unloaded. */
- (BOOL) reusesColumns
{
  return _reusesColumns;
}

/** If flag is YES, prevents NSMatrix objects from being freed when
    their columns are unloaded, so they can be reused. */
- (void) setReusesColumns: (BOOL)flag
{
  _reusesColumns = flag;
}

/** Returns the maximum number of visible columns. */
- (int) maxVisibleColumns
{
  return _maxVisibleColumns;
}

/** Sets the maximum number of columns displayed. */
- (void) setMaxVisibleColumns: (int)columnCount
{
  if ((columnCount < 1) || (_maxVisibleColumns == columnCount))
    return;

  _maxVisibleColumns = columnCount;

  // Redisplay
  [self tile];
}

/** Returns the minimum column width in pixels. */
- (int) minColumnWidth
{
  return _minColumnWidth;
}

/** Sets the minimum column width in pixels. */
- (void) setMinColumnWidth: (int)columnWidth
{
  float sw;

  sw = scrollerWidth;
  // Take the border into account
  if (_separatesColumns)
    sw += 2 * (_sizeForBorderType (NSBezelBorder)).width;

  // Column width cannot be less than scroller and border
  if (columnWidth < sw)
    _minColumnWidth = sw;
  else
    _minColumnWidth = columnWidth;

  [self tile];
}

/** Returns whether columns are separated by bezeled borders. */
- (BOOL) separatesColumns
{
  return _separatesColumns;
}

/** Sets whether to separate columns with bezeled borders. */
- (void) setSeparatesColumns: (BOOL)flag
{
  NSBrowserColumn *bc;
  NSScrollView    *sc;
  NSBorderType    bt;
  int             i, columnCount;

  // if this flag already set or browser is titled -- do nothing
  if (_separatesColumns == flag || _isTitled)
    return;

  columnCount = [_browserColumns count];
  bt = flag ? NSBezelBorder : NSNoBorder;
  for (i = 0; i < columnCount; i++)
    {
      bc = [_browserColumns objectAtIndex: i];
      sc = [bc columnScrollView];
      [sc setBorderType:bt];
    }

  _separatesColumns = flag;
  [self setNeedsDisplay:YES];
  [self tile];
}

/** Returns YES if the title of a column is set to the string value of 
    the selected NSCell in the previous column.*/
- (BOOL) takesTitleFromPreviousColumn
{
  return _takesTitleFromPreviousColumn;
}

/** Sets whether the title of a column is set to the string value of the
    selected NSCell in the previous column. */
- (void) setTakesTitleFromPreviousColumn: (BOOL)flag
{
  if (_takesTitleFromPreviousColumn != flag)
    {
      _takesTitleFromPreviousColumn = flag;
      [self setNeedsDisplay: YES];
    }
}


/*
 * Manipulating column titles
 */

/** Returns the title displayed for the column at index column. */
- (NSString *) titleOfColumn: (int)column
{
  NSBrowserColumn *bc;

  bc = [_browserColumns objectAtIndex: column];

  return bc->_columnTitle;
}

/** Sets the title of the column at index column to aString. */
- (void) setTitle: (NSString *)aString
	 ofColumn: (int)column
{
  NSBrowserColumn *bc;

  bc = [_browserColumns objectAtIndex: column];

  [bc setColumnTitle: aString];
  
  // If column is not visible then nothing to redisplay
  if (!_isTitled || !NSBR_COLUMN_IS_VISIBLE(column))
    return;
  
  [self setNeedsDisplayInRect: [self titleFrameOfColumn: column]];
}

/** Returns whether columns display titles. */
- (BOOL) isTitled
{
  return _isTitled;
}

/** Sets whether columns display titles. */
- (void) setTitled: (BOOL)flag
{
  if (_isTitled == flag || !_separatesColumns)
    return;
  
  _isTitled = flag;
  [self tile];
  [self setNeedsDisplay: YES];
}

- (void) drawTitleOfColumn: (int)column 
		    inRect: (NSRect)aRect
{
  [self drawTitle: [self titleOfColumn: column] 
	inRect: aRect 
	ofColumn: column];
}

/** Draws the title for the column at index column within the rectangle
    defined by aRect. */
- (void) drawTitle: (NSString *)title
	    inRect: (NSRect)aRect
	  ofColumn: (int)column
{
  if (!_isTitled || !NSBR_COLUMN_IS_VISIBLE(column))
    return;

  [titleCell setStringValue: title];
  [titleCell drawWithFrame: aRect inView: self];
}

/** Returns the height of column titles.  */
- (float) titleHeight
{
  // Nextish look requires 21 here
  return 21;
}

/** Returns the bounds of the title frame for the column at index column. */
- (NSRect) titleFrameOfColumn: (int)column
{
  // Not titled then no frame
  if (!_isTitled)
    {
      return NSZeroRect;
    }
  else
    {
      // Number of columns over from the first
      int n = column - _firstVisibleColumn;
      int h = [self titleHeight];
      NSRect r;

      // Calculate origin
      if (_separatesColumns)
	{
	  r.origin.x = n * (_columnSize.width + NSBR_COLUMN_SEP);
	}
      else
	{
	  r.origin.x = n * _columnSize.width;
	}
      r.origin.y = _frame.size.height - h;
      
      // Calculate size
      if (column == _lastVisibleColumn)
	{
	  r.size.width = _frame.size.width - r.origin.x;
	}
      else
	{
	  r.size.width = _columnSize.width;
	}
      r.size.height = h;

      return r;
    }
}


/*
 * Scrolling an NSBrowser
 */

/** Scrolls to make the column at index column visible. */
- (void) scrollColumnToVisible: (int)column
{
  // If there are not enough columns to scroll with
  // then the column must be visible
  if (_lastColumnLoaded + 1 <= [self numberOfVisibleColumns])
    return;

  // If its the last visible column then we are there already
  if (_lastVisibleColumn < column)
    {
      [self scrollColumnsRightBy: (column - _lastVisibleColumn)];
    } 
  else if (_firstVisibleColumn > column)
    {
      [self scrollColumnsLeftBy: (_firstVisibleColumn - column)];
    } 
}

/** Scrolls columns left by shiftAmount columns. */
- (void) scrollColumnsLeftBy: (int)shiftAmount
{
  // Cannot shift past the zero column
  if ((_firstVisibleColumn - shiftAmount) < 0)
    shiftAmount = _firstVisibleColumn;

  // No amount to shift then nothing to do
  if (shiftAmount <= 0)
    return;

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserWillScroll:)])
    [_browserDelegate browserWillScroll: self];

  // Shift
  _firstVisibleColumn = _firstVisibleColumn - shiftAmount;
  _lastVisibleColumn = _lastVisibleColumn - shiftAmount;

  // Update the scroller
  [self updateScroller];

  // Update the scrollviews
  [self tile];
  [self _remapColumnSubviews: YES];
  [self _setColumnTitlesNeedDisplay];

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserDidScroll:)])
    [_browserDelegate browserDidScroll: self];  
}

/** Scrolls columns right by shiftAmount columns. */
- (void) scrollColumnsRightBy: (int)shiftAmount
{
  // Cannot shift past the last loaded column
  if ((shiftAmount + _lastVisibleColumn) > _lastColumnLoaded)
    shiftAmount = _lastColumnLoaded - _lastVisibleColumn;

  // No amount to shift then nothing to do
  if (shiftAmount <= 0)
    return;

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserWillScroll:)])
    [_browserDelegate browserWillScroll: self];

  // Shift
  _firstVisibleColumn = _firstVisibleColumn + shiftAmount;
  _lastVisibleColumn = _lastVisibleColumn + shiftAmount;

  // Update the scroller
  [self updateScroller];

  // Update the scrollviews
  [self tile];
  [self _remapColumnSubviews: NO];
  [self _setColumnTitlesNeedDisplay];

  // Notify the delegate
  if ([_browserDelegate respondsToSelector: @selector(browserDidScroll:)])
    [_browserDelegate browserDidScroll: self];
}

/** Updates the horizontal scroller to reflect column positions. */
- (void) updateScroller
{
  int num;

  num = [self numberOfVisibleColumns];

  // If there are not enough columns to scroll with
  // then the column must be visible
  if ((_lastColumnLoaded == 0) ||
      (_lastColumnLoaded <= (num - 1)))
    {
      [_horizontalScroller setEnabled: NO];
    }
  else
    {
      if (!_skipUpdateScroller)
      	{
      	  float prop = (float)num / (float)(_lastColumnLoaded + 1);
      	  float i = _lastColumnLoaded - num + 1;
      	  float f = 1 + ((_lastVisibleColumn - _lastColumnLoaded) / i);

          [_horizontalScroller setFloatValue: f knobProportion: prop];
	}
      [_horizontalScroller setEnabled: YES];
    }

  [_horizontalScroller setNeedsDisplay: YES];
}

/** Scrolls columns left or right based on an NSScroller. */
- (void) scrollViaScroller: (NSScroller *)sender
{
  NSScrollerPart hit;

  if ([sender class] != [NSScroller class])
    return;
  
  hit = [sender hitPart];
  
  switch (hit)
    {
      // Scroll to the left
      case NSScrollerDecrementLine:
      case NSScrollerDecrementPage:
      	[self scrollColumnsLeftBy: 1];
      	break;
      
      // Scroll to the right
      case NSScrollerIncrementLine:
      case NSScrollerIncrementPage:
        [self scrollColumnsRightBy: 1];
      	break;
      
      // The knob or knob slot
      case NSScrollerKnob:
      case NSScrollerKnobSlot:
	{
	  float f = [sender floatValue];

	  _skipUpdateScroller = YES;
	  [self scrollColumnToVisible: rintf(f * _lastColumnLoaded)];
	  _skipUpdateScroller = NO;
	}
      	break;
      
      // NSScrollerNoPart ???
      default:
      	break;
    }
}


/*
 * Showing a horizontal scroller
 */

/** Returns whether an NSScroller is used to scroll horizontally. */
- (BOOL) hasHorizontalScroller
{
  return _hasHorizontalScroller;
}

/** Sets whether an NSScroller is used to scroll horizontally. */
- (void) setHasHorizontalScroller: (BOOL)flag
{
  if (_hasHorizontalScroller != flag)
    {
      _hasHorizontalScroller = flag;
      if (!flag)
      	[_horizontalScroller removeFromSuperview];
      else
        [self addSubview: _horizontalScroller];
      [self tile];
      [self setNeedsDisplay: YES];
    }
}


/*
 * Setting the behavior of arrow keys
 */

/** Returns YES if the arrow keys are enabled. */
- (BOOL) acceptsArrowKeys
{
  return _acceptsArrowKeys;
}

/** Enables or disables the arrow keys as used for navigating within
    and between browsers. */
- (void) setAcceptsArrowKeys: (BOOL)flag
{
  _acceptsArrowKeys = flag;
}

/** Returns NO if pressing an arrow key only scrolls the browser, YES if
    it also sends the action message specified by setAction:. */
- (BOOL) sendsActionOnArrowKeys
{
  return _sendsActionOnArrowKeys;
}

/** Sets whether pressing an arrow key will cause the action message
 to be sent (in addition to causing scrolling). */
- (void) setSendsActionOnArrowKeys: (BOOL)flag
{
  _sendsActionOnArrowKeys = flag;
}


/*
 * Getting column frames
 */

/** Returns the rectangle containing the column at index column. */
- (NSRect) frameOfColumn: (int)column
{
  NSRect r = NSZeroRect;
  NSSize bs = _sizeForBorderType (NSBezelBorder);
  int n;

  // Number of columns over from the first
  n = column - _firstVisibleColumn;

  // Calculate the frame
  r.size = _columnSize;
  r.origin.x = n * _columnSize.width;

  if (_separatesColumns)
    {
      r.origin.x += n * NSBR_COLUMN_SEP;
    }
  else
    {
      if (column == _firstVisibleColumn)
        r.origin.x = (n * _columnSize.width) + 2;
      else
	r.origin.x = (n * _columnSize.width) + (n + 2);
    }

  // Adjust for horizontal scroller
  if (_hasHorizontalScroller)
    {
      if (_separatesColumns)
 	r.origin.y = (scrollerWidth - 1) + (2 * bs.height) + NSBR_VOFFSET;
      else
	r.origin.y = scrollerWidth + bs.width;
    }

  // Padding : _columnSize.width is rounded in "tile" method
  if (column == _lastVisibleColumn)
    {
      if (_separatesColumns)
	r.size.width = _frame.size.width - r.origin.x;
      else
	r.size.width = _frame.size.width 
	  - (r.origin.x + (2 * bs.width) + ([self numberOfVisibleColumns] - 1));
    }

  if (r.size.width < 0)
    {
      r.size.width = 0;
    }
  if (r.size.height < 0)
    {
      r.size.height = 0;
    }

  return r;
}

/** Returns the rectangle containing the column at index column, */
// not including borders.
- (NSRect) frameOfInsideOfColumn: (int)column
{
  // xxx what does this one do?
  return [self frameOfColumn: column];
}


/*
 * Arranging browser components
 */

/** Adjusts the various subviews of NSBrowser-scrollers, columns,
 titles, and so on-without redrawing. Your code shouldn't send this
 message.  It's invoked any time the appearance of the NSBrowser
 changes. */
- (void) tile
{
  NSSize bs = _sizeForBorderType (NSBezelBorder);
  int i, num, columnCount, delta;
  float  frameWidth;

  _columnSize.height = _frame.size.height;
  
  // Titles (there is no real frames to resize)
  if (_isTitled)
    {
      _columnSize.height -= [self titleHeight] + NSBR_VOFFSET;
    }

  // Horizontal scroller
  if (_hasHorizontalScroller)
    {
      _scrollerRect.origin.x = bs.width;
      _scrollerRect.origin.y = bs.height - 1;
      _scrollerRect.size.width = (_frame.size.width - (2 * bs.width)) + 1;
      _scrollerRect.size.height = scrollerWidth;
      
      if (_separatesColumns)
	_columnSize.height -= (scrollerWidth - 1) + (2 * bs.height) 
	  + NSBR_VOFFSET;
      else
	_columnSize.height -= scrollerWidth + (2 * bs.height);
      
      if (!NSEqualRects(_scrollerRect, [_horizontalScroller frame]))
        {
          [_horizontalScroller setFrame: _scrollerRect];
        }
    }
  else
    {
      _scrollerRect = NSZeroRect;
    }

  num = _lastVisibleColumn - _firstVisibleColumn + 1;

  if (_minColumnWidth > 0)
    {
      float colWidth = _minColumnWidth + scrollerWidth;

      if ((int)(_frame.size.width > _minColumnWidth))
	{
	  if (_separatesColumns)
	    colWidth += NSBR_COLUMN_SEP;

	  columnCount = (int)(_frame.size.width / colWidth);
	}
      else
	columnCount = 1;
    }
  else
    columnCount = num;

  if (_maxVisibleColumns > 0 && columnCount > _maxVisibleColumns)
    columnCount = _maxVisibleColumns;

  if (columnCount != num)
    {
      if (num > 0)
	delta = columnCount - num;
      else
	delta = columnCount - 1;

      if ((delta > 0) && (_lastVisibleColumn <= _lastColumnLoaded))
	{
	  _firstVisibleColumn = (_firstVisibleColumn - delta > 0) ?
	    _firstVisibleColumn - delta : 0;
	}

      for (i = [_browserColumns count]; i < columnCount; i++)
	[self _createColumn];

      _lastVisibleColumn = _firstVisibleColumn + columnCount - 1;
    }

  // Columns
  if (_separatesColumns)
    frameWidth = _frame.size.width - ((columnCount - 1) * NSBR_COLUMN_SEP);
  else
    frameWidth = _frame.size.width - (columnCount + (2 * bs.width));

  _columnSize.width = (int)(frameWidth / (float)columnCount);

  if (_columnSize.height < 0)
    _columnSize.height = 0;
  
  for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
    {
      id bc, sc;
      id matrix;

      bc = [_browserColumns objectAtIndex: i];

      if (!(sc = [bc columnScrollView]))
	{
	  NSLog(@"NSBrowser error, sc != [bc columnScrollView]");
	  return;
	}

      [sc setFrame: [self frameOfColumn: i]];
      matrix = [bc columnMatrix];
      
      // Adjust matrix to fit in scrollview if column has been loaded
      if (matrix && [bc isLoaded])
        {
	  NSSize cs, ms;
	  
	  cs = [sc contentSize];
	  ms = [matrix cellSize];
	  ms.width = cs.width;
	  [matrix setCellSize: ms];
	  [sc setDocumentView: matrix];
	}
    }

  if (columnCount != num)
    {
      [self updateScroller];
      [self _remapColumnSubviews: YES];
      //      [self _setColumnTitlesNeedDisplay];  
      [self setNeedsDisplay: YES];
    }
}


/*
 * Setting the delegate
 */

/** Returns the NSBrowser's delegate. */
- (id) delegate
{
  return _browserDelegate;
}

/** Sets the NSBrowser's delegate to anObject.  Raises
 NSBrowserIllegalDelegateException if the delegate specified by
 anObject doesn't respond to browser:willDisplayCell:atRow:column: (if
 passive) and either of the methods browser:numberOfRowsInColumn: or
 browser:createRowsForColumn:inMatrix:. */
- (void) setDelegate: (id)anObject
{
  BOOL flag = NO;

  if ([anObject respondsToSelector: 
		  @selector(browser:numberOfRowsInColumn:)])
    {
      _passiveDelegate = YES;
      flag = YES;
      if (![anObject respondsToSelector: 
			 @selector(browser:willDisplayCell:atRow:column:)])
	[NSException raise: NSBrowserIllegalDelegateException
		     format: @"(Passive) Delegate does not respond to %s\n",
		     "browser: willDisplayCell: atRow: column: "];
    }

  if ([anObject respondsToSelector: 
		  @selector(browser:createRowsForColumn:inMatrix:)])
    {
      _passiveDelegate = NO;

      // If flag is already set
      // then delegate must respond to both methods
      if (flag)
        {
	  [NSException raise: NSBrowserIllegalDelegateException
		       format: @"Delegate responds to both %s and %s\n",
		       "browser: numberOfRowsInColumn: ",
		       "browser: createRowsForColumn: inMatrix: "];
	}

      flag = YES;
    }

  if (!flag)
    [NSException raise: NSBrowserIllegalDelegateException
		 format: @"Delegate does not respond to %s or %s\n",
		 "browser: numberOfRowsInColumn: ",
		 "browser: createRowsForColumn: inMatrix: "];

  _browserDelegate = anObject;
}


/*
 * Target and action
 */

/** Returns the NSBrowser's double-click action method. */
- (SEL) doubleAction
{
  return _doubleAction;
}

/** Sets the NSBrowser's double-click action to aSelector. */
- (void) setDoubleAction: (SEL)aSelector
{
  _doubleAction = aSelector;
}

/** Sends the action message to the target. Returns YES upon success, 
    NO if no target for the message could be found. */
- (BOOL) sendAction
{
  return [self sendAction: [self action]  to: [self target]];
}


/*
 * Event handling
 */

/** Responds to (single) mouse clicks in a column of the NSBrowser. */
- (void) doClick: (id)sender
{
  NSArray        *a;
  NSMutableArray *selectedCells;
  NSEnumerator   *enumerator;
  NSBrowserCell  *cell;
  int             row, column, aCount, selectedCellsCount;

  if ([sender class] != _browserMatrixClass)
    return;

  column = [self columnOfMatrix: sender];
  // If the matrix isn't ours then just return
  if (column == -1)
    return;

  a = [sender selectedCells];
  aCount = [a count];
  if(aCount == 0)
    return;

  selectedCells = [a mutableCopy];

  enumerator = [a objectEnumerator];
  while ((cell = [enumerator nextObject]))
    {
      if (_allowsBranchSelection == NO && [cell isLeaf] == NO)
	{
	  [selectedCells removeObject: cell];
	}
    }

  if ([selectedCells count] == 0)
    [selectedCells addObject: [sender selectedCell]];

  selectedCellsCount = [selectedCells count];

  if (selectedCellsCount == 0)
    {
      // If we should not select the cell
      // then deselect it and return

      [sender deselectAllCells];
      RELEASE(selectedCells);
      return;
    }
  else if (selectedCellsCount < aCount)
    {
      [sender deselectSelectedCell];

      enumerator = [selectedCells objectEnumerator];
      while ((cell = [enumerator nextObject]))
	[sender selectCell: cell];

      // FIXME: shouldn't be locking focus on another object
      // probably all this loop is wrong, because deselectSelectedCell
      // above may have changed array a.
      [sender lockFocus];

      enumerator = [a objectEnumerator];
      while ((cell = [enumerator nextObject]))
	{
	  if ([selectedCells containsObject: cell] == NO)
	    {
	      if (![sender getRow: &row column: NULL ofCell: cell])
		continue;

	      if ([cell isHighlighted])
		[sender highlightCell: NO atRow: row column: 0];
	      else
		[sender drawCellAtRow: row column: 0];
	    }
	}
      [sender unlockFocus];
      [self displayIfNeeded];
      [_window flushWindow];
    }

  if (selectedCellsCount > 0)
    {
      // Single selection
      if (selectedCellsCount == 1)
      	{
      	  cell = [selectedCells objectAtIndex: 0];
	  
	  // If the cell is a leaf
	  // then unload the columns after
	  if ([cell isLeaf])
	    [self setLastColumn: column];
	  // The cell is not a leaf so we need to load a column
	  else
	    {
	      int count = [_browserColumns count];

	      if (column < count - 1)
		  [self setLastColumn: column];

	      [self addColumn];
	    }

	  [sender scrollCellToVisibleAtRow: [sender selectedRow]
		  column: column];
	}
      // Multiple selection
      else
	{
	  [self setLastColumn: column];
	}
    }

  // Send the action to target
  [self sendAction];

  RELEASE(selectedCells);
}

/** Responds to double-clicks in a column of the NSBrowser. */
- (void) doDoubleClick: (id)sender
{
  // We have already handled the single click
  // so send the double action

  [self sendAction: _doubleAction to: [self target]];
}

+ (void) initialize
{
  if (self == [NSBrowser class])
    {
      // Initial version
      [self setVersion: 1];
      scrollerWidth = [NSScroller scrollerWidth];
      titleCell = [GSBrowserTitleCell new];
    }
}

/*
 * Override superclass methods
 */

/** Setups browser with frame 'rect'. */
- (id) initWithFrame: (NSRect)rect
{
  NSSize bs;
  //NSScroller *hs;

  self = [super initWithFrame: rect];

  // Class setting
  _browserCellPrototype = [[[NSBrowser cellClass] alloc] init];
  _browserMatrixClass = [NSMatrix class];
  
  // Default values
  _pathSeparator = @"/";
  _allowsBranchSelection = YES;
  _allowsEmptySelection = YES;
  _allowsMultipleSelection = YES;
  _reusesColumns = NO;
  _separatesColumns = YES;
  _isTitled = YES;
  _takesTitleFromPreviousColumn = YES;
  _hasHorizontalScroller = YES;
  _isLoaded = NO;
  _acceptsArrowKeys = YES;
  _acceptsAlphaNumericalKeys = YES;
  _lastKeyPressed = 0.;
  _charBuffer = nil;
  _sendsActionOnArrowKeys = YES;
  _sendsActionOnAlphaNumericalKeys = YES;
  _browserDelegate = nil;
  _passiveDelegate = YES;
  _doubleAction = NULL;  
  bs = _sizeForBorderType (NSBezelBorder);
  _minColumnWidth = scrollerWidth + (2 * bs.width);
  if (_minColumnWidth < 100.0)
    _minColumnWidth = 100.0;

  // Horizontal scroller
  _scrollerRect.origin.x = bs.width;
  _scrollerRect.origin.y = bs.height;
  _scrollerRect.size.width = _frame.size.width - (2 * bs.width);
  _scrollerRect.size.height = scrollerWidth;
  _horizontalScroller = [[NSScroller alloc] initWithFrame: _scrollerRect];
  [_horizontalScroller setTarget: self];
  [_horizontalScroller setAction: @selector(scrollViaScroller:)];
  [self addSubview: _horizontalScroller];
  _skipUpdateScroller = NO;

  // Columns
  _browserColumns = [[NSMutableArray alloc] init];

  // Create a single column
  _lastColumnLoaded = -1;
  _firstVisibleColumn = 0;
  _lastVisibleColumn = 0;
  _maxVisibleColumns = 3;
  [self _createColumn];

  return self;
}

- (void) dealloc
{
  RELEASE(_browserCellPrototype);
  RELEASE(_pathSeparator);
  RELEASE(_horizontalScroller);
  RELEASE(_browserColumns);
  TEST_RELEASE(_charBuffer);

  [super dealloc];
}



/*
 * Target-actions
 */

/** Set target to 'target' */
- (void) setTarget: (id)target
{
  _target = target;
}

/** Return current target. */
- (id) target
{
  return _target;
}

/** Set action to 's'. */
- (void) setAction: (SEL)s
{
  _action = s;
}

/** Return current action. */
- (SEL) action
{
  return _action;
}



/*
 * Events handling 
 */

- (void) drawRect: (NSRect)rect
{
  NSRectClip(rect);
  [[_window backgroundColor] set];
  NSRectFill(rect);

  // Load the first column if not already done
  if (!_isLoaded)
    {
      [self loadColumnZero];
    }

  // Draws titles
  if (_isTitled)
    {
      int i;

      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; ++i)
	{
	  NSRect titleRect = [self titleFrameOfColumn: i];
	  if (NSIntersectsRect (titleRect, rect) == YES)
	    {
	      [self drawTitleOfColumn: i
		    inRect: titleRect];
	    }
	}
    }

  // Draws scroller border
  if (_hasHorizontalScroller)
    {
      NSRect scrollerBorderRect = _scrollerRect;
      NSSize bs = _sizeForBorderType (NSBezelBorder);

      scrollerBorderRect.origin.x = 0;
      scrollerBorderRect.origin.y = 0;
      scrollerBorderRect.size.width += 2 * bs.width - 1;
      scrollerBorderRect.size.height += (2 * bs.height) - 1;

      if ((NSIntersectsRect (scrollerBorderRect, rect) == YES) && _window)
      	{
      	  NSDrawGrayBezel (scrollerBorderRect, rect);
	}
    }

  if (!_separatesColumns)
    {
      NSPoint p1,p2;
      NSRect  browserRect;
      int     i, visibleColumns;
      
      // Columns borders
      browserRect = NSMakeRect(0, 0, rect.size.width, rect.size.height);
      NSDrawGrayBezel (browserRect, rect);
      
      [[NSColor blackColor] set];
      visibleColumns = [self numberOfVisibleColumns]; 
      for (i = 1; i < visibleColumns; i++)
	{
	  p1 = NSMakePoint((_columnSize.width * i) + 2 + (i-1), 
			   _columnSize.height + scrollerWidth + 2);
	  p2 = NSMakePoint((_columnSize.width * i) + 2 + (i-1), scrollerWidth + 3);
	  [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
	}
      
      // Horizontal scroller border
      p1 = NSMakePoint(2, scrollerWidth + 2);
      p2 = NSMakePoint(rect.size.width - 2, scrollerWidth + 2);
      [NSBezierPath strokeLineFromPoint: p1 toPoint: p2];
    }
}

/* Informs the receivers's subviews that the receiver's bounds
 rectangle size has changed from oldFrameSize. */
- (void) resizeSubviewsWithOldSize: (NSSize)oldSize
{
  [self tile];
}


/* Override NSControl handler (prevents highlighting). */
- (void) mouseDown: (NSEvent *)theEvent
{
}

- (void) moveLeft: (id)sender
{
  if (_acceptsArrowKeys)
    {
      NSMatrix *matrix;
      NSCell   *selectedCell;
      int       selectedRow, selectedColumn;

      selectedColumn = [self selectedColumn];
      if (selectedColumn > 0)
	{
	  matrix = [self matrixInColumn: selectedColumn];
	  selectedCell = [matrix selectedCell];
	  selectedRow = [matrix selectedRow];

	  [matrix deselectAllCells];

	  if(selectedColumn+1 <= [self lastColumn])
	    [self setLastColumn: selectedColumn];

	  matrix = [self matrixInColumn: [self selectedColumn]];
	  [_window makeFirstResponder: matrix];

	  if (_sendsActionOnArrowKeys == YES)
	    [super sendAction: _action to: _target];
	}
    }
}

- (void) moveRight: (id)sender
{
  if (_acceptsArrowKeys)
    {
      NSMatrix *matrix;
      BOOL      selectFirstRow = NO;
      int       selectedColumn;

      selectedColumn = [self selectedColumn];
      if (selectedColumn == -1)
	{
	  matrix = [self matrixInColumn: 0];

	  if ([[matrix cells] count])
	    {
	      [matrix selectCellAtRow: 0 column: 0];
	      [_window makeFirstResponder: matrix];
	      [self doClick: matrix];
	      selectedColumn = 0;
	    }
	}
      else
	{
	  matrix = [self matrixInColumn: selectedColumn];

	  if (![[matrix selectedCell] isLeaf]
	      && [[matrix selectedCells] count] == 1)
	    selectFirstRow = YES;
	}

      if(selectFirstRow == YES)
	{
	  matrix = [self matrixInColumn: [self lastColumn]];
	  if ([[matrix cells] count])
	    {
	      [matrix selectCellAtRow: 0 column: 0];
	      [_window makeFirstResponder: matrix];
	      [self doClick: matrix];
	    }
	}

      if (_sendsActionOnArrowKeys == YES)
	[super sendAction: _action to: _target];
    }
}

- (void) keyDown: (NSEvent *)theEvent
{
  NSString *characters = [theEvent characters];
  unichar character = 0;

  if ([characters length] > 0)
    {
      character = [characters characterAtIndex: 0];
    }

  if (_acceptsArrowKeys)
    {
      switch (character)
	{
	case NSUpArrowFunctionKey:
	case NSDownArrowFunctionKey:
	  return;
	case NSLeftArrowFunctionKey:
	  [self moveLeft:self];
	  return;
	case NSRightArrowFunctionKey:
	  [self moveRight:self];
	  return;
	case NSTabCharacter:
	  {
	    if ([theEvent modifierFlags] & NSShiftKeyMask)
	      {
		[_window selectKeyViewPrecedingView: self];
	      }
	    else
	      {
		[_window selectKeyViewFollowingView: self];
	      }
	  }
	  return;
	  break;
	}
    }

  if (_acceptsAlphaNumericalKeys && (character < 0xF700)
       && ([characters length] > 0))
    {
      NSMatrix *matrix;
      NSString *sv;
      int i, n, s;
      int selectedColumn;
      SEL lcarcSel = @selector(loadedCellAtRow:column:);
      IMP lcarc = [self methodForSelector: lcarcSel];
      
      selectedColumn = [self selectedColumn];
      if(selectedColumn != -1)
	{
	  matrix = [self matrixInColumn: selectedColumn];
	  n = [matrix numberOfRows];
	  s = [matrix selectedRow];
	  
	  if (!_charBuffer)
	    {
	      _charBuffer = [characters substringToIndex: 1];
	      RETAIN(_charBuffer);
	    }
	  else
	    {
	      if (([theEvent timestamp] - _lastKeyPressed < 2000.0)
		  && (_alphaNumericalLastColumn == selectedColumn))
		{
		  NSString *transition;
		  transition = [_charBuffer 
				 stringByAppendingString:
				   [characters substringToIndex: 1]];
		  RELEASE(_charBuffer);
		  _charBuffer = transition;
		  RETAIN(_charBuffer);
		}
	      else
		{
		  RELEASE(_charBuffer);
		  _charBuffer = [characters substringToIndex: 1];
		  RETAIN(_charBuffer);
		}
	    }
	  
	  _alphaNumericalLastColumn = selectedColumn;
	  _lastKeyPressed = [theEvent timestamp];
	  
	  sv = [((*lcarc)(self, lcarcSel, s, selectedColumn))
		 stringValue];

	  if (([sv length] > 0)
	      && ([sv hasPrefix: _charBuffer]))
	    return;
	  
	  for (i = s+1; i < n; i++)
	    {
	      sv = [((*lcarc)(self, lcarcSel, i, selectedColumn))
		     stringValue];
	      if (([sv length] > 0)
		  && ([sv hasPrefix: _charBuffer]))
		{
		  [self selectRow: i
			inColumn: selectedColumn];	
		  [matrix scrollCellToVisibleAtRow: i column: 0];
		  [matrix performClick: self];
		  return;
		}
	    }
	  for (i = 0; i < s; i++)
	    {
	      sv = [((*lcarc)(self, lcarcSel, i, selectedColumn))
		     stringValue];
	      if (([sv length] > 0)
		  && ([sv hasPrefix: _charBuffer]))
		{
		  [self selectRow: i
			inColumn: selectedColumn];
		  [matrix scrollCellToVisibleAtRow: i column: 0];
		  [matrix performClick: self];
		  return;
		}
	    }
	}
      _lastKeyPressed = 0.;
    }

  [super keyDown: theEvent];
}

/*
 * NSCoding protocol
 *
 * We do not encode most of the instance variables except the Browser columns
 * because they are internal objects (though not transportable). So we just
 * encode enoguh information to rebuild identical columns on the decoder
 * side. Same for the Horizontal Scroller
 */

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  // Here to keep compatibility with old version
  [aCoder encodeObject: nil];
  [aCoder encodeObject:_browserCellPrototype];
  [aCoder encodeObject: NSStringFromClass (_browserMatrixClass)];

  [aCoder encodeObject:_pathSeparator];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsBranchSelection];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsEmptySelection];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsMultipleSelection];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_maxVisibleColumns];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_minColumnWidth];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_reusesColumns];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_separatesColumns];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_takesTitleFromPreviousColumn];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_isTitled];

 
  [aCoder encodeObject:_horizontalScroller];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_hasHorizontalScroller];
  [aCoder encodeRect: _scrollerRect];
  [aCoder encodeSize: _columnSize];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_acceptsArrowKeys];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_sendsActionOnArrowKeys];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_acceptsAlphaNumericalKeys];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_sendsActionOnAlphaNumericalKeys];

  [aCoder encodeConditionalObject:_browserDelegate];

  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_doubleAction];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];

  [aCoder encodeObject: _browserColumns];

  // Just encode the number of columns and the first visible
  // and rebuild the browser columns on the decoding side
  {
    int colCount = [_browserColumns count];  
    [aCoder encodeValueOfObjCType: @encode(int) at: &colCount];
    [aCoder encodeValueOfObjCType: @encode(int) at: &_firstVisibleColumn];
  }

}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  int colCount;
  id dummy;

  [super initWithCoder: aDecoder];
  // Here to keep compatibility with old version
  dummy = [aDecoder decodeObject];
  _browserCellPrototype = RETAIN([aDecoder decodeObject]);
  _browserMatrixClass   = NSClassFromString ((NSString *)[aDecoder decodeObject]);

  [self setPathSeparator: [aDecoder decodeObject]];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isLoaded];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsBranchSelection];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsEmptySelection];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsMultipleSelection];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_maxVisibleColumns];
  [aDecoder decodeValueOfObjCType: @encode(float) at: &_minColumnWidth];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_reusesColumns];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_separatesColumns];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_takesTitleFromPreviousColumn];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_isTitled];

  //NSBox *_horizontalScrollerBox;
  _horizontalScroller = RETAIN([aDecoder decodeObject]);
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_hasHorizontalScroller];
  _scrollerRect = [aDecoder decodeRect];
  _columnSize = [aDecoder decodeSize];

  _skipUpdateScroller = NO;
  /*
  _horizontalScroller = [[NSScroller alloc] initWithFrame: _scrollerRect];
  [_horizontalScroller setTarget: self];
  [_horizontalScroller setAction: @selector(scrollViaScroller:)];
  */
  [self setHasHorizontalScroller: _hasHorizontalScroller];

  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_acceptsArrowKeys];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_sendsActionOnArrowKeys];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_acceptsAlphaNumericalKeys];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_sendsActionOnAlphaNumericalKeys];
  _lastKeyPressed = 0;
  _charBuffer = nil;
  // Skip: int _alphaNumericalLastColumn;

  _browserDelegate = [aDecoder decodeObject];
  if (_browserDelegate != nil)
    [self setDelegate:_browserDelegate];
  else
    _passiveDelegate = YES;


  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_doubleAction];
  _target = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
  

  // Do the minimal thing to initiate the browser...
  /*
  _lastColumnLoaded = -1;
  _firstVisibleColumn = 0;
  _lastVisibleColumn = 0;
  [self _createColumn];
  */
  _browserColumns = RETAIN([aDecoder decodeObject]);
  // ..and rebuild any existing browser columns
  [aDecoder decodeValueOfObjCType: @encode(int) at: &colCount];
  [aDecoder decodeValueOfObjCType: @encode(int) at: &_firstVisibleColumn];

  // Display even if there isn't any column
  _isLoaded = NO;
  [self tile];
  return self;
}



/*
 * Div.
 */

- (BOOL) isOpaque
{
  return YES; // See drawRect.
}

@end

@implementation NSBrowser (GNUstepExtensions)
/*
 * Setting the behavior of arrow keys
 */

/** Returns YES if the alphanumerical keys are enabled. */
- (BOOL) acceptsAlphaNumericalKeys
{
  return _acceptsAlphaNumericalKeys;
}

/** Enables or disables the arrow keys as used for navigating within
    and between browsers. */
- (void) setAcceptsAlphaNumericalKeys: (BOOL)flag
{
  _acceptsAlphaNumericalKeys = flag;
}

/** Returns NO if pressing an arrow key only scrolls the browser, YES if 
    it also sends the action message specified by setAction:. */
- (BOOL) sendsActionOnAlphaNumericalKeys
{
  return _sendsActionOnAlphaNumericalKeys;
}

/** Sets whether pressing an arrow key will cause the action message 
    to be sent (in addition to causing scrolling). */
- (void) setSendsActionOnAlphaNumericalKeys: (BOOL)flag
{
  _sendsActionOnAlphaNumericalKeys = flag;
}

@end


/*
 *
 *  PRIVATE METHODS
 *
 */
@implementation NSBrowser (Private)

- (void) _remapColumnSubviews: (BOOL)fromFirst
{
  id bc, sc;
  int i, count;
  id firstResponder = nil;
  BOOL setFirstResponder = NO;

  // Removes all column subviews.
  count = [_browserColumns count];
  for (i = 0; i < count; i++)
    {
      bc = [_browserColumns objectAtIndex: i];
      sc = [bc columnScrollView];

      if (!firstResponder && [bc columnMatrix] == [_window firstResponder])
	{
	  firstResponder = [bc columnMatrix];
	}
      if (sc)
	{
	  [sc removeFromSuperviewWithoutNeedingDisplay];
	}
    }

  if (_firstVisibleColumn > _lastVisibleColumn)
    return;

  // Sets columns subviews order according to fromFirst (display order...).
  // All added subviews are automaticaly marked as needing display (->
  // NSView).
  if (fromFirst)
    {
      for (i = _firstVisibleColumn; i <= _lastVisibleColumn; i++)
	{
	  bc = [_browserColumns objectAtIndex: i];
	  sc = [bc columnScrollView];
	  [self addSubview: sc];

	  if ([bc columnMatrix] == firstResponder)
	    {
	      [_window makeFirstResponder: firstResponder];
	      setFirstResponder = YES;
	    }
	}

      if (firstResponder && setFirstResponder == NO)
	{
	  [_window makeFirstResponder:
		     [[_browserColumns objectAtIndex: _firstVisibleColumn]
		       columnMatrix]];
	}
    }
  else
    {
      for (i = _lastVisibleColumn; i >= _firstVisibleColumn; i--)
	{
	  bc = [_browserColumns objectAtIndex: i];
	  sc = [bc columnScrollView];
	  [self addSubview: sc];

	  if ([bc columnMatrix] == firstResponder)
	    {
	      [_window makeFirstResponder: firstResponder];
	      setFirstResponder = YES;
	    }
	}

      if (firstResponder && setFirstResponder == NO)
	{
	  [_window makeFirstResponder:
		     [[_browserColumns objectAtIndex: _lastVisibleColumn]
		       columnMatrix]];
	}
    }
}

/* Loads column 'column' (asking the delegate). */
- (void) _performLoadOfColumn: (int)column
{
  id bc, sc, matrix;
  int i, rows, cols;

  if (_passiveDelegate)
    {
      // Ask the delegate for the number of rows
      rows = [_browserDelegate browser: self numberOfRowsInColumn: column];
      cols = 1;
    }
  else
    {
      rows = 0;
      cols = 0;
    }

  bc = [_browserColumns objectAtIndex: column];

  if (!(sc = [bc columnScrollView]))
    return;

  matrix = [bc columnMatrix];

  if (_reusesColumns && matrix)
    {
      [matrix renewRows: rows columns: cols];

      // Mark all the cells as unloaded
      for (i = 0; i < rows; i++)
        {
	  [[matrix cellAtRow: i column: 0] setLoaded: NO];
	}
    }
  else
    {
      NSRect matrixRect = {{0, 0}, {100, 100}};
      NSSize matrixIntercellSpace = {0, 0};

      // create a new col matrix
      matrix = [[_browserMatrixClass alloc]
		   initWithFrame: matrixRect
		   mode: NSListModeMatrix
		   prototype: _browserCellPrototype
		   numberOfRows: rows
		   numberOfColumns: cols];
      [matrix setIntercellSpacing: matrixIntercellSpace];
      [matrix setAllowsEmptySelection: _allowsEmptySelection];
      [matrix setAutoscroll: YES];
      if (!_allowsMultipleSelection)
        {
	  [matrix setMode: NSRadioModeMatrix];
	}
      [matrix setTarget: self];
      [matrix setAction: @selector(doClick:)];
      [matrix setDoubleAction: @selector(doDoubleClick:)];
      
      // set new col matrix and release old
      [bc setColumnMatrix: matrix];
      RELEASE (matrix);
    }
  [sc setDocumentView: matrix];

  // Loading is different based upon passive/active delegate
  if (_passiveDelegate)
    {
      // Now loop through the cells and load each one
      id aCell;
      SEL sel1 = @selector(browser:willDisplayCell:atRow:column:);
      IMP imp1 = [_browserDelegate methodForSelector: sel1];
      SEL sel2 = @selector(cellAtRow:column:);
      IMP imp2 = [matrix methodForSelector: sel2];
      
      for (i = 0; i < rows; i++)
        {
	  aCell = (*imp2)(matrix, sel2, i, 0);
	  if (![aCell isLoaded])
	    {
	      (*imp1)(_browserDelegate, sel1, self, aCell, i, 
		      column);
	      [aCell setLoaded: YES];
	    }
	}
    }
  else
    {
      // Tell the delegate to create the rows
      [_browserDelegate browser: self
			createRowsForColumn: column
			inMatrix: matrix];
    }

  [sc setNeedsDisplay: YES];
  [bc setIsLoaded: YES];

  /* Determine the height of a cell in the matrix, and set that as the 
     cellSize of the matrix.  */
  {
    NSSize cs, ms;
    NSBrowserCell *b = [matrix cellAtRow: 0  column: 0]; 

    if (b != nil)
      {
	ms = [b cellSize];
      }
    else
      {
	ms = [matrix cellSize];
      }
    cs = [sc contentSize];
    ms.width = cs.width;
    [matrix setCellSize: ms];
  }

  // Get the title even when untiteled, as this may change later.
  [self setTitle: [self _getTitleOfColumn: column] ofColumn: column];
}

/* Get the title of a column. */
- (NSString *) _getTitleOfColumn: (int)column
{
  // Ask the delegate for the column title
  if ([_browserDelegate respondsToSelector: 
			  @selector(browser:titleOfColumn:)])
    {
      return [_browserDelegate browser: self titleOfColumn: column];
    }
  

  // Check if we take title from previous column
  if (_takesTitleFromPreviousColumn)
    {
      id c;
      
      // If first column then use the path separator
      if (column == 0)
	{
	  return _pathSeparator;
	}
      
      // Get the selected cell
      // Use its string value as the title
      // Only if it is not a leaf
      if(_allowsMultipleSelection == NO)
	{
	  c = [self selectedCellInColumn: column - 1];
	}
      else
	{
	  NSMatrix *matrix;
	  NSArray  *selectedCells;

	  if (!(matrix = [self matrixInColumn: column - 1]))
	    return @"";

	  selectedCells = [matrix selectedCells];

	  if([selectedCells count] == 1)
	    {
	      c = [selectedCells objectAtIndex:0];
	    }
	  else
	    {
	      return @"";
	    }
	}

      if ([c isLeaf])
	{
	  return @"";
	}
      else
	{ 
	  NSString *value = [c stringValue];

	  if (value != nil)
	    {
	      return value;
	    }
	  else
	    {
	      return @"";
	    }
	}
    }
  return @"";
}

/* Marks all titles as needing to be redrawn. */
- (void) _setColumnTitlesNeedDisplay
{
  if (_isTitled)
    {
      NSRect r = [self titleFrameOfColumn: _firstVisibleColumn];

      r.size.width = _frame.size.width;
      [self setNeedsDisplayInRect: r];
    }
}

@end
