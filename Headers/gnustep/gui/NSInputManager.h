/* -*-objc-*-
   NSInputManager.h

   Copyright (C) 2001, 2002 Free Software Foundation, Inc.

   Author: Nicola Pero <n.pero@mi.flashnet.it>
   Date: December 2001, February 2002

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

#ifndef _GNUstep_H_NSInputManager
#define _GNUstep_H_NSInputManager

#include <objc/Protocol.h>
#include <objc/objc.h>
#include <Foundation/NSGeometry.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAttributedString.h>

@class NSInputServer;
@class NSEvent;
@class NSImage;

@protocol NSTextInput
- (void) setMarkedText: (id)aString  selectedRange: (NSRange)selRange;
- (BOOL) hasMarkedText;
- (NSRange) markedRange;
- (NSRange) selectedRange;
- (void) unmarkText;
- (NSArray*) validAttributesForMarkedText;


- (NSAttributedString *) attributedSubstringFromRange: (NSRange)theRange;
- (unsigned int) characterIndexForPoint: (NSPoint)thePoint;
- (long) conversationIdentifier;
- (void) doCommandBySelector: (SEL)aSelector;
- (NSRect) firstRectForCharacterRange: (NSRange)theRange;
- (void) insertText: (id)aString;
@end

/* The input manager understands quite sophisticated keybindings.  
 *
 * A certain keystroke (represented by a unichar + some modifiers) can
 * be bound to a selector.  For example: "Control-f" = "moveForward:";
 * If you press Control-f, the selector moveForward: is invoked.
 *
 * A certain keystroke can be bound to an array of selectors.  For
 * example: "Control-k" = ("moveToBeginningOfLine:", "deleteToEndOfLine:");
 * If you press Control-k, the selector moveToBeginningOfLine: is invoked,
 * immediately followed by deleteToEndOfLine:.
 *
 * A certain keystroke can be bound to a dictionary of other
 * keybindings.  For example "Control-c" = { "Control-f" =
 * "openFile:"; "Control-s" = "save:"; };
 * If you press Control-c followed by Control-f, openFile: is invoked;
 * if you press Control-c followed by Control-s, save: is invoked.
 *
 * Any keystroke which is not bound by a keybinding is basically inserted
 * as it is by calling 'insertText:' of the caller.
 *
 * Control-g is normally bound to aborting the current keybinding
 * sequence.  Whenever you are confused about what the hell you have
 * typed and what strange command the input manager is going to
 * understand, just type Control-g to discard past pending keystrokes,
 * and reset the input manager.
 *
 * Control-q is normally bound to literally quoting the next
 * keystroke.  That is, the next keystroke is *not* interpreted by the
 * input manager, but rather inserted literally into the text.
 */

@class GSKeyBindingTable;

@interface NSInputManager: NSObject <NSTextInput>
{
  /* The current client we are working for.  */
  id _currentClient;

  /* This is the basic, root set of bindings.  Whenever the input
     manager detects that the current client has changed, it immediately
     resets the current key bindings to the root ones.  If you are typing
     and are confused about what's happening, pressing Control-g always
     resets the bindings to the root bindings.  */
  GSKeyBindingTable *_rootBindingTable;

  /* These are the bindings which will be used to interpret the next
     keystroke.  At the beginning, this is the same as the
     _rootBindingTable.  But when you type a keystroke which is the
     beginning of a sequence of keystrokes producing a certain action,
     then the input manager updates the _currentBindingTable to be the
     table where he looks up the next keystroke you put in.
  */
  GSKeyBindingTable *_currentBindingTable;

  /* When we are reading multi-keystroke bindings, we need to remember
     the keystrokes we read thinking they were the beginning of a
     multi-keystroke binding ... just in case it turns out that they
     are not :-)  */
  NSMutableArray *_pendingKeyEvents;

  /* When it is YES, the next key stroke is interpreted literally rather
     than looked up using the _currentBindingTable.  */
  BOOL _interpretNextKeyStrokeLiterally;

  /* Extremely special keybinding which overrides any other keybinding
     in all contexts - abort - normally bound to Control-g.  When we
     encounter this keystroke, we abort all pending keystrokes and
     reset ourselves immediately into vanilla root input state.  */
  unichar _abortCharacter;
  int _abortFlags;

  /* When it is YES, keystrokes containing the NSControlKeyMask as not
     inserted into the text.  This is so that if you press Control-x,
     and that is bound to nothing, it doesn't get inserted as a strange
     character into your text.  */
  BOOL _insertControlKeystrokes;
}
+ (NSInputManager *) currentInputManager;

- (id) initWithName: (NSString *)inputServerName
	       host: (NSString *)hostName;

- (BOOL) handleMouseEvent: (NSEvent *)theMouseEvent;
- (void) handleKeyboardEvents: (NSArray *)eventArray
		       client: (id)client;
- (NSString *) language;
- (NSString *) localizedInputManagerName;
- (void) markedTextAbandoned: (id)client;
- (void) markedTextSelectionChanged: (NSRange)newSel
			    client: (id)client;
- (BOOL) wantsToDelayTextChangeNotifications;
- (BOOL) wantsToHandleMouseEvents;
- (BOOL) wantsToInterpretAllKeystrokes;

/* GNUstep Extensions.  */

/* Parses a key as found in a keybinding file.
   key is something like 'Control-f' or 'Control-Shift-LeftArrow'.
   Returns YES if the key could be parsed, NO if not.  If the key
   could be parsed, character will contain the unichar, and modifiers
   the modifiers.  */
+ (BOOL) parseKey: (NSString *)key 
    intoCharacter: (unichar *)character
     andModifiers: (int *)modifiers;

/* This is used to produce a key description which can be put into a
   keybinding file from an actual keystroke.  The gnustep-gui never
   needs this :-) since it only reads keybinding files, never writes
   them, but Preferences applications might need it - they can have
   the user type in the desired keystroke, then call this method to
   turn the keystroke into a string which can be put in keybindings
   files.  Pass 0 as modifiers if you only want the name of the
   keystroke, ignoring modifiers.  */
+ (NSString *) describeKeyStroke: (unichar)character
		   withModifiers: (int)modifiers;

/* Methods used internally ... not really part of the public API, can change
   without notice.  */

/* Reset the internal state.  Normally bound to Control-g [regardless
   of context!], but also automatically done whenever the current
   client changes.  */
- (void) resetInternalState;

/* Quote the next key stroke.  Normally bound to Control-q.  */
- (void) quoteNextKeyStroke;


@end

#endif /* _GNUstep_H_NSInputManager */
