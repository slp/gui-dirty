/* 
   NSControl.h

   The abstract control class

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

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSControl
#define _GNUstep_H_NSControl

#include <AppKit/NSText.h>

@class NSString;
@class NSNotification;
@class NSFormatter;

@class NSCell;
@class NSFont;
@class NSEvent;

@interface NSControl : NSView
{
  // Attributes
  int _tag;
  id _cell; // id so compiler wont complain too much for subclasses
  BOOL _ignoresMultiClick;
}

//
// Setting the Control's Cell 
//
+ (Class)cellClass;
+ (void)setCellClass:(Class)factoryId;
- (id)cell;
- (void)setCell:(NSCell *)aCell;

//
// Enabling and Disabling the Control 
//
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;

//
// Identifying the Selected Cell 
//
- (id)selectedCell;
- (int)selectedTag;

//
// Setting the Control's Value 
//
- (void) setDoubleValue: (double)aDouble;
- (double) doubleValue;

- (void) setFloatValue: (float)aFloat;
- (float) floatValue;

- (void) setIntValue: (int)anInt;
- (int) intValue;

- (void) setStringValue: (NSString *)aString;
- (NSString *) stringValue;

- (void) setObjectValue: (id)anObject;
- (id) objectValue;

- (void) setNeedsDisplay;

//
// Interacting with Other Controls 
//
- (void) takeDoubleValueFrom: (id)sender;
- (void) takeFloatValueFrom: (id)sender;
- (void) takeIntValueFrom: (id)sender;
- (void) takeStringValueFrom: (id)sender;
- (void) takeObjectValueFrom: (id)sender;

//
// Formatting Text 
//
- (NSTextAlignment)alignment;
- (NSFont *)font;
- (void)setAlignment:(NSTextAlignment)mode;
- (void)setFont:(NSFont *)fontObject;
- (void)setFloatingPointFormat:(BOOL)autoRange
			  left:(unsigned)leftDigits
			 right:(unsigned)rightDigits;
#ifndef STRICT_OPENSTEP
- (void)setFormatter:(NSFormatter*)newFormatter;
- (id)formatter;
#endif

//
// Managing the Field Editor 
//
- (BOOL)abortEditing;
- (NSText *)currentEditor;
- (void)validateEditing;

//
// Resizing the Control 
//
- (void)calcSize;
- (void)sizeToFit;

//
// Displaying the Control and Cell 
//
- (void)drawCell:(NSCell *)aCell;
- (void)drawCellInside:(NSCell *)aCell;
- (void)selectCell:(NSCell *)aCell;
- (void)updateCell:(NSCell *)aCell;
- (void)updateCellInside:(NSCell *)aCell;

//
// Target and Action 
//
- (SEL)action;
- (BOOL)isContinuous;
- (BOOL)sendAction:(SEL)theAction
		to:(id)theTarget;
- (int)sendActionOn:(int)mask;
- (void)setAction:(SEL)aSelector;
- (void)setContinuous:(BOOL)flag;
- (void)setTarget:(id)anObject;
- (id)target;

//
// Attributed string handling
//
#ifndef STRICT_OPENSTEP
- (NSAttributedString *)attributedStringValue;
- (void)setAttributedStringValue:(NSAttributedString *)attribStr;
#endif 

//
// Assigning a Tag 
//
- (void)setTag:(int)anInt;
- (int)tag;

//
// Activation
//
- (void)performClick:(id)sender;
#ifndef STRICT_OPENSTEP
- (BOOL)refusesFirstResponder;
- (void)setRefusesFirstResponder:(BOOL)flag;
#endif

//
// Tracking the Mouse 
//
- (void)mouseDown:(NSEvent *)theEvent;
- (BOOL)ignoresMultiClick;
- (void)setIgnoresMultiClick:(BOOL)flag;

@end

APPKIT_EXPORT NSString *NSControlTextDidBeginEditingNotification;
APPKIT_EXPORT NSString *NSControlTextDidEndEditingNotification;
APPKIT_EXPORT NSString *NSControlTextDidChangeNotification;

//
// Methods Implemented by the Delegate
//
@interface NSObject (NSControlDelegate)
- (BOOL) control: (NSControl *)control
  textShouldBeginEditing: (NSText *)fieldEditor;

- (BOOL) control: (NSControl *)control
  textShouldEndEditing: (NSText *)fieldEditor;

- (void) controlTextDidBeginEditing: (NSNotification *)aNotification;

- (void) controlTextDidEndEditing: (NSNotification *)aNotification;

- (void) controlTextDidChange: (NSNotification *)aNotification;

- (BOOL) control: (NSControl *)control 
  didFailToFormatString: (NSString *)string 
  errorDescription: (NSString *)error;

- (void) control: (NSControl *)control 
  didFailToValidatePartialString: (NSString *)string 
  errorDescription: (NSString *)error;

- (BOOL) control: (NSControl *)control  isValidObject:(id)object;
@end


#endif // _GNUstep_H_NSControl