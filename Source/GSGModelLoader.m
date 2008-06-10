/** <title>GSGormLoader</title>

   <abstract>Gorm model loader</abstract>

   Copyright (C) 1997, 1999 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2005
   
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

#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

#include "GNUstepGUI/GSModelLoaderFactory.h"
#include "GNUstepGUI/IMLoading.h"

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

@interface GSGModelLoader : GSModelLoader
@end

@implementation GSGModelLoader
+ (void) initialize
{
  // register for the gmodel type.
}

+ (NSString *) type
{
  return @"gmodel";
}

+ (float) priority
{
  return 2.0;
}

- (BOOL) loadModelFile: (NSString *)fileName
     externalNameTable: (NSDictionary *)context
              withZone: (NSZone *)zone;
{
  NSString      *ext = [fileName pathExtension];

  /*
   * If the file to be read is a gmodel, use the GMModel method to
   * read it in and skip the dearchiving below.
   */
  if ([ext isEqualToString: @"gmodel"])
    {
      return [gmodel_class() loadIMFile: fileName
		      owner: [context objectForKey: @"NSOwner"]];
    } 

  return NO;
}
@end
