/** <title>NSTableView</title>

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: March 2000, June 2000, August 2000, September 2000
   
   Author: Pierre-Yves Rivaille <pyrivail@ens-lyon.fr>
   Date: August 2001, January 2002

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

#include <Foundation/NSException.h>
#include <Foundation/NSFormatter.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSSet.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSValue.h>

#include <AppKit/NSTableView.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSCell.h>
#include <AppKit/NSClipView.h>
#include <AppKit/NSColor.h>
#include <AppKit/NSEvent.h>
#include <AppKit/NSImage.h>
#include <AppKit/NSGraphics.h>
#include <AppKit/NSScroller.h>
#include <AppKit/NSTableColumn.h>
#include <AppKit/NSTableHeaderView.h>
#include <AppKit/NSText.h>
#include <AppKit/NSTextFieldCell.h>
#include <AppKit/NSWindow.h>
#include <AppKit/PSOperators.h>
#include <AppKit/NSCachedImageRep.h>
#include <AppKit/NSPasteboard.h>
#include <AppKit/NSDragging.h>
#include <AppKit/NSCustomImageRep.h>

#include <math.h>
static NSNotificationCenter *nc = nil;

static const int currentVersion = 3;

static NSRect oldDraggingRect;
static int oldDropRow;
static NSTableViewDropOperation oldDropOperation;
static NSTableViewDropOperation currentDropOperation;
static int currentDropRow;
static int lastQuarterPosition;
static unsigned currentDragOperation;


#define ALLOWS_MULTIPLE (1)
#define ALLOWS_EMPTY (1 << 1)
#define SHIFT_DOWN (1 << 2)
#define CONTROL_DOWN (1 << 3)
#define ADDING_ROW (1 << 4)


@interface NSTableView (NotificationRequestMethods)
- (void) _postSelectionIsChangingNotification;
- (void) _postSelectionDidChangeNotification;
- (void) _postColumnDidMoveNotificationWithOldIndex: (int) oldIndex
					   newIndex: (int) newIndex;
- (void) _postColumnDidResizeNotification;
- (BOOL) _shouldSelectTableColumn: (NSTableColumn *)tableColumn;
- (BOOL) _shouldSelectRow: (int)rowIndex;
- (BOOL) _shouldSelectionChange;
- (BOOL) _shouldEditTableColumn: (NSTableColumn *)tableColumn
			    row: (int) rowIndex;

- (BOOL) _writeRows: (NSArray *) rows
       toPasteboard: (NSPasteboard *)pboard;
- (BOOL) _isDraggingSource;
- (id)_objectValueForTableColumn: (NSTableColumn *)tb
			     row: (int)index;
- (void)_setObjectValue: (id)value
	 forTableColumn: (NSTableColumn *)tb
		    row: (int)index;
@end


/*
 *  A specific struct and its associated quick sort function
 *  This is used by the -sizeToFit method
 */
typedef struct {
  float width;
  BOOL isMax;
} columnSorting;


static
void quick_sort_internal(columnSorting *data, int p, int r)
{
  if (p < r)
    {
      int q;
      {
	float x = data[p].width;
	BOOL y = data[p].isMax;
	int i = p - 1;
	int j = r + 1;
	columnSorting exchange;
	while(1)
	  {
	    j--;
	    for(; 
		(data[j].width > x)
		  || ((data[j].width == x) 
		      && (data[j].isMax == YES)
		      && (y == NO));
		j--)
	      ;

	    i++;
	    for(;
		(data[i].width < x)
		  || ((data[i].width == x) 
		      && (data[i].isMax == NO)
		      && (y == YES));
		i++)
	      ;
	    if ( i < j )
	      {
		exchange = data[j];
		data[j] = data[i];
		data[i] = exchange;
	      }
	    else
	      {
		q = j;
		break;
	      }
	  }
      }
      quick_sort_internal(data, p, q);
      quick_sort_internal(data, q + 1, r);
    }
}


/* The selection arrays are stored so that the selected columns/rows
   are always in ascending order.  The following function is used
   whenever a new column/row is added to the array, to keep the
   columns/rows in the correct order. */
static 
void _insertNumberInSelectionArray (NSMutableArray *array, 
				    NSNumber *num)
{
  int i, count;

  count = [array count];

  for (i = 0; i < count; i++)
    {
      NSNumber *number;

      number = [array objectAtIndex: i];
      if ([number compare: num] == NSOrderedDescending)
	break;
    }
  [array insertObject: num  atIndex: i];
}

/* 
 * Now some auxiliary functions used to manage real-time user selections. 
 *
 */

static void computeNewSelection
(NSTableView *tv,
 id delegate,
 NSSet *_oldSelectedRows,
 NSMutableArray *_selectedRows,
 int _originalRow,
 int _oldRow,
 int _currentRow,
 int *_selectedRow,
 unsigned selectionMode)
{
  if (   (selectionMode & ALLOWS_MULTIPLE)
      && (selectionMode & SHIFT_DOWN)
      && (selectionMode & ADDING_ROW))
    // we add new row to the current selection
    {
      if (_oldRow == -1)
	// this is the first pass
	{
	  int diff, i;
	  BOOL notified = NO;
      	  diff = _currentRow - _originalRow;

	  if (diff >= 0)
	    {
	      for (i = _originalRow; i <= _currentRow; i++)
		{
		  if ([_selectedRows 
			containsObject: 
			  [NSNumber numberWithInt: i]] == YES)
		    {
		      *_selectedRow = i;
		      notified = YES;
		    }
		  else
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    }
		}
	    }
	  else
	    {
	      // this case does happen, (sometimes)
	      for (i = _originalRow; i >= _currentRow; i--)
		{
		  if ([_selectedRows 
			containsObject: 
			  [NSNumber numberWithInt: i]] == YES)
		    {
		      *_selectedRow = i;
		      notified = YES;
		    }
		  else
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    }
		}
	    }
	  if (notified == YES)
	    {
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      else // new multiple selection, after first pass
	{ 
	  int oldDiff, newDiff, i;
	  oldDiff = _oldRow - _originalRow;
	  newDiff = _currentRow - _originalRow;
	  if (oldDiff >= 0 && newDiff >= 0)
	    {
	      if (newDiff >= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow + 1; i <= _currentRow; i++)
		    {
		      if ([_selectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]] == YES)
			{
			  *_selectedRow = i;
			  notified = YES;
			}
		      else
			{
			  if ([tv _shouldSelectRow: i] == YES)
			    {
			      if (notified == NO)
				{
				  notified = YES;
				}
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			    }
			}
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;
		  int pos;

		  for (i = _oldRow; i > _currentRow; i--)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // leave it selected
			  continue;
			}
		      
		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      NSNumber *lastObject = [_selectedRows lastObject];
		      if (lastObject == nil)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = [lastObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff <= 0)
	    {
	      if (newDiff <= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow - 1; i >= _currentRow; i--)
		    {
		      if ([_selectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]] == YES)
			{
			  *_selectedRow = i;
			  notified = YES;
			}
		      else
			{
			  if ([tv _shouldSelectRow: i] == YES)
			    {
			      if (notified == NO)
				{
				  notified = YES;
				}
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			    }
			} 
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;
		  int pos;


		  for (i = _oldRow; i < _currentRow; i++)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // leave it selected
			  continue;
			}

		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      if ([_selectedRows count] == 0)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  NSNumber *firstObject = 
			    [_selectedRows objectAtIndex: 0];
			  *_selectedRow = [firstObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff >= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i < _originalRow; i++)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// leave it selected
			continue;
		      }
		    
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow + 1; i <= _currentRow; i++)
		  {
		    if ([_selectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]] == YES)
		      {
			*_selectedRow = i;
			notified = YES;
		      }
		    else
		      {
			if ([tv _shouldSelectRow: i] == YES)
			  {
			    if (notified == NO)
			      {
				notified = YES;
			      }
			    [tv setNeedsDisplayInRect:
				  [tv rectOfRow: i]];
			    _insertNumberInSelectionArray
			      (_selectedRows,
			       [NSNumber numberWithInt: i]);
			    *_selectedRow = i;
			  }
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *firstObject = 
			[_selectedRows objectAtIndex: 0];
		      *_selectedRow = [firstObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	  else if (oldDiff >= 0 && newDiff <= 0)
	    {
	      BOOL notified = NO;

	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i > _originalRow; i--)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// leave it selected
			continue;
		      }
		    
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow - 1; i >= _currentRow; i--)
		  {
		    if ([_selectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]] == YES)
		      {
			*_selectedRow = i;
			notified = YES;
		      }
		    else
		      {
			if ([tv _shouldSelectRow: i] == YES)
			  {
			    if (notified == NO)
			      {
				notified = YES;
			      }
			    [tv setNeedsDisplayInRect:
				  [tv rectOfRow: i]];
			    _insertNumberInSelectionArray
			      (_selectedRows,
			       [NSNumber numberWithInt: i]);
			    *_selectedRow = i;
			  }
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *lastObject = 
			[_selectedRows lastObject];
		      *_selectedRow = [lastObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }

	}
    }
  else if (   (selectionMode & ALLOWS_MULTIPLE)
	   && ((selectionMode & SHIFT_DOWN) == 0)
	   && (selectionMode & ALLOWS_EMPTY)
	      )
    // ic, sr : ok
    // new multiple selection (empty possible)
    {
      if (_oldRow == -1)
	// this is the first pass
	// we'll clear the selection first
	{
	  int diff, i;
	  int count = [_selectedRows count];
	  BOOL notified = NO;
      	  diff = _currentRow - _originalRow;

	  if (count > 0)
	    {
	      notified = YES;
	    }

	  for (i = 0; i < count; i++)
	    {
	      [tv setNeedsDisplayInRect: 
		    [tv rectOfRow: 
			  [[_selectedRows objectAtIndex: i] intValue]]];
	    }
	  [_selectedRows removeAllObjects];
	  *_selectedRow = -1;

	  if (diff >= 0)
	    {
	      for (i = _originalRow; i <= _currentRow; i++)
		{
		  if ([tv _shouldSelectRow: i] == YES)
		    {
		      if (notified == NO)
			{
			  notified = YES;
			}

		      [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
		      _insertNumberInSelectionArray
			(_selectedRows,
			 [NSNumber numberWithInt: i]);
		      *_selectedRow = i;
		    }
		}
	    }
	  else
	    {
	      // this case does happen (sometimes)
	      for (i = _originalRow; i >= _currentRow; i--)
		{
		  if ([tv _shouldSelectRow: i] == YES)
		    {
		      if (notified == NO)
			{
			  notified = YES;
			}

		      [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
		      _insertNumberInSelectionArray
			(_selectedRows,
			 [NSNumber numberWithInt: i]);
		      *_selectedRow = i;
		    }
		}
	    }
	  if (notified == YES)
	    {
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      else // new multiple selection, after first pass
	{ 
	  int oldDiff, newDiff, i;
	  oldDiff = _oldRow - _originalRow;
	  newDiff = _currentRow - _originalRow;
	  if (oldDiff >= 0 && newDiff >= 0)
	    {
	      if (newDiff >= oldDiff)
		{
		  BOOL notified = NO;
		  for (i = _oldRow + 1; i <= _currentRow; i++)
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		{
		  BOOL notified = NO;
		  int pos;

		  for (i = _oldRow; i > _currentRow; i--)
		    {
		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      NSNumber *lastObject = [_selectedRows lastObject];
		      if (lastObject == nil)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = [lastObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff <= 0)
	    {
	      if (newDiff <= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow - 1; i >= _currentRow; i--)
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    } 
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;
		  int pos;


		  for (i = _oldRow; i < _currentRow; i++)
		    {
		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      if ([_selectedRows count] == 0)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  NSNumber *firstObject = 
			    [_selectedRows objectAtIndex: 0];
			  *_selectedRow = [firstObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff >= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i < _originalRow; i++)
		  {
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow + 1; i <= _currentRow; i++)
		  {
		    if ([tv _shouldSelectRow: i] == YES)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			_insertNumberInSelectionArray
			  (_selectedRows,
			   [NSNumber numberWithInt: i]);
			*_selectedRow = i;
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *firstObject = 
			[_selectedRows objectAtIndex: 0];
		      *_selectedRow = [firstObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	  else if (oldDiff >= 0 && newDiff <= 0)
	    {
	      BOOL notified = NO;

	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i > _originalRow; i--)
		  {
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow - 1; i >= _currentRow; i--)
		  {
		    if ([tv _shouldSelectRow: i] == YES)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			_insertNumberInSelectionArray
			  (_selectedRows,
			   [NSNumber numberWithInt: i]);
			*_selectedRow = i;
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *lastObject = 
			[_selectedRows lastObject];
		      *_selectedRow = [lastObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }

	}
    }
  else if ((((selectionMode & ALLOWS_MULTIPLE) == 0)
	    && ((selectionMode & SHIFT_DOWN) == 0))
	   || 
	   (((selectionMode & ALLOWS_MULTIPLE) == 0)
	    && ((selectionMode & ALLOWS_EMPTY) == 0))
	   ||
	   (((selectionMode & ALLOWS_MULTIPLE) == 0)
	    && (selectionMode & SHIFT_DOWN)
	    && (selectionMode & ALLOWS_EMPTY)
	    && (selectionMode & ADDING_ROW)))
    // we'll be selecting exactly one row
    // ic, sc : ok
    {
      int i;
      int j;
      int count = [_selectedRows count];
      BOOL notified = NO;

      if ([tv _shouldSelectRow: _currentRow] == NO)
	{
	  return;
	}
      
      if ((count != 1) || (_oldRow == -1))
	{
	  // this is the first call that goes thru shouldSelectRow
	  // Therefore we don't know anything about the selection
	  notified = YES;
	  for (i = 0; i < count; i++)
	    {
	      j = [[_selectedRows objectAtIndex: i] intValue];
	      if (j == _currentRow)
		{
		  notified = NO;
		  continue;
		}
	      [tv setNeedsDisplayInRect: 
		    [tv rectOfRow: j]];
	    }
	  [_selectedRows removeAllObjects];
	  [_selectedRows addObject: 
			   [NSNumber numberWithInt: _currentRow]];
	  *_selectedRow = _currentRow;
	  
	  if (notified == YES)
	    {
	      [tv setNeedsDisplayInRect:
		    [tv rectOfRow: _currentRow]];
	    }
	  else
	    {
	      if (count > 1)
		{
		  notified = YES;
		}
	    }
	  if (notified == YES)
	    {
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      else
	{
	  // we know there is only one column selected
	  // this column is *_selectedRow

	  //begin checking code
	  if ([_selectedRows containsObject:
			     [NSNumber numberWithInt: *_selectedRow]]
	      == NO)
	    {
	      NSLog(@"*_selectedRow is not the only selected row!");
	    }
	  //end checking code

	  if (*_selectedRow == _currentRow)
	    {
	      // currentRow is already selecteed
	      return;
	    }
	  else
	    {
	      [_selectedRows replaceObjectAtIndex:0
			     withObject:
			       [NSNumber numberWithInt: _currentRow]];
	      [tv setNeedsDisplayInRect:
		    [tv rectOfRow: *_selectedRow]];
	      [tv setNeedsDisplayInRect:
		    [tv rectOfRow: _currentRow]];
	      *_selectedRow = _currentRow;
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      
    }
  else if (((selectionMode & ALLOWS_MULTIPLE) == 0)
	   && ((selectionMode & SHIFT_DOWN) == SHIFT_DOWN)
	   && ((selectionMode & ALLOWS_EMPTY) == ALLOWS_EMPTY)
	   && ((selectionMode & ADDING_ROW) == 0))
    // we will unselect the selected row
    // ic, sc : ok
    {
      int i;
      int count = [_selectedRows count];
      /*
      BOOL wasOriginalRowSelected =
	[_oldSelectedRows containsObject:
			    [NSNumber numberWithInt: _originalRow]];
      */

      if ((count == 0) && (_oldRow == -1))
	{
	  NSLog(@"how did you get there ?");
	  NSLog(@"you're supposed to have clicked on a selected row,");
	  NSLog(@"but there's no selected row!");
	  return;
	}
      else if (count > 1)
	{
	  for (i = 0; i < count; i++)
	    {
	      [tv setNeedsDisplayInRect: 
		    [tv rectOfRow:
			  [[_selectedRows objectAtIndex: i] intValue]]];
	    }
	  [_selectedRows removeAllObjects];
	  *_selectedRow = -1;
	  [tv _postSelectionIsChangingNotification];
	  
	}
      else if (_currentRow != _originalRow)
	{
	  if (*_selectedRow == _originalRow)
	    {
	      // we are already selected, don't do anything
	    }
	  else
	    {
	      //begin checking code
	      if (count > 0)
		{
		  NSLog(@"There should not be any row selected");
		}
	      //end checking code

	      if ([tv _shouldSelectRow: _originalRow] == NO)
		{
		  return;
		}

	      [tv setNeedsDisplayInRect:
		    [tv rectOfRow: _originalRow]];
	      
	      [_selectedRows addObject: 
			       [NSNumber numberWithInt: _originalRow]];
	      *_selectedRow = _originalRow;
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      else if (_currentRow == _originalRow)
	{
	  if (count == 0)
	    {
	      // the row is already deselected
	      // nothing to do !
	    }
	  else
	    {
	      [tv setNeedsDisplayInRect:
		    [tv rectOfRow: _originalRow]];
	      [_selectedRows removeObjectAtIndex: 0];
	      *_selectedRow = -1;
	      [tv _postSelectionIsChangingNotification];
	    }
	}
    }
  else if (((selectionMode & ALLOWS_MULTIPLE)
	    && ((selectionMode & SHIFT_DOWN) == 0)
	    && ((selectionMode & ALLOWS_EMPTY) == 0)
	    && (selectionMode & ADDING_ROW))
	   // the following case can be assimilated to the 
	   // one before, although it will lead to an
	   // extra redraw
	   // TODO: solve this issue
	   ||
	   ((selectionMode & ALLOWS_MULTIPLE)
	    && ((selectionMode & SHIFT_DOWN) == 0)
	    && ((selectionMode & ALLOWS_EMPTY) == 0)
	    && ((selectionMode & ADDING_ROW) == 0))
	   )
    {
      if (_oldRow == -1)
	{
	  // if we can select the _originalRow, we'll clear the old selection
	  // else we'll add to the old selection
	  if ([tv _shouldSelectRow: _currentRow] == YES)
	    {
	      // let's clear the old selection
	      // this code is copied from another case
	      // (AM = 1, SD=0, AE=1, AR=*, first pass)
	      int diff, i;
	      int count = [_selectedRows count];
	      BOOL notified = NO;
	      diff = _currentRow - _originalRow;
	      
	      if (count > 0)
		{
		  notified = YES;
		}
	      
	      for (i = 0; i < count; i++)
		{
		  [tv setNeedsDisplayInRect: 
			[tv rectOfRow: 
			      [[_selectedRows objectAtIndex: i] intValue]]];
		}
	      [_selectedRows removeAllObjects];
	      *_selectedRow = -1;
	      
	      if (diff >= 0)
		{
		  for (i = _originalRow; i <= _currentRow; i++)
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    }	      
		}
	      else
		{
		  for (i = _originalRow; i >= _currentRow; i--)
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    }	      
		}
	    }
	  else
	    {
	      // let's add to the old selection
	      // this code is copied from another case
	      // (AM=1, SD=1, AE=*, AR=1)
	      int diff, i;
	      //	      int count = [_selectedRows count];
	      BOOL notified = NO;
	      diff = _currentRow - _originalRow;
	      
	      if (diff >= 0)
		{
		  for (i = _originalRow; i <= _currentRow; i++)
		    {
		      if ([_selectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]] == YES)
			{
			  *_selectedRow = i;
			  notified = YES;
			}
		      else
			{
			  if ([tv _shouldSelectRow: i] == YES)
			    {
			      if (notified == NO)
				{
				  notified = YES;
				}
			      
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			    }
			}
		    }
		}
	      else
		{
		  // this case does happen (sometimes)
		  for (i = _originalRow; i >= _currentRow; i--)
		    {
		      if ([_selectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]] == YES)
			{
			  *_selectedRow = i;
			  notified = YES;
			}
		      else
			{
			  if ([tv _shouldSelectRow: i] == YES)
			    {
			      if (notified == NO)
				{
				  notified = YES;
				}
			      
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			    }
			}
		    }
		}
	      if (notified == YES)
		{
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	}
      else if ([_selectedRows containsObject:
				[NSNumber numberWithInt: _originalRow]])
	// as the originalRow is selected,
	// we are in a new selection
	{
	  // this code is copied from another case
	  // (AM=1, SD=0, AE=1, AR=*, after first pass)
	  int oldDiff, newDiff, i;
	  oldDiff = _oldRow - _originalRow;
	  newDiff = _currentRow - _originalRow;
	  if (oldDiff >= 0 && newDiff >= 0)
	    {
	      if (newDiff >= oldDiff)
		{
		  BOOL notified = NO;
		  for (i = _oldRow + 1; i <= _currentRow; i++)
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		{
		  BOOL notified = NO;
		  int pos;

		  for (i = _oldRow; i > _currentRow; i--)
		    {
		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      NSNumber *lastObject = [_selectedRows lastObject];
		      if (lastObject == nil)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = [lastObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff <= 0)
	    {
	      if (newDiff <= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow - 1; i >= _currentRow; i--)
		    {
		      if ([tv _shouldSelectRow: i] == YES)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			}
		    } 
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;
		  int pos;


		  for (i = _oldRow; i < _currentRow; i++)
		    {
		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      if ([_selectedRows count] == 0)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  NSNumber *firstObject = 
			    [_selectedRows objectAtIndex: 0];
			  *_selectedRow = [firstObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff >= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i < _originalRow; i++)
		  {
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow + 1; i <= _currentRow; i++)
		  {
		    if ([tv _shouldSelectRow: i] == YES)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			_insertNumberInSelectionArray
			  (_selectedRows,
			   [NSNumber numberWithInt: i]);
			*_selectedRow = i;
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *firstObject = 
			[_selectedRows objectAtIndex: 0];
		      *_selectedRow = [firstObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	  else if (oldDiff >= 0 && newDiff <= 0)
	    {
	      BOOL notified = NO;

	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i > _originalRow; i--)
		  {
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow - 1; i >= _currentRow; i--)
		  {
		    if ([tv _shouldSelectRow: i] == YES)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			_insertNumberInSelectionArray
			  (_selectedRows,
			   [NSNumber numberWithInt: i]);
			*_selectedRow = i;
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *lastObject = 
			[_selectedRows lastObject];
		      *_selectedRow = [lastObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	}
      else
	// as the originalRow is not selection, 
	// we are adding to the old selection
	{
	  // this code is copied from another case
	  // (AM=1, SD=1, AE=*, AR=1, after first pass)
	  int oldDiff, newDiff, i;
	  oldDiff = _oldRow - _originalRow;
	  newDiff = _currentRow - _originalRow;

	  if (oldDiff >= 0 && newDiff >= 0)
	    {
	      if (newDiff >= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow + 1; i <= _currentRow; i++)
		    {
		      if ([_selectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]] == YES)
			{
			  *_selectedRow = i;
			  notified = YES;
			}
		      else
			{
			  if ([tv _shouldSelectRow: i] == YES)
			    {
			      if (notified == NO)
				{
				  notified = YES;
				}
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			    }
			}
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;
		  int pos;

		  for (i = _oldRow; i > _currentRow; i--)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // leave it selected
			  continue;
			}
		      
		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      NSNumber *lastObject = [_selectedRows lastObject];
		      if (lastObject == nil)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = [lastObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff <= 0)
	    {
	      if (newDiff <= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow - 1; i >= _currentRow; i--)
		    {
		      if ([_selectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]] == YES)
			{
			  *_selectedRow = i;
			  notified = YES;
			}
		      else
			{
			  if ([tv _shouldSelectRow: i] == YES)
			    {
			      if (notified == NO)
				{
				  notified = YES;
				}
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			    }
			} 
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;
		  int pos;


		  for (i = _oldRow; i < _currentRow; i++)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // leave it selected
			  continue;
			}

		      pos = [_selectedRows indexOfObject:
					     [NSNumber numberWithInt: i]];
		      if (pos != NSNotFound)
			{
			  if (notified == NO)
			    {
			      notified = YES;
			    }
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  [_selectedRows removeObject:
					   [NSNumber numberWithInt: i]];
			}
		    }
		  if (notified == YES)
		    {
		      if ([_selectedRows count] == 0)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  NSNumber *firstObject = 
			    [_selectedRows objectAtIndex: 0];
			  *_selectedRow = [firstObject intValue];
			}
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff >= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i < _originalRow; i++)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// leave it selected
			continue;
		      }
		    
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow + 1; i <= _currentRow; i++)
		  {
		    if ([_selectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]] == YES)
		      {
			*_selectedRow = i;
			notified = YES;
		      }
		    else
		      {
			if ([tv _shouldSelectRow: i] == YES)
			  {
			    if (notified == NO)
			      {
				notified = YES;
			      }
			    [tv setNeedsDisplayInRect:
				  [tv rectOfRow: i]];
			    _insertNumberInSelectionArray
			      (_selectedRows,
			       [NSNumber numberWithInt: i]);
			    *_selectedRow = i;
			  }
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *firstObject = 
			[_selectedRows objectAtIndex: 0];
		      *_selectedRow = [firstObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	  else if (oldDiff >= 0 && newDiff <= 0)
	    {
	      BOOL notified = NO;

	      // we're reducing the selection
	      {
		int pos;
		for (i = _oldRow; i > _originalRow; i--)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// leave it selected
			continue;
		      }
		    
		    pos = [_selectedRows indexOfObject:
					   [NSNumber numberWithInt: i]];
		    if (pos != NSNotFound)
		      {
			if (notified == NO)
			  {
			    notified = YES;
			  }
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			[_selectedRows removeObject:
					 [NSNumber numberWithInt: i]];
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow - 1; i >= _currentRow; i--)
		  {
		    if ([_selectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]] == YES)
		      {
			*_selectedRow = i;
			notified = YES;
		      }
		    else
		      {
			if ([tv _shouldSelectRow: i] == YES)
			  {
			    if (notified == NO)
			      {
				notified = YES;
			      }
			    [tv setNeedsDisplayInRect:
				  [tv rectOfRow: i]];
			    _insertNumberInSelectionArray
			      (_selectedRows,
			       [NSNumber numberWithInt: i]);
			    *_selectedRow = i;
			  }
		      }
		  }
	      }

	      if (notified == YES)
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      NSNumber *lastObject = 
			[_selectedRows lastObject];
		      *_selectedRow = [lastObject intValue];
		    }
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	}
    }
  else if ((selectionMode & ALLOWS_MULTIPLE)
	   && (selectionMode & SHIFT_DOWN)
	   && (selectionMode & ALLOWS_EMPTY)
	   && ((selectionMode & ADDING_ROW) == 0))
    {
      if (_oldRow == -1)
	// this is the first pass
	{
	  int diff, i;
	  unsigned pos;
	  //	  int count = [_selectedRows count];
	  BOOL notified = NO;
      	  diff = _currentRow - _originalRow;

	  if (diff >= 0)
	    {
	      for (i = _originalRow; i <= _currentRow; i++)
		{
		  if ((pos = [_selectedRows 
			       indexOfObject: 
				 [NSNumber numberWithInt: i]])
		      != NSNotFound)
		    {
		      [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
		      notified = YES;
		      [_selectedRows removeObjectAtIndex: pos];
		    }
		}
	      if (   notified 
		  && (*_selectedRow >= _originalRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}
	    }
	  else
	    {
	      // this case does happen (sometimes)
	      for (i = _originalRow; i >= _currentRow; i--)
		{
		  if ((pos = [_selectedRows 
			       indexOfObject: 
				 [NSNumber numberWithInt: i]])
		      != NSNotFound)
		    {
		      [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
		      notified = YES;
		      [_selectedRows removeObjectAtIndex: pos];
		    }
		}
	      if (   notified 
		  && (*_selectedRow >= _originalRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}
	    }
	  if (notified == YES)
	    {
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      else // new multiple antiselection, after first pass
	{ 
	  int oldDiff, newDiff, i;
	  unsigned pos;
	  oldDiff = _oldRow - _originalRow;
	  newDiff = _currentRow - _originalRow;
	  if (oldDiff >= 0 && newDiff >= 0)
	    {
	      if (newDiff >= oldDiff)
		// we're extending the antiselection
		{
		  BOOL notified = NO;
		  for (i = _oldRow + 1; i <= _currentRow; i++)
		    {
		      if ((pos = [_selectedRows 
				   indexOfObject: 
				     [NSNumber numberWithInt: i]])
			  != NSNotFound)
			{
			  [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
			  notified = YES;
			  [_selectedRows removeObjectAtIndex: pos];
			}
		    }

		  if (   notified 
		      && (*_selectedRow > _oldRow)
		      && (*_selectedRow <= _currentRow))
		    {
		      if ([_selectedRows count] == 0)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = 
			    [[_selectedRows objectAtIndex: 0]
			      intValue];
			}
		    }

		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;

		  for (i = _oldRow; i > _currentRow; i--)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // select it
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			  notified = YES;
			}
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff <= 0)
	    {
	      if (newDiff <= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow - 1; i >= _currentRow; i--)
		    {
		      if ((pos = [_selectedRows 
				   indexOfObject: 
				     [NSNumber numberWithInt: i]])
			  != NSNotFound)
			{
			  [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
			  notified = YES;
			  [_selectedRows removeObjectAtIndex: pos];
			}
		    }

		  if (   notified 
		      && (*_selectedRow < _oldRow)
		      && (*_selectedRow >= _currentRow))
		    {
		      if ([_selectedRows count] == 0)
			{
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = 
			    [[_selectedRows objectAtIndex: 0]
			      intValue];
			}
		    }

		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;

		  for (i = _oldRow; i < _currentRow; i++)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // select it
			  [tv setNeedsDisplayInRect:
				[tv rectOfRow: i]];
			  _insertNumberInSelectionArray
			    (_selectedRows,
			     [NSNumber numberWithInt: i]);
			  *_selectedRow = i;
			  notified = YES;
			}
		    }

		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff >= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		for (i = _oldRow; i < _originalRow; i++)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// select it
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			_insertNumberInSelectionArray
			  (_selectedRows,
			   [NSNumber numberWithInt: i]);
			*_selectedRow = i;
			notified = YES;
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow + 1; i <= _currentRow; i++)
		  {
		    if ((pos = [_selectedRows 
				 indexOfObject: 
				   [NSNumber numberWithInt: i]])
			!= NSNotFound)
		      {
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			notified = YES;
			[_selectedRows removeObjectAtIndex: pos];
		      }
		  }
	      }

	      if (   notified 
		  && (*_selectedRow > _oldRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}

	      if (notified == YES)
		{
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	  else if (oldDiff >= 0 && newDiff <= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		for (i = _oldRow; i > _originalRow; i--)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// select it
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			_insertNumberInSelectionArray
			  (_selectedRows,
			   [NSNumber numberWithInt: i]);
			*_selectedRow = i;
			notified = YES;
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow - 1; i >= _currentRow; i--)
		  {
		    if ((pos = [_selectedRows 
				 indexOfObject: 
				   [NSNumber numberWithInt: i]])
			!= NSNotFound)
		      {
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			notified = YES;
			[_selectedRows removeObjectAtIndex: pos];
		      }
		  }
	      }

	      if (   notified 
		  && (*_selectedRow > _oldRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}

	      if (notified == YES)
		{
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	}
    }
  else if ((selectionMode & ALLOWS_MULTIPLE)
	   && (selectionMode & SHIFT_DOWN)
	   && ((selectionMode & ALLOWS_EMPTY) == 0)
	   && ((selectionMode & ADDING_ROW) == 0))
    {
      if (_oldRow == -1)
	// this is the first pass
	{
	  int diff, i;
	  unsigned pos;
	  int count = [_selectedRows count];
	  BOOL notified = NO;
      	  diff = _currentRow - _originalRow;

	  if (diff >= 0)
	    {
	      for (i = _originalRow; i <= _currentRow; i++)
		{
		  if (((pos = [_selectedRows 
			       indexOfObject: 
				 [NSNumber numberWithInt: i]])
		      != NSNotFound) && (count > 1))
		    {
		      [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
		      notified = YES;
		      [_selectedRows removeObjectAtIndex: pos];
		      count--;
		    }
		}
	      if (   notified 
		  && (*_selectedRow >= _originalRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      NSLog(@"error!");
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}
	    }
	  else
	    {
	      // this case does happen (sometimes)
	      for (i = _originalRow; i >= _currentRow; i--)
		{
		  if (((pos = [_selectedRows 
			       indexOfObject: 
				 [NSNumber numberWithInt: i]])
		      != NSNotFound) && (count > 1))
		    {
		      [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
		      notified = YES;
		      [_selectedRows removeObjectAtIndex: pos];
		      count--;
		    }
		}
	      if (   notified 
		  && (*_selectedRow >= _originalRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      NSLog(@"error!");
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}
	    }
	  if (notified == YES)
	    {
	      [tv _postSelectionIsChangingNotification];
	    }
	}
      else // new multiple antiselection, after first pass
	{ 
	  int oldDiff, newDiff, i;
	  unsigned pos;
	  int count = [_selectedRows count];
	  oldDiff = _oldRow - _originalRow;
	  newDiff = _currentRow - _originalRow;
	  if (oldDiff >= 0 && newDiff >= 0)
	    {
	      if (newDiff >= oldDiff)
		// we're extending the antiselection
		{
		  BOOL notified = NO;
		  for (i = _oldRow + 1; i <= _currentRow; i++)
		    {
		      if (((pos = [_selectedRows 
				   indexOfObject: 
				     [NSNumber numberWithInt: i]])
			  != NSNotFound) && (count > 1))
			{
			  [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
			  notified = YES;
			  [_selectedRows removeObjectAtIndex: pos];
			  count--;
			}
		    }

		  if (   notified 
		      && (*_selectedRow > _oldRow)
		      && (*_selectedRow <= _currentRow))
		    {
		      if ([_selectedRows count] == 0)
			{
			  NSLog(@"error!");
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = 
			    [[_selectedRows objectAtIndex: 0]
			      intValue];
			}
		    }

		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;

		  for (i = _oldRow; i > _currentRow; i--)
		    {
		      if (([_oldSelectedRows 
			     containsObject: 
			       [NSNumber numberWithInt: i]]))
			{
			  // this row was in the old selection
			  // select it
			  if ([_selectedRows 
				containsObject:
				  [NSNumber numberWithInt: i]] == NO)
			    {
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			      notified = YES;
			    }
			}
		    }
		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff <= 0)
	    {
	      if (newDiff <= oldDiff)
		// we're extending the selection
		{
		  BOOL notified = NO;
		  for (i = _oldRow - 1; i >= _currentRow; i--)
		    {
		      if (((pos = [_selectedRows 
				   indexOfObject: 
				     [NSNumber numberWithInt: i]])
			  != NSNotFound) && (count > 1))
			{
			  [tv setNeedsDisplayInRect:
			    [tv rectOfRow: i]];
			  notified = YES;
			  [_selectedRows removeObjectAtIndex: pos];
			  count--;
			}
		    }

		  if (   notified 
		      && (*_selectedRow < _oldRow)
		      && (*_selectedRow >= _currentRow))
		    {
		      if ([_selectedRows count] == 0)
			{
			  NSLog(@"error!");
			  *_selectedRow = -1;
			}
		      else
			{
			  *_selectedRow = 
			    [[_selectedRows objectAtIndex: 0]
			      intValue];
			}
		    }

		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	      else
		// we're reducing the selection
		{
		  BOOL notified = NO;

		  for (i = _oldRow; i < _currentRow; i++)
		    {
		      if ([_oldSelectedRows 
			    containsObject: 
			      [NSNumber numberWithInt: i]])
			{
			  // this row was in the old selection
			  // select it
			  if ([_selectedRows 
				containsObject:
				  [NSNumber numberWithInt: i]] == NO)
			    {
			      [tv setNeedsDisplayInRect:
				    [tv rectOfRow: i]];
			      _insertNumberInSelectionArray
				(_selectedRows,
				 [NSNumber numberWithInt: i]);
			      *_selectedRow = i;
			      notified = YES;
			    }
			  count++;
			}
		    }

		  if (notified == YES)
		    {
		      [tv _postSelectionIsChangingNotification];
		    }
		}
	    }
	  else if (oldDiff <= 0 && newDiff >= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		for (i = _oldRow; i < _originalRow; i++)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// select it
			if ([_selectedRows 
			      containsObject:
				[NSNumber numberWithInt: i]] == NO)
			  {
			    [tv setNeedsDisplayInRect:
				  [tv rectOfRow: i]];
			    _insertNumberInSelectionArray
			      (_selectedRows,
			       [NSNumber numberWithInt: i]);
			    *_selectedRow = i;
			    notified = YES;
			  }
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow + 1; i <= _currentRow; i++)
		  {
		    if (((pos = [_selectedRows 
				 indexOfObject: 
				   [NSNumber numberWithInt: i]])
			!= NSNotFound) && (count > 1))
		      {
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			notified = YES;
			[_selectedRows removeObjectAtIndex: pos];
			count--;
		      }
		  }
	      }

	      if (   notified 
		  && (*_selectedRow > _oldRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      NSLog(@"error!");
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}

	      if (notified == YES)
		{
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	  else if (oldDiff >= 0 && newDiff <= 0)
	    {
	      BOOL notified = NO;
	      
	      // we're reducing the selection
	      {
		for (i = _oldRow; i > _originalRow; i--)
		  {
		    if ([_oldSelectedRows 
			  containsObject: 
			    [NSNumber numberWithInt: i]])
		      {
			// this row was in the old selection
			// select it
			if ([_selectedRows 
			      containsObject:
				[NSNumber numberWithInt: i]] == NO)
			  {
			    [tv setNeedsDisplayInRect:
				  [tv rectOfRow: i]];
			    _insertNumberInSelectionArray
			      (_selectedRows,
			       [NSNumber numberWithInt: i]);
			    *_selectedRow = i;
			    notified = YES;
			  }
		      }
		  }
	      }
	      // then we're extending it
	      {
		for (i = _originalRow - 1; i >= _currentRow; i--)
		  {
		    if (((pos = [_selectedRows 
				 indexOfObject: 
				   [NSNumber numberWithInt: i]])
			!= NSNotFound) && (count > 1))
		      {
			[tv setNeedsDisplayInRect:
			      [tv rectOfRow: i]];
			notified = YES;
			[_selectedRows removeObjectAtIndex: pos];
			count--;
		      }
		  }
	      }

	      if (   notified 
		  && (*_selectedRow > _oldRow)
		  && (*_selectedRow <= _currentRow))
		{
		  if ([_selectedRows count] == 0)
		    {
		      NSLog(@"error!");
		      *_selectedRow = -1;
		    }
		  else
		    {
		      *_selectedRow = 
			[[_selectedRows objectAtIndex: 0]
			  intValue];
		    }
		}

	      if (notified == YES)
		{
		  [tv _postSelectionIsChangingNotification];
		}
	    }
	}
    }
}

/*
static void
_selectRowsInRange (NSTableView *tv, id delegate, 
		    int startRow, int endRow, int clickedRow)
{
  int i;
  int tmp;
  int shift = 1;

  // Switch rows if in the wrong order
  if (startRow > endRow)
    {
      tmp = startRow;
      startRow = endRow;
      endRow = tmp;
      shift = 0;
    }

  for (i = startRow + shift; i < endRow + shift; i++)
    {
      if (i != clickedRow)
	{
	  if (delegate != nil)
	    {
	      if ([delegate tableView: tv   shouldSelectRow: i] == NO)
		continue;
	    }

	  [tv selectRow: i  byExtendingSelection: YES];
	  [tv setNeedsDisplayInRect: [tv rectOfRow: i]];
	}
    }
}

static void
_deselectRowsInRange (NSTableView *tv, int startRow, int endRow, 
		      int clickedRow)
{
  int i;
  int tmp;
  int shift = 1;

  if (startRow > endRow)
    {
      tmp = startRow;
      startRow = endRow;
      endRow = tmp;
      shift = 0;
    }

  for (i = startRow + shift; i < endRow + shift; i++)
    {
      if (i != clickedRow)
	{
	  [tv deselectRow: i];
	  [tv setNeedsDisplayInRect: [tv rectOfRow: i]];
	}
    }
}
*/

/*
 * The following function can work on columns or rows; 
 * passing the correct select/deselect function switches between one 
 * and the other.  Currently used only for rows, anyway.
 */

static void
_selectionChange (NSTableView *tv, id delegate, int numberOfRows, 
		  int clickedRow, 
		  int oldSelectedRow, int newSelectedRow, 
		  void (*deselectFunction)(NSTableView *, int, int, int), 
		  void (*selectFunction)(NSTableView *, id, int, int, int))
{
  int newDistance;
  int oldDistance;

  if (oldSelectedRow == newSelectedRow)
    return;

  /* Change coordinates - distance from the center of selection */
  oldDistance = oldSelectedRow - clickedRow;
  newDistance = newSelectedRow - clickedRow;

  /* If they have different signs, then we decompose it into 
     two problems with the same sign */
  if ((oldDistance * newDistance) < 0)
    {
      _selectionChange (tv, delegate, numberOfRows, clickedRow, 
			oldSelectedRow, clickedRow, deselectFunction, 
			selectFunction);
      _selectionChange (tv, delegate, numberOfRows, clickedRow, clickedRow, 
			newSelectedRow, deselectFunction, selectFunction);
      return;
    }

  /* Otherwise, take the modulus of the distances */
  if (oldDistance < 0)
    oldDistance = -oldDistance;

  if (newDistance < 0)
    newDistance = -newDistance;

  /* If the new selection is more wide, we need to select */
  if (newDistance > oldDistance)
    {
      selectFunction (tv, delegate, oldSelectedRow, newSelectedRow, 
		      clickedRow);
    }
  else /* Otherwise to deselect */
    {
      deselectFunction (tv, newSelectedRow, oldSelectedRow, clickedRow);
    }
}

static inline BOOL 
_isCellEditable (id delegate, NSArray *tableColumns, 
		 NSTableView *tableView, int row, int column)
{
  {
    NSTableColumn *tb;
    tb = [tableColumns objectAtIndex: column];
    if ([tableView _shouldEditTableColumn: tb 
		   row: row] == NO)
      {
	return NO;
	}
  }
  
  return YES;
}

@interface GSTableCornerView : NSView
{}
@end

@implementation GSTableCornerView

- (void) drawRect: (NSRect)aRect
{
  NSRectEdge up_sides[] = {NSMaxXEdge, NSMinYEdge, 
			   NSMinXEdge, NSMaxYEdge, 
			   NSMinYEdge};
  NSRectEdge down_sides[] = {NSMaxXEdge, NSMaxYEdge, 
			     NSMinXEdge, NSMinYEdge, 
			     NSMaxYEdge};
  float grays[] = {NSBlack, NSBlack, 
		   NSLightGray, NSLightGray, 
		   NSBlack};
  NSRect rect;
  NSGraphicsContext *ctxt = GSCurrentContext();

  if (GSWViewIsFlipped(ctxt) == YES)
    {
      rect = NSDrawTiledRects(_bounds, aRect,
			       down_sides, grays, 5);
    }
  else
    {
      rect = NSDrawTiledRects(_bounds, aRect,
			       up_sides, grays, 5);
    }

  DPSsetgray(ctxt, NSDarkGray);
  DPSrectfill(ctxt, NSMinX(rect), NSMinY(rect), 
	      NSWidth(rect), NSHeight(rect));


  /*
  NSRect rect = _bounds;

  NSDrawButton (rect, aRect);
  [[NSColor controlShadowColor] set];
  rect.size.width -= 4;
  rect.size.height -= 4;
  rect.origin.x += 2;
  rect.origin.y += 2;
  NSRectFill (rect);*/
}

@end

@interface NSTableView (TableViewInternalPrivate)
- (void) _setSelectingColumns: (BOOL)flag;
- (BOOL) _editNextEditableCellAfterRow: (int)row
				column: (int)column;
- (BOOL) _editPreviousEditableCellBeforeRow: (int)row
				     column: (int)column;
- (void) _autosaveTableColumns;
- (void) _autoloadTableColumns;
@end


@implementation NSTableView 

+ (void) initialize
{
  if (self == [NSTableView class])
    {
      [self setVersion: currentVersion];
      nc = [NSNotificationCenter defaultCenter];
    }
}

/*
 * Initializing/Releasing 
 */

- (id) initWithFrame: (NSRect)frameRect
{
  self = [super initWithFrame: frameRect];
  _drawsGrid        = YES;
  _rowHeight        = 16.0;
  _intercellSpacing = NSMakeSize (2.0, 3.0);
  ASSIGN (_gridColor, [NSColor gridColor]); 
  ASSIGN (_backgroundColor, [NSColor controlBackgroundColor]); 
  ASSIGN (_tableColumns, [NSMutableArray array]);
  ASSIGN (_selectedColumns, [NSMutableArray array]);
  ASSIGN (_selectedRows, [NSMutableArray array]);
  _allowsEmptySelection = YES;
  _allowsMultipleSelection = NO;
  _allowsColumnSelection = YES;
  _allowsColumnResizing = YES;
  _allowsColumnReordering = YES;
  _autoresizesAllColumnsToFit = NO;
  _editedColumn = -1;
  _editedRow = -1;
  _selectedColumn = -1;
  _selectedRow = -1;
  _highlightedTableColumn = nil;
  _headerView = [NSTableHeaderView new];
  [_headerView setFrameSize: NSMakeSize (frameRect.size.width, 22.0)];
  [_headerView setTableView: self];
  _cornerView = [GSTableCornerView new];
  [self tile];
  return self;
}

- (void) dealloc
{
  [self abortEditing];

  RELEASE (_gridColor);
  RELEASE (_backgroundColor);
  RELEASE (_tableColumns);
  RELEASE (_selectedColumns);
  RELEASE (_selectedRows);
  TEST_RELEASE (_headerView);
  TEST_RELEASE (_cornerView);
  if (_autosaveTableColumns == YES)
    {
      [nc removeObserver: self 
	  name: NSTableViewColumnDidResizeNotification
	  object: self];
    }
  TEST_RELEASE (_autosaveName);
  if (_numberOfColumns > 0)
    {
      NSZoneFree (NSDefaultMallocZone (), _columnOrigins);
    }
  [super dealloc];
}

- (BOOL) isFlipped
{
  return YES;
}

/*
 * Table Dimensions 
 */

- (int) numberOfColumns
{
  return _numberOfColumns;
}

- (int) numberOfRows
{
  return _numberOfRows;
}

/* 
 * Columns 
 */

- (void) addTableColumn: (NSTableColumn *)aColumn
{
  [aColumn setTableView: self];
  [_tableColumns addObject: aColumn];
  _numberOfColumns++;
  if (_numberOfColumns > 1)
    {
      _columnOrigins = NSZoneRealloc (NSDefaultMallocZone (), _columnOrigins,
				      (sizeof (float)) * _numberOfColumns);
    }
  else 
    {
      _columnOrigins = NSZoneMalloc (NSDefaultMallocZone (), sizeof (float));
    }      
  [self tile];
}

- (void) removeTableColumn: (NSTableColumn *)aColumn
{
  int columnIndex = [self columnWithIdentifier: [aColumn identifier]];
  int column, i, count;

  if (columnIndex == -1)
    {
      NSLog (@"Warning: Tried to remove not-existent column from table");
      return;
    }

  /* Remove selection on this column */
  [self deselectColumn: columnIndex];
  /* Shift column indexes on the right by one */
  if (_selectedColumn > columnIndex)
    {
      _selectedColumn--;
    }

  count = [_selectedColumns count];
  for (i = 0; i < count; i++)
    {
      column = [[_selectedColumns objectAtIndex: i] intValue];
      if (column > columnIndex)
	{
	  column--;
	  [_selectedColumns replaceObjectAtIndex: i 
			    withObject: [NSNumber numberWithInt: column]];
	}
    }

  /* Now really remove the column */

  /* NB: Set table view to nil before removing the column from the
     array, because removing it from the array could deallocate it !  */
  [aColumn setTableView: nil];
  [_tableColumns removeObject: aColumn];
  _numberOfColumns--;
  if (_numberOfColumns > 0)
    {
      _columnOrigins = NSZoneRealloc (NSDefaultMallocZone (), _columnOrigins,
				      (sizeof (float)) * _numberOfColumns);
    }
  else 
    {
      NSZoneFree (NSDefaultMallocZone (), _columnOrigins);
    }      
  [self tile];
}

- (void) moveColumn: (int)columnIndex toColumn: (int)newIndex
{
  /* The range of columns which need to be shifted, 
     extremes included */
  int minRange, maxRange;
  /* Amount of shift for these columns */
  int shift;
  /* Dummy variables for the loop */
  int i, count, column;

  if ((columnIndex < 0) || (columnIndex > (_numberOfColumns - 1)))
    {
      NSLog (@"Attempt to move column outside table");
      return;
    }
  if ((newIndex < 0) || (newIndex > (_numberOfColumns - 1)))
    {
      NSLog (@"Attempt to move column to outside table");
      return;
    }

  if (columnIndex == newIndex)
    return;

  if (columnIndex > newIndex)
    {
      minRange = newIndex;
      maxRange = columnIndex - 1;
      shift = +1;
    }
  else // columnIndex < newIndex
    {
      minRange = columnIndex + 1;
      maxRange = newIndex;
      shift = -1;
    }

  /* Rearrange selection */
  if (_selectedColumn == columnIndex)
    {
      _selectedColumn = newIndex;
    }
  else if ((_selectedColumn >= minRange) && (_selectedColumn <= maxRange)) 
    {
      _selectedColumn += shift;
    }

  count = [_selectedColumns count];
  for (i = 0; i < count; i++)
    {
      column = [[_selectedColumns objectAtIndex: i] intValue];

      if (column == columnIndex)
	{
	  [_selectedColumns replaceObjectAtIndex: i 
			    withObject: [NSNumber numberWithInt: newIndex]];
	  continue;
	}

      if ((column >= minRange) && (column <= maxRange))
	{
	  column += shift;
	  [_selectedColumns replaceObjectAtIndex: i 
			    withObject: [NSNumber numberWithInt: column]];
	  continue;
	}

      if ((column > columnIndex) && (column > newIndex))
	{
	  break;
	}
    }
  /* Now really move the column */
  if (columnIndex < newIndex)
    {
      [_tableColumns insertObject: [_tableColumns objectAtIndex: columnIndex]
		     atIndex: newIndex + 1];
      [_tableColumns removeObjectAtIndex: columnIndex];
    }
  else
    {
      [_tableColumns insertObject: [_tableColumns objectAtIndex: columnIndex]
		     atIndex: newIndex];
      [_tableColumns removeObjectAtIndex: columnIndex + 1];
    }
  /* Tile */
  [self tile];

  /* Post notification */

  [self _postColumnDidMoveNotificationWithOldIndex: columnIndex
	newIndex: newIndex];

  [self _autosaveTableColumns];
}

- (NSArray *) tableColumns
{
  return AUTORELEASE ([_tableColumns mutableCopyWithZone: 
				       NSDefaultMallocZone ()]);
}

- (int) columnWithIdentifier: (id)anObject
{
  NSEnumerator	*enumerator = [_tableColumns objectEnumerator];
  NSTableColumn	*tb;
  int           return_value = 0;
  
  while ((tb = [enumerator nextObject]) != nil)
    {
      if ([[tb identifier] isEqual: anObject])
	return return_value;
      else
	return_value++;
    }
  return -1;
}

- (NSTableColumn *) tableColumnWithIdentifier:(id)anObject
{
  int indexOfColumn = [self columnWithIdentifier: anObject];

  if (indexOfColumn == -1)
    return nil;
  else 
    return [_tableColumns objectAtIndex: indexOfColumn];
}

/* 
 * Data Source 
 */

- (id) dataSource
{
  return _dataSource;
}

- (void) setDataSource: (id)anObject
{
  /* Used only for readability */
  const SEL sel_a = @selector (numberOfRowsInTableView:);
  const SEL sel_b = @selector (tableView:objectValueForTableColumn:row:);
  const SEL sel_c = @selector(tableView:setObjectValue:forTableColumn:row:);
  if ([anObject respondsToSelector: sel_a] == NO) 
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"Data Source doesn't respond to numberOfRowsInTableView:"];
    }
  
  if ([anObject respondsToSelector: sel_b] == NO) 
    {
      [NSException raise: NSInternalInconsistencyException 
		   format: @"Data Source doesn't respond to "
		   @"tableView:objectValueForTableColumn:row:"];
    }
  
  
  _dataSource_editable = [anObject respondsToSelector: sel_c];

  /* We do *not* retain the dataSource, it's like a delegate */
  _dataSource = anObject;
  [self tile];
  [self reloadData];
}

/* 
 * Loading data 
 */

- (void) reloadData
{
  [self noteNumberOfRowsChanged];
  [self setNeedsDisplay: YES];
}

/* 
 * Target-action 
 */

- (void) setDoubleAction: (SEL)aSelector
{
  _doubleAction = aSelector;
}

- (SEL) doubleAction
{
  return _doubleAction;
}

- (void) setTarget:(id)anObject
{
  _target = anObject;
}

- (id) target
{
  return _target;
}

- (int) clickedColumn
{
  return _clickedColumn;
}

- (int) clickedRow
{
  return _clickedRow;
}

/*
 * The NSTableHeaderView calls this method when it receives a double click.
 */

- (void) _sendDoubleActionForColumn: (int)columnIndex
{
  _clickedColumn = columnIndex;
  _clickedRow = -1;
  [self sendAction: _doubleAction  to: _target]; 
}

/*
 * And this when it gets a simple click which turns out to be for 
 * selecting/deselecting a column.
 */

- (void) _selectColumn: (int)columnIndex
	     modifiers: (unsigned int)modifiers
{
  SEL selector;

  if (_allowsColumnSelection == NO)
    {
      return;
    }

  if ([self isColumnSelected: columnIndex] == YES)
    {
      if (([_selectedColumns count] == 1) && (_allowsEmptySelection == NO))
	{
	  return;
	}
	  
      if ([self _shouldSelectionChange] == NO)
	{
	  return;
	}

      if (_selectingColumns == NO)
	{
	  [self _setSelectingColumns: YES];
	}

      [self deselectColumn: columnIndex];
      //      [self setNeedsDisplayInRect: [self rectOfColumn: columnIndex]];
      return;
    }
  else // column is not selected 
    {
      BOOL newSelection;
      
      if ((modifiers & (NSShiftKeyMask | NSAlternateKeyMask)) 
	  && _allowsMultipleSelection)
	{
	  newSelection = NO;
	}
      else
	{
	  newSelection = YES;
	}

      if (([_selectedColumns count] > 0) && (_allowsMultipleSelection == NO)
	  && (newSelection == NO))
	{
	  return;
	}
      
      if ([self _shouldSelectionChange] == NO)
	{
	  return;
	}

      
      {
	NSTableColumn *tc = [_tableColumns objectAtIndex: columnIndex];
	if ([self _shouldSelectTableColumn: tc] == NO)
	  {
	    return;
	  }
      }

      if (_selectingColumns == NO)
	{
	  [self _setSelectingColumns: YES];
	}

      if (newSelection == YES)
	{
	  /* No shift or alternate key pressed: clear the old selection */
	  
	  /* Compute rect to redraw to clear the old selection */
	  /*
	  int column, i, count = [_selectedColumns count];
	  
	  for (i = 0; i < count; i++)
	    {
	      column = [[_selectedColumns objectAtIndex: i] intValue];
	      [self setNeedsDisplayInRect: [self rectOfColumn: column]];
	    }
	  */
	  /* Draw the new selection */
	  [self selectColumn: columnIndex  byExtendingSelection: NO];
	  //	  [self setNeedsDisplayInRect: [self rectOfColumn: columnIndex]];
	}
      else /* Simply add to the old selection */
	{
	  [self selectColumn: columnIndex  byExtendingSelection: YES];
	  //	  [self setNeedsDisplayInRect: [self rectOfColumn: columnIndex]];
	}
    }
}


/*
 *Configuration 
 */ 

- (void) setAllowsColumnReordering: (BOOL)flag
{
  _allowsColumnReordering = flag;
}

- (BOOL) allowsColumnReordering
{
  return _allowsColumnReordering;
}

- (void) setAllowsColumnResizing: (BOOL)flag
{
  _allowsColumnResizing = flag;
}

- (BOOL) allowsColumnResizing
{
  return _allowsColumnResizing;
}

- (void) setAllowsMultipleSelection: (BOOL)flag
{
  _allowsMultipleSelection = flag;
}

- (BOOL) allowsMultipleSelection
{
  return _allowsMultipleSelection;
}

- (void) setAllowsEmptySelection: (BOOL)flag
{
  _allowsEmptySelection = flag;
}

- (BOOL) allowsEmptySelection
{
  return _allowsEmptySelection;
}

- (void) setAllowsColumnSelection: (BOOL)flag
{
  _allowsColumnSelection = flag;
}

- (BOOL) allowsColumnSelection
{
  return _allowsColumnSelection;
}

/* 
 * Drawing Attributes 
 */

- (void) setIntercellSpacing: (NSSize)aSize
{
  _intercellSpacing = aSize;
  [self setNeedsDisplay: YES];
}

- (NSSize) intercellSpacing
{
  return _intercellSpacing;
}

- (void) setRowHeight: (float)rowHeight
{
  _rowHeight = rowHeight;
  [self tile];
}

- (float) rowHeight
{
  return _rowHeight;
}

- (void) setBackgroundColor: (NSColor *)aColor
{
  ASSIGN (_backgroundColor, aColor);
}

- (NSColor *) backgroundColor
{
  return _backgroundColor;
}

/*
 * Selecting Columns and Rows
 */
- (void) selectColumn: (int)columnIndex 
 byExtendingSelection: (BOOL)flag
{
  NSNumber *num  = [NSNumber numberWithInt: columnIndex];
  
  if (columnIndex < 0 || columnIndex > _numberOfColumns)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Column index out of table in selectColumn"];
    }

  _selectingColumns = YES;

  if (flag == NO)
    {
      /* If the current selection is the one we want, just ends editing
       * This is not just a speed up, it prevents us from sending
       * a NSTableViewSelectionDidChangeNotification.
       * This behaviour is required by the specifications */
      if ([_selectedColumns count] == 1
	  && [_selectedColumns containsObject: num] == YES)
	{
	  /* Stop editing if any */
	  if (_textObject != nil)
	    {
	      [self validateEditing];
	      [self abortEditing];
	    }  
	  return;
	} 

      /* If _numberOfColumns == 1, we can skip trying to deselect the
	 only column - because we have been called to select it. */
      if (_numberOfColumns > 1)
	{
	  [_selectedColumns removeAllObjects];
	  [self setNeedsDisplay: YES];
	  if (_headerView)
	    {
	      [_headerView setNeedsDisplay: YES];
	    }
	  _selectedColumn = -1;
	}
    }
  else // flag == YES
    {
      if (_allowsMultipleSelection == NO)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Can not extend selection in table view when multiple selection is disabled"];  
	}
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }

  /* Now select the column and post notification only if needed */ 
  if ([_selectedColumns containsObject: num] == NO)
    {
      _insertNumberInSelectionArray (_selectedColumns, num);
      _selectedColumn = columnIndex;

      [self setNeedsDisplayInRect: [self rectOfColumn: columnIndex]];
      if (_headerView)
	{
	  [_headerView setNeedsDisplayInRect: 
			 [_headerView headerRectOfColumn: columnIndex]];
	}
      [self _postSelectionDidChangeNotification];
    }
  else /* Otherwise simply change the last selected column */
    {
      _selectedColumn = columnIndex;
    }
}

#if 0
- (void) internal_selectRow: (int)rowIndex
byExtendingSelection: (BOOL)flag
{
  NSNumber *num  = [NSNumber numberWithInt: rowIndex];

  if (rowIndex < 0 || rowIndex > _numberOfRows)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Row index out of table in selectRow"];
    }

  _selectingColumns = NO;

  if (flag == NO)
    {
      /* If the current selection is the one we want, just ends editing
       * This is not just a speed up, it prevents us from sending
       * a NSTableViewSelectionDidChangeNotification.
       * This behaviour is required by the specifications */
      if ([_selectedRows count] == 1
	  && [_selectedRows containsObject: num] == YES)
	{
	  /* Stop editing if any */
	  if (_textObject != nil)
	    {
	      [self validateEditing];
	      [self abortEditing];
	    }
	  return;
	} 

      /* If _numberOfRows == 1, we can skip trying to deselect the
	 only row - because we have been called to select it. */
      if (_numberOfRows > 1)
	{
	  [_selectedRows removeAllObjects];
	  _selectedRow = -1;
	}
    }
  else // flag == YES
    {
      if (_allowsMultipleSelection == NO)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Can not extend selection in table view when multiple selection is disabled"];  
	}
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }  

  /* Now select the row and post notification only if needed */ 
  if ([_selectedRows containsObject: num] == NO)
    {
      _insertNumberInSelectionArray (_selectedRows, num);
      _selectedRow = rowIndex;
      [self _postSelectionIsChangingNotification];
    }
  else /* Otherwise simply change the last selected row */
    {
      _selectedRow = rowIndex;
    }
}
#endif

- (void) selectRow: (int)rowIndex
byExtendingSelection: (BOOL)flag
{
  NSNumber *num  = [NSNumber numberWithInt: rowIndex];

  if (rowIndex < 0 || rowIndex >= _numberOfRows)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Row index out of table in selectRow"];
    }

  if (_selectingColumns)
    {
      _selectingColumns = NO;
      if (_headerView)
	{
	  [_headerView setNeedsDisplay: YES];
	}
    }

  if (flag == NO)
    {
      /* If the current selection is the one we want, just ends editing
       * This is not just a speed up, it prevents us from sending
       * a NSTableViewSelectionDidChangeNotification.
       * This behaviour is required by the specifications */
      if ([_selectedRows count] == 1
	  && [_selectedRows containsObject: num] == YES)
	{
	  /* Stop editing if any */
	  if (_textObject != nil)
	    {
	      [self validateEditing];
	      [self abortEditing];
	    }
	  return;
	} 

      /* If _numberOfRows == 1, we can skip trying to deselect the
	 only row - because we have been called to select it. */
      if (_numberOfRows > 1)
	{
	  [self setNeedsDisplay: YES];
	  [_selectedRows removeAllObjects];
	  _selectedRow = -1;
	}
    }
  else // flag == YES
    {
      if (_allowsMultipleSelection == NO)
	{
	  [NSException raise: NSInternalInconsistencyException
		       format: @"Can not extend selection in table view when multiple selection is disabled"];  
	}
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }  

  /* Now select the row and post notification only if needed */ 
  if ([_selectedRows containsObject: num] == NO)
    {
      _insertNumberInSelectionArray (_selectedRows, num);
      _selectedRow = rowIndex;
      [self setNeedsDisplayInRect: [self rectOfRow: rowIndex]];
      [self _postSelectionDidChangeNotification];
    }
  else /* Otherwise simply change the last selected row */
    {
      _selectedRow = rowIndex;
    }
}

- (void) deselectColumn: (int)columnIndex
{
  NSNumber *num  = [NSNumber numberWithInt: columnIndex];

  if ([_selectedColumns containsObject: num] == NO)
    {
      return;
    }

  /* Now by internal consistency we assume columnIndex is in fact a
     valid column index, since it was the index of a selected column */

  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }
  
  _selectingColumns = YES;

  [_selectedColumns removeObject: num];

  if (_selectedColumn == columnIndex)
    {
      int i, count = [_selectedColumns count]; 
      int nearestColumn = -1;
      int nearestColumnDistance = _numberOfColumns;
      int column, distance;
      for (i = 0; i < count; i++)
	{
	  column = [[_selectedColumns objectAtIndex: i] intValue];

	  distance = column - columnIndex;
	  if (distance < 0)
	    {
	      distance = -distance;
	    }

	  if (distance < nearestColumnDistance)
	    {
	      nearestColumn = column;
	    }
	}
      _selectedColumn = nearestColumn;
    }

  [self setNeedsDisplayInRect: [self rectOfColumn: columnIndex]];
  if (_headerView)
    {
      [_headerView setNeedsDisplayInRect: 
		     [_headerView headerRectOfColumn: columnIndex]];
    }

  [self _postSelectionDidChangeNotification];
}

- (void) deselectRow: (int)rowIndex
{
  NSNumber *num  = [NSNumber numberWithInt: rowIndex];

  if ([_selectedRows containsObject: num] == NO)
    {
      return;
    }

  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }

  _selectingColumns = NO;

  [_selectedRows removeObject: num];

  if (_selectedRow == rowIndex)
    {
      int i, count = [_selectedRows count]; 
      int nearestRow = -1;
      int nearestRowDistance = _numberOfRows;
      int row, distance;
      for (i = 0; i < count; i++)
	{
	  row = [[_selectedRows objectAtIndex: i] intValue];

	  distance = row - rowIndex;
	  if (distance < 0)
	    {
	      distance = -distance;
	    }

	  if (distance < nearestRowDistance)
	    {
	      nearestRow = row;
	    }
	}
      _selectedRow = nearestRow;
    }

  [self _postSelectionDidChangeNotification];
}

- (int) numberOfSelectedColumns
{
  return [_selectedColumns count];
}

- (int) numberOfSelectedRows
{
  return [_selectedRows count];
}

- (int) selectedColumn
{
  return _selectedColumn;
}

- (int) selectedRow
{
  return _selectedRow;
}

- (BOOL) isColumnSelected: (int)columnIndex
{
  NSNumber *num  = [NSNumber numberWithInt: columnIndex];
  return [_selectedColumns containsObject: num];
}

- (BOOL) isRowSelected: (int)rowIndex
{
  NSNumber *num  = [NSNumber numberWithInt: rowIndex];
  return [_selectedRows containsObject: num];
}

- (NSEnumerator *) selectedColumnEnumerator
{
  return [_selectedColumns objectEnumerator];
}

- (NSEnumerator *) selectedRowEnumerator
{
  return [_selectedRows objectEnumerator];
}

- (void) selectAll: (id) sender
{
  SEL selector; 

  if (_allowsMultipleSelection == NO)
    return;

  /* Ask the delegate if we can select all columns or rows */
  if (_selectingColumns == YES)
    {
      if ([_selectedColumns count] == _numberOfColumns)
	{
	  // Nothing to do !
	  return;
	}

      {
	NSEnumerator *enumerator = [_tableColumns objectEnumerator];
	NSTableColumn *tb;
	while ((tb = [enumerator nextObject]) != nil)
	  {
	    if ([self _shouldSelectTableColumn: tb] == NO)
	      {
		return;
	      }
	  }
      }
    }
  else // selecting rows
    {
      if ([_selectedRows count] == _numberOfRows)
	{
	  // Nothing to do !
	  return;
	}

      {
	int row; 
	
	for (row = 0; row < _numberOfRows; row++)
	  {
	    if ([self _shouldSelectRow: row] == NO)
	      return;
	  }
      }
    }

  /* Stop editing if any */
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }  

  /* Do the real selection */
  if (_selectingColumns == YES)
    {
      int column;

      [_selectedColumns removeAllObjects];
      for (column = 0; column < _numberOfColumns; column++)
	{
	  NSNumber *num  = [NSNumber numberWithInt: column];
	  [_selectedColumns addObject: num];
	}
    }
  else // selecting rows
    {
      int row;

      [_selectedRows removeAllObjects];
      for (row = 0; row < _numberOfRows; row++)
	{
	  NSNumber *num  = [NSNumber numberWithInt: row];
	  [_selectedRows addObject: num];
	}
    }
  
  [self _postSelectionDidChangeNotification];
}



- (void) deselectAll: (id) sender
{
  SEL selector; 

  if (_allowsEmptySelection == NO)
    return;

  if ([self _shouldSelectionChange] == NO)
    {
      return;
    }
  
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }
	  
  if (([_selectedColumns count] > 0) || ([_selectedRows count] > 0))
    {
      [_selectedColumns removeAllObjects];
      [_selectedRows removeAllObjects];
      _selectedColumn = -1;
      _selectedRow = -1;
      _selectingColumns = NO;
      [self _postSelectionDidChangeNotification];
    }
  else
    {
      _selectedColumn = -1;
      _selectedRow = -1;
      _selectingColumns = NO;
    }
}

/* 
 * Grid Drawing attributes 
 */

- (void) setDrawsGrid: (BOOL)flag
{
  _drawsGrid = flag;
}

- (BOOL) drawsGrid
{
  return _drawsGrid;
}

- (void) setGridColor: (NSColor *)aColor
{
  ASSIGN (_gridColor, aColor);
}

- (NSColor *) gridColor
{
  return _gridColor;
}

/* 
 * Editing Cells 
 */

- (BOOL) abortEditing
{ 
  if (_textObject)
    {
      [_textObject setString: @""];
      [_editedCell endEditing: _textObject];
      RELEASE (_editedCell);
      [self setNeedsDisplayInRect: 
	      [self frameOfCellAtColumn: _editedColumn row: _editedRow]];
      _editedRow = -1;
      _editedColumn = -1;
      _editedCell = nil;
      _textObject = nil;
      return YES;
    }
  else
    return NO;
}

- (NSText *) currentEditor
{
  if (_textObject && ([_window firstResponder] == _textObject))
    return _textObject;
  else
    return nil;
}

- (void) validateEditing
{
  if (_textObject)
    {
      NSFormatter *formatter;
      NSString *string;
      id newObjectValue;
      BOOL validatedOK = YES;

      formatter = [_editedCell formatter];
      string = AUTORELEASE ([[_textObject text] copy]);

      if (formatter == nil)
	{
	  newObjectValue = string;
	}
      else
	{
	  NSString *error;
	  
	  if ([formatter getObjectValue: &newObjectValue 
			 forString: string 
			 errorDescription: &error] == NO)
	    {
	      if ([_delegate control: self 
			     didFailToFormatString: string 
			     errorDescription: error] == NO)
		{
		  validatedOK = NO;
		}
	      else
		{
		  newObjectValue = string;
		}
	    }
	}
      if (validatedOK == YES)
	{
	  [_editedCell setObjectValue: newObjectValue];
	  
	  if (_dataSource_editable)
	    {
	      NSTableColumn *tb;
	      
	      tb = [_tableColumns objectAtIndex: _editedColumn];
	      
	      [self _setObjectValue: newObjectValue
		    forTableColumn: tb
		    row: _editedRow];

	      //[_dataSource tableView: self  setObjectValue: newObjectValue
	      //	 forTableColumn: tb  row: _editedRow];
	    }
	}
    }
}

- (void) editColumn: (int) columnIndex 
		row: (int) rowIndex 
	  withEvent: (NSEvent *) theEvent 
	     select: (BOOL) flag
{
  NSText *t;
  NSTableColumn *tb;
  NSRect drawingRect;
  unsigned length = 0;

  // We refuse to edit cells if the delegate can not accept results 
  // of editing.
  if (_dataSource_editable == NO)
    {
      return;
    }
  
  [self scrollRowToVisible: rowIndex];
  [self scrollColumnToVisible: columnIndex];

  if (rowIndex < 0 || rowIndex >= _numberOfRows 
      || columnIndex < 0 || columnIndex >= _numberOfColumns)
    {
      [NSException raise: NSInvalidArgumentException
		   format: @"Row/column out of index in edit"];
    }
  
  if (_textObject != nil)
    {
      [self validateEditing];
      [self abortEditing];
    }

  // Now (_textObject == nil)

  t = [_window fieldEditor: YES  forObject: self];

  if ([t superview] != nil)
    {
      if ([t resignFirstResponder] == NO)
	{
	  return;
	}
    }
  
  _editedRow = rowIndex;
  _editedColumn = columnIndex;

  // Prepare the cell
  tb = [_tableColumns objectAtIndex: columnIndex];
  // NB: need to be released when no longer used
  _editedCell = [[tb dataCellForRow: rowIndex] copy];

  [_editedCell setEditable: YES];
  [_editedCell setObjectValue: [self _objectValueForTableColumn: tb
				     row: rowIndex]];
  /* [_dataSource tableView: self
     objectValueForTableColumn: tb
     row: rowIndex]]; */

  // We really want the correct background color!
  if ([_editedCell respondsToSelector: @selector(setBackgroundColor:)])
    {
      [(NSTextFieldCell *)_editedCell setBackgroundColor: _backgroundColor];
    }
  else
    {
      [t setBackgroundColor: _backgroundColor];
    }
  
  // But of course the delegate can mess it up if it wants
  if (_del_responds)
    {
      [_delegate tableView: self   willDisplayCell: _editedCell 
		 forTableColumn: tb   row: rowIndex];
    }

  /* Please note the important point - calling stringValue normally
     causes the _editedCell to call the validateEditing method of its
     control view ... which happens to be this NSTableView object :-)
     but we don't want any spurious validateEditing to be performed
     before the actual editing is started (otherwise you easily end up
     with the table view picking up the string stored in the field
     editor, which is likely to be the string resulting from the last
     edit somewhere else ... getting into the bug that when you TAB
     from one cell to another one, the string is copied!), so we must
     call stringValue when _textObject is still nil.  */
  if (flag)
    {
      length = [[_editedCell stringValue] length];
    }

  _textObject = [_editedCell setUpFieldEditorAttributes: t];

  drawingRect = [self frameOfCellAtColumn: columnIndex  row: rowIndex];
  if (flag)
    {
      [_editedCell selectWithFrame: drawingRect
		   inView: self
		   editor: _textObject
		   delegate: self
		   start: 0
		   length: length];
    }
  else
    {
      [_editedCell editWithFrame: drawingRect
		   inView: self
		   editor: _textObject
		   delegate: self
		   event: theEvent];
    }
  return;    
}

- (int) editedRow
{
  return _editedRow;  
}

- (int) editedColumn
{
  return _editedColumn;
}

- (void) _setSelectingColumns: (BOOL)flag
{
  if (flag == _selectingColumns)
    return;
  
  if (flag == NO)
    {
      /* Compute rect to redraw to clear the old column selection */
      int column, i, count = [_selectedColumns count];
      
      for (i = 0; i < count; i++)
	{
	  column = [[_selectedColumns objectAtIndex: i] intValue];
	  [self setNeedsDisplayInRect: [self rectOfColumn: column]];
	}	  
      [_selectedColumns removeAllObjects];
      _selectedColumn = -1;  
      _selectingColumns = NO;
    }
  else
    {
      /* Compute rect to redraw to clear the old row selection */
      int row, i, count = [_selectedRows count];
      
      for (i = 0; i < count; i++)
	{
	  row = [[_selectedRows objectAtIndex: i] intValue];
	  [self setNeedsDisplayInRect: [self rectOfRow: row]];
	}	  
      [_selectedRows removeAllObjects];
      _selectedRow = -1;  
      _selectingColumns = YES;
    }
}

- (void) mouseDown: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSPoint initialLocation = [theEvent locationInWindow];
  NSTableColumn *tb;
  int clickCount;
  BOOL shouldEdit;
  int _originalRow;
  int _oldRow = -1;
  int _currentRow = -1;

  //
  // Pathological case -- ignore mouse down
  //
  if ((_numberOfRows == 0) || (_numberOfColumns == 0))
    {
      [super mouseDown: theEvent];
      return; 
    }
  
  clickCount = [theEvent clickCount];

  if (clickCount > 2)
    return;

  // Determine row and column which were clicked
  location = [self convertPoint: location  fromView: nil];
  _clickedRow  = [self rowAtPoint: location];
  _clickedColumn = [self columnAtPoint: location];
  _originalRow = _clickedRow;

  // Selection
  if (clickCount == 1)
    {
      SEL selector;
      unsigned int modifiers = [theEvent modifierFlags];
      BOOL startedPeriodicEvents = NO;
      unsigned int eventMask = (NSLeftMouseUpMask 
				| NSLeftMouseDownMask
				| NSLeftMouseDraggedMask 
				| NSPeriodicMask);
      unsigned selectionMode;
      NSPoint mouseLocationWin;
      NSDate *distantFuture = [NSDate distantFuture];
      NSEvent *lastEvent;
      NSSet *_oldSelectedRows;
      id delegateIfItTakesPart;
      BOOL mouseUp = NO;
      BOOL done = NO;
      BOOL draggingPossible = [self _isDraggingSource];
      NSRect visibleRect = [self convertRect: [self visibleRect]
				 toView: nil];
      float minYVisible = NSMinY (visibleRect);
      float maxYVisible = NSMaxY (visibleRect);

      /* We have three zones of speed. 
	 0   -  50 pixels: period 0.2  <zone 1>
	 50  - 100 pixels: period 0.1  <zone 2>
	 100 - 150 pixels: period 0.01 <zone 3> */
      float oldPeriod = 0;
      inline float computePeriod ()
	{
	  float distance = 0;
	  
	  if (mouseLocationWin.y < minYVisible) 
	    {
	      distance = minYVisible - mouseLocationWin.y; 
	    }
	  else if (mouseLocationWin.y > maxYVisible)
	    {
	      distance = mouseLocationWin.y - maxYVisible;
	    }
	  
	  if (distance < 50)
	    return 0.2;
	  else if (distance < 100)
	    return 0.1;
	  else 
	    return 0.01;
	}
      
      selectionMode = 0;
      if (_allowsMultipleSelection == YES)
	{
	  selectionMode |= ALLOWS_MULTIPLE;
	}

      if (_allowsEmptySelection == YES)
	{
	  selectionMode |= ALLOWS_EMPTY;
	}
      
      if (modifiers & NSShiftKeyMask)
	{
	  selectionMode |= SHIFT_DOWN;
	}
      
      if ([_selectedRows containsObject: 
			   [NSNumber numberWithInt: _clickedRow]] == NO)
	{
	  selectionMode |= ADDING_ROW;
	}

      if (modifiers & NSControlKeyMask)
	{
	  selectionMode |= CONTROL_DOWN;
	  if (_allowsMultipleSelection == YES)
	    {
	      _originalRow = _selectedRow;
	      selectionMode |= SHIFT_DOWN;
	      selectionMode |= ADDING_ROW;
	    }
	}
      
      // does the delegate take part in the selection
      /*
      selector = @selector (tableView:shouldSelectRow:);
      if ([_delegate respondsToSelector: selector] == YES)
	{
	  delegateIfItTakesPart = _delegate;
	}
      else
	{
	  delegateIfItTakesPart = nil;
	}
      */

      // is the delegate ok for a new selection ?
      if ([self _shouldSelectionChange] == NO)
	{
	  return;
	}

      // if we are in column selection mode, stop it
      if (_selectingColumns == YES)
	{
	  if (_headerView)
	    {
	      int i;
	      for (i = 0; i < _numberOfColumns; i++)
		{
		  if ([self isColumnSelected: i])
		    [_headerView setNeedsDisplayInRect: 
				   [_headerView headerRectOfColumn: i]];
		}
	    }
	  [self _setSelectingColumns: NO];
	}

      // let's sort the _selectedRows
      _oldSelectedRows = [[NSSet alloc] 
			   initWithArray: _selectedRows];

      lastEvent = theEvent;
      while (done != YES)
	{
	  switch ([lastEvent type])
	    {
	    case NSLeftMouseUp:
	      mouseLocationWin = [lastEvent locationInWindow]; 
	      if ((mouseLocationWin.y > minYVisible) 
		  && (mouseLocationWin.y < maxYVisible))
		// mouse dragged within table
		{
		  NSPoint mouseLocationView;
		  
		  if (startedPeriodicEvents == YES)
		    {
		      [NSEvent stopPeriodicEvents];
		      startedPeriodicEvents = NO;
		    }
		  mouseLocationView = [self convertPoint: 
					      mouseLocationWin 
					    fromView: nil];
		  mouseLocationView.x = _bounds.origin.x;
		  _oldRow = _currentRow;
		  _currentRow = [self rowAtPoint: mouseLocationView];
		  if (_oldRow == _currentRow)
		    {
		      // the row hasn't changed, nothing to do
		    }
		  else
		    {
		      // we should now compute the new selection
		      
		      computeNewSelection(self,
					  delegateIfItTakesPart,
					  _oldSelectedRows, 
					  _selectedRows,
					  _originalRow,
					  _oldRow,
					  _currentRow,
					  &_selectedRow,
					  selectionMode);
		      [self displayIfNeeded];
		    }
		}
	      else
		// Mouse dragged out of the table
		{
		  // we don't care
		}
	      done = YES;
	      break;
	    case NSLeftMouseDown:
	    case NSLeftMouseDragged:
	      mouseLocationWin = [lastEvent locationInWindow]; 
	      if (draggingPossible == YES)
		{
		  //		  NSLog(@"draggingPossible");
		  if (mouseLocationWin.y - initialLocation.y > 2
		      || mouseLocationWin.y - initialLocation.y < -2)
		    {
		      draggingPossible = NO;
		    }
		  else if (mouseLocationWin.x - initialLocation.x >=4
			   || mouseLocationWin.x - initialLocation.x <= -4)
		    {
		      NSPasteboard *pboard;
		      //		      NSLog(@"start dragging");

		      pboard = [NSPasteboard pasteboardWithName: NSDragPboard];
		      
		      if ([self _writeRows: _selectedRows
				toPasteboard: pboard] == YES)
			{
			  NSPoint p = NSZeroPoint;
			  NSImage *dragImage =
			    [self dragImageForRows: _selectedRows
				  event: theEvent
				  dragImageOffset: &p];

			  [self dragImage: dragImage
				at: NSZeroPoint
				offset: NSMakeSize(0, 0)
				event: theEvent
				pasteboard: pboard
				source: self
				slideBack: YES];
			  return;
			}
		      else
			{
			  //			  NSLog(@"dragging refused");
			  draggingPossible = NO;
			}
		    }
		}
	      else if ((mouseLocationWin.y > minYVisible) 
		       && (mouseLocationWin.y < maxYVisible))
		// mouse dragged within table
		{
		  NSPoint mouseLocationView;
		  
		  if (startedPeriodicEvents == YES)
		    {
		      [NSEvent stopPeriodicEvents];
		      startedPeriodicEvents = NO;
		    }
		  mouseLocationView = [self convertPoint: 
					      mouseLocationWin 
					    fromView: nil];
		  mouseLocationView.x = _bounds.origin.x;
		  _oldRow = _currentRow;
		  _currentRow = [self rowAtPoint: mouseLocationView];

		  if (_oldRow == _currentRow)
		    {
		      // the row hasn't changed, nothing to do
		    }
		  else
		    {
		      // we should now compute the new selection
		      
		      computeNewSelection(self,
					  delegateIfItTakesPart,
					  _oldSelectedRows, 
					  _selectedRows,
					  _originalRow,
					  _oldRow,
					  _currentRow,
					  &_selectedRow,
					  selectionMode);
		      [self displayIfNeeded];
		      //		      [_window flushWindow];		      
		    }
		}
	      else
		// Mouse dragged out of the table
		{
		  if (startedPeriodicEvents == YES)
		    {
		      /* Check - if the mouse did not change zone, 
			 we do nothing */
		      if (computePeriod () == oldPeriod)
			break;

		      [NSEvent stopPeriodicEvents];
		    }
		  /* Start periodic events */
		  oldPeriod = computePeriod ();
			
		  [NSEvent startPeriodicEventsAfterDelay: 0
			   withPeriod: oldPeriod];
		  startedPeriodicEvents = YES;
		  if (mouseLocationWin.y <= minYVisible) 
		    mouseUp = NO;
		  else
		    mouseUp = YES;
		}
	      break;
	    case NSPeriodic:
	      if (draggingPossible)
		{
		}
	      else if (mouseUp == NO) // mouse below the table
		{
		  if (_currentRow >= _numberOfRows - 1)
		    {
		      // last row already selected, nothing to do
		    }
		  else
		    {
		      _oldRow = _currentRow;
		      _currentRow++;
		      [self scrollRowToVisible: _currentRow];
		      // we should now compute the new selection
		      computeNewSelection(self,
					  delegateIfItTakesPart,
					  _oldSelectedRows, 
					  _selectedRows,
					  _originalRow,
					  _oldRow,
					  _currentRow,
					  &_selectedRow,
					  selectionMode);

		      [self displayIfNeeded];
		    }
		}
	      else /* mouse above the table */
		{
		  if (_currentRow <= 0)
		    {
		      // first row already selected, nothing to do
		    }
		  else
		    {
		      _oldRow = _currentRow;
		      _currentRow--;
		      [self scrollRowToVisible: _currentRow];
		      // we should now compute the new selection
		      computeNewSelection(self,
					  delegateIfItTakesPart,
					  _oldSelectedRows, 
					  _selectedRows,
					  _originalRow,
					  _oldRow,
					  _currentRow,
					  &_selectedRow,
					  selectionMode);

		      [self displayIfNeeded];
		    }
		}
	      break;
	    default:
	      break;
	    }
	  if (done == NO)
	    {
	      lastEvent = [NSApp nextEventMatchingMask: eventMask 
				 untilDate: distantFuture
				 inMode: NSEventTrackingRunLoopMode 
				 dequeue: YES]; 
	    }
	}
	    
      if (startedPeriodicEvents == YES)
	[NSEvent stopPeriodicEvents];

      [_selectedRows sortUsingSelector: @selector(compare:)];

      if ([_selectedRows 
	    isEqualToArray: 
	      [[_oldSelectedRows allObjects] 
		sortedArrayUsingSelector: @selector(compare:)]] == NO)
	{
	  [self _postSelectionDidChangeNotification];
	}	    
      return;
    }

  // Double-click events

  if ([self isRowSelected: _clickedRow] == NO)
    return;

  tb = [_tableColumns objectAtIndex: _clickedColumn];

  shouldEdit = YES;

  if ([tb isEditable] == NO)
    {
      shouldEdit = NO;
    }
  else if ([self _shouldEditTableColumn: tb 
		 row: _clickedRow] == NO)
    {
      shouldEdit = NO;
    }
  if (shouldEdit == NO)
    {
      // Send double-action but don't edit
      [self sendAction: _doubleAction to: _target];
      return;
    }

  // It is OK to edit column.  Go on, do it.
  [self editColumn: _clickedColumn  row: _clickedRow
	withEvent: theEvent  select: NO];
}

/*
- (void) mouseDown2: (NSEvent *)theEvent
{
  NSPoint location = [theEvent locationInWindow];
  NSTableColumn *tb;
  int clickCount;
  BOOL shouldEdit;

  //
  // Pathological case -- ignore mouse down
  //
  if ((_numberOfRows == 0) || (_numberOfColumns == 0))
    {
      [super mouseDown: theEvent];
      return; 
    }
  
  clickCount = [theEvent clickCount];

  if (clickCount > 2)
    return;

  // Determine row and column which were clicked
  location = [self convertPoint: location  fromView: nil];
  _clickedRow = [self rowAtPoint: location];
  _clickedColumn = [self columnAtPoint: location];

  // Selection
  if (clickCount == 1)
    {
      SEL selector;
      unsigned int modifiers;
      modifiers = [theEvent modifierFlags];

      // Unselect a selected row if the shift key is pressed
      if ([self isRowSelected: _clickedRow] == YES
	  && (modifiers & NSShiftKeyMask))
	{
	  if (([_selectedRows count] == 1) && (_allowsEmptySelection == NO))
	    return;

	  selector = @selector (selectionShouldChangeInTableView:);
	  if ([_delegate respondsToSelector: selector] == YES) 
	    {
	      if ([_delegate selectionShouldChangeInTableView: self] == NO)
		{
		  return;
		}
	    }

	  if (_selectingColumns == YES)
	    {
	      [self _setSelectingColumns: NO];
	    }
	 
	  [self deselectRow: _clickedRow];
	  [self setNeedsDisplayInRect: [self rectOfRow: _clickedRow]];
	  return;
	}
      else // row is not selected 
	{
	  BOOL newSelection;

	  if ((modifiers & (NSShiftKeyMask | NSAlternateKeyMask)) 
	      && _allowsMultipleSelection)
	    newSelection = NO;
	  else
	    newSelection = YES;

	  selector = @selector (selectionShouldChangeInTableView:);
	  if ([_delegate respondsToSelector: selector] == YES) 
	    {
	      if ([_delegate selectionShouldChangeInTableView: self] == NO)
		{
		  return;
		}
	    }
	  
	  selector = @selector (tableView:shouldSelectRow:);
	  if ([_delegate respondsToSelector: selector] == YES) 
	    {
	      if ([_delegate tableView: self 
			     shouldSelectRow: _clickedRow] == NO)
		{
		  return;
		}
	    }

	  if (_selectingColumns == YES)
	    {
	      [self _setSelectingColumns: NO];
	    }

	  if (newSelection == YES)
	    {
	      // No shift or alternate key pressed: clear the old selection
	      
	      // Compute rect to redraw to clear the old selection
	      int row, i, count = [_selectedRows count];
	      
	      for (i = 0; i < count; i++)
		{
		  row = [[_selectedRows objectAtIndex: i] intValue];
		  [self setNeedsDisplayInRect: [self rectOfRow: row]];
		}

	      // Draw the new selection
	      [self selectRow: _clickedRow  byExtendingSelection: NO];
	      [self setNeedsDisplayInRect: [self rectOfRow: _clickedRow]];
	    }
	  else // Simply add to the old selection
	    {
	      [self selectRow: _clickedRow  byExtendingSelection: YES];
	      [self setNeedsDisplayInRect: [self rectOfRow: _clickedRow]];
	    }

	  if (_allowsMultipleSelection == NO)
	    {
	      return;
	    }
	  
	  // else, we track the mouse to allow extending selection to
	  // areas by dragging the mouse
	  
	  // Draw immediately because we are going to enter an event
	  // loop to track the mouse
	  [_window flushWindow];
	  
	  // We track the cursor and highlight according to the cursor
	  // position.  When the cursor gets out (up or down) of the
	  // table, we start periodic events and scroll periodically
	  // the table enlarging or reducing selection.
	  {
	    BOOL startedPeriodicEvents = NO;
	    unsigned int eventMask = (NSLeftMouseUpMask 
				      | NSLeftMouseDraggedMask 
				      | NSPeriodicMask);
	    NSEvent *lastEvent;
	    BOOL done = NO;
	    NSPoint mouseLocationWin;
	    NSDate *distantFuture = [NSDate distantFuture];
	    int lastSelectedRow = _clickedRow;
	    NSRect visibleRect = [self convertRect: [self visibleRect]
				       toView: nil];
	    float minYVisible = NSMinY (visibleRect);
	    float maxYVisible = NSMaxY (visibleRect);
	    BOOL delegateTakesPart;
	    BOOL mouseUp = NO;
	    // We have three zones of speed. 
	    // 0   -  50 pixels: period 0.2  <zone 1>
	    // 50  - 100 pixels: period 0.1  <zone 2>
	    // 100 - 150 pixels: period 0.01 <zone 3>
	    float oldPeriod = 0;
	    inline float computePeriod ()
	      {
		float distance = 0;
		
		if (mouseLocationWin.y < minYVisible) 
		  {
		    distance = minYVisible - mouseLocationWin.y; 
		  }
		else if (mouseLocationWin.y > maxYVisible)
		  {
		    distance = mouseLocationWin.y - maxYVisible;
		  }
		
		if (distance < 50)
		  return 0.2;
		else if (distance < 100)
		  return 0.1;
		else 
		  return 0.01;
	      }

	    selector = @selector (tableView:shouldSelectRow:);
	    delegateTakesPart = [_delegate respondsToSelector: selector];
	    
	    while (done != YES)
	      {
		lastEvent = [NSApp nextEventMatchingMask: eventMask 
				   untilDate: distantFuture
				   inMode: NSEventTrackingRunLoopMode 
				   dequeue: YES]; 

		switch ([lastEvent type])
		  {
		  case NSLeftMouseUp:
		    done = YES;
		    break;
		  case NSLeftMouseDragged:
		    mouseLocationWin = [lastEvent locationInWindow]; 
		    if ((mouseLocationWin.y > minYVisible) 
			&& (mouseLocationWin.y < maxYVisible))
		      {
			NSPoint mouseLocationView;
			int rowAtPoint;
			
			if (startedPeriodicEvents == YES)
			  {
			    [NSEvent stopPeriodicEvents];
			    startedPeriodicEvents = NO;
			  }
			mouseLocationView = [self convertPoint: 
						    mouseLocationWin 
						  fromView: nil];
			mouseLocationView.x = _bounds.origin.x;
			rowAtPoint = [self rowAtPoint: mouseLocationView];
			
			if (delegateTakesPart == YES)
			  {
			    _selectionChange (self, _delegate, 
					      _numberOfRows, _clickedRow, 
					      lastSelectedRow, rowAtPoint, 
					      _deselectRowsInRange, 
					      _selectRowsInRange);
			  }
			else
			  {
			    _selectionChange (self, nil,
					      _numberOfRows, _clickedRow, 
					      lastSelectedRow, rowAtPoint, 
					      _deselectRowsInRange, 
					      _selectRowsInRange);
			  }
			lastSelectedRow = rowAtPoint;
			[_window flushWindow];
			[nc postNotificationName: 
			      NSTableViewSelectionIsChangingNotification
			    object: self];
		      }
		    else // Mouse dragged out of the table
		      {
			if (startedPeriodicEvents == YES)
			  {
			    // Check - if the mouse did not change zone, 
			    // we do nothing
			    if (computePeriod () == oldPeriod)
			      break;

			    [NSEvent stopPeriodicEvents];
			  }
			// Start periodic events
			oldPeriod = computePeriod ();
			
			[NSEvent startPeriodicEventsAfterDelay: 0
				 withPeriod: oldPeriod];
			startedPeriodicEvents = YES;
			if (mouseLocationWin.y <= minYVisible) 
			  mouseUp = NO;
			else
			  mouseUp = YES;
		      }
		    break;
		  case NSPeriodic:
		    if (mouseUp == NO) // mouse below the table
		      {
			if (lastSelectedRow < _clickedRow)
			  {
			    [self deselectRow: lastSelectedRow];
			    [self setNeedsDisplayInRect: 
				    [self rectOfRow: lastSelectedRow]];
			    [self scrollRowToVisible: lastSelectedRow];
			    [_window flushWindow];
			    lastSelectedRow++;
			  }
			else
			  {
			    if ((lastSelectedRow + 1) < _numberOfRows)
			      {
				lastSelectedRow++;
				if ((delegateTakesPart == YES) &&
				    ([_delegate 
				       tableView: self 
				       shouldSelectRow: lastSelectedRow] 
				     == NO))
				  {
				    break;
				  }
				[self selectRow: lastSelectedRow 
				      byExtendingSelection: YES];
				[self setNeedsDisplayInRect: 
					[self rectOfRow: lastSelectedRow]];
				[self scrollRowToVisible: lastSelectedRow];
				[_window flushWindow];
			      }
			  }
		      }
		    else // mouse above the table
		      {
			if (lastSelectedRow <= _clickedRow)
			  {
			    if ((lastSelectedRow - 1) >= 0)
			      {
				lastSelectedRow--;
				if ((delegateTakesPart == YES) &&
				    ([_delegate 
				       tableView: self 
				       shouldSelectRow: lastSelectedRow] 
				     == NO))
				  {
				    break;
				  }
				[self selectRow: lastSelectedRow 
				      byExtendingSelection: YES];
				[self setNeedsDisplayInRect: 
					[self rectOfRow: lastSelectedRow]];
				[self scrollRowToVisible: lastSelectedRow];
				[_window flushWindow];
			      }
			  }
			else
			  {
			    [self deselectRow: lastSelectedRow];
			    [self setNeedsDisplayInRect: 
				    [self rectOfRow: lastSelectedRow]];
			    [self scrollRowToVisible: lastSelectedRow];
			    [_window flushWindow];
			    lastSelectedRow--;
			  }
		      }
		    [nc postNotificationName: 
			  NSTableViewSelectionIsChangingNotification
			object: self];
		    break;
		  default:
		    break;
		  }

	      }
	    
	    if (startedPeriodicEvents == YES)
	      [NSEvent stopPeriodicEvents];

	    [nc postNotificationName: 
		  NSTableViewSelectionDidChangeNotification
		object: self];
	    
	    return;
	  }
	}
    }

  // Double-click events

  if ([self isRowSelected: _clickedRow] == NO)
    return;

  tb = [_tableColumns objectAtIndex: _clickedColumn];

  shouldEdit = YES;

  if ([tb isEditable] == NO)
    {
      shouldEdit = NO;
    }
  else if ([_delegate respondsToSelector: 
			@selector(tableView:shouldEditTableColumn:row:)])
    {
      if ([_delegate tableView: self shouldEditTableColumn: tb 
		     row: _clickedRow] == NO)
	{
	  shouldEdit = NO;
	}
    }
  
  if (shouldEdit == NO)
    {
      // Send double-action but don't edit
      [self sendAction: _doubleAction to: _target];
      return;
    }

  // It is OK to edit column.  Go on, do it.
  [self editColumn: _clickedColumn  row: _clickedRow
	withEvent: theEvent  select: NO];
}
*/

/* 
 * Auxiliary Components 
 */

- (void) setHeaderView: (NSTableHeaderView*)aHeaderView
{
  if (_super_view != nil)
    {
      /* Changing the headerView after the table has been linked to a
	 scrollview is not yet supported - the doc is not clear
	 whether it should be supported at all.  If it is, perhaps
	 it's going to be done through a private method between the
	 tableview and the scrollview. */
      NSLog (@"setHeaderView: called after NSTableView has been put "
	     @"in the view tree!"); 
    }
  [_headerView setTableView: nil];
  ASSIGN (_headerView, aHeaderView);
  [_headerView setTableView: self];
  [self tile];
}

- (NSTableHeaderView*) headerView
{
  return _headerView;
}

- (void) setCornerView: (NSView*)aView
{
  ASSIGN (_cornerView, aView);
  [self tile];
}

- (NSView*) cornerView
{
  return _cornerView;
}

/* 
 * Layout 
 */

- (NSRect) rectOfColumn: (int)columnIndex
{
  NSRect rect;

  if (columnIndex < 0)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"ColumnIndex < 0 in [NSTableView -rectOfColumn:]"];
    }
  if (columnIndex >= _numberOfColumns)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"ColumnIndex => _numberOfColumns in [NSTableView -rectOfColumn:]"];
    }

  rect.origin.x = _columnOrigins[columnIndex];
  rect.origin.y = _bounds.origin.y;
  rect.size.width = [[_tableColumns objectAtIndex: columnIndex] width];
  rect.size.height = _bounds.size.height;
  return rect;
}

- (NSRect) rectOfRow: (int)rowIndex
{
  NSRect rect;

  if (rowIndex < 0)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"RowIndex < 0 in [NSTableView -rectOfRow:]"];
    }
  if (rowIndex >= _numberOfRows)
    {
      [NSException 
	raise: NSInternalInconsistencyException 
	format: @"RowIndex => _numberOfRows in [NSTableView -rectOfRow:]"];
    }
  rect.origin.x = _bounds.origin.x;
  rect.origin.y = _bounds.origin.y + (_rowHeight * rowIndex);
  rect.size.width = _bounds.size.width;
  rect.size.height = _rowHeight;
  return rect;
}

- (NSRange) columnsInRect: (NSRect)aRect
{
  NSRange range;

  range.location = [self columnAtPoint: aRect.origin];
  range.length = [self columnAtPoint: 
			 NSMakePoint (NSMaxX (aRect), _bounds.origin.y)];
  range.length -= range.location;
  range.length += 1;
  return range;
}

- (NSRange) rowsInRect: (NSRect)aRect
{
  NSRange range;

  range.location = [self rowAtPoint: aRect.origin];
  range.length = [self rowAtPoint: 
			 NSMakePoint (_bounds.origin.x, NSMaxY (aRect))];
  range.length -= range.location;
  range.length += 1;
  return range;
}

- (int) columnAtPoint: (NSPoint)aPoint
{
  if ((NSMouseInRect (aPoint, _bounds, YES)) == NO)
    {
      return -1;
    }
  else
    {
      int i = 0;
      
      while ((aPoint.x >= _columnOrigins[i]) && (i < _numberOfColumns))
	{
	  i++;
	}
      return i - 1;
    }
}

- (int) rowAtPoint: (NSPoint)aPoint
{
  /* NB: Y coordinate system is flipped in NSTableView */
  if ((NSMouseInRect (aPoint, _bounds, YES)) == NO)
    {
      return -1;
    }
  else
    {
      int return_value;

      aPoint.y -= _bounds.origin.y;
      return_value = (int) (aPoint.y / _rowHeight);
      /* This could happen if point lies on the grid line below the last row */
      if (return_value == _numberOfRows)
	{
	  return_value--;
	}
      return return_value;
    }
}

- (NSRect) frameOfCellAtColumn: (int)columnIndex 
			   row: (int)rowIndex
{
  NSRect frameRect;

  if ((columnIndex < 0) 
      || (rowIndex < 0)
      || (columnIndex > (_numberOfColumns - 1))
      || (rowIndex > (_numberOfRows - 1)))
    return NSZeroRect;
      
  frameRect.origin.y  = _bounds.origin.y + (rowIndex * _rowHeight);
  frameRect.origin.y += _intercellSpacing.height / 2;
  frameRect.size.height = _rowHeight - _intercellSpacing.height;

  frameRect.origin.x = _columnOrigins[columnIndex];
  frameRect.origin.x  += _intercellSpacing.width / 2;
  frameRect.size.width = [[_tableColumns objectAtIndex: columnIndex] width];
  frameRect.size.width -= _intercellSpacing.width;

  // We add some space to separate the cell from the grid
  if (_drawsGrid)
    {
      frameRect.size.width -= 4;
      frameRect.origin.x += 2;
    }

  // Safety check
  if (frameRect.size.width < 0)
    frameRect.size.width = 0;
  
  return frameRect;
}

- (void) setAutoresizesAllColumnsToFit: (BOOL)flag
{
  _autoresizesAllColumnsToFit = flag;
}

- (BOOL) autoresizesAllColumnsToFit
{
  return _autoresizesAllColumnsToFit;
}

- (void) sizeLastColumnToFit
{
  if ((_super_view != nil) && (_numberOfColumns > 0))
    {
      float excess_width;
      float last_column_width;
      NSTableColumn *lastColumn;

      lastColumn = [_tableColumns objectAtIndex: (_numberOfColumns - 1)];
      if ([lastColumn isResizable] == NO)
	return;
      excess_width = NSMaxX ([self convertRect: [_super_view bounds] 
				      fromView: _super_view]);
      excess_width -= NSMaxX (_bounds);
      last_column_width = [lastColumn width];
      last_column_width += excess_width;
      _tilingDisabled = YES;
      if (last_column_width < [lastColumn minWidth])
	{
	  [lastColumn setWidth: [lastColumn minWidth]];
	}
      else if (last_column_width > [lastColumn maxWidth])
	{
	  [lastColumn setWidth: [lastColumn maxWidth]];
	}
      else
	{
	  [lastColumn setWidth: last_column_width];
	}
      _tilingDisabled = NO;
      [self tile];
    }
}

- (void) setFrame: (NSRect) aRect
{
  [super setFrame: aRect];
}

- (void) sizeToFit
{
  NSTableColumn *tb;
  int i, j;
  float remainingWidth;
  float availableWidth;
  columnSorting *columnInfo;
  float *currentWidth;
  float *maxWidth;
  float *minWidth;
  BOOL *isResizable;
  int numberOfCurrentColumns = 0;
  float previousPoint;
  float nextPoint;
  float difference;
  float toAddToCurrentColumns;


  if ((_super_view == nil) || (_numberOfColumns == 0))
    return;

  columnInfo = NSZoneMalloc(NSDefaultMallocZone(),
			    sizeof(columnSorting) * 2 
			    * _numberOfColumns);
  currentWidth = NSZoneMalloc(NSDefaultMallocZone(),
			      sizeof(float) * _numberOfColumns);
  maxWidth = NSZoneMalloc(NSDefaultMallocZone(),
			  sizeof(float) * _numberOfColumns);
  minWidth = NSZoneMalloc(NSDefaultMallocZone(),
			  sizeof(float) * _numberOfColumns);
  isResizable = NSZoneMalloc(NSDefaultMallocZone(),
			     sizeof(BOOL) * _numberOfColumns);

  availableWidth = NSMaxX([self convertRect: [_super_view bounds] 
				fromView: _super_view]);
  remainingWidth = availableWidth;

  /*
   *  We store the minWidth and the maxWidth of every column
   *  because we'll use those values *a lot*
   *  At the same time we set every column to its mininum width
   */
  for (i = 0; i < _numberOfColumns; i++)
    {
      tb = [_tableColumns objectAtIndex: i];
      isResizable[i] = [tb isResizable];
      if (isResizable[i] == YES)
	{
	  minWidth[i] = [tb minWidth];
	  maxWidth[i] = [tb maxWidth];
	  
	  if (minWidth[i] < 0)
	    minWidth[i] = 0;
	  if (minWidth[i] > maxWidth[i])
	    {
	      minWidth[i] = [tb width];
	      maxWidth[i] = minWidth[i];
	    }
	  columnInfo[i * 2].width = minWidth[i];
	  columnInfo[i * 2].isMax = 0;
	  currentWidth[i] = minWidth[i];
	  remainingWidth -= minWidth[i];
	  
	  columnInfo[i * 2 + 1].width = maxWidth[i];
	  columnInfo[i * 2 + 1].isMax = 1;
	}
      else
	{
	  minWidth[i] = [tb width];
	  columnInfo[i * 2].width = minWidth[i];
	  columnInfo[i * 2].isMax = 0;
	  currentWidth[i] = minWidth[i];
	  remainingWidth -= minWidth[i];
	  
	  maxWidth[i] = minWidth[i];
	  columnInfo[i * 2 + 1].width = maxWidth[i];
	  columnInfo[i * 2 + 1].isMax = 1;
	}
    } 

  // sort the info we have
  quick_sort_internal(columnInfo, 0, 2 * _numberOfColumns - 1);

  previousPoint = columnInfo[0].width;
  numberOfCurrentColumns = 1;
  
  if (remainingWidth >= 0.)
    {
      for (i = 1; i < 2 * _numberOfColumns; i++)
	{
	  nextPoint = columnInfo[i].width;
	  
	  if (numberOfCurrentColumns > 0 && 
	      (nextPoint - previousPoint) > 0.)
	    {
	      int verification = 0;
	      
	      if ((nextPoint - previousPoint) * numberOfCurrentColumns
		  <= remainingWidth)
		{
		  toAddToCurrentColumns = nextPoint - previousPoint;
		  remainingWidth -= 
		    (nextPoint - previousPoint) * numberOfCurrentColumns;

		  for(j = 0; j < _numberOfColumns; j++)
		    {
		      if (minWidth[j] <= previousPoint
			  && maxWidth[j] >= nextPoint)
			{
			  verification++;
			  currentWidth[j] += toAddToCurrentColumns;
			}
		    }
		  if (verification != numberOfCurrentColumns)
		    {
		      NSLog(@"[NSTableView sizeToFit]: unexpected error");
		    }
		}
	      else
		{
		  int remainingInt = floor(remainingWidth);
		  int quotient = remainingInt / numberOfCurrentColumns;
		  int remainder = remainingInt - quotient * numberOfCurrentColumns;
		  int oldRemainder = remainder;

		  for(j = _numberOfColumns - 1; j >= 0; j--)
		    {
		      if (minWidth[j] <= previousPoint
			  && maxWidth[j] >= nextPoint)
			{
			  currentWidth[j] += quotient;
			  if (remainder > 0 
			      && maxWidth[j] >= currentWidth[j] + 1)
			    {
			      remainder--;
			      currentWidth[j]++;
			    }
			}
		    }
		  while (oldRemainder > remainder && remainder > 0)
		    {
		      oldRemainder = remainder;
		      for(j = 0; j < _numberOfColumns; j++)
			{
			  if (minWidth[j] <= previousPoint
			      && maxWidth[j] >= nextPoint)
			    {
			      if (remainder > 0 
				  && maxWidth[j] >= currentWidth[j] + 1)
				{
				  remainder--;
				  currentWidth[j]++;
				}
			    }
			  
			}
		    }
		  if (remainder > 0)
		    NSLog(@"There is still free space to fill.\
 However it seems better to use integer width for the columns");
		  else
		    remainingWidth = 0.;
		}
	      
	      
	    }
	  else if (numberOfCurrentColumns < 0)
	    {
	      NSLog(@"[NSTableView sizeToFit]: unexpected error");
	    }
	  
	  if (columnInfo[i].isMax)
	    numberOfCurrentColumns--;
	  else
	    numberOfCurrentColumns++;
	  previousPoint = nextPoint;
	  
	  if (remainingWidth == 0.)
	    {
	      break;
	    }
	}
    }

  _tilingDisabled = YES;

  remainingWidth = 0.;
  for (i = 0; i < _numberOfColumns; i++)
    {
      if (isResizable[i] == YES)
	{
	  tb = [_tableColumns objectAtIndex: i];
	  remainingWidth += currentWidth[i];
	  [tb setWidth: currentWidth[i]];
	}
      else
	{
	  remainingWidth += minWidth[i];
	}
    }


  difference = availableWidth - remainingWidth;


  _tilingDisabled = NO;
  NSZoneFree(NSDefaultMallocZone(), columnInfo);
  NSZoneFree(NSDefaultMallocZone(), currentWidth);
  NSZoneFree(NSDefaultMallocZone(), maxWidth);
  NSZoneFree(NSDefaultMallocZone(), minWidth);


  [self tile];
}
/*
- (void) sizeToFit
{
  NSCell *cell;
  NSEnumerator	*enumerator;
  NSTableColumn	*tb;
  float table_width;
  float width;
  float candidate_width;
  int row;

  _tilingDisabled = YES;

  // First Step
  // Resize Each Column to its Minimum Width
  table_width = _bounds.origin.x;
  enumerator = [_tableColumns objectEnumerator];
  while ((tb = [enumerator nextObject]) != nil)
    {
      // Compute min width of column 
      width = [[tb headerCell] cellSize].width;
      for (row = 0; row < _numberOfRows; row++)
	{
	  cell = [tb dataCellForRow: row];
	  [cell setObjectValue: [_dataSource tableView: self
					     objectValueForTableColumn: tb
					     row: row]]; 
	  if (_del_responds)
	    {
	      [_delegate tableView: self   willDisplayCell: cell 
			 forTableColumn: tb   row: row];
	    }
	  candidate_width = [cell cellSize].width;

	  if (_drawsGrid)
	    candidate_width += 4;

	  if (candidate_width > width)
	    {
	      width = candidate_width;
	    }
	}
      width += _intercellSpacing.width;
      [tb setWidth: width];
      // It is necessary to ask the column for the width, since it might have 
      // been changed by the column to constrain it to a min or max width
      table_width += [tb width];
    }

  // Second Step
  // If superview (clipview) is bigger than that, divide remaining space 
  // between all columns
  if ((_super_view != nil) && (_numberOfColumns > 0))
    {
      float excess_width;

      excess_width = NSMaxX ([self convertRect: [_super_view bounds] 
				      fromView: _super_view]);
      excess_width -= table_width;
      // Since we resized each column at its minimum width, 
      // it's useless to try shrinking more: we can't
      if (excess_width <= 0)
	{
	  _tilingDisabled = NO;
	  [self tile];
	  NSLog(@"exiting sizeToFit");
	  return;
	}
      excess_width = excess_width / _numberOfColumns;

      enumerator = [_tableColumns objectEnumerator];
      while ((tb = [enumerator nextObject]) != nil)
	{
	  [tb setWidth: ([tb width] + excess_width)];
	}
    }

  _tilingDisabled = NO;
  [self tile];
  NSLog(@"exiting sizeToFit");
}
*/
- (void) noteNumberOfRowsChanged
{
  _numberOfRows = [_dataSource numberOfRowsInTableView: self];
  
  /* If we are selecting rows, we have to check that we have no
     selected rows below the new end of the table */
  if (!_selectingColumns)
    {
      int i, count = [_selectedRows count]; 
      int row = -1;
      
      /* Check that all selected rows are in the new range of rows */
      for (i = 0; i < count; i++)
	{
	  row = [[_selectedRows objectAtIndex: i] intValue];

	  if (row >= _numberOfRows)
	    {
	      break;
	    }
	}

      if (i < count  &&  row > -1)
	{
	  /* Some of them are outside the table ! - Remove them */
	  for (; i < count; i++)
	    {
	      [_selectedRows removeLastObject];
	    }
	  /* Now if the _selectedRow is outside the table, reset it to be
	     the last selected row (if any) */
	  if (_selectedRow >= _numberOfRows)
	    {
	      if ([_selectedRows count] > 0)
		{
		  _selectedRow = [[_selectedRows lastObject] intValue];
		}
	      else
		{
		  /* Argh - all selected rows were outside the table */
		  if (_allowsEmptySelection)
		    {
		      _selectedRow = -1;
		    }
		  else
		    {
		      /* We shouldn't allow empty selection - try
                         selecting the last row */
		      int lastRow = _numberOfRows - 1;
		      
		      if (lastRow > -1)
			{
			  [_selectedRows addObject: 
					   [NSNumber numberWithInt: lastRow]];
			  _selectedRow = lastRow;
			}
		      else
			{
			  /* problem - there are no rows at all */
			  _selectedRow = -1;
			}
		    }
		}
	    }
	}
    }

  [self setFrame: NSMakeRect (_frame.origin.x, 
			      _frame.origin.y,
			      _frame.size.width, 
			      (_numberOfRows * _rowHeight) + 1)];
  
  /* If we are shorter in height than the enclosing clipview, we
     should redraw us now. */
  if (_super_view != nil)
    {
      NSRect superviewBounds; // Get this *after* [self setFrame:]
      superviewBounds = [_super_view bounds];
      if ((superviewBounds.origin.x <= _frame.origin.x) 
          && (NSMaxY (superviewBounds) >= NSMaxY (_frame)))
	{
	  [self setNeedsDisplay: YES];
	}
    }
}

- (void) tile
{
  float table_width = 0;
  float table_height;

  if (_tilingDisabled == YES)
    return;

  if (_numberOfColumns > 0)
    {
      int i;
      float width;
  
      _columnOrigins[0] = _bounds.origin.x;
      width = [[_tableColumns objectAtIndex: 0] width];
      table_width += width;
      for (i = 1; i < _numberOfColumns; i++)
	{
	  _columnOrigins[i] = _columnOrigins[i - 1] + width;
	  width = [[_tableColumns objectAtIndex: i] width];
	  table_width += width;
	}
    }
  /* + 1 for the last grid line */
  table_height = (_numberOfRows * _rowHeight) + 1;
  [self setFrameSize: NSMakeSize (table_width, table_height)];
  [self setNeedsDisplay: YES];

  if (_headerView != nil)
    {
      [_headerView setFrameSize: 
		     NSMakeSize (_frame.size.width,
				 [_headerView frame].size.height)];
      [_cornerView setFrameSize: 
		     NSMakeSize ([NSScroller scrollerWidth] + 1,
				 [_headerView frame].size.height)];
      [_headerView setNeedsDisplay: YES];
      [_cornerView setNeedsDisplay: YES];
    }  
}

/* 
 * Drawing 
 */

- (void)drawRow: (int)rowIndex clipRect: (NSRect)aRect
{
  int startingColumn; 
  int endingColumn;
  NSTableColumn *tb;
  NSRect drawingRect;
  NSCell *cell;
  int i;
  float x_pos;

  if (_dataSource == nil)
    {
      return;
    }

  /* Using columnAtPoint: here would make it called twice per row per drawn 
     rect - so we avoid it and do it natively */

  /* Determine starting column as fast as possible */
  x_pos = NSMinX (aRect);
  i = 0;
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  startingColumn = (i - 1);

  if (startingColumn == -1)
    startingColumn = 0;

  /* Determine ending column as fast as possible */
  x_pos = NSMaxX (aRect);
  // Nota Bene: we do *not* reset i
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;

  /* Draw the row between startingColumn and endingColumn */
  for (i = startingColumn; i <= endingColumn; i++)
    {
      if (i != _editedColumn || rowIndex != _editedRow)
	{
	  tb = [_tableColumns objectAtIndex: i];
	  cell = [tb dataCellForRow: rowIndex];
	  if (_del_responds)
	    {
	      [_delegate tableView: self   willDisplayCell: cell 
			 forTableColumn: tb   row: rowIndex];
	    }
	  [cell setObjectValue: [_dataSource tableView: self
					     objectValueForTableColumn: tb
					     row: rowIndex]]; 
	  drawingRect = [self frameOfCellAtColumn: i
			      row: rowIndex];
	  [cell drawWithFrame: drawingRect inView: self];
	}
    }
}


- (void) drawGridInClipRect: (NSRect)aRect
{
  float minX = NSMinX (aRect);
  float maxX = NSMaxX (aRect);
  float minY = NSMinY (aRect);
  float maxY = NSMaxY (aRect);
  int i;
  float x_pos;
  int startingColumn; 
  int endingColumn;

  NSGraphicsContext *ctxt = GSCurrentContext ();
  float position;

  int startingRow    = [self rowAtPoint: 
			       NSMakePoint (_bounds.origin.x, minY)];
  int endingRow      = [self rowAtPoint: 
			       NSMakePoint (_bounds.origin.x, maxY)];

  /* Using columnAtPoint:, rowAtPoint: here calls them only twice 

     per drawn rect */
  x_pos = minX;
  i = 0;
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  startingColumn = (i - 1);

  x_pos = maxX;
  // Nota Bene: we do *not* reset i
  while ((x_pos > _columnOrigins[i]) && (i < _numberOfColumns))
    {
      i++;
    }
  endingColumn = (i - 1);

  if (endingColumn == -1)
    endingColumn = _numberOfColumns - 1;
  /*
  int startingColumn = [self columnAtPoint: 
			       NSMakePoint (minX, _bounds.origin.y)];
  int endingColumn   = [self columnAtPoint: 
			       NSMakePoint (maxX, _bounds.origin.y)];
  */

  DPSgsave (ctxt);
  DPSsetlinewidth (ctxt, 1);
  [_gridColor set];

  if (_numberOfRows > 0)
    {
      /* Draw horizontal lines */
      if (startingRow == -1)
	startingRow = 0;
      if (endingRow == -1)
	endingRow = _numberOfRows - 1;
      
      position = _bounds.origin.y;
      position += startingRow * _rowHeight;
      for (i = startingRow; i <= endingRow + 1; i++)
	{
	  DPSmoveto (ctxt, minX, position);
	  DPSlineto (ctxt, maxX, position);
	  DPSstroke (ctxt);
	  position += _rowHeight;
	}
    }
  
  if (_numberOfColumns > 0)
    {
      /* Draw vertical lines */
      if (startingColumn == -1)
	startingColumn = 0;
      if (endingColumn == -1)
	endingColumn = _numberOfColumns - 1;

      for (i = startingColumn; i <= endingColumn; i++)
	{
	  DPSmoveto (ctxt, _columnOrigins[i], minY);
	  DPSlineto (ctxt, _columnOrigins[i], maxY);
	  DPSstroke (ctxt);
	}
      position =  _columnOrigins[endingColumn];
      position += [[_tableColumns objectAtIndex: endingColumn] width];  
      /* Last vertical line must moved a pixel to the left */
      if (endingColumn == (_numberOfColumns - 1))
	position -= 1;
      DPSmoveto (ctxt, position, minY);
      DPSlineto (ctxt, position, maxY);
      DPSstroke (ctxt);
    }

  DPSgrestore (ctxt);
}

- (void) highlightSelectionInClipRect: (NSRect)clipRect
{
  if (_selectingColumns == NO)
    {
      int selectedRowsCount;
      int row;
      int startingRow, endingRow;
      
      selectedRowsCount = [_selectedRows count];
      
      if (selectedRowsCount == 0)
	return;
      
      /* highlight selected rows */
      startingRow = [self rowAtPoint: NSMakePoint (0, NSMinY (clipRect))];
      endingRow   = [self rowAtPoint: NSMakePoint (0, NSMaxY (clipRect))];
      
      if (startingRow == -1)
	startingRow = 0;
      if (endingRow == -1)
	endingRow = _numberOfRows - 1;
      
      for (row = 0; row < selectedRowsCount; row++)
	{
	  int rowNumber; 
	  
	  rowNumber = [[_selectedRows objectAtIndex: row] intValue];
	  
	  if (rowNumber > endingRow)
	    break;
	  
	  if (rowNumber >= startingRow)
	    {
	      //NSHighlightRect(NSIntersectionRect([self rectOfRow: rowNumber],
	      //						 clipRect));
	      [[NSColor whiteColor] set];
	      NSRectFill(NSIntersectionRect([self rectOfRow: rowNumber], clipRect));
	    }
	}
    }
  else // Selecting columns
    {
      int selectedColumnsCount;
      int column;
      int startingColumn, endingColumn;
      
      selectedColumnsCount = [_selectedColumns count];
      
      if (selectedColumnsCount == 0)
	return;
      
      /* highlight selected columns */
      startingColumn = [self columnAtPoint: NSMakePoint (NSMinX (clipRect), 
							 0)];
      endingColumn = [self columnAtPoint: NSMakePoint (NSMaxX (clipRect), 0)];

      if (startingColumn == -1)
	startingColumn = 0;
      if (endingColumn == -1)
	endingColumn = _numberOfColumns - 1;
      
      for (column = 0; column < selectedColumnsCount; column++)
	{
	  int columnNumber; 
	  
	  columnNumber = [[_selectedColumns objectAtIndex: column] intValue];
	  
	  if (columnNumber > endingColumn)
	    break;
	  
	  if (columnNumber >= startingColumn)
	    {
	      NSHighlightRect
		(NSIntersectionRect([self rectOfColumn: columnNumber],
				    clipRect));
	    }
	}     
    }
}

- (void) drawRect: (NSRect)aRect
{
  int startingRow;
  int endingRow;
  int i;

  /* Draw background */

  /*  
  [_backgroundColor set];
  NSRectFill (aRect);
  */
  if ((_numberOfRows == 0) || (_numberOfColumns == 0))
    {
      return;
    }

  /* Draw selection */
  //    [self highlightSelectionInClipRect: aRect];

  /* Draw grid */
  if (_drawsGrid)
    {
      [self drawGridInClipRect: aRect];
    }
  
  /* Draw visible cells */
  /* Using rowAtPoint: here calls them only twice per drawn rect */
  startingRow = [self rowAtPoint: NSMakePoint (0, NSMinY (aRect))];
  endingRow   = [self rowAtPoint: NSMakePoint (0, NSMaxY (aRect))];

  if (startingRow == -1)
    {
      startingRow = 0;
    }
  if (endingRow == -1)
    {
      endingRow = _numberOfRows - 1;
    }
  //  NSLog(@"drawRect : %d-%d", startingRow, endingRow);
  {
    SEL sel = @selector(drawRow:clipRect:);
    IMP imp = [self methodForSelector: sel];
    
    NSRect localBackground;
    localBackground = aRect;
    localBackground.size.height = _rowHeight;
    localBackground.origin.y = _bounds.origin.y + (_rowHeight * startingRow);
    
    for (i = startingRow; i <= endingRow; i++)
      {
	[_backgroundColor set];
	NSRectFill (localBackground);
	[self highlightSelectionInClipRect: localBackground];
	if (_drawsGrid)
	  {
	    [self drawGridInClipRect: localBackground];
	  }
	localBackground.origin.y += _rowHeight;
	(*imp)(self, sel, i, aRect);
      }

    if (NSMaxY(aRect) > NSMaxY(localBackground) - _rowHeight)
      {
	[_backgroundColor set];
	localBackground.size.height =
	  aRect.size.height - aRect.origin.y + localBackground.origin.y;
	NSRectFill (localBackground);
      }
  }
}

- (BOOL) isOpaque
{
  return YES;
}

/* 
 * Scrolling 
 */

- (void) scrollRowToVisible: (int)rowIndex
{
  if (_super_view != nil)
    {
      NSRect rowRect = [self rectOfRow: rowIndex];
      NSRect visibleRect = [self visibleRect];
      
      // If the row is over the top, or it is partially visible 
      // on top,
      if ((rowRect.origin.y < visibleRect.origin.y))	
	{
	  // Then make it visible on top
	  NSPoint newOrigin;  
	  
	  newOrigin.x = visibleRect.origin.x;
	  newOrigin.y = rowRect.origin.y;
	  newOrigin = [self convertPoint: newOrigin  toView: _super_view];
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
      // If the row is under the bottom, or it is partially visible on
      // the bottom,
      if (NSMaxY (rowRect) > NSMaxY (visibleRect))
	{
	  // Then make it visible on bottom
	  NSPoint newOrigin;  
	  
	  newOrigin.x = visibleRect.origin.x;
	  newOrigin.y = visibleRect.origin.y;
	  newOrigin.y += NSMaxY (rowRect) - NSMaxY (visibleRect);
	  newOrigin = [self convertPoint: newOrigin  toView: _super_view];
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
    }
}

- (void) scrollColumnToVisible: (int)columnIndex
{
  if (_super_view != nil)
    {
      NSRect columnRect = [self rectOfColumn: columnIndex];
      NSRect visibleRect = [self visibleRect];
      float diff;

      // If the row is out on the left, or it is partially visible 
      // on the left
      if ((columnRect.origin.x < visibleRect.origin.x))	
	{
	  // Then make it visible on the left
	  NSPoint newOrigin;  
	  
	  newOrigin.x = columnRect.origin.x;
	  newOrigin.y = visibleRect.origin.y;
	  newOrigin = [self convertPoint: newOrigin  toView: _super_view];
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
      diff = NSMaxX (columnRect) - NSMaxX (visibleRect);
      // If the row is out on the right, or it is partially visible on
      // the right,
      if (diff > 0)
	{
	  // Then make it visible on the right
	  NSPoint newOrigin;

	  newOrigin.x = visibleRect.origin.x;
	  newOrigin.y = visibleRect.origin.y;
	  newOrigin.x += diff;
	  newOrigin = [self convertPoint: newOrigin  toView: _super_view];
	  [(NSClipView *)_super_view scrollToPoint: newOrigin];
	  return;
	}
    }
}


/* 
 * Text delegate methods 
 */

- (void) textDidBeginEditing: (NSNotification *)aNotification
{
  NSMutableDictionary *d;

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidBeginEditingNotification
      object: self
      userInfo: d];
}

- (void) textDidChange: (NSNotification *)aNotification
{
  NSMutableDictionary *d;

  // MacOS-X asks us to inform the cell if possible.
  if ((_editedCell != nil) && [_editedCell respondsToSelector: 
						 @selector(textDidChange:)])
    [_editedCell textDidChange: aNotification];

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidChangeNotification
      object: self
      userInfo: d];
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  NSMutableDictionary *d;
  id textMovement;
  int row, column;

  [self validateEditing];

  [_editedCell endEditing: [aNotification object]];
  [self setNeedsDisplayInRect: 
	  [self frameOfCellAtColumn: _editedColumn row: _editedRow]];
  _textObject = nil;
  RELEASE (_editedCell);
  _editedCell = nil;
  /* Save values */
  row = _editedRow;
  column = _editedColumn;
  /* Only then Reset them */
  _editedColumn = -1;
  _editedRow = -1;

  d = [[NSMutableDictionary alloc] initWithDictionary: 
				     [aNotification userInfo]];
  [d setObject: [aNotification object] forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidEndEditingNotification
      object: self
      userInfo: d];

  textMovement = [[aNotification userInfo] objectForKey: @"NSTextMovement"];
  if (textMovement)
    {
      switch ([(NSNumber *)textMovement intValue])
	{
	case NSReturnTextMovement:
	  // Send action ?
	  break;
	case NSTabTextMovement:
	  if([self _editNextEditableCellAfterRow: row  column: column] == YES)
	    {
	      break;
	    }
	  [_window selectKeyViewFollowingView: self];
	  break;
	case NSBacktabTextMovement:
	  if([self _editPreviousEditableCellBeforeRow: row  column: column] == YES)
	    {
	      break;
	    }
	  [_window selectKeyViewPrecedingView: self];
	  break;
	}
    }
}

- (BOOL) textShouldBeginEditing: (NSText *)textObject
{
  if (_delegate && [_delegate respondsToSelector:
				@selector(control:textShouldBeginEditing:)])
    return [_delegate control: self
		      textShouldBeginEditing: textObject];
  else
    return YES;
}

- (BOOL) textShouldEndEditing: (NSText *)aTextObject
{
  if ([_delegate respondsToSelector:
		   @selector(control:textShouldEndEditing:)])
    {
      if ([_delegate control: self
		     textShouldEndEditing: aTextObject] == NO)
	{
	  NSBeep ();
	  return NO;
	}
      
      return YES;
    }

  if ([_delegate respondsToSelector: 
		   @selector(control:isValidObject:)] == YES)
    {
      NSFormatter *formatter;
      id newObjectValue;
      
      formatter = [_cell formatter];
      
      if ([formatter getObjectValue: &newObjectValue 
		     forString: [_textObject text] 
		     errorDescription: NULL] == YES)
	{
	  if ([_delegate control: self
			 isValidObject: newObjectValue] == NO)
	    return NO;
	}
    }

  return [_editedCell isEntryAcceptable: [aTextObject text]];
}

/* 
 * Persistence 
 */

- (NSString *) autosaveName
{
  return _autosaveName;
}

- (BOOL) autosaveTableColumns
{
  return _autosaveTableColumns;
}

- (void) setAutosaveName: (NSString *)name
{
  ASSIGN (_autosaveName, name);
  [self _autoloadTableColumns];
}

- (void) setAutosaveTableColumns: (BOOL)flag
{
  if (flag == _autosaveTableColumns)
    {
      return;
    }

  _autosaveTableColumns = flag;
  if (flag)
    {
      [self _autoloadTableColumns];
      [nc addObserver: self 
          selector: @selector(_autosaveTableColumns)
	  name: NSTableViewColumnDidResizeNotification
	  object: self];
    }
  else
    {
      [nc removeObserver: self 
	  name: NSTableViewColumnDidResizeNotification
	  object: self];    
    }
}

/* 
 * Delegate 
 */

- (void) setDelegate: (id)anObject
{
  const SEL sel = @selector(tableView:willDisplayCell:forTableColumn:row:);

  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;
  
#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(tableView##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(tableView##notif_name:) \
      name: NSTableView##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(ColumnDidMove);
  SET_DELEGATE_NOTIFICATION(ColumnDidResize);
  SET_DELEGATE_NOTIFICATION(SelectionDidChange);
  SET_DELEGATE_NOTIFICATION(SelectionIsChanging);
  
  /* Cache */
  _del_responds = [_delegate respondsToSelector: sel];
}

- (id) delegate
{
  return _delegate;
}


/* indicator image */
- (NSImage *) indicatorImageInTableColumn: (NSTableColumn *)aTableColumn
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"indicatorImageInTableColumn:", "NSTableView");
  return nil;
}

- (void) setIndicatorImage: (NSImage *)anImage
	     inTableColumn: (NSTableColumn *)aTableColumn
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"setIndicatorImage:inTableColumn:", "NSTableView");
}

/* highlighting columns */
- (NSTableColumn *) highlightedTableColumn
{
  return _highlightedTableColumn;
}

- (void) setHighlightedTableColumn: (NSTableColumn *)aTableColumn
{
  int tableColumnIndex;

  tableColumnIndex = [_tableColumns indexOfObject: aTableColumn];

  if (tableColumnIndex == NSNotFound)
    {
      NSLog(@"setHighlightedTableColumn received an invalid\
 NSTableColumn object");
      return;
    }

  // we do not need to retain aTableColumn as it is already in
  // _tableColumns array
  _highlightedTableColumn = aTableColumn;

  [_headerView setNeedsDisplay: YES];
}

/* dragging rows */
- (NSImage*) dragImageForRows: (NSArray*)dragRows
			event: (NSEvent*)dragEvent
	      dragImageOffset: (NSPoint*)dragImageOffset
{

  NSImage *dragImage = [[NSImage alloc]
			 initWithSize: NSMakeSize(8, 8)];

  return dragImage;
}

- (void) setDropRow: (int)row
      dropOperation: (NSTableViewDropOperation)operation
{
  
  if (row < 0)
    {
      currentDropRow = 0;
    }
  else if (operation == NSTableViewDropOn)
    {
      if (row >= _numberOfRows)
	currentDropRow = _numberOfRows;
    }
  else if (row > _numberOfRows)
    {
      currentDropRow = _numberOfRows;
    }
  else
    {
      currentDropRow = row;
    }
  
  currentDropOperation = operation;
}

- (void) setVerticalMotionCanBeginDrag: (BOOL)flag
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"setVerticalMotionCanBeginDrag:", "NSTableView");
}

- (BOOL) verticalMotionCanBeginDrag
{
  // TODO
  NSLog(@"Method %s is not implemented for class %s",
	"verticalMotionCanBeginDrag", "NSTableView");
  return NO;
}

/*
 * Encoding/Decoding
 */

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: _dataSource];
  [aCoder encodeObject: _tableColumns];
  [aCoder encodeObject: _gridColor];
  [aCoder encodeObject: _backgroundColor];
  [aCoder encodeObject: _headerView];
  [aCoder encodeObject: _cornerView];
  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeConditionalObject: _target];

  [aCoder encodeValueOfObjCType: @encode(int) at: &_numberOfRows];
  [aCoder encodeValueOfObjCType: @encode(int) at: &_numberOfColumns];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_drawsGrid];
  [aCoder encodeValueOfObjCType: @encode(float) at: &_rowHeight];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_doubleAction];
  [aCoder encodeSize: _intercellSpacing];

  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsMultipleSelection];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsEmptySelection];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnSelection];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnResizing];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnReordering];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autoresizesAllColumnsToFit];

}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  int version = [aDecoder versionForClassName: 
			    @"NSTableView"];

  id aDelegate;

  if (version == currentVersion)
    {
      self = [super initWithCoder: aDecoder];
      
      _dataSource      = [aDecoder decodeObject];
      _tableColumns    = RETAIN([aDecoder decodeObject]);
      _gridColor       = RETAIN([aDecoder decodeObject]);
      _backgroundColor = RETAIN([aDecoder decodeObject]);
      _headerView      = RETAIN([aDecoder decodeObject]);
      _cornerView      = RETAIN([aDecoder decodeObject]);
      aDelegate        = [aDecoder decodeObject];
      _target          = [aDecoder decodeObject];
      
      [self setDelegate: aDelegate];
      [_headerView setTableView: self];
      [_tableColumns makeObjectsPerformSelector: @selector(setTableView:)
		     withObject: self];
      
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_numberOfRows];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_numberOfColumns];
      

      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_drawsGrid];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_rowHeight];
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_doubleAction];
      _intercellSpacing = [aDecoder decodeSize];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsMultipleSelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsEmptySelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnSelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnResizing];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnReordering];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_autoresizesAllColumnsToFit];
      
      ASSIGN (_selectedColumns, [NSMutableArray array]);
      ASSIGN (_selectedRows, [NSMutableArray array]);
      if (_numberOfColumns)
	_columnOrigins = NSZoneMalloc (NSDefaultMallocZone (), 
				       sizeof(float) * _numberOfColumns);
      
      _clickedRow = -1;
      _clickedColumn = -1;
      _selectingColumns = NO;
      _selectedColumn = -1;
      _selectedRow = -1;
      _editedColumn = -1;
      _editedRow = -1;
      
      /*
      [self tile];
      
      NSLog(@"frame %@", NSStringFromRect([self frame]));
      NSLog(@"dataSource %@", _dataSource);
      if (_dataSource != nil)
	{
	  [self setDataSource: _dataSource];
	  NSLog(@"dataSource set");
	}
      */
    }
  else if (version == 2)
    {
      self = [super initWithCoder: aDecoder];
      
      _dataSource      = [aDecoder decodeObject];
      _tableColumns    = RETAIN([aDecoder decodeObject]);
      _gridColor       = RETAIN([aDecoder decodeObject]);
      _backgroundColor = RETAIN([aDecoder decodeObject]);
      _headerView      = RETAIN([aDecoder decodeObject]);
      _cornerView      = RETAIN([aDecoder decodeObject]);
      aDelegate        = [aDecoder decodeObject];
      _target          = [aDecoder decodeObject];
      
      [self setDelegate: aDelegate];
      [_headerView setTableView: self];
      [_tableColumns makeObjectsPerformSelector: @selector(setTableView:)
		     withObject: self];
      
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_numberOfRows];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_numberOfColumns];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_drawsGrid];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_rowHeight];
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_doubleAction];
      _intercellSpacing = [aDecoder decodeSize];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsMultipleSelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsEmptySelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnSelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnResizing];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_autoresizesAllColumnsToFit];
      
      ASSIGN (_selectedColumns, [NSMutableArray array]);
      ASSIGN (_selectedRows, [NSMutableArray array]);
      if (_numberOfColumns)
	_columnOrigins = NSZoneMalloc (NSDefaultMallocZone (), 
				       sizeof(float) * _numberOfColumns);
      
      _clickedRow = -1;
      _clickedColumn = -1;
      _selectingColumns = NO;
      _selectedColumn = -1;
      _selectedRow = -1;
      _editedColumn = -1;
      _editedRow = -1;
      [self tile];
    }
  else if (version == 1)
    {
      self = [super initWithCoder: aDecoder];
      
      _dataSource      = [aDecoder decodeObject];
      _tableColumns    = RETAIN([aDecoder decodeObject]);
      _gridColor       = RETAIN([aDecoder decodeObject]);
      _backgroundColor = RETAIN([aDecoder decodeObject]);
      _headerView      = RETAIN([aDecoder decodeObject]);
      _cornerView      = RETAIN([aDecoder decodeObject]);
      aDelegate        = [aDecoder decodeObject];
      _target          = [aDecoder decodeObject];
      
      [self setDelegate: aDelegate];
      [_headerView setTableView: self];
      [_tableColumns makeObjectsPerformSelector: @selector(setTableView:)
		     withObject: self];
      
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_numberOfRows];
      [aDecoder decodeValueOfObjCType: @encode(int) at: &_numberOfColumns];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_drawsGrid];
      [aDecoder decodeValueOfObjCType: @encode(float) at: &_rowHeight];
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_doubleAction];
      _intercellSpacing = [aDecoder decodeSize];
      
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsMultipleSelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsEmptySelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnSelection];
      [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_allowsColumnResizing];
      
      ASSIGN (_selectedColumns, [NSMutableArray array]);
      ASSIGN (_selectedRows, [NSMutableArray array]);
      if (_numberOfColumns)
	_columnOrigins = NSZoneMalloc (NSDefaultMallocZone (), 
				       sizeof(float) * _numberOfColumns);
      
      _clickedRow = -1;
      _clickedColumn = -1;
      _selectingColumns = NO;
      _selectedColumn = -1;
      _selectedRow = -1;
      _editedColumn = -1;
      _editedRow = -1;
    }

  return self;
}

- (void) updateCell: (NSCell*)aCell
{
  int i, j;
  NSTableColumn *tb;
  if (aCell == nil)
    return;
  return;
  for (i = 0; i < _numberOfColumns; i++)
    {
      tb = [_tableColumns objectAtIndex: i];
      if ([tb dataCellForRow: -1] == aCell)
	{
	  [self setNeedsDisplayInRect: [self rectOfColumn: i]];
	}
      else
	{
	  NSRect columnRect = [self rectOfColumn: i];
	  NSRect rowRect;
	  NSRect visibleRect = [self convertRect: [_super_view bounds]
				     toView: self];
	  NSPoint top = NSMakePoint(NSMinX(visibleRect),
				    NSMinY(visibleRect));
	  NSPoint bottom = NSMakePoint(NSMinX(visibleRect),
				       NSMaxY(visibleRect));
	  int firstVisibleRow = [self rowAtPoint: top];
	  int lastVisibleRow = [self rowAtPoint: bottom];

	  if (firstVisibleRow == -1)
	    firstVisibleRow = 0;

	  if (lastVisibleRow == -1)
	    lastVisibleRow = _numberOfColumns - 1;

	  for (j = firstVisibleRow; j < lastVisibleRow; j++)
	    {
	      if ([tb dataCellForRow: j] == aCell)
		{
		  rowRect = [self rectOfRow: j];
		  [self setNeedsDisplayInRect:
			  NSIntersectionRect(columnRect, rowRect)];
		}
	    }
	}
    }
}

- (void) _userResizedTableColumn: (int)index
			   width: (float)width
{
  [[_tableColumns objectAtIndex: index] setWidth: width];
}

- (float *) _columnOrigins
{
  return _columnOrigins;
}

- (void) _mouseDownInHeaderOfTableColumn: (NSTableColumn *)tc
{
  if ([_delegate 
	respondsToSelector:
	  @selector(tableView:mouseDownInHeaderOfTableColumn:)])
    {
      [_delegate tableView: self
		 mouseDownInHeaderOfTableColumn: tc];
    }
}

- (void) _didClickTableColumn: (NSTableColumn *)tc
{
  if ([_delegate 
	respondsToSelector:
	  @selector(tableView:didClickTableColumn:)])
    {
      [_delegate tableView: self
		 didClickTableColumn: tc];
    }
}

-(BOOL) _editNextEditableCellAfterRow: (int)row
			       column: (int)column
{
  int i, j;
  
  if (row > -1)
    {
      // First look for cells in the same row
      for (j = column + 1; j < _numberOfColumns; j++)
	{
	  if (_isCellEditable (_delegate, _tableColumns, self, row, j) == YES)
	    {
	      [self editColumn: j  row: row  withEvent: nil  select: YES];
	      return YES;
	    }
	}
    }
  // Otherwise, make the big cycle.
  for (i = row + 1; i < _numberOfRows; i++)
    {
      for (j = 0; j < _numberOfColumns; j++)
	{
	  if (_isCellEditable (_delegate, _tableColumns, self, i, j) == YES)
	    {
	      [self editColumn: j  row: i  withEvent: nil  select: YES];
	      return YES;
	    }
	}
    }
  return NO;
}
-(BOOL) _editPreviousEditableCellBeforeRow: (int)row
				    column: (int)column
{
  int i,j;
  if (row < _numberOfColumns)
    {
      // First look for cells in the same row
      for (j = column - 1; j > -1; j--)
	{
	  if (_isCellEditable (_delegate, _tableColumns, self, row, j) == YES)
	    {
	      [self editColumn: j  row: row  withEvent: nil  select: YES];
	      return YES;
	    }
	}
    }
  // Otherwise, make the big cycle.
  for (i = row - 1; i > -1; i--)
    {
      for (j = _numberOfColumns - 1; j > -1; j--)
	{
	  if (_isCellEditable (_delegate, _tableColumns, self, i, j) == YES)
	    {
	      [self editColumn: j  row: i  withEvent: nil  select: YES];
	      return YES;
	    }
	}
    }
  return NO;
}
- (void) _autosaveTableColumns
{
  if (_autosaveTableColumns && _autosaveName != nil) 
    {
      NSUserDefaults      *defaults;
      NSString            *tableKey;
      NSMutableDictionary *config;
      NSTableColumn       *column;
      id                  en;

      defaults  = [NSUserDefaults standardUserDefaults];
      tableKey = [NSString stringWithFormat: @"NSTableView Columns %@", 
			   _autosaveName];
      config = [NSMutableDictionary new];
      
      en = [[self tableColumns] objectEnumerator];
      while ((column = [en nextObject]) != nil)
	{
	  NSArray *array;
	  NSNumber *width, *identNum;
	  NSObject *ident;
	  
	  width = [NSNumber numberWithInt: [column width]];
	  ident = [column identifier];
	  identNum = [NSNumber numberWithInt: [self columnWithIdentifier: 
						      ident]];
	  array = [NSArray arrayWithObjects: width, identNum, nil];  
	  [config setObject: array  forKey: ident];      
	} 
      [defaults setObject: config  forKey: tableKey];
      [defaults synchronize];
      RELEASE (config);
    }
}

- (void) _autoloadTableColumns
{
  if (_autosaveTableColumns && _autosaveName != nil) 
    { 
      NSUserDefaults     *defaults;
      NSDictionary       *config;
      NSString           *tableKey;

      defaults  = [NSUserDefaults standardUserDefaults];
      tableKey = [NSString stringWithFormat: @"NSTableView Columns %@", 
			   _autosaveName];
      config = [defaults objectForKey: tableKey];
      if (config != nil) 
	{
	  NSEnumerator *en = [[config allKeys] objectEnumerator];
	  NSString *colKey;
	  NSArray *colDesc; 
	  NSTableColumn *col;
	  
	  while ((colKey = [en nextObject]) != nil) 
	    {
	      col = [self tableColumnWithIdentifier: colKey];
	      
	      if (col != nil)
		{
		  colDesc = [config objectForKey: colKey];
		  [col setWidth: [[colDesc objectAtIndex: 0] intValue]];
		  [self moveColumn: [self columnWithIdentifier: colKey]
			toColumn: [[colDesc objectAtIndex: 1] intValue]];
		}
	    }
	}
    }
}

- (void) superviewFrameChanged: (NSNotification*)aNotification
{
  if (_autoresizesAllColumnsToFit == YES)
    {
      float visible_width = [self convertRect: [_super_view bounds] 
				  fromView: _super_view].size.width;
      float table_width = 0;

      if(_numberOfColumns > 0)
        {
          table_width = 
            _columnOrigins[_numberOfColumns - 1] +
            [[_tableColumns objectAtIndex: _numberOfColumns - 1] width];
        }
      
      /*
	NSLog(@"columnOrigins[0] %f", _columnOrigins[0]);
	NSLog(@"superview.bounds %@", 
	      NSStringFromRect([_super_view bounds]));
	NSLog(@"superview.frame %@", 
	      NSStringFromRect([_super_view frame]));
	NSLog(@"table_width %f", table_width);
	NSLog(@"width %f", visible_width);
	NSLog(@"_superview_width %f", _superview_width);
      */

      if ( table_width - _superview_width <= 0.001
	   && table_width - _superview_width >= -0.001 )
	{
	  // the last column had been sized to fit
	  [self sizeToFit];
	}
      else if ( table_width <= _superview_width
		&& table_width >= visible_width )
	{
	  // the tableView was too small and is now too large
	  [self sizeToFit];
	}
      else if (table_width >= _superview_width
	       && table_width <= visible_width )
	{
	  // the tableView was too large and is now too small
	  if (_numberOfColumns > 0)
	    [self scrollColumnToVisible: 0];
	  [self sizeToFit];
	}
      _superview_width = visible_width;
    }
  else
    {
      float visible_width = [self convertRect: [_super_view bounds] 
				  fromView: _super_view].size.width;
      float table_width = 0;

      if(_numberOfColumns > 0)
        {
          table_width = 
            _columnOrigins[_numberOfColumns - 1] +
            [[_tableColumns objectAtIndex: _numberOfColumns - 1] width];
        }
      
      /*
	NSLog(@"columnOrigins[0] %f", _columnOrigins[0]);
	NSLog(@"superview.bounds %@", 
	      NSStringFromRect([_super_view bounds]));
	NSLog(@"superview.frame %@", 
	      NSStringFromRect([_super_view frame]));
	NSLog(@"table_width %f", table_width);
	NSLog(@"width %f", visible_width);
	NSLog(@"_superview_width %f", _superview_width);
      */

      if ( table_width - _superview_width <= 0.001
	   && table_width - _superview_width >= -0.001 )
	{
	  // the last column had been sized to fit
	  [self sizeLastColumnToFit];
	}
      else if ( table_width <= _superview_width
		&& table_width >= visible_width )
	{
	  // the tableView was too small and is now too large
	  [self sizeLastColumnToFit];
	}
      else if (table_width >= _superview_width
	       && table_width <= visible_width )
	{
	  // the tableView was too large and is now too small
	  if (_numberOfColumns > 0)
	    [self scrollColumnToVisible: 0];
	  [self sizeLastColumnToFit];
	}
      _superview_width = visible_width;
    }
}


- (unsigned int) draggingSourceOperationMaskForLocal: (BOOL) flag
{
  return (NSDragOperationAll);
}


- (unsigned int) draggingEntered: (id <NSDraggingInfo>) sender
{
  NSLog(@"draggingEntered");
  currentDropRow = -1;
  currentDropOperation = -1;
  oldDropRow = -1;
  lastQuarterPosition = -1;
  oldDraggingRect = NSMakeRect(0.,0., 0., 0.);
  currentDragOperation = NSDragOperationAll;
  return currentDragOperation;
}


- (void) draggingExited: (id <NSDraggingInfo>) sender
{
  [self setNeedsDisplayInRect: oldDraggingRect];
  [self displayIfNeeded];
}

- (unsigned int) draggingUpdated: (id <NSDraggingInfo>) sender
{
  NSPoint p = [sender draggingLocation];
  NSRect newRect;
  NSTableViewDropOperation operation = NSTableViewDropAbove;
  int row;
  int quarterPosition;
  unsigned dragOperation;

  p = [self convertPoint: p fromView: nil];
  quarterPosition = (p.y - _bounds.origin.y) / _rowHeight * 4.;

  if ((quarterPosition - oldDropRow * 4 <= 2) &&
      (quarterPosition - oldDropRow * 4 >= -3) )
    {
      row = oldDropRow;
    }
  else
    {
      row = (quarterPosition + 2) / 4;
    }

  currentDropRow = row;
  currentDropOperation = NSTableViewDropAbove;

  dragOperation = [sender draggingSourceOperationMask];

  if ((lastQuarterPosition != quarterPosition)
      || (currentDragOperation != dragOperation))
    {
      currentDragOperation = dragOperation;
      if ([_dataSource respondsToSelector: 
			 @selector(tableView:validateDrop:proposedRow:proposedDropOperation:)])
	{
	  currentDragOperation = [_dataSource tableView: self
					      validateDrop: sender
					      proposedRow: currentDropRow
					      proposedDropOperation: NSTableViewDropAbove];
	}
      
      lastQuarterPosition = quarterPosition;
      
      if ((currentDropRow != oldDropRow) || (currentDropOperation != oldDropOperation))
	{
	  [self lockFocus];
	  
	  [self setNeedsDisplayInRect: oldDraggingRect];
	  [self displayIfNeeded];
	  
	  [[NSColor darkGrayColor] set];
      
	  if (currentDropOperation == NSTableViewDropAbove)
	    {
	      if (currentDropRow == 0)
		{
		  newRect = NSMakeRect([self visibleRect].origin.x,
				       currentDropRow * _rowHeight,
				       [self visibleRect].size.width,
				       3);
		}
	      else if (currentDropRow == _numberOfRows)
		{
		  newRect = NSMakeRect([self visibleRect].origin.x,
				       currentDropRow * _rowHeight - 2,
				       [self visibleRect].size.width,
				       3);
		}
	      else
		{
		  newRect = NSMakeRect([self visibleRect].origin.x,
				       currentDropRow * _rowHeight - 1,
				       [self visibleRect].size.width,
				       3);
		}
	      NSRectFill(newRect);
	      oldDraggingRect = newRect;
	    }
	  else
	    {
	      newRect = [self frameOfCellAtColumn: 0
			      row: currentDropRow];
	      newRect.origin.x = _bounds.origin.x;
	      newRect.size.width = _bounds.size.width + 2;
	      newRect.origin.x -= _intercellSpacing.height / 2;
	      newRect.size.height += _intercellSpacing.height;
	      oldDraggingRect = newRect;
	      oldDraggingRect.origin.y -= 1;
	      oldDraggingRect.size.height += 2;

	      newRect.size.height -= 1;

	      newRect.origin.x += 3;
	      newRect.size.width -= 3;
		
	      if (_drawsGrid)
		{
		  //newRect.origin.y += 1;
		  //newRect.origin.x += 1;
		  //newRect.size.width -= 2;
		  newRect.size.height += 1;
		}
	      else
		{
		}

	      NSFrameRectWithWidth(newRect, 2.0);
	      //	      NSRectFill(newRect);

	    }
	  [_window flushWindow];
	  
	  [self unlockFocus];
	  
	  oldDropRow = currentDropRow;
	  oldDropOperation = currentDropOperation;
	}
    }


  return dragOperation;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
  NSLog(@"performDragOperation");
  if ([_dataSource respondsToSelector: @selector(tableView:acceptDrop:row:dropOperation:)])
    {
      return [_dataSource tableView: self
			  acceptDrop: sender
			  row: currentDropRow
			  dropOperation: currentDropOperation];
    }
  else
    return NO;
}
- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
  [self setNeedsDisplayInRect: oldDraggingRect];
  [self displayIfNeeded];

  return YES;
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
}


/*
 * (NotificationRequestMethods)
 */
- (void) _postSelectionIsChangingNotification
{
  [nc postNotificationName: 
	NSTableViewSelectionIsChangingNotification
      object: self];
}
- (void) _postSelectionDidChangeNotification
{
  [nc postNotificationName: 
	NSTableViewSelectionDidChangeNotification
      object: self];
}
- (void) _postColumnDidMoveNotificationWithOldIndex: (int) oldIndex
					   newIndex: (int) newIndex
{
  [nc postNotificationName: 
	NSTableViewColumnDidMoveNotification
      object: self
      userInfo: [NSDictionary 
		  dictionaryWithObjectsAndKeys:
		  [NSNumber numberWithInt: newIndex],
		  @"NSNewColumn",
		    [NSNumber numberWithInt: oldIndex],
		  @"NSOldColumn",
		  nil]];
}

- (void) _postColumnDidResizeNotificationWithOldWidth: (float) oldWidth
{
  [nc postNotificationName: 
	NSTableViewColumnDidResizeNotification
      object: self
      userInfo: [NSDictionary 
		  dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithFloat: oldWidth],
		  @"NSOldWidth", 
		  nil]];
}

- (BOOL) _shouldSelectTableColumn: (NSTableColumn *)tableColumn
{
  if ([_delegate respondsToSelector: 
		   @selector (tableView:shouldSelectTableColumn:)] == YES) 
    {
      if ([_delegate tableView: self  shouldSelectTableColumn: tableColumn] == NO)
	{
	  return NO;
	}
    }

  return YES;
}

- (BOOL) _shouldSelectRow: (int)rowIndex
{
  if ([_delegate respondsToSelector: 
		   @selector (tableView:shouldSelectRow:)] == YES) 
    {
      if ([_delegate tableView: self  shouldSelectRow: rowIndex] == NO)
	{
	  return NO;
	}
    }
  
  return YES;
}

- (BOOL) _shouldSelectionChange
{
  if ([_delegate respondsToSelector: 
	  @selector (selectionShouldChangeInTableView:)] == YES) 
    {
      if ([_delegate selectionShouldChangeInTableView: self] == NO)
	{
	  return NO;
	}
    }
  
  return YES;
}

- (BOOL) _shouldEditTableColumn: (NSTableColumn *)tableColumn
			    row: (int) rowIndex
{
  if ([_delegate respondsToSelector: 
			@selector(tableView:shouldEditTableColumn:row:)])
    {
      if ([_delegate tableView: self shouldEditTableColumn: tableColumn
		     row: rowIndex] == NO)
	{
	  return NO;
	}
    }

  return YES;
}

- (id) _objectValueForTableColumn: (NSTableColumn *)tb
			      row: (int) index
{
  id result = nil;

  if([_dataSource respondsToSelector:
		    @selector(tableView:objectValueForTableColumn:row:)])
    {
      result = [_dataSource tableView: self
			    objectValueForTableColumn: tb
			    row: index];
    }

  return result;
}

- (void) _setObjectValue: (id)value
	  forTableColumn: (NSTableColumn *)tb
		     row: (int) index
{
  if([_dataSource respondsToSelector:
		    @selector(tableView:objectValueForTableColumn:row:)])
    {
      [_dataSource tableView: self
		   setObjectValue: value
		   forTableColumn: tb
		   row: index];
    }
}

- (BOOL) _isDraggingSource
{
  return [_dataSource respondsToSelector:
			@selector(tableView:writeRows:toPasteboard:)];
}

- (BOOL) _writeRows: (NSArray *) rows
       toPasteboard: (NSPasteboard *)pboard
{
  if ([_dataSource respondsToSelector:
		     @selector(tableView:writeRows:toPasteboard:)] == YES)
    {
      return [_dataSource tableView: self
			  writeRows: rows
			  toPasteboard: pboard];
    }
  return NO;
}

@end /* implementation of NSTableView */

