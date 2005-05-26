/** <title>NSTextField</title>

   <abstract>Text field control class for text entry</abstract>

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Scott Christley <scottc@net-community.com>
   Date: 1996
   Author: Felipe A. Rodriguez <far@ix.netcom.com>
   Date: August 1998
   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: November 1999

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
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
*/

#include "config.h"

#include <Foundation/NSFormatter.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSString.h>
#include <Foundation/NSValue.h>

#include "AppKit/NSApplication.h"
#include "AppKit/NSCursor.h"
#include "AppKit/NSTextField.h"
#include "AppKit/NSTextFieldCell.h"
#include "AppKit/NSWindow.h"
static NSNotificationCenter *nc;

/*
 * Class variables
 */
static Class usedCellClass;
static Class textFieldCellClass;

@implementation NSTextField
//
// Class methods
//
+ (void) initialize
{
  if (self == [NSTextField class])
    {
      [self setVersion: 1];
      textFieldCellClass = [NSTextFieldCell class];
      usedCellClass = textFieldCellClass;
      nc = [NSNotificationCenter defaultCenter];
    }
}

/*
 * Setting the Cell class
 */
+ (Class) cellClass
{
  return usedCellClass;
}

+ (void) setCellClass: (Class)factoryId
{
  usedCellClass = factoryId ? factoryId : textFieldCellClass;
}

//
// Instance methods
//
- (id) initWithFrame: (NSRect)frameRect
{
  [super initWithFrame: frameRect];
  [_cell setState: 1];
  [_cell setBezeled: YES];
  [_cell setSelectable: YES];
  [_cell setEnabled: YES];
  [_cell setEditable: YES];
  [_cell setDrawsBackground: YES];
  _text_object = nil;

  return self;
}

- (void) dealloc
{
  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
      _delegate = nil;
    }

  [super dealloc];
}

//
// Setting User Access to Text
//
- (BOOL) isEditable
{
  return [_cell isEditable];
}

- (BOOL) isSelectable
{
  return [_cell isSelectable];
}

- (void) setEditable: (BOOL)flag
{
  [_cell setEditable: flag];
  if (_text_object)
    [_text_object setEditable: flag];
}

- (void) setSelectable: (BOOL)flag
{
  [_cell setSelectable: flag];
  if (_text_object)
    [_text_object setSelectable: flag];
}

//
// Editing Text
//
- (void) selectText: (id)sender
{
  if ([self isSelectable] && (_super_view != nil))
    {
      if (_text_object)
	[_text_object selectAll: self];
      else
	{
	  NSText *t = [_window fieldEditor: YES  forObject: self];
	  int length;

	  if ([t superview] != nil)
	    if ([t resignFirstResponder] == NO)
	      return;
	  
	  //  [NSCursor hide];
	  /* [self stringValue] generates a call to validateEditing 
	     so we need to call it before setting up the _text_object */
	  length = [[self stringValue] length];
	  _text_object = [_cell setUpFieldEditorAttributes: t];
	  [_cell selectWithFrame: _bounds
		 inView: self
		 editor: _text_object
		 delegate: self
		 start: 0
		 length: length];
	}
    }
}

//
// Setting Tab Key Behavior
//
- (id) nextText
{
  return [self nextKeyView];
}

- (id) previousText
{
  return [self previousKeyView];
}

- (void) setNextText: (id)anObject
{
  [self setNextKeyView: anObject];
}

- (void) setPreviousText: (id)anObject
{
  [self setPreviousKeyView: anObject];
}

//
// Assigning a Delegate
//
- (void) setDelegate: (id)anObject
{
  if (_delegate)
    [nc removeObserver: _delegate name: nil object: self];
  _delegate = anObject;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(controlText##notif_name:)]) \
    [nc addObserver: _delegate \
      selector: @selector(controlText##notif_name:) \
      name: NSControlText##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidBeginEditing);
  SET_DELEGATE_NOTIFICATION(DidEndEditing);
  SET_DELEGATE_NOTIFICATION(DidChange);
}

- (id) delegate
{
  return _delegate;
}

//
// Modifying Graphic Attributes
//
- (void) setBackgroundColor: (NSColor *)aColor
{
  [_cell setBackgroundColor: aColor];
}

- (NSColor *) backgroundColor
{
  return [_cell backgroundColor];
}

- (BOOL) drawsBackground
{
  return [_cell drawsBackground];
}

- (BOOL) isBezeled
{
  return [_cell isBezeled];
}

- (BOOL) isBordered
{
  return [_cell isBordered];
}

- (void) setBezeled: (BOOL)flag
{
  [_cell setBezeled: flag];
}

- (void) setBordered: (BOOL)flag
{
  [_cell setBordered: flag];
}

- (void) setDrawsBackground: (BOOL)flag
{
  [_cell setDrawsBackground: flag];
}

- (void) setTextColor: (NSColor *)aColor
{
  [_cell setTextColor: aColor];
}

- (NSColor *) textColor
{
  return [_cell textColor];
}

//
// Target and Action
//
- (SEL) errorAction
{
  return _error_action;
}

- (void) setErrorAction: (SEL)aSelector
{
  _error_action = aSelector;
}

//
// Handling Events
//
- (void) mouseDown: (NSEvent*)theEvent
{
  if ([self isSelectable] == NO)
    {
      [super mouseDown: theEvent];
      return;
    }

  /* NB: If we're receiving this click from the NSWindow, we expect
     _text_object to never be nil here, since NSWindow makes the
     NSTextField the first responder (which invokes its
     -becomeFirstResponder:, which invokes its -selectText:, which, if
     it is selectable, sets up the _text_object, then makes the
     _text_object first responder!) before calling its -mouseDown:.
     Only the first click should go via here; further clicks will be
     sent directly by the NSWindow to the _text_object.
  */
  if (_text_object)
    {
      [_text_object mouseDown: theEvent];
      return;
    }
  else
    {
      /* I suppose you could get here in subclasses which override
       * -becomeFirstResponder not to select the text.  In that case,
       * we set up the _text_object manually to start editing here.
       */

      /* Make sure we have first responder status when we start edit.
       * This does nothing if we are already first responder; but
       * (important!) it implicitly should free the fieldEditor if it
       * was in use by another control.
       */
      if ([_window makeFirstResponder: self])
	{
	  NSText *t = [_window fieldEditor: YES forObject: self];
	  
	  if ([t superview] != nil)
	    {
	      /* Can't take the field editor ... give up.  */
	      return;
	    }

	  _text_object = [_cell setUpFieldEditorAttributes: t];
	  [_cell editWithFrame: _bounds
		 inView: self
		 editor: _text_object
		 delegate: self
		 event: theEvent];
	}
    }
}

- (BOOL) acceptsFirstMouse: (NSEvent *)aEvent
{
  return [self isEditable];
}

- (BOOL) acceptsFirstResponder
{
  // we do not accept first responder if there is already a 
  // _text_object, else it would make the _text_object resign
  // and end editing
  return (_text_object == nil) && [self isSelectable];
}

- (BOOL) becomeFirstResponder
{
  if ([self acceptsFirstResponder])
    {
      [self selectText: self];
      return YES;
    }
  else
    {
      return NO;
    }
}

-(BOOL) needsPanelToBecomeKey
{
  return [self isEditable];
}

- (BOOL) abortEditing
{
  if (_text_object)
    {
      [_cell endEditing: _text_object];
      _text_object = nil;
      return YES;
    }
  else 
    return NO;
}

- (NSText *) currentEditor
{
  if (_text_object && ([_window firstResponder] == _text_object))
    return _text_object;
  else
    return nil;
}

- (void) validateEditing
{
  if (_text_object)
    {
      NSFormatter *formatter;
      NSString *string;

      formatter = [_cell formatter];
      string = AUTORELEASE ([[_text_object text] copy]);

      if (formatter == nil)
	{
	  [_cell setStringValue: string];
	}
      else
	{
	  id newObjectValue;
	  NSString *error;
 
	  if ([formatter getObjectValue: &newObjectValue 
			 forString: string 
			 errorDescription: &error] == YES)
	    {
	      [_cell setObjectValue: newObjectValue];
	    }
	  else
	    {
	      if ([_delegate control: self 
			     didFailToFormatString: string 
			     errorDescription: error] == YES)
		{
		  [_cell setStringValue: string];
		}
	      
	    }
	}
    }
}

- (void) textDidBeginEditing: (NSNotification *)aNotification
{
  NSDictionary *d;
  
  d = [NSDictionary dictionaryWithObject:[aNotification object] 
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidBeginEditingNotification
      object: self
      userInfo: d];
}

- (void) textDidChange: (NSNotification *)aNotification
{
  NSDictionary *d;
  NSFormatter *formatter;

  d = [NSDictionary dictionaryWithObject: [aNotification object] 
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidChangeNotification
      object: self
      userInfo: d];

  formatter = [_cell formatter];
  if (formatter != nil)
    {
      /*
       * FIXME: This part needs heavy interaction with the yet to finish 
       * text system.
       *
       */
      NSString *partialString;
      NSString *newString = nil;
      NSString *error = nil;
      BOOL wasAccepted;
      
      partialString = [_text_object string];
      wasAccepted = [formatter isPartialStringValid: partialString 
			       newEditingString: &newString 
			       errorDescription: &error];

      if (wasAccepted == NO)
	{
	  [_delegate control:self 
		     didFailToValidatePartialString: partialString 
		     errorDescription: error];
	}

      if (newString != nil)
	{
	  NSLog (@"Unimplemented: should set string to %@", newString);
	  // FIXME ! This would reset editing !
	  //[_text_object setString: newString];
	}
      else
	{
	  if (wasAccepted == NO)
	    {
	      // FIXME: Need to delete last typed character (?!)
	      NSLog (@"Unimplemented: should delete last typed character");
	    }
	}

    }
}

- (void) textDidEndEditing: (NSNotification *)aNotification
{
  NSDictionary *d;
  id textMovement;

  [self validateEditing];

  [_cell endEditing: [aNotification object]];

  _text_object = nil;

  d = [NSDictionary dictionaryWithObject: [aNotification object] 
		    forKey: @"NSFieldEditor"];
  [nc postNotificationName: NSControlTextDidEndEditingNotification
      object: self
      userInfo: d];

  textMovement = [[aNotification userInfo] objectForKey: @"NSTextMovement"];
  if (textMovement)
    {
      switch ([(NSNumber *)textMovement intValue])
	{
	case NSReturnTextMovement:
	  if ([self sendAction: [self action] to: [self target]] == NO)
	    {
	      if ([self performKeyEquivalent: [_window currentEvent]] == NO)
		[self selectText: self];
	    }
	  break;
	case NSTabTextMovement:
	  [_window selectKeyViewFollowingView: self];

	  if ([_window firstResponder] == _window)
	    [self selectText: self];
	  break;
	case NSBacktabTextMovement:
	  [_window selectKeyViewPrecedingView: self];

	  if ([_window firstResponder] == _window)
	    [self selectText: self];
	  break;
	}
    }
}

- (BOOL) textShouldBeginEditing: (NSText *)textObject
{
  if ([self isEditable] == NO)
    return NO;
  
  if (_delegate && [_delegate respondsToSelector: 
				@selector(control:textShouldBeginEditing:)])
    return [_delegate control: self 
		      textShouldBeginEditing: textObject];
  else 
    return YES;
}

- (BOOL) textShouldEndEditing: (NSText*)textObject
{
  if ([_cell isEntryAcceptable: [textObject text]] == NO)
    {
      [self sendAction: _error_action to: [self target]];
      return NO;
    }
  
  if ([_delegate respondsToSelector: 
		   @selector(control:textShouldEndEditing:)])
    {
      if ([_delegate control: self textShouldEndEditing: textObject] == NO)
	{
	  NSBeep ();
	  return NO;
	}
    }

  if ([_delegate respondsToSelector: @selector(control:isValidObject:)] == YES)
    {
      NSFormatter *formatter;
      id newObjectValue;
      
      formatter = [_cell formatter];
      
      if ([formatter getObjectValue: &newObjectValue 
			  forString: [_text_object text] 
		   errorDescription: NULL] == YES)
	{
	  if ([_delegate control: self isValidObject: newObjectValue] == NO)
	    {
	      return NO;
	    }
	}
    }

  // In all other cases
  return YES;
}

//
// Rich Text
//
- (void)setAllowsEditingTextAttributes:(BOOL)flag
{
  [_cell setAllowsEditingTextAttributes: flag];
}

- (BOOL)allowsEditingTextAttributes
{
  return [_cell allowsEditingTextAttributes];
}

- (void)setImportsGraphics:(BOOL)flag
{
  [_cell setImportsGraphics: flag];
}

- (BOOL)importsGraphics
{
  return [_cell importsGraphics];
}

- (void)setTitleWithMnemonic:(NSString *)aString
{
  [_cell setTitleWithMnemonic: aString];
}

//
// NSCoding protocol
//
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [super encodeWithCoder: aCoder];

  [aCoder encodeConditionalObject: _delegate];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_error_action];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  self = [super initWithCoder: aDecoder];

  if ([aDecoder allowsKeyedCoding])
    {
    }
  else
    {
      [self setDelegate: [aDecoder decodeObject]];
      [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_error_action];
    }
  _text_object = nil;

  return self;
}

@end

