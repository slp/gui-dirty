/** <title>NSBundleAdditions</title>

   <abstract>Implementation of NSBundle Additions</abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: 1997
   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: 1999
   
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
   License along with this library;
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#include "config.h"
#include <Foundation/NSArchiver.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSBundle.h>
#include <Foundation/NSCoder.h>
#include <Foundation/NSData.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSDebug.h>
#include <Foundation/NSEnumerator.h>
#include <Foundation/NSException.h>
#include <Foundation/NSInvocation.h>
#include <Foundation/NSObjCRuntime.h>
#include <Foundation/NSPathUtilities.h>
#include <Foundation/NSFileManager.h>
#include <Foundation/NSString.h>
#include <Foundation/NSUserDefaults.h>
#include <Foundation/NSKeyValueCoding.h>
#include <Foundation/NSNotification.h>
#include <Foundation/NSURL.h>
#include "AppKit/NSNibConnector.h"
#include "AppKit/NSNibLoading.h"
#include "AppKit/NSNib.h"
#include "GNUstepGUI/GSNibTemplates.h"
#include "GNUstepGUI/IMLoading.h"

@implementation	NSNibConnector

- (void) dealloc
{
  RELEASE(_src);
  RELEASE(_dst);
  RELEASE(_tag);
  [super dealloc];
}

- (id) destination
{
  return _dst;
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
  [aCoder encodeObject: _src];
  [aCoder encodeObject: _dst];
  [aCoder encodeObject: _tag];
}

- (void) establishConnection
{
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
  if ([aDecoder allowsKeyedCoding])
    {
      ASSIGN(_src, [aDecoder decodeObjectForKey: @"NSSource"]);
      ASSIGN(_dst, [aDecoder decodeObjectForKey: @"NSDestination"]);
      ASSIGN(_tag, [aDecoder decodeObjectForKey: @"NSLabel"]);
    }
  else
    {
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_src];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_dst];
      [aDecoder decodeValueOfObjCType: @encode(id) at: &_tag];
    }
  return self;
}

- (NSString*) label
{
  return _tag;
}

- (void) replaceObject: (id)anObject withObject: (id)anotherObject
{
  if (_src == anObject)
    {
      ASSIGN(_src, anotherObject);
    }
  if (_dst == anObject)
    {
      ASSIGN(_dst, anotherObject);
    }
  if (_tag == anObject)
    {
      ASSIGN(_tag, anotherObject);
    }
}

- (id) source
{
  return _src;
}

- (void) setDestination: (id)anObject
{
  ASSIGN(_dst, anObject);
}

- (void) setLabel: (NSString*)label
{
  ASSIGN(_tag, label);
}

- (void) setSource: (id)anObject
{
  ASSIGN(_src, anObject);
}

@end

@implementation	NSNibControlConnector
- (void) establishConnection
{
  SEL		sel = NSSelectorFromString(_tag);
	      
  [_src setTarget: _dst];
  [_src setAction: sel];
}
@end

@implementation	NSNibOutletConnector
- (void) establishConnection
{
  if (_src != nil)
    {
      NSString	*selName;
      SEL	sel;

      selName = [NSString stringWithFormat: @"set%@%@:",
			  [[_tag substringToIndex: 1] uppercaseString],
			  [_tag substringFromIndex: 1]];
      sel = NSSelectorFromString(selName);
	      
      if (sel && [_src respondsToSelector: sel])
	{
	  [_src performSelector: sel withObject: _dst];
	}
      else
	{
	  const char	*nam = [_tag cString];
	  const char	*type;
	  unsigned int	size;
	  unsigned int	offset;

	  /*
	   * Use the GNUstep additional function to set the instance
	   * variable directly.
	   * FIXME - need some way to do this for libFoundation and
	   * Foundation based systems.
	   */
	  if (GSObjCFindVariable(_src, nam, &type, &size, &offset))
	    {
	      GSObjCSetVariable(_src, offset, size, (void*)&_dst); 
	    }
	}
    }
}
@end

// declare this here to avoid a compiler warning...
@interface NSNib (GNUstepPrivate)
+ (NSString *) _nibFilename: (NSString *)fileName;
@end

@implementation NSBundle (NSBundleAdditions)

static 
Class gmodel_class(void)
{
  static Class gmclass = Nil;

  if (gmclass == Nil)
    {
      NSBundle	*theBundle;
      NSEnumerator *benum;
      NSString	*path;

      /* Find the bundle */
      benum = [NSStandardLibraryPaths() objectEnumerator];
      while ((path = [benum nextObject]))
	{
	  path = [path stringByAppendingPathComponent: @"Bundles"];
	  path = [path stringByAppendingPathComponent: @"libgmodel.bundle"];
	  if ([[NSFileManager defaultManager] fileExistsAtPath: path])
	    break;
	  path = nil;
	}
      NSCAssert(path != nil, @"Unable to load gmodel bundle");
      NSDebugLog(@"Loading gmodel from %@", path);

      theBundle = [NSBundle bundleWithPath: path];
      NSCAssert(theBundle != nil, @"Can't init gmodel bundle");
      gmclass = [theBundle classNamed: @"GMModel"];
      NSCAssert(gmclass, @"Can't load gmodel bundle");
    }
  return gmclass;
}

+ (BOOL) loadNibFile: (NSString*)fileName
   externalNameTable: (NSDictionary*)context
	    withZone: (NSZone*)zone
{
  NSString            *ext    = [fileName pathExtension];
  NSNib               *nib    = nil;
  BOOL                 result = NO;
  NSMutableDictionary *ctx    = nil;

  /* 
   * Determine if we're loading a .gorm or a .gmodel
   * if the extension is .nib.
   */
  if ([ext isEqual: @"nib"])
    {
      NSFileManager	*mgr = [NSFileManager defaultManager];
      NSString		*base = [fileName stringByDeletingPathExtension];

      /* We can't read nibs, look for an equivalent gorm or gmodel file */
      fileName = [base stringByAppendingPathExtension: @"gorm"];
      if ([mgr isReadableFileAtPath: fileName])
	{
	  ext = @"gorm";
	}
      else
	{
	  fileName = [base stringByAppendingPathExtension: @"gmodel"];
	  ext = @"gmodel";
	}
    }

  /*
   * If the file to be read is a gmodel, use the GMModel method to
   * read it in and skip the dearchiving below.
   */
  if ([ext isEqualToString: @"gmodel"])
    {
      return [gmodel_class() loadIMFile: fileName
			  owner: [context objectForKey: @"NSOwner"]];
    } 
  
  // Create a temporary context dictionary, containing all of the entries of the
  // one passed in, but replacing the NSOwner and NSTopLevelObjects entries with
  // the ones used by the NSNib class.   We want *all* nib handling to happen in
  // one unified place within NSNib.  GJC
  if(context != nil)
    {
      id obj = nil;

      ctx = [NSMutableDictionary dictionaryWithDictionary: context];

      // remove and set the owner...
      obj = [ctx objectForKey: @"NSOwner"];
      if(obj != nil)
	{
	  [ctx removeObjectForKey: @"NSOwner"];
	  [ctx setObject: obj forKey: @"NSNibOwner"];
	}

      // Remove and set the top level objects...
      obj = [ctx objectForKey: @"NSTopLevelObjects"];
      if(obj != nil)
	{
	  [ctx removeObjectForKey: @"NSTopLevelObjects"];
	  [ctx setObject: obj forKey: @"NSNibTopLevelObjects"];
	}
    }

  // Load and instantiate the nib...  release the NSNib object.
  nib = [[NSNib alloc] initWithContentsOfURL: [NSURL fileURLWithPath: [NSNib _nibFilename: fileName]]];
  result = [nib instantiateNibWithExternalNameTable: ctx withZone: zone];
  RELEASE(nib);

  return result;
}

+ (BOOL) loadNibNamed: (NSString *)aNibName
	        owner: (id)owner
{
  NSDictionary	*table;
  NSBundle	*bundle;

  if (owner == nil || aNibName == nil)
    {
      return NO;
    }
  table = [NSDictionary dictionaryWithObject: owner forKey: @"NSOwner"];
  bundle = [self bundleForClass: [owner class]];
  if (bundle == nil)
    {
      bundle = [self mainBundle];
    }
  return [bundle loadNibFile: aNibName
	   externalNameTable: table
		    withZone: [owner zone]];
}

- (NSString *) pathForNibResource: (NSString *)fileName
{
  NSFileManager		*mgr = [NSFileManager defaultManager];
  NSMutableArray	*array = [NSMutableArray arrayWithCapacity: 8];
  NSArray		*languages = [NSUserDefaults userLanguages];
  NSString		*rootPath = [self bundlePath];
  NSString		*primary;
  NSString		*language;
  NSEnumerator		*enumerator;
  NSString		*ext;

  ext = [fileName pathExtension];
  fileName = [fileName stringByDeletingPathExtension];
  if ([ext isEqualToString: @"nib"] == YES)
    {
      ext = @"";
    }

  /*
   * Build an array of resource paths that differs from the normal order -
   * we want a localized file in preference to a generic one.
   */
  primary = [rootPath stringByAppendingPathComponent: @"Resources"];
  enumerator = [languages objectEnumerator];
  while ((language = [enumerator nextObject]))
    {
      NSString	*langDir;

      langDir = [NSString stringWithFormat: @"%@.lproj", language];
      [array addObject: [primary stringByAppendingPathComponent: langDir]];
    }
  [array addObject: primary];
  primary = rootPath;
  enumerator = [languages objectEnumerator];
  while ((language = [enumerator nextObject]))
    {
      NSString	*langDir;

      langDir = [NSString stringWithFormat: @"%@.lproj", language];
      [array addObject: [primary stringByAppendingPathComponent: langDir]];
    }
  [array addObject: primary];

  enumerator = [array objectEnumerator];
  while ((rootPath = [enumerator nextObject]) != nil)
    {
      NSString	*path;

      rootPath = [rootPath stringByAppendingPathComponent: fileName];
      // If the file does not have an extension, then we need to
      // figure out what type of model file to load.
      if ([ext isEqualToString: @""] == YES)
	{
	  path = [rootPath stringByAppendingPathExtension: @"gorm"];
	  if ([mgr isReadableFileAtPath: path] == NO)
	    {
	      path = [rootPath stringByAppendingPathExtension: @"gmodel"];
	      if ([mgr isReadableFileAtPath: path] == NO)
		{
		  continue;
		}
	    }
	  return path;
	}
      else
	{
	  path = [rootPath stringByAppendingPathExtension: ext];
	  if([mgr isReadableFileAtPath: path])
	    {
	      return path;
	    }
	}
    }

  return nil;
}

- (BOOL) loadNibFile: (NSString*)fileName
   externalNameTable: (NSDictionary*)context
	    withZone: (NSZone*)zone
{
  NSString *path = [self pathForNibResource: fileName];
  if (fileName != nil)
    {
      return [NSBundle loadNibFile: path
		 externalNameTable: context
			  withZone: (NSZone*)zone];
    }
  return NO;
}
@end
// end of NSBundleAdditions
