/* 
   NSMatrix.h

   This is the Matrix class. This class corresponds to NSMatrix
   of the OpenStep specification, but it also allows for rows
   and columns of different sizes.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Pascal Forget <pascal@wsc.com>
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

#ifndef _GNUstep_H_NSMatrix
#define _GNUstep_H_NSMatrix

#include <AppKit/stdappkit.h>
#include <AppKit/NSControl.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSNotification.h>

@interface NSMatrix : NSControl <NSCoding>

{
    // Attributes
    NSMutableArray *rows;
    NSMutableArray *col_widths;
    NSMutableArray *row_heights;
    int num_cols;
    int num_rows;
    NSCell *cell_prototype;
    NSSize inter_cell;
    Class cell_class;
    BOOL allows_empty_selection;
    BOOL selection_by_rect;
    BOOL draws_background;
    BOOL draws_cell_background;
    NSMutableArray *selected_cells;
    BOOL autoscroll;
    BOOL scrollable;
    BOOL autosize;
    NSMatrixMode mode;
    SEL double_action;
    SEL error_action;
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
- (SEL)doubleAction;
- (void)setDoubleAction:(SEL)aSelector;
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

//
// NSCoding protocol
//
- (void)encodeWithCoder:aCoder;
- initWithCoder:aDecoder;

@end

#endif // _GNUstep_H_NSMatrix
