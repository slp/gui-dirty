/* 
   example.m

   GNUstep example services facility

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date: November 1998
   
   This file is part of the GNUstep Project

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public License
   as published by the Free Software Foundation; either version 2
   of the License, or (at your option) any later version.
    
   You should have received a copy of the GNU General Public  
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/ 

#include <gnustep/gui/config.h>
#include <Foundation/NSString.h>
#include <Foundation/NSData.h>
#include <Foundation/NSArray.h>
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSDictionary.h>
#include <Foundation/NSException.h>
#include <Foundation/NSRunLoop.h>
#include <Foundation/NSString.h>
#include <Foundation/NSException.h>
#include <Foundation/NSTask.h>
#include <Foundation/NSUserDefaults.h>
#include <AppKit/NSApplication.h>
#include <AppKit/NSPasteboard.h>

#include "wgetopt.h"

#include	<signal.h>

@interface ExampleServices : NSObject
- (void) openURL: (NSPasteboard*)bp
	userData: (NSString*)ud
	   error: (NSString**)err;
- (void) tolower: (NSPasteboard*)bp
	userData: (NSString*)ud
	   error: (NSString**)err;
- (void) toupper: (NSPasteboard*)bp
	userData: (NSString*)ud
	   error: (NSString**)err;
@end

@implementation ExampleServices
- (void) openURL: (NSPasteboard*)pb
	userData: (NSString*)ud
	   error: (NSString**)err
{
  NSString	*url;
  NSArray	*types;
  NSArray	*args;
  NSString	*path;
  NSTask	*task;
  NSString      *browser;
  NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];

  types = [pb types];
  if (![types containsObject: NSStringPboardType])
    {
      *err = @"No string type supplied on pasteboard";
      return;
    }

  url = [pb stringForType: NSStringPboardType];
  if (url == nil)
    {
      *err = @"No string value supplied on pasteboard";
      return;
    }

  browser = [defs objectForKey:@"NSWebBrowser"];
  if(!browser || [browser isEqualToString:@""])
  {
    browser = @"mozilla -remote \"openURL(%@,new-window)\"";
  }

  path = @"/bin/sh";
  args = [NSArray arrayWithObjects:
    @"-c",
    [NSString stringWithFormat: browser, url],
    nil];

  task = [NSTask launchedTaskWithLaunchPath: path
				  arguments: args];
}
- (void) tolower: (NSPasteboard*)pb
	userData: (NSString*)ud
	   error: (NSString**)err
{
  NSString	*in;
  NSString	*out;
  NSArray	*types;

  types = [pb types];
  if (![types containsObject: NSStringPboardType])
    {
      *err = @"No string type supplied on pasteboard";
      return;
    }

  in = [pb stringForType: NSStringPboardType];
  if (in == nil)
    {
      *err = @"No string value supplied on pasteboard";
      return;
    }

  out = [in lowercaseString];
  types = [NSArray arrayWithObject: NSStringPboardType];
  [pb declareTypes: types owner: nil];
  [pb setString: out forType: NSStringPboardType];

}
- (void) toupper: (NSPasteboard*)pb
	userData: (NSString*)ud
	   error: (NSString**)err
{
  NSString	*in;
  NSString	*out;
  NSArray	*types;

  types = [pb types];
  if (![types containsObject: NSStringPboardType])
    {
      *err = @"No string type supplied on pasteboard";
      return;
    }

  in = [pb stringForType: NSStringPboardType];
  if (in == nil)
    {
      *err = @"No string value supplied on pasteboard";
      return;
    }

  out = [in uppercaseString];
  types = [NSArray arrayWithObject: NSStringPboardType];
  [pb declareTypes: types owner: nil];
  [pb setString: out forType: NSStringPboardType];

}
@end

static int	debug = 0;
static int	verbose = 0;

static int
ihandler(int sig)
{
  abort();
}

static void
init(int argc, char** argv)
{
  const char  *options = "Hdv";
  int	  sym;

  while ((sym = getopt(argc, argv, options)) != -1)
    {
      switch(sym)
	{
	  case 'H':
	    printf("%s -[%s]\n", argv[0], options);
	    printf("GNU Services example server\n");
	    printf("-H\tfor help\n");
	    printf("-d\tavoid fork() to make debugging easy\n");
	    exit(0);

	  case 'd':
	    debug++;
	    break;

	  case 'v':
	    verbose++;
	    break;

	  default:
	    printf("%s - GNU Pasteboard server\n", argv[0]);
	    printf("-H	for help\n");
	    exit(0);
	}
    }

  for (sym = 0; sym < 32; sym++)
    {
      signal(sym, ihandler);
    }
#ifndef __MINGW__
  signal(SIGPIPE, SIG_IGN);
  signal(SIGTTOU, SIG_IGN);
  signal(SIGTTIN, SIG_IGN);
  signal(SIGHUP, SIG_IGN);
#endif
  signal(SIGTERM, ihandler);

  if (debug == 0)
    {
      /*
       *  Now fork off child process to run in background.
       */
#ifndef __MINGW__
      switch (fork())
	{
	  case -1:
	    NSLog(@"gpbs - fork failed - bye.\n");
	    exit(1);

	  case 0:
	    /*
	     *	Try to run in background.
	     */
#ifdef	NeXT
	    setpgrp(0, getpid());
#else
	    setsid();
#endif
	    break;

	  default:
	    if (verbose)
	      {
		NSLog(@"Process backgrounded (running as daemon)\r\n");
	      }
	    exit(0);
	}
#endif
    }
}

int
main(int argc, char** argv, char **env)
{
  NSAutoreleasePool *pool;
  ExampleServices *server;

#ifdef GS_PASS_ARGUMENTS
  [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif
  pool = [NSAutoreleasePool new];
  server = [ExampleServices new];
  init(argc, argv);

  // [NSObject enableDoubleReleaseCheck: YES];

  if (server == nil)
    {
      NSLog(@"Unable to create server object.\n");
      exit(1);
    }

  NSRegisterServicesProvider(server, @"ExampleServices");

  [[NSRunLoop currentRunLoop] run];

  exit(0);
}


