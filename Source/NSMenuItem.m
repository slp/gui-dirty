/* 
   NSMenuItem.m

   The menu cell class.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  David Lazaro Saz <khelekir@encomix.es>
   Date: Sep 1999

   Author:  Ovidiu Predescu <ovidiu@net-community.com>
   Date: May 1997
   
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

#include <gnustep/gui/config.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSDictionary.h>
#include <AppKit/NSMenuItem.h>
#include <AppKit/NSMenu.h>

static BOOL usesUserKeyEquivalents = NO;
static Class imageClass;

@interface GSMenuSeparator : NSMenuItem

@end

@implementation GSMenuSeparator

- (id) init
{
  self = [super initWithTitle: @"-----------"
		action: NULL
		keyEquivalent: @""];
  _enabled = NO;
  _changesState = NO;
  return self;
}

- (BOOL) isSeparatorItem
{
  return YES;
}

// FIXME: We need a lot of methods to switch of changes for a separator
@end


@implementation NSMenuItem

+ (void) initialize
{
  if (self == [NSMenuItem class])
    {
      [self setVersion: 1];
      imageClass = [NSImage class];
    }
}

+ (void) setUsesUserKeyEquivalents: (BOOL)flag
{
  usesUserKeyEquivalents = flag;
}

+ (BOOL) usesUserKeyEquivalents
{
  return usesUserKeyEquivalents;
}

+ (id <NSMenuItem>) separatorItem
{
  return [GSMenuSeparator new];
}

- (id) init
{
  return [self initWithTitle: @""
	       action: NULL
	       keyEquivalent: @""];
}

- (void) dealloc
{
  NSDebugLog (@"NSMenuItem '%@' dealloc", [self title]);

  TEST_RELEASE(_title);
  TEST_RELEASE(_keyEquivalent);
  TEST_RELEASE(_image);
  TEST_RELEASE(_onStateImage);
  TEST_RELEASE(_offStateImage);
  TEST_RELEASE(_mixedStateImage);
  TEST_RELEASE(_submenu);
  TEST_RELEASE(_representedObject);
  [super dealloc];
}

- (id) initWithTitle: (NSString*)aString
	      action: (SEL)aSelector
       keyEquivalent: (NSString*)charCode
{
  self = [super init];
  //_menu = nil;
  [self setTitle: aString];
  [self setKeyEquivalent: charCode];
  _keyEquivalentModifierMask = NSCommandKeyMask;
  _mnemonicLocation = 255; // No mnemonic
  _state = NSOffState;
  _enabled = YES;
  //_image = nil;
  // Set the images according to the spec. On: check mark; off: dash.
  [self setOnStateImage: [imageClass imageNamed: @"common_2DCheckMark"]];
  [self setMixedStateImage: [imageClass imageNamed: @"common_2DDash"]];
  //_offStateImage = nil;
  //_target = nil;
  _action = aSelector;
  //_changesState = NO;
  return self;
}

- (void) setMenu: (NSMenu*)menu
{
  _menu = menu;
  if (_submenu != nil)
    {
      [_submenu setSupermenu: menu];
      [self setTarget: _menu];
    }
}

- (NSMenu*) menu
{
  return _menu;
}

- (BOOL) hasSubmenu
{
  return (_submenu == nil) ? NO : YES;
}

- (void) setSubmenu: (NSMenu*)submenu
{
  if ([submenu supermenu] != nil)
    [NSException raise: NSInvalidArgumentException
		format: @"submenu already has supermenu: "];
  ASSIGN(_submenu, submenu);
  [submenu setSupermenu: _menu];
  [self setTarget: _menu];
  [self setAction: @selector(submenuAction:)];
}

- (NSMenu*) submenu
{
  return _submenu;
}

- (void) setTitle: (NSString*)aString
{
  if (nil == aString)
    aString = @"";

  ASSIGNCOPY(_title,  aString);
}

- (NSString*) title
{
  return _title;
}

- (BOOL) isSeparatorItem
{
  return NO;
}

- (void) setKeyEquivalent: (NSString*)aKeyEquivalent
{
  if (nil == aKeyEquivalent)
    aKeyEquivalent = @"";

  ASSIGNCOPY(_keyEquivalent,  aKeyEquivalent);
}

- (NSString*) keyEquivalent
{
  if (usesUserKeyEquivalents)
    return [self userKeyEquivalent];
  else
    return _keyEquivalent;
}

- (void) setKeyEquivalentModifierMask: (unsigned int)mask
{
  _keyEquivalentModifierMask = mask;
}

- (unsigned int) keyEquivalentModifierMask
{
  return _keyEquivalentModifierMask;
}

- (NSString*) userKeyEquivalent
{
  NSString *userKeyEquivalent = [[[[NSUserDefaults standardUserDefaults]
				      persistentDomainForName: NSGlobalDomain]
				     objectForKey: @"NSCommandKeys"]
				    objectForKey: _title];

  if (nil == userKeyEquivalent)
    userKeyEquivalent = @"";

  return userKeyEquivalent;
}

- (unsigned int) userKeyEquivalentModifierMask
{
  // FIXME
  return NSCommandKeyMask;
}

- (void) setMnemonicLocation: (unsigned)location
{
  _mnemonicLocation = location;
}

- (unsigned) mnemonicLocation
{
  if (_mnemonicLocation != 255)
    return _mnemonicLocation;
  else
    return NSNotFound;
}

- (NSString*) mnemonic
{
  if (_mnemonicLocation != 255)
    return [_title substringWithRange: NSMakeRange(_mnemonicLocation, 1)];
  else
    return @"";
}

- (void) setTitleWithMnemonic: (NSString*)stringWithAmpersand
{
  unsigned int location = [stringWithAmpersand rangeOfString: @"&"].location;

  [self setTitle: [stringWithAmpersand stringByReplacingString: @"&"
				       withString: @""]];
  [self setMnemonicLocation: location];
}

- (void) setImage: (NSImage *)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_image, image);
}

- (NSImage*) image
{
  return _image;
}

- (void) setState: (int)state
{
  _state = state;
  _changesState = YES;
}

- (int) state
{
  return _state;
}

- (void) setOnStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_onStateImage, image);
}

- (NSImage*) onStateImage
{
  return _onStateImage;
}

- (void) setOffStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_offStateImage, image);
}

- (NSImage*) offStateImage
{
  return _offStateImage;
}

- (void) setMixedStateImage: (NSImage*)image
{
  NSAssert(image == nil || [image isKindOfClass: imageClass],
    NSInvalidArgumentException);

  ASSIGN(_mixedStateImage, image);
}

- (NSImage*) mixedStateImage
{
  return _mixedStateImage;
}

- (void) setEnabled: (BOOL)flag
{
  _enabled = flag;
}

- (BOOL) isEnabled
{
  return _enabled;
}

- (void) setTarget: (id)anObject
{
  _target = anObject;
}

- (id) target
{
  return _target;
}

- (void) setAction: (SEL)aSelector
{
  _action = aSelector;
}

- (SEL) action
{
  return _action;
}

- (void) setTag: (int)anInt
{
  _tag = anInt;
}

- (int) tag
{
  return _tag;
}

- (void) setRepresentedObject: (id)anObject
{
  ASSIGN(_representedObject, anObject);
}

- (id) representedObject
{
  return _representedObject;
}

/*
 * NSCopying protocol
 */
- (id) copyWithZone: (NSZone*)zone
{
  NSMenuItem *copy = (NSMenuItem*)NSCopyObject (self, 0, zone);

  NSDebugLog (@"menu item '%@' copy", [self title]);

  // We reset the menu to nil to allow the reuse of the copy
  copy->_menu = nil;
  copy->_title = [_title copyWithZone: zone];
  copy->_keyEquivalent = [_keyEquivalent copyWithZone: zone];
  copy->_image = [_image copyWithZone: zone];
  copy->_onStateImage = [_onStateImage copyWithZone: zone];
  copy->_offStateImage = [_offStateImage copyWithZone: zone];
  copy->_mixedStateImage = [_mixedStateImage copyWithZone: zone];
  copy->_representedObject = RETAIN(_representedObject);
  copy->_submenu = [_submenu copy];

  return copy;
}

/*
 * NSCoding protocol
 */
- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _title];
  [aCoder encodeObject: _keyEquivalent];
  [aCoder encodeValueOfObjCType: "I" at: &_keyEquivalentModifierMask];
  [aCoder encodeValueOfObjCType: "I" at: &_mnemonicLocation];
  [aCoder encodeValueOfObjCType: "i" at: &_state];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_enabled];
  [aCoder encodeObject: _image];
  [aCoder encodeObject: _onStateImage];
  [aCoder encodeObject: _offStateImage];
  [aCoder encodeObject: _mixedStateImage];
  [aCoder encodeValueOfObjCType: @encode(BOOL) at: &_changesState];
  [aCoder encodeConditionalObject: _target];
  [aCoder encodeValueOfObjCType: @encode(SEL) at: &_action];
  [aCoder encodeValueOfObjCType: "i" at: &_tag];
  [aCoder encodeConditionalObject: _representedObject];
  [aCoder encodeObject: _submenu];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_title];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_keyEquivalent];
  [aDecoder decodeValueOfObjCType: "I" at: &_keyEquivalentModifierMask];
  [aDecoder decodeValueOfObjCType: "I" at: &_mnemonicLocation];
  [aDecoder decodeValueOfObjCType: "i" at: &_state];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_enabled];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_image];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_onStateImage];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_offStateImage];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_mixedStateImage];
  [aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_changesState];
  _target = [aDecoder decodeObject];
  [aDecoder decodeValueOfObjCType: @encode(SEL) at: &_action];
  [aDecoder decodeValueOfObjCType: "i" at: &_tag];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_representedObject];
  [aDecoder decodeValueOfObjCType: @encode(id) at: &_submenu];

  return self;
}

@end

@implementation NSMenuItem (GNUstepExtra)

/*
 * These methods support the special arranging in columns of menu
 * items in GNUstep.  There's no need to use them outside but if
 * they are used the display is more pleasant.
 */
- (void) setChangesState: (BOOL)flag
{
  _changesState = flag;
}

- (BOOL) changesState
{
  return _changesState;
}

@end
