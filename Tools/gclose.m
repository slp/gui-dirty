/* This tool opens the appropriate application from the command line
   based on what type of file is being accessed. 

   Copyright (C) 2001 Free Software Foundation, Inc.

   Written by:  Gregory Casamento <greg_casamento@yahoo.com>
   Created: November 2001

   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

   */

#include <Foundation/NSArray.h>
#include <Foundation/NSConnection.h>
#include <Foundation/NSHost.h>
#include <Foundation/NSString.h>
#include <Foundation/NSProcessInfo.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSException.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSApplication.h>

int
main(int argc, char** argv, char **env_c)
{
  CREATE_AUTORELEASE_POOL(pool);
  NSEnumerator	*argEnumerator = nil;
  NSString	*arg = nil;
  NSString	*host = nil;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env_c];
#endif
  argEnumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
  
  host = [[NSUserDefaults standardUserDefaults] stringForKey: @"NSHost"];

  [argEnumerator nextObject]; // skip the first element, which is empty.
  while ((arg = [argEnumerator nextObject]) != nil)
    {
      if ([arg isEqualToString: @"-NSHost"])
	{
	  // skip since this is handled above...
	  arg = [argEnumerator nextObject];
	}
      else // no option specified
	{
	  NS_DURING
	    {
	      NSString	*port;
	      id	app;

	      if (host == nil)
		{
		  host = @"";
		}
	      else
		{
		  NSHost	*h = [NSHost hostWithName: host];

		  if ([h isEqual: [NSHost currentHost]] == YES)
		    {
		      host = @"";
		    }
		}

	      port = [[arg lastPathComponent] stringByDeletingPathExtension];
	      /*
	       *	Try to contact a running application.
	       */
	      app = [NSConnection
		rootProxyForConnectionWithRegisteredName: port  host: host];

	      NS_DURING
		{
		  [app terminate: nil];
		}
	      NS_HANDLER
		{
		  /* maybe it terminated. */
		}
	      NS_ENDHANDLER
	    }
	  NS_HANDLER
	    {
	      NSLog(@"Exception while attempting to terminate %@ - %@: %@",
		    arg, [localException name], [localException reason]);
	    }
	  NS_ENDHANDLER
	}
    }
  RELEASE(pool);
  exit(EXIT_SUCCESS);
}
