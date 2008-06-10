/** <title>NSTextStorage</title>

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author: Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
  
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

#include <Foundation/NSNotification.h>
#include <Foundation/NSException.h>
#include <Foundation/NSDebug.h>
#include "AppKit/NSAttributedString.h"
#include "AppKit/NSTextStorage.h"
#include "GNUstepGUI/GSLayoutManager.h"
#include "GSTextStorage.h"

@implementation NSTextStorage

static	Class	abstract;
static	Class	concrete;

static NSNotificationCenter *nc = nil;

+ (void) initialize
{
  if (self == [NSTextStorage class])
    {
      abstract = self;
      concrete = [GSTextStorage class];
      nc = [NSNotificationCenter defaultCenter];
    }
}

+ (id) allocWithZone: (NSZone*)zone
{
  if (self == abstract)
    return NSAllocateObject(concrete, 0, zone);
  else
    return NSAllocateObject(self, 0, zone);
}

- (void) dealloc
{
  RELEASE (_layoutManagers);
  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
      _delegate = nil;
    }
  [super dealloc];
}

/*
 *	The designated intialiser
 */
- (id) initWithString: (NSString*)aString
           attributes: (NSDictionary*)attributes
{
  _layoutManagers = [[NSMutableArray alloc] initWithCapacity: 2];
  return self;
}

/*
 * Return a string
 */

- (NSString*) string
{
  [self subclassResponsibility: _cmd];
  return nil;
}

/*
 *	Managing GSLayoutManagers
 */
- (void) addLayoutManager: (GSLayoutManager*)obj
{
  if ([_layoutManagers indexOfObjectIdenticalTo: obj] == NSNotFound)
    {
      [_layoutManagers addObject: obj];
      [obj setTextStorage: self];
    }
}

- (void) removeLayoutManager: (GSLayoutManager*)obj
{
  [obj setTextStorage: nil];
  [_layoutManagers removeObjectIdenticalTo: obj];
}

- (NSArray*) layoutManagers
{
  return _layoutManagers;
}

- (void) beginEditing
{
  _editCount++;
}

- (void) endEditing
{
  if (_editCount == 0)
    {
      [NSException raise: NSGenericException
		   format: @"endEditing without corresponding beginEditing"];
    }
  if (--_editCount == 0)
    {
      [self processEditing];
    }
}

/*
 *	If there are no outstanding beginEditing calls, this method calls
 *	processEditing to cause post-editing stuff to happen. This method
 *	has to be called by the primitives after changes are made.
 *	The range argument to edited:... is the range in the original string
 *	(before the edit).
 */
- (void) edited: (unsigned)mask range: (NSRange)old changeInLength: (int)delta
{

  NSDebugLLog(@"NSText", @"edited:range:changeInLength: called");

  /*
   * Add in any new flags for this edit.
   */
  _editedMask |= mask;

  /*
   * Extend edited range to encompass the latest edit.
   */
  if (_editedRange.length == 0)
    {
      _editedRange = old;		// First edit.
    }
  else
    {
      _editedRange = NSUnionRange (_editedRange, old);
    }

  /*
   * If the number of characters has been increased or decreased -
   * adjust the delta accordingly.
   */
  if ((mask & NSTextStorageEditedCharacters) && delta)
    {
      if (delta < 0)
	{
	  NSAssert (old.length >= (unsigned)-delta, NSInvalidArgumentException);
	}
      _editedRange.length += delta; 
      _editedDelta += delta;
    }

  if (_editCount == 0)
    [self processEditing];
}

/*
 *	This is called from edited:range:changeInLength: or endEditing.
 *	This method sends out NSTextStorageWillProcessEditing, then fixes
 *	the attributes, then sends out NSTextStorageDidProcessEditing,
 *	and finally notifies the layout managers of change with the
 *	textStorage:edited:range:changeInLength:invalidatedRange: method.
 */
- (void) processEditing
{
  NSRange	r;
  int original_delta;
  unsigned int i;
  unsigned length;

  NSDebugLLog(@"NSText", @"processEditing called in NSTextStorage.");

  /*
   * The _editCount gets decreased later again, so that changes by the
   * delegate or by ourselves when we fix attributes dont trigger a
   * new processEditing */
  _editCount++;
  [nc postNotificationName: NSTextStorageWillProcessEditingNotification
		    object: self];

  /* Very important: we save the current _editedRange */
  r = _editedRange;
  original_delta = _editedDelta;
  length = [self length];
  // Multiple adds at the end might give a too long result
  if (NSMaxRange(r) > length)
    {
      r.length = length - r.location;
    }
  
  /* The following call will potentially fix attributes.  These changes 
     are done through NSTextStorage methods, which records the changes 
     by calling edited:range:changeInLength: - which modifies editedRange.
     
     As a consequence, if any attribute has been fixed, r !=
     editedRange after this call.  This is why we saved r in the first
     place. */
  [self invalidateAttributesInRange: r];

  [nc postNotificationName: NSTextStorageDidProcessEditingNotification
                    object: self];
  _editCount--;

  /*
  The attribute fixes might have added or removed characters. We must make
  sure that range and delta we give to the layout managers is valid.
  */
  if (original_delta != _editedDelta)
    {
      if (_editedDelta - original_delta > 0)
	{
	  r.length += _editedDelta - original_delta;
	}
      else
	{
	  if ((unsigned)(original_delta - _editedDelta) > r.length)
	    {
	      r.length = 0;
	      if (r.location > [self length])
		r.location = [self length];
	    }
	  else
	    {
	      r.length += _editedDelta - original_delta;
	    }
	}
    }

  /*
   * Calls textStorage:edited:range:changeInLength:invalidatedRange: for
   * every layoutManager.
   */

  for (i = 0; i < [_layoutManagers count]; i++)
    {
      GSLayoutManager *lManager = [_layoutManagers objectAtIndex: i];

      [lManager textStorage: self  edited: _editedMask  range: r
		changeInLength: _editedDelta  invalidatedRange: _editedRange];
    }

  /*
   * edited values reset to be used again in the next pass.
   */

  _editedRange = NSMakeRange (0, 0);
  _editedDelta = 0;
  _editedMask = 0;
}

/*
 *	These methods return information about the editing status.
 *	Especially useful when there are outstanding beginEditing calls or
 *	during processEditing... editedRange.location will be NSNotFound if
 *	nothing has been edited.
 */       
- (unsigned) editedMask
{
  return _editedMask;
}

- (NSRange) editedRange
{
  return _editedRange;
}

- (int) changeInLength
{
  return _editedDelta;
}

/**
 * Set the delegate (adds it as an observer for text storage notifications)
 * and removes any old value (removes it as an observer).<br />
 * The delegate is <em>not</em> retained.
 */
- (void) setDelegate: (id)delegate
{
  if (_delegate != nil)
    {
      [nc removeObserver: _delegate  name: nil  object: self];
    }
  _delegate = delegate;

#define SET_DELEGATE_NOTIFICATION(notif_name) \
  if ([_delegate respondsToSelector: @selector(textStorage##notif_name:)]) \
    [nc addObserver: _delegate \
	   selector: @selector(textStorage##notif_name:) \
	       name: NSTextStorage##notif_name##Notification object: self]

  SET_DELEGATE_NOTIFICATION(DidProcessEditing);
  SET_DELEGATE_NOTIFICATION(WillProcessEditing);
}

/**
 * Returns the value most recently set usiong the -setDelegate: method.
 */
- (id) delegate
{
  return _delegate;
}

- (void) ensureAttributesAreFixedInRange: (NSRange)range
{
  // Do nothing as the default is not lazy fixing, so all is done already
}

- (BOOL) fixesAttributesLazily
{
  return NO;
}

- (void) invalidateAttributesInRange: (NSRange)range
{
  [self fixAttributesInRange: range];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      id delegate = [aDecoder decodeObjectForKey: @"NSDelegate"];
      NSString *string = [aDecoder decodeObjectForKey: @"NSString"];
      
      self = [self initWithString: string];
      [self setDelegate: delegate];
    }
  else
    {
	self = [super initWithCoder: aDecoder]; 
    }      
  return self;
}

- (void) encodeWithCoder: (NSCoder *)coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: [self delegate] forKey: @"NSDelegate"];
      [coder encodeObject: [self string] forKey: @"NSString"];
    }
  else
    {
      [super encodeWithCoder: coder];
    }
}

@end
