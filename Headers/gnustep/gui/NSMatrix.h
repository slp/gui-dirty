/* 
   NSMatrix.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   A completely rewritten version of the original source by Pascal Forget and
   Scott Christley.
   
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

#ifndef _GNUstep_H_NSMatrix
#define _GNUstep_H_NSMatrix

#include <AppKit/NSControl.h>

@class NSArray;
@class NSMutableArray;
@class NSNotification;

@class NSCell;
@class NSColor;
@class NSText;
@class NSEvent;

typedef enum _NSMatrixMode {
  NSRadioModeMatrix,
  NSHighlightModeMatrix,
  NSListModeMatrix,
  NSTrackModeMatrix 
} NSMatrixMode;

@interface NSMatrix : NSControl <NSCoding>
{
  NSMutableArray* cells;
  NSMatrixMode mode;
  int numRows;
  int numCols;
  Class cellClass;
  id cellPrototype;
  NSSize cellSize;
  NSSize intercell;
  NSColor* backgroundColor;
  NSColor* cellBackgroundColor;
  id delegate;
  id target;
  SEL action;
  SEL doubleAction;
  SEL errorAction;
  id selectedCell;
  int selectedRow;
  int selectedColumn;
  void* selectedCells;
  BOOL allowsEmptySelection;
  BOOL selectionByRect;
  BOOL drawsBackground;
  BOOL drawsCellBackground;
  BOOL autosizesCells;
  BOOL autoscroll;
}

//
// Initializing the NSMatrix Class 
//
+ (Class)cellClass;
+ (void)setCellClass:(Class)classId;

//
// Initializing an NSMatrix Object
//
- (id)initWithFrame:(NSRect)frameRect;
- (id)initWithFrame:(NSRect)frameRect
	       mode:(int)aMode
	  cellClass:(Class)classId
       numberOfRows:(int)rowsHigh
    numberOfColumns:(int)colsWide;
- (id)initWithFrame:(NSRect)frameRect
	       mode:(int)aMode
	  prototype:(NSCell *)aCell
       numberOfRows:(int)rowsHigh
    numberOfColumns:(int)colsWide;

//
// Setting the Selection Mode 
//
- (NSMatrixMode)mode;
- (void)setMode:(NSMatrixMode)aMode;

//
// Configuring the NSMatrix 
//
- (BOOL)allowsEmptySelection;
- (BOOL)isSelectionByRect;
- (void)setAllowsEmptySelection:(BOOL)flag;
- (void)setSelectionByRect:(BOOL)flag;

//
// Setting the Cell Class 
//
- (Class)cellClass;
- (id)prototype;
- (void)setCellClass:(Class)classId;
- (void)setPrototype:(NSCell *)aCell;

//
// Laying Out the NSMatrix 
//
- (void)addColumn;
- (void)addColumnWithCells:(NSArray *)cellArray;
- (void)addRow;
- (void)addRowWithCells:(NSArray *)cellArray;
- (NSRect)cellFrameAtRow:(int)row
		  column:(int)column;
- (NSSize)cellSize;
- (void)getNumberOfRows:(int *)rowCount
		columns:(int *)columnCount;
- (void)insertColumn:(int)column;
- (void)insertColumn:(int)column withCells:(NSArray *)cellArray;
- (void)insertRow:(int)row;
- (void)insertRow:(int)row withCells:(NSArray *)cellArray;
- (NSSize)intercellSpacing;
- (NSCell *)makeCellAtRow:(int)row
		   column:(int)column;
- (void)putCell:(NSCell *)newCell
	  atRow:(int)row
	 column:(int)column;
- (void)removeColumn:(int)column;
- (void)removeRow:(int)row;
- (void)renewRows:(int)newRows
	  columns:(int)newColumns;
- (void)setCellSize:(NSSize)aSize;
- (void)setIntercellSpacing:(NSSize)aSize;
- (void)sortUsingFunction:(int (*)(id element1, id element2, void *userData))comparator
		  context:(void *)context;
- (void)sortUsingSelector:(SEL)comparator;
- (int)numberOfColumns;
- (int)numberOfRows;

//
// Finding Matrix Coordinates 
//
- (BOOL)getRow:(int *)row
	column:(int *)column
      forPoint:(NSPoint)aPoint;
- (BOOL)getRow:(int *)row
	column:(int *)column
	ofCell:(NSCell *)aCell;

//
// Modifying Individual Cells 
//
- (void)setState:(int)value
	   atRow:(int)row
	  column:(int)column;

//
// Selecting Cells 
//
- (void)deselectAllCells;
- (void)deselectSelectedCell;
- (void)selectAll:(id)sender;
- (void)selectCellAtRow:(int)row
		 column:(int)column;
- (BOOL)selectCellWithTag:(int)anInt;
- (id)selectedCell;
- (NSArray *)selectedCells;
- (int)selectedColumn;
- (int)selectedRow;
- (void)setSelectionFrom:(int)startPos
		      to:(int)endPos
		  anchor:(int)anchorPos
	       highlight:(BOOL)flag;

//
// Finding Cells 
//
- (id)cellAtRow:(int)row
	 column:(int)column;
- (id)cellWithTag:(int)anInt;
- (NSArray *)cells;

//
// Modifying Graphic Attributes 
//
- (NSColor *)backgroundColor;
- (NSColor *)cellBackgroundColor;
- (BOOL)drawsBackground;
- (BOOL)drawsCellBackground;
- (void)setBackgroundColor:(NSColor *)aColor;
- (void)setCellBackgroundColor:(NSColor *)aColor;
- (void)setDrawsBackground:(BOOL)flag;
- (void)setDrawsCellBackground:(BOOL)flag;

//
// Editing Text in Cells 
//
- (void)selectText:(id)sender;
- (id)selectTextAtRow:(int)row
	       column:(int)column;
- (void)textDidBeginEditing:(NSNotification *)notification;
- (void)textDidChange:(NSNotification *)notification;
- (void)textDidEndEditing:(NSNotification *)notification;
- (BOOL)textShouldBeginEditing:(NSText *)textObject;
- (BOOL)textShouldEndEditing:(NSText *)textObject;

//
// Setting Tab Key Behavior 
//
- (id)nextText;
- (id)previousText;
- (void)setNextText:(id)anObject;
- (void)setPreviousText:(id)anObject;

//
// Assigning a Delegate 
//
- (void)setDelegate:(id)anObject;
- (id)delegate;

//
// Resizing the Matrix and Cells 
//
- (BOOL)autosizesCells;
- (void)setAutosizesCells:(BOOL)flag;
- (void)setValidateSize:(BOOL)flag;
- (void)sizeToCells;

//
// Scrolling 
//
- (BOOL)isAutoscroll;
- (void)scrollCellToVisibleAtRow:(int)row
			  column:(int)column;
- (void)setAutoscroll:(BOOL)flag;
- (void)setScrollable:(BOOL)flag;

//
// Displaying 
//
- (void)drawCellAtRow:(int)row
	       column:(int)column;
- (void)highlightCell:(BOOL)flag
		atRow:(int)row
	       column:(int)column;

//
//Target and Action 
//
- (void)setAction:(SEL)aSelector;
- (SEL)action;
- (void)setDoubleAction:(SEL)aSelector;
- (SEL)doubleAction;
- (void)setErrorAction:(SEL)aSelector;
- (SEL)errorAction;
- (BOOL)sendAction;
- (void)sendAction:(SEL)aSelector
		to:(id)anObject
       forAllCells:(BOOL)flag;
- (void)sendDoubleAction;
- (void)setErrorAction:(SEL)aSelector;

//
// Handling Event and Action Messages 
//
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent;
- (void)mouseDown:(NSEvent *)theEvent;
- (int)mouseDownFlags;
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;

//
// Managing the Cursor 
//
- (void)resetCursorRects;

@end

#endif // _GNUstep_H_NSMatrix
